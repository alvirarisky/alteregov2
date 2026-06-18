import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../ui/glass.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _majorController = TextEditingController();
  final TextEditingController _hobbyController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _readProfileData(); // (R)EAD Data
  }

  // ================= CRUD: READ =================
  Future<void> _readProfileData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('profile').doc('data').get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        setState(() {
          _nameController.text = data['nama'] ?? '';
          _phoneController.text = data['no_hp'] ?? '';
          _majorController.text = data['jurusan'] ?? '';
          _hobbyController.text = data['hobi'] ?? '';
          _bioController.text = data['bio'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('Read error: $e');
    }
  }

  // ================= CRUD: CREATE / UPDATE =================
  Future<void> _saveProfileData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('profile').doc('data').set({
        'nama': _nameController.text.trim(),
        'no_hp': _phoneController.text.trim(),
        'jurusan': _majorController.text.trim(),
        'hobi': _hobbyController.text.trim(),
        'bio': _bioController.text.trim(),
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // Merge true bertindak sebagai Create or Update

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data berhasil disimpan! (C/U)')));
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Save error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ================= CRUD: DELETE =================
  Future<void> _deleteProfileData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('profile').doc('data').delete();
      
      setState(() {
        _nameController.clear();
        _phoneController.clear();
        _majorController.clear();
        _hobbyController.clear();
        _bioController.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Semua data berhasil dihapus! (D)'), backgroundColor: Colors.redAccent));
      }
    } catch (e) {
      debugPrint('Delete error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Edit Profil Lengkap (CRUD)', style: TextStyle(fontSize: 16)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => Navigator.pop(context)),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            child: GlassCard(
              padding: const EdgeInsets.all(20),
              borderRadius: BorderRadius.circular(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('LENGKAPI DATA DIRI', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.5), fontWeight: FontWeight.w600, letterSpacing: 1)),
                  const SizedBox(height: 24),
                  
                  _buildTextField(_nameController, 'Nama Lengkap', Icons.person_outline),
                  const SizedBox(height: 16),
                  _buildTextField(_phoneController, 'Nomor HP', Icons.phone_android_rounded, isPhone: true),
                  const SizedBox(height: 16),
                  _buildTextField(_majorController, 'Jurusan / Universitas', Icons.school_outlined),
                  const SizedBox(height: 16),
                  _buildTextField(_hobbyController, 'Hobi & Minat', Icons.favorite_border_rounded),
                  const SizedBox(height: 16),
                  _buildTextField(_bioController, 'Tentang Saya (Context AI)', Icons.edit_note_rounded, maxLines: 3),
                  
                  const SizedBox(height: 40),
                  
                  // TOMBOL UPDATE / CREATE
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfileData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6).withOpacity(0.25),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      minimumSize: const Size(double.infinity, 52),
                    ),
                    child: _isLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                      : const Text('Simpan Perubahan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 16),
                  
                  // TOMBOL DELETE
                  OutlinedButton(
                    onPressed: _isLoading ? null : () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: const Color(0xFF16082A),
                          title: const Text('Hapus Data?', style: TextStyle(color: Colors.white)),
                          content: const Text('Ini akan menghapus seluruh data profil lo dari database.', style: TextStyle(color: Colors.white70)),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
                            TextButton(onPressed: () {
                              Navigator.pop(ctx);
                              _deleteProfileData();
                            }, child: const Text('Hapus (Delete)', style: TextStyle(color: Colors.redAccent))),
                          ],
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      minimumSize: const Size(double.infinity, 52),
                    ),
                    child: const Text('Hapus Semua Data', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, IconData icon, {bool isPhone = false, int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.4), size: 18),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.15))),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFA78BFA))),
      ),
    );
  }
}