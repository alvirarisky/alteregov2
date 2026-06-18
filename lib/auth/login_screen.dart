import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../ui/glass.dart';
import '../view_models/auth_view_model.dart';
import 'register_screen.dart'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();

    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Orb Ungu Besar di Atas
            Positioned(
              top: -100,
              left: -50,
              child: GlowingOrb(
                width: 350,
                height: 350,
                color: const Color(0xFF7C3AED).withOpacity(0.35),
              ),
            ),
            // Orb Teal di Bawah
            Positioned(
              bottom: -50,
              right: -50,
              child: GlowingOrb(
                width: 250,
                height: 250,
                color: const Color(0xFF2DD4BF).withOpacity(0.2),
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
                      // LOGO / JUDUL
                      const Icon(Icons.auto_awesome_mosaic_rounded, size: 64, color: Color(0xFFC4B5FD)),
                      const SizedBox(height: 16),
                      const Text(
                        'AlterEgo',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Temui versi terbaik dirimu',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.5)),
                      ),
                      const SizedBox(height: 48),

                      // FORM LOGIN
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
                            const SizedBox(height: 32),
                            
                            // Tombol Login Interaktif (InkWell)
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: authVM.isLoading ? null : () async {
                                  final email = _emailController.text.trim();
                                  final password = _passwordController.text;

                                  // Validasi kalau inputan kosong
                                  if (email.isEmpty || password.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text('Email dan password nggak boleh kosong bray!', style: TextStyle(color: Colors.white)),
                                        backgroundColor: const Color(0xFFF472B6),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    );
                                    return;
                                  }

                                  try {
                                    // Tunggu proses login ke Firebase
                                    await authVM.login(email, password);
                                  } catch (e) {
                                    // Tangkap error dan munculin popup merah
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: const Text('Login gagal! Coba cek lagi email & password lo.', style: TextStyle(color: Colors.white)),
                                          backgroundColor: const Color(0xFFE11D48),
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                      );
                                    }
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
                                        : const Text('MASUK', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Navigasi ke Register
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Belum punya akun? ", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
                            },
                            child: const Text(
                              "Daftar Sekarang",
                              style: TextStyle(color: Color(0xFFC4B5FD), fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
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