import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../ui/glass.dart';
import '../view_models/profile_view_model.dart';
import '../view_models/auth_view_model.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  final ThemeMode? themeMode;
  final ValueChanged<ThemeMode>? onThemeModeChanged;

  const ProfileScreen({super.key, this.themeMode, this.onThemeModeChanged});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileViewModel>().fetchProfile();
    });
  }

  // Stream untuk update statistik secara real-time
  Stream<Map<String, String>> _streamUserStats() async* {
    while (true) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        yield {'chat': '0', 'reflect': '0'};
        continue;
      }
      try {
        final refQuery = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('reflections')
            .count()
            .get();

        int totalChat = 0;
        for (String p in ['Past Self', 'Ideal Self', 'Future Self']) {
          final snap = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('personaChats')
              .doc(p)
              .collection('messages')
              .where('sender', isEqualTo: 'user')
              .count()
              .get();
          totalChat += (snap.count ?? 0);
        }

        yield {
          'chat': totalChat.toString(),
          'reflect': refQuery.count.toString(),
        };
      } catch (e) {
        yield {'chat': '0', 'reflect': '0'};
      }
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'alvira@email.com';
    final name = user?.displayName ?? (email.split('@').first);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background Glow
          Positioned(
            top: -100,
            left: MediaQuery.of(context).size.width / 2 - 150,
            child: GlowingOrb(
              width: 300,
              height: 300,
              color: const Color(0xFF8B5CF6).withOpacity(0.25),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // --- AVATAR SECTION ---
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 24),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color.fromRGBO(139, 92, 246, 0.4), Color.fromRGBO(109, 40, 217, 0.6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: const Color.fromRGBO(139, 92, 246, 0.5), width: 1.5),
                          ),
                          child: const Icon(Icons.person_rounded, size: 32, color: Color(0xFFC4B5FD)),
                        ),
                        const SizedBox(height: 16),
                        Text(name, style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 0.5)),
                        const SizedBox(height: 4),
                        Text(email, style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.white.withOpacity(0.5))),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5CF6).withOpacity(0.25),
                            border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.3)),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('Member UAS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFC4B5FD))),
                        ),
                      ],
                    ),
                  ),

                  // --- STATS GRID (REALTIME) ---
                  StreamBuilder<Map<String, String>>(
                    stream: _streamUserStats(),
                    builder: (context, snapshot) {
                      final stats = snapshot.data ?? {'chat': '0', 'reflect': '0'};
                      return GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 1.6,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        children: [
                          _buildStatCard(stats['chat']!, 'Total Pesan'),
                          _buildStatCard(stats['reflect']!, 'Refleksi Diri'),
                          _buildStatCard('1', 'Hari Berturut'),
                          _buildStatCard('Ideal', 'Persona Fav', isAccent: true),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  // --- MENU SECTION ---
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                    child: _buildMenuRow(Icons.edit_note_rounded, 'Edit Profil Lengkap'),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => context.read<AuthViewModel>().logout(),
                    child: _buildMenuRow(Icons.logout_rounded, 'Keluar Akun', color: const Color(0xFFF472B6)),
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, {bool isAccent = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.bold, color: isAccent ? const Color(0xFFA78BFA) : Colors.white)),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.white.withOpacity(0.5), fontWeight: FontWeight.w500), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildMenuRow(IconData icon, String title, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        border: Border.all(color: Colors.white.withOpacity(0.12), width: 0.5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? Colors.white.withOpacity(0.6)),
          const SizedBox(width: 14),
          Expanded(child: Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, color: color ?? Colors.white))),
          Icon(Icons.chevron_right_rounded, size: 18, color: Colors.white.withOpacity(0.3)),
        ],
      ),
    );
  }
}