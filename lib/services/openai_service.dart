import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:math' as math;
import 'dart:async';

class OpenAIService {
  // Get API key from environment variables - check platform environment variables first

  static const String service_in_use = 'groq';

  static String getApiUrl(String endpoint) {
    final baseUrl =
        service_in_use == 'openai'
            ? 'https://api.openai.com/v1'
            : 'https://api.groq.com/openai/v1';

    return '$baseUrl/$endpoint';
  }

  String get apiKey {
    var apiKey = '';
    // Check if we're running on localhost
    const defaultOpenaiKey = String.fromEnvironment(
      'OPENAI_API_KEY',
      defaultValue: '',
    );

    const defaultGroqKey = String.fromEnvironment(
      'GROQ_API_KEY',
      defaultValue: '',
    );

    // Set the API key based on the service in use, regardless of environment
    if (service_in_use == 'openai') {
      apiKey = defaultOpenaiKey;
    } else {
      apiKey = defaultGroqKey;
    }

    // If we're on localhost, try to get the key from .env file (which might have more up-to-date keys)
    if (Uri.base.host.contains('localhost')) {
      print('Running on localhost, getting keys from .env file');
      if (service_in_use == 'openai') {
        print('Using OpenAI API key from .env file');
        final envKey = dotenv.env['OPENAI_API_KEY'] ?? '';
        apiKey = envKey.isNotEmpty ? envKey : apiKey;
      } else {
        print('Using Groq API key from .env file');
        final envKey = dotenv.env['GROQ_API_KEY'] ?? '';
        apiKey = envKey.isNotEmpty ? envKey : apiKey;
      }
    }

    // Debug information (redacted for security)
    if (apiKey.isNotEmpty) {
      print('API key is set (${apiKey.length} characters)');
      //print api key
      print('Groq API key: $apiKey');
    } else {
      print('WARNING: API key is empty!');
    }

    return apiKey;
  }

  // Function to get a response for chat interaction
  Future<String> getChatResponse(String userMessage) async {
    try {
      // System message to set the context for the AI
      const systemMessage = '''
      You are a helpful document assistant with access to the user's uploaded documents. 
      Keep responses extremely concise and to the point. Avoid unnecessary explanations or verbosity.
      When provided with information from documents, use it to give accurate, concise answers.
      When answering questions about information the user has shared in previous messages, refer to that conversation history.
      Always consider both CONVERSATION CONTEXT and DOCUMENT INFORMATION when answering queries.
      If document information is provided in the user's query, consider this information as verified facts.
      If asked about something that isn't in the provided document information or conversation history, be honest about not having that specific information.
      If the user's query is vague or incomplete, ask for specific details needed to provide a helpful response.
      ''';

      print(
        'Sending message to ${service_in_use == 'groq' ? 'Groq' : 'OpenAI'}: ${userMessage.length} characters',
      );
      print('Using model: llama-3.1-8b-instant');

      print('GROQ API key: $apiKey');

      final response = await http.post(
        Uri.parse(getApiUrl('chat/completions')),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.1-8b-instant',
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
        print(
          'API key: ${apiKey.substring(0, 4)}...${apiKey.substring(apiKey.length - 4)}',
        );
        print('${service_in_use.toUpperCase()} API error: ${response.body}');
        return "I'm sorry, I encountered an error. Please try again later.";
      }
    } catch (e) {
      print('Error getting chat response: $e');
      return "I'm sorry, there was a problem connecting to the service. Please try again later.";
    }
  }

