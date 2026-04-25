import 'dart:math';
import 'package:flutter/material.dart';
import '../ui/glass.dart';

class ReflectionScreen extends StatefulWidget {
  const ReflectionScreen({super.key});

  @override
  State<ReflectionScreen> createState() => _ReflectionScreenState();
}

class _ReflectionScreenState extends State<ReflectionScreen> {
  String? title;
  String? message;

  final List<Map<String, String>> cards = [
    {"title": "The Growth 🌱", "msg": "Lo lagi berkembang, sabar ya."},
    {"title": "The Storm ⛈", "msg": "Ini berat tapi bakal lewat."},
    {"title": "The Light ✨", "msg": "Ada harapan di depan."},
  ];

  void drawCard() {
    final random = Random();
    final card = cards[random.nextInt(cards.length)];

    setState(() {
      title = card["title"];
      message = card["msg"];
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text("Reflection"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GlassCard(
                  child: Column(
                    children: [
                      Icon(Icons.auto_awesome_rounded, color: scheme.primary),
                      const SizedBox(height: 10),
                      Text(
                        "Reflection",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Tarik kartu untuk dapet insight singkat.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: scheme.onSurface.withValues(alpha: 0.65),
                        ),
                      ),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: drawCard,
                        icon: const Icon(Icons.style_rounded),
                        label: const Text("Draw a card"),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                if (title != null)
                  GlassCard(
                    child: Column(
                      children: [
                        Text(
                          title!,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: scheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          message!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: scheme.onSurface.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}