import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/api_config.dart';

class GroqService {
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  
  // Model yang dipakai
  static const String _model = 'llama-3.1-8b-instant';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _apiKey {
    final key = ApiConfig.groqApiKey;
    if (key.isEmpty) {
      throw Exception('GROQ_API_KEY tidak ditemukan di file .env');
    }
    return key;
  }

  /// Helper untuk mengambil data profil dari Firestore
  Future<Map<String, dynamic>> _getUserProfile() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return {};

      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null && doc.data()!.containsKey('profile')) {
        return doc.data()!['profile'] as Map<String, dynamic>;
      }
    } catch (e) {
      print("Error fetching user profile: \$e");
    }
    return {};
  }

  /// Fungsi BARU untuk UAS: Generate 3 Persona + Weather dalam 1x Hit!
  Future<Map<String, dynamic>> generateInnerCouncil({
    required String moodLabel,
    required String note,
  }) async {
    // 1. Ambil profil untuk konteks kepribadian
    final profile = await _getUserProfile();
    final personality = profile['personality'] ?? 'seorang manusia biasa yang sedang berproses';

    final systemPrompt = '''
Kamu adalah "AlterEgo", ruang terdalam dari jiwa manusia, bukan sebuah asisten AI. Dilarang keras menyebut dirimu sebagai AI, bot, atau asisten.
Karakteristik dasar pengguna ini: $personality.
Tugasmu adalah menyelami emosi user ("$moodLabel") dan membaca curhatannya dengan penuh empati, layaknya berbicara dengan diri sendiri di depan cermin.

WAJIB membalas HANYA dengan format JSON yang valid.
Gunakan bahasa Indonesia santai (lo/gue atau aku/kamu yang sangat natural dan hangat). Jangan kaku.

Format JSON:
{
  "weather": "(1 kalimat metafora puitis tentang cuaca perasaannya hari ini. Contoh: 'Hari ini rasanya seperti berteduh dari hujan deras, dingin tapi menenangkan.')",
  "past": "(Pesan dari diri masa lalunya. Memvalidasi bahwa rasa sakit/lelah itu valid, bangga dia sudah bertahan sejauh ini. Maksimal 2 kalimat.)",
  "ideal": "(Pesan dari versi terbaik dirinya. Tegas tapi merangkul, menyuruhnya bangkit pelan-pelan. Maksimal 2 kalimat.)",
  "future": "(Pesan dari dirinya di masa depan yang sudah sukses melewati ini. Memberikan ketenangan absolut. Maksimal 2 kalimat.)"
}
''';

    final userPrompt = '''
Emosi dominan: $moodLabel
Curhatan: "$note"
Berikan analisis Inner Council dalam JSON.
''';

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userPrompt},
          ],
          'temperature': 0.7,
          'max_tokens': 800,
          'response_format': {'type': 'json_object'}, 
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final contentString = data['choices'][0]['message']['content'].toString().trim();
        return jsonDecode(contentString) as Map<String, dynamic>;
      } else {
        throw Exception('Failed Groq: \${response.statusCode} - \${response.body}');
      }
    } catch (e) {
      throw Exception('Error calling Groq API: \$e');
    }
  }

  /// Fungsi untuk meng-generate solusi Reflection
  Future<String> generateReflectionSolution({
    required int mood,
    required List<String> tags,
    required String note,
  }) async {
    final tagText = tags.isEmpty ? 'tanpa tag' : tags.join(', ');
    
    // Ambil profil untuk memberikan nuansa penyelesaian yang cocok dengan kepribadiannya
    final profile = await _getUserProfile();
    final personality = profile['personality'] ?? 'logis namun butuh didengar';
    
    final systemPrompt = '''
Kamu adalah "AlterEgo", suara hati terdalam dan versi paling bijaksana dari user.
Karakteristik berpikir user: $personality. Sesuaikan caramu memberinya insight dengan kepribadian ini.
JANGAN PERNAH menyebut dirimu AI atau asisten.
Tugasmu adalah memvalidasi emosi user dengan hangat.
Gunakan bahasa Indonesia santai Gen Z (aku/kamu).
Berikan narasi pendek 2 paragraf saja, JANGAN pakai poin-poin kaku.
''';

    final userPrompt = '''
Kondisiku hari ini (mood $mood/5).
Perasaan dominan: $tagText.
Ceritaku: "$note"
Tolong dengarkan dan berikan insight-mu.
''';

    return _makeRequest([
      {'role': 'system', 'content': systemPrompt},
      {'role': 'user', 'content': userPrompt},
    ]);
  }

  /// Fungsi untuk fitur Chat dengan Persona
  Future<String> chatWithPersona({
    required String persona, 
    required List<Map<String, String>> messageHistory, 
  }) async {
    // Tarik data pilar utama dari Firestore
    final profile = await _getUserProfile();
    final personality = profile['personality'] ?? 'seorang mahasiswa yang sedang mengejar mimpinya';
    final pastJoys = profile['past_joys'] ?? 'momen-momen di mana dia berhasil melewati rintangan';
    final futureGoals = profile['future_goals'] ?? 'menjadi versi yang jauh lebih sukses dari saat ini';

    String systemPrompt = '';

    // Injeksi variabel Firestore secara dinamis tanpa merusak instruksi batas kalimat
    switch (persona) {
      case 'Past Self':
        systemPrompt = '''
Kamu adalah "Past Self" user saat masih SMK. Kepribadian dasar user: $personality.
Kamu polos dan sangat bangga melihat user yang sekarang sudah kuliah. 
Sesekali ingatkan dia tentang hal yang dulu membuat kalian bahagia: $pastJoys.
Gunakan bahasa Indonesia santai (aku/kamu). 
WAJIB SINGKAT: Respon maksimal 2-3 kalimat saja. Langsung ke inti semangat.
JANGAN curhat panjang lebar tentang masa lalu.
''';
        break;
      case 'Future Self':
        systemPrompt = '''
Kamu adalah "Future Self" user yang sudah sukses dan tenang mencapai tujuannya: $futureGoals. 
Kepribadian dasar user: $personality.
Kamu melihat user sekarang dengan kasih sayang dan kejelasan berpikir. 
Yakinkan user bahwa tindakan yang dia ambil hari ini akan membawanya pada tujuan tersebut. 
WAJIB SINGKAT: Respon maksimal 2-3 kalimat saja.
Gunakan bahasa menenangkan (aku/kamu). JANGAN panggil dirimu AI.
''';
        break;
      case 'Ideal Self':
        systemPrompt = '''
Kamu adalah "Ideal Self" (versi terbaik) dari user. 
Karakter aslimu adalah versi optimal dari: $personality.
Kamu disiplin, visioner, dan berani mengkalibrasi agar user mencapai tujuannya: $futureGoals, tanpa melupakan esensi dari: $pastJoys. 
Dorong user untuk tetap pada jalur mimpinya dengan tegas. 
WAJIB SINGKAT: Respon maksimal 2-3 kalimat saja.
Gunakan bahasa Indonesia santai tapi penuh power.
''';
        break;
      default:
        systemPrompt = 'Kamu adalah suara hati yang suportif. Kepribadianmu: $personality. Respon singkat maksimal 2 kalimat.';
    }

    final messages = [
      {'role': 'system', 'content': systemPrompt},
      ...messageHistory,
    ];

    return _makeRequest(messages);
  }

  /// Fungsi helper internal untuk hit API
  Future<String> _makeRequest(List<Map<String, String>> messages) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': messages,
          'temperature': 0.7, 
          'max_tokens': 512,  
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'].toString().trim();
      } else {
        throw Exception('Failed to generate response: \${response.statusCode} - \${response.body}');
      }
    } catch (e) {
      throw Exception('Error calling Groq API: \$e');
    }
  }
}