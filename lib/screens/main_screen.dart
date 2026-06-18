import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';

import 'home_screen.dart';
import 'chat_screen.dart';
import 'reflection_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import '../ui/glass.dart';
import '../view_models/chat_view_model.dart';

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
  int _currentIndex = 0;

  // FIX: pindah ke level State biar bisa diakses child widget
  static const List<String> _personas = [
    'Past Self',
    'Ideal Self',
    'Future Self',
  ];

  String _selectedPersona = _personas.first;

  void _selectPersona(String persona) {
    if (!_personas.contains(persona)) return;
    setState(() => _selectedPersona = persona);
  }

  void _switchToChatTab(String persona) {
    _selectPersona(persona);
    setState(() => _currentIndex = 1);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // FIX: tidak double-provide — main.dart sudah provide ChatViewModel
    final chatVM = context.watch<ChatViewModel>();

    // FIX: explicit type List<Widget> agar IndexedStack tidak error
    final List<Widget> pages = [
      HomeScreen(
        onSelectPersona: _switchToChatTab,
        themeMode: widget.themeMode,
        onThemeModeChanged: widget.onThemeModeChanged,
      ),
      _ChatTab(
        selectedPersona: _selectedPersona,
        personas: _personas,
        onPersonaChanged: _selectPersona,
        isWaitingForAI: chatVM.isWaitingForAI,
      ),
      const ReflectionScreen(),
      HistoryScreen(
        personas: _personas,
        selectedPersona: _selectedPersona,
        messagesByPersona: const {},
        onOpenPersona: _switchToChatTab,
      ),
      // FIX: ProfileScreen sekarang bisa diakses — file ada di folder screens/
      ProfileScreen(
        themeMode: widget.themeMode,
        onThemeModeChanged: widget.onThemeModeChanged,
      ),
    ];

    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        body: IndexedStack(
          index: _currentIndex,
          children: pages,
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.10)
                        : Colors.white.withValues(alpha: 0.70),
                    border: Border.all(
                      color: Colors.white
                          .withValues(alpha: isDark ? 0.18 : 0.40),
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: BottomNavigationBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    type: BottomNavigationBarType.fixed,
                    currentIndex: _currentIndex,
                    onTap: (index) => setState(() => _currentIndex = index),
                    selectedItemColor: scheme.primary,
                    unselectedItemColor:
                        scheme.onSurface.withValues(alpha: 0.55),
                    selectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 11),
                    unselectedLabelStyle: const TextStyle(fontSize: 11),
                    items: const [
                      BottomNavigationBarItem(
                        icon: Icon(Icons.home_rounded),
                        label: 'Home',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.chat_bubble_rounded),
                        label: 'Chat',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.auto_awesome_rounded),
                        label: 'Reflect',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.history_rounded),
                        label: 'History',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.person_rounded),
                        label: 'Profile',
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

// ─────────────────────────────────────────────────────────────────────────────
// Chat Tab
// ─────────────────────────────────────────────────────────────────────────────
class _ChatTab extends StatelessWidget {
  final String selectedPersona;
  final List<String> personas;
  final ValueChanged<String> onPersonaChanged;
  final bool isWaitingForAI;

  const _ChatTab({
    required this.selectedPersona,
    required this.personas,
    required this.onPersonaChanged,
    required this.isWaitingForAI,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Chat'),
        actions: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedPersona,
              dropdownColor: scheme.surface,
              iconEnabledColor: scheme.onSurface,
              style: TextStyle(color: scheme.onSurface),
              items: personas
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (val) {
                if (val != null) onPersonaChanged(val);
              },
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Stack(
        children: [
          ChatScreen(persona: selectedPersona),
          if (isWaitingForAI)
            Positioned(
              bottom: 90,
              left: 20,
              child: GlassCard(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
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
                      '$selectedPersona is typing...',
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