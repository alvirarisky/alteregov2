import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../ui/glass.dart';

class HistoryScreen extends StatefulWidget {
  final List<String> personas;
  final String selectedPersona;
  // messagesByPersona dipertahankan untuk kompatibilitas, tapi History
  // sekarang fetch langsung dari Firestore via stream
  final Map<String, List<Map<String, dynamic>>> messagesByPersona;
  final ValueChanged<String> onOpenPersona;

  const HistoryScreen({
    super.key,
    required this.personas,
    required this.selectedPersona,
    required this.messagesByPersona,
    required this.onOpenPersona,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late String _activePersona;

  @override
  void initState() {
    super.initState();
    _activePersona = widget.selectedPersona;
  }

  @override
  void didUpdateWidget(covariant HistoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedPersona != widget.selectedPersona) {
      setState(() => _activePersona = widget.selectedPersona);
    }
  }

  // Stream Firestore langsung — fix dari versi sebelumnya yang pakai local map
  Stream<QuerySnapshot<Map<String, dynamic>>> _getMessagesStream(
      String persona) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('personaChats')
        .doc(persona)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'History',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Filter Bar ──────────────────────────────────────────
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: widget.personas.map((p) {
                  final isSelected = _activePersona == p;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: InkWell(
                      onTap: () => setState(() => _activePersona = p),
                      borderRadius: BorderRadius.circular(20),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 9),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? scheme.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? scheme.primary
                                : scheme.onSurface.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected) ...[
                              Icon(Icons.check_rounded,
                                  size: 14,
                                  color: scheme.onPrimary),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              p,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? scheme.onPrimary
                                    : scheme.onSurface
                                        .withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── Message List (stream dari Firestore) ─────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _getMessagesStream(_activePersona),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Gagal memuat history.',
                      style: TextStyle(
                          color: scheme.onSurface.withValues(alpha: 0.5)),
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 44,
                          color: scheme.primary.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Mulai ngobrol sama $_activePersona\ndi menu Chat.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color:
                                scheme.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Grouping: ambil preview dari pesan terakhir
                final lastDoc = docs.last.data();
                // FIX: pakai field 'message', bukan 'text'
                final lastMessage =
                    (lastDoc['message'] as String?) ?? '';
                final lastSender =
                    (lastDoc['sender'] as String?) ?? 'user';
                final totalMessages = docs.length;

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // Card summary sesi
                    InkWell(
                      onTap: () => widget.onOpenPersona(_activePersona),
                      borderRadius: BorderRadius.circular(24),
                      child: GlassCard(
                        padding: const EdgeInsets.all(20),
                        borderRadius: BorderRadius.circular(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: scheme.primary
                                        .withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.auto_awesome_rounded,
                                    size: 16,
                                    color: scheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _activePersona,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: scheme.onSurface,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: scheme.primary
                                        .withValues(alpha: 0.1),
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '$totalMessages msgs',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: scheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: scheme.onSurface
                                    .withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                // FIX: label sender yang benar
                                '${lastSender == 'user' ? 'Kamu' : _activePersona}: $lastMessage',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  height: 1.4,
                                  color: scheme.onSurface
                                      .withValues(alpha: 0.75),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'Tap to continue →',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: scheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Semua pesan ditampilkan sebagai timeline
                    // FIX: dulu itemCount: 1, sekarang semua pesan tampil
                    ...docs.map((doc) {
                      final data = doc.data();
                      // FIX: field 'message', bukan 'text'
                      final text = (data['message'] as String?) ?? '';
                      final sender =
                          (data['sender'] as String?) ?? 'user';
                      final isUser = sender == 'user';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: isUser
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          children: [
                            if (!isUser)
                              Container(
                                margin: const EdgeInsets.only(
                                    right: 8, top: 4),
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: scheme.primary
                                      .withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 12,
                                  color: scheme.primary,
                                ),
                              ),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isUser
                                      ? scheme.primary
                                          .withValues(alpha: 0.15)
                                      : scheme.onSurface
                                          .withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: Radius.circular(
                                        isUser ? 16 : 4),
                                    bottomRight: Radius.circular(
                                        isUser ? 4 : 16),
                                  ),
                                ),
                                child: Text(
                                  text,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: scheme.onSurface
                                        .withValues(alpha: 0.85),
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ),
                            if (isUser)
                              Container(
                                margin: const EdgeInsets.only(
                                    left: 8, top: 4),
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: scheme.primary
                                      .withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.person_rounded,
                                  size: 12,
                                  color: scheme.primary,
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}