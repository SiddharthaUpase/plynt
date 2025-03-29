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
      child: Column(
        children: [
          // Chat messages area
          Expanded(
            child: Obx(() {
              if (chatController.messages.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Plynt branding at the top
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
                      const SizedBox(height: 20),
                      // Custom input-like container
                      Container(
                        width: 600,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF40414F),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Ask anything',
                                style: TextStyle(
                                  color: Color(0xFF8E8EA0),
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Container(
                              height: 36,
                              width: 36,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Icon(
                                Icons.mic,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              }

              return ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
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

          // Message input area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2D2D3A),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 5,
                  offset: const Offset(0, -2),
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
                      filled: true,
                      fillColor: const Color(0xFF40414F),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                    onSubmitted: (text) {
                      _sendMessage();
                      // Request focus back to the input field
                      _messageFocusNode.requestFocus();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10A37F), // ChatGPT green color
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
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
    return Row(
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
              color: isUser ? const Color(0xFF10A37F) : const Color(0xFF444654),
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
                Text(
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
        if (isUser) ...[const SizedBox(width: 12), _buildAvatar(isUser: true)],
      ],
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
}
