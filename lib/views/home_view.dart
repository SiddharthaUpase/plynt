import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/document_controller.dart';
import 'components/sidebar.dart';
import 'components/document_list.dart';
import 'components/chat_section.dart';

class HomeView extends GetView<DocumentController> {
  HomeView({super.key});

  final AuthController authController = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    // Make sure to refresh documents when this page is shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchDocuments();
    });

    return Scaffold(
      backgroundColor: const Color(0xFF202123),
      body: Stack(
        children: [
          Row(
            children: [
              // Sidebar
              Sidebar(),

              // Main content
              Expanded(
                child: Column(
                  children: [
                    // Content area - show either document list or chat based on selection
                    Expanded(
                      child: Obx(() {
                        if (controller.selectedTag.value == 'chat') {
                          return const ChatSection();
                        } else {
                          return DocumentList();
                        }
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Processing status overlay
          Obx(
            () =>
                controller.isProcessing.value
                    ? _buildProcessingOverlay()
                    : const SizedBox.shrink(),
          ),
        ],
      ),
      floatingActionButton: Obx(
        () =>
            controller.selectedTag.value != 'chat'
                ? Container(
                  height: 56,
                  width: 56,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade700,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed:
                        controller.isUploading.value
                            ? null
                            : controller.pickAndUploadFile,
                    icon:
                        controller.isUploading.value
                            ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : const Icon(Icons.add, color: Colors.white),
                    tooltip: 'Upload Document',
                    iconSize: 30,
                  ),
                )
                : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildProcessingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Processing Document',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              // Main status message
              Obx(
                () => Text(
                  controller.processingStatus.value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 16),

              // Progress steps
              Obx(() => _buildStepIndicator()),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      width: 300,
      child: Column(
        children: [
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value:
                  controller.processingStep.value /
                  controller.totalProcessingSteps.value,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
            ),
          ),

          const SizedBox(height: 8),

          // Step counter
          Text(
            'Step ${controller.processingStep.value} of ${controller.totalProcessingSteps.value}',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),

          // Processing steps list
          const SizedBox(height: 16),
          _buildProcessingStepsList(),
        ],
      ),
    );
  }

  Widget _buildProcessingStepsList() {
    final currentStep = controller.processingStep.value;

    return Column(
      children: [
        _buildStep(1, 'Preparing document', currentStep >= 1),
        _buildStep(2, 'Uploading to storage', currentStep >= 2),
        _buildStep(3, 'Analyzing with AI', currentStep >= 3),
        _buildStep(4, 'Storing document knowledge', currentStep >= 4),
        _buildStep(5, 'Saving document information', currentStep >= 5),
      ],
    );
  }

  Widget _buildStep(int step, String description, bool isCompleted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted ? Colors.green : Colors.grey.shade300,
            ),
            child:
                isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : Text(
                      '$step',
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
          ),
          const SizedBox(width: 12),
          Text(
            description,
            style: TextStyle(
              color: isCompleted ? Colors.black : Colors.grey.shade600,
              fontWeight: isCompleted ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Obx(() {
              final selectedTag = controller.selectedTag.value;
              final title =
                  selectedTag == 'all'
                      ? 'All Documents'
                      : selectedTag == 'chat'
                      ? 'Chat'
                      : _capitalizeTag(selectedTag);

              return Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              );
            }),
            const Spacer(),
            if (controller.selectedTag.value != 'chat') _buildSearchBar(),
            const SizedBox(width: 16),
            if (controller.selectedTag.value != 'chat') _buildSortButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SizedBox(
          width: 300,
          child: Row(
            children: [
              const Icon(Icons.search, color: Colors.grey, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search documents...',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortButton() {
    return Container(
      height: 40,
      width: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: IconButton(
        icon: const Icon(Icons.sort, size: 20),
        onPressed: () {
          // Show sort options
        },
      ),
    );
  }

  String _capitalizeTag(String tag) {
    if (tag.isEmpty) return '';
    return tag[0].toUpperCase() + tag.substring(1);
  }
}
