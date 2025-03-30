import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenAIService {
  // Get API key from environment variables - check platform environment variables first

  static const String apiUrl = 'https://api.openai.com/v1/chat/completions';

  final String apiKey = String.fromEnvironment(
    'OPENAI_API_KEY',
    defaultValue: '',
  );

  // Function to get a response for chat interaction
  Future<String> getChatResponse(String userMessage) async {
    try {
      // System message to set the context for the AI
      const systemMessage = '''
      You are a helpful document assistant with access to the user's uploaded documents. 
      When provided with information from documents, use it to give accurate, concise answers.
      If document information is provided in the user's query, consider this information as verified facts.
      Keep your responses helpful and informative, but concise.
      If asked about something that isn't in the provided document information, be honest about not having that specific information.
      ''';

      print('Sending message to OpenAI: ${userMessage.length} characters');

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {'role': 'system', 'content': systemMessage},
            {'role': 'user', 'content': userMessage},
          ],
          'temperature': 0.7,
          'max_tokens': 400,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiResponse =
            data['choices'][0]['message']['content'].toString().trim();
        return aiResponse;
      } else {
        //print api key
        print('API key: $apiKey');
        print('OpenAI API error: ${response.body}');
        return "I'm sorry, I encountered an error. Please try again later.";
      }
    } catch (e) {
      print('Error getting chat response: $e');
      return "I'm sorry, there was a problem connecting to the service. Please try again later.";
    }
  }

  // New method to categorize a message as query or statement
  Future<String> categorizeMessage(String message) async {
    try {
      print('Categorizing message: $message');

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a message classifier. Categorize the user message as either "query" if it\'s a question or information request, or "statement" if it\'s providing information or making a statement. Respond only with the word "query" or "statement" with no additional text.',
            },
            {'role': 'user', 'content': message},
          ],
          'temperature': 0.3,
          'max_tokens': 10,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final classification =
            data['choices'][0]['message']['content']
                .toString()
                .trim()
                .toLowerCase();

        print('Message categorized as: $classification');

        // Ensure we only return "query" or "statement"
        if (classification == "query" || classification == "statement") {
          return classification;
        } else {
          // Default to query if response is unexpected
          print(
            'Unexpected classification response: $classification. Defaulting to query.',
          );
          return "query";
        }
      } else {
        //print api key
        print('API key: $apiKey');
        print('OpenAI API error: ${response.body}');
        return "query"; // Default to query on error
      }
    } catch (e) {
      print('Error categorizing message: $e');
      return "query"; // Default to query on error
    }
  }

  // Function to determine if a response is positive or negative
  Future<bool> isPositiveResponse(String response) async {
    try {
      print('Analyzing sentiment of response: $response');

      final apiResponse = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a sentiment analyzer. Determine if the user message represents a positive/affirmative response or a negative/declining response. Respond only with "positive" or "negative" with no additional text.',
            },
            {'role': 'user', 'content': response},
          ],
          'temperature': 0.3,
          'max_tokens': 10,
        }),
      );

      if (apiResponse.statusCode == 200) {
        final data = jsonDecode(apiResponse.body);
        final sentiment =
            data['choices'][0]['message']['content']
                .toString()
                .trim()
                .toLowerCase();

        print('Response sentiment analyzed as: $sentiment');

        // Return true for positive responses
        return sentiment == "positive";
      } else {
        print('OpenAI API error: ${apiResponse.body}');
        // Default to false on error
        return false;
      }
    } catch (e) {
      print('Error analyzing response sentiment: $e');
      // Default to false on error
      return false;
    }
  }

  // Function to analyze file content and generate a description and tag
  Future<Map<String, String>> generateDocumentInfo(
    String fileName,
    String fileType,
    String base64FileContent,
  ) async {
    try {
      print('Sending file content to OpenAI: $fileName ($fileType)');

      // Determine the MIME type based on file extension
      String mimeType = _getMimeType(fileName);

      // Format base64 content as a data URL
      String dataUrl = 'data:$mimeType;base64,$base64FileContent';

      // Create a prompt for OpenAI with file content
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o',
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'file',
                  'file': {'filename': fileName, 'file_data': dataUrl},
                },
                {
                  'type': 'text',
                  'text':
                      'Please analyze this document thoroughly and extract all important information. For each key piece of information, format it as a conversational statement (e.g., "The user\'s passport number is 1242" instead of "Passport number: 1242"). Return your analysis as JSON with "key_points" (array of conversational statements) and "tag" keys. The tag should be one of: travel, finance, education, health, personal, work, legal, receipts, housing.',
                },
              ],
            },
          ],
          'temperature': 0.3,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiResponse =
            data['choices'][0]['message']['content'].toString().trim();

        print('File Analysis Complete:');
        print('--------------------------');
        print(aiResponse);
        print('--------------------------');

        try {
          // Remove any markdown code block markers if present
          // Handle patterns like ```json { ... } ``` or ``` { ... } ```
          String jsonString = aiResponse;
          if (aiResponse.startsWith('```')) {
            // Find the first { after the opening backticks
            final openBraceIndex = aiResponse.indexOf('{');
            if (openBraceIndex != -1) {
              final closeBraceIndex = aiResponse.lastIndexOf('}');
              if (closeBraceIndex != -1 && closeBraceIndex > openBraceIndex) {
                jsonString = aiResponse.substring(
                  openBraceIndex,
                  closeBraceIndex + 1,
                );
              }
            } else {
              // If no opening brace, just remove the backticks
              jsonString =
                  aiResponse.replaceAll(RegExp(r'```.*?\n|\n```'), '').trim();
            }
          }

          // Try to parse as JSON
          final jsonResult = jsonDecode(jsonString);
          print('JSON Result: $jsonResult');

          // Extract key points and tag
          final List<String> keyPoints =
              jsonResult['key_points'] != null
                  ? List<String>.from(jsonResult['key_points'])
                  : [];
          final tag = (jsonResult['tag'] ?? '').toLowerCase();

          return {
            'key_points': jsonEncode(keyPoints), // Convert list to JSON string
            'description': jsonResult['description'] ?? '',
            'tag': tag,
          };
        } catch (e) {
          // Fallback if not valid JSON
          print('Failed to parse JSON response: $e');

          // Extract tag and description from text response
          final String description =
              aiResponse.length > 150
                  ? '${aiResponse.substring(0, 147)}...'
                  : aiResponse;

          return {
            'description': description,
            'tag': _getDefaultTag(fileName, fileType),
          };
        }
      } else {
        print('OpenAI API error: ${response.body}');
        return {
          'description': 'No description available',
          'tag': _getDefaultTag(fileName, fileType),
        };
      }
    } catch (e) {
      print('Error generating document info: $e');
      return {
        'description': 'No description available',
        'tag': _getDefaultTag(fileName, fileType),
      };
    }
  }

  // Helper method to determine MIME type based on file extension
  String _getMimeType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();

    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }

  // Function to analyze file name and generate a tag
  Future<String> generateTagForDocument(
    String fileName,
    String fileType,
  ) async {
    try {
      // Create a prompt for OpenAI
      final prompt = '''
      Based on this file name and type, suggest a single category tag that best represents it.
      File name: $fileName
      File type: $fileType
      
      Respond with ONLY the tag name in lowercase, with no additional text or explanation.
      Choose from the following categories: 
      travel, finance, education, health, personal, work, legal, receipts, housing
      ''';

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a helpful assistant that categorizes documents.',
            },
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.3,
          'max_tokens': 10,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String tag =
            data['choices'][0]['message']['content']
                .toString()
                .trim()
                .toLowerCase();

        // Remove any non-alphanumeric characters and ensure it's a single word
        tag = tag.replaceAll(RegExp(r'[^a-zA-Z]'), '');

        return tag;
      } else {
        print('OpenAI API error: ${response.body}');
        return _getDefaultTag(fileName, fileType);
      }
    } catch (e) {
      print('Error generating tag: $e');
      return _getDefaultTag(fileName, fileType);
    }
  }

  // Fallback method if API fails
  String _getDefaultTag(String fileName, String fileType) {
    fileName = fileName.toLowerCase();

    if (fileName.contains('passport') ||
        fileName.contains('visa') ||
        fileName.contains('ticket')) {
      return 'travel';
    } else if (fileName.contains('invoice') ||
        fileName.contains('receipt') ||
        fileName.contains('bill')) {
      return 'finance';
    } else if (fileName.contains('certificate') ||
        fileName.contains('diploma') ||
        fileName.contains('course')) {
      return 'education';
    } else if (fileName.contains('medical') ||
        fileName.contains('health') ||
        fileName.contains('prescription')) {
      return 'health';
    } else if (fileName.contains('contract') ||
        fileName.contains('agreement') ||
        fileName.contains('legal')) {
      return 'legal';
    } else {
      return 'personal';
    }
  }

  // Function to evaluate if a statement is worth saving to memory
  Future<bool> isWorthSaving(String statement) async {
    try {
      print('Evaluating if worth saving: $statement');

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are an evaluator of information value. Determine if the provided statement contains substantial information worth remembering for future reference. Examples of valuable information: specific facts about the user, important details about their preferences, information that might be recalled later. Examples of NOT valuable information: basic greetings, simple acknowledgments, vague statements without specific content. Respond only with "yes" if it\'s worth saving or "no" if it\'s not, without any explanation.',
            },
            {'role': 'user', 'content': statement},
          ],
          'temperature': 0.3,
          'max_tokens': 5,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final evaluation =
            data['choices'][0]['message']['content']
                .toString()
                .trim()
                .toLowerCase();

        print('Statement value evaluated as: $evaluation');

        // Return true if worth saving
        return evaluation == "yes";
      } else {
        print('OpenAI API error: ${response.body}');
        return false; // Default to not saving on error
      }
    } catch (e) {
      print('Error evaluating statement value: $e');
      return false; // Default to not saving on error
    }
  }

  // Function to evaluate if a query needs memory search
  Future<bool> requiresMemorySearch(String query) async {
    try {
      print('Evaluating if query needs memory search: $query');

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are an evaluator determining if a user query likely requires searching through personal/document memory. Example queries needing memory: questions about specific documents, personal information, or factual details the user previously shared. Examples NOT needing memory: general questions, greetings, casual conversation, opinions, or generic inquiries. Respond only with "yes" if memory search is needed or "no" if not needed, with no additional text.',
            },
            {'role': 'user', 'content': query},
          ],
          'temperature': 0.3,
          'max_tokens': 5,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final evaluation =
            data['choices'][0]['message']['content']
                .toString()
                .trim()
                .toLowerCase();

        print('Query memory search need evaluated as: $evaluation');

        // Return true if memory search is needed
        return evaluation == "yes";
      } else {
        print('OpenAI API error: ${response.body}');
        return true; // Default to searching memory on error (safer)
      }
    } catch (e) {
      print('Error evaluating query memory need: $e');
      return true; // Default to searching memory on error (safer)
    }
  }
}
