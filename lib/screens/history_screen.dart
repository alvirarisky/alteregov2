import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../ui/glass.dart';

class HistoryScreen extends StatefulWidget {
  final List<String> personas;
  final String selectedPersona;
  final Map<String, List<Map<String, dynamic>>> messagesByPersona;
  final ValueChanged<String> onOpenPersona;

  const HistoryScreen({
    super.key,
    required this.personas,
    required this.selectedPersona,
    required this.messagesByPersona,
    required this.onOpenPersona,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // Ambil 1 pesan terakhir dari TIAP persona buat bikin layout ala List Kontak WA
  Stream<List<Map<String, dynamic>>> _getChatRoomList() async* {
    while (true) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        List<Map<String, dynamic>> roomList = [];
        final firestore = FirebaseFirestore.instance;
        try {
          for (String p in ['Past Self', 'Ideal Self', 'Future Self']) {
            final snap = await firestore.collection('users').doc(user.uid)
                .collection('personaChats').doc(p).collection('messages')
                .orderBy('timestamp', descending: true).limit(1).get();
            if (snap.docs.isNotEmpty) {
              roomList.add(snap.docs.first.data());
            }
          }
          // Sort dari yang paling terakhir dichat
          roomList.sort((a, b) {
            final tA = a['timestamp'] as Timestamp?;
            final tB = b['timestamp'] as Timestamp?;
            if (tA == null) return 1;
            if (tB == null) return -1;
            return tB.compareTo(tA);
          });
          yield roomList;
        } catch (e) {
          yield [];
        }
      }
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned(top: -40, right: -40, child: GlowingOrb(width: 240, height: 240, color: const Color(0xFF6D28D9).withOpacity(0.3))),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Daftar Sesi', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5)),
                      const SizedBox(height: 4),
                      Text('Lanjutkan obrolan dengan alter ego-mu', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.5))),
                    ],
                  ),
                ),
                
                Expanded(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _getChatRoomList(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator(color: Color(0xFFA78BFA)));
                      }
                      
                      final docs = snapshot.data ?? [];

                      if (docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.history_toggle_off_rounded, size: 72, color: Colors.white.withOpacity(0.1)),
                              const SizedBox(height: 20),
                              Text('Belum ada sesi obrolan.', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 15)),
                              const SizedBox(height: 6),
                              Text('Pilih alter ego di halaman Home.', style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 13)),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                        physics: const BouncingScrollPhysics(),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data = docs[index];
                          final personaName = data['persona'] ?? 'Alter Ego';
                          final message = data['message'] ?? data['text'] ?? '';
                          final isUser = data['sender'] == 'user';
                          
                          Color pColor = Colors.tealAccent;
                          IconData pIcon = Icons.auto_awesome;
                          if (personaName == 'Past Self') { pColor = Colors.pinkAccent; pIcon = Icons.history_edu_rounded; }
                          else if (personaName == 'Ideal Self') { pColor = const Color(0xFFC4B5FD); pIcon = Icons.star_outline_rounded; }
                          else if (personaName == 'Future Self') { pColor = Colors.lightBlueAccent; pIcon = Icons.rocket_launch_outlined; }

                          return GestureDetector(
                            onTap: () => widget.onOpenPersona(personaName),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.06), 
                                border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.5), 
                                borderRadius: BorderRadius.circular(20)
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48, height: 48,
                                    decoration: BoxDecoration(color: pColor.withOpacity(0.15), borderRadius: BorderRadius.circular(16), border: Border.all(color: pColor.withOpacity(0.25), width: 0.5)),
                                    child: Icon(pIcon, color: pColor, size: 22),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(personaName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                                            Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.2), size: 18),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text('${isUser ? "Anda: " : ""}$message', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.5)), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}