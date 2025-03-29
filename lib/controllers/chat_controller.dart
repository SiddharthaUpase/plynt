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

  // New properties for memory confirmation
  final RxBool isAwaitingMemoryConfirmation = false.obs;
  final RxString pendingMemoryContent = ''.obs;

  // Number of previous messages to include as context
  final int contextWindowSize = 6;

  ChatController({String apiKey = ''})
    : openAIService = OpenAIService(apiKey: apiKey);

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

      // Check if we're waiting for confirmation to add to memory
      if (isAwaitingMemoryConfirmation.value) {
        await _handleMemoryConfirmation(text, userId);
      } else {
        // Categorize the message as query or statement
        final messageType = await openAIService.categorizeMessage(text);
        print('Message categorized as: $messageType');

        if (messageType == "query") {
          // For queries, determine if memory search is needed
          final needsMemorySearch = await openAIService.requiresMemorySearch(
            text,
          );
          print('Query needs memory search? $needsMemorySearch');

          if (needsMemorySearch) {
            // Full memory search flow for relevant queries
            await _handleQuery(text, userId);
          } else {
            // Simple direct response for conversational queries
            final response = await openAIService.getChatResponse(text);

            // Add AI response to the chat
            final aiMessage = ChatMessage(
              message: response,
              isUser: false,
              timestamp: DateTime.now(),
            );
            messages.add(aiMessage);
          }
        } else {
          // For statements, check if worth saving before asking
          final isWorthSaving = await openAIService.isWorthSaving(text);
          print('Statement worth saving? $isWorthSaving');

          if (isWorthSaving) {
            // Statement is valuable, ask for confirmation
            pendingMemoryContent.value = text;
            isAwaitingMemoryConfirmation.value = true;

            final confirmationMessage = ChatMessage(
              message:
                  "This information seems valuable. Would you like me to remember it for future reference?",
              isUser: false,
              timestamp: DateTime.now(),
            );
            messages.add(confirmationMessage);
          } else {
            // Statement isn't valuable, just respond normally
            final response = await openAIService.getChatResponse(text);

            // Add AI response to the chat
            final aiMessage = ChatMessage(
              message: response,
              isUser: false,
              timestamp: DateTime.now(),
            );
            messages.add(aiMessage);
          }
        }
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

  // Handle memory confirmation response
  Future<void> _handleMemoryConfirmation(String response, String userId) async {
    // Get the content we're potentially storing
    final contentToStore = pendingMemoryContent.value;

    // Reset confirmation state
    isAwaitingMemoryConfirmation.value = false;
    pendingMemoryContent.value = '';

    // Use OpenAI to determine if response is positive
    final isAffirmative = await openAIService.isPositiveResponse(response);
    print(
      'Confirmation response interpreted as: ${isAffirmative ? "positive" : "negative"}',
    );

    if (isAffirmative) {
      // Get conversation context
      final context = _getConversationContext();
      print('Saving context to memory: $context');

      // Add the memory with context
      final result = await mem0Service.addMemory(userId, context);

      String responseMessage;
      if (result['success']) {
        responseMessage =
            "I've added that to my memory. I'll remember this conversation for future reference.";
      } else {
        responseMessage =
            "I tried to save that to memory, but encountered an issue. Please try again later.";
      }

      // Add confirmation message
      messages.add(
        ChatMessage(
          message: responseMessage,
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    } else {
      // User declined saving to memory
      messages.add(
        ChatMessage(
          message: "No problem. I won't remember that.",
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    }

    // Always respond to the statement regardless of save decision
    final aiResponse = await openAIService.getChatResponse(contentToStore);

    // Add AI response to the chat
    final aiMessage = ChatMessage(
      message: aiResponse,
      isUser: false,
      timestamp: DateTime.now(),
    );
    messages.add(aiMessage);
  }

  // Handle query flow (refactored from existing code)
  Future<void> _handleQuery(String text, String userId) async {
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

    // Prepare context with memories
    String contextWithMemories = '';
    if (relevantMemories.isNotEmpty) {
      contextWithMemories = "Here's what I know from your documents:\n";
      for (int i = 0; i < relevantMemories.length; i++) {
        contextWithMemories += "- ${relevantMemories[i]}\n";
      }
      contextWithMemories +=
          "\nPlease use this information to answer my question: $text";

      print('Using context with memories for response');
    } else {
      contextWithMemories = text;
      print('No relevant memories found, using original query');
    }

    // Get response from OpenAI with memory context
    final response = await openAIService.getChatResponse(contextWithMemories);

    // Add AI response to the chat
    final aiMessage = ChatMessage(
      message: response,
      isUser: false,
      timestamp: DateTime.now(),
    );
    messages.add(aiMessage);
  }
}
