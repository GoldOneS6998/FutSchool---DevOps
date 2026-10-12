import 'package:flutter/material.dart';

import '../domain/tournament.dart';

class TorneosPage extends StatefulWidget {
  const TorneosPage({super.key});

  @override
  State<TorneosPage> createState() => _TorneosPageState();
}

class _TorneosPageState extends State<TorneosPage> {
  final TextEditingController _searchController = TextEditingController();
  TournamentStatus _selectedFilter = TournamentStatus.all;
  String _searchQuery = '';

  static const List<Tournament> _mockTournaments = [
    Tournament(
      id: '1',
      name: 'Torneo Interescolar 2026',
      category: 'Fútbol varonil',
      statusLabel: 'Inscripciones abiertas',
      statusCategory: TournamentStatus.upcoming,
      dates: '15 de octubre - 30 de noviembre',
      description: 'Torneo interescolar oficial de la academia FutSchool.',
    ),
    Tournament(
      id: '2',
      name: 'Copa Primavera FutSchool',
      category: 'Fútbol varonil',
      statusLabel: 'Próximamente',
      statusCategory: TournamentStatus.upcoming,
      dates: '5 de enero - 20 de febrero',
      description: 'Competencia rápida de inicio de año escolar.',
    ),
    Tournament(
      id: '3',
      name: 'Torneo Femenil de Secundaria',
      category: 'Fútbol femenil',
      statusLabel: 'Inscripciones abiertas',
      statusCategory: TournamentStatus.upcoming,
      dates: '1 de noviembre - 15 de diciembre',
      description: 'Torneo para categorías secundarias y preparatorias.',
    ),
    Tournament(
      id: '4',
      name: 'Copa Otoño 2025',
      category: 'Fútbol varonil',
      statusLabel: 'Finalizado',
      statusCategory: TournamentStatus.finished,
      dates: '1 de septiembre - 15 de octubre',
      description: 'Edición anterior del torneo de otoño.',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Tournament> get _filteredTournaments {
    return _mockTournaments.where((t) {
      final matchesSearch =
          t.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          t.category.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesFilter = switch (_selectedFilter) {
        TournamentStatus.all => true,
        TournamentStatus.upcoming =>
          t.statusCategory == TournamentStatus.upcoming,
        TournamentStatus.finished =>
          t.statusCategory == TournamentStatus.finished,
      };

      return matchesSearch && matchesFilter;
    }).toList();
  }

  Color _getStatusBadgeColor(String statusLabel, ThemeData theme) {
    if (statusLabel == 'Inscripciones abiertas') {
      return const Color(0xFF2E7D32);
    } else if (statusLabel == 'Próximamente') {
      return const Color(0xFFE65100);
    } else {
      return Colors.grey.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filteredTournaments;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Torneos disponibles'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              // Buscador de torneos
              TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Buscar torneo...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Chips de filtro: Todos, Próximos, Finalizados
              Row(
                children: [
                  _FilterChipItem(
                    label: 'Todos',
                    isSelected: _selectedFilter == TournamentStatus.all,
                    onSelected: () =>
                        setState(() => _selectedFilter = TournamentStatus.all),
                  ),
                  const SizedBox(width: 8),
                  _FilterChipItem(
                    label: 'Próximos',
                    isSelected: _selectedFilter == TournamentStatus.upcoming,
                    onSelected: () => setState(
                      () => _selectedFilter = TournamentStatus.upcoming,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _FilterChipItem(
                    label: 'Finalizados',
                    isSelected: _selectedFilter == TournamentStatus.finished,
                    onSelected: () => setState(
                      () => _selectedFilter = TournamentStatus.finished,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Lista de torneos
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 48,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No se encontraron torneos',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final tournament = filtered[index];
                          return _TournamentCard(
                            tournament: tournament,
                            statusColor: _getStatusBadgeColor(
                              tournament.statusLabel,
                              theme,
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChipItem extends StatelessWidget {
  const _FilterChipItem({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: theme.colorScheme.primaryContainer,
      labelStyle: TextStyle(
        color: isSelected
            ? theme.colorScheme.onPrimaryContainer
            : theme.colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}

class _TournamentCard extends StatelessWidget {
  const _TournamentCard({required this.tournament, required this.statusColor});

  final Tournament tournament;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badges superiores: Categoría y Estado
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    tournament.category,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    tournament.statusLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Nombre del torneo
            Text(
              tournament.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Fecha
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    tournament.dates,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Botón "Ver detalles"
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Detalle del torneo "${tournament.name}" estará disponible próximamente.',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('Ver detalles'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
