import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  static const List<String> _personas = ['Past Self', 'Ideal Self', 'Future Self'];
  String _selectedPersona = _personas.first;

  void _selectPersona(String persona) {
    if (!_personas.contains(persona)) return;
    setState(() => _selectedPersona = persona);
  }

  void _switchToChatTab(String persona) {
    _selectPersona(persona);
    setState(() => _currentIndex = 1);
  }

  void _switchToHistoryTab() {
    setState(() => _currentIndex = 3);
  }

  @override
  Widget build(BuildContext context) {
    final chatVM = context.watch<ChatViewModel>();
    // Cek apakah keyboard lagi terbuka
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    final List<Widget> pages = [
      HomeScreen(
        onSelectPersona: _switchToChatTab,
        onSeeAllHistory: _switchToHistoryTab,
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
      ProfileScreen(
        themeMode: widget.themeMode,
        onThemeModeChanged: widget.onThemeModeChanged,
      ),
    ];

    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        // HANYA MAIN SCREEN YANG BOLEH RESIZE SAAT KEYBOARD MUNCUL
        resizeToAvoidBottomInset: true, 
        body: Stack(
          children: [
            IndexedStack(
              index: _currentIndex,
              children: pages,
            ),
            // FLOATING BOTTOM NAV: Hilang otomatis kalau keyboard ngetik kebuka
            if (!isKeyboardOpen)
              Positioned(
                bottom: 24,
                left: 20,
                right: 20,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 8)),
                      BoxShadow(color: const Color(0xFF8B5CF6).withOpacity(0.1), blurRadius: 30, offset: const Offset(0, 0))
                    ],
                  ),
                  child: GlassCard( 
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    borderRadius: BorderRadius.circular(28),
                    bgColor: const Color(0xFF16082A).withOpacity(0.85),
                    borderColor: Colors.white.withOpacity(0.15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNavItem(Icons.home_rounded, 'Home', 0),
                        _buildNavItem(Icons.chat_bubble_outline_rounded, 'Chat', 1),
                        _buildNavItem(Icons.auto_awesome_rounded, 'Reflect', 2),
                        _buildNavItem(Icons.history_rounded, 'History', 3),
                        _buildNavItem(Icons.person_outline_rounded, 'Profile', 4),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isActive = _currentIndex == index;
    final color = isActive ? const Color(0xFFA78BFA) : Colors.white.withOpacity(0.35);

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: isActive ? FontWeight.w600 : FontWeight.normal, color: color)),
            const SizedBox(height: 4),
            Container(width: 4, height: 4, decoration: BoxDecoration(color: isActive ? const Color(0xFFA78BFA) : Colors.transparent, shape: BoxShape.circle)),
          ],
        ),
      ),
    );
  }
}

// Wrapper Tab Chat di MainScreen
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
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false, // MATIKAN RESIZE GANDA
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Chat'),
        actions: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedPersona,
              dropdownColor: const Color(0xFF16082A),
              iconEnabledColor: Colors.white,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              items: personas.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
              onChanged: (val) {
                if (val != null) onPersonaChanged(val);
              },
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Stack(
        children: [
          ChatScreen(persona: selectedPersona),
          if (isWaitingForAI)
            Positioned(
              bottom: isKeyboardOpen ? 80 : 100, // Dinamis menyesuaikan keyboard
              left: 20,
              child: GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                borderRadius: BorderRadius.circular(12),
                child: Row(
                  children: [
                    const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFA78BFA))),
                    const SizedBox(width: 10),
                    Text('$selectedPersona is typing...', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7))),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}