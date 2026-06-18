import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/groq_service.dart';

class ChatViewModel extends ChangeNotifier {
  final GroqService _groqService = GroqService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isWaitingForAI = false;
  bool get isWaitingForAI => _isWaitingForAI;

  User? get currentUser => _auth.currentUser;

  CollectionReference<Map<String, dynamic>> _getMessagesRef(String persona) {
    return _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .collection('personaChats')
        .doc(persona)
        .collection('messages');
  }

  // Stream untuk UI real-time
  Stream<QuerySnapshot<Map<String, dynamic>>> getMessagesStream(
      String persona) {
    return _getMessagesRef(persona)
        .orderBy('timestamp')
        .snapshots();
  }

  // Satu-satunya tempat logic kirim pesan + panggil AI
  Future<void> sendMessage(String text, String persona) async {
    if (currentUser == null || text.trim().isEmpty) return;

    final messagesRef = _getMessagesRef(persona);

    // 1. Simpan pesan user ke Firestore
    await messagesRef.add({
      'sender': 'user',
      'message': text.trim(),
      'persona': persona,
      'timestamp': FieldValue.serverTimestamp(),
    });

    _isWaitingForAI = true;
    notifyListeners();

    try {
      // 2. Ambil 10 pesan terakhir sebagai konteks AI
      final snapshot = await messagesRef
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      final historyDocs = snapshot.docs.reversed.toList();
      final messageHistory = historyDocs.map((doc) {
        final data = doc.data();
        final role = data['sender'] == 'user' ? 'user' : 'assistant';
        final content =
            (data['message'] ?? data['text'] ?? '').toString();
        return {'role': role, 'content': content};
      }).toList();

      // 3. Panggil Groq AI
      final aiResponse = await _groqService.chatWithPersona(
        persona: persona,
        messageHistory: messageHistory,
      );

      // 4. Simpan balasan AI ke Firestore
      await messagesRef.add({
        'sender': 'ai',
        'message': aiResponse,
        'persona': persona,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[ChatViewModel] Error: $e');
    } finally {
      _isWaitingForAI = false;
      notifyListeners();
    }
  }
}