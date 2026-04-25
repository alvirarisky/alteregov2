import 'package:flutter/material.dart';
import '../ui/glass.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class HomeScreen extends StatelessWidget {
  final ValueChanged<String> onSelectPersona;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  const HomeScreen({
    super.key,
    required this.onSelectPersona,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  Widget personaCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => onSelectPersona(title),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: GlassCard(
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: scheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: scheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: scheme.onSurface.withValues(alpha: 0.45),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text("AlterEgo"),
        actions: [
          if (Firebase.apps.isNotEmpty && FirebaseAuth.instance.currentUser != null)
            IconButton(
              tooltip: 'Logout',
              onPressed: () => FirebaseAuth.instance.signOut(),
              icon: const Icon(Icons.logout_rounded),
            ),
          IconButton(
            tooltip: 'Toggle theme',
            onPressed: () {
              final next =
                  themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
              onThemeModeChanged(next);
            },
            icon: Icon(
              themeMode == ThemeMode.dark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Choose a persona",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Pilih alter ego yang paling cocok buat mood kamu sekarang.",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 20),
            personaCard(context, "Past Self", "healing & acceptance", Icons.child_care),
            personaCard(context, "Ideal Self", "focus & discipline", Icons.star_rounded),
            personaCard(context, "Future Self", "vision & direction", Icons.rocket_launch_rounded),
          ],
        ),
      ),
    );
  }
}