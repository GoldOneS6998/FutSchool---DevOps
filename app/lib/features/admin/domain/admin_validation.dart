import 'admin_models.dart';

/// Input checks for usability. Firestore rules enforce them independently.
abstract final class AdminValidation {
  static const streamLimit = 200;
  static const matchDuration = Duration(hours: 1);

  static DateTime calendarDate(DateTime value) =>
      DateTime(value.year, value.month, value.day).toUtc();

  static void id(String value) {
    if (!RegExp(r'^[A-Za-z0-9_-]{1,128}$').hasMatch(value)) {
      throw const AdminFailure('El identificador no es válido.');
    }
  }

  static void tournament({
    required String name,
    required String description,
    required DateTime startDate,
    required DateTime endDate,
    required int maxTeams,
  }) {
    if (name.trim().length < 3 || name.trim().length > 100) {
      throw const AdminFailure('El nombre debe tener de 3 a 100 caracteres.');
    }
    if (description.trim().length > 2000) {
      throw const AdminFailure('La descripción admite hasta 2000 caracteres.');
    }
    if (calendarDate(endDate).isBefore(calendarDate(startDate))) {
      throw const AdminFailure(
        'La fecha de fin debe ser igual o posterior al inicio.',
      );
    }
    if (maxTeams < 2 || maxTeams > 64) {
      throw const AdminFailure('El cupo debe ser de 2 a 64 equipos.');
    }
  }

  static void team({required String tournamentId, required String name}) {
    id(tournamentId);
    if (name.trim().length < 2 || name.trim().length > 80) {
      throw const AdminFailure(
        'El nombre del equipo debe tener de 2 a 80 caracteres.',
      );
    }
  }

  static void match({
    required String tournamentId,
    required String homeTeamId,
    required String awayTeamId,
    required String courtId,
    required DateTime startsAt,
  }) {
    id(tournamentId);
    id(homeTeamId);
    id(awayTeamId);
    if (homeTeamId == awayTeamId) {
      throw const AdminFailure('Selecciona dos equipos distintos.');
    }
    if (!RegExp(r'^[a-z0-9-]{1,40}$').hasMatch(courtId)) {
      throw const AdminFailure(
        'La cancha admite letras minúsculas, números y guiones.',
      );
    }
    if (startsAt.toUtc().millisecondsSinceEpoch % 3600000 != 0) {
      throw const AdminFailure(
        'Programa el partido al inicio de una hora exacta.',
      );
    }
  }

  static void matchInTournament(DateTime startsAt, AdminTournament tournament) {
    final start = startsAt.toUtc();
    final endExclusive = tournament.endDate.add(const Duration(days: 1));
    if (start.isBefore(tournament.startDate) ||
        start.add(matchDuration).isAfter(endExclusive)) {
      throw const AdminFailure(
        'El partido debe estar dentro de las fechas del torneo.',
      );
    }
  }

  static void result({
    required AdminMatchStatus status,
    int? homeScore,
    int? awayScore,
  }) {
    final withResult =
        status == AdminMatchStatus.live || status == AdminMatchStatus.finished;
    if (withResult) {
      if (homeScore == null ||
          awayScore == null ||
          homeScore < 0 ||
          awayScore < 0 ||
          homeScore > 99 ||
          awayScore > 99) {
        throw const AdminFailure('Introduce ambos marcadores entre 0 y 99.');
      }
    } else if (homeScore != null || awayScore != null) {
      throw const AdminFailure(
        'Los partidos programados o cancelados no tienen marcador.',
      );
    }
  }

  static void transition(AdminMatchStatus previous, AdminMatchStatus next) {
    if ((previous == AdminMatchStatus.finished && next != previous) ||
        (previous == AdminMatchStatus.cancelled && next != previous) ||
        (previous == AdminMatchStatus.live &&
            next == AdminMatchStatus.scheduled)) {
      throw const AdminFailure(
        'No se puede regresar este partido a un estado anterior.',
      );
    }
  }
}
