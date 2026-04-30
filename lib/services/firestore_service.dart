import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/message_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirestoreService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  User get _requireUser {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('User is not signed in.');
    }
    return user;
  }

  CollectionReference<Map<String, dynamic>> _messagesCollection({
    required String uid,
    required String persona,
  }) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('personaChats')
        .doc(persona)
        .collection('messages');
  }

  /// Save 1 message under:
  /// users/{uid}/personaChats/{persona}/messages/{messageId}
  Future<void> saveMessage(MessageModel message) async {
    final user = _requireUser;
    final coll = _messagesCollection(uid: user.uid, persona: message.persona);
    await coll.add(
      message.toMap(
        useServerTimestampIfNull: true,
      ),
    );
  }

  /// Realtime stream of messages ordered by timestamp ascending.
  Stream<List<MessageModel>> getMessagesByPersona(String persona) {
    final user = _requireUser;
    final coll = _messagesCollection(uid: user.uid, persona: persona);

    // Secondary ordering gives stable UI ordering when timestamps are equal
    // (or temporarily null due to pending serverTimestamp).
    final query = coll
        .orderBy('timestamp', descending: false)
        .orderBy(FieldPath.documentId, descending: false);

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map(
            (d) => MessageModel.fromMap(d.data(), fallbackPersona: persona),
          )
          .toList();
    });
  }

  /// One-time fetch of messages ordered by timestamp ascending.
  Future<List<MessageModel>> getMessagesByPersonaOnce(String persona) async {
    final user = _requireUser;
    final coll = _messagesCollection(uid: user.uid, persona: persona);

    final query = coll
        .orderBy('timestamp', descending: false)
        .orderBy(FieldPath.documentId, descending: false);

    final snap = await query.get();
    return snap.docs
        .map(
          (d) => MessageModel.fromMap(d.data(), fallbackPersona: persona),
        )
        .toList();
  }
}

