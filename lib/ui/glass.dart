import 'dart:ui';
import 'package:flutter/material.dart';

// ============================================================================
// 1. GLASS BACKGROUND (Hanya Base Gradient Polos - Orbs Pindah ke Screen)
// ============================================================================
class GlassBackground extends StatelessWidget {
  final Widget child;

  const GlassBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.4, 1.0],
          colors: [
            Color(0xFF1A0A2E), // Gelap ungu (.bg-grad di HTML)
            Color(0xFF16082A), // Lebih gelap
            Color(0xFF0D1A3A), // Gelap biru
          ],
        ),
      ),
      child: child,
    );
  }
}

// ============================================================================
// 2. GLOWING ORB (Widget Kustom untuk Cahaya Neon di Tiap Halaman)
// ============================================================================
class GlowingOrb extends StatelessWidget {
  final double width;
  final double height;
  final Color color;
  final double blur;

  const GlowingOrb({
    super.key,
    required this.width,
    required this.height,
    required this.color,
    this.blur = 60.0, // Blur disesuaikan agar smooth
  });

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}

// ============================================================================
// 3. GLASS CARD (Optimasi Ketebalan Kaca Sesuai Mockup HTML)
// ============================================================================
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final Color? bgColor;
  final Color? borderColor;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.bgColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        // Menurunkan tingkat kemandegan dari 20.0 ke 12.0 biar tembus pandang jernih
        filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0), 
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            // Mengikuti spek .glass-card HTML: Putih dasar opasitas 0.06
            color: bgColor ?? Colors.white.withOpacity(0.06),
            borderRadius: borderRadius,
            border: Border.all(
              // Mengikuti spek HTML: Border putih halus opasitas 0.15
              color: borderColor ?? Colors.white.withOpacity(0.15), 
              width: 0.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}