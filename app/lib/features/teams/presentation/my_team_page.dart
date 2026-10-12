import 'package:flutter/material.dart';

// Modelo simple para representar a un jugador
class Player {
  final String id;
  final String name;
  final String position;
  final int number;

  Player({
    required this.id,
    required this.name,
    required this.position,
    required this.number,
  });
}

class MyTeamPage extends StatefulWidget {
  const MyTeamPage({super.key});

  @override
  State<MyTeamPage> createState() => _MyTeamPageState();
}

class _MyTeamPageState extends State<MyTeamPage> {
  // Datos de ejemplo para la vista previa
  final String teamName = 'Halcones FC';
  final String captainName = 'Carlos Méndez';

  final List<Player> players = [
    Player(
      id: '1',
      name: 'Carlos Méndez',
      position: 'Mediocampista',
      number: 10,
    ),
    Player(id: '2', name: 'Andrés López', position: 'Delantero', number: 9),
    Player(id: '3', name: 'Luis Herrera', position: 'Extremo', number: 7),
    Player(id: '4', name: 'Diego Ramírez', position: 'Defensa', number: 3),
    Player(id: '5', name: 'Mateo Torres', position: 'Portero', number: 1),
  ];

  @override
  Widget build(BuildContext context) {
    // Colores del tema según el diseño
    const backgroundColor = Color(0xFF0F1A15);
    const cardBackgroundColor = Color(0xFF14291F);
    const primaryGreen = Color(0xFF10B981);
    const textWhite = Colors.white;
    const textGrey = Colors.grey;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textWhite),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Mi Equipo',
          style: TextStyle(color: textWhite, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          children: [
            // Targeta de datos del equipo
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: cardBackgroundColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primaryGreen.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: primaryGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.shield, color: textWhite, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          teamName,
                          style: const TextStyle(
                            color: textWhite,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Capitán: $captainName',
                          style: const TextStyle(color: textGrey, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Encabezado de la lista de jugadores y botón de Agregar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Jugadores (${players.length})',
                  style: const TextStyle(
                    color: textWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // Accion para agregar jugador
                  },
                  icon: const Icon(Icons.add, size: 18, color: textWhite),
                  label: const Text(
                    'Agregar jugador',
                    style: TextStyle(color: textWhite, fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Lista de jugadores
            Expanded(
              child: ListView.separated(
                itemCount: players.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final player = players[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: cardBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: primaryGreen,
                        child: Text(
                          '${player.number}',
                          style: const TextStyle(
                            color: textWhite,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        player.name,
                        style: const TextStyle(
                          color: textWhite,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        player.position,
                        style: const TextStyle(color: textGrey, fontSize: 12),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit_outlined, color: textGrey),
                        onPressed: () {
                          // Acción para editar jugador
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
