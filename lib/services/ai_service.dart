// services/ai_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/task_model.dart';
import '../models/timer_settings_model.dart';
import 'dart:math';

class AIService {
  // Singleton instance
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;

  // API key for DeepSeek
  static String apiKey = 'sk-01cd5245e677480fa0a1b0f47a02ab67';

  // Real API URL
  static const String _baseUrl = 'https://api.deepseek.ai/v1';

  // Store conversation history
  final List<Map<String, dynamic>> _conversationHistory = [];

  // FocusMate AI branding
  static const String aiName = "FocusMate AI";
  static const String aiDescription =
      """I'm FocusMate AI, your personal productivity assistant. I can help you manage tasks, recommend optimal pomodoro settings, provide productivity tips, and answer any questions about using the app.""";

  AIService._internal() {
    // Load API key from secure storage
    _loadApiKey();

    // Initialize with greeting message
    addAssistantMessage(_getWelcomeMessage());
  }

  String _getWelcomeMessage() {
    final currentHour = DateTime.now().hour;
    String greeting;

    if (currentHour < 12) {
      greeting = "Good morning";
    } else if (currentHour < 17) {
      greeting = "Good afternoon";
    } else {
      greeting = "Good evening";
    }

    return "$greeting! $aiDescription How can I assist you today?";
  }

  Future<void> _loadApiKey() async {
    // Use Flutter Secure Storage for production
    // For development, you can load from .env file with flutter_dotenv
    // apiKey = await secureStorage.read(key: 'deepseek_api_key');
  }

  // Add this method to set the API key
  static void setApiKey(String key) {
    apiKey = key;
  }

  // Task categories and their recommended pomodoro settings
  final Map<String, Map<String, int>> _taskRecommendations = {
    'coding': {
      'pomodoroTime': 25,
      'shortBreak': 5,
      'longBreak': 15,
      'pomodoroCount': 4,
    },
    'writing': {
      'pomodoroTime': 30,
      'shortBreak': 5,
      'longBreak': 20,
      'pomodoroCount': 3,
    },
    'reading': {
      'pomodoroTime': 25,
      'shortBreak': 5,
      'longBreak': 15,
      'pomodoroCount': 3,
    },
    'studying': {
      'pomodoroTime': 25,
      'shortBreak': 5,
      'longBreak': 20,
      'pomodoroCount': 4,
    },
    'design': {
      'pomodoroTime': 30,
      'shortBreak': 10,
      'longBreak': 20,
      'pomodoroCount': 3,
    },
    'meeting': {
      'pomodoroTime': 45,
      'shortBreak': 10,
      'longBreak': 30,
      'pomodoroCount': 2,
    },
    'default': {
      'pomodoroTime': 25,
      'shortBreak': 5,
      'longBreak': 15,
      'pomodoroCount': 4,
    },
  };

