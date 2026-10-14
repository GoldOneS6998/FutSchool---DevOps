import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

const futGreen = Color(0xFF16A34A);
const futCard = Color(0xFF0F241B);
const futText = Color(0xFFD1FAE5);

ThemeData authTheme(BuildContext context) => Theme.of(context).copyWith(
  colorScheme: ColorScheme.fromSeed(
    seedColor: futGreen,
    brightness: Brightness.dark,
    surface: futCard,
    primary: futGreen,
  ),
  textTheme: Theme.of(context).textTheme
      .apply(bodyColor: Colors.white, displayColor: Colors.white),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white.withValues(alpha: .05),
    labelStyle: const TextStyle(color: futText),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: futGreen),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: futGreen),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: futGreen,
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(56),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: Colors.white,
      side: const BorderSide(color: futGreen),
      minimumSize: const Size.fromHeight(56),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  ),
);

class AuthSurface extends StatelessWidget {
  const AuthSurface({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Theme(
    data: authTheme(context),
    child: Scaffold(
      backgroundColor: const Color(0xFF0B1F14),
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0B1F14),
                    Color(0xFF0F2A1A),
                    Color(0xFF0A1A10),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: -210,
            top: -240,
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: SvgPicture.asset('assets/figma/auth/pitch-glow.svg'),
            ),
          ),
          Positioned(
            right: -310,
            bottom: -280,
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 70, sigmaY: 70),
              child: SvgPicture.asset('assets/figma/auth/stadium-glow.svg'),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 32,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: child,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class AcademyLogo extends StatelessWidget {
  const AcademyLogo({super.key});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: futGreen,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Center(child: SvgPicture.asset('assets/figma/auth/logo.svg')),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .07),
            borderRadius: BorderRadius.circular(99),
          ),
          child: const Text(
            'FUTSCHOOL ACADEMY',
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}
