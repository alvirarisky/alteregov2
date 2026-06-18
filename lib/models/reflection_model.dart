import 'package:cloud_firestore/cloud_firestore.dart';

class ReflectionModel {
  final String? id;
  final String content;
  final String moodEmoji;
  final String moodLabel;
  final String? emotionalWeather;
  final Map<String, dynamic>? councilResponses;
  final DateTime? createdAt;

  const ReflectionModel({
    this.id,
    required this.content,
    required this.moodEmoji,
    required this.moodLabel,
    this.emotionalWeather,
    this.councilResponses,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'moodEmoji': moodEmoji,
      'moodLabel': moodLabel,
      'emotionalWeather': emotionalWeather,
      'councilResponses': councilResponses,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    }..removeWhere((_, v) => v == null);
  }

  factory ReflectionModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime? toDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      return null;
    }

    return ReflectionModel(
      id: docId,
      content: map['content'] as String? ?? '',
      moodEmoji: map['moodEmoji'] as String? ?? '😐',
      moodLabel: map['moodLabel'] as String? ?? 'neutral',
      emotionalWeather: map['emotionalWeather'] as String?,
      councilResponses: map['councilResponses'] as Map<String, dynamic>?,
      createdAt: toDate(map['createdAt']),
    );
  }
}