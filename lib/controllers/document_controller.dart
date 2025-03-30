import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart' show Colors;
import 'package:get/get.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/document_model.dart';
import '../services/openai_service.dart';
import '../services/mem0_service.dart';
import '../views/dialogs/keypoints_dialog.dart';
import 'auth_controller.dart';

// Conditionally import file_picker based on platform
import 'package:file_picker/file_picker.dart'
    if (dart.library.js) 'package:file_picker/file_picker.dart';

class DocumentController extends GetxController {
  final supabase = Supabase.instance.client;
  final authController = Get.find<AuthController>();
  final OpenAIService openAIService;
  final mem0Service = Mem0Service();

  final RxList<DocumentModel> documents = <DocumentModel>[].obs;
  final RxList<String> tags = <String>[].obs;
  final RxString selectedTag = 'chat'.obs;
  final RxBool isLoading = false.obs;
  final RxBool isUploading = false.obs;

  // Key points for current document being processed
  final RxList<String> extractedKeyPoints = <String>[].obs;

  // Processing status tracking
  final RxString processingStatus = ''.obs;
  final RxInt processingStep = 0.obs;
  final RxInt totalProcessingSteps = 6.obs;
  final RxBool isProcessing = false.obs;

  DocumentController() : openAIService = OpenAIService();

  @override
  void onInit() {
    super.onInit();

    print('API Key: ${openAIService.apiKey}');

    //add a delay so that the user is fetched
    Future.delayed(const Duration(milliseconds: 600), () {
      fetchDocuments();
    });
  }

  // Update processing status with step information
  void _updateProcessingStatus(String status, int step, {int? totalSteps}) {
    processingStatus.value = status;
    processingStep.value = step;
    if (totalSteps != null) {
      totalProcessingSteps.value = totalSteps;
    }
  }

  // Reset processing status
  void _resetProcessingStatus() {
    isProcessing.value = false;
    processingStatus.value = '';
    processingStep.value = 0;
    extractedKeyPoints.clear();
  }

  // Fetch all documents for the current user
  Future<void> fetchDocuments() async {
    try {
      print('Fetching documents');
      isLoading.value = true;
      final user = authController.currentUser;
      if (user != null) {
        print('User found: ${user.id}');
        final data = await supabase
            .from('documents')
            .select()
            .eq('user_id', user.id)
            .order('created_at', ascending: false);

        documents.value = List<DocumentModel>.from(
          data.map((doc) => DocumentModel.fromJson(doc)).toList(),
        );

        // Extract unique tags
        final uniqueTags = <String>{};
        for (var doc in documents) {
          if (doc.tag != null && doc.tag!.isNotEmpty) {
            uniqueTags.add(doc.tag!);
          }
        }
        tags.value = uniqueTags.toList()..sort();
      } else {
        print('No user found');
      }
    } catch (e) {
      print('Error fetching documents: $e');
      Get.snackbar('Error', 'Failed to fetch documents');
    } finally {
      isLoading.value = false;
    }
  }

  // Filter documents by tag
  List<DocumentModel> getFilteredDocuments() {
    if (selectedTag.value == 'all' || selectedTag.value == 'chat') {
      return documents;
    } else {
      return documents.where((doc) => doc.tag == selectedTag.value).toList();
    }
  }

  // Set selected tag
  void setSelectedTag(String tag) {
    selectedTag.value = tag;
  }

