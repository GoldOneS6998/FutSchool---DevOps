import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

const captainGreen = Color(0xFF16A34A);
const captainSurface = Color(0xFF0F241B);
const captainMuted = Color(0xFF9CA3AF);
const captainText = Color(0xFFD1FAE5);

/// Native layouts preserve the Figma palette and assets while allowing scrolling,
/// a physical keyboard and large text on both mobile and web.
ThemeData captainTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: const Color(0xFF0B1F14),
    colorScheme: base.colorScheme.copyWith(
      primary: captainGreen,
      onPrimary: Colors.white,
      surface: captainSurface,
      onSurface: Colors.white,
      secondary: captainText,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: .05),
      labelStyle: const TextStyle(color: captainText),
      hintStyle: const TextStyle(color: captainMuted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: captainGreen),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: captainGreen),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: captainText, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: captainGreen,
        foregroundColor: Colors.white,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: captainText,
        side: const BorderSide(color: captainGreen),
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Color(0xFF174733),
      contentTextStyle: TextStyle(color: Colors.white),
    ),
    dividerTheme: DividerThemeData(color: Colors.white.withValues(alpha: .08)),
  );
}

class CaptainAsset extends StatelessWidget {
  const CaptainAsset(this.name, {super.key});
  final String name;

  static const dimensions = <String, double>{
    'home': 22,
    'trophy': 22,
    'trophy_white': 22,
    'shield': 22,
    'user': 22,
    'arrow_left': 20,
    'pencil': 18,
    'plus': 16,
    'search': 18,
    'calendar': 14,
    'chevron_right': 14,
  };

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SvgPicture.asset(
      'assets/figma/captain/$name.svg',
      width: dimensions[name]!,
      height: dimensions[name]!,
    ),
  );
}

class CaptainScaffold extends StatelessWidget {
  const CaptainScaffold({
    super.key,
    required this.title,
    required this.children,
    this.actions = const [],
    this.bottomNavigation,
    this.showBack = true,
    this.maxWidth = 760,
  });

  final String title;
  final List<Widget> children;
  final List<Widget> actions;
  final Widget? bottomNavigation;
  final bool showBack;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Theme(
    data: captainTheme(),
    child: Builder(
      builder: (context) => Scaffold(
        bottomNavigationBar: bottomNavigation,
        body: Stack(
          children: [
            const Positioned.fill(child: _CaptainBackground()),
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                    children: [
                      Row(
                        children: [
                          if (showBack)
                            CaptainIconButton(
                              label: 'Volver',
                              asset: 'arrow_left',
                              onPressed: () => Navigator.of(context).maybePop(),
                            ),
                          if (showBack) const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          ...actions,
                        ],
                      ),
                      const SizedBox(height: 24),
                      ...children,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _CaptainBackground extends StatelessWidget {
  const _CaptainBackground();
  @override
  Widget build(BuildContext context) => ClipRect(
    child: Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
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
          top: -240,
          left: -210,
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 60, sigmaY: 60),
            child: SvgPicture.asset(
              'assets/figma/captain/pitch_glow.svg',
              width: 660,
              height: 660,
            ),
          ),
        ),
        Positioned(
          top: 480,
          left: 140,
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 70, sigmaY: 70),
            child: SvgPicture.asset(
              'assets/figma/captain/stadium_glow.svg',
              width: 640,
              height: 640,
            ),
          ),
        ),
        for (final offset in [-24.0, 214.0])
          Positioned(
            top: -40,
            left: offset,
            child: Transform.rotate(
              angle: (offset < 0 ? -12 : 12) * math.pi / 180,
              child: Container(
                width: 220,
                height: 890,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .02),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .08),
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class CaptainCard extends StatelessWidget {
  const CaptainCard({super.key, required this.child, this.padding = 20});
  final Widget child;
  final double padding;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(padding),
    decoration: BoxDecoration(
      color: captainSurface,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: captainGreen),
      boxShadow: [
        BoxShadow(color: captainGreen.withValues(alpha: .12), blurRadius: 24),
        BoxShadow(
          color: Colors.black.withValues(alpha: .25),
          blurRadius: 30,
          offset: const Offset(0, 12),
        ),
      ],
    ),
    child: Material(type: MaterialType.transparency, child: child),
  );
}

class CaptainIconButton extends StatelessWidget {
  const CaptainIconButton({
    super.key,
    required this.label,
    required this.asset,
    required this.onPressed,
  });
  final String label;
  final String asset;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => IconButton.outlined(
    tooltip: label,
    onPressed: onPressed,
    icon: CaptainAsset(asset),
    style: IconButton.styleFrom(
      side: const BorderSide(color: captainGreen),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      minimumSize: const Size(48, 48),
    ),
  );
}

class CaptainBottomNavigation extends StatelessWidget {
  const CaptainBottomNavigation({
    super.key,
    required this.selected,
    required this.onSelected,
  });
  final int selected;
  final ValueChanged<int> onSelected;
  static const labels = ['Inicio', 'Torneos', 'Mi Equipo', 'Perfil'];
  static const assets = ['home', 'trophy', 'shield', 'user'];

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: captainSurface.withValues(alpha: .98),
      border: Border.all(color: captainGreen),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
    ),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          children: List.generate(4, (index) {
            final active = selected == index;
            return Expanded(
              child: Semantics(
                selected: active,
                button: true,
                child: InkWell(
                  key: ValueKey('captain-nav-$index'),
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => onSelected(index),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: 40,
                          width: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: active ? captainGreen : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: CaptainAsset(assets[index]),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          labels[index],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: active ? captainGreen : captainMuted,
                            fontSize: 11,
                            fontWeight: active
                                ? FontWeight.bold
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    ),
  );
}

class CaptainBadge extends StatelessWidget {
  const CaptainBadge(this.text, {super.key, this.warning = false});
  final String text;
  final bool warning;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: (warning ? Colors.amber : captainGreen).withValues(alpha: .12),
      border: Border.all(color: warning ? Colors.amber : captainGreen),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: warning ? Colors.amber : captainText,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

void captainNotify(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

String captainDate(DateTime value) {
  final date = value.toLocal();
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}

String captainTime(DateTime value) {
  final date = value.toLocal();
  return '${date.hour.toString().padLeft(2, '0')}:'
      '${date.minute.toString().padLeft(2, '0')}';
}
