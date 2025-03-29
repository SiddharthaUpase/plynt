import 'dart:convert';
import 'package:http/http.dart' as http;

class Mem0Service {
  // Replace with your actual Mem0 API key
  static const String apiKey = 'm0-Q7FEFPUZAQ5xxXAjBy139zDyQzMNz4cRVMWvUnF9';
  static const String apiUrl = 'https://api.mem0.ai/v1/memories/';
  static const String searchUrl =
      'https://api.mem0.ai/v1/memories/search/?version=v2';

  // Add a memory to Mem0
  Future<Map<String, dynamic>> addMemory(String userId, String content) async {
    try {
      print('Adding memory to Mem0: $content');

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Token $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'messages': [
            {'role': 'user', 'content': content},
            {
              'role': 'assistant',
              'content': 'I have stored this information for you.',
            },
          ],
          'user_id': userId,
        }),
      );

      print('Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Memory added successfully');

        // Parse the response to get the memory ID
        final data = jsonDecode(response.body);
        print('Data: $data');

        // The API returns an array of memory objects
        if (data is List && data.isNotEmpty) {
          // Use the first memory's ID (or return multiple if needed)
          final firstMemory = data[0];
          final memoryId = firstMemory['id']?.toString() ?? '';
          final memoryContent = firstMemory['memory'] ?? content;

          print('Extracted memory ID: $memoryId, Content: $memoryContent');

          return {
            'success': true,
            'memory_id': memoryId,
            'content': memoryContent,
          };
        } else if (data is Map && data.containsKey('id')) {
          // Handle case where response is a single object
          final memoryId = data['id']?.toString() ?? '';
          return {'success': true, 'memory_id': memoryId, 'content': content};
        } else {
          print('Unexpected response format: $data');
          return {'success': false, 'memory_id': '', 'content': content};
        }
      } else {
        print('Mem0 API error: ${response.body}');
        return {'success': false, 'memory_id': '', 'content': content};
      }
    } catch (e) {
      print('Error adding memory: $e');
      return {'success': false, 'memory_id': '', 'content': content};
    }
  }

  // Add multiple memories at once - one by one (slower)
  Future<List<bool>> addMemoriesSequentially(
    String userId,
    List<String> memories,
  ) async {
    final results = <bool>[];
    for (final memory in memories) {
      final result = await addMemory(userId, memory);
      results.add(result['success']);
    }
    return results;
  }

  // Add multiple memories in a single API call (bulk upload - faster)
  Future<List<Map<String, dynamic>>> addMemories(
    String userId,
    List<String> memories,
  ) async {
    try {
      if (memories.isEmpty) {
        print('No memories to upload');
        return [];
      }

      print('Adding ${memories.length} memories to Mem0');

      // Store results with memory IDs
      List<Map<String, dynamic>> results = [];

      // Try a batch approach with a single conversation
      if (memories.length > 1) {
        try {
          // Create a single conversation with multiple user messages
          final List<Map<String, String>> messages = [];

          // Add each memory as a separate user message
          for (final memory in memories) {
            messages.add({'role': 'user', 'content': memory});
            // Brief acknowledgment from assistant
            messages.add({'role': 'assistant', 'content': 'Noted.'});
          }

          // Final confirmation
          messages.add({
            'role': 'assistant',
            'content': 'I\'ve stored all this information for you.',
          });

          final response = await http.post(
            Uri.parse(apiUrl),
            headers: {
              'Authorization': 'Token $apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'messages': messages, 'user_id': userId}),
          );

          print('Batch response status: ${response.statusCode}');
          print('Batch response: ${response.body}');

          if (response.statusCode == 200 || response.statusCode == 201) {
            final data = jsonDecode(response.body);

            if (data is List) {
              // Track memory index to map content correctly
              int memoryIndex = 0;

              // Process each memory in the response
              for (final memoryObj in data) {
                if (memoryObj is Map && memoryObj.containsKey('id')) {
                  final memoryId = memoryObj['id']?.toString() ?? '';
                  // Use the original content if available, or extract from response
                  final memoryContent =
                      memoryIndex < memories.length
                          ? memories[memoryIndex]
                          : memoryObj['memory'] ?? '';

                  results.add({
                    'success': true,
                    'memory_id': memoryId,
                    'content': memoryContent,
                  });

                  memoryIndex++;
                }
              }

              print(
                'Successfully added ${results.length} memories in batch mode',
              );

              // If we have fewer results than memories, add the missing ones
              if (results.length < memories.length) {
                print(
                  'Mismatch between memories count and results, adding missing memories',
                );
                await _addRemainingMemories(userId, memories, results);
              }

              return results;
            }
          }

          // If batch fails, fall back to individual calls
          print(
            'Batch processing did not return expected format, falling back to individual calls',
          );
        } catch (e) {
          print(
            'Error in batch memory upload: $e - falling back to individual uploads',
          );
        }
      }

      // Fallback: Add each memory separately to get individual IDs
      return await _addRemainingMemories(userId, memories, results);
    } catch (e) {
      print('Error in memory upload: $e');
      return [];
    }
  }

  // Helper to add memories that weren't processed in the batch operation
  Future<List<Map<String, dynamic>>> _addRemainingMemories(
    String userId,
    List<String> memories,
    List<Map<String, dynamic>> existingResults,
  ) async {
    List<Map<String, dynamic>> results = List.from(existingResults);

    // Identify which memories need to be added
    final Set<String> addedContents =
        existingResults.map((result) => result['content'].toString()).toSet();

    for (final memory in memories) {
      // Skip if this content was already processed
      if (addedContents.contains(memory)) continue;

      final result = await addMemory(userId, memory);
      print('Result from individual add: $result');

      if (result['success']) {
        results.add(result);
        addedContents.add(memory);
      }
    }

    print('Successfully added ${results.length} memories with IDs');
    return results;
  }

  // Delete a memory from Mem0
  Future<bool> deleteMemory(String memoryId) async {
    try {
      print('Deleting memory from Mem0: $memoryId');

      final response = await http.delete(
        Uri.parse('$apiUrl$memoryId/'),
        headers: {
          'Authorization': 'Token $apiKey',
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Error deleting memory: $e');
      return false;
    }
  }

  // Update a memory in Mem0
  Future<Map<String, dynamic>> updateMemory(
    String memoryId,
    String newContent,
    String userId,
  ) async {
    try {
      print('Updating memory in Mem0: $memoryId with new content: $newContent');

      // Try to delete the existing memory
      bool isDeleted = false;
      int retryCount = 0;
      const maxRetries = 2;

      while (!isDeleted && retryCount < maxRetries) {
        isDeleted = await deleteMemory(memoryId);
        if (!isDeleted) {
          retryCount++;
          print(
            'Delete attempt $retryCount failed for memory $memoryId, retrying...',
          );
          await Future.delayed(
            Duration(milliseconds: 500 * retryCount),
          ); // Exponential backoff
        }
      }

      if (isDeleted) {
        print(
          'Successfully deleted memory $memoryId, creating new memory with updated content',
        );
        // Create a new memory with the updated content
        final result = await addMemory(userId, newContent);

        if (result['success']) {
          print(
            'Memory updated successfully with new ID: ${result['memory_id']}',
          );
          return result;
        } else {
          print('Failed to create new memory after deletion');
        }
      }

      // If deletion failed or creating a new memory failed, try a fallback approach
      print(
        'Using fallback approach: creating new memory without deleting old one',
      );
      final fallbackResult = await addMemory(userId, newContent);

      if (fallbackResult['success']) {
        print(
          'Created new memory with ID: ${fallbackResult['memory_id']} (old memory may still exist)',
        );
        return {
          'success': true,
          'memory_id': fallbackResult['memory_id'],
          'content': newContent,
          'old_memory_id': memoryId,
          'warning': 'Original memory was not deleted',
        };
      }

      print('All approaches to update memory failed');
      return {'success': false, 'memory_id': memoryId, 'content': newContent};
    } catch (e) {
      print('Error updating memory: $e');
      return {'success': false, 'memory_id': memoryId, 'content': newContent};
    }
  }

  // Delete multiple memories at once
  Future<Map<String, dynamic>> deleteMemories(List<String> memoryIds) async {
    try {
      int successCount = 0;
      List<String> failedIds = [];

      for (final memoryId in memoryIds) {
        final success = await deleteMemory(memoryId);
        if (success) {
          successCount++;
        } else {
          failedIds.add(memoryId);
        }
      }

      return {
        'success_count': successCount,
        'failed_count': failedIds.length,
        'failed_ids': failedIds,
      };
    } catch (e) {
      print('Error in bulk memory deletion: $e');
      return {
        'success_count': 0,
        'failed_count': memoryIds.length,
        'failed_ids': memoryIds,
      };
    }
  }

  // Search for relevant memories based on a query
  Future<List<String>> searchMemories(String userId, String query) async {
    try {
      print('Searching memories for: $query');

      final response = await http.post(
        Uri.parse(searchUrl),
        headers: {
          'Authorization': 'Token $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'query': query, 'user_id': userId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Debug full response structure
        print('Search results found');

        List<String> memories = [];

        if (data is List && data.isNotEmpty) {
          // Get just the top 3 results (or fewer if less are available)
          final resultsCount = data.length > 3 ? 3 : data.length;

          for (var i = 0; i < resultsCount; i++) {
            final result = data[i];
            if (result['memory'] != null) {
              memories.add(result['memory']);
            }
          }

          print('Extracted ${memories.length} memories from search results');
        } else {
          print('No matching memories found or unexpected response format');
        }

        return memories;
      } else {
        print('Mem0 API search error: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error searching memories: $e');
      return [];
    }
  }
}
