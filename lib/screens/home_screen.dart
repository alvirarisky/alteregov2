import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../ui/glass.dart';
import 'chat_screen.dart';

class HomeScreen extends StatelessWidget {
  final Function(String)? onSelectPersona;
  final ThemeMode? themeMode;
  final ValueChanged<ThemeMode>? onThemeModeChanged;

  const HomeScreen({
    super.key,
    this.onSelectPersona,
    this.themeMode,
    this.onThemeModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // Ambil nama user yang sedang aktif
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? '';
    final displayName = user?.displayName ??
        (email.isNotEmpty
            ? email.split('@').first.replaceAll('.', ' ').replaceAll('_', ' ')
            : 'there');
    // Capitalize kata pertama
    final firstName = displayName.trim().split(' ').first;
    final greeting = _getGreeting();

    final List<Map<String, dynamic>> personas = [
      {
        'name': 'Past Self',
        'desc': 'Healing & acceptance dari masa lalu.',
        'icon': Icons.history_edu_rounded,
        'color': Colors.pinkAccent,
        'time': '18:12',
      },
      {
        'name': 'Ideal Self',
        'desc': 'Focus & discipline menuju versi terbaik.',
        'icon': Icons.star_outline_rounded,
        'color': Colors.tealAccent,
        'time': '20:05',
      },
      {
        'name': 'Future Self',
        'desc': 'Wisdom & direction dari masa depan.',
        'icon': Icons.rocket_launch_outlined,
        'color': Colors.lightBlueAccent,
        'time': 'Now',
      },
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (onThemeModeChanged != null)
            IconButton(
              icon: Icon(
                themeMode == ThemeMode.dark
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded,
              ),
              onPressed: () {
                onThemeModeChanged!(
                  themeMode == ThemeMode.dark
                      ? ThemeMode.light
                      : ThemeMode.dark,
                );
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Greeting ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$greeting 👋',
                    style: TextStyle(
                      fontSize: 13,
                      color: scheme.onSurface.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _capitalize(firstName),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: scheme.onSurface,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Siapa yang mau kamu ajak ngobrol hari ini?',
                    style: TextStyle(
                      fontSize: 14,
                      color: scheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Persona Carousel ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Text(
                'PERSONAS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.8,
                  color: scheme.onSurface.withValues(alpha: 0.45),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 96,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: personas.length,
                itemBuilder: (context, index) {
                  final p = personas[index];
                  return GestureDetector(
                    onTap: () => _navigateToChat(context, p['name']),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        children: [
                          Container(
                            width: 62,
                            height: 62,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: (p['color'] as Color)
                                  .withValues(alpha: 0.15),
                              border: Border.all(
                                  color: p['color'] as Color, width: 2),
                            ),
                            child: Icon(p['icon'] as IconData,
                                color: p['color'] as Color, size: 28),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            (p['name'] as String).split(' ').first,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Divider(
                height: 28,
                thickness: 1,
                color: scheme.onSurface.withValues(alpha: 0.08),
              ),
            ),

            // ── Messages List ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Text(
                'MESSAGES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.8,
                  color: scheme.onSurface.withValues(alpha: 0.45),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: personas.length,
                itemBuilder: (context, index) {
                  final persona = personas[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () =>
                          _navigateToChat(context, persona['name']),
                      child: GlassCard(
                        padding: const EdgeInsets.all(16),
                        borderRadius: BorderRadius.circular(20),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: (persona['color'] as Color)
                                    .withValues(alpha: 0.15),
                              ),
                              child: Icon(
                                persona['icon'] as IconData,
                                color: persona['color'] as Color,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        persona['name'],
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: scheme.onSurface,
                                        ),
                                      ),
                                      Text(
                                        persona['time'],
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: scheme.onSurface
                                              .withValues(alpha: 0.45),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    persona['desc'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: scheme.onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  void _navigateToChat(BuildContext context, String personaName) {
    if (onSelectPersona != null) {
      onSelectPersona!(personaName);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(persona: personaName),
        ),
      );
    }
  }
}