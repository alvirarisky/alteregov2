import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/auth_view_model.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  final Widget signedIn;

  const AuthGate({super.key, required this.signedIn});

  @override
  Widget build(BuildContext context) {
    // Mendengarkan perubahan state login langsung dari ViewModel
    return StreamBuilder<User?>(
      stream: context.read<AuthViewModel>().authStateStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) return const LoginScreen();
        return signedIn;
      },
    );
  }
}