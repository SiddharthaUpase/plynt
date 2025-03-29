import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/document_controller.dart';
import '../../models/document_model.dart';
import 'document_card.dart';

class DocumentList extends GetView<DocumentController> {
  DocumentList({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF2D2D3A), // Dark background color
      child: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10A37F)),
            ),
          );
        }

        // Show processing indicator if document is being processed
        if (controller.isProcessing.value) {
          return _buildProcessingIndicator();
        }

        final filteredDocs = controller.getFilteredDocuments();

        if (filteredDocs.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            final document = filteredDocs[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: DocumentCard(document: document),
            );
          },
        );
      }),
    );
  }

  Widget _buildProcessingIndicator() {
    return Container(
      color: const Color(0xFF2D2D3A), // Dark background color
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: const Color(0xFF444654).withOpacity(0.8),
                    borderRadius: BorderRadius.circular(70),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF10A37F),
                    ),
                    strokeWidth: 6,
                    value:
                        controller.processingStep.value /
                        controller.totalProcessingSteps.value,
                  ),
                ),
                Column(
                  children: [
                    Text(
                      "${(controller.processingStep.value / controller.totalProcessingSteps.value * 100).toInt()}%",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Step ${controller.processingStep.value}/${controller.totalProcessingSteps.value}",
                      style: const TextStyle(
                        color: Color(0xFF8E8EA0),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 40),
            Container(
              width: 400,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF444654).withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                controller.processingStatus.value,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final selectedTag = controller.selectedTag.value;
    final hasDocuments = controller.documents.isNotEmpty;

    return Container(
      color: const Color(0xFF2D2D3A), // Dark background color
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Brand logo
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

            hasDocuments
                ? Icon(
                  Icons.filter_list,
                  size: 50,
                  color: const Color(0xFF8E8EA0).withOpacity(0.6),
                )
                : Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFF444654).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: Icon(
                    Icons.upload_file_outlined,
                    size: 50,
                    color: const Color(0xFF8E8EA0).withOpacity(0.8),
                  ),
                ),
            const SizedBox(height: 24),
            Text(
              hasDocuments
                  ? 'No documents with tag "$selectedTag"'
                  : 'Upload your first document',
              style: const TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: 400,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                hasDocuments
                    ? 'Try selecting a different category from the sidebar'
                    : 'Upload documents to start analyzing and chatting with your content',
                style: const TextStyle(fontSize: 16, color: Color(0xFF8E8EA0)),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 40),
            if (!hasDocuments)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10A37F).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () => controller.pickAndUploadFile(),
                  icon: const Icon(Icons.upload_file, size: 22),
                  label: const Text(
                    'Upload Document',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10A37F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
