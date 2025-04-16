import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../utils/constants.dart';
import '../services/ai_service.dart';
import '../providers/task_provider.dart';
import '../models/task_model.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final AIService _aiService = AIService();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _showRecommendation = false;
  Map<String, dynamic>? _currentRecommendation;

  @override
  void initState() {
    super.initState();
    _loadConversationHistory();
    // Add a productivity tip
    _getProductivityTip();
  }

  Future<void> _loadConversationHistory() async {
    final history = _aiService.getConversationHistory();

    if (history.isNotEmpty) {
      setState(() {
        for (final message in history) {
          _messages.add(ChatMessage(
            text: message['content'],
            isUser: message['role'] == 'user',
          ));
        }
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _getProductivityTip() async {
    final tip = await _aiService.getProductivityTip();
    _addBotMessage("💡 Tip: $tip");
  }

  void _addBotMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: false,
      ));
    });
  }

  void _handleSubmit(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
      ));
      _messageController.clear();
      _isTyping = true;
      _showRecommendation = false;
    });

    try {
      // Process the user input to get task recommendations
      final response = await _aiService.processUserInput(text);

      if (response['success'] == true) {
        // Check if it's a chat-only response
        if (response['isChat'] == true) {
          _addBotMessage(response['response']);
        } else {
          // It's a task recommendation
          _currentRecommendation = response;

          // Add AI response with the reasoning
          _addBotMessage(
            "I've analyzed your task and created a recommendation:\n\n"
            "Task: ${response['title']}\n\n"
            "${response['reasoning']}\n\n"
            "Would you like me to create this task with these settings?",
          );

          setState(() {
            _showRecommendation = true;
          });
        }
      } else {
        // Error handling
        _addBotMessage(
          response['response'] ??
              "I'm sorry, I couldn't process your request. Please try again with more details about your task.",
        );
      }
    } catch (e) {
      _addBotMessage(
        "Sorry, I encountered an error while processing your request. Please try again.",
      );
    } finally {
      setState(() {
        _isTyping = false;
      });
    }
  }

  Future<void> _createTaskFromRecommendation() async {
    if (_currentRecommendation == null) return;

    try {
      final task =
          _aiService.createTaskFromRecommendations(_currentRecommendation!);

      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      await taskProvider.addTask(task);

      _addBotMessage(
        "Great! I've created the task '${task.title}' with the recommended settings. You can find it in your task list.",
      );

      setState(() {
        _showRecommendation = false;
        _currentRecommendation = null;
      });
    } catch (e) {
      _addBotMessage(
        "Sorry, I couldn't create the task. Please try again later.",
      );
    }
  }

  void _adjustRecommendation() {
    if (_currentRecommendation == null) return;

    _addBotMessage(
      "What would you like to adjust about the recommendation? You can specify changes to the title, description, focus time, break time, or number of sessions.",
    );

    setState(() {
      _showRecommendation = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FocusMate AI'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(AppConstants.spacing8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildChatMessage(message)
                    .animate()
                    .fadeIn(duration: 300.ms, delay: 100.ms)
                    .slideY(
                        begin: 0.1,
                        end: 0,
                        duration: 300.ms,
                        curve: Curves.easeOutCubic);
              },
            ),
          ),

          // Typing indicator
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.all(AppConstants.spacing8),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: FaIcon(
                      FontAwesomeIcons.message,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacing8),
                  Text(
                    'FocusMate AI is typing...',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),

          // Recommendation actions
          if (_showRecommendation && _currentRecommendation != null)
            _buildRecommendationActions(),

          // Text input
          _buildMessageComposer(),
        ],
      ),
    );
  }

  Widget _buildChatMessage(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppConstants.spacing4,
        horizontal: AppConstants.spacing8,
      ),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              backgroundColor: AppColors.primary,
              child: FaIcon(
                FontAwesomeIcons.message,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: AppConstants.spacing8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(AppConstants.spacing12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isUser
                      ? Colors.white
                      : Theme.of(context).textTheme.bodyMedium!.color,
                ),
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: AppConstants.spacing8),
            CircleAvatar(
              backgroundColor: Colors.grey.shade200,
              child: FaIcon(
                FontAwesomeIcons.user,
                color: Theme.of(context).primaryColor,
                size: 18,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageComposer() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacing8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(
            color: Colors.grey.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Describe your task...',
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusMedium),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacing16,
                  vertical: AppConstants.spacing12,
                ),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade800
                    : Colors.grey.shade100,
              ),
              minLines: 1,
              maxLines: 5,
              textInputAction: TextInputAction.send,
              onSubmitted: _handleSubmit,
            ),
          ),
          const SizedBox(width: AppConstants.spacing8),
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.paperPlane),
            color: Theme.of(context).primaryColor,
            onPressed: () => _handleSubmit(_messageController.text),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationActions() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacing12),
      color: Colors.grey.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _createTaskFromRecommendation,
              icon: const FaIcon(FontAwesomeIcons.check),
              label: const Text('Create Task'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: AppConstants.spacing8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _adjustRecommendation,
              icon: const FaIcon(FontAwesomeIcons.edit),
              label: const Text('Adjust'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({
    required this.text,
    this.isUser = false,
  });
}
