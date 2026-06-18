import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../ui/glass.dart';
import '../view_models/auth_view_model.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final authVM = context.read<AuthViewModel>();
    
    if (_passwordController.text != _confirmController.text) {
      setState(() => _errorText = 'Password tidak cocok');
      return;
    }
    if (_passwordController.text.length < 6) {
      setState(() => _errorText = 'Password minimal 6 karakter');
      return;
    }

    setState(() => _errorText = null);

    try {
      await authVM.register(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (mounted) Navigator.pop(context); // Kembali ke halaman Login jika sukses
    } catch (e) {
      setState(() => _errorText = "Gagal mendaftar. Periksa kembali data Anda.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();

    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        // extendBodyBehindAppBar biar gradient background gak kepotong AppBar
        extendBodyBehindAppBar: true, 
        body: Stack(
          children: [
            // Orb Teal di Kanan Atas
            Positioned(
              top: -80,
              right: -50,
              child: GlowingOrb(
                width: 280,
                height: 280,
                color: const Color(0xFF2DD4BF).withOpacity(0.25),
              ),
            ),
            // Orb Pink di Kiri Bawah
            Positioned(
              bottom: -50,
              left: -80,
              child: GlowingOrb(
                width: 250,
                height: 250,
                color: const Color(0xFFF472B6).withOpacity(0.2),
              ),
            ),

            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Buat Akun Baru',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Mulai perjalanan refleksimu di sini',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.5)),
                      ),
                      const SizedBox(height: 40),

                      // FORM REGISTER (Pakai GlassCard)
                      GlassCard(
                        padding: const EdgeInsets.all(24),
                        borderRadius: BorderRadius.circular(24),
                        child: Column(
                          children: [
                            // Field Email
                            TextField(
                              controller: _emailController,
                              style: const TextStyle(color: Colors.white),
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                hintText: 'Email',
                                hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                                prefixIcon: Icon(Icons.email_outlined, color: Colors.white.withOpacity(0.5)),
                                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.15))),
                                focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF8B5CF6))),
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Field Password
                            TextField(
                              controller: _passwordController,
                              style: const TextStyle(color: Colors.white),
                              obscureText: true,
                              decoration: InputDecoration(
                                hintText: 'Password',
                                hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                                prefixIcon: Icon(Icons.lock_outline_rounded, color: Colors.white.withOpacity(0.5)),
                                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.15))),
                                focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF8B5CF6))),
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Field Konfirmasi Password
                            TextField(
                              controller: _confirmController,
                              style: const TextStyle(color: Colors.white),
                              obscureText: true,
                              decoration: InputDecoration(
                                hintText: 'Konfirmasi Password',
                                hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                                prefixIcon: Icon(Icons.check_circle_outline_rounded, color: Colors.white.withOpacity(0.5)),
                                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.15))),
                                focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF8B5CF6))),
                              ),
                            ),
                            
                            // Pesan Error Validasi
                            if (_errorText != null) ...[
                              const SizedBox(height: 16),
                              Text(
                                _errorText!,
                                style: const TextStyle(color: Color(0xFFF472B6), fontSize: 13, fontWeight: FontWeight.w500),
                                textAlign: TextAlign.center,
                              ),
                            ],

                            const SizedBox(height: 32),
                            // Tombol Register Cyberpunk
                            GestureDetector(
                              onTap: () {
                                if (!authVM.isLoading) {
                                  _handleRegister();
                                }
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(color: const Color(0xFF7C3AED).withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4)),
                                  ],
                                ),
                                child: Center(
                                  child: authVM.isLoading
                                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : const Text('DAFTAR SEKARANG', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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
}