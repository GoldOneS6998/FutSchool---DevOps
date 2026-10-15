part of 'admin_page.dart';

class _AdminAsset extends StatelessWidget {
  const _AdminAsset(this.name, {required this.width, required this.height});
  final String name;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    'assets/figma/admin/$name.svg',
    width: width,
    height: height,
    excludeFromSemantics: true,
  );
}

class _AdminBackground extends StatelessWidget {
  const _AdminBackground({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => ClipRect(
    child: Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0B1F14), Color(0xFF0F2A1A), Color(0xFF0A1A10)],
              stops: [.08, .5672, .92],
            ),
          ),
        ),
        Positioned(
          left: -210,
          top: -240,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
            child: const _AdminAsset('pitch-glow', width: 660, height: 660),
          ),
        ),
        Positioned(
          left: 140,
          top: 480,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
            child: const _AdminAsset('stadium-glow', width: 640, height: 640),
          ),
        ),
        Positioned(
          left: -24,
          top: -70,
          child: IgnorePointer(
            child: Transform.rotate(
              angle: -.20944,
              child: Container(
                width: 220,
                height: 890,
                decoration: BoxDecoration(
                  color: const Color(0x05FFFFFF),
                  border: Border.all(color: const Color(0x14FFFFFF)),
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: -160,
          top: -24,
          child: IgnorePointer(
            child: Transform.rotate(
              angle: .20944,
              child: Container(
                width: 220,
                height: 890,
                decoration: BoxDecoration(
                  color: const Color(0x05FFFFFF),
                  border: Border.all(color: const Color(0x14FFFFFF)),
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    ),
  );
}

class _AdminNavigation extends StatelessWidget {
  const _AdminNavigation({
    required this.selectedIndex,
    required this.onSelected,
  });
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: Color(0xFF0F241B),
      border: Border(top: BorderSide(color: Color(0xFF16A34A))),
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    child: SafeArea(
      top: false,
      child: Align(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final minimumWidth =
                    320 * MediaQuery.textScalerOf(context).scale(1);
                final width = constraints.maxWidth < minimumWidth
                    ? minimumWidth
                    : constraints.maxWidth;
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: width,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final entry in const [
                          ('Inicio', Icons.home_outlined),
                          ('Panel', Icons.dashboard_outlined),
                          ('Crear torneo', Icons.emoji_events_outlined),
                          ('Partidos', Icons.calendar_month_outlined),
                          ('Crear partido', Icons.add_circle_outline),
                        ].indexed)
                          Expanded(
                            child: Semantics(
                              selected: selectedIndex == entry.$1,
                              child: TextButton(
                                key: ValueKey('adminNav:${entry.$1}'),
                                onPressed: () => onSelected(entry.$1),
                                style: TextButton.styleFrom(
                                  foregroundColor: selectedIndex == entry.$1
                                      ? const Color(0xFF22C55E)
                                      : const Color(0xFFB6C2BC),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                    vertical: 6,
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 40,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: selectedIndex == entry.$1
                                            ? const Color(0xFF16A34A)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Icon(
                                        entry.$2.$2,
                                        size: 24,
                                        color: selectedIndex == entry.$1
                                            ? Colors.white
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      entry.$2.$1,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 12),
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
              },
            ),
          ),
        ),
      ),
    ),
  );
}

class _ManagementRows extends StatelessWidget {
  const _ManagementRows({required this.actions});
  final List<_AdminAction> actions;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final action in actions) ...[
        _Panel(
          padding: EdgeInsets.zero,
          child: InkWell(
            key: ValueKey('adminAction:${action.title}'),
            onTap: action.onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0x2616A34A),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: action.assetName == null
                        ? Icon(
                            action.icon,
                            color: const Color(0xFF22C55E),
                            size: 18,
                          )
                        : _AdminAsset(action.assetName!, width: 18, height: 18),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          action.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          action.description,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const _AdminAsset('chevron-right', width: 16, height: 16),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    ],
  );
}

class _AdminMatchSummary extends StatelessWidget {
  const _AdminMatchSummary({
    required this.match,
    required this.homeName,
    required this.awayName,
  });
  final AdminMatch match;
  final String homeName;
  final String awayName;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact =
          constraints.maxWidth >= 280 &&
          MediaQuery.textScalerOf(context).scale(1) < 1.5;
      final color = match.status == AdminMatchStatus.live
          ? const Color(0xFFEF4444)
          : match.status == AdminMatchStatus.finished ||
                match.status == AdminMatchStatus.cancelled
          ? const Color(0xFF9CA3AF)
          : const Color(0xFF22C55E);
      final badge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          _statusText(match.status),
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
      final date = Row(
        children: [
          const _AdminAsset('match-calendar', width: 12, height: 12),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              _dateTimeText(match.startsAt),
              style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
            ),
          ),
        ],
      );
      Widget team(String name, {bool right = false}) => Row(
        children: [
          if (!right) ...[
            const _AdminAsset('match-shield', width: 32, height: 32),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              name,
              textAlign: right ? TextAlign.right : TextAlign.left,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          if (right) ...[
            const SizedBox(width: 8),
            const _AdminAsset('match-shield', width: 32, height: 32),
          ],
        ],
      );
      final score = Text(
        match.homeScore != null && match.awayScore != null
            ? '${match.homeScore} - ${match.awayScore}'
            : 'vs',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 18,
          color: match.status == AdminMatchStatus.live
              ? const Color(0xFF22C55E)
              : Colors.white,
        ),
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (compact)
            Row(
              children: [
                Expanded(child: date),
                const SizedBox(width: 8),
                badge,
              ],
            )
          else ...[
            date,
            const SizedBox(height: 8),
            Align(alignment: Alignment.centerLeft, child: badge),
          ],
          const SizedBox(height: 16),
          if (compact)
            Row(
              children: [
                Expanded(child: team(homeName)),
                const SizedBox(width: 8),
                score,
                const SizedBox(width: 8),
                Expanded(child: team(awayName, right: true)),
              ],
            )
          else ...[
            team(homeName),
            const SizedBox(height: 8),
            score,
            const SizedBox(height: 8),
            team(awayName),
          ],
          const SizedBox(height: 12),
          const Divider(color: Color(0x1AFFFFFF)),
          const SizedBox(height: 8),
          Row(
            children: [
              const _AdminAsset('map-pin', width: 12, height: 12),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Cancha: ${match.courtId}',
                  style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
}

class _PendingRegistrationsBanner extends StatefulWidget {
  const _PendingRegistrationsBanner({required this.repository});
  final AdminManagementRepository repository;
  @override
  State<_PendingRegistrationsBanner> createState() =>
      _PendingRegistrationsBannerState();
}

class _PendingRegistrationsBannerState
    extends State<_PendingRegistrationsBanner> {
  late final _stream = widget.repository.watchRegistrations();
  @override
  Widget build(BuildContext context) => StreamBuilder(
    stream: _stream,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return _ErrorNotice(message: _safeError(snapshot.error!));
      }
      if (!snapshot.hasData) return const _Loading();
      final pending = snapshot.data!
          .where((item) => item.status == RegistrationStatus.pending)
          .length;
      return _Panel(
        child: Row(
          children: [
            const _AdminAsset('info', width: 20, height: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Inscripciones activas',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '$pending solicitudes esperando confirmación.',
                    key: const Key('pendingRegistrationsCount'),
                  ),
                  if (snapshot.data!.length >= 200)
                    const Text(
                      'Conteo de hasta 200 solicitudes cargadas; pueden existir más.',
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _AdminUsersPage extends StatefulWidget {
  const _AdminUsersPage({required this.repository});
  final AdminManagementRepository repository;
  @override
  State<_AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<_AdminUsersPage> {
  late final _stream = widget.repository.watchCaptains();
  String _search = '';
  String? _busyId;
  String? _error;

  Future<void> _toggle(CaptainProfile user) async {
    final disabled = !user.disabled;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(disabled ? 'Suspender acceso' : 'Restablecer acceso'),
        content: Text(
          disabled
              ? 'El capitán ${user.displayName} dejará de acceder a sus datos en FutSchool. Sus datos y su cuenta de Firebase se conservan.'
              : 'El capitán ${user.displayName} volverá a acceder a FutSchool.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || _busyId != null) return;
    setState(() {
      _busyId = user.id;
      _error = null;
    });
    try {
      await widget.repository.setCaptainDisabled(
        uid: user.id,
        disabled: disabled,
      );
      if (mounted) {
        _notify(
          context,
          disabled ? 'Acceso suspendido.' : 'Acceso restablecido.',
        );
      }
    } catch (error) {
      if (mounted) setState(() => _error = _safeError(error));
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) => _AdminScaffold(
    title: 'Gestionar usuarios',
    children: [
      TextField(
        key: const Key('adminUsersSearch'),
        decoration: const InputDecoration(
          labelText: 'Buscar por nombre o correo',
          prefixIcon: Icon(Icons.search),
        ),
        onChanged: (value) =>
            setState(() => _search = value.trim().toLowerCase()),
      ),
      const SizedBox(height: 16),
      const Text(
        'Se muestran los capitanes que han entrado a FutSchool. La suspensión afecta el acceso a la aplicación.',
      ),
      _FormFeedback(busy: _busyId != null, error: _error),
      const SizedBox(height: 16),
      StreamBuilder(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _ErrorNotice(message: _safeError(snapshot.error!));
          }
          if (!snapshot.hasData) return const _Loading();
          final profiles = snapshot.data!;
          final filtered = profiles.where(
            (user) => '${user.displayName} ${user.email}'
                .toLowerCase()
                .contains(_search),
          );
          if (filtered.isEmpty) {
            return const _Empty(
              'No hay capitanes que coincidan con tu búsqueda.',
            );
          }
          return Column(
            children: [
              for (final user in filtered) ...[
                _Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        user.displayName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(user.email),
                      Text(
                        user.disabled ? 'Acceso suspendido' : 'Acceso activo',
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        key: ValueKey('captainAccess:${user.id}'),
                        onPressed: _busyId == null ? () => _toggle(user) : null,
                        child: Text(
                          user.disabled
                              ? 'Restablecer acceso'
                              : 'Suspender acceso',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              _LimitNotice(count: profiles.length),
            ],
          );
        },
      ),
    ],
  );
}

class _AdminTeamsManagementPage extends StatefulWidget {
  const _AdminTeamsManagementPage({
    required this.repository,
    required this.adminRepository,
  });
  final AdminManagementRepository repository;
  final AdminRepository adminRepository;
  @override
  State<_AdminTeamsManagementPage> createState() =>
      _AdminTeamsManagementPageState();
}

class _AdminTeamsManagementPageState extends State<_AdminTeamsManagementPage> {
  late final _stream = widget.repository.watchCaptainTeams();
  @override
  Widget build(BuildContext context) => _AdminScaffold(
    title: 'Gestionar equipos',
    children: [
      OutlinedButton.icon(
        onPressed: () =>
            _open(context, _TeamsPage(repository: widget.adminRepository)),
        icon: const Icon(Icons.emoji_events_outlined),
        label: const Text('Equipos inscritos en torneos'),
      ),
      const SizedBox(height: 16),
      StreamBuilder(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _ErrorNotice(message: _safeError(snapshot.error!));
          }
          if (!snapshot.hasData) return const _Loading();
          final teams = snapshot.data!;
          if (teams.isEmpty) {
            return const _Empty(
              'Los equipos aparecerán cuando sus capitanes los registren.',
            );
          }
          return Column(
            children: [
              for (final team in teams) ...[
                _Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        team.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (team.description.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(team.description),
                      ],
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        key: ValueKey('adminRoster:${team.id}'),
                        onPressed: () => _open(
                          context,
                          _AdminRosterPage(
                            repository: widget.repository,
                            team: team,
                          ),
                        ),
                        icon: const Icon(Icons.groups_outlined),
                        label: const Text('Ver integrantes'),
                      ),
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
}

class _AdminRosterPage extends StatefulWidget {
  const _AdminRosterPage({required this.repository, required this.team});
  final AdminManagementRepository repository;
  final CaptainTeam team;
  @override
  State<_AdminRosterPage> createState() => _AdminRosterPageState();
}

class _AdminRosterPageState extends State<_AdminRosterPage> {
  late final _stream = widget.repository.watchPlayers(widget.team.id);
  @override
  Widget build(BuildContext context) => _AdminScaffold(
    title: widget.team.name,
    children: [
      const Text(
        'Integrantes del equipo',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 16),
      StreamBuilder(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _ErrorNotice(message: _safeError(snapshot.error!));
          }
          if (!snapshot.hasData) return const _Loading();
          final players = snapshot.data!;
          if (players.isEmpty) {
            return const _Empty('Este equipo todavía no tiene integrantes.');
          }
          return Column(
            children: [
              for (final player in players) ...[
                _Panel(
                  child: Row(
                    children: [
                      CircleAvatar(child: Text('${player.jerseyNumber}')),
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
                            Text(switch (player.position) {
                              PlayerPosition.goalkeeper => 'Portero',
                              PlayerPosition.defender => 'Defensa',
                              PlayerPosition.midfielder => 'Mediocampista',
                              PlayerPosition.forward => 'Delantero',
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
    ],
  );
}

class _TournamentManagementPage extends StatefulWidget {
  const _TournamentManagementPage({
    required this.tournament,
    required this.repository,
  });
  final AdminTournament tournament;
  final AdminManagementRepository repository;
  @override
  State<_TournamentManagementPage> createState() =>
      _TournamentManagementPageState();
}

class _TournamentManagementPageState extends State<_TournamentManagementPage> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.tournament.name);
  late final _description = TextEditingController(
    text: widget.tournament.description,
  );
  late final _capacity = TextEditingController(
    text: '${widget.tournament.maxTeams}',
  );
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _capacity.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.repository.updateTournamentMetadata(
        id: widget.tournament.id,
        name: _name.text.trim(),
        description: _description.text.trim(),
        maxTeams: int.parse(_capacity.text),
      );
      if (mounted) _notify(context, 'Torneo actualizado.');
    } catch (error) {
      if (mounted) setState(() => _error = _safeError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => _AdminScaffold(
    title: 'Administrar torneo',
    children: [
      Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              key: const Key('editTournamentName'),
              controller: _name,
              enabled: !_busy,
              maxLength: 100,
              decoration: const InputDecoration(labelText: 'Nombre del torneo'),
              validator: (value) => _lengthError(value, min: 3, max: 100),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              enabled: !_busy,
              maxLength: 1000,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Descripción y reglamento',
              ),
              validator: (value) => _lengthError(value, min: 0, max: 1000),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('editTournamentCapacity'),
              controller: _capacity,
              enabled: !_busy,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Cupo de equipos'),
              validator: (value) {
                final count = int.tryParse(value?.trim() ?? '');
                return count == null ||
                        count < 2 ||
                        count > 64 ||
                        count < widget.tournament.teamCount
                    ? 'El cupo debe estar entre ${widget.tournament.teamCount > 2 ? widget.tournament.teamCount : 2} y 64 equipos.'
                    : null;
              },
            ),
            const SizedBox(height: 12),
            Text(
              'Fechas: ${_dateText(widget.tournament.startDate)} – ${_dateText(widget.tournament.endDate)}',
            ),
            const Text(
              'Las fechas se conservan para mantener el calendario de los partidos.',
            ),
            _FormFeedback(busy: _busy, error: _error),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('editTournamentSubmit'),
              onPressed: _busy ? null : _save,
              child: const Text('Guardar torneo'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      const Text(
        'Inscripciones al torneo',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 12),
      _RegistrationReviewList(
        repository: widget.repository,
        tournamentId: widget.tournament.id,
      ),
    ],
  );
}

class _RegistrationReviewList extends StatefulWidget {
  const _RegistrationReviewList({
    required this.repository,
    required this.tournamentId,
  });
  final AdminManagementRepository repository;
  final String tournamentId;
  @override
  State<_RegistrationReviewList> createState() =>
      _RegistrationReviewListState();
}

class _RegistrationReviewListState extends State<_RegistrationReviewList> {
  late final _stream = widget.repository.watchRegistrations();
  final _draftNotes = <String, String>{};
  String? _busyId;
  String? _error;

  Future<void> _review(
    TournamentRegistration registration,
    bool approve,
  ) async {
    if (_busyId != null) return;
    final comment = await showDialog<String>(
      context: context,
      builder: (context) => _RegistrationDecisionDialog(
        approve: approve,
        teamName: registration.teamName,
        initialNote: _draftNotes[registration.id] ?? '',
      ),
    );
    if (!mounted || comment == null || _busyId != null) return;
    _draftNotes[registration.id] = comment;
    setState(() {
      _busyId = registration.id;
      _error = null;
    });
    try {
      await widget.repository.reviewRegistration(
        id: registration.id,
        approve: approve,
        note: comment,
      );
      _draftNotes.remove(registration.id);
      if (mounted) {
        _notify(
          context,
          approve ? 'Inscripción aprobada.' : 'Inscripción rechazada.',
        );
      }
    } catch (error) {
      if (mounted) setState(() => _error = _safeError(error));
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _FormFeedback(busy: _busyId != null, error: _error),
      StreamBuilder(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _ErrorNotice(message: _safeError(snapshot.error!));
          }
          if (!snapshot.hasData) return const _Loading();
          final registrations = snapshot.data!
              .where((entry) => entry.tournamentId == widget.tournamentId)
              .toList();
          if (registrations.isEmpty) {
            return const _Empty('Todavía no hay solicitudes de inscripción.');
          }
          return Column(
            children: [
              for (final registration in registrations) ...[
                _Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        registration.teamName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(switch (registration.status) {
                        RegistrationStatus.pending => 'Pendiente de revisión',
                        RegistrationStatus.approved => 'Aprobada',
                        RegistrationStatus.rejected => 'Rechazada',
                      }),
                      if (registration.reviewNote.isNotEmpty)
                        Text(registration.reviewNote),
                      if (registration.status ==
                          RegistrationStatus.pending) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilledButton(
                              key: ValueKey(
                                'approveRegistration:${registration.id}',
                              ),
                              onPressed: _busyId == null
                                  ? () => _review(registration, true)
                                  : null,
                              child: const Text('Aprobar'),
                            ),
                            OutlinedButton(
                              key: ValueKey(
                                'rejectRegistration:${registration.id}',
                              ),
                              onPressed: _busyId == null
                                  ? () => _review(registration, false)
                                  : null,
                              child: const Text('Rechazar'),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              _LimitNotice(count: snapshot.data!.length),
            ],
          );
        },
      ),
    ],
  );
}

class _RegistrationDecisionDialog extends StatefulWidget {
  const _RegistrationDecisionDialog({
    required this.approve,
    required this.teamName,
    required this.initialNote,
  });
  final bool approve;
  final String teamName;
  final String initialNote;
  @override
  State<_RegistrationDecisionDialog> createState() =>
      _RegistrationDecisionDialogState();
}

class _RegistrationDecisionDialogState
    extends State<_RegistrationDecisionDialog> {
  late final _note = TextEditingController(text: widget.initialNote);
  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.approve ? 'Aprobar inscripción' : 'Rechazar inscripción',
    ),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.approve
                ? '${widget.teamName} ocupará un lugar en este torneo.'
                : 'El capitán podrá consultar el motivo del rechazo.',
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('registrationReviewNote'),
            controller: _note,
            maxLength: 500,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Comentario para el capitán (opcional)',
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, _note.text.trim()),
        child: const Text('Confirmar'),
      ),
    ],
  );
}

class _AdminConfigurationPage extends StatefulWidget {
  const _AdminConfigurationPage({required this.repository});
  final AdminManagementRepository repository;
  @override
  State<_AdminConfigurationPage> createState() =>
      _AdminConfigurationPageState();
}

class _AdminConfigurationPageState extends State<_AdminConfigurationPage> {
  late final _stream = widget.repository.watchSettings();
  @override
  Widget build(BuildContext context) => _AdminScaffold(
    title: 'Configuración general',
    children: [
      StreamBuilder(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _ErrorNotice(message: _safeError(snapshot.error!));
          }
          if (!snapshot.hasData) return const _Loading();
          return _SettingsEditor(
            repository: widget.repository,
            settings: snapshot.data!,
          );
        },
      ),
    ],
  );
}

class _SettingsEditor extends StatefulWidget {
  const _SettingsEditor({required this.repository, required this.settings});
  final AdminManagementRepository repository;
  final AppSettings settings;
  @override
  State<_SettingsEditor> createState() => _SettingsEditorState();
}

class _SettingsEditorState extends State<_SettingsEditor> {
  final _formKey = GlobalKey<FormState>();
  late bool _registrationEnabled = widget.settings.registrationEnabled;
  late final _announcement = TextEditingController(
    text: widget.settings.announcement,
  );
  late final _responsible = TextEditingController(
    text: widget.settings.privacyResponsible,
  );
  late final _contact = TextEditingController(
    text: widget.settings.privacyContact.isEmpty
        ? 'ernex9897@gmail.com'
        : widget.settings.privacyContact,
  );
  late final _notice = TextEditingController(
    text: widget.settings.privacyNotice,
  );
  late final _version = TextEditingController(
    text: widget.settings.privacyVersion,
  );
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final controller in [
      _announcement,
      _responsible,
      _contact,
      _notice,
      _version,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.repository.saveSettings(
        AppSettings(
          registrationEnabled: _registrationEnabled,
          announcement: _announcement.text.trim(),
          privacyResponsible: _responsible.text.trim(),
          privacyContact: _contact.text.trim(),
          privacyNotice: _notice.text.trim(),
          privacyVersion: _version.text.trim(),
        ),
      );
      if (mounted) _notify(context, 'Configuración guardada.');
    } catch (error) {
      if (mounted) setState(() => _error = _safeError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _formKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Panel(
          child: SwitchListTile.adaptive(
            key: const Key('registrationEnabled'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Recibir inscripciones'),
            subtitle: const Text(
              'Permite que los capitanes soliciten un lugar en torneos.',
            ),
            value: _registrationEnabled,
            onChanged: _busy
                ? null
                : (value) => setState(() => _registrationEnabled = value),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          key: const Key('settingsAnnouncement'),
          controller: _announcement,
          enabled: !_busy,
          maxLength: 1000,
          minLines: 2,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Aviso para los capitanes',
          ),
          validator: (value) => _lengthError(value, min: 0, max: 1000),
        ),
        const SizedBox(height: 16),
        const Text(
          'Aviso de privacidad',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        const SizedBox(height: 8),
        const Text(
          'Completa estos datos con la información aprobada por la universidad. El aviso se muestra a los capitanes; publicar un texto no acredita cumplimiento legal.',
        ),
        const SizedBox(height: 16),
        TextFormField(
          key: const Key('privacyResponsible'),
          controller: _responsible,
          enabled: !_busy,
          maxLength: 200,
          decoration: const InputDecoration(
            labelText: 'Institución responsable del tratamiento',
          ),
          validator: (value) => _lengthError(value, min: 0, max: 200),
        ),
        const SizedBox(height: 12),
        TextFormField(
          key: const Key('privacyContact'),
          controller: _contact,
          enabled: !_busy,
          maxLength: 200,
          decoration: const InputDecoration(
            labelText: 'Contacto para derechos ARCO',
          ),
          validator: (value) => _lengthError(value, min: 0, max: 200),
        ),
        const SizedBox(height: 12),
        TextFormField(
          key: const Key('privacyVersion'),
          controller: _version,
          enabled: !_busy,
          maxLength: 40,
          decoration: const InputDecoration(
            labelText: 'Versión o fecha del aviso',
          ),
          validator: (value) => _lengthError(value, min: 0, max: 40),
        ),
        const SizedBox(height: 12),
        TextFormField(
          key: const Key('privacyNotice'),
          controller: _notice,
          enabled: !_busy,
          maxLength: 10000,
          minLines: 5,
          maxLines: 15,
          decoration: const InputDecoration(
            labelText: 'Texto del aviso de privacidad',
          ),
          validator: (value) => _lengthError(value, min: 0, max: 10000),
        ),
        _FormFeedback(busy: _busy, error: _error),
        const SizedBox(height: 20),
        FilledButton(
          key: const Key('saveSettings'),
          onPressed: _busy ? null : _save,
          child: const Text('Guardar configuración'),
        ),
      ],
    ),
  );
}
