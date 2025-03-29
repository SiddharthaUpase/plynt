import 'package:flutter/material.dart';
import 'package:get/get.dart';

class KeypointsDialog extends StatefulWidget {
  final RxList<String> keyPoints;

  const KeypointsDialog({super.key, required this.keyPoints});

  @override
  State<KeypointsDialog> createState() => _KeypointsDialogState();
}

class _KeypointsDialogState extends State<KeypointsDialog> {
  late List<TextEditingController> _controllers;
  final TextEditingController _newPointController = TextEditingController();
  bool _isAddingNewPoint = false;

  @override
  void initState() {
    super.initState();
    // Create controllers for each existing key point
    _controllers = List.generate(
      widget.keyPoints.length,
      (index) => TextEditingController(text: widget.keyPoints[index]),
    );
  }

  @override
  void dispose() {
    // Dispose all controllers
    for (final controller in _controllers) {
      controller.dispose();
    }
    _newPointController.dispose();
    super.dispose();
  }

  void _addNewKeyPoint() {
    final text = _newPointController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        widget.keyPoints.add(text);
        _controllers.add(TextEditingController(text: text));
        _newPointController.clear();
        _isAddingNewPoint = false;
      });
    }
  }

  void _removeKeyPoint(int index) {
    setState(() {
      widget.keyPoints.removeAt(index);
      _controllers[index].dispose();
      _controllers.removeAt(index);
    });
  }

  void _updateKeyPoint(int index, String text) {
    if (text.trim().isNotEmpty) {
      widget.keyPoints[index] = text.trim();
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
                    'Review Extracted Information',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We found the following key points in your document. You can edit, remove, or add new ones.',
                    style: TextStyle(color: Colors.grey[300], fontSize: 14),
                  ),
                ],
              ),
            ),

            // Key points list
            Expanded(
              child: Obx(() {
                if (widget.keyPoints.isEmpty) {
                  return Center(
                    child: Text(
                      'No key points extracted',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: widget.keyPoints.length,
                  itemBuilder: (context, index) {
                    return _buildKeyPointItem(index);
                  },
                );
              }),
            ),

            // Add new key point section
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
                  if (_isAddingNewPoint)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: TextField(
                        controller: _newPointController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Enter a new key point...',
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
                            onPressed: _addNewKeyPoint,
                          ),
                        ),
                        onSubmitted: (_) => _addNewKeyPoint(),
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _isAddingNewPoint = !_isAddingNewPoint;
                            if (!_isAddingNewPoint) {
                              _newPointController.clear();
                            }
                          });
                        },
                        icon: Icon(
                          _isAddingNewPoint ? Icons.close : Icons.add,
                          size: 18,
                          color:
                              _isAddingNewPoint
                                  ? Colors.red.shade300
                                  : const Color(0xFF10A37F),
                        ),
                        label: Text(
                          _isAddingNewPoint ? 'Cancel' : 'Add Key Point',
                          style: TextStyle(
                            color:
                                _isAddingNewPoint
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
                                _updateKeyPoint(i, _controllers[i].text);
                              }
                              // Return the updated list
                              Get.back(result: widget.keyPoints.toList());
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
                            child: const Text('Confirm'),
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

  Widget _buildKeyPointItem(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF444654),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge with number
          Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.only(top: 12, left: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF10A37F),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Editable text field
          Expanded(
            child: TextField(
              controller: _controllers[index],
              style: const TextStyle(color: Colors.white),
              maxLines: null,
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 4,
                ),
                hintText: 'Enter key point...',
                hintStyle: TextStyle(color: Colors.grey[500]),
              ),
              onChanged: (text) => _updateKeyPoint(index, text),
            ),
          ),
          // Delete button
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: Colors.red.shade300,
              size: 20,
            ),
            onPressed: () => _removeKeyPoint(index),
          ),
        ],
      ),
    );
  }
}
