import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dummy = ["Chat 1", "Chat 2", "Chat 3"];

    return Scaffold(
      appBar: AppBar(
        title: const Text("History"),
        backgroundColor: Colors.deepPurple,
      ),
      body: ListView.builder(
        itemCount: dummy.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(dummy[index]),
          );
        },
      ),
    );
  }
}