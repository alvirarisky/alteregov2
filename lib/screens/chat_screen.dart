import 'package:flutter/material.dart';
import '../ui/glass.dart';

class ChatView extends StatefulWidget {
  final String persona;
  final List<Map<String, dynamic>> messages;
  final ValueChanged<String> onSend;

  const ChatView({
    super.key,
    required this.persona,
    required this.messages,
    required this.onSend,
  });

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();

  @override
  void dispose() {
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }

  void sendMessage() {
    final text = controller.text.trim();
    if (text.isEmpty) return;

    widget.onSend(text);
    controller.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (!scrollController.hasClients) return;
    scrollController.animateTo(
      scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Widget chatBubble(String text, bool isUser) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment:
          isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 290),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: isUser
              ? Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    text,
                    style: TextStyle(color: scheme.onPrimary),
                  ),
                )
              : GlassCard(
                  padding: const EdgeInsets.all(12),
                  borderRadius: const BorderRadius.all(Radius.circular(18)),
                  child: Text(
                    text,
                    style: TextStyle(color: scheme.onSurface),
                  ),
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isSendEnabled = controller.text.trim().isNotEmpty;
    final keyboardBottom = MediaQuery.viewInsetsOf(context).bottom;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Align(
            alignment: Alignment.centerLeft,
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              borderRadius: const BorderRadius.all(Radius.circular(16)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome, size: 18, color: scheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    "Talking to: ${widget.persona}",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: widget.messages.isEmpty
              ? Center(
                  child: GlassCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: scheme.onSurface.withValues(alpha: 0.6),
                          size: 28,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Start the conversation",
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Ketik pesan pertama kamu di bawah.",
                          style: TextStyle(
                            color: scheme.onSurface.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: widget.messages.length,
                  itemBuilder: (context, index) {
                    final msg = widget.messages[index];
                    return chatBubble(
                      (msg["text"] as String?) ?? "",
                      msg["sender"] == "user",
                    );
                  },
                ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 12 + keyboardBottom),
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            borderRadius: const BorderRadius.all(Radius.circular(18)),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => sendMessage(),
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      isDense: true,
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        color: scheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: isSendEnabled ? sendMessage : null,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Icon(Icons.send_rounded, size: 18),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

@Deprecated('Use ChatView embedded in ChatTabScreen instead.')
class ChatScreen extends StatelessWidget {
  final String persona;

  const ChatScreen({super.key, required this.persona});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(persona),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: ChatView(
        persona: persona,
        messages: const [],
        onSend: (_) {},
      ),
    );
  }
}