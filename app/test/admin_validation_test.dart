import 'package:flutter_test/flutter_test.dart';
import 'package:futschool/features/admin/domain/admin_models.dart';
import 'package:futschool/features/admin/domain/admin_validation.dart';

void main() {
  final invalid = throwsA(isA<AdminFailure>());

  void validateTournament({
    String name = 'Copa escolar',
    String description = '',
    DateTime? startDate,
    DateTime? endDate,
    int maxTeams = 16,
  }) => AdminValidation.tournament(
    name: name,
    description: description,
    startDate: startDate ?? DateTime(2026, 10, 15),
    endDate: endDate ?? DateTime(2026, 10, 30),
    maxTeams: maxTeams,
  );

  void validateMatch({
    String tournamentId = 'tournament-1',
    String homeTeamId = 'home-1',
    String awayTeamId = 'away-1',
    String courtId = 'cancha-1',
    DateTime? startsAt,
  }) => AdminValidation.match(
    tournamentId: tournamentId,
    homeTeamId: homeTeamId,
    awayTeamId: awayTeamId,
    courtId: courtId,
    startsAt: startsAt ?? DateTime.utc(2026, 10, 18, 16),
  );

  group('Torneos', () {
    test('acepta cupos extremos permitidos y torneo de un día', () {
      expect(() => validateTournament(maxTeams: 2), returnsNormally);
      expect(() => validateTournament(maxTeams: 64), returnsNormally);
      expect(
        () => validateTournament(endDate: DateTime(2026, 10, 15)),
        returnsNormally,
      );
    });

    test('rechaza nombres vacíos, cortos o excesivos', () {
      for (final name in ['', '   ', 'AB', List.filled(101, 'a').join()]) {
        expect(() => validateTournament(name: name), invalid);
      }
    });

    test('rechaza descripción excesiva y cupos fuera de límite', () {
      expect(
        () => validateTournament(description: List.filled(2001, 'a').join()),
        invalid,
      );
      for (final maxTeams in [-1, 0, 1, 65, 1000000]) {
        expect(() => validateTournament(maxTeams: maxTeams), invalid);
      }
    });

    test('rechaza fin anterior al inicio', () {
      expect(
        () => validateTournament(endDate: DateTime(2026, 10, 14)),
        invalid,
      );
    });

    test('fecha de calendario conserva medianoche local como instante UTC', () {
      final date = AdminValidation.calendarDate(DateTime(2026, 10, 15, 23, 59));
      expect(date, DateTime(2026, 10, 15).toUtc());
      expect(date.toLocal().day, 15);
      expect(date.toLocal().hour, 0);
      expect(date.isUtc, isTrue);
    });
  });

  group('Equipos e identificadores', () {
    test('acepta nombre válido y rechaza vacío o excesivo', () {
      expect(
        () => AdminValidation.team(tournamentId: 't1', name: ' Lobos '),
        returnsNormally,
      );
      for (final name in ['', ' ', 'A', List.filled(81, 'a').join()]) {
        expect(
          () => AdminValidation.team(tournamentId: 't1', name: name),
          invalid,
        );
      }
    });

    test('rechaza rutas y propiedades manipuladas como IDs', () {
      for (final id in [
        '',
        '../t1',
        't1/team1',
        'id with spaces',
        't1?role=admin',
      ]) {
        expect(() => AdminValidation.id(id), invalid);
      }
      expect(() => AdminValidation.id('AutoID_42-valid'), returnsNormally);
    });
  });

  group('Programación de partidos', () {
    test('acepta dos equipos distintos en hora entera', () {
      expect(validateMatch, returnsNormally);
    });

    test('rechaza un equipo que juega contra sí mismo', () {
      expect(() => validateMatch(awayTeamId: 'home-1'), invalid);
    });

    test('rechaza canchas vacías o con ruta', () {
      for (final court in ['', '../cancha', 'cancha/1', 'Cancha 1']) {
        expect(() => validateMatch(courtId: court), invalid);
      }
    });

    test('rechaza minutos, segundos o milisegundos intermedios', () {
      for (final start in [
        DateTime.utc(2026, 10, 18, 16, 30),
        DateTime.utc(2026, 10, 18, 16, 0, 1),
        DateTime.utc(2026, 10, 18, 16, 0, 0, 1),
      ]) {
        expect(() => validateMatch(startsAt: start), invalid);
      }
    });

    const tournamentId = 't1';
    final tournament = AdminTournament(
      id: tournamentId,
      name: 'Copa escolar',
      description: '',
      startDate: DateTime(2026, 10, 15).toUtc(),
      endDate: DateTime(2026, 10, 30).toUtc(),
      maxTeams: 16,
      teamCount: 2,
    );

    test('incluye primer y último horario completo del torneo', () {
      expect(
        () => AdminValidation.matchInTournament(
          DateTime(2026, 10, 15).toUtc(),
          tournament,
        ),
        returnsNormally,
      );
      expect(
        () => AdminValidation.matchInTournament(
          DateTime(2026, 10, 30, 23).toUtc(),
          tournament,
        ),
        returnsNormally,
      );
    });

    test(
      'rechaza horarios externos y partidos que terminan fuera del torneo',
      () {
        for (final start in [
          DateTime(2026, 10, 14, 23).toUtc(),
          DateTime(2026, 10, 31).toUtc(),
          DateTime(2026, 10, 30, 23, 30).toUtc(),
        ]) {
          expect(
            () => AdminValidation.matchInTournament(start, tournament),
            invalid,
          );
        }
      },
    );
  });

  group('Marcadores y estados', () {
    test('acepta extremos válidos en partido en curso y finalizado', () {
      for (final status in [AdminMatchStatus.live, AdminMatchStatus.finished]) {
        expect(
          () => AdminValidation.result(
            status: status,
            homeScore: 0,
            awayScore: 99,
          ),
          returnsNormally,
        );
      }
    });

    test('rechaza marcador incompleto, negativo o excesivo', () {
      for (final score in <int?>[null, -1, 100]) {
        expect(
          () => AdminValidation.result(
            status: AdminMatchStatus.finished,
            homeScore: score,
            awayScore: 0,
          ),
          invalid,
        );
        expect(
          () => AdminValidation.result(
            status: AdminMatchStatus.live,
            homeScore: 0,
            awayScore: score,
          ),
          invalid,
        );
      }
    });

    test('programado y cancelado requieren ausencia de marcador', () {
      for (final status in [
        AdminMatchStatus.scheduled,
        AdminMatchStatus.cancelled,
      ]) {
        expect(() => AdminValidation.result(status: status), returnsNormally);
        expect(
          () => AdminValidation.result(status: status, homeScore: 0),
          invalid,
        );
      }
    });

    test('permite captura histórica y corrección de resultado final', () {
      expect(
        () => AdminValidation.transition(
          AdminMatchStatus.scheduled,
          AdminMatchStatus.finished,
        ),
        returnsNormally,
      );
      expect(
        () => AdminValidation.transition(
          AdminMatchStatus.finished,
          AdminMatchStatus.finished,
        ),
        returnsNormally,
      );
    });

    test(
      'rechaza reabrir finalizado, cancelado y volver en curso a programado',
      () {
        for (final next in [
          AdminMatchStatus.scheduled,
          AdminMatchStatus.live,
        ]) {
          expect(
            () => AdminValidation.transition(AdminMatchStatus.finished, next),
            invalid,
          );
          expect(
            () => AdminValidation.transition(AdminMatchStatus.cancelled, next),
            invalid,
          );
        }
        expect(
          () => AdminValidation.transition(
            AdminMatchStatus.live,
            AdminMatchStatus.scheduled,
          ),
          invalid,
        );
      },
    );
  });
}
