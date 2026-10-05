import 'package:flutter/material.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key, this.onSignOut});
  final Future<void> Function()? onSignOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('FutSchool')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.sports_soccer,
                  size: 72,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Torneos escolares',
                  style: theme.textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                if (onSignOut != null) ...[
                  const SizedBox(height: 24),
                  OutlinedButton(
                    onPressed: () async {
                      try {
                        await onSignOut!();
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'No se pudo cerrar sesión. Intenta de nuevo.',
                              ),
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Cerrar sesión'),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  'Organiza y consulta tus torneos escolares.',
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
