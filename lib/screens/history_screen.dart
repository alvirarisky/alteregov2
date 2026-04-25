import 'package:flutter/material.dart';
import '../ui/glass.dart';

class HistoryScreen extends StatefulWidget {
  final List<String> personas;
  final String selectedPersona;
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
  late String activePersona;

  @override
  void initState() {
    super.initState();
    activePersona = widget.selectedPersona;
  }

  @override
  void didUpdateWidget(covariant HistoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedPersona != widget.selectedPersona) {
      activePersona = widget.selectedPersona;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final messages = widget.messagesByPersona[activePersona] ?? const [];

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text("History"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Wrap(
              spacing: 8,
              children: widget.personas
                  .map(
                    (p) => ChoiceChip(
                      label: Text(p),
                      selected: activePersona == p,
                      onSelected: (_) {
                        setState(() {
                          activePersona = p;
                        });
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: GlassCard(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.history_rounded,
                            size: 28,
                            color: scheme.onSurface.withValues(alpha: 0.6),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "No messages yet",
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Belum ada chat untuk persona ini.",
                            style: TextStyle(
                              color: scheme.onSurface.withValues(alpha: 0.65),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: 1,
                    itemBuilder: (context, index) {
                      final msg = messages.last;
                      final sender = (msg["sender"] as String?) ?? "";
                      final text = (msg["text"] as String?) ?? "";

                      return InkWell(
                        onTap: () => widget.onOpenPersona(activePersona),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: GlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.chat_bubble_outline_rounded,
                                      size: 18,
                                      color: scheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      activePersona,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  "$sender: $text",
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: scheme.onSurface.withValues(alpha: 0.8),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Tap to continue",
                                  style: TextStyle(
                                    color: scheme.onSurface.withValues(alpha: 0.55),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}