import 'package:flutter/material.dart';
import '../core/services/api_service.dart';
import '../core/localization/app_i18n.dart';

class PlanningChatScreen extends StatefulWidget {
  const PlanningChatScreen({super.key});

  @override
  State<PlanningChatScreen> createState() => _PlanningChatScreenState();
}

class _PlanningChatScreenState extends State<PlanningChatScreen> with SingleTickerProviderStateMixin {
  late AnimationController _dotsController;
  late List<Animation<double>> _dotAnimations;
  final ApiService _api = ApiService();
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  bool _loading = false;
  bool _historyLoading = true;

  String _t(String en, String ar) => AppI18n.t(context, en, ar);

  static const _green = Color(0xFF2E7D32);
  static const _lightGreen = Color(0xFF4CAF50);
  static const _bgGreen = Color(0xFFE8F5E9);

  // Suggested questions shown when chat is empty
  static const _suggestions = [
    'What was our average budget for the last 3 months?',
    'Who was the best child in the past 2 weeks?',
    'What do you suggest to save money next month?',
    'Suggest meals for today based on what we have.',
    'Which category did we overspend on?',
    'How many tasks were completed this week?',
  ];

  @override
  void initState() {
    super.initState();
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
    _dotAnimations = List.generate(3, (i) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _dotsController,
          curve: Interval(i * 0.2, 0.6 + i * 0.2, curve: Curves.easeInOut),
        ),
      );
    });
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final msgs = await _api.getPlanningHistory();
      if (!mounted) return;
      setState(() {
        _messages = msgs;
        _historyLoading = false;
      });
      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      setState(() => _historyLoading = false);
    }
  }

  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _loading) return;

    _inputCtrl.clear();
    setState(() {
      _messages.add({'role': 'user', 'content': trimmed});
      _loading = true;
    });
    _scrollToBottom();

    try {
      final reply = await _api.sendPlanningMessage(trimmed);
      if (!mounted) return;
      setState(() {
        _messages.add({'role': 'assistant', 'content': reply});
        _loading = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': _t('Sorry, something went wrong. Please try again.', 'عذراً، حدث خطأ. يرجى المحاولة مجدداً.'),
        });
        _loading = false;
      });
      _scrollToBottom();
    }
  }

  Future<void> _clearHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_t('Clear History', 'مسح السجل')),
        content: Text(_t('Are you sure you want to clear the entire chat history?', 'هل أنت متأكد من مسح سجل المحادثة بالكامل؟')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(_t('Cancel', 'إلغاء'))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_t('Clear', 'مسح'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    try {
      await _api.clearPlanningHistory();
      if (!mounted) return;
      setState(() => _messages = []);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t('Failed to clear history', 'فشل مسح السجل'))),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _dotsController.dispose();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F6),
      appBar: AppBar(
        backgroundColor: _green,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.smart_toy_outlined, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_t('Family AI Assistant', 'مساعد العائلة الذكي'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                Text(_t('Powered by Gemini', 'مدعوم بـ Gemini'),
                    style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.75))),
              ],
            ),
          ],
        ),
        actions: [
          if (_messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: _t('Clear history', 'مسح السجل'),
              onPressed: _clearHistory,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _historyLoading
                ? const Center(child: CircularProgressIndicator(color: _lightGreen))
                : _messages.isEmpty
                    ? _buildEmptyState()
                    : _buildMessageList(),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _bgGreen,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _lightGreen.withOpacity(0.3)),
              ),
              child: const Icon(Icons.smart_toy_outlined, color: _green, size: 44),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              _t('Ask me anything about your family!', 'اسألني أي شيء عن عائلتك!'),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _green),
              textAlign: TextAlign.center,
            ),
          ),
          Center(
            child: Text(
              _t('Budget, tasks, points, suggestions and more.', 'الميزانية، المهام، النقاط، والاقتراحات وأكثر.'),
              style: const TextStyle(fontSize: 13, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            _t('Try asking:', 'جرب أن تسأل:'),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF555555)),
          ),
          const SizedBox(height: 12),
          ..._suggestions.map((s) => _buildSuggestionChip(s)),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return GestureDetector(
      onTap: () => _sendMessage(text),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _lightGreen.withOpacity(0.35)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.chat_bubble_outline, color: _lightGreen, size: 16),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: Color(0xFF333333)))),
            const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: _messages.length + (_loading ? 1 : 0),
      itemBuilder: (context, index) {
        if (_loading && index == _messages.length) {
          return _buildTypingIndicator();
        }
        final msg = _messages[index];
        final isUser = msg['role'] == 'user';
        return _buildMessageBubble(msg['content'] as String, isUser);
      },
    );
  }

  Widget _buildMessageBubble(String content, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? _green : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 8, offset: const Offset(0, 2)),
          ],
          border: isUser ? null : Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.smart_toy_outlined, size: 14, color: _green),
                    const SizedBox(width: 4),
                    Text(_t('AI Assistant', 'المساعد الذكي'),
                        style: const TextStyle(fontSize: 11, color: _green, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            SelectableText(
              content,
              style: TextStyle(
                fontSize: 14,
                color: isUser ? Colors.white : const Color(0xFF1A1A1A),
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(color: const Color(0xFFE0E0E0)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6)],
        ),
        child: AnimatedBuilder(
          animation: _dotsController,
          builder: (context, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final t = _dotAnimations[i].value;
                final lift = t < 0.5 ? t * 2 : (1 - t) * 2;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Transform.translate(
                    offset: Offset(0, -6 * lift),
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: _lightGreen.withOpacity(0.4 + 0.6 * lift),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 12, MediaQuery.of(context).viewInsets.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputCtrl,
              enabled: !_loading,
              maxLines: 4,
              minLines: 1,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: _t('Ask about budget, tasks, points…', 'اسأل عن الميزانية، المهام، النقاط…'),
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (v) => _sendMessage(v),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _sendMessage(_inputCtrl.text),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _loading ? Colors.grey.shade300 : _green,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _loading ? Icons.hourglass_empty : Icons.send,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