  // Add user message to conversation history
  void addUserMessage(String message) {
    _conversationHistory.add({
      'role': 'user',
      'content': message,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Add assistant message to conversation history
  void addAssistantMessage(String message) {
    _conversationHistory.add({
      'role': 'assistant',
      'content': message,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Get conversation history
  List<Map<String, dynamic>> getConversationHistory() {
    return _conversationHistory;
  }

  // Process user text input and extract task data
  Future<Map<String, dynamic>> processUserInput(String input) async {
    // Add user message to conversation history
    addUserMessage(input);

    try {
      // Check if this is a question or conversation rather than a task creation request
      if (_isQuestion(input) || _isConversational(input)) {
        final response = await _generateChatResponse(input);
        addAssistantMessage(response);

        return {
          'success': true,
          'isChat': true,
          'response': response,
        };
      }

      // Extract task title - use the first line or up to 40 chars
      String title = input.split('\n').first;
      if (title.length > 40) {
        title = '${title.substring(0, 37)}...';
      }

      // Extract or create description
      String description = '';
      if (input.contains('\n')) {
        description = input.substring(input.indexOf('\n')).trim();
      }

      // Determine task category based on keywords
      String category = _determineTaskCategory(input.toLowerCase());

      // Get recommended settings for this task type
      final settings =
          _taskRecommendations[category] ?? _taskRecommendations['default']!;

      // Create reasoning based on task and category
      final reasoning = _generateReasoning(category, settings);

      // Add assistant response to conversation history with FocusMate AI branding
      addAssistantMessage(
          "I've analyzed your task and created a recommendation:\n\n"
          "Task: $title\n\n"
          "$reasoning\n\n"
          "Would you like me to create this task with these settings?");

      return {
        'success': true,
        'isChat': false,
        'title': title,
        'description': description,
        'category': category,
        'pomodoroTime': settings['pomodoroTime'],
        'shortBreak': settings['shortBreak'],
        'longBreak': settings['longBreak'],
        'pomodoroCount': settings['pomodoroCount'],
        'reasoning': reasoning,
      };
    } catch (e) {
      final errorMessage =
          "I'm sorry, I encountered an error while processing your request. Please try again.";
      addAssistantMessage(errorMessage);

      return {
        'success': false,
        'isChat': true,
        'response': errorMessage,
        'error': 'Failed to process input: $e',
      };
    }
  }

  // Check if input is a question rather than a task description
  bool _isQuestion(String input) {
    final lowercaseInput = input.toLowerCase().trim();

    // Check for question marks
    if (input.contains('?')) return true;

    // Check for common question starters
    final questionStarters = [
      'what',
      'how',
      'when',
      'why',
      'where',
      'who',
      'which',
      'can you',
      'could you',
      'will you',
      'would you',
      'do you',
      'tell me',
      'explain'
    ];

    for (final starter in questionStarters) {
      if (lowercaseInput.startsWith(starter)) return true;
    }

    return false;
  }

  // Check if the input is conversational rather than a task
  bool _isConversational(String input) {
    final lowercaseInput = input.toLowerCase().trim();

    // Check for greetings and common conversational phrases
    final conversationalPhrases = [
      'hi',
      'hello',
      'hey',
      'thanks',
      'thank you',
      'great',
      'good',
      'nice',
      'awesome',
      'cool',
      'yes',
      'no',
      'maybe',
      'ok',
      'okay',
      'bye',
      'goodbye',
      'see you',
      'later',
      'please'
    ];

    // Check if input is very short (likely conversational)
    if (input.length < 10) {
      for (final phrase in conversationalPhrases) {
        if (lowercaseInput == phrase || lowercaseInput.startsWith('$phrase ')) {
          return true;
        }
      }
    }

    // Look at conversation history to determine if we're in a conversation
    if (_conversationHistory.length >= 2) {
      // If the last message was from the assistant and ended with a question
      final lastAssistantMsg = _conversationHistory.lastWhere(
          (msg) => msg['role'] == 'assistant',
          orElse: () => {'content': ''});

      if (lastAssistantMsg['content'] != null &&
          lastAssistantMsg['content'].toString().contains('?')) {
        return true;
      }
    }

    return false;
  }

  // Generate AI response for chat messages
  Future<String> _generateChatResponse(String userInput) async {
    try {
      // Prepare conversation history for the API
      final apiMessages = [];

      // Add system message for FocusMate AI personality
      apiMessages.add({
        'role': 'system',
        'content': 'You are $aiName, a friendly and professional AI assistant for the FocusMate app. '
            'You help users manage their tasks, improve productivity, and use the pomodoro technique effectively. '
            'Keep responses relevant to productivity, time management, and using the FocusMate app. '
            'Be encouraging, positive, and provide actionable advice. '
            'Never mention being powered by DeepSeek or other AI companies - you are uniquely FocusMate AI.',
      });

      // Add conversation history
      for (final message in _conversationHistory) {
        apiMessages.add({
          'role': message['role'],
          'content': message['content'],
        });
      }

      // Make API request
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': apiMessages,
          'temperature': 0.7,
          'max_tokens': 800,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        // Handle errors gracefully
        return "I'm sorry, I'm having trouble processing your request at the moment. Could you try again in a moment?";
      }
    } catch (e) {
      return "I apologize, but I'm experiencing technical difficulties. Please try again later.";
    }
  }

  // Get personalized productivity tips
  Future<String> getProductivityTip() async {
    try {
      // Call DeepSeek API for productivity tip
      final response = await callDeepSeekAPI('chat/completions', {
        'model': 'deepseek-chat',
        'messages': [
          {
            'role': 'system',
            'content':
                'You are a productivity expert that provides short, actionable productivity tips.'
          },
          {
            'role': 'user',
            'content':
                'Give me one short, practical productivity tip that can be applied to the Pomodoro technique.'
          }
        ],
        'max_tokens': 100,
        'temperature': 0.7,
      });

      if (response.containsKey('choices') &&
          response['choices'] is List &&
          response['choices'].isNotEmpty) {
        final content = response['choices'][0]['message']['content'];
        return content;
      } else {
        // Fallback tips if API fails
        final tips = [
          "Try the 'two-minute rule': if a task takes less than two minutes, do it immediately.",
          "Consider using the 'Eisenhower Matrix' to categorize tasks by urgency and importance.",
          "Set specific goals for each Pomodoro session to maintain focus.",
          "Keep a distraction list nearby to jot down thoughts that come up during focus time.",
          "Your most productive time is usually within the first 2-3 hours after waking up.",
          "Stay hydrated! Even mild dehydration can reduce cognitive performance."
        ];

        final random = Random();
        return tips[random.nextInt(tips.length)];
      }
    } catch (e) {
      // Fallback if API call fails completely
      return "Set clear, specific goals for each Pomodoro session to maintain focus and track progress.";
    }
  }

  // Determine task category based on keywords in the input
  String _determineTaskCategory(String input) {
    if (input.contains('cod') ||
        input.contains('program') ||
        input.contains('develop') ||
        input.contains('debug')) {
      return 'coding';
    } else if (input.contains('writ') ||
        input.contains('essay') ||
        input.contains('blog') ||
        input.contains('article')) {
      return 'writing';
    } else if (input.contains('read') || input.contains('book')) {
      return 'reading';
    } else if (input.contains('stud') ||
        input.contains('learn') ||
        input.contains('course') ||
        input.contains('homework')) {
      return 'studying';
    } else if (input.contains('design') ||
        input.contains('sketch') ||
        input.contains('draw')) {
      return 'design';
    } else if (input.contains('meet') ||
        input.contains('call') ||
        input.contains('interview')) {
      return 'meeting';
    }

    return 'default';
  }

  // Generate reasoning for the recommendations
  String _generateReasoning(String category, Map<String, int> settings) {
    switch (category) {
      case 'coding':
        return "Coding tasks typically benefit from ${settings['pomodoroTime']}-minute focus sessions with ${settings['shortBreak']}-minute breaks. I've set ${settings['pomodoroCount']} sessions to help you make significant progress while preventing mental fatigue.";
      case 'writing':
        return "For writing tasks, ${settings['pomodoroTime']}-minute sessions help maintain creative flow, with ${settings['shortBreak']}-minute breaks to refresh. ${settings['pomodoroCount']} sessions should provide a good balance for productivity.";
      case 'reading':
        return "When reading, ${settings['pomodoroTime']}-minute focused sessions help with comprehension and retention. ${settings['pomodoroCount']} sessions with ${settings['shortBreak']}-minute breaks will help you make progress without eye strain.";
      case 'studying':
        return "Study sessions of ${settings['pomodoroTime']} minutes optimize learning while ${settings['shortBreak']}-minute breaks help with memory consolidation. A total of ${settings['pomodoroCount']} sessions is ideal for effective studying.";
      case 'design':
        return "Creative design work benefits from slightly longer ${settings['pomodoroTime']}-minute sessions with ${settings['shortBreak']}-minute breaks to rest your eyes and creative thinking. ${settings['pomodoroCount']} sessions should help you make good progress.";
      case 'meeting':
        return "For meetings, longer ${settings['pomodoroTime']}-minute sessions with ${settings['shortBreak']}-minute breaks help maintain focus during discussions. ${settings['pomodoroCount']} sessions should cover most meeting scenarios.";
      default:
        return "I've recommended a standard pomodoro setting of ${settings['pomodoroTime']} minutes with ${settings['shortBreak']}-minute breaks, which works well for most tasks. You'll have ${settings['pomodoroCount']} sessions to complete your work.";
    }
  }

  // Create task from AI recommendations
  Task createTaskFromRecommendations(Map<String, dynamic> recommendations) {
    return Task(
      title: recommendations['title'],
      description: recommendations['description'],
      pomodoroTime: recommendations['pomodoroTime'],
      shortBreak: recommendations['shortBreak'],
      longBreak: recommendations['longBreak'],
      pomodoroCount: recommendations['pomodoroCount'],
    );
  }

  Future<Map<String, dynamic>> callDeepSeekAPI(
      String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/$endpoint'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('API error: ${response.statusCode}');
        print('Response body: ${response.body}');
        return {
          'success': false,
          'error': 'API error: ${response.statusCode}',
          'message': response.body
        };
      }
    } catch (e) {
      print('API call exception: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
}
