import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../ui/glass.dart';
import '../view_models/chat_view_model.dart'; 

// ============================================================================
// 1. CHAT SCREEN (Sekarang murni hanya untuk merender UI / View)
// ============================================================================
class ChatScreen extends StatelessWidget {
  final String persona;

  const ChatScreen({super.key, required this.persona});

  @override
  Widget build(BuildContext context) {
    // Hubungkan UI dengan ViewModel menggunakan Provider
    final viewModel = context.watch<ChatViewModel>();

    if (viewModel.currentUser == null) {
      return const Scaffold(
        body: Center(child: Text("Silakan login terlebih dahulu.")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(persona),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        // Mengambil data real-time dari ViewModel, bukan Firebase langsung
        stream: viewModel.getMessagesStream(persona),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Gagal memuat pesan."));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Format data dari Firestore ke bentuk List yang diterima ChatView
          final messages = snapshot.data?.docs.map((doc) {
            final data = doc.data();
            return {
              "id": doc.id,
              "sender": data['sender'],
              "message": data['message'] ?? data['text'] ?? "Pesan kosong/Error",
            };
          }).toList() ?? [];

          return Stack(
            children: [
              ChatView(
                persona: persona,
                messages: messages,
                onSend: (text) {
                  // UI hanya menyuruh ViewModel untuk bekerja (memisahkan logic)
                  context.read<ChatViewModel>().sendMessage(text, persona);
                },
              ),
              // Menampilkan indikator loading yang diatur oleh ViewModel
              if (viewModel.isWaitingForAI)
                Positioned(
                  bottom: 90, 
                  left: 20,
                  child: GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    borderRadius: BorderRadius.circular(12),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "$persona is typing...",
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ============================================================================
// 2. CHAT VIEW (UI Murni - Menggunakan Markdown untuk AI Bubble)
// ============================================================================
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
  bool _isSending = false;
  String? _lastSentText;
  int _lastSentAtMs = 0;

  @override
  void didUpdateWidget(covariant ChatView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.messages.length > oldWidget.messages.length) {
      _isSending = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAutoScrollToBottom());
    }

    if (oldWidget.messages.isEmpty && widget.messages.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAutoScrollToBottom(force: true));
    }
  }

  @override
  void dispose() {
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }

  void sendMessage() {
    final text = controller.text.trim();
    if (text.isEmpty) return;
    if (_isSending) return;

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (_lastSentText == text && (nowMs - _lastSentAtMs) < 700) return;
    _lastSentText = text;
    _lastSentAtMs = nowMs;

    setState(() {
      _isSending = true;
    });
    widget.onSend(text);
    controller.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAutoScrollToBottom(force: true));
  }

  void _maybeAutoScrollToBottom({bool force = false}) {
    if (!scrollController.hasClients) return;

    final position = scrollController.position;
    final distanceFromBottom = position.maxScrollExtent - position.pixels;

    if (!force && distanceFromBottom > 120) return;

    scrollController.animateTo(
      position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Widget chatBubble(String text, bool isUser) {
    final scheme = Theme.of(context).colorScheme;
    final textColor = isUser ? scheme.onPrimary : scheme.onSurface;

    // Pengaman: Pastikan teks yang akan dirender benar-benar tidak kosong (blank)
    final String displayText = text.trim().isEmpty ? "Pesan kosong" : text;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
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
                    displayText, 
                    style: TextStyle(color: textColor),
                  ),
                )
              : GlassCard(
                  padding: const EdgeInsets.all(12),
                  borderRadius: const BorderRadius.all(Radius.circular(18)),
                  child: MarkdownBody(
                    data: displayText,
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(color: textColor, height: 1.3),
                      strong: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      listBullet: TextStyle(color: textColor),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isSendEnabled = controller.text.trim().isNotEmpty && !_isSending;
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
                      (msg["message"] as String?) ?? "Pesan kosong (error list)",
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
                    onChanged: (_) => setState(() {
                      _isSending = false;
                    }),
                    onSubmitted: (_) => sendMessage(),
                    textInputAction: TextInputAction.send,
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
                  child: _isSending
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: scheme.onPrimary,
                          ),
                        )
                      : const Icon(Icons.send_rounded, size: 18),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}