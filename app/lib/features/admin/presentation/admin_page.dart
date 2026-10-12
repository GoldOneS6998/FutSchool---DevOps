import 'package:flutter/material.dart';

import '../domain/admin_repository.dart';

/// Administration uses the repository's live data; no sample totals or users.
class AdminPage extends StatefulWidget {
  const AdminPage({
    super.key,
    required this.repository,
    required this.onSignOut,
  });

  final AdminRepository repository;
  final Future<void> Function() onSignOut;

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  bool _signingOut = false;

  Future<void> _signOut() async {
    if (_signingOut) return;
    setState(() => _signingOut = true);
    try {
      await widget.onSignOut();
    } catch (_) {
      if (mounted) {
        _notify(context, 'No se pudo cerrar sesión. Intenta de nuevo.');
      }
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repository = widget.repository;
    return _AdminScaffold(
      title: 'FutSchool',
      actions: [
        IconButton(
          tooltip: 'Cerrar sesión',
          onPressed: _signingOut ? null : _signOut,
          icon: const Icon(Icons.logout),
        ),
      ],
      children: [
        const Text(
          'Hola, Admin',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text('Panel de control general'),
        const SizedBox(height: 24),
        _Statistics(repository: repository),
        const SizedBox(height: 24),
        _ActionCards(
          actions: [
            _AdminAction(
              title: 'Panel de Administración',
              description: 'Gestiona torneos, equipos y partidos.',
              icon: Icons.settings_outlined,
              onTap: () =>
                  _open(context, _ManagementPage(repository: repository)),
            ),
            _AdminAction(
              title: 'Crear torneo',
              description: 'Define fechas, cupos y descripción.',
              icon: Icons.emoji_events_outlined,
              onTap: () => _openAndNotify(
                context,
                _TournamentForm(repository: repository),
                'Torneo creado.',
              ),
            ),
            _AdminAction(
              title: 'Partidos del torneo',
              description: 'Consulta horarios, estados y resultados.',
              icon: Icons.calendar_month_outlined,
              onTap: () => _open(context, _MatchesPage(repository: repository)),
            ),
            _AdminAction(
              title: 'Crear partido',
              description: 'Programa dos equipos y reserva una cancha.',
              icon: Icons.add_circle_outline,
              onTap: () => _openAndNotify(
                context,
                _MatchForm(repository: repository),
                'Partido programado.',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ManagementPage extends StatelessWidget {
  const _ManagementPage({required this.repository});

  final AdminRepository repository;

  @override
  Widget build(BuildContext context) => _AdminScaffold(
    title: 'Administración',
    children: [
      _Statistics(repository: repository),
      const SizedBox(height: 24),
      _ActionCards(
        actions: [
          _AdminAction(
            title: 'Gestionar torneos',
            description: 'Consulta los torneos y crea uno nuevo.',
            icon: Icons.emoji_events_outlined,
            onTap: () =>
                _open(context, _TournamentsPage(repository: repository)),
          ),
          _AdminAction(
            title: 'Gestionar equipos',
            description: 'Registra equipos dentro de un torneo.',
            icon: Icons.shield_outlined,
            onTap: () => _open(context, _TeamsPage(repository: repository)),
          ),
          _AdminAction(
            title: 'Gestionar partidos',
            description: 'Programa encuentros y actualiza marcadores.',
            icon: Icons.sports_soccer,
            onTap: () => _open(context, _MatchesPage(repository: repository)),
          ),
        ],
      ),
      const SizedBox(height: 24),
      const Text(
        'Las cuentas de acceso se administran desde Firebase. '
        'Este panel no asigna permisos de administrador.',
      ),
    ],
  );
}

class _Statistics extends StatefulWidget {
  const _Statistics({required this.repository});

  final AdminRepository repository;

  @override
  State<_Statistics> createState() => _StatisticsState();
}

class _StatisticsState extends State<_Statistics> {
  late final _tournaments = widget.repository.watchTournaments();
  late final _teams = widget.repository.watchTeams();
  late final _matches = widget.repository.watchMatches();

  @override
  Widget build(BuildContext context) => StreamBuilder(
    stream: _tournaments,
    builder: (context, tournaments) => StreamBuilder(
      stream: _teams,
      builder: (context, teams) => StreamBuilder(
        stream: _matches,
        builder: (context, matches) {
          final error = tournaments.error ?? teams.error ?? matches.error;
          if (error != null) return _ErrorNotice(message: _safeError(error));
          if (!tournaments.hasData || !teams.hasData || !matches.hasData) {
            return const _Loading();
          }
          final counts = [
            ('Torneos', tournaments.data!.length),
            ('Equipos', teams.data!.length),
            ('Partidos', matches.data!.length),
          ];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 600 ? 3 : 1;
                  final width =
                      (constraints.maxWidth - (columns - 1) * 12) / columns;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final count in counts)
                        SizedBox(
                          width: width,
                          child: _Panel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(count.$1),
                                Text(
                                  '${count.$2}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium,
                                ),
                                const Text('Registros cargados'),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              if (counts.any((count) => count.$2 >= 200)) ...[
                const SizedBox(height: 8),
                const Text(
                  'Cada vista muestra hasta 200 registros. '
                  'Estos valores no son totales de toda la base de datos.',
                ),
              ],
            ],
          );
        },
      ),
    ),
  );
}

class _TournamentsPage extends StatefulWidget {
  const _TournamentsPage({required this.repository});

  final AdminRepository repository;

  @override
  State<_TournamentsPage> createState() => _TournamentsPageState();
}

class _TournamentsPageState extends State<_TournamentsPage> {
  late final _stream = widget.repository.watchTournaments();

  @override
  Widget build(BuildContext context) => _AdminScaffold(
    title: 'Torneos',
    children: [
      FilledButton.icon(
        onPressed: () => _openAndNotify(
          context,
          _TournamentForm(repository: widget.repository),
          'Torneo creado.',
        ),
        icon: const Icon(Icons.add),
        label: const Text('Crear torneo'),
      ),
      const SizedBox(height: 20),
      StreamBuilder(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _ErrorNotice(message: _safeError(snapshot.error!));
          }
          if (!snapshot.hasData) return const _Loading();
          final tournaments = snapshot.data!;
          if (tournaments.isEmpty) {
            return const _Empty('Todavía no hay torneos. Crea el primero.');
          }
          return Column(
            children: [
              for (final tournament in tournaments) ...[
                _Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        tournament.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_dateText(tournament.startDate)} – '
                        '${_dateText(tournament.endDate)}',
                      ),
                      Text(
                        '${tournament.teamCount} de '
                        '${tournament.maxTeams} equipos registrados',
                      ),
                      if (tournament.description.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(tournament.description),
                      ],
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _open(
                              context,
                              _TeamsPage(
                                repository: widget.repository,
                                initialTournamentId: tournament.id,
                              ),
                            ),
                            icon: const Icon(Icons.groups_outlined),
                            label: const Text('Equipos'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _open(
                              context,
                              _MatchesPage(
                                repository: widget.repository,
                                initialTournamentId: tournament.id,
                              ),
                            ),
                            icon: const Icon(Icons.sports_soccer),
                            label: const Text('Partidos'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              _LimitNotice(count: tournaments.length),
            ],
          );
        },
      ),
    ],
  );
}

class _TeamsPage extends StatefulWidget {
  const _TeamsPage({required this.repository, this.initialTournamentId});

  final AdminRepository repository;
  final String? initialTournamentId;

  @override
  State<_TeamsPage> createState() => _TeamsPageState();
}

class _TeamsPageState extends State<_TeamsPage> {
  late final _tournaments = widget.repository.watchTournaments();
  late String? _tournamentId = widget.initialTournamentId;
  late Stream<List<AdminTeam>> _teams = widget.repository.watchTeams(
    tournamentId: _tournamentId,
  );

  void _selectTournament(String? id) {
    setState(() {
      _tournamentId = id;
      _teams = widget.repository.watchTeams(tournamentId: id);
    });
  }

  @override
  Widget build(BuildContext context) => _AdminScaffold(
    title: 'Equipos',
    children: [
      StreamBuilder(
        stream: _tournaments,
        builder: (context, tournamentSnapshot) {
          if (tournamentSnapshot.hasError) {
            return _ErrorNotice(message: _safeError(tournamentSnapshot.error!));
          }
          if (!tournamentSnapshot.hasData) return const _Loading();
          final tournaments = tournamentSnapshot.data!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TournamentPicker(
                tournaments: tournaments,
                selectedId: _tournamentId,
                allowAll: true,
                onChanged: _selectTournament,
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                key: const Key('registerTeamOpen'),
                onPressed: tournaments.isEmpty
                    ? null
                    : () => _openAndNotify(
                        context,
                        _TeamForm(
                          repository: widget.repository,
                          initialTournamentId: _tournamentId,
                        ),
                        'Equipo registrado.',
                      ),
                icon: const Icon(Icons.add),
                label: const Text('Registrar equipo'),
              ),
              if (tournaments.isEmpty) ...[
                const SizedBox(height: 12),
                const _Empty('Crea un torneo antes de registrar equipos.'),
              ],
              const SizedBox(height: 20),
              StreamBuilder(
                stream: _teams,
                builder: (context, teamSnapshot) {
                  if (teamSnapshot.hasError) {
                    return _ErrorNotice(
                      message: _safeError(teamSnapshot.error!),
                    );
                  }
                  if (!teamSnapshot.hasData) return const _Loading();
                  final teams = teamSnapshot.data!;
                  if (teams.isEmpty) {
                    return const _Empty('No hay equipos en esta selección.');
                  }
                  final names = {for (final t in tournaments) t.id: t.name};
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final team in teams) ...[
                        _Panel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                team.name,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 6),
                              Text(names[team.tournamentId] ?? 'Torneo'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      _LimitNotice(count: teams.length),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    ],
  );
}

class _MatchesPage extends StatefulWidget {
  const _MatchesPage({required this.repository, this.initialTournamentId});

  final AdminRepository repository;
  final String? initialTournamentId;

  @override
  State<_MatchesPage> createState() => _MatchesPageState();
}

class _MatchesPageState extends State<_MatchesPage> {
  late final _tournaments = widget.repository.watchTournaments();
  late String? _tournamentId = widget.initialTournamentId;
  late Stream<List<AdminTeam>> _teams = widget.repository.watchTeams(
    tournamentId: _tournamentId,
  );
  late Stream<List<AdminMatch>> _matches = widget.repository.watchMatches(
    tournamentId: _tournamentId,
  );
  AdminMatchStatus? _status;

  void _selectTournament(String? id) {
    setState(() {
      _tournamentId = id;
      _teams = widget.repository.watchTeams(tournamentId: id);
      _matches = widget.repository.watchMatches(tournamentId: id);
    });
  }

  @override
  Widget build(BuildContext context) => _AdminScaffold(
    title: 'Partidos del torneo',
    children: [
      StreamBuilder(
        stream: _tournaments,
        builder: (context, tournaments) {
          if (tournaments.hasError) {
            return _ErrorNotice(message: _safeError(tournaments.error!));
          }
          if (!tournaments.hasData) return const _Loading();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TournamentPicker(
                tournaments: tournaments.data!,
                selectedId: _tournamentId,
                allowAll: true,
                onChanged: _selectTournament,
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: tournaments.data!.isEmpty
                    ? null
                    : () => _openAndNotify(
                        context,
                        _MatchForm(
                          repository: widget.repository,
                          initialTournamentId: _tournamentId,
                        ),
                        'Partido programado.',
                      ),
                icon: const Icon(Icons.add),
                label: const Text('Crear partido'),
              ),
            ],
          );
        },
      ),
      const SizedBox(height: 16),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          FilterChip(
            label: const Text('Todos'),
            selected: _status == null,
            onSelected: (_) => setState(() => _status = null),
          ),
          for (final status in AdminMatchStatus.values)
            FilterChip(
              label: Text(_statusText(status)),
              selected: _status == status,
              onSelected: (_) => setState(() => _status = status),
            ),
        ],
      ),
      const SizedBox(height: 20),
      StreamBuilder(
        stream: _teams,
        builder: (context, teams) => StreamBuilder(
          stream: _matches,
          builder: (context, matches) {
            final error = teams.error ?? matches.error;
            if (error != null) return _ErrorNotice(message: _safeError(error));
            if (!teams.hasData || !matches.hasData) return const _Loading();
            final names = {for (final team in teams.data!) team.id: team.name};
            final filtered = matches.data!
                .where((match) => _status == null || match.status == _status)
                .toList();
            if (filtered.isEmpty) {
              return const _Empty('No hay partidos en esta selección.');
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final match in filtered) ...[
                  _Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _dateTimeText(match.startsAt),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(_statusText(match.status)),
                        const SizedBox(height: 12),
                        Text(
                          '${names[match.homeTeamId] ?? 'Equipo local'} '
                          'vs ${names[match.awayTeamId] ?? 'Equipo visitante'}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        if (match.homeScore != null && match.awayScore != null)
                          Text(
                            '${match.homeScore} – ${match.awayScore}',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        const SizedBox(height: 10),
                        Text('Cancha: ${match.courtId}'),
                        if (match.status != AdminMatchStatus.cancelled) ...[
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () => _openAndNotify(
                              context,
                              _MatchResultForm(
                                repository: widget.repository,
                                match: match,
                                homeName: names[match.homeTeamId] ?? 'Local',
                                awayName:
                                    names[match.awayTeamId] ?? 'Visitante',
                              ),
                              'Partido actualizado.',
                            ),
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Estado y resultado'),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                _LimitNotice(count: matches.data!.length),
              ],
            );
          },
        ),
      ),
    ],
  );
}

class _TournamentForm extends StatefulWidget {
  const _TournamentForm({required this.repository});

  final AdminRepository repository;

  @override
  State<_TournamentForm> createState() => _TournamentFormState();
}

class _TournamentFormState extends State<_TournamentForm> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _maxTeams = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _maxTeams.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.repository.createTournament(
        name: _name.text.trim(),
        description: _description.text.trim(),
        startDate: _utcDate(_startDate!),
        endDate: _utcDate(_endDate!),
        maxTeams: int.parse(_maxTeams.text.trim()),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) setState(() => _error = _safeError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => _AdminScaffold(
    title: 'Crear torneo',
    children: [
      Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              key: const Key('tournamentName'),
              controller: _name,
              enabled: !_busy,
              maxLength: 100,
              decoration: const InputDecoration(labelText: 'Nombre del torneo'),
              validator: (value) => _lengthError(value, min: 3, max: 100),
            ),
            const SizedBox(height: 16),
            _FieldPair(
              first: _DateField(
                label: 'Fecha de inicio',
                value: _startDate,
                enabled: !_busy,
                onChanged: (date) => setState(() => _startDate = date),
                validator: (date) =>
                    date == null ? 'Selecciona la fecha.' : null,
              ),
              second: _DateField(
                label: 'Fecha de fin',
                value: _endDate,
                enabled: !_busy,
                onChanged: (date) => setState(() => _endDate = date),
                validator: (date) {
                  if (date == null) return 'Selecciona la fecha.';
                  if (_startDate != null && date.isBefore(_startDate!)) {
                    return 'Debe ser igual o posterior al inicio.';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('tournamentCapacity'),
              controller: _maxTeams,
              enabled: !_busy,
              keyboardType: TextInputType.number,
              maxLength: 2,
              decoration: const InputDecoration(
                labelText: 'Número máximo de equipos',
                helperText: 'Entre 2 y 64 equipos.',
              ),
              validator: (value) {
                final number = int.tryParse(value?.trim() ?? '');
                return number == null || number < 2 || number > 64
                    ? 'Introduce un número entero entre 2 y 64.'
                    : null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _description,
              enabled: !_busy,
              minLines: 3,
              maxLines: 6,
              maxLength: 2000,
              decoration: const InputDecoration(
                labelText: 'Descripción (opcional)',
              ),
              validator: (value) => (value?.trim().length ?? 0) > 2000
                  ? 'Máximo 2000 caracteres.'
                  : null,
            ),
            _FormFeedback(busy: _busy, error: _error),
            const SizedBox(height: 20),
            FilledButton(
              key: const Key('createTournamentSubmit'),
              onPressed: _busy ? null : _submit,
              child: const Text('Crear torneo'),
            ),
          ],
        ),
      ),
    ],
  );
}

class _TeamForm extends StatefulWidget {
  const _TeamForm({required this.repository, this.initialTournamentId});

  final AdminRepository repository;
  final String? initialTournamentId;

  @override
  State<_TeamForm> createState() => _TeamFormState();
}

class _TeamFormState extends State<_TeamForm> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  late final _tournaments = widget.repository.watchTournaments();
  late String? _tournamentId = widget.initialTournamentId;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.repository.createTeam(
        tournamentId: _tournamentId!,
        name: _name.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) setState(() => _error = _safeError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => _AdminScaffold(
    title: 'Registrar equipo',
    children: [
      StreamBuilder(
        stream: _tournaments,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _ErrorNotice(message: _safeError(snapshot.error!));
          }
          if (!snapshot.hasData) return const _Loading();
          if (snapshot.data!.isEmpty) {
            return const _Empty('Crea un torneo antes de registrar un equipo.');
          }
          return Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TournamentPicker(
                  tournaments: snapshot.data!,
                  selectedId: _tournamentId,
                  enabled: !_busy,
                  onChanged: (id) => setState(() => _tournamentId = id),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('teamName'),
                  controller: _name,
                  enabled: !_busy,
                  maxLength: 80,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del equipo',
                  ),
                  validator: (value) => _lengthError(value, min: 2, max: 80),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Se comprobará que el torneo tenga cupo disponible '
                  'antes de registrar el equipo.',
                ),
                _FormFeedback(busy: _busy, error: _error),
                const SizedBox(height: 20),
                FilledButton(
                  key: const Key('createTeamSubmit'),
                  onPressed: _busy ? null : _submit,
                  child: const Text('Registrar equipo'),
                ),
              ],
            ),
          );
        },
      ),
    ],
  );
}

class _MatchForm extends StatefulWidget {
  const _MatchForm({required this.repository, this.initialTournamentId});

  final AdminRepository repository;
  final String? initialTournamentId;

  @override
  State<_MatchForm> createState() => _MatchFormState();
}

class _MatchFormState extends State<_MatchForm> {
  final _form = GlobalKey<FormState>();
  final _court = TextEditingController();
  late final _tournaments = widget.repository.watchTournaments();
  late String? _tournamentId = widget.initialTournamentId;
  Stream<List<AdminTeam>>? _teams;
  String? _homeTeamId;
  String? _awayTeamId;
  DateTime? _date;
  int? _hour;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (_tournamentId != null) {
      _teams = widget.repository.watchTeams(tournamentId: _tournamentId);
    }
  }

  @override
  void dispose() {
    _court.dispose();
    super.dispose();
  }

  void _selectTournament(String? id) {
    setState(() {
      _tournamentId = id;
      _homeTeamId = null;
      _awayTeamId = null;
      _date = null;
      _teams = id == null
          ? null
          : widget.repository.watchTeams(tournamentId: id);
    });
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    final startsAt = DateTime(_date!.year, _date!.month, _date!.day, _hour!);
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.repository.createMatch(
        tournamentId: _tournamentId!,
        homeTeamId: _homeTeamId!,
        awayTeamId: _awayTeamId!,
        courtId: _court.text.trim(),
        startsAt: startsAt.toUtc(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) setState(() => _error = _safeError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => _AdminScaffold(
    title: 'Crear partido',
    children: [
      StreamBuilder(
        stream: _tournaments,
        builder: (context, tournaments) {
          if (tournaments.hasError) {
            return _ErrorNotice(message: _safeError(tournaments.error!));
          }
          if (!tournaments.hasData) return const _Loading();
          final entries = tournaments.data!;
          if (entries.isEmpty) {
            return const _Empty(
              'Crea un torneo y registra al menos dos equipos.',
            );
          }
          AdminTournament? selected;
          for (final tournament in entries) {
            if (tournament.id == _tournamentId) selected = tournament;
          }
          return Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TournamentPicker(
                  tournaments: entries,
                  selectedId: _tournamentId,
                  enabled: !_busy,
                  onChanged: _selectTournament,
                ),
                const SizedBox(height: 16),
                if (_teams != null)
                  StreamBuilder(
                    stream: _teams,
                    builder: (context, teams) {
                      if (teams.hasError) {
                        return _ErrorNotice(message: _safeError(teams.error!));
                      }
                      if (!teams.hasData) return const _Loading();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (teams.data!.length < 2) ...[
                            const Text(
                              'Este torneo necesita al menos dos equipos. '
                              'Regístralos desde Gestionar equipos.',
                            ),
                            const SizedBox(height: 12),
                          ],
                          _TeamPicker(
                            label: 'Equipo local',
                            teams: teams.data!,
                            selectedId: _homeTeamId,
                            enabled: !_busy,
                            onChanged: (id) => setState(() => _homeTeamId = id),
                          ),
                          const SizedBox(height: 16),
                          _TeamPicker(
                            label: 'Equipo visitante',
                            teams: teams.data!,
                            selectedId: _awayTeamId,
                            enabled: !_busy,
                            onChanged: (id) => setState(() => _awayTeamId = id),
                            validator: (id) {
                              if (id == null) return 'Selecciona un equipo.';
                              return id == _homeTeamId
                                  ? 'Debe ser distinto del equipo local.'
                                  : null;
                            },
                          ),
                        ],
                      );
                    },
                  )
                else
                  const Text('Selecciona un torneo para ver sus equipos.'),
                const SizedBox(height: 16),
                _FieldPair(
                  first: _DateField(
                    label: 'Fecha del partido',
                    value: _date,
                    enabled: !_busy && selected != null,
                    firstDate: selected == null
                        ? null
                        : _localDate(selected.startDate),
                    lastDate: selected == null
                        ? null
                        : _localDate(selected.endDate),
                    onChanged: (date) => setState(() => _date = date),
                    validator: (date) => date == null
                        ? 'Selecciona la fecha dentro del torneo.'
                        : null,
                  ),
                  second: DropdownButtonFormField<int>(
                    key: const Key('matchHour'),
                    initialValue: _hour,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Hora local'),
                    items: [
                      for (var hour = 0; hour < 24; hour++)
                        DropdownMenuItem(
                          value: hour,
                          child: Text('${_twoDigits(hour)}:00'),
                        ),
                    ],
                    onChanged: _busy
                        ? null
                        : (hour) => setState(() => _hour = hour),
                    validator: (hour) =>
                        hour == null ? 'Selecciona la hora.' : null,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('matchCourt'),
                  controller: _court,
                  enabled: !_busy,
                  maxLength: 40,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Cancha',
                    helperText: 'Ejemplo: cancha-1. Letras minúsculas, números y guiones.',
                  ),
                  validator: (value) =>
                      RegExp(r'^[a-z0-9][a-z0-9-]{0,39}$')
                          .hasMatch(value?.trim() ?? '')
                      ? null
                      : 'Usa un nombre válido para la cancha.',
                ),
                const SizedBox(height: 12),
                const Text(
                  'Cada partido reserva 60 minutos, empezando en una hora exacta. '
                  'Usa siempre el mismo nombre para la misma cancha. '
                  'Un horario ocupado será rechazado.',
                ),
                _FormFeedback(busy: _busy, error: _error),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed:
                      _busy ||
                          selected == null ||
                          _teams == null ||
                          _homeTeamId == null ||
                          _awayTeamId == null
                      ? null
                      : _submit,
                  child: const Text('Programar partido'),
                ),
              ],
            ),
          );
        },
      ),
    ],
  );
}

