import 'package:flutter/material.dart';
import 'chat_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void goToChat(BuildContext context, String persona) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(persona: persona),
      ),
    );
  }

Widget personaCard(BuildContext context, String title, IconData icon) {
  return GestureDetector(
    onTap: () => goToChat(context, title),
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.deepPurple,
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AlterEgo")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Pilih Persona",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            personaCard(context, "Past Self", Icons.child_care),
            personaCard(context, "Ideal Self", Icons.star),
            personaCard(context, "Future Self", Icons.rocket),
          ],
        ),
      ),
    );
  }
}