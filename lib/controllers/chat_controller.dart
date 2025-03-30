import 'package:get/get.dart';
import '../services/openai_service.dart';
import '../services/mem0_service.dart';
import '../controllers/auth_controller.dart';

class ChatMessage {
  final String message;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.message,
    required this.isUser,
    required this.timestamp,
  });

  String get timeString {
    final hour = timestamp.hour;
    final minute = timestamp.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final formattedHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final formattedMinute = minute.toString().padLeft(2, '0');
    return '$formattedHour:$formattedMinute $period';
  }
}

class ChatController extends GetxController {
  final OpenAIService openAIService;
  final Mem0Service mem0Service = Mem0Service();
  final AuthController authController = Get.find<AuthController>();

  final RxList<ChatMessage> messages = <ChatMessage>[].obs;
  final RxBool isTyping = false.obs;
  final RxBool isSearchingMemories = false.obs;
  final RxList<String> relevantMemories = <String>[].obs;

  // New properties for context management
  final RxString conversationSummary = ''.obs;
  final RxBool isSummarizing = false.obs;
  final int maxContextChars = 3000; // Character limit before summarization
  final RxInt messageIndexAfterLastSummary =
      0.obs; // Track messages after last summary

  // Number of previous messages to include as context
  final int contextWindowSize = 6;

  ChatController() : openAIService = OpenAIService();

