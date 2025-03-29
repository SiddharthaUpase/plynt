import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../controllers/document_controller.dart';
import '../../models/document_model.dart';
import '../../views/dialogs/document_details_dialog.dart';

class DocumentCard extends StatelessWidget {
  final DocumentModel document;
  final DocumentController documentController = Get.find<DocumentController>();

  DocumentCard({super.key, required this.document});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF444654),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            // Handle document tap - Preview or download
            launchURL(document.fileUrl);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFileIcon(),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            document.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Uploaded ${_formatDate(document.createdAt)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF8E8EA0),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 32,
                      width: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF343541),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(
                          Icons.more_vert,
                          size: 16,
                          color: Colors.white70,
                        ),
                        onPressed: () {
                          _showOptions(context);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (document.tag != null && document.tag!.isNotEmpty)
                  Container(
                    decoration: BoxDecoration(
                      color: _getTagColor(document.tag!),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Text(
                      _capitalizeTag(document.tag!),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _getTagTextColor(document.tag!),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFileIcon() {
    IconData iconData;
    Color iconColor;

    switch (document.fileType.toLowerCase()) {
      case 'pdf':
        iconData = Icons.picture_as_pdf;
        iconColor = Colors.red.shade300;
        break;
      case 'document':
        iconData = Icons.article;
        iconColor = Colors.blue.shade300;
        break;
      case 'image':
        iconData = Icons.image;
        iconColor = Colors.green.shade300;
        break;
      default:
        iconData = Icons.insert_drive_file;
        iconColor = Colors.grey.shade300;
    }

    return Container(
      height: 40,
      width: 40,
      decoration: BoxDecoration(
        color: const Color(0xFF343541),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(child: Icon(iconData, size: 20, color: iconColor)),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: const BoxDecoration(
              color: Color(0xFF343541),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildOptionButton(
                  icon: Icons.visibility,
                  label: 'Preview',
                  onTap: () {
                    Navigator.pop(context);
                    launchURL(document.fileUrl);
                  },
                ),
                _buildOptionButton(
                  icon: Icons.download,
                  label: 'Download',
                  onTap: () {
                    Navigator.pop(context);
                    launchURL(document.fileUrl);
                  },
                ),
                _buildOptionButton(
                  icon: Icons.edit_note,
                  label: 'Edit Details',
                  onTap: () {
                    Navigator.pop(context);
                    _showEditDetailsDialog(context);
                  },
                ),
                _buildOptionButton(
                  icon: Icons.delete,
                  label: 'Delete',
                  isDestructive: true,
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDelete(context);
                  },
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF444654),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color:
                        isDestructive
                            ? Colors.red.shade300
                            : const Color(0xFF10A37F),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDestructive ? Colors.red.shade300 : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF343541),
            title: const Text(
              'Delete Document',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              'Are you sure you want to delete "${document.name}"?',
              style: const TextStyle(color: Color(0xFFBBBBC0)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Color(0xFF8E8EA0)),
                ),
              ),
              TextButton(
                onPressed: () {
                  documentController.deleteDocument(document.id, '');
                  Navigator.pop(context);
                },
                child: Text(
                  'Delete',
                  style: TextStyle(color: Colors.red.shade300),
                ),
              ),
            ],
          ),
    );
  }

  void _showEditDetailsDialog(BuildContext context) async {
    // Show loading dialog for initial fetch
    final loadingDialog = Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10A37F)),
      ),
    );

    Get.dialog(loadingDialog, barrierDismissible: false);

    List<Map<String, dynamic>> details = [];
    try {
      // Fetch document details
      details = await documentController.fetchDocumentDetails(document.id);
    } catch (e) {
      print('Error fetching document details: $e');
    } finally {
      // Force close dialog
      Get.back();
    }

    if (details.isEmpty) {
      Get.snackbar(
        'No Details',
        'No extracted details found for this document',
        backgroundColor: const Color(0xFF343541),
        colorText: Colors.white,
      );
      return;
    }

    // Create an Rx list to hold the details
    final RxList<Map<String, dynamic>> rxDetails =
        RxList<Map<String, dynamic>>.from(details);

    // Show edit dialog
    final result = await Get.dialog<List<Map<String, dynamic>>>(
      DocumentDetailsDialog(details: rxDetails, documentName: document.name),
      barrierDismissible: true,
    );

    // If user confirmed changes, update the document details
    if (result != null) {
      // Show a separate update loading dialog
      final dialogCompleter = Get.dialog<void>(
        Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10A37F)),
          ),
        ),
        barrierDismissible: false,
      );

      try {
        await documentController.updateDocumentDetails(document.id, result);

        // Close the dialog directly
        Get.back();

        // Wait a moment before showing success message
        await Future.delayed(Duration(milliseconds: 300));

        Get.snackbar(
          'Success',
          'Document details updated successfully',
          backgroundColor: const Color(0xFF10A37F),
          colorText: Colors.white,
        );
      } catch (e) {
        print('Error while updating document details: $e');

        // Close the dialog directly
        Get.back();

        Get.snackbar(
          'Error',
          'Failed to update document details',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  Color _getTagColor(String tag) {
    switch (tag.toLowerCase()) {
      case 'travel':
        return const Color(0xFF10A37F).withOpacity(0.2); // Green tint
      case 'finance':
        return const Color(0xFF5436DA).withOpacity(0.2); // Purple tint
      case 'education':
        return const Color(0xFFF89820).withOpacity(0.2); // Orange tint
      case 'health':
        return Colors.red.withOpacity(0.2);
      case 'personal':
        return Colors.blue.withOpacity(0.2);
      case 'work':
        return Colors.amber.withOpacity(0.2);
      case 'legal':
        return Colors.indigo.withOpacity(0.2);
      default:
        return const Color(0xFF343541).withOpacity(0.5);
    }
  }

  Color _getTagTextColor(String tag) {
    switch (tag.toLowerCase()) {
      case 'travel':
        return const Color(0xFF10A37F); // Green
      case 'finance':
        return const Color(0xFF5436DA); // Purple
      case 'education':
        return const Color(0xFFF89820); // Orange
      case 'health':
        return Colors.red.shade300;
      case 'personal':
        return Colors.blue.shade300;
      case 'work':
        return Colors.amber.shade300;
      case 'legal':
        return Colors.indigo.shade300;
      default:
        return Colors.white;
    }
  }

  String _formatDate(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy').format(dateTime);
  }

  String _capitalizeTag(String tag) {
    if (tag.isEmpty) return '';
    return tag[0].toUpperCase() + tag.substring(1);
  }

  void launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
