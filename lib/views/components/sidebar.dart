import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/document_controller.dart';

class Sidebar extends GetView<DocumentController> {
  Sidebar({super.key});

  final AuthController authController = Get.find<AuthController>();
  final RxBool isChatOpen = false.obs;

  @override
  Widget build(BuildContext context) {
    // Ensure document tags are refreshed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.tags.isEmpty && controller.documents.isNotEmpty) {
        // Extract unique tags if they haven't been loaded yet
        final uniqueTags = <String>{};
        for (var doc in controller.documents) {
          if (doc.tag != null && doc.tag!.isNotEmpty) {
            uniqueTags.add(doc.tag!);
          }
        }
        controller.tags.value = uniqueTags.toList()..sort();
      }
    });

    return Container(
      width: 250,
      color: const Color(0xFF202123), // Dark background like ChatGPT
      child: Column(
        children: [
          // Brand logo at the top
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  'plynt',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: Colors.grey.shade800),
          const SizedBox(height: 16),

          // Chat section - primary
          Obx(
            () => _buildNavItem(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'Chat',
              isSelected: isChatOpen.value,
              onTap: () {
                isChatOpen.value = true;
                controller.setSelectedTag('chat');
              },
            ),
          ),

          Obx(
            () => _buildNavItem(
              icon: Icons.description_outlined,
              title: 'All Documents',
              isSelected:
                  controller.selectedTag.value == 'all' && !isChatOpen.value,
              onTap: () {
                isChatOpen.value = false;
                controller.setSelectedTag('all');
              },
            ),
          ),

          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Text(
                  'CATEGORIES',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8E8EA0),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.add, size: 16, color: Colors.white70),
                  onPressed: () {},
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Obx(() {
              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 5),
                itemCount: controller.tags.length,
                itemBuilder: (context, index) {
                  final tag = controller.tags[index];
                  return Obx(
                    () => _buildNavItem(
                      icon: _getIconForTag(tag),
                      title: _capitalizeTag(tag),
                      isSelected:
                          controller.selectedTag.value == tag &&
                          !isChatOpen.value,
                      onTap: () {
                        isChatOpen.value = false;
                        controller.setSelectedTag(tag);
                      },
                    ),
                  );
                },
              );
            }),
          ),
          Divider(height: 1, thickness: 1, color: Colors.grey.shade800),

          // Profile info moved to bottom
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              children: [
                Container(
                  height: 36,
                  width: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: const Color(0xFF444654),
                  ),
                  child: Center(
                    child: Obx(() {
                      final user = authController.currentUser;
                      final initial =
                          user?.name?.isNotEmpty == true
                              ? user!.name![0].toUpperCase()
                              : user?.email[0].toUpperCase() ?? 'U';
                      return Text(
                        initial,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Obx(() {
                    final user = authController.currentUser;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'User',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          user?.email ?? '',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF8E8EA0),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),

          _buildNavItem(
            icon: Icons.logout,
            title: 'Logout',
            onTap: () => authController.signOut(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String title,
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: isSelected ? const Color(0xFF343541) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          hoverColor: const Color(0xFF343541).withOpacity(0.5),
          splashColor: Colors.white10,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? Colors.white : Colors.grey[400],
                ),
                const SizedBox(width: 15),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? Colors.white : Colors.grey[300],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconForTag(String tag) {
    switch (tag.toLowerCase()) {
      case 'travel':
        return Icons.flight_outlined;
      case 'finance':
        return Icons.account_balance_outlined;
      case 'education':
        return Icons.school_outlined;
      case 'health':
        return Icons.medical_services_outlined;
      case 'personal':
        return Icons.person_outline;
      case 'work':
        return Icons.work_outline;
      case 'legal':
        return Icons.gavel_outlined;
      case 'receipts':
        return Icons.receipt_outlined;
      case 'housing':
        return Icons.home_outlined;
      default:
        return Icons.folder_outlined;
    }
  }

  String _capitalizeTag(String tag) {
    if (tag.isEmpty) return '';
    return tag[0].toUpperCase() + tag.substring(1);
  }
}
