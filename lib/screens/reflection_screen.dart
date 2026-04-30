import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../ui/glass.dart';
import '../models/reflection_model.dart';
import '../services/reflection_service.dart';
import '../services/groq_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ReflectionScreen extends StatefulWidget {
  const ReflectionScreen({super.key});

  @override
  State<ReflectionScreen> createState() => _ReflectionScreenState();
}

class _ReflectionScreenState extends State<ReflectionScreen> {
  final ReflectionService _service = ReflectionService();
  final GroqService _groqService = GroqService(); 
  final TextEditingController _noteController = TextEditingController();

  static const _tags = <String>[
    'stress',
    'fokus',
    'overthinking',
    'cemas',
    'sedih',
    'marah',
    'capek',
    'motivasi',
    'percaya diri',
  ];

  int _mood = 3;
  final Set<String> _selectedTags = {};
  bool _isSaving = false;
  bool _isGenerating = false;
  String? _lastSavedReflectionId;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _resetForm() {
    setState(() {
      _mood = 3;
      _selectedTags.clear();
      _noteController.clear();
      _lastSavedReflectionId = null;
    });
  }

  void _markFormAsDirty() {
    if (_lastSavedReflectionId != null) {
      setState(() => _lastSavedReflectionId = null);
    }
  }

  Future<void> _saveReflection({bool isFromGenerate = false}) async {
    FocusScope.of(context).unfocus();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kamu belum login.')),
      );
      return;
    }

    final note = _noteController.text.trim();
    if (note.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Catatan refleksi tidak boleh kosong.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final id = await _service.saveReflection(
        ReflectionModel(
          mood: _mood,
          tags: _selectedTags.toList()..sort(),
          note: note,
          createdAt: DateTime.now(),
        ),
      );
      if (!mounted) return;
      
      setState(() => _lastSavedReflectionId = id);
      
      if (!isFromGenerate) {
        _resetForm();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reflection tersimpan.')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan reflection. Coba lagi.')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _generateSolution() async {
    FocusScope.of(context).unfocus();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final note = _noteController.text.trim();
    if (note.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi dulu catatan refleksinya ya.')),
      );
      return;
    }

    if (_lastSavedReflectionId == null) {
      await _saveReflection(isFromGenerate: true);
      if (_lastSavedReflectionId == null) return;
    }

    setState(() => _isGenerating = true);
    try {
      final response = await _groqService.generateReflectionSolution(
        mood: _mood,
        tags: _selectedTags.toList()..sort(),
        note: note,
      );

      await _service.setAiResponse(
        reflectionId: _lastSavedReflectionId!,
        aiResponse: response,
      );

      if (!mounted) return;
      
      _resetForm();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insight berhasil dibuat!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal generate insight: $e')), 
      );
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text("Reflection"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: ListView(
              children: [
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.auto_awesome_rounded, color: scheme.primary),
                          const SizedBox(width: 10),
                          Text(
                            "Reflection",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: scheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Mood & tag membantu kamu tracking kondisi. Tombol “Generate Solusi” adalah step terpisah (lebih terkontrol).",
                        style: TextStyle(
                          color: scheme.onSurface.withValues(alpha: 0.70),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        "Mood: $_mood/5",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
                      Slider(
                        value: _mood.toDouble(),
                        min: 1,
                        max: 5,
                        divisions: 4,
                        onChanged: (v) {
                          setState(() => _mood = v.round());
                          _markFormAsDirty(); 
                        },
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Tags",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: _tags.map((t) {
                          final selected = _selectedTags.contains(t);
                          return FilterChip(
                            label: Text(t),
                            selected: selected,
                            onSelected: (v) {
                              setState(() {
                                if (v) {
                                  _selectedTags.add(t);
                                } else {
                                  _selectedTags.remove(t);
                                }
                              });
                              _markFormAsDirty(); 
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _noteController,
                        maxLines: 4,
                        textInputAction: TextInputAction.newline,
                        onChanged: (v) => _markFormAsDirty(), 
                        decoration: InputDecoration(
                          hintText: "Tulis singkat: apa yang terjadi / apa yang kamu rasakan?",
                          filled: true,
                          fillColor: scheme.surface.withValues(alpha: 0.35),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: scheme.outline.withValues(alpha: 0.25),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isSaving ? null : () => _saveReflection(isFromGenerate: false),
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text("Save"),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              onPressed: (_isGenerating || _isSaving)
                                  ? null
                                  : _generateSolution,
                              child: _isGenerating
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text("Generate Solusi"),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GlassCard(
                  child: StreamBuilder<ReflectionModel?>(
                    stream: _service.streamLatestReflection(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Center(child: Text("Gagal memuat history."));
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final data = snapshot.data;
                      if (data == null) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              "Latest reflection",
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: scheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Belum ada reflection tersimpan.",
                              style: TextStyle(
                                color: scheme.onSurface.withValues(alpha: 0.70),
                              ),
                            ),
                          ],
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            "Latest reflection",
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Mood ${data.mood}/5 • ${data.tags.isEmpty ? "no tags" : data.tags.join(", ")}",
                            style: TextStyle(
                              color: scheme.onSurface.withValues(alpha: 0.75),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            data.note,
                            style: TextStyle(
                              color: scheme.onSurface.withValues(alpha: 0.80),
                            ),
                          ),
                          if (data.aiResponse != null) ...[
                            const SizedBox(height: 12),
                            Divider(color: scheme.outline.withValues(alpha: 0.25)),
                            const SizedBox(height: 10),
                            Text(
                              "✨ Inner Voice Insight", // [UPDATE]: Berubah jadi Inner Voice Insight
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: scheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            MarkdownBody(
                              data: data.aiResponse!,
                              styleSheet: MarkdownStyleSheet(
                                p: TextStyle(
                                  color: scheme.onSurface.withValues(alpha: 0.80),
                                  height: 1.35,
                                ),
                                strong: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: scheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
