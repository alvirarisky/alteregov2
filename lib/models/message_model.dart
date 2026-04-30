import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String sender;
  final String message;
  final String persona;
  final DateTime? timestamp;

  const MessageModel({
    required this.sender,
    required this.message,
    required this.persona,
    this.timestamp,
  });

  /// Compatibility with older UI that still reads `.text`.
  String get text => message;

  /// Firestore-friendly map with fields:
  /// sender, message, persona, timestamp.
  ///
  /// If [timestamp] is null, we can optionally store a server timestamp to keep
  /// ordering usable for chat UI.
  Map<String, dynamic> toMap({
    bool useServerTimestampIfNull = true,
  }) {
    return <String, dynamic>{
      'sender': sender,
      'message': message,
      'persona': persona,
      'timestamp': timestamp != null
          ? Timestamp.fromDate(timestamp!)
          : (useServerTimestampIfNull ? FieldValue.serverTimestamp() : null),
    }..removeWhere((_, v) => v == null);
  }

  /// Build [MessageModel] from Firestore map.
  ///
  /// Supports:
  /// - Firestore [Timestamp]
  /// - raw [DateTime] (tests / local)
  /// - legacy key `text` for message body
  factory MessageModel.fromMap(
    Map<String, dynamic> map, {
    String? fallbackPersona,
  }) {
    final dynamic ts = map['timestamp'];
    DateTime? dt;
    if (ts is Timestamp) {
      dt = ts.toDate();
    } else if (ts is DateTime) {
      dt = ts;
    }

    return MessageModel(
      sender: (map['sender'] as String?) ?? 'user',
      message: (map['message'] as String?) ?? (map['text'] as String?) ?? '',
      persona: (map['persona'] as String?) ?? (fallbackPersona ?? ''),
      timestamp: dt,
    );
  }

  MessageModel copyWith({
    String? sender,
    String? message,
    String? persona,
    DateTime? timestamp,
  }) {
    return MessageModel(
      sender: sender ?? this.sender,
      message: message ?? this.message,
      persona: persona ?? this.persona,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Backward-compatible alias for older code in this project.
  @Deprecated('Use toMap()')
  Map<String, dynamic> toMapForFirestore({
    bool useServerTimestampIfNull = true,
  }) =>
      toMap(useServerTimestampIfNull: useServerTimestampIfNull);

  /// Backward-compatible alias for older code in this project.
  @Deprecated('Use MessageModel.fromMap()')
  static MessageModel fromFirestoreMap(
    Map<String, dynamic> map, {
    required String fallbackPersona,
  }) =>
      MessageModel.fromMap(map, fallbackPersona: fallbackPersona);
}

