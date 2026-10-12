enum TournamentStatus { all, upcoming, finished }

class Tournament {
  final String id;
  final String name;
  final String category;
  final String statusLabel;
  final TournamentStatus statusCategory;
  final String dates;
  final String? description;

  const Tournament({
    required this.id,
    required this.name,
    required this.category,
    required this.statusLabel,
    required this.statusCategory,
    required this.dates,
    this.description,
  });
}
