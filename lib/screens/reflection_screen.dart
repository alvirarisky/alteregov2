import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../ui/glass.dart';
import '../view_models/reflection_view_model.dart';
import '../models/reflection_model.dart';

class ReflectionScreen extends StatefulWidget {
  const ReflectionScreen({super.key});

  @override
  State<ReflectionScreen> createState() => _ReflectionScreenState();
}

class _ReflectionScreenState extends State<ReflectionScreen> {
  final TextEditingController _noteController = TextEditingController();

  // Data 8 Emosi untuk Mood Wheel
  final List<Map<String, String>> _moods = [
    {'label': 'joy', 'emoji': '✨'},
    {'label': 'calm', 'emoji': '🍃'},
    {'label': 'love', 'emoji': '💖'},
    {'label': 'neutral', 'emoji': '😐'},
    {'label': 'sad', 'emoji': '🌧️'},
    {'label': 'fear', 'emoji': '🌪️'},
    {'label': 'stress', 'emoji': '⚡'},
    {'label': 'angry', 'emoji': '🔥'},
  ];

  String _selectedMoodLabel = 'neutral';
  String _selectedMoodEmoji = '😐';

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _generateCouncil() async {
    FocusScope.of(context).unfocus(); // Tutup keyboard
    if (_noteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tuliskan dulu apa yang kamu rasakan.')),
      );
      return;
    }

    try {
      await context.read<ReflectionViewModel>().generateAndSaveCouncil(
            content: _noteController.text,
            moodEmoji: _selectedMoodEmoji,
            moodLabel: _selectedMoodLabel,
          );
      _noteController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final viewModel = context.watch<ReflectionViewModel>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Mind Space', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // --- BAGIAN 1: FORM INPUT (MOOD WHEEL & TEXT AREA) ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: GlassCard(
                padding: const EdgeInsets.all(24),
                borderRadius: BorderRadius.circular(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HOW DO YOU FEEL?',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Mood Wheel (Horizontal Scroll)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: _moods.map((mood) {
                          final isSelected = _selectedMoodLabel == mood['label'];
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedMoodLabel = mood['label']!;
                                  _selectedMoodEmoji = mood['emoji']!;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected ? scheme.primary.withValues(alpha: 0.2) : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected ? scheme.primary : scheme.onSurface.withValues(alpha: 0.1),
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  children: [
                                    Text(mood['emoji']!, style: const TextStyle(fontSize: 24)),
                                    const SizedBox(height: 4),
                                    Text(
                                      mood['label']!.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: isSelected ? scheme.primary : scheme.onSurface.withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Area Teks Transparan
                    Container(
                      decoration: BoxDecoration(
                        color: scheme.onSurface.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextField(
                        controller: _noteController,
                        maxLines: 4,
                        style: TextStyle(color: scheme.onSurface, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: "Tumpahkan semua beban pikiranmu di sini...",
                          hintStyle: TextStyle(color: scheme.onSurface.withValues(alpha: 0.4)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Tombol Aksi
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: scheme.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: viewModel.isGenerating ? null : _generateCouncil,
                        icon: viewModel.isGenerating 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.psychology_rounded),
                        label: Text(
                          viewModel.isGenerating ? "CONSULTING COUNCIL..." : "GENERATE INNER COUNCIL",
                          style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // --- BAGIAN 2: BENTO GRID INNER COUNCIL (LATEST REFLECTION) ---
          StreamBuilder<ReflectionModel?>(
            stream: viewModel.latestReflectionStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !viewModel.isGenerating) {
                return const SliverToBoxAdapter(child: SizedBox());
              }

              final reflection = snapshot.data;
              if (reflection == null || reflection.councilResponses == null) {
                return const SliverToBoxAdapter(child: SizedBox());
              }

              final weather = reflection.emotionalWeather ?? "Cuaca tidak menentu.";
              final past = reflection.councilResponses!['past'] ?? '';
              final ideal = reflection.councilResponses!['ideal'] ?? '';
              final future = reflection.councilResponses!['future'] ?? '';

              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100), // Padding bawah agar tidak tertutup nav bar
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 12),
                        child: Text(
                          'YOUR INNER COUNCIL',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2, color: scheme.onSurface.withValues(alpha: 0.5)),
                        ),
                      ),
                      
                      // BENTO GRID START
                      
                      // 1. Emotional Weather (Full Width)
                      GlassCard(
                        padding: const EdgeInsets.all(20),
                        borderRadius: BorderRadius.circular(24),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: scheme.secondary.withValues(alpha: 0.15), shape: BoxShape.circle),
                              child: Icon(Icons.wb_twilight_rounded, color: scheme.secondary, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Emotional Weather", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: scheme.secondary, letterSpacing: 1)),
                                  const SizedBox(height: 4),
                                  Text('"$weather"', style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: scheme.onSurface, height: 1.4)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // 2. Past Self & Ideal Self (2 Columns)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildBentoCard(
                              context, 
                              "Past Self", 
                              Icons.history_edu_rounded, 
                              Colors.pinkAccent, 
                              past,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildBentoCard(
                              context, 
                              "Ideal Self", 
                              Icons.star_outline_rounded, 
                              Colors.tealAccent, 
                              ideal,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // 3. Future Self (Full Width)
                      _buildBentoCard(
                        context, 
                        "Future Self", 
                        Icons.rocket_launch_outlined, 
                        Colors.lightBlueAccent, 
                        future,
                        isFullWidth: true,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Helper widget untuk membuat kartu Bento yang seragam
  Widget _buildBentoCard(BuildContext context, String title, IconData icon, Color color, String content, {bool isFullWidth = false}) {
    final scheme = Theme.of(context).colorScheme;
    
    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 13,
              color: scheme.onSurface.withValues(alpha: 0.85),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}