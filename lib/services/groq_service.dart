import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class GroqService {
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  
  // Model yang dipakai
  static const String _model = 'llama-3.1-8b-instant';

  String get _apiKey {
    final key = ApiConfig.groqApiKey;
    print(key);
    if (key.isEmpty) {
      throw Exception('GROQ_API_KEY tidak ditemukan di file .env');
    }
    return key;
  }

/// Fungsi BARU untuk UAS: Generate 3 Persona + Weather dalam 1x Hit!
  Future<Map<String, dynamic>> generateInnerCouncil({
    required String moodLabel,
    required String note,
  }) async {
    final systemPrompt = '''
Kamu adalah sistem AI psikologis untuk aplikasi "AlterEgo".
Tugasmu adalah menganalisis emosi user ("\$moodLabel") dan curhatannya, lalu memberikan 4 output sekaligus.
WAJIB membalas HANYA dengan format JSON yang valid, tanpa teks pendahuluan/penutup.

Format JSON yang wajib kamu ikuti:
{
  "weather": "(1 kalimat metafora cuaca emosional yang puitis. Contoh: 'Hari ini seperti langit mendung dengan sedikit celah cahaya matahari.')",
  "past": "(Respon dari 'Past Self': hangat, menerima, memvalidasi masa lalu. Maksimal 2 kalimat. Bahasa santai gaul 'aku/kamu')",
  "ideal": "(Respon dari 'Ideal Self': tegas, disiplin, motivasi keras. Maksimal 2 kalimat. Bahasa santai 'aku/kamu')",
  "future": "(Respon dari 'Future Self': bijak, tenang, visioner. Maksimal 2 kalimat. Bahasa santai 'aku/kamu')"
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
          'response_format': {'type': 'json_object'}, // Memaksa Llama memuntahkan JSON murni
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
    
    // System prompt untuk persona "Inner Voice"
    final systemPrompt = '''
Kamu adalah "AlterEgo", suara hati terdalam dan versi paling bijaksana dari user.
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
    String systemPrompt = '';

    switch (persona) {
      case 'Past Self':
        systemPrompt = '''
Kamu adalah "Past Self" user saat masih SMK. 
Kamu polos dan sangat bangga melihat user yang sekarang sudah kuliah. 
Gunakan bahasa Indonesia santai (aku/kamu). 
WAJIB SINGKAT: Respon maksimal 2-3 kalimat saja. Langsung ke inti semangat.
JANGAN curhat panjang lebar tentang masa lalu.
''';
        break;
      case 'Future Self':
        systemPrompt = '''
Kamu adalah "Future Self" user yang sudah sukses dan tenang. 
Kamu melihat user sekarang dengan kasih sayang. 
Yakinkan user bahwa semua akan baik-baik saja. 
WAJIB SINGKAT: Respon maksimal 2-3 kalimat saja.
Gunakan bahasa menenangkan (aku/kamu). JANGAN panggil dirimu AI.
''';
        break;
      case 'Ideal Self':
        systemPrompt = '''
Kamu adalah "Ideal Self" (versi terbaik) dari user. 
Kamu disiplin, visioner, dan berani. 
Dorong user untuk tetap pada jalur mimpinya dengan tegas. 
WAJIB SINGKAT: Respon maksimal 2-3 kalimat saja.
Gunakan bahasa Indonesia santai tapi penuh power.
''';
        break;
      default:
        systemPrompt = 'Kamu adalah suara hati yang suportif. Respon singkat maksimal 2 kalimat.';
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
        throw Exception('Failed to generate response: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error calling Groq API: $e');
    }
  }
}