  @override
  void onInit() {
    super.onInit();

    // Add initial greeting message
    messages.add(
      ChatMessage(
        message:
            "Hello! I'm your document assistant. How can I help you today?",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  // New method to build the full conversation context
  String _buildFullContext() {
    if (messages.isEmpty) return "";

    StringBuffer contextBuilder = StringBuffer();

    // Add summary if available
    if (conversationSummary.value.isNotEmpty) {
      contextBuilder.writeln("CONVERSATION SUMMARY:");
      contextBuilder.writeln(conversationSummary.value);
      contextBuilder.writeln("\nRECENT MESSAGES:");
    }

    // Add recent messages (those after the last summary)
    for (int i = messageIndexAfterLastSummary.value; i < messages.length; i++) {
      final msg = messages[i];
      String speaker = msg.isUser ? "User" : "Assistant";
      contextBuilder.writeln("$speaker: ${msg.message}");
    }

    return contextBuilder.toString();
  }

  // New method to summarize the conversation
  Future<void> _summarizeConversation() async {
    if (messages.length <= 1) return; // Nothing to summarize

    isSummarizing.value = true;

    try {
      // Create prompt for summarization
      StringBuffer conversationText = StringBuffer();
      conversationText.writeln("Please summarize the following conversation:");

      // Include existing summary if available
      if (conversationSummary.value.isNotEmpty) {
        conversationText.writeln("\nPrevious summary:");
        conversationText.writeln(conversationSummary.value);
        conversationText.writeln("\nNew messages to incorporate:");
      }

      // Add messages since last summary
      for (
        int i = messageIndexAfterLastSummary.value;
        i < messages.length;
        i++
      ) {
        final msg = messages[i];
        String speaker = msg.isUser ? "User" : "Assistant";
        conversationText.writeln("$speaker: ${msg.message}");
      }

      print('Summarizing conversation...');

      // Ask LLM to summarize using dedicated summarization method
      final summary = await openAIService.summarizeConversation(
        conversationText.toString(),
      );

      // Update the summary and tracking index
      conversationSummary.value = summary;
      messageIndexAfterLastSummary.value = messages.length;

      print(
        'Conversation summarized. New summary length: ${summary.length} chars',
      );
      print('Summary: $summary');
    } catch (e) {
      print('Error summarizing conversation: $e');
    } finally {
      isSummarizing.value = false;
    }
  }

  // Get current context for debugging
  Future<void> debugContext() async {
    final context = _buildFullContext();
    print('--- CURRENT CONTEXT (${context.length} chars) ---');
    print(context);
    print('--- END CONTEXT ---');

    print('Messages total: ${messages.length}');
    print(
      'Messages since last summary: ${messages.length - messageIndexAfterLastSummary.value}',
    );
    print('Has summary: ${conversationSummary.value.isNotEmpty}');
    print('Summary length: ${conversationSummary.value.length}');
  }

  // Manually trigger summarization (for testing)
  Future<void> triggerSummarization() async {
    print('Manually triggering summarization...');
    await _summarizeConversation();
    await debugContext();
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Add user message to the chat
    final userMessage = ChatMessage(
      message: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
    messages.add(userMessage);

    // Set typing indicator
    isTyping.value = true;

    try {
      // Get current user
      final user = authController.currentUser;
      String? userId = user?.email ?? user?.id;

      if (userId == null) {
        throw Exception('No user ID available');
      }

      // Special commands for debugging
      if (text == "!debug_context") {
        await debugContext();
        final aiMessage = ChatMessage(
          message:
              "Context debugging information has been printed to the console.",
          isUser: false,
          timestamp: DateTime.now(),
        );
        messages.add(aiMessage);
        isTyping.value = false;
        return;
      } else if (text == "!summarize") {
        await triggerSummarization();
        final aiMessage = ChatMessage(
          message:
              "Conversation has been summarized. Summary: ${conversationSummary.value}",
          isUser: false,
          timestamp: DateTime.now(),
        );
        messages.add(aiMessage);
        isTyping.value = false;
        return;
      }

      // Use the combined analysis just to categorize the message
      final messageAnalysis = await openAIService.analyzeMessage(text);
      final messageType = messageAnalysis['category'] as String;

      print('Message analysis - Category: $messageType');

      // Get current context for response generation
      String currentContext = _buildFullContext();
      print('Current context length: ${currentContext.length}');

      // Check if we need to summarize
      if (currentContext.length > maxContextChars && !isSummarizing.value) {
        print(
          'Context length (${currentContext.length}) exceeds maximum (${maxContextChars}). Summarizing...',
        );
        await _summarizeConversation();
        // Rebuild context with summary
        currentContext = _buildFullContext();
        print(
          'New context length after summarization: ${currentContext.length}',
        );
      }

      if (messageType == "query") {
        print('Here is the text along with the current context: $text');
        // For queries, always search memory for a more comprehensive response
        await _handleQuery(text, userId, currentContext);
      } else {
        // For statements, simply respond normally with context
        final response = await openAIService.getChatResponse(
          "CONVERSATION CONTEXT:\n$currentContext\n\nUSER STATEMENT: $text",
        );

        // Add AI response to the chat
        final aiMessage = ChatMessage(
          message: response,
          isUser: false,
          timestamp: DateTime.now(),
        );
        messages.add(aiMessage);
      }
    } catch (e) {
      print('Error processing message: $e');
      // Add error message
      final errorMessage = ChatMessage(
        message:
            "I'm sorry, I couldn't process your request. Please try again.",
        isUser: false,
        timestamp: DateTime.now(),
      );
      messages.add(errorMessage);
    } finally {
      // Hide typing indicator
      isTyping.value = false;
    }
  }

  // Helper to get recent conversation context
  String _getConversationContext() {
    if (messages.isEmpty) return "";

    // Get the last few messages for context
    int startIndex = messages.length - contextWindowSize;
    if (startIndex < 0) startIndex = 0;

    final List<ChatMessage> recentMessages = messages.sublist(startIndex);

    // Format the context as a string
    StringBuffer contextBuilder = StringBuffer();
    contextBuilder.writeln("Conversation context:");

    for (final msg in recentMessages) {
      String speaker = msg.isUser ? "User" : "Assistant";
      contextBuilder.writeln("$speaker: ${msg.message}");
    }

    print('Conversation context: $contextBuilder');

    return contextBuilder.toString();
  }

  // Handle query flow (refactored from existing code)
  Future<void> _handleQuery(String text, String userId, String context) async {
    relevantMemories.clear();

    // Search for relevant memories
    isSearchingMemories.value = true;
    final memories = await mem0Service.searchMemories(userId, text);
    relevantMemories.value = memories;
    isSearchingMemories.value = false;

    print('Found ${memories.length} relevant memories for query: $text');
    // Debug each memory found
    for (int i = 0; i < memories.length; i++) {
      print('Memory ${i + 1}: ${memories[i]}');
    }

    // Always include both conversation context and document memory (if available)
    String fullContext = "CONVERSATION CONTEXT:\n$context\n\n";

    // Add document memories if found
    if (relevantMemories.isNotEmpty) {
      fullContext += "DOCUMENT INFORMATION:\n";
      for (int i = 0; i < relevantMemories.length; i++) {
        fullContext += "- ${relevantMemories[i]}\n";
      }
      print(
        'Using both conversation context and document memories for response',
      );
    } else {
      print(
        'No relevant document memories found, using conversation context only',
      );
    }

    fullContext += "\nUSER QUERY: $text";

    // Get response from OpenAI with combined context
    final response = await openAIService.getChatResponse(fullContext);

    // Add AI response to the chat
    final aiMessage = ChatMessage(
      message: response,
      isUser: false,
      timestamp: DateTime.now(),
    );
    messages.add(aiMessage);
  }

  // Method to clear chat and start over with intro message
  void clearChat() {
    // Clear all messages and relevant memories
    messages.clear();
    relevantMemories.clear();

    // Reset context management state
    conversationSummary.value = '';
    messageIndexAfterLastSummary.value = 0;

    // Add initial greeting message
    messages.add(
      ChatMessage(
        message:
            "Hello! I'm your document assistant. How can I help you today?",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );

    print('Chat cleared. Started new conversation.');
  }
}
