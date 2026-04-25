import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'home_screen.dart';
import 'chat_screen.dart';
import 'reflection_screen.dart';
import 'history_screen.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../ui/glass.dart';
import 'dart:ui';

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

  static const Map<String, String> personaIdByName = {
    "Past Self": "past",
    "Ideal Self": "ideal",
    "Future Self": "future",
  };

  String? selectedPersona;
  final Map<String, List<Map<String, dynamic>>> messagesByPersona = {
    "Past Self": [],
    "Ideal Self": [],
    "Future Self": [],
  };

  bool isLoadingPersistedState = true;
  final List<StreamSubscription<QuerySnapshot<Map<String, dynamic>>>> _subs = [];

  @override
  void initState() {
    super.initState();
    _loadPersistedState();
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
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

      // Local messages only used for widget tests / when Firebase not available.
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

    final firestore = FirebaseFirestore.instance;
    for (final personaName in personas) {
      final personaId = personaIdByName[personaName]!;
      final sub = firestore
          .collection('users')
          .doc(user.uid)
          .collection('personas')
          .doc(personaId)
          .collection('messages')
          .orderBy('ts')
          .snapshots()
          .listen((snapshot) {
        final mapped = snapshot.docs.map((d) {
          final data = d.data();
          return {
            "sender": data["sender"],
            "text": data["text"],
            "ts": data["ts"],
          };
        }).toList();

        if (!mounted) return;
        setState(() {
          messagesByPersona[personaName] = mapped;
        });
      });
      _subs.add(sub);
    }
  }

  Future<void> _persistState() async {
    final prefs = await SharedPreferences.getInstance();
    final personaToSave = selectedPersona ?? personas.first;
    await prefs.setString(_prefsKeyLastPersona, personaToSave);
    // Keep local persistence only for non-Firebase environments (tests).
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

  void _sendMessageForSelectedPersona(String text) {
    final persona = selectedPersona ?? personas.first;
    final now = DateTime.now().millisecondsSinceEpoch;

    String reply;
    if (persona == "Past Self") {
      reply = "Aku ngerti... jangan takut ya.";
    } else if (persona == "Ideal Self") {
      reply = "Kamu pasti bisa, tetap fokus.";
    } else {
      reply = "Ini bagian dari proses, tetap jalan.";
    }

    if (Firebase.apps.isNotEmpty && FirebaseAuth.instance.currentUser != null) {
      final user = FirebaseAuth.instance.currentUser!;
      final firestore = FirebaseFirestore.instance;
      final personaId = personaIdByName[persona]!;
      final coll = firestore
          .collection('users')
          .doc(user.uid)
          .collection('personas')
          .doc(personaId)
          .collection('messages');

      final batch = firestore.batch();
      final userDoc = coll.doc();
      batch.set(userDoc, {
        "sender": "user",
        "text": text,
        "ts": FieldValue.serverTimestamp(),
      });
      final botDoc = coll.doc();
      batch.set(botDoc, {
        "sender": "bot",
        "text": reply,
        "ts": FieldValue.serverTimestamp(),
      });
      batch.commit();
    } else {
      // Fallback local (widget tests / no Firebase).
      setState(() {
        messagesByPersona[persona] = [
          ...messagesByPersona[persona]!,
          {"sender": "user", "text": text, "ts": now},
          {"sender": "bot", "text": reply, "ts": now + 1},
        ];
      });
      _persistState();
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
  final VoidCallback? onBack;

  const ChatTabScreen({
    super.key,
    required this.personas,
    required this.selectedPersona,
    required this.messages,
    required this.onPersonaChanged,
    required this.onSend,
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
      body: ChatView(
        persona: selectedPersona,
        messages: messages,
        onSend: onSend,
      ),
    );
  }
}