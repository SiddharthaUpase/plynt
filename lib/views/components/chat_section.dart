import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/chat_controller.dart';

class ChatSection extends StatefulWidget {
  const ChatSection({super.key});

  @override
  State<ChatSection> createState() => _ChatSectionState();
}

class _ChatSectionState extends State<ChatSection>
    with TickerProviderStateMixin {
  final ChatController chatController = Get.put(ChatController());
  final TextEditingController textController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();

  late final List<AnimationController> _animationControllers;
  late final List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();

    // Create animation controllers for typing indicator
    _animationControllers = List.generate(
      3,
      (index) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 300),
      ),
    );

    // Create animations for typing indicator dots
    _animations =
        _animationControllers.map((controller) {
          return Tween<double>(begin: 0, end: -5).animate(
            CurvedAnimation(parent: controller, curve: Curves.easeInOut),
          );
        }).toList();

    // Start animations with delays to create bouncing effect
    Future.delayed(Duration(milliseconds: 100), () {
      _startTypingAnimation();
    });

    // Listen for changes in the messages list
    chatController.messages.listen((_) {
      _scrollToBottom();
    });

    // Listen for typing state changes
    chatController.isTyping.listen((isTyping) {
      if (isTyping) {
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    // Always use post-frame callback to ensure the ListView has rendered the new message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _startTypingAnimation() {
    if (!mounted) return;

    for (var i = 0; i < _animationControllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (!mounted) return;

        _animationControllers[i].forward().then((_) {
          if (!mounted) return;
          _animationControllers[i].reverse().then((_) {
            if (!mounted) return;
            _startTypingAnimation();
          });
        });
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _animationControllers) {
      controller.dispose();
    }
    textController.dispose();
    scrollController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF343541), // ChatGPT background color
      child: Stack(
        children: [
          Column(
            children: [
              // Chat messages area
              Expanded(
                child: Obx(() {
                  if (chatController.messages.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        children: [
                          // Add spacer to push content down
                          const SizedBox(height: 80),
                          // Plynt branding
                          Text(
                            'plynt',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 36),
                          // Main heading
                          Text(
                            "What can I help with?",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 100),
                          // Flexible spacer to push content up from bottom
                          Spacer(),
                          // SizedBox at bottom to create space for floating input
                          SizedBox(height: 120),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 40, // Increased top padding
                      bottom:
                          100, // Add extra padding at bottom for the floating input
                    ),
                    itemCount:
                        chatController.messages.length +
                        (chatController.isTyping.value ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Show typing indicator at the end if AI is typing
                      if (chatController.isTyping.value &&
                          index == chatController.messages.length) {
                        return _buildTypingIndicator();
                      }

                      // Show messages
                      final message = chatController.messages[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildChatBubble(
                          message: message.message,
                          isUser: message.isUser,
                          time: message.timeString,
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),

          // Floating message input area
          Positioned(
            left: 0,
            right: 0,
            bottom: 30, // Position from bottom
            child: Center(
              child: Container(
                width:
                    MediaQuery.of(context).size.width * 0.7, // Wider input box
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12, // Slightly more padding
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2D3A),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: textController,
                        focusNode: _messageFocusNode,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 1,
                        textInputAction: TextInputAction.send,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: const TextStyle(color: Color(0xFF8E8EA0)),
                          filled: false,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (text) {
                          _sendMessage();
                          // Request focus back to the input field
                          _messageFocusNode.requestFocus();
                        },
                      ),
                    ),
                    Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10A37F), // ChatGPT green color
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 16,
                        ),
                        onPressed: _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Clear chat floating button in top-right corner
          Obx(
            () =>
                chatController.messages.length > 1
                    ? Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        height: 44,
                        width: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 5,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.white,
                            size: 20,
                          ),
                          tooltip: 'Clear chat',
                          onPressed: _showClearChatConfirmation,
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    )
                    : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    final text = textController.text.trim();
    if (text.isNotEmpty) {
      chatController.sendMessage(text);
      textController.clear();
      _messageFocusNode.requestFocus();
      // Ensure we scroll to bottom after sending a message
      _scrollToBottom();
    }
  }

  Widget _buildTypingIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _buildAvatar(isUser: false),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF444654),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              _buildBounceAnimation(0),
              const SizedBox(width: 5),
              _buildBounceAnimation(1),
              const SizedBox(width: 5),
              _buildBounceAnimation(2),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBounceAnimation(int index) {
    return AnimatedBuilder(
      animation: _animationControllers[index],
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animations[index].value),
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildChatBubble({
    required String message,
    required bool isUser,
    required String time,
  }) {
    return Padding(
      padding: EdgeInsets.only(top: 8, bottom: 8),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            _buildAvatar(isUser: false),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color:
                    isUser ? const Color(0xFF10A37F) : const Color(0xFF444654),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    message,
                    style: const TextStyle(fontSize: 15, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    time,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFFBBBBC0),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 12),
            _buildAvatar(isUser: true),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar({required bool isUser}) {
    return Container(
      height: 36,
      width: 36,
      decoration: BoxDecoration(
        color: isUser ? const Color(0xFF10A37F) : const Color(0xFF444654),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          isUser ? Icons.person_outline : Icons.assistant_outlined,
          size: 20,
          color: Colors.white,
        ),
      ),
    );
  }

  void _showClearChatConfirmation() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF343541),
            title: const Text(
              'Clear conversation',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'Are you sure you want to clear this conversation? This action cannot be undone.',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              TextButton(
                onPressed: () {
                  // Clear the chat and close the dialog
                  chatController.clearChat();
                  Navigator.of(context).pop();
                },
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF10A37F),
                ),
                child: const Text(
                  'Clear',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
    );
  }
}
