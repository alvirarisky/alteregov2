import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../ui/glass.dart';
import '../view_models/chat_view_model.dart';

class ChatScreen extends StatelessWidget {
  final String persona;
  const ChatScreen({super.key, required this.persona});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ChatViewModel>();
    final bool isPushed = Navigator.of(context).canPop();

    if (viewModel.currentUser == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: isPushed ? AppBar(backgroundColor: Colors.transparent, elevation: 0) : null,
        body: const Center(child: Text("Silakan login terlebih dahulu.", style: TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false, // MATIKAN RESIZE GANDA
      appBar: isPushed
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              title: Text(persona, style: const TextStyle(color: Colors.white, fontSize: 16)),
            )
          : null,
      body: Stack(
        children: [
          Positioned(
            top: -60,
            right: -60,
            child: GlowingOrb(width: 240, height: 240, color: const Color(0xFF8B5CF6).withOpacity(0.3)),
          ),
          SafeArea(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: viewModel.getMessagesStream(persona),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text("Gagal memuat pesan.", style: TextStyle(color: Colors.white)));
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFFA78BFA)));

                final messages = snapshot.data?.docs.map((doc) {
                  final data = doc.data();
                  return {"id": doc.id, "sender": data['sender'], "message": data['message'] ?? data['text'] ?? ""};
                }).toList() ?? [];

                return ChatView(
                  persona: persona,
                  messages: messages,
                  isPushed: isPushed,
                  onSend: (text) {
                    context.read<ChatViewModel>().sendMessage(text, persona);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ChatView extends StatefulWidget {
  final String persona;
  final List<Map<String, dynamic>> messages;
  final ValueChanged<String> onSend;
  final bool isPushed;

  const ChatView({super.key, required this.persona, required this.messages, required this.onSend, required this.isPushed});

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
    if (widget.messages.length > oldWidget.messages.length || (oldWidget.messages.isEmpty && widget.messages.isNotEmpty)) {
      _isSending = false;
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
    if (text.isEmpty || _isSending) return;

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (_lastSentText == text && (nowMs - _lastSentAtMs) < 700) return;

    _lastSentText = text;
    _lastSentAtMs = nowMs;

    setState(() => _isSending = true);
    widget.onSend(text);
    controller.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAutoScrollToBottom(force: true));
  }

  void _maybeAutoScrollToBottom({bool force = false}) {
    if (!scrollController.hasClients) return;
    final position = scrollController.position;
    if (!force && (position.maxScrollExtent - position.pixels) > 120) return;
    scrollController.animateTo(position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  Widget chatBubble(String text, bool isUser) {
    final displayText = text.trim().isEmpty ? "..." : text;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: isUser
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18), bottomLeft: Radius.circular(18), bottomRight: Radius.circular(4)),
                  ),
                  child: Text(displayText, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.45)),
                )
              : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    border: Border.all(color: Colors.white.withOpacity(0.14), width: 0.5),
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18), bottomRight: Radius.circular(18), bottomLeft: Radius.circular(4)),
                  ),
                  child: MarkdownBody(
                    data: displayText,
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13, height: 1.45),
                      strong: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    
    // Margin sempurna: Kalau keyboard kebuka cuma butuh 20px biar box nempel persis di atas keyboard!
    final double bottomMargin = widget.isPushed ? 20.0 : (isKeyboardOpen ? 20.0 : 110.0);

    final Map<String, dynamic> pInfo = {
      'Past Self': {'desc': 'Healing & acceptance', 'color': Colors.pinkAccent, 'icon': Icons.history_edu_rounded},
      'Ideal Self': {'desc': 'Versi terbaik dirimu', 'color': const Color(0xFFC4B5FD), 'icon': Icons.star_outline_rounded},
      'Future Self': {'desc': 'Wisdom & direction', 'color': Colors.lightBlueAccent, 'icon': Icons.rocket_launch_outlined},
    }[widget.persona] ?? {'desc': 'Alter Ego', 'color': Colors.tealAccent, 'icon': Icons.auto_awesome};

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            borderRadius: BorderRadius.circular(16),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: (pInfo['color'] as Color).withOpacity(0.3), borderRadius: BorderRadius.circular(12)),
                  child: Icon(pInfo['icon'], size: 18, color: pInfo['color']),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Talking to: ${widget.persona}", style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(pInfo['desc'], style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.4))),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withOpacity(0.25),
                    border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.3), width: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text("Online", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFFC4B5FD))),
                ),
              ],
            ),
          ),
        ),

        Expanded(
          child: widget.messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded, color: Colors.white.withOpacity(0.3), size: 32),
                      const SizedBox(height: 12),
                      Text("Mulai percakapan dengan ${widget.persona}", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: widget.messages.length,
                  itemBuilder: (context, index) {
                    final msg = widget.messages[index];
                    return chatBubble((msg["message"] as String?) ?? "", msg["sender"] == "user");
                  },
                ),
        ),

        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: EdgeInsets.fromLTRB(20, 8, 20, bottomMargin),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    border: Border.all(color: Colors.white.withOpacity(0.15), width: 0.5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TextField(
                    controller: controller,
                    onChanged: (val) => setState(() => _isSending = false),
                    onSubmitted: (_) => sendMessage(),
                    textInputAction: TextInputAction.send,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: "Ketik pesan...",
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  if (controller.text.trim().isNotEmpty && !_isSending) sendMessage();
                },
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _isSending ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}