  // Pick and upload a file
  Future<void> pickAndUploadFile() async {
    try {
      if (!kIsWeb && !Platform.isAndroid && !Platform.isIOS) {
        Get.snackbar(
          'Not Supported',
          'File picking is not supported on this platform',
        );
        return;
      }

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        if (kIsWeb) {
          // For web, use bytes
          if (file.bytes != null) {
            await uploadBytes(file.bytes!, file.name);
          }
        } else {
          // For mobile platforms
          if (file.path != null) {
            final fileObj = File(file.path!);
            await uploadFile(fileObj, file.name);
          }
        }
      }
    } catch (e) {
      print('Error picking file: $e');
      Get.snackbar('Error', 'Failed to pick file');
    }
  }

  // Upload bytes (for web)
  Future<void> uploadBytes(Uint8List bytes, String fileName) async {
    try {
      isUploading.value = true;
      isProcessing.value = true;
      _updateProcessingStatus('Preparing document...', 1, totalSteps: 6);

      final user = authController.currentUser;

      if (user == null) {
        Get.snackbar('Error', 'You must be logged in to upload files');
        return;
      }

      final fileExtension = path.extension(fileName).toLowerCase();
      final fileType = _getFileType(fileExtension);

      // Generate a unique file name
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath = 'documents/${user.id}/$timestamp$fileExtension';

      _updateProcessingStatus('Uploading to storage...', 2);
      // Upload to Supabase Storage
      await supabase.storage
          .from('documents')
          .uploadBinary(
            storagePath,
            bytes,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      // Get the public URL
      final fileUrl = supabase.storage
          .from('documents')
          .getPublicUrl(storagePath);

      // Convert file bytes to base64
      final base64FileContent = base64Encode(bytes);

      _updateProcessingStatus('Analyzing document content with AI...', 3);
      // Generate document info using OpenAI
      final documentInfo = await openAIService.generateDocumentInfo(
        fileName,
        fileType,
        base64FileContent,
      );

      // Print the OpenAI response
      print('OpenAI Response: $documentInfo');

      // Extract key points and show to user for confirmation
      List<String> keyPoints = [];
      if (documentInfo.containsKey('key_points')) {
        final keyPointsJson = documentInfo['key_points'] ?? '[]';
        final List<dynamic> extractedPoints = jsonDecode(keyPointsJson);
        keyPoints = extractedPoints.map((item) => item.toString()).toList();

        // Update the observable list for the UI
        extractedKeyPoints.assignAll(keyPoints);

        _updateProcessingStatus('Review extracted information...', 4);

        // Show dialog for user to confirm/edit key points
        final confirmedKeyPoints = await Get.dialog<List<String>>(
          KeypointsDialog(keyPoints: extractedKeyPoints),
          barrierDismissible: false,
        );

        // If user confirmed key points, use those instead
        if (confirmedKeyPoints != null) {
          keyPoints = confirmedKeyPoints;
          print('User confirmed ${keyPoints.length} key points');
        } else {
          // User canceled
          _resetProcessingStatus();
          isUploading.value = false;
          return;
        }
      }

      // Process key points and store in Mem0
      try {
        if (keyPoints.isNotEmpty) {
          final pointsCount = keyPoints.length;
          _updateProcessingStatus(
            'Storing document knowledge ($pointsCount items)...',
            5,
          );

          print('Storing $pointsCount memories in Mem0');

          // Use user's email as Mem0 user ID
          final userId = user.email ?? user.id;

          // Add all key points and get their memory IDs
          final memoryResults = await mem0Service.addMemories(
            userId,
            keyPoints,
          );

          // Generate tag using OpenAI
          final tag =
              documentInfo.containsKey('tag') && documentInfo['tag'] != null
                  ? documentInfo['tag']
                  : await openAIService.generateTagForDocument(
                    fileName,
                    fileType,
                  );

          _updateProcessingStatus('Finalizing document upload...', 6);

          // Insert document metadata into database
          final documentData =
              await supabase
                  .from('documents')
                  .insert({
                    'name': fileName,
                    'file_url': fileUrl,
                    'file_type': fileType,
                    'tag': tag,
                    'user_id': user.id,
                    'created_at': DateTime.now().toIso8601String(),
                  })
                  .select('id')
                  .single();

          final documentId = documentData['id'];

          // Store document-memory associations
          print('Storing ${memoryResults.length} document-memory associations');
          for (final memoryResult in memoryResults) {
            if (memoryResult['memory_id'] != null &&
                memoryResult['memory_id'].isNotEmpty) {
              // Make sure we have the content from the original keypoint
              final memoryContent = memoryResult['content'] ?? '';

              if (memoryContent.isNotEmpty) {
                await supabase.from('document_memories').insert({
                  'document_id': documentId,
                  'memory_id': memoryResult['memory_id'],
                  'memory_content': memoryContent,
                });
              } else {
                print(
                  'Warning: Empty memory content for ID: ${memoryResult['memory_id']}',
                );
              }
            }
          }

          print('Stored ${memoryResults.length} document-memory associations');
        }
      } catch (e) {
        print('Error storing memories in Mem0: $e');
      }

      // If no key points were processed, we still need to save the document
      if (keyPoints.isEmpty) {
        _updateProcessingStatus('Finalizing document upload...', 6);

        // Generate tag using OpenAI
        final tag =
            documentInfo.containsKey('tag') && documentInfo['tag'] != null
                ? documentInfo['tag']
                : await openAIService.generateTagForDocument(
                  fileName,
                  fileType,
                );

        // Insert document metadata into database
        await supabase.from('documents').insert({
          'name': fileName,
          'file_url': fileUrl,
          'file_type': fileType,
          'tag': tag,
          'user_id': user.id,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // Refresh the documents list
      await fetchDocuments();

      Get.snackbar('Success', 'File uploaded successfully');
    } catch (e) {
      print('Error uploading file: $e');
      Get.snackbar('Error', 'Failed to upload file: $e');
    } finally {
      isUploading.value = false;
      _resetProcessingStatus();
    }
  }

  // Upload a file to Supabase storage and save metadata
  Future<void> uploadFile(File file, String fileName) async {
    try {
      isUploading.value = true;
      isProcessing.value = true;
      _updateProcessingStatus('Preparing document...', 1, totalSteps: 6);

      final user = authController.currentUser;

      if (user == null) {
        Get.snackbar('Error', 'You must be logged in to upload files');
        return;
      }

      final fileExtension = path.extension(fileName).toLowerCase();
      final fileType = _getFileType(fileExtension);

      // Generate a unique file name
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath = 'documents/${user.id}/$timestamp$fileExtension';

      // Read file as bytes
      final fileBytes = await file.readAsBytes();

      _updateProcessingStatus('Uploading to storage...', 2);
      // Upload to Supabase Storage
      await supabase.storage
          .from('documents')
          .uploadBinary(
            storagePath,
            fileBytes,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      // Get the public URL
      final fileUrl = supabase.storage
          .from('documents')
          .getPublicUrl(storagePath);

      // Convert file bytes to base64
      final base64FileContent = base64Encode(fileBytes);

      _updateProcessingStatus('Analyzing document content with AI...', 3);
      // Generate document info using OpenAI
      final documentInfo = await openAIService.generateDocumentInfo(
        fileName,
        fileType,
        base64FileContent,
      );

      // Print the OpenAI response
      print('OpenAI Response: $documentInfo');

      // Extract key points and show to user for confirmation
      List<String> keyPoints = [];
      if (documentInfo.containsKey('key_points')) {
        final keyPointsJson = documentInfo['key_points'] ?? '[]';
        final List<dynamic> extractedPoints = jsonDecode(keyPointsJson);
        keyPoints = extractedPoints.map((item) => item.toString()).toList();

        // Update the observable list for the UI
        extractedKeyPoints.assignAll(keyPoints);

        _updateProcessingStatus('Review extracted information...', 4);

        // Show dialog for user to confirm/edit key points
        final confirmedKeyPoints = await Get.dialog<List<String>>(
          KeypointsDialog(keyPoints: extractedKeyPoints),
          barrierDismissible: false,
        );

        // If user confirmed key points, use those instead
        if (confirmedKeyPoints != null) {
          keyPoints = confirmedKeyPoints;
          print('User confirmed ${keyPoints.length} key points');
        } else {
          // User canceled
          _resetProcessingStatus();
          isUploading.value = false;
          return;
        }
      }

      // Process key points and store in Mem0
      try {
        if (keyPoints.isNotEmpty) {
          final pointsCount = keyPoints.length;
          _updateProcessingStatus(
            'Storing document knowledge ($pointsCount items)...',
            5,
          );

          print('Storing $pointsCount memories in Mem0');

          // Use user's email as Mem0 user ID
          final userId = user.email ?? user.id;

          // Add all key points and get their memory IDs
          final memoryResults = await mem0Service.addMemories(
            userId,
            keyPoints,
          );

          // Generate tag using OpenAI
          final tag =
              documentInfo.containsKey('tag') && documentInfo['tag'] != null
                  ? documentInfo['tag']
                  : await openAIService.generateTagForDocument(
                    fileName,
                    fileType,
                  );

          _updateProcessingStatus('Finalizing document upload...', 6);

          // Insert document metadata into database
          final documentData =
              await supabase
                  .from('documents')
                  .insert({
                    'name': fileName,
                    'file_url': fileUrl,
                    'file_type': fileType,
                    'tag': tag,
                    'user_id': user.id,
                    'created_at': DateTime.now().toIso8601String(),
                  })
                  .select('id')
                  .single();

          final documentId = documentData['id'];

          // Store document-memory associations
          print('Storing ${memoryResults.length} document-memory associations');
          for (final memoryResult in memoryResults) {
            if (memoryResult['memory_id'] != null &&
                memoryResult['memory_id'].isNotEmpty) {
              // Make sure we have the content from the original keypoint
              final memoryContent = memoryResult['content'] ?? '';

              if (memoryContent.isNotEmpty) {
                await supabase.from('document_memories').insert({
                  'document_id': documentId,
                  'memory_id': memoryResult['memory_id'],
                  'memory_content': memoryContent,
                });
              } else {
                print(
                  'Warning: Empty memory content for ID: ${memoryResult['memory_id']}',
                );
              }
            }
          }

          print('Stored ${memoryResults.length} document-memory associations');
        }
      } catch (e) {
        print('Error storing memories in Mem0: $e');
      }

      // If no key points were processed, we still need to save the document
      if (keyPoints.isEmpty) {
        _updateProcessingStatus('Finalizing document upload...', 6);

        // Generate tag using OpenAI
        final tag =
            documentInfo.containsKey('tag') && documentInfo['tag'] != null
                ? documentInfo['tag']
                : await openAIService.generateTagForDocument(
                  fileName,
                  fileType,
                );

        // Insert document metadata into database
        await supabase.from('documents').insert({
          'name': fileName,
          'file_url': fileUrl,
          'file_type': fileType,
          'tag': tag,
          'user_id': user.id,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // Refresh the documents list
      await fetchDocuments();

      Get.snackbar('Success', 'File uploaded successfully');
    } catch (e) {
      print('Error uploading file: $e');
      Get.snackbar('Error', 'Failed to upload file: $e');
    } finally {
      isUploading.value = false;
      _resetProcessingStatus();
    }
  }

  // Delete a document
  Future<void> deleteDocument(String documentId, String storagePath) async {
    try {
      // Get associated memories before deleting the document
      final memoryData = await supabase
          .from('document_memories')
          .select('memory_id')
          .eq('document_id', documentId);

      // Extract memory IDs
      final List<String> memoryIds =
          memoryData
              .map<String>((item) => item['memory_id'].toString())
              .toList();

      // Debug the memory IDs
      print('Extracted ${memoryIds.length} memory IDs: $memoryIds');

      // Delete memories from Mem0
      if (memoryIds.isNotEmpty) {
        print('Deleting ${memoryIds.length} associated memories');
        final result = await mem0Service.deleteMemories(memoryIds);
        print(
          'Deleted ${result['success_count']} memories, '
          'failed: ${result['failed_count']}',
        );
      }

      // Delete document from database (this will cascade delete document_memories)
      await supabase.from('documents').delete().eq('id', documentId);

      // Delete from storage if path is provided
      if (storagePath.isNotEmpty) {
        await supabase.storage.from('documents').remove([storagePath]);
      }

      // Refresh the documents list
      await fetchDocuments();

      Get.snackbar('Success', 'Document deleted successfully');
    } catch (e) {
      print('Error deleting document: $e');
      Get.snackbar('Error', 'Failed to delete document');
    }
  }

  // Helper method to determine file type
  String _getFileType(String extension) {
    switch (extension) {
      case '.pdf':
        return 'PDF';
      case '.doc':
      case '.docx':
        return 'Document';
      case '.jpg':
      case '.jpeg':
      case '.png':
        return 'Image';
      default:
        return 'Other';
    }
  }

  // Fetch extracted details (memories) for a document
  Future<List<Map<String, dynamic>>> fetchDocumentDetails(
    String documentId,
  ) async {
    try {
      final data = await supabase
          .from('document_memories')
          .select('id, memory_id, memory_content')
          .eq('document_id', documentId)
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('Error fetching document details: $e');
      Get.snackbar('Error', 'Failed to fetch document details');
      return [];
    }
  }

  // Update document details (memories)
  Future<void> updateDocumentDetails(
    String documentId,
    List<Map<String, dynamic>> details,
  ) async {
    try {
      final user = authController.currentUser;
      if (user == null) {
        Get.snackbar('Error', 'You must be logged in to update documents');
        return;
      }

      // Get existing memory details
      final existingDetails = await fetchDocumentDetails(documentId);
      // Create a map for faster lookup by ID
      final Map<String, Map<String, dynamic>> existingDetailsMap = {
        for (var detail in existingDetails) detail['id'].toString(): detail,
      };
      final existingMemoryIds =
          existingDetails.map((e) => e['memory_id'].toString()).toList();

      int updatedCount = 0;
      int addedCount = 0;
      int deletedCount = 0;

      // Process updated details
      for (final detail in details) {
        final String memoryId = detail['memory_id'] ?? '';
        final String content = detail['memory_content'] ?? '';
        final String? recordId = detail['id'];

        if (memoryId.isNotEmpty &&
            existingMemoryIds.contains(memoryId) &&
            recordId != null) {
          // Check if the content has actually changed
          final existingDetail = existingDetailsMap[recordId];
          final existingContent = existingDetail?['memory_content'] ?? '';

          if (content != existingContent) {
            // Content has changed, update in Mem0 and database
            print('Updating changed memory: $recordId');
            final userId = user.email ?? user.id;
            final updateResult = await mem0Service.updateMemory(
              memoryId,
              content,
              userId,
            );

            if (updateResult['success']) {
              // If the update uses a fallback approach with a new memory ID
              if (updateResult.containsKey('warning') &&
                  updateResult.containsKey('old_memory_id')) {
                print('Using new memory ID after fallback update');
                final newMemoryId = updateResult['memory_id'];

                // Update the record with the new memory ID
                await supabase
                    .from('document_memories')
                    .update({
                      'memory_id': newMemoryId,
                      'memory_content': content,
                    })
                    .eq('id', recordId);

                // Try to delete the old memory that wasn't deleted during update
                await mem0Service.deleteMemory(memoryId);
              } else {
                // Normal update - just update the content
                await supabase
                    .from('document_memories')
                    .update({'memory_content': content})
                    .eq('id', recordId);
              }
              updatedCount++;
            } else {
              print('Failed to update memory: $memoryId');
              Get.snackbar(
                'Warning',
                'Some details may not have been fully updated',
                backgroundColor: Colors.orange,
                colorText: Colors.white,
              );
            }
          } else {
            print('Skipping unchanged memory: $recordId');
          }
        } else if (content.isNotEmpty) {
          // This is a new memory, add it
          print('Adding new memory');
          final userId = user.email ?? user.id;
          final memoryResult = await mem0Service.addMemory(userId, content);

          if (memoryResult['success'] && memoryResult['memory_id'] != null) {
            // Store in Supabase
            await supabase.from('document_memories').insert({
              'document_id': documentId,
              'memory_id': memoryResult['memory_id'],
              'memory_content': content,
            });
            addedCount++;
          }
        }
      }

      // Handle deletions - same logic as before
      for (final existingDetail in existingDetails) {
        final existingId = existingDetail['id'];
        final existingMemoryId = existingDetail['memory_id'];

        // Check if this memory still exists in the updated list
        final stillExists = details.any((d) => d['id'] == existingId);

        if (!stillExists && existingId != null && existingMemoryId != null) {
          print('Deleting removed memory: $existingId');
          // Delete from Supabase
          await supabase
              .from('document_memories')
              .delete()
              .eq('id', existingId);

          // Delete from Mem0
          await mem0Service.deleteMemories([existingMemoryId]);
          deletedCount++;
        }
      }

      print(
        'Document details updated: $updatedCount updated, $addedCount added, $deletedCount deleted',
      );
      // Don't show snackbar here as it will be shown in the UI layer
    } catch (e) {
      print('Error updating document details: $e');
      throw e; // Rethrow to be caught in the UI layer
    }
  }
}