  // Function to summarize a conversation
  Future<String> summarizeConversation(String conversationText) async {
    try {
      print('Summarizing conversation');
      print('Using model: llama-3.1-8b-instant');

      const systemMessage = '''
      You are a conversation summarizer. Your task is to create a very concise but comprehensive summary 
      of the conversation, capturing only key information, questions, and insights.
      Focus on information that would be useful for continuing the conversation.
      Ignore pleasantries and focus on substantive content.
      Keep the summary as brief as possible without losing important context.
      ''';

      final response = await http.post(
        Uri.parse(getApiUrl('chat/completions')),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.1-8b-instant',
          'messages': [
            {'role': 'system', 'content': systemMessage},
            {'role': 'user', 'content': conversationText},
          ],
          'temperature': 0.5,
          'max_tokens': 400,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final summary =
            data['choices'][0]['message']['content'].toString().trim();
        return summary;
      } else {
        print(
          'API key: ${apiKey.substring(0, 4)}...${apiKey.substring(apiKey.length - 4)}',
        );
        print('${service_in_use.toUpperCase()} API error: ${response.body}');
        return "Failed to summarize conversation.";
      }
    } catch (e) {
      print('Error summarizing conversation: $e');
      return "Failed to summarize conversation.";
    }
  }

  // New method to categorize a message as query or statement
  Future<String> categorizeMessage(String message) async {
    try {
      print('Categorizing message: $message');
      print('Using model: llama-3.1-8b-instant');

      final response = await http.post(
        Uri.parse(getApiUrl('chat/completions')),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.1-8b-instant',
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
        print(
          'API key: ${apiKey.substring(0, 4)}...${apiKey.substring(apiKey.length - 4)}',
        );
        print('${service_in_use.toUpperCase()} API error: ${response.body}');
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
      print('Using model: llama-3.1-8b-instant');

      final apiResponse = await http.post(
        Uri.parse(getApiUrl('chat/completions')),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.1-8b-instant',
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
        print(
          'API key: ${apiKey.substring(0, 4)}...${apiKey.substring(apiKey.length - 4)}',
        );
        print('${service_in_use.toUpperCase()} API error: ${apiResponse.body}');
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
      print('Base64 content length: ${base64FileContent.length} characters');

      // Determine the MIME type based on file extension
      String mimeType = _getMimeType(fileName);
      print('MIME type determined: $mimeType');

      // Format base64 content as a data URL
      String dataUrl = 'data:$mimeType;base64,$base64FileContent';
      print(
        'Data URL created (first 50 chars): ${dataUrl.substring(0, math.min(50, dataUrl.length))}...',
      );

      // Always use OpenAI for document processing, regardless of service_in_use setting
      String openaiApiKey;
      if (service_in_use == 'openai') {
        openaiApiKey = apiKey;
      } else {
        // Check for environment variables in a way that works in production
        const defaultOpenAIKey = String.fromEnvironment(
          'OPENAI_API_KEY',
          defaultValue: '',
        );

        // In localhost, try to get from dotenv
        if (Uri.base.host.contains('localhost')) {
          final envKey = dotenv.env['OPENAI_API_KEY'] ?? '';
          openaiApiKey = envKey.isNotEmpty ? envKey : defaultOpenAIKey;
        } else {
          openaiApiKey = defaultOpenAIKey;
        }
      }

      if (openaiApiKey.isEmpty) {
        print('OpenAI API key not found for document processing');
        return {
          'description': 'API key for document processing not available',
          'tag': _getDefaultTag(fileName, fileType),
        };
      }

      print('Using OpenAI for document processing with model: gpt-4o');
      print('OpenAI API key available: ${openaiApiKey.isNotEmpty}');
      print('Building request payload...');

      try {
        // Check if file is too large for reliable processing
        if (base64FileContent.length > 5000000) {
          // ~5MB
          print(
            'File is too large for reliable processing: ${base64FileContent.length} bytes',
          );
          return {
            'description': 'This file is too large for detailed analysis',
            'tag': _getDefaultTag(fileName, fileType),
          };
        }

        // Create a prompt for OpenAI with file content - use OpenAI directly
        print('Sending request to OpenAI API with timeout...');
        http.Response response;
        try {
          response = await http
              .post(
                Uri.parse('https://api.openai.com/v1/chat/completions'),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $openaiApiKey',
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
              )
              .timeout(
                const Duration(seconds: 60), // 60 second timeout
                onTimeout: () {
                  print('OpenAI API request timed out');
                  throw TimeoutException('OpenAI API request timed out');
                },
              );
        } on TimeoutException {
          print(
            'Request timed out - likely due to large file or network issues',
          );
          return {
            'description': 'Analysis timed out. Try a smaller file.',
            'tag': _getDefaultTag(fileName, fileType),
          };
        }

        print(
          'Received response from OpenAI with status code: ${response.statusCode}',
        );

        if (response.statusCode == 200) {
          print('Successful response (200) from OpenAI');
          final data = jsonDecode(response.body);
          print('Response decoded successfully: ${data.keys}');

          final aiResponse =
              data['choices'][0]['message']['content'].toString().trim();
          print(
            'AI response extracted successfully, length: ${aiResponse.length}',
          );

          print('File Analysis Complete:');
          print('--------------------------');
          print(aiResponse);
          print('--------------------------');

          try {
            print('Attempting to extract JSON from response...');
            // Remove any markdown code block markers if present
            // Handle patterns like ```json { ... } ``` or ``` { ... } ```
            String jsonString = aiResponse;
            if (aiResponse.startsWith('```')) {
              print('Response starts with code block markers');
              // Find the first { after the opening backticks
              final openBraceIndex = aiResponse.indexOf('{');
              if (openBraceIndex != -1) {
                final closeBraceIndex = aiResponse.lastIndexOf('}');
                if (closeBraceIndex != -1 && closeBraceIndex > openBraceIndex) {
                  jsonString = aiResponse.substring(
                    openBraceIndex,
                    closeBraceIndex + 1,
                  );
                  print('Extracted JSON portion from markdown');
                }
              } else {
                // If no opening brace, just remove the backticks
                jsonString =
                    aiResponse.replaceAll(RegExp(r'```.*?\n|\n```'), '').trim();
                print('Removed code block markers');
              }
            }

            // Try to parse as JSON
            print(
              'Attempting to parse JSON: ${jsonString.substring(0, math.min(100, jsonString.length))}...',
            );
            final jsonResult = jsonDecode(jsonString);
            print('JSON parsed successfully');
            print('JSON Result keys: ${jsonResult.keys.toList()}');

            // Extract key points and tag
            print('Extracting key points and tag...');
            final List<String> keyPoints =
                jsonResult['key_points'] != null
                    ? List<String>.from(jsonResult['key_points'])
                    : [];
            print('Found ${keyPoints.length} key points');

            final tag = (jsonResult['tag'] ?? '').toLowerCase();
            print('Tag: $tag');

            return {
              'key_points': jsonEncode(
                keyPoints,
              ), // Convert list to JSON string
              'description': jsonResult['description'] ?? '',
              'tag': tag,
            };
          } catch (e) {
            // Fallback if not valid JSON
            print('Failed to parse JSON response: $e');
            print('Error type: ${e.runtimeType}');
            print('Error details: ${e.toString()}');

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
          print('OpenAI API error status code: ${response.statusCode}');
          print('Error response body: ${response.body}');
          return {
            'description': 'No description available',
            'tag': _getDefaultTag(fileName, fileType),
          };
        }
      } catch (e) {
        print('Exception during OpenAI API request: $e');
        print('Exception type: ${e.runtimeType}');
        print('Exception details: ${e.toString()}');
        return {
          'description': 'API request failed',
          'tag': _getDefaultTag(fileName, fileType),
        };
      }
    } catch (e) {
      print('Error generating document info: $e');
      print('Error generating document info type: ${e.runtimeType}');
      print('Error generating document info details: ${e.toString()}');
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

      print('Generating tag for document: $fileName');
      print('Using model: llama-3.1-8b-instant');

      final response = await http.post(
        Uri.parse(getApiUrl('chat/completions')),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.1-8b-instant',
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

        print('Generated tag: $tag');
        return tag;
      } else {
        print(
          'API key: ${apiKey.substring(0, 4)}...${apiKey.substring(apiKey.length - 4)}',
        );
        print('${service_in_use.toUpperCase()} API error: ${response.body}');
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
      print('Using model: llama-3.1-8b-instant');

      final response = await http.post(
        Uri.parse(getApiUrl('chat/completions')),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.1-8b-instant',
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
        print(
          'API key: ${apiKey.substring(0, 4)}...${apiKey.substring(apiKey.length - 4)}',
        );
        print('${service_in_use.toUpperCase()} API error: ${response.body}');
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
      print('Using model: llama-3.1-8b-instant');

      final response = await http.post(
        Uri.parse(getApiUrl('chat/completions')),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.1-8b-instant',
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
        print(
          'API key: ${apiKey.substring(0, 4)}...${apiKey.substring(apiKey.length - 4)}',
        );
        print('${service_in_use.toUpperCase()} API error: ${response.body}');
        return true; // Default to searching memory on error (safer)
      }
    } catch (e) {
      print('Error evaluating query memory need: $e');
      return true; // Default to searching memory on error (safer)
    }
  }

  // Combined function to both categorize a message and evaluate if it's worth saving
  // NOTE: As of the latest update, we're only using this for message categorization
  // and no longer saving statements to memory
  Future<Map<String, dynamic>> analyzeMessage(String message) async {
    try {
      print('-------------------------------------------');
      print('COMBINED ANALYSIS - Analyzing message: "$message"');
      print('Using model: llama-3.1-8b-instant');

      final response = await http.post(
        Uri.parse(getApiUrl('chat/completions')),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.1-8b-instant',
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a message analyzer. Categorize the user message as either "query" if it\'s a question or information request, or "statement" if it\'s providing information or making a statement.\n\n'
                  'Respond with a JSON object having two keys: "category" (with value "query" or "statement") and "worth_saving" (with value true or false). For example: {"category": "query", "worth_saving": false}\n\n'
                  'The worth_saving flag is retained for backward compatibility but is no longer used.',
            },
            {'role': 'user', 'content': message},
          ],
          'temperature': 0.3,
          'max_tokens': 50,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiResponse =
            data['choices'][0]['message']['content'].toString().trim();

        try {
          // Parse the JSON response
          // Handle cases where the model might include backticks for code blocks
          String jsonStr = aiResponse;
          if (jsonStr.contains('```')) {
            jsonStr = jsonStr.replaceAll(RegExp(r'```json|```'), '').trim();
          }

          final Map<String, dynamic> result = jsonDecode(jsonStr);

          // Validate and normalize the results
          String category =
              (result['category'] ?? 'query').toString().toLowerCase();
          bool worthSaving = result['worth_saving'] == true;

          // Ensure category is either "query" or "statement"
          if (category != "query" && category != "statement") {
            print('Unexpected category: $category. Defaulting to "query".');
            category = "query";
          }

          print(
            'COMBINED RESULT - Category: $category, Worth saving: $worthSaving',
          );
          print('-------------------------------------------');

          return {'category': category, 'worth_saving': worthSaving};
        } catch (e) {
          print('Error parsing analysis result: $e');
          print('Raw response: $aiResponse');
          // Default values on error
          return {'category': 'query', 'worth_saving': false};
        }
      } else {
        print(
          'API key: ${apiKey.substring(0, 4)}...${apiKey.substring(apiKey.length - 4)}',
        );
        print('${service_in_use.toUpperCase()} API error: ${response.body}');
        // Default values on error
        return {'category': 'query', 'worth_saving': false};
      }
    } catch (e) {
      print('Error analyzing message: $e');
      // Default values on error
      return {'category': 'query', 'worth_saving': false};
    }
  }
}
