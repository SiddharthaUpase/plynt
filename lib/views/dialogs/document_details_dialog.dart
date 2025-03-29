import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DocumentDetailsDialog extends StatefulWidget {
  final RxList<Map<String, dynamic>> details;
  final String documentName;

  const DocumentDetailsDialog({
    super.key,
    required this.details,
    required this.documentName,
  });

  @override
  State<DocumentDetailsDialog> createState() => _DocumentDetailsDialogState();
}

class _DocumentDetailsDialogState extends State<DocumentDetailsDialog> {
  late List<TextEditingController> _controllers;
  final TextEditingController _newDetailController = TextEditingController();
  bool _isAddingNewDetail = false;

  @override
  void initState() {
    super.initState();
    // Create controllers for each existing detail
    _controllers = List.generate(
      widget.details.length,
      (index) => TextEditingController(
        text: widget.details[index]['memory_content'] ?? '',
      ),
    );
  }

  @override
  void dispose() {
    // Dispose all controllers
    for (final controller in _controllers) {
      controller.dispose();
    }
    _newDetailController.dispose();
    super.dispose();
  }

  void _addNewDetail() {
    final text = _newDetailController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        widget.details.add({'memory_content': text});
        _controllers.add(TextEditingController(text: text));
        _newDetailController.clear();
        _isAddingNewDetail = false;
      });
    }
  }

  void _removeDetail(int index) {
    setState(() {
      widget.details.removeAt(index);
      _controllers[index].dispose();
      _controllers.removeAt(index);
    });
  }

  void _updateDetail(int index, String text) {
    if (text.trim().isNotEmpty) {
      final detail = widget.details[index];
      detail['memory_content'] = text.trim();
      widget.details[index] = detail;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF343541),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF444654),
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Extracted Details',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Edit the extracted details for "${widget.documentName}"',
                    style: TextStyle(color: Colors.grey[300], fontSize: 14),
                  ),
                ],
              ),
            ),

            // Details list
            Expanded(
              child: Obx(() {
                if (widget.details.isEmpty) {
                  return Center(
                    child: Text(
                      'No details extracted',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: widget.details.length,
                  itemBuilder: (context, index) {
                    return _buildDetailItem(index);
                  },
                );
              }),
            ),

            // Add new detail section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade800, width: 1),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isAddingNewDetail)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: TextField(
                        controller: _newDetailController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Enter a new detail...',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade700),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade700),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF10A37F),
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(
                              Icons.check,
                              color: Color(0xFF10A37F),
                            ),
                            onPressed: _addNewDetail,
                          ),
                        ),
                        onSubmitted: (_) => _addNewDetail(),
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _isAddingNewDetail = !_isAddingNewDetail;
                            if (!_isAddingNewDetail) {
                              _newDetailController.clear();
                            }
                          });
                        },
                        icon: Icon(
                          _isAddingNewDetail ? Icons.close : Icons.add,
                          size: 18,
                          color:
                              _isAddingNewDetail
                                  ? Colors.red.shade300
                                  : const Color(0xFF10A37F),
                        ),
                        label: Text(
                          _isAddingNewDetail ? 'Cancel' : 'Add Detail',
                          style: TextStyle(
                            color:
                                _isAddingNewDetail
                                    ? Colors.red.shade300
                                    : const Color(0xFF10A37F),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () => Get.back(),
                            child: Text(
                              'Cancel',
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              // Ensure all changes are saved
                              for (int i = 0; i < _controllers.length; i++) {
                                _updateDetail(i, _controllers[i].text);
                              }
                              // Return the updated list
                              Get.back(result: widget.details.toList());
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10A37F),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                            ),
                            child: const Text('Save'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF444654),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controllers[index],
              style: const TextStyle(color: Colors.white),
              maxLines: null,
              decoration: InputDecoration(
                hintText: 'Enter detail...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFF10A37F),
                    width: 1,
                  ),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 20,
                  ),
                  onPressed: () => _removeDetail(index),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              onChanged: (value) => _updateDetail(index, value),
            ),
          ],
        ),
      ),
    );
  }
}
