import 'package:cloud_firestore/cloud_firestore.dart';

class ReflectionModel {
  final int mood; // 1..5
  final List<String> tags;
  final String note;
  final DateTime? createdAt;
  final String? aiResponse;
  final DateTime? aiGeneratedAt;

  const ReflectionModel({
    required this.mood,
    required this.tags,
    required this.note,
    this.createdAt,
    this.aiResponse,
    this.aiGeneratedAt,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'mood': mood,
      'tags': tags,
      'note': note,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'aiResponse': aiResponse,
      'aiGeneratedAt':
          aiGeneratedAt != null ? Timestamp.fromDate(aiGeneratedAt!) : null,
      'version': 1,
    }..removeWhere((_, v) => v == null);
  }

  factory ReflectionModel.fromMap(Map<String, dynamic> map) {
    DateTime? toDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      return null;
    }

    return ReflectionModel(
      mood: (map['mood'] as int?) ?? 3,
      tags: (map['tags'] is List)
          ? (map['tags'] as List).whereType<String>().toList()
          : const [],
      note: (map['note'] as String?) ?? '',
      createdAt: toDate(map['createdAt']),
      aiResponse: map['aiResponse'] as String?,
      aiGeneratedAt: toDate(map['aiGeneratedAt']),
    );
  }
}

