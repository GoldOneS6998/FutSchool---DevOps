import 'package:flutter/material.dart';

import '../../tournaments/presentation/tournaments_page.dart';
import '../../teams/presentation/my_team_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key, this.onSignOut, this.onRefreshAccess});
  final Future<void> Function()? onSignOut;
  final Future<void> Function()? onRefreshAccess;

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
                const SizedBox(height: 12),
                Text(
                  'Organiza y consulta tus torneos escolares.',
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                // Botón para acceder a la lista de Torneos Disponibles
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const TorneosPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.emoji_events_outlined),
                  label: const Text('Ver Torneos Disponibles'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    textStyle: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 28),
                // Segundo botón actualizado
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const MyTeamPage(),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.groups_outlined,
                  ), // Ícono de equipo/grupo
                  label: const Text('Mi Equipo'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    textStyle: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (onRefreshAccess != null) ...[
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: onRefreshAccess,
                    child: const Text('Actualizar permisos'),
                  ),
                ],
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
