import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../ui/glass.dart';
import '../view_models/reflection_view_model.dart';

class ReflectionScreen extends StatefulWidget {
  const ReflectionScreen({super.key});

  @override
  State<ReflectionScreen> createState() => _ReflectionScreenState();
}

class _ReflectionScreenState extends State<ReflectionScreen> with SingleTickerProviderStateMixin {
  int _selectedMoodIndex = 2;
  final List<String> _selectedTags = [];
  final TextEditingController _storyController = TextEditingController();
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final List<Map<String, dynamic>> _moods = [
    {'icon': Icons.sentiment_very_dissatisfied_rounded, 'color': const Color(0xFFEF4444), 'label': 'Hancur'},
    {'icon': Icons.sentiment_dissatisfied_rounded, 'color': const Color(0xFFF59E0B), 'label': 'Capek'},
    {'icon': Icons.sentiment_neutral_rounded, 'color': const Color(0xFF9CA3AF), 'label': 'Kosong'},
    {'icon': Icons.sentiment_satisfied_rounded, 'color': const Color(0xFF10B981), 'label': 'Tenang'},
    {'icon': Icons.sentiment_very_satisfied_rounded, 'color': const Color(0xFF8B5CF6), 'label': 'On Fire'},
  ];

  final Map<String, Map<String, Color>> _tagColors = {
    'fokus': {'bg': const Color(0xFFA78BFA).withOpacity(0.2), 'border': const Color(0xFFA78BFA).withOpacity(0.4), 'text': const Color(0xFFC4B5FD)},
    'motivasi': {'bg': const Color(0xFF2DD4BF).withOpacity(0.15), 'border': const Color(0xFF2DD4BF).withOpacity(0.35), 'text': const Color(0xFF5EEAD4)},
    'cemas': {'bg': const Color(0xFFF472B6).withOpacity(0.15), 'border': const Color(0xFFF472B6).withOpacity(0.35), 'text': const Color(0xFFF9A8D4)},
    'stress': {'bg': Colors.white.withOpacity(0.06), 'border': Colors.white.withOpacity(0.1), 'text': Colors.white54},
    'capek': {'bg': Colors.white.withOpacity(0.06), 'border': Colors.white.withOpacity(0.1), 'text': Colors.white54},
  };

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutQuart));
  }

  void _toggleTag(String tag) {
    setState(() {
      _selectedTags.contains(tag) ? _selectedTags.remove(tag) : _selectedTags.add(tag);
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _storyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReflectionViewModel>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Orb Kiri Bawah (Pink)
          Positioned(
            bottom: 100,
            left: -80,
            child: GlowingOrb(
              width: 260,
              height: 260,
              color: const Color(0xFFF472B6).withOpacity(0.2), 
            ),
          ),
          // Orb Kanan Atas (Ungu)
          Positioned(
            top: 100,
            right: -60,
            child: GlowingOrb(
              width: 200,
              height: 200,
              color: const Color(0xFF8B5CF6).withOpacity(0.25), 
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mind Space',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tumpahkan isi kepalamu hari ini.',
                    style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.5)),
                  ),
                  const SizedBox(height: 32),

                  _buildSectionLabel('MOOD HARI INI'),
                  const SizedBox(height: 12),
                  Row(
                    children: List.generate(_moods.length, (index) {
                      final isActive = _selectedMoodIndex == index;
                      final mood = _moods[index];
                      
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedMoodIndex = index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOutBack,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isActive ? (mood['color'] as Color).withOpacity(0.25) : Colors.white.withOpacity(0.06),
                              border: Border.all(
                                color: isActive ? (mood['color'] as Color).withOpacity(0.5) : Colors.white.withOpacity(0.1),
                              ),
                              borderRadius: BorderRadius.circular(14),
                              // FIX ANIMASI SHADOW DI SINI BRAY
                              boxShadow: [
                                BoxShadow(
                                  color: isActive ? (mood['color'] as Color).withOpacity(0.3) : Colors.transparent, 
                                  blurRadius: 12, 
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: Icon(
                              mood['icon'] as IconData,
                              color: isActive ? (mood['color'] as Color) : Colors.white54,
                              size: isActive ? 28 : 24,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 28),

                  _buildSectionLabel('TAGS EMOSI'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 12,
                    children: _tagColors.keys.map((tag) {
                      final isActive = _selectedTags.contains(tag);
                      final bg = isActive ? _tagColors[tag]!['bg'] : Colors.white.withOpacity(0.06);
                      final border = isActive ? _tagColors[tag]!['border'] : Colors.white.withOpacity(0.1);
                      final textCol = isActive ? _tagColors[tag]!['text'] : Colors.white54;

                      return GestureDetector(
                        onTap: () => _toggleTag(tag),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: bg,
                            border: Border.all(color: border!, width: 1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(tag.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textCol, letterSpacing: 0.5)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 28),

                  _buildSectionLabel('CERITA KAMU'),
                  const SizedBox(height: 12),
                  GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    borderRadius: BorderRadius.circular(20),
                    child: TextField(
                      controller: _storyController,
                      maxLines: 5,
                      minLines: 3,
                      style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9), height: 1.5),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Tidak ada yang menghakimi di sini. Tulis saja...',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontStyle: FontStyle.italic),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  GestureDetector(
                    onTap: () async {
                      if (vm.isGenerating) return;
                      if (_storyController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Ceritamu masih kosong bray!', style: TextStyle(color: Colors.white)),
                            backgroundColor: const Color(0xFFF472B6),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          )
                        );
                        return;
                      }
                      
                      _animController.reset(); 
                      final tagsText = _selectedTags.isNotEmpty ? _selectedTags.join(', ') : 'netral';
                      final moodLabel = _moods[_selectedMoodIndex]['label'] as String;

                      try {
                        await vm.generateAndSaveCouncil(
                          content: _storyController.text,
                          moodEmoji: moodLabel, 
                          moodLabel: tagsText,
                        );
                        _animController.forward(); 
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Koneksi AI terputus: $e')));
                        }
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: vm.isGenerating 
                            ? [const Color(0xFF4C1D95), const Color(0xFF312E81)] 
                            : [const Color(0xFF7C3AED), const Color(0xFF6D28D9)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: vm.isGenerating ? Colors.transparent : const Color(0xFF7C3AED).withOpacity(0.4), 
                            blurRadius: 15, 
                            offset: const Offset(0, 6)
                          ),
                        ],
                      ),
                      child: Center(
                        child: vm.isGenerating
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                                  const SizedBox(width: 12),
                                  Text('Menyelami pikiranmu...', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14, fontStyle: FontStyle.italic)),
                                ],
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                                  SizedBox(width: 8),
                                  Text('TANYA INNER COUNCIL', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                                ],
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  if (vm.lastCouncilResult != null && !vm.isGenerating)
                    FadeTransition(
                      opacity: _fadeAnim,
                      child: SlideTransition(
                        position: _slideAnim,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Text(
                                '✨ PESAN UNTUKMU HARI INI ✨',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFFA78BFA).withOpacity(0.8), letterSpacing: 1.5),
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            if (vm.lastWeather != null) ...[
                              Center(
                                child: Text(
                                  '"${vm.lastWeather}"',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 14, color: Color(0xFF5EEAD4), height: 1.6, fontStyle: FontStyle.italic),
                                ),
                              ),
                              const SizedBox(height: 32),
                            ],

                            _buildInsightCard(
                              title: 'Dari Masa Lalumu',
                              content: vm.lastCouncilResult!['past'] ?? '',
                              icon: Icons.history_edu_rounded,
                              accentColor: Colors.pinkAccent,
                            ),
                            const SizedBox(height: 16),

                            _buildInsightCard(
                              title: 'Dari Versi Terbaikmu',
                              content: vm.lastCouncilResult!['ideal'] ?? '',
                              icon: Icons.star_outline_rounded,
                              accentColor: const Color(0xFFC4B5FD),
                            ),
                            const SizedBox(height: 16),

                            _buildInsightCard(
                              title: 'Dari Masa Depanmu',
                              content: vm.lastCouncilResult!['future'] ?? '',
                              icon: Icons.rocket_launch_outlined,
                              accentColor: Colors.lightBlueAccent,
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.5, color: Colors.white.withOpacity(0.4)),
    );
  }

  Widget _buildInsightCard({required String title, required String content, required IconData icon, required Color accentColor}) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(20),
      borderColor: accentColor.withOpacity(0.3),
      bgColor: accentColor.withOpacity(0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 14, color: accentColor),
              ),
              const SizedBox(width: 10),
              Text(
                title.toUpperCase(),
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: accentColor.withOpacity(0.8), letterSpacing: 1.0),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.9), height: 1.5),
          ),
        ],
      ),
    );
  }
}