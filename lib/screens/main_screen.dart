import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'home_screen.dart';
import 'chat_screen.dart'; // Tetap biarkan import-nya meskipun ChatScreen asli udah jarang dipakai
import 'reflection_screen.dart';
import 'history_screen.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../ui/glass.dart';
import 'dart:ui';
import '../models/message_model.dart';
import '../services/firestore_service.dart';
import '../services/groq_service.dart'; // [TAMBAH INI] Import Groq Service

class MainScreen extends StatefulWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  const MainScreen({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentIndex = 0;
  int lastNonChatIndex = 0;

  static const List<String> personas = ["Past Self", "Ideal Self", "Future Self"];
  static const _prefsKeyLastPersona = 'alterego_last_persona';
  static const _prefsKeyMessagesByPersona = 'alterego_messages_by_persona';

  String? selectedPersona;
  final Map<String, List<Map<String, dynamic>>> messagesByPersona = {
    "Past Self": [],
    "Ideal Self": [],
    "Future Self": [],
  };

  bool isLoadingPersistedState = true;
  final List<StreamSubscription<List<MessageModel>>> _subs = [];
  StreamSubscription<User?>? _authSub;
  final FirestoreService _firestoreService = FirestoreService();
  final GroqService _groqService = GroqService(); // [TAMBAH INI] Inisialisasi AI

  final Map<String, bool> _sendingByPersona = {};
  final Map<String, String> _lastUserTextByPersona = {};
  final Map<String, int> _lastUserTextAtMsByPersona = {};
  final Map<String, int> _lastStreamErrorAtMsByPersona = {};

  @override
  void initState() {
    super.initState();
    _loadPersistedState();
    _listenToAuthChanges();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }

  void _listenToAuthChanges() {
    _authSub?.cancel();

    if (Firebase.apps.isEmpty) return;
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted) return;

      if (user == null) {
        for (final s in _subs) {
          s.cancel();
        }
        _subs.clear();
        _sendingByPersona.clear();
        _lastUserTextByPersona.clear();
        _lastUserTextAtMsByPersona.clear();
        _lastStreamErrorAtMsByPersona.clear();
        setState(() {
          for (final persona in personas) {
            messagesByPersona[persona] = [];
          }
        });
        return;
      }

      _startFirestoreListenersIfSignedIn();
    });
  }

  Future<void> _loadPersistedState() async {
    final prefs = await SharedPreferences.getInstance();
    final lastPersona = prefs.getString(_prefsKeyLastPersona);
    final messagesJson = prefs.getString(_prefsKeyMessagesByPersona);

    if (!mounted) return;

    setState(() {
      selectedPersona = (lastPersona != null && personas.contains(lastPersona))
          ? lastPersona
          : personas.first;

      if (Firebase.apps.isEmpty && messagesJson != null && messagesJson.isNotEmpty) {
        try {
          final decoded = jsonDecode(messagesJson);
          if (decoded is Map<String, dynamic>) {
            for (final persona in personas) {
              final list = decoded[persona];
              if (list is List) {
                messagesByPersona[persona] = list
                    .whereType<Map>()
                    .map((m) => Map<String, dynamic>.from(m))
                    .toList();
              }
            }
          }
        } catch (_) {}
      }

      isLoadingPersistedState = false;
    });

    _startFirestoreListenersIfSignedIn();
  }

  void _startFirestoreListenersIfSignedIn() {
    if (Firebase.apps.isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();

    for (final personaName in personas) {
      final sub = _firestoreService.getMessagesByPersona(personaName).listen((msgs) {
        final mapped = msgs
            .map(
              (m) => <String, dynamic>{
                "sender": m.sender,
                "text": m.message,
                "message": m.message, // [FIX UI]: Pastikan 'message' ter-mapping juga!
                "ts": m.timestamp?.millisecondsSinceEpoch,
              },
            )
            .toList();
        if (!mounted) return;
        setState(() {
          messagesByPersona[personaName] = mapped;
        });
      }, onError: (e, st) {
        if (kDebugMode) {
          debugPrint('[Firestore][ERROR] persona="$personaName" stream error: $e');
        }
        final now = DateTime.now().millisecondsSinceEpoch;
        final lastAt = _lastStreamErrorAtMsByPersona[personaName] ?? 0;
        if (mounted && (now - lastAt) > 6000) {
          _lastStreamErrorAtMsByPersona[personaName] = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Koneksi bermasalah. Mencoba sinkron ulang chat...'),
            ),
          );
        }
      });
      _subs.add(sub);
    }
  }

  Future<void> _persistState() async {
    final prefs = await SharedPreferences.getInstance();
    final personaToSave = selectedPersona ?? personas.first;
    await prefs.setString(_prefsKeyLastPersona, personaToSave);
    if (Firebase.apps.isEmpty) {
      await prefs.setString(_prefsKeyMessagesByPersona, jsonEncode(messagesByPersona));
    }
  }

  void _selectPersona(String persona) {
    if (!personas.contains(persona)) return;
    setState(() {
      selectedPersona = persona;
    });
    _persistState();
  }

  void _switchToChatTabWithPersona(String persona) {
    _selectPersona(persona);
    setState(() {
      if (currentIndex != 1) {
        lastNonChatIndex = currentIndex;
      }
      currentIndex = 1;
    });
  }

  // =======================================================================
  // [BAGIAN PALING PENTING]: LOGIKA AI GROQ DI DALAM FUNGSI SEND MESSAGE
  // =======================================================================
  void _sendMessageForSelectedPersona(String text) async {
    final persona = selectedPersona ?? personas.first;
    final now = DateTime.now().millisecondsSinceEpoch;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final lastText = _lastUserTextByPersona[persona];
    final lastAt = _lastUserTextAtMsByPersona[persona] ?? 0;
    if (lastText == trimmed && (now - lastAt) < 700) return;
    
    _lastUserTextByPersona[persona] = trimmed;
    _lastUserTextAtMsByPersona[persona] = now;

    if (_sendingByPersona[persona] == true) return;

    setState(() {
      _sendingByPersona[persona] = true;
    });

    try {
      // Jika pakai Firebase, kita simpan pesan user dulu
      if (Firebase.apps.isNotEmpty && FirebaseAuth.instance.currentUser != null) {
        final userMessage = MessageModel(
          sender: "user",
          message: trimmed,
          persona: persona,
          timestamp: DateTime.now(),
        );
        await _firestoreService.saveMessage(userMessage);

        // Siapkan history untuk Groq (diambil dari state lokal messagesByPersona)
        final history = (messagesByPersona[persona] ?? []).map((msg) {
          final role = msg['sender'] == 'user' ? 'user' : 'assistant';
          final content = (msg['message'] ?? msg['text'] ?? '').toString();
          return {'role': role, 'content': content};
        }).toList();

        // [PANGGIL AI GROQ]
        final aiResponse = await _groqService.chatWithPersona(
          persona: persona,
          messageHistory: history,
        );

        // Simpan balasan AI ke Firestore
        final botMessage = MessageModel(
          sender: "ai", // atau bisa diganti "bot" sesuai kesepakatan aplikasi lo
          message: aiResponse,
          persona: persona,
          timestamp: DateTime.now(),
        );
        await _firestoreService.saveMessage(botMessage);
      } else {
        // Fallback kalau gak login / ga pakai Firebase (hanya UI test)
        final aiResponse = await _groqService.chatWithPersona(
          persona: persona,
          messageHistory: [], // Simulasi history kosong
        );
        setState(() {
          messagesByPersona[persona] = [
            ...messagesByPersona[persona]!,
            {"sender": "user", "text": trimmed, "message": trimmed, "ts": now},
            {"sender": "ai", "text": aiResponse, "message": aiResponse, "ts": now + 1},
          ];
        });
        _persistState();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[ERROR AI]: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal generate pesan dari AI: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _sendingByPersona[persona] = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final persona = selectedPersona ?? personas.first;
    final chatMessages = messagesByPersona[persona] ?? const [];

    final pages = [
      HomeScreen(
        onSelectPersona: _switchToChatTabWithPersona,
        themeMode: widget.themeMode,
        onThemeModeChanged: widget.onThemeModeChanged,
      ),
      ChatTabScreen(
        personas: personas,
        selectedPersona: persona,
        messages: chatMessages,
        onPersonaChanged: _selectPersona,
        onSend: _sendMessageForSelectedPersona,
        // Lempar status 'sedang ngetik AI' ke ChatTabScreen untuk UI loading
        isSending: _sendingByPersona[persona] ?? false, 
        onBack: () {
          setState(() {
            currentIndex = lastNonChatIndex;
          });
        },
      ),
      const ReflectionScreen(),
      HistoryScreen(
        personas: personas,
        selectedPersona: persona,
        messagesByPersona: messagesByPersona,
        onOpenPersona: _switchToChatTabWithPersona,
      ),
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        body: isLoadingPersistedState
            ? const Center(child: CircularProgressIndicator())
            : pages[currentIndex],
        bottomNavigationBar: currentIndex == 1
            ? null
            : SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: (isDark
                                  ? Colors.white.withValues(alpha: 0.10)
                                  : Colors.white.withValues(alpha: 0.70))
                              .withValues(alpha: isDark ? 0.10 : 0.70),
                          border: Border.all(
                            color: Colors.white.withValues(
                              alpha: isDark ? 0.18 : 0.40,
                            ),
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: BottomNavigationBar(
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          type: BottomNavigationBarType.fixed,
                          currentIndex: currentIndex,
                          onTap: (index) {
                            setState(() {
                              if (currentIndex != 1 && index != 1) {
                                lastNonChatIndex = index;
                              } else if (currentIndex != 1 && index == 1) {
                                lastNonChatIndex = currentIndex;
                              }
                              currentIndex = index;
                            });
                          },
                          selectedItemColor: Theme.of(context).colorScheme.primary,
                          unselectedItemColor: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.55),
                          items: const [
                            BottomNavigationBarItem(
                              icon: Icon(Icons.home),
                              label: "Home",
                            ),
                            BottomNavigationBarItem(
                              icon: Icon(Icons.chat_bubble),
                              label: "Chat",
                            ),
                            BottomNavigationBarItem(
                              icon: Icon(Icons.auto_awesome),
                              label: "Reflect",
                            ),
                            BottomNavigationBarItem(
                              icon: Icon(Icons.history),
                              label: "History",
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class ChatTabScreen extends StatelessWidget {
  final List<String> personas;
  final String selectedPersona;
  final List<Map<String, dynamic>> messages;
  final ValueChanged<String> onPersonaChanged;
  final ValueChanged<String> onSend;
  final bool isSending; // Parameter baru untuk loading state
  final VoidCallback? onBack;

  const ChatTabScreen({
    super.key,
    required this.personas,
    required this.selectedPersona,
    required this.messages,
    required this.onPersonaChanged,
    required this.onSend,
    this.isSending = false,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text("Chat"),
        actions: [
          if (onBack != null)
            IconButton(
              tooltip: 'Back',
              onPressed: onBack,
              icon: const Icon(Icons.close_rounded),
            ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedPersona,
              dropdownColor: scheme.surface,
              iconEnabledColor: scheme.onSurface,
              style: TextStyle(color: scheme.onSurface),
              items: personas
                  .map(
                    (p) => DropdownMenuItem<String>(
                      value: p,
                      child: Text(p),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                onPersonaChanged(value);
              },
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Stack(
        children: [
          // Panggil ChatView asli milik lo yang ada di chat_screen.dart
          ChatView(
            persona: selectedPersona,
            messages: messages,
            onSend: onSend,
          ),
          // Tambahkan efek loading "AI is typing..." jika sedang send message ke Groq
          if (isSending)
            Positioned(
              bottom: 90,
              left: 20,
              child: GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                borderRadius: BorderRadius.circular(12),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "$selectedPersona is typing...",
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}