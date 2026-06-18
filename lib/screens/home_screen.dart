import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../ui/glass.dart';
import 'chat_screen.dart';

class HomeScreen extends StatelessWidget {
  final Function(String)? onSelectPersona;
  final VoidCallback? onSeeAllHistory;
  final ThemeMode? themeMode;
  final ValueChanged<ThemeMode>? onThemeModeChanged;

  const HomeScreen({
    super.key,
    this.onSelectPersona,
    this.onSeeAllHistory,
    this.themeMode,
    this.onThemeModeChanged,
  });

  // Custom Live Stream buat narik 1 pesan paling baru dari semua persona
  Stream<Map<String, dynamic>?> _getLatestActivity() async* {
    while (true) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        List<Map<String, dynamic>> allLatest = [];
        final firestore = FirebaseFirestore.instance;
        try {
          for (String p in ['Past Self', 'Ideal Self', 'Future Self']) {
            final snap = await firestore.collection('users').doc(user.uid)
                .collection('personaChats').doc(p).collection('messages')
                .orderBy('timestamp', descending: true).limit(1).get();
            if (snap.docs.isNotEmpty) allLatest.add(snap.docs.first.data());
          }
          if (allLatest.isNotEmpty) {
            allLatest.sort((a, b) {
              final tA = a['timestamp'] as Timestamp?;
              final tB = b['timestamp'] as Timestamp?;
              if (tA == null) return 1;
              if (tB == null) return -1;
              return tB.compareTo(tA);
            });
            yield allLatest.first;
          } else {
            yield null;
          }
        } catch (e) {
          yield null;
        }
      }
      await Future.delayed(const Duration(seconds: 2)); // Refresh per 2 detik
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? '';
    final displayName = user?.displayName ?? (email.isNotEmpty ? email.split('@').first.replaceAll('.', ' ') : 'there');
    final firstName = displayName.trim().split(' ').first;

    final List<Map<String, dynamic>> personas = [
      {'name': 'Past Self', 'desc': 'Healing & acceptance', 'icon': Icons.history_edu_rounded, 'color': Colors.pinkAccent},
      {'name': 'Ideal Self', 'desc': 'Focus & discipline', 'icon': Icons.star_outline_rounded, 'color': const Color(0xFFC4B5FD)},
      {'name': 'Future Self', 'desc': 'Wisdom & direction', 'icon': Icons.rocket_launch_outlined, 'color': Colors.lightBlueAccent},
    ];

    return Scaffold(
      backgroundColor: Colors.transparent, 
      resizeToAvoidBottomInset: false, 
      body: Stack(
        children: [
          Positioned(top: -80, left: -60, child: GlowingOrb(width: 280, height: 280, color: const Color(0xFF6D28D9).withOpacity(0.35))),
          Positioned(top: 200, right: -80, child: GlowingOrb(width: 200, height: 200, color: const Color(0xFF2DD4BF).withOpacity(0.15))),
          
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(left: 20, right: 20, top: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hey, $firstName', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.5), fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          const Text('Gimana perasaanmu\nhari ini?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white, height: 1.2, letterSpacing: -0.5)),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: const Text('Belum ada notifikasi baru.', style: TextStyle(color: Colors.white, fontSize: 12)), backgroundColor: const Color(0xFF1E0F3D), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          );
                        },
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), border: Border.all(color: Colors.white.withOpacity(0.15), width: 0.5), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  GlassCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PILIH ALTER EGO KAMU', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.white.withOpacity(0.4))),
                        const SizedBox(height: 14),
                        Column(
                          children: personas.map((p) {
                            final isIdeal = p['name'] == 'Ideal Self';
                            return GestureDetector(
                              onTap: () => _navigateToChat(context, p['name']),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isIdeal ? const Color(0xFF8B5CF6).withOpacity(0.15) : Colors.white.withOpacity(0.06),
                                  border: Border.all(color: isIdeal ? const Color(0xFF8B5CF6).withOpacity(0.35) : Colors.white.withOpacity(0.12), width: 0.5),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44, height: 44,
                                      decoration: BoxDecoration(color: (p['color'] as Color).withOpacity(0.2), borderRadius: BorderRadius.circular(14), border: Border.all(color: (p['color'] as Color).withOpacity(0.3), width: 0.5)),
                                      child: Icon(p['icon'] as IconData, color: p['color'] as Color, size: 22),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(p['name'], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                                          const SizedBox(height: 2),
                                          Text(p['desc'], style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5))),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(isIdeal ? 0.4 : 0.2), size: 18),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Aktivitas Terakhir', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.8))),
                      GestureDetector(
                        onTap: onSeeAllHistory,
                        child: Container(color: Colors.transparent, padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8), child: const Text('Lihat semua', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFA78BFA)))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // LIVE ACTIVITY BUILDER
                  StreamBuilder<Map<String, dynamic>?>(
                    stream: _getLatestActivity(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
                          child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFA78BFA)))),
                        );
                      }
                      
                      final data = snapshot.data;
                      if (data == null) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.5)),
                          child: Center(child: Text('Belum ada aktivitas chat.', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.4)))),
                        );
                      }

                      final pName = data['persona'] ?? 'Alter Ego';
                      final msg = data['message'] ?? data['text'] ?? '...';
                      final isUser = data['sender'] == 'user';
                      
                      Color pColor = Colors.tealAccent;
                      IconData pIcon = Icons.auto_awesome;
                      if (pName == 'Past Self') { pColor = Colors.pinkAccent; pIcon = Icons.history_edu_rounded; }
                      else if (pName == 'Ideal Self') { pColor = const Color(0xFFC4B5FD); pIcon = Icons.star_outline_rounded; }
                      else if (pName == 'Future Self') { pColor = Colors.lightBlueAccent; pIcon = Icons.rocket_launch_outlined; }

                      return GestureDetector(
                        onTap: () => _navigateToChat(context, pName),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.5), borderRadius: BorderRadius.circular(16)),
                          child: Row(
                            children: [
                              Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(color: pColor.withOpacity(0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: pColor.withOpacity(0.3), width: 0.5)),
                                child: Icon(pIcon, color: pColor, size: 18),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(pName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                                    const SizedBox(height: 4),
                                    Text('${isUser ? "Lu: " : ""}$msg', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5)), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
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

  void _navigateToChat(BuildContext context, String personaName) {
    if (onSelectPersona != null) {
      onSelectPersona!(personaName);
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(persona: personaName)));
    }
  }
}