class _MatchResultForm extends StatefulWidget {
  const _MatchResultForm({
    required this.repository,
    required this.match,
    required this.homeName,
    required this.awayName,
  });

  final AdminRepository repository;
  final AdminMatch match;
  final String homeName;
  final String awayName;

  @override
  State<_MatchResultForm> createState() => _MatchResultFormState();
}

class _MatchResultFormState extends State<_MatchResultForm> {
  final _form = GlobalKey<FormState>();
  late final _homeScore = TextEditingController(
    text: widget.match.homeScore?.toString() ?? '',
  );
  late final _awayScore = TextEditingController(
    text: widget.match.awayScore?.toString() ?? '',
  );
  late AdminMatchStatus _status = widget.match.status;
  bool _busy = false;
  String? _error;

  bool get _needsScores =>
      _status == AdminMatchStatus.live || _status == AdminMatchStatus.finished;

  @override
  void dispose() {
    _homeScore.dispose();
    _awayScore.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.repository.updateMatchResult(
        id: widget.match.id,
        status: _status,
        homeScore: _needsScores ? int.parse(_homeScore.text.trim()) : null,
        awayScore: _needsScores ? int.parse(_awayScore.text.trim()) : null,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) setState(() => _error = _safeError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _scoreError(String? value) {
    final score = int.tryParse(value?.trim() ?? '');
    return score == null || score < 0 || score > 99
        ? 'Introduce goles enteros entre 0 y 99.'
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final availableStatuses = switch (widget.match.status) {
      AdminMatchStatus.finished => [AdminMatchStatus.finished],
      AdminMatchStatus.cancelled => [AdminMatchStatus.cancelled],
      AdminMatchStatus.live => [
        AdminMatchStatus.live,
        AdminMatchStatus.finished,
        AdminMatchStatus.cancelled,
      ],
      _ => AdminMatchStatus.values,
    };
    return _AdminScaffold(
      title: 'Estado y resultado',
      children: [
        Text(
          '${widget.homeName} vs ${widget.awayName}',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<AdminMatchStatus>(
                initialValue: _status,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Estado'),
                items: [
                  for (final status in availableStatuses)
                    DropdownMenuItem(
                      value: status,
                      child: Text(_statusText(status)),
                    ),
                ],
                onChanged: _busy
                    ? null
                    : (status) {
                        if (status != null) setState(() => _status = status);
                      },
              ),
              if (_needsScores) ...[
                const SizedBox(height: 16),
                _FieldPair(
                  first: TextFormField(
                    controller: _homeScore,
                    enabled: !_busy,
                    keyboardType: TextInputType.number,
                    maxLength: 2,
                    decoration: InputDecoration(
                      labelText: 'Goles: ${widget.homeName}',
                    ),
                    validator: _scoreError,
                  ),
                  second: TextFormField(
                    controller: _awayScore,
                    enabled: !_busy,
                    keyboardType: TextInputType.number,
                    maxLength: 2,
                    decoration: InputDecoration(
                      labelText: 'Goles: ${widget.awayName}',
                    ),
                    validator: _scoreError,
                  ),
                ),
              ],
              if (_status == AdminMatchStatus.cancelled) ...[
                const SizedBox(height: 16),
                const Text('Un partido cancelado no puede reabrirse.'),
              ],
              if (_status == AdminMatchStatus.finished) ...[
                const SizedBox(height: 16),
                const Text(
                  'Después de finalizar podrás corregir el marcador, '
                  'pero no reabrir el partido.',
                ),
              ],
              _FormFeedback(busy: _busy, error: _error),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _busy ? null : _submit,
                child: const Text('Guardar cambios'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AdminScaffold extends StatelessWidget {
  const _AdminScaffold({
    required this.title,
    required this.children,
    this.actions,
  });

  final String title;
  final List<Widget> children;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF10A05B),
      brightness: Brightness.dark,
    );
    final theme = ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF10271D),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF10271D),
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Color(0xFF183729),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        ),
      ),
    );
    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 72 * MediaQuery.textScalerOf(context).scale(1),
          title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
          actions: actions,
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: children,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminAction {
  const _AdminAction({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;
}

class _ActionCards extends StatelessWidget {
  const _ActionCards({required this.actions});

  final List<_AdminAction> actions;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 640 ? 2 : 1;
      final width = (constraints.maxWidth - (columns - 1) * 16) / columns;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          for (final action in actions)
            SizedBox(
              width: width,
              child: _Panel(
                padding: EdgeInsets.zero,
                child: InkWell(
                  key: ValueKey('adminAction:${action.title}'),
                  borderRadius: BorderRadius.circular(20),
                  onTap: action.onTap,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          action.icon,
                          size: 32,
                          color: const Color(0xFF47CD80),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          action.title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(action.description),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.padding = const EdgeInsets.all(20)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    color: const Color(0xFF102F21),
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      side: const BorderSide(color: Color(0xFF286A43)),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Padding(padding: padding, child: child),
  );
}

class _TournamentPicker extends StatelessWidget {
  const _TournamentPicker({
    required this.tournaments,
    required this.selectedId,
    required this.onChanged,
    this.enabled = true,
    this.allowAll = false,
  });

  final List<AdminTournament> tournaments;
  final String? selectedId;
  final ValueChanged<String?> onChanged;
  final bool enabled;
  final bool allowAll;

  @override
  Widget build(BuildContext context) {
    final validId = tournaments.any((entry) => entry.id == selectedId)
        ? selectedId
        : null;
    return DropdownButtonFormField<String>(
      key: ValueKey(('tournament', validId, allowAll)),
      initialValue: validId ?? (allowAll ? '' : null),
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Torneo'),
      items: [
        if (allowAll)
          const DropdownMenuItem(value: '', child: Text('Todos los torneos')),
        for (final tournament in tournaments)
          DropdownMenuItem(
            value: tournament.id,
            child: Text(tournament.name, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: enabled ? (id) => onChanged(id == '' ? null : id) : null,
      validator: allowAll
          ? null
          : (id) => id == null ? 'Selecciona un torneo.' : null,
    );
  }
}

class _TeamPicker extends StatelessWidget {
  const _TeamPicker({
    required this.label,
    required this.teams,
    required this.selectedId,
    required this.onChanged,
    required this.enabled,
    this.validator,
  });

  final String label;
  final List<AdminTeam> teams;
  final String? selectedId;
  final ValueChanged<String?> onChanged;
  final bool enabled;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final validId = teams.any((team) => team.id == selectedId)
        ? selectedId
        : null;
    return DropdownButtonFormField<String>(
      key: ValueKey((label, validId)),
      initialValue: validId,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final team in teams)
          DropdownMenuItem(
            value: team.id,
            child: Text(team.name, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: enabled ? onChanged : null,
      validator:
          validator ?? (id) => id == null ? 'Selecciona un equipo.' : null,
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
    required this.validator,
    this.firstDate,
    this.lastDate,
  });

  final String label;
  final DateTime? value;
  final bool enabled;
  final ValueChanged<DateTime> onChanged;
  final String? Function(DateTime?) validator;
  final DateTime? firstDate;
  final DateTime? lastDate;

  @override
  Widget build(BuildContext context) => FormField<DateTime>(
    key: ValueKey((label, value)),
    initialValue: value,
    validator: validator,
    builder: (field) => InkWell(
      onTap: enabled
          ? () async {
              final first = firstDate ?? DateTime(2000);
              final last = lastDate ?? DateTime(2100, 12, 31);
              var initial = value ?? DateTime.now();
              if (initial.isBefore(first)) initial = first;
              if (initial.isAfter(last)) initial = last;
              final date = await showDatePicker(
                context: context,
                initialDate: initial,
                firstDate: first,
                lastDate: last,
                helpText: label,
                confirmText: 'Aceptar',
                cancelText: 'Cancelar',
              );
              if (date != null && context.mounted) {
                field.didChange(date);
                onChanged(date);
              }
            }
          : null,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          enabled: enabled,
          errorText: field.errorText,
          suffixIcon: const Icon(Icons.calendar_month_outlined),
        ),
        child: Text(value == null ? 'Seleccionar fecha' : _dateText(value!)),
      ),
    ),
  );
}

class _FieldPair extends StatelessWidget {
  const _FieldPair({required this.first, required this.second});

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth >= 600) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: first),
            const SizedBox(width: 16),
            Expanded(child: second),
          ],
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [first, const SizedBox(height: 16), second],
      );
    },
  );
}

class _FormFeedback extends StatelessWidget {
  const _FormFeedback({required this.busy, required this.error});

  final bool busy;
  final String? error;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (error != null) ...[
        const SizedBox(height: 16),
        _ErrorNotice(message: error!),
      ],
      if (busy) ...[const SizedBox(height: 16), const _Loading()],
    ],
  );
}

class _ErrorNotice extends StatelessWidget {
  const _ErrorNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Text(
      message,
      style: TextStyle(color: Theme.of(context).colorScheme.error),
    ),
  );
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(16),
    child: Center(
      child: CircularProgressIndicator(semanticsLabel: 'Cargando datos'),
    ),
  );
}

class _Empty extends StatelessWidget {
  const _Empty(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => _Panel(child: Text(message));
}

class _LimitNotice extends StatelessWidget {
  const _LimitNotice({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => count >= 200
      ? const Text(
          'Esta vista muestra hasta 200 registros. Selecciona un torneo para acotar la consulta.',
        )
      : const SizedBox.shrink();
}

Future<void> _open(BuildContext context, Widget page) async {
  await Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => page));
}

Future<void> _openAndNotify(
  BuildContext context,
  Widget page,
  String message,
) async {
  final saved = await Navigator.of(context)
      .push<bool>(MaterialPageRoute(builder: (_) => page));
  if (saved == true && context.mounted) _notify(context, message);
}

void _notify(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

String _safeError(Object error) => error is AdminFailure
    ? error.message
    : 'No se pudo completar la operación. Revisa tu conexión e intenta de nuevo.';

String? _lengthError(String? value, {required int min, required int max}) {
  final length = value?.trim().length ?? 0;
  return length < min || length > max
      ? 'Introduce entre $min y $max caracteres.'
      : null;
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');

String _dateText(DateTime date) {
  final local = date.toLocal();
  return '${_twoDigits(local.day)}/${_twoDigits(local.month)}/${local.year}';
}

String _dateTimeText(DateTime instant) {
  final local = instant.toLocal();
  return '${_dateText(local)}, ${_twoDigits(local.hour)}:${_twoDigits(local.minute)}';
}

DateTime _utcDate(DateTime date) =>
    DateTime(date.year, date.month, date.day).toUtc();

DateTime _localDate(DateTime date) {
  final local = date.toLocal();
  return DateTime(local.year, local.month, local.day);
}

String _statusText(AdminMatchStatus status) => switch (status) {
  AdminMatchStatus.scheduled => 'Programado',
  AdminMatchStatus.live => 'En curso',
  AdminMatchStatus.finished => 'Finalizado',
  AdminMatchStatus.cancelled => 'Cancelado',
};
