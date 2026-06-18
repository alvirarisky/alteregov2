import 'package:flutter/material.dart';
import '../models/reflection_model.dart';
import '../services/reflection_service.dart';
import '../services/groq_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReflectionViewModel extends ChangeNotifier {
  final ReflectionService _reflectionService = ReflectionService();
  final GroqService _groqService = GroqService();

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  bool _isGenerating = false;
  bool get isGenerating => _isGenerating;

  // ── STATE BARU UNTUK UI DINAMIS ─────────────────────────────
  Map<String, dynamic>? _lastCouncilResult;
  Map<String, dynamic>? get lastCouncilResult => _lastCouncilResult;

  String? _lastWeather;
  String? get lastWeather => _lastWeather;
  // ────────────────────────────────────────────────────────────

  Stream<List<ReflectionModel>> get reflectionsStream =>
      _reflectionService.streamAllReflections();

  Stream<ReflectionModel?> get latestReflectionStream =>
      _reflectionService.streamLatestReflection();

  Future<void> saveBasicReflection({
    required String content,
    required String moodEmoji,
    required String moodLabel,
  }) async {
    if (content.trim().isEmpty) return;
    _isSaving = true;
    notifyListeners();
    try {
      final reflection = ReflectionModel(
        content: content.trim(),
        moodEmoji: moodEmoji,
        moodLabel: moodLabel,
      );
      await _reflectionService.saveReflection(reflection);
    } catch (e) {
      debugPrint('[ReflectionViewModel] Save Error: $e');
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // ── FUNGSI GENERATE AI YANG SUDAH DI-UPDATE ─────────────────
  Future<void> generateAndSaveCouncil({
    required String content,
    required String moodEmoji,
    required String moodLabel,
  }) async {
    if (content.trim().isEmpty) throw Exception("Ceritamu belum diisi!");
    _isGenerating = true;
    // Reset hasil sebelumnya saat loading baru
    _lastWeather = null;
    _lastCouncilResult = null;
    notifyListeners();
    
    try {
      // 1. Hit Llama-3 lewat Groq
      final aiResult = await _groqService.generateInnerCouncil(
        moodLabel: moodLabel,
        note: content.trim(),
      );
      
      final weather = aiResult['weather'] as String? ?? 'Cuaca emosional tidak menentu.';
      final council = {
        'past': aiResult['past'] as String? ?? '...',
        'ideal': aiResult['ideal'] as String? ?? '...',
        'future': aiResult['future'] as String? ?? '...',
      };

      // 2. Simpan ke State Lokal agar UI langsung berubah (MVVM Concept)
      _lastWeather = weather;
      _lastCouncilResult = council;

      // 3. Background task: Tetap simpan ke Firebase (CRUD Requirement UAS)
      final reflection = ReflectionModel(
        content: content.trim(),
        moodEmoji: moodEmoji,
        moodLabel: moodLabel,
        emotionalWeather: weather,
        councilResponses: council,
      );
      await _reflectionService.saveReflection(reflection);

    } catch (e) {
      debugPrint('[ReflectionViewModel] Inner Council Error: $e');
      rethrow;
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  Future<void> updateReflection(String docId, String newContent) async {
    if (newContent.trim().isEmpty) return;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('reflections')
          .doc(docId)
          .update({
        'content': newContent.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[ReflectionViewModel] Update Error: $e');
    }
  }

  Future<void> deleteReflection(String docId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('reflections')
          .doc(docId)
          .delete();
    } catch (e) {
      debugPrint('[ReflectionViewModel] Delete Error: $e');
    }
  }
}