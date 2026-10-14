import 'package:flutter/material.dart';

import '../domain/captain_repository.dart';
import 'captain_design.dart';
import 'captain_forms.dart';

class CaptainPage extends StatefulWidget {
  const CaptainPage({
    super.key,
    required this.repository,
    required this.onSignOut,
    this.onRefreshAccess,
  });
  final CaptainRepository repository;
  final Future<void> Function() onSignOut;
  final Future<void> Function()? onRefreshAccess;
  @override
  State<CaptainPage> createState() => _CaptainPageState();
}

class _CaptainPageState extends State<CaptainPage> {
  late Future<void> _initialization = widget.repository.ensureProfile();
  int _selected = 0;
  bool _signingOut = false;

  Future<void> _signOut() async {
    if (_signingOut) return;
    setState(() => _signingOut = true);
    try {
      await widget.onSignOut();
    } catch (_) {
      if (mounted) {
        captainNotify(context, 'No se pudo cerrar sesión. Reintenta.');
      }
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: _initialization,
    builder: (context, initialization) {
      if (initialization.connectionState != ConnectionState.done) {
        return const CaptainScaffold(
          title: 'FutSchool',
          showBack: false,
          children: [
            Center(child: CircularProgressIndicator()),
            Text('Preparando tu perfil...'),
          ],
        );
      }
      if (initialization.hasError) {
        return CaptainScaffold(
          title: 'FutSchool',
          showBack: false,
          children: [
            CaptainFormError(_captainError(initialization.error)),
            FilledButton(
              onPressed: () => setState(() {
                _initialization = widget.repository.ensureProfile();
              }),
              child: const Text('Reintentar'),
            ),
            OutlinedButton(
              onPressed: _signingOut ? null : _signOut,
              child: const Text('Cerrar sesión'),
            ),
          ],
        );
      }
      return CaptainLive<CaptainProfile?>(
        watch: widget.repository.watchProfile,
        wrapFallback: (child) => CaptainScaffold(
          title: 'FutSchool',
          showBack: false,
          children: [
            child,
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: _signingOut ? null : _signOut,
              child: const Text('Cerrar sesión'),
            ),
          ],
        ),
        builder: (context, profile) {
          if (profile == null || profile.disabled) {
            return CaptainScaffold(
              title: 'Acceso restringido',
              showBack: false,
              children: [
                const CaptainCard(
                  child: Text(
                    'No se puede habilitar tu perfil. '
                    'Contacta al administrador si tu cuenta fue deshabilitada.',
                  ),
                ),
                const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: _signingOut ? null : _signOut,
                  child: const Text('Cerrar sesión'),
                ),
              ],
            );
          }
          final pages = <Widget>[
            _CaptainHome(
              repository: widget.repository,
              profile: profile,
              onSelect: (index) => setState(() => _selected = index),
            ),
            _CaptainTournaments(repository: widget.repository),
            _CaptainTeam(repository: widget.repository, profile: profile),
            _CaptainProfile(
              repository: widget.repository,
              profile: profile,
              onSignOut: _signOut,
              signingOut: _signingOut,
              onRefreshAccess: widget.onRefreshAccess,
            ),
          ];
          return CaptainScaffold(
            key: ValueKey('captain-section-$_selected'),
            title: _selected == 0
                ? 'Hola, ${profile.displayName}'
                : CaptainBottomNavigation.labels[_selected],
            showBack: false,
            bottomNavigation: CaptainBottomNavigation(
              selected: _selected,
              onSelected: (index) => setState(() => _selected = index),
            ),
            children: [pages[_selected]],
          );
        },
      );
    },
  );
}

/// A failed read never becomes an empty successful list. Retrying opens a fresh
/// listener, while ordinary widget rebuilds retain the current subscription.
class CaptainLive<T> extends StatefulWidget {
  const CaptainLive({
    super.key,
    required this.watch,
    required this.builder,
    this.wrapFallback,
  });
  final Stream<T> Function() watch;
  final Widget Function(BuildContext context, T value) builder;
  final Widget Function(Widget child)? wrapFallback;
  @override
  State<CaptainLive<T>> createState() => _CaptainLiveState<T>();
}

class _CaptainLiveState<T> extends State<CaptainLive<T>> {
  late Stream<T> _stream = widget.watch();
  @override
  Widget build(BuildContext context) => StreamBuilder<T>(
    stream: _stream,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        final error = CaptainCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CaptainFormError(_captainError(snapshot.error)),
              OutlinedButton(
                onPressed: () => setState(() => _stream = widget.watch()),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        );
        return widget.wrapFallback?.call(error) ?? error;
      }
      if (snapshot.connectionState == ConnectionState.waiting) {
        const loading = Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        );
        return widget.wrapFallback?.call(loading) ?? loading;
      }
      return widget.builder(context, snapshot.data as T);
    },
  );
}

String _captainError(Object? error) => error is CaptainFailure
    ? error.message
    : 'No se pudieron cargar o guardar los datos. Intenta de nuevo.';

void _openCaptain(BuildContext context, Widget page) {
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
}

Future<void> _editCaptainTeam(
  BuildContext context,
  CaptainRepository repository, [
  CaptainTeam? team,
]) async {
  final saved = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => CaptainTeamForm(
        editing: team != null,
        name: team?.name ?? '',
        description: team?.description ?? '',
        logoBase64: team?.logoBase64,
        onSave: (name, description, logo) => repository.saveTeam(
          name: name,
          description: description,
          logoBase64: logo,
        ),
      ),
    ),
  );
  if (saved == true && context.mounted) {
    captainNotify(context, 'Equipo guardado.');
  }
}

class _CaptainHome extends StatelessWidget {
  const _CaptainHome({
    required this.repository,
    required this.profile,
    required this.onSelect,
  });
  final CaptainRepository repository;
  final CaptainProfile profile;
  final ValueChanged<int> onSelect;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text(
        'Organiza tu equipo y sigue su participación.',
        style: TextStyle(color: captainText),
      ),
      const SizedBox(height: 20),
      CaptainLive<AppSettings>(
        watch: repository.watchSettings,
        builder: (context, settings) => settings.announcement.isEmpty
            ? const SizedBox.shrink()
            : Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: CaptainCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Aviso de FutSchool',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(settings.announcement),
                    ],
                  ),
                ),
              ),
      ),
      CaptainLive<CaptainTeam?>(
        watch: repository.watchMyTeam,
        builder: (context, team) => CaptainCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CaptainTeamLogo(logoBase64: team?.logoBase64),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          team?.name ?? 'Crear equipo',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Capitán: ${profile.displayName}',
                          style: const TextStyle(color: captainText),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => team == null
                    ? _editCaptainTeam(context, repository)
                    : onSelect(2),
                child: Text(
                  team == null ? 'Registrar mi equipo' : 'Gestionar mi equipo',
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 20),
      _MyNextMatch(repository: repository),
      const SizedBox(height: 20),
      CaptainLive<List<AdminTournament>>(
        watch: repository.watchTournaments,
        builder: (context, tournaments) {
          final upcoming =
              tournaments
                  .where(
                    (item) => !item.endDate.toLocal().isBefore(
                      DateTime.now().subtract(const Duration(days: 1)),
                    ),
                  )
                  .toList()
                ..sort((a, b) => a.startDate.compareTo(b.startDate));
          return CaptainCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  children: [
                    CaptainAsset('trophy_white'),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Próximo torneo',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  upcoming.isEmpty
                      ? 'Aún no hay torneos próximos.'
                      : upcoming.first.name,
                  style: const TextStyle(fontSize: 18),
                ),
                if (upcoming.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${captainDate(upcoming.first.startDate)} — ${captainDate(upcoming.first.endDate)}',
                    style: const TextStyle(color: captainMuted),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => _openCaptain(
                      context,
                      CaptainTournamentDetail(
                        repository: repository,
                        tournamentId: upcoming.first.id,
                      ),
                    ),
                    child: const Text('Ver torneo'),
                  ),
                ] else ...[
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => onSelect(1),
                    child: const Text('Consultar torneos'),
                  ),
                ],
              ],
            ),
          );
        },
      ),
      const SizedBox(height: 20),
      _MyRegistrations(repository: repository),
    ],
  );
}

class _MyNextMatch extends StatelessWidget {
  const _MyNextMatch({required this.repository});
  final CaptainRepository repository;
  @override
  Widget build(BuildContext context) =>
      CaptainLive<List<TournamentRegistration>>(
        watch: repository.watchRegistrations,
        builder: (context, registrations) => CaptainLive<List<AdminMatch>>(
          watch: repository.watchMatches,
          builder: (context, matches) => CaptainLive<List<AdminTeam>>(
            watch: repository.watchTeams,
            builder: (context, teams) {
              final entrants = registrations
                  .where((entry) => entry.status == RegistrationStatus.approved)
                  .map((entry) => entry.entrantId)
                  .whereType<String>()
                  .toSet();
              final mine =
                  matches
                      .where(
                        (match) =>
                            (entrants.contains(match.homeTeamId) ||
                                entrants.contains(match.awayTeamId)) &&
                            (match.status == AdminMatchStatus.live ||
                                (match.status == AdminMatchStatus.scheduled &&
                                    !match.startsAt.isBefore(DateTime.now()))),
                      )
                      .toList()
                    ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
              return CaptainCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Mi próximo partido',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (mine.isEmpty)
                      const Text(
                        'Aún no tienes partidos programados. Se mostrarán después de aprobar tu inscripción.',
                      )
                    else
                      _MatchContent(match: mine.first, teams: teams),
                  ],
                ),
              );
            },
          ),
        ),
      );
}

class _MyRegistrations extends StatelessWidget {
  const _MyRegistrations({required this.repository});
  final CaptainRepository repository;
  @override
  Widget build(
    BuildContext context,
  ) => CaptainLive<List<TournamentRegistration>>(
    watch: repository.watchRegistrations,
    builder: (context, entries) => CaptainLive<List<AdminTournament>>(
      watch: repository.watchTournaments,
      builder: (context, tournaments) => CaptainCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Mis inscripciones',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (entries.isEmpty)
              const Text(
                'No tienes solicitudes. Encuentra un torneo e inscribe tu equipo.',
              )
            else
              for (final entry in entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _openCaptain(
                      context,
                      CaptainRegistrationPage(
                        repository: repository,
                        tournamentId: entry.tournamentId,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _tournamentName(tournaments, entry.tournamentId),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          CaptainBadge(
                            _registrationStatus(entry.status),
                            warning:
                                entry.status != RegistrationStatus.approved,
                          ),
                          if (entry.reviewNote.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(entry.reviewNote),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
            if (entries.length >= 200) const _ListLimit(),
          ],
        ),
      ),
    ),
  );
}

String _tournamentName(List<AdminTournament> tournaments, String id) {
  for (final item in tournaments) {
    if (item.id == id) return item.name;
  }
  return 'Torneo';
}

String _registrationStatus(RegistrationStatus status) => switch (status) {
  RegistrationStatus.pending => 'Pendiente de revisión',
  RegistrationStatus.approved => 'Inscripción aprobada',
  RegistrationStatus.rejected => 'Solicitud rechazada',
};

class _CaptainTeam extends StatelessWidget {
  const _CaptainTeam({required this.repository, required this.profile});
  final CaptainRepository repository;
  final CaptainProfile profile;
  @override
  Widget build(BuildContext context) => CaptainLive<CaptainTeam?>(
    watch: repository.watchMyTeam,
    builder: (context, team) {
      if (team == null) {
        return CaptainCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Tu equipo empieza aquí',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              const Text(
                'Registra su nombre, descripción y un logo opcional; después agrega tus jugadores.',
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => _editCaptainTeam(context, repository),
                child: const Text('Registrar mi equipo'),
              ),
            ],
          ),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CaptainCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    CaptainTeamLogo(logoBase64: team.logoBase64),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            team.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Capitán: ${profile.displayName}',
                            style: const TextStyle(color: captainText),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (team.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(team.description),
                  ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => _editCaptainTeam(context, repository, team),
                  icon: const CaptainAsset('pencil'),
                  label: const Text('Editar equipo'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _CaptainPlayers(repository: repository),
          const SizedBox(height: 20),
          _MyRegistrations(repository: repository),
        ],
      );
    },
  );
}

const _positions = <PlayerPosition, String>{
  PlayerPosition.goalkeeper: 'Portero',
  PlayerPosition.defender: 'Defensa',
  PlayerPosition.midfielder: 'Mediocampista',
  PlayerPosition.forward: 'Delantero',
};

class _CaptainPlayers extends StatefulWidget {
  const _CaptainPlayers({required this.repository});
  final CaptainRepository repository;
  @override
  State<_CaptainPlayers> createState() => _CaptainPlayersState();
}

class _CaptainPlayersState extends State<_CaptainPlayers> {
  bool _deleting = false;
  Future<void> _edit([CaptainPlayer? player]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CaptainPlayerForm(
          editing: player != null,
          name: player?.name ?? '',
          position: player == null ? null : _positions[player.position],
          number: player?.jerseyNumber,
          positions: _positions.values.toList(),
          onSave: (name, position, number) => widget.repository.savePlayer(
            id: player?.id,
            name: name,
            position: _positions.entries
                .firstWhere((entry) => entry.value == position)
                .key,
            jerseyNumber: number,
          ),
        ),
      ),
    );
    if (saved == true && mounted) captainNotify(context, 'Jugador guardado.');
  }

  Future<void> _delete(CaptainPlayer player) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar jugador'),
        content: Text('¿Eliminar a ${player.name} de tu equipo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (approved != true || !mounted || _deleting) return;
    setState(() => _deleting = true);
    try {
      await widget.repository.deletePlayer(player.id);
      if (mounted) captainNotify(context, 'Jugador eliminado.');
    } catch (error) {
      if (mounted) captainNotify(context, _captainError(error));
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) => CaptainLive<List<CaptainPlayer>>(
    watch: widget.repository.watchPlayers,
    builder: (context, players) => CaptainCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              Text(
                'Jugadores (${players.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              FilledButton.icon(
                onPressed: _deleting ? null : _edit,
                icon: const CaptainAsset('plus'),
                label: const Text('Agregar jugador'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (players.isEmpty)
            const Text('Aún no has agregado jugadores.')
          else
            for (final player in players)
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                color: captainGreen,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${player.jerseyNumber}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    player.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    _positions[player.position]!,
                                    style: const TextStyle(
                                      color: captainMuted,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            CaptainIconButton(
                              label: 'Editar ${player.name}',
                              asset: 'pencil',
                              onPressed: _deleting ? null : () => _edit(player),
                            ),
                          ],
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: _deleting ? null : () => _delete(player),
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: const Text('Eliminar jugador'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                ],
              ),
          if (players.length >= 200) const _ListLimit(),
        ],
      ),
    ),
  );
}

enum _TournamentFilter { all, upcoming, finished }

class _CaptainTournaments extends StatefulWidget {
  const _CaptainTournaments({required this.repository});
  final CaptainRepository repository;
  @override
  State<_CaptainTournaments> createState() => _CaptainTournamentsState();
}

class _CaptainTournamentsState extends State<_CaptainTournaments> {
  String _search = '';
  _TournamentFilter _filter = _TournamentFilter.all;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TextField(
        key: const ValueKey('captain-tournament-search'),
        decoration: const InputDecoration(
          hintText: 'Buscar torneo',
          prefixIcon: Padding(
            padding: EdgeInsets.all(16),
            child: CaptainAsset('search'),
          ),
        ),
        onChanged: (value) =>
            setState(() => _search = value.trim().toLowerCase()),
        maxLength: 80,
      ),
      const SizedBox(height: 16),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final entry in {
            _TournamentFilter.all: 'Todos',
            _TournamentFilter.upcoming: 'Próximos',
            _TournamentFilter.finished: 'Finalizados',
          }.entries)
            ChoiceChip(
              label: Text(entry.value),
              selected: _filter == entry.key,
              onSelected: (_) => setState(() => _filter = entry.key),
            ),
        ],
      ),
      const SizedBox(height: 20),
      CaptainLive<List<AdminTournament>>(
        watch: widget.repository.watchTournaments,
        builder: (context, tournaments) {
          final now = DateTime.now();
          final visible = tournaments.where((item) {
            final end = DateTime(
              item.endDate.toLocal().year,
              item.endDate.toLocal().month,
              item.endDate.toLocal().day,
            ).add(const Duration(days: 1));
            return item.name.toLowerCase().contains(_search) &&
                switch (_filter) {
                  _TournamentFilter.all => true,
                  _TournamentFilter.upcoming => item.startDate.isAfter(now),
                  _TournamentFilter.finished => end.isBefore(now),
                };
          }).toList()..sort((a, b) => a.startDate.compareTo(b.startDate));
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (visible.isEmpty)
                const CaptainCard(child: Text('No hay torneos que coincidan.')),
              for (final tournament in visible)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: CaptainCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            CaptainBadge(_tournamentPhase(tournament)),
                            CaptainBadge(
                              '${tournament.teamCount}/${tournament.maxTeams} equipos',
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          tournament.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const CaptainAsset('calendar'),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${captainDate(tournament.startDate)} — ${captainDate(tournament.endDate)}',
                                style: const TextStyle(
                                  color: captainMuted,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 28),
                        FilledButton(
                          onPressed: () => _openCaptain(
                            context,
                            CaptainTournamentDetail(
                              repository: widget.repository,
                              tournamentId: tournament.id,
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Ver detalles'),
                              SizedBox(width: 8),
                              CaptainAsset('chevron_right'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (tournaments.length >= 200) const _ListLimit(),
            ],
          );
        },
      ),
    ],
  );
}

String _tournamentPhase(AdminTournament tournament) {
  final now = DateTime.now();
  final end = tournament.endDate.toLocal();
  final endExclusive = DateTime(
    end.year,
    end.month,
    end.day,
  ).add(const Duration(days: 1));
  if (endExclusive.isBefore(now)) return 'Finalizado';
  if (tournament.startDate.isAfter(now)) return 'Próximo';
  return 'En curso';
}

class CaptainTournamentDetail extends StatelessWidget {
  const CaptainTournamentDetail({
    super.key,
    required this.repository,
    required this.tournamentId,
  });
  final CaptainRepository repository;
  final String tournamentId;
  @override
  Widget build(BuildContext context) => CaptainScaffold(
    title: 'Detalles del torneo',
    children: [
      CaptainLive<List<AdminTournament>>(
        watch: repository.watchTournaments,
        builder: (context, tournaments) {
          final found = tournaments
              .where((tournament) => tournament.id == tournamentId)
              .toList();
          if (found.isEmpty) {
            return const CaptainCard(
              child: Text('Este torneo no está disponible en la lista actual.'),
            );
          }
          final tournament = found.first;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CaptainCard(
                child: Column(
                  children: [
                    Text(
                      tournament.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    CaptainBadge(_tournamentPhase(tournament)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              CaptainCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Descripción del torneo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      tournament.description.isEmpty
                          ? 'Sin descripción.'
                          : tournament.description,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${captainDate(tournament.startDate)} — ${captainDate(tournament.endDate)}',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cupo: ${tournament.teamCount} de ${tournament.maxTeams} equipos',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              CaptainCard(
                padding: 8,
                child: Column(
                  children: [
                    _DetailLink(
                      'Equipos inscritos',
                      () => _openCaptain(
                        context,
                        _TournamentTeams(
                          repository: repository,
                          tournament: tournament,
                        ),
                      ),
                    ),
                    _DetailLink(
                      'Partidos',
                      () => _openCaptain(
                        context,
                        _TournamentMatches(
                          repository: repository,
                          tournament: tournament,
                        ),
                      ),
                    ),
                    _DetailLink(
                      'Tabla de posiciones',
                      () => _openCaptain(
                        context,
                        _TournamentStandings(
                          repository: repository,
                          tournament: tournament,
                        ),
                      ),
                    ),
                    _DetailLink(
                      'Calendario',
                      () => _openCaptain(
                        context,
                        _TournamentMatches(
                          repository: repository,
                          tournament: tournament,
                          calendar: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => _openCaptain(
                  context,
                  CaptainRegistrationPage(
                    repository: repository,
                    tournamentId: tournament.id,
                  ),
                ),
                child: const Text('Inscribir mi equipo / ver solicitud'),
              ),
            ],
          );
        },
      ),
    ],
  );
}

class _DetailLink extends StatelessWidget {
  const _DetailLink(this.title, this.onTap);
  final String title;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(
      title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
    ),
    trailing: const CaptainAsset('chevron_right'),
    onTap: onTap,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  );
}

class _TournamentTeams extends StatelessWidget {
  const _TournamentTeams({required this.repository, required this.tournament});
  final CaptainRepository repository;
  final AdminTournament tournament;
  @override
  Widget build(BuildContext context) => CaptainScaffold(
    title: 'Equipos inscritos',
    children: [
      Text(tournament.name, style: const TextStyle(color: captainText)),
      const SizedBox(height: 20),
      CaptainLive<List<AdminTeam>>(
        watch: () => repository.watchTeams(tournamentId: tournament.id),
        builder: (context, teams) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (teams.isEmpty)
              const CaptainCard(child: Text('Aún no hay equipos aprobados.')),
            for (final team in teams)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: CaptainCard(
                  child: Row(
                    children: [
                      const CaptainTeamLogo(),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          team.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (teams.length >= 200) const _ListLimit(),
          ],
        ),
      ),
    ],
  );
}

class _TournamentMatches extends StatefulWidget {
  const _TournamentMatches({
    required this.repository,
    required this.tournament,
    this.calendar = false,
  });
  final CaptainRepository repository;
  final AdminTournament tournament;
  final bool calendar;
  @override
  State<_TournamentMatches> createState() => _TournamentMatchesState();
}

class _TournamentMatchesState extends State<_TournamentMatches> {
  AdminMatchStatus? _status;
  @override
  Widget build(BuildContext context) => CaptainScaffold(
    title: widget.calendar ? 'Calendario' : 'Partidos del torneo',
    children: [
      Text(widget.tournament.name, style: const TextStyle(color: captainText)),
      const SizedBox(height: 16),
      if (!widget.calendar) ...[
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Todos'),
              selected: _status == null,
              onSelected: (_) => setState(() => _status = null),
            ),
            for (final status in AdminMatchStatus.values)
              ChoiceChip(
                label: Text(_matchStatus(status)),
                selected: _status == status,
                onSelected: (_) => setState(() => _status = status),
              ),
          ],
        ),
        const SizedBox(height: 20),
      ],
      CaptainLive<List<AdminMatch>>(
        watch: () =>
            widget.repository.watchMatches(tournamentId: widget.tournament.id),
        builder: (context, matches) => CaptainLive<List<AdminTeam>>(
          watch: () =>
              widget.repository.watchTeams(tournamentId: widget.tournament.id),
          builder: (context, teams) {
            final visible =
                matches
                    .where(
                      (match) => _status == null || match.status == _status,
                    )
                    .toList()
                  ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
            String? lastDay;
            final children = <Widget>[];
            for (final match in visible) {
              final date = captainDate(match.startsAt);
              if (widget.calendar && date != lastDay) {
                children.add(
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      date,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                );
                lastDay = date;
              }
              children.add(
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: CaptainCard(
                    child: _MatchContent(match: match, teams: teams),
                  ),
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (visible.isEmpty)
                  const CaptainCard(
                    child: Text('No hay partidos para mostrar.'),
                  ),
                ...children,
                if (matches.length >= 200) const _ListLimit(),
              ],
            );
          },
        ),
      ),
    ],
  );
}

String _matchStatus(AdminMatchStatus status) => switch (status) {
  AdminMatchStatus.scheduled => 'Programado',
  AdminMatchStatus.live => 'En curso',
  AdminMatchStatus.finished => 'Finalizado',
  AdminMatchStatus.cancelled => 'Cancelado',
};

String _teamName(List<AdminTeam> teams, String id) {
  for (final team in teams) {
    if (team.id == id) return team.name;
  }
  return 'Equipo';
}

class _MatchContent extends StatelessWidget {
  const _MatchContent({required this.match, required this.teams});
  final AdminMatch match;
  final List<AdminTeam> teams;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Wrap(
        spacing: 12,
        runSpacing: 8,
        alignment: WrapAlignment.spaceBetween,
        children: [
          Text(
            '${captainDate(match.startsAt)} · ${captainTime(match.startsAt)}',
            style: const TextStyle(color: captainMuted),
          ),
          CaptainBadge(
            _matchStatus(match.status),
            warning: match.status == AdminMatchStatus.cancelled,
          ),
        ],
      ),
      const SizedBox(height: 20),
      Row(
        children: [
          Expanded(
            child: Text(
              _teamName(teams, match.homeTeamId),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              match.homeScore == null || match.awayScore == null
                  ? 'VS'
                  : '${match.homeScore} - ${match.awayScore}',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: captainGreen,
              ),
            ),
          ),
          Expanded(
            child: Text(
              _teamName(teams, match.awayTeamId),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      const Divider(height: 28),
      Text(
        'Cancha: ${match.courtId}',
        style: const TextStyle(color: captainMuted),
      ),
    ],
  );
}

/// A computed summary, never a captain-editable ranking or stored authority.
class CaptainStanding {
  CaptainStanding(this.team);
  final AdminTeam team;
  int played = 0, won = 0, drawn = 0, lost = 0, goalsFor = 0, goalsAgainst = 0;
  int get points => won * 3 + drawn;
  int get difference => goalsFor - goalsAgainst;
}

List<CaptainStanding> captainStandings(
  List<AdminTeam> teams,
  List<AdminMatch> matches,
) {
  final rows = {for (final team in teams) team.id: CaptainStanding(team)};
  for (final match in matches) {
    if (match.status != AdminMatchStatus.finished ||
        match.homeScore == null ||
        match.awayScore == null) {
      continue;
    }
    final home = rows[match.homeTeamId], away = rows[match.awayTeamId];
    if (home == null || away == null || match.homeTeamId == match.awayTeamId) {
      continue;
    }
    home.played++;
    away.played++;
    home.goalsFor += match.homeScore!;
    home.goalsAgainst += match.awayScore!;
    away.goalsFor += match.awayScore!;
    away.goalsAgainst += match.homeScore!;
    if (match.homeScore! > match.awayScore!) {
      home.won++;
      away.lost++;
    } else if (match.homeScore! < match.awayScore!) {
      away.won++;
      home.lost++;
    } else {
      home.drawn++;
      away.drawn++;
    }
  }
  return rows.values.toList()..sort((a, b) {
    var result = b.points.compareTo(a.points);
    if (result != 0) return result;
    result = b.difference.compareTo(a.difference);
    if (result != 0) return result;
    result = b.goalsFor.compareTo(a.goalsFor);
    return result != 0 ? result : a.team.name.compareTo(b.team.name);
  });
}

class _TournamentStandings extends StatelessWidget {
  const _TournamentStandings({
    required this.repository,
    required this.tournament,
  });
  final CaptainRepository repository;
  final AdminTournament tournament;
  @override
  Widget build(BuildContext context) => CaptainScaffold(
    title: 'Tabla de posiciones',
    children: [
      Text(tournament.name, style: const TextStyle(color: captainText)),
      const SizedBox(height: 20),
      CaptainLive<List<AdminTeam>>(
        watch: () => repository.watchTeams(tournamentId: tournament.id),
        builder: (context, teams) => CaptainLive<List<AdminMatch>>(
          watch: () => repository.watchMatches(tournamentId: tournament.id),
          builder: (context, matches) {
            final rows = captainStandings(teams, matches);
            return CaptainCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (rows.isEmpty)
                    const Text('Aún no hay equipos inscritos.')
                  else
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 20,
                        columns: [
                          for (final label in [
                            'Equipo',
                            'PJ',
                            'G',
                            'E',
                            'P',
                            'GF',
                            'GC',
                            'DG',
                            'Pts',
                          ])
                            DataColumn(label: Text(label)),
                        ],
                        rows: rows
                            .map(
                              (row) => DataRow(
                                cells: [
                                  DataCell(Text(row.team.name)),
                                  for (final value in [
                                    row.played,
                                    row.won,
                                    row.drawn,
                                    row.lost,
                                    row.goalsFor,
                                    row.goalsAgainst,
                                    row.difference,
                                    row.points,
                                  ])
                                    DataCell(Text('$value')),
                                ],
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  const SizedBox(height: 16),
                  const Text(
                    'Resumen de partidos finalizados: victoria 3 puntos, empate 1. '
                    'Orden: puntos, diferencia de goles y goles a favor. Consulta el reglamento del torneo para clasificaciones oficiales.',
                    style: TextStyle(color: captainMuted, fontSize: 12),
                  ),
                  if (teams.length >= 200 || matches.length >= 200)
                    const _ListLimit(),
                ],
              ),
            );
          },
        ),
      ),
    ],
  );
}

class CaptainRegistrationPage extends StatefulWidget {
  const CaptainRegistrationPage({
    super.key,
    required this.repository,
    required this.tournamentId,
  });
  final CaptainRepository repository;
  final String tournamentId;
  @override
  State<CaptainRegistrationPage> createState() =>
      _CaptainRegistrationPageState();
}

class _CaptainRegistrationPageState extends State<CaptainRegistrationPage> {
  bool _saving = false;
  String? _error;
  Future<void> _register() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repository.registerForTournament(widget.tournamentId);
      if (mounted) {
        captainNotify(
          context,
          'Solicitud enviada. El administrador revisará tu inscripción.',
        );
      }
    } catch (error) {
      if (mounted) setState(() => _error = _captainError(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => CaptainScaffold(
    title: 'Inscripción',
    children: [
      CaptainLive<List<AdminTournament>>(
        watch: widget.repository.watchTournaments,
        builder: (context, tournaments) {
          final found = tournaments
              .where((tournament) => tournament.id == widget.tournamentId)
              .toList();
          if (found.isEmpty) {
            return const CaptainCard(child: Text('Torneo no disponible.'));
          }
          final tournament = found.first;
          return CaptainLive<CaptainTeam?>(
            watch: widget.repository.watchMyTeam,
            builder: (context, team) =>
                CaptainLive<List<TournamentRegistration>>(
                  watch: widget.repository.watchRegistrations,
                  builder: (context, entries) => CaptainLive<AppSettings>(
                    watch: widget.repository.watchSettings,
                    builder: (context, settings) {
                      final registrations = entries
                          .where(
                            (entry) =>
                                entry.tournamentId == widget.tournamentId,
                          )
                          .toList();
                      final entry = registrations.isEmpty
                          ? null
                          : registrations.first;
                      final closed =
                          !settings.registrationEnabled ||
                          !DateTime.now().isBefore(
                            tournament.endDate.add(const Duration(days: 1)),
                          ) ||
                          tournament.teamCount >= tournament.maxTeams;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CaptainCard(
                            child: Row(
                              children: [
                                const CaptainTeamLogo(),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tournament.name,
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      CaptainBadge(
                                        _tournamentPhase(tournament),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                          const Text(
                            'Nombre del equipo',
                            style: TextStyle(
                              color: captainText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          CaptainCard(
                            child: Text(
                              team?.name ?? 'Primero registra tu equipo.',
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Estado',
                            style: TextStyle(
                              color: captainText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          CaptainCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry == null
                                      ? 'Sin solicitud'
                                      : _registrationStatus(entry.status),
                                ),
                                if (entry != null &&
                                    entry.reviewNote.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(entry.reviewNote),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'La solicitud queda pendiente hasta que el administrador la apruebe. '
                            'La inscripción utiliza el nombre de tu equipo; no publica tu correo ni la lista privada de jugadores.',
                            style: TextStyle(color: captainMuted),
                          ),
                          const SizedBox(height: 24),
                          if (team == null)
                            OutlinedButton(
                              onPressed: () =>
                                  _editCaptainTeam(context, widget.repository),
                              child: const Text('Registrar mi equipo'),
                            ),
                          if (closed && entry == null)
                            const CaptainFormError(
                              'Las inscripciones están cerradas o el cupo está completo.',
                            ),
                          if (_error != null) CaptainFormError(_error!),
                          CaptainSaveButton(
                            key: const ValueKey('captain-register-tournament'),
                            label: entry == null
                                ? 'Enviar inscripción'
                                : 'Solicitud registrada',
                            saving: _saving,
                            onPressed: team == null || entry != null || closed
                                ? null
                                : _register,
                          ),
                        ],
                      );
                    },
                  ),
                ),
          );
        },
      ),
    ],
  );
}

class _CaptainProfile extends StatefulWidget {
  const _CaptainProfile({
    required this.repository,
    required this.profile,
    required this.onSignOut,
    required this.signingOut,
    this.onRefreshAccess,
  });
  final CaptainRepository repository;
  final CaptainProfile profile;
  final Future<void> Function() onSignOut;
  final bool signingOut;
  final Future<void> Function()? onRefreshAccess;
  @override
  State<_CaptainProfile> createState() => _CaptainProfileState();
}

class _CaptainProfileState extends State<_CaptainProfile> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.profile.displayName);
  bool _saving = false;
  bool _refreshing = false;
  String? _error;
  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repository.updateProfile(displayName: _name.text.trim());
      if (mounted) captainNotify(context, 'Perfil guardado.');
    } catch (error) {
      if (mounted) setState(() => _error = _captainError(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    try {
      await widget.onRefreshAccess!();
    } catch (_) {
      if (mounted) captainNotify(context, 'No se pudo actualizar la sesión.');
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      CaptainCard(
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Capitán',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SelectableText(widget.profile.email),
              const SizedBox(height: 20),
              TextFormField(
                key: const ValueKey('captain-profile-name'),
                controller: _name,
                enabled: !_saving,
                maxLength: 80,
                decoration: const InputDecoration(
                  labelText: 'Nombre para mostrar',
                ),
                validator: captainNameValidator,
              ),
              const SizedBox(height: 16),
              if (_error != null) CaptainFormError(_error!),
              CaptainSaveButton(
                label: 'Guardar perfil',
                saving: _saving,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 20),
      CaptainLive<AppSettings>(
        watch: widget.repository.watchSettings,
        builder: (context, settings) => CaptainCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Privacidad y tus datos',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'FutSchool guarda tu perfil, tu equipo y sus jugadores para organizar torneos. '
                'Solo puedes modificar los datos de tu equipo. El administrador puede gestionarlos para operar el torneo.',
              ),
              const SizedBox(height: 16),
              if (settings.privacyNotice.isEmpty ||
                  settings.privacyResponsible.isEmpty ||
                  settings.privacyContact.isEmpty)
                const CaptainFormError(
                  'El aviso institucional y el contacto para derechos ARCO están pendientes de configurar. '
                  'Esta información no sustituye el aviso de privacidad de la universidad.',
                )
              else ...[
                Text('Responsable: ${settings.privacyResponsible}'),
                const SizedBox(height: 8),
                SelectableText(settings.privacyNotice),
                const SizedBox(height: 12),
                Text(
                  'Contacto para acceso, rectificación, cancelación u oposición: ${settings.privacyContact}',
                ),
                if (settings.privacyVersion.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('Versión: ${settings.privacyVersion}'),
                  ),
              ],
              const SizedBox(height: 12),
              const Text(
                'Para proteger tu identidad, las solicitudes se atienden por el canal institucional. '
                'No envíes contraseñas ni identificaciones en campos del equipo.',
                style: TextStyle(color: captainMuted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 20),
      if (widget.onRefreshAccess != null) ...[
        OutlinedButton(
          onPressed: _refreshing ? null : _refresh,
          child: Text(
            _refreshing ? 'Actualizando...' : 'Actualizar permisos de sesión',
          ),
        ),
        const SizedBox(height: 12),
      ],
      OutlinedButton.icon(
        onPressed: widget.signingOut ? null : widget.onSignOut,
        icon: const Icon(Icons.logout),
        label: Text(widget.signingOut ? 'Cerrando sesión...' : 'Cerrar sesión'),
      ),
    ],
  );
}

class _ListLimit extends StatelessWidget {
  const _ListLimit();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(top: 12),
    child: Text(
      'Vista limitada a 200 registros. '
      'Los totales y resúmenes corresponden a los datos cargados.',
      style: TextStyle(color: captainMuted, fontSize: 12),
    ),
  );
}
