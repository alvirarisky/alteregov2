import 'dart:math';
import 'package:flutter/material.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reflection"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            /// BUTTON TAROT
            GestureDetector(
              onTap: drawCard,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 30, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "🔮 Tarik Kartu",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),

            const SizedBox(height: 30),

            /// HASIL KARTU
            if (title != null)
              Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Text(
                      title!,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      message!,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}