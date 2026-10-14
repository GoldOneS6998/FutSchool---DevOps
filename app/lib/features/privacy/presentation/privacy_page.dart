import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/widgets/auth_surface.dart';
import '../domain/privacy_repository.dart';

class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key, required this.repository});
  final PrivacyRepository repository;
  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  late Future<PrivacyNotice> _notice = widget.repository.readNotice();
  @override
  Widget build(BuildContext context) => AuthSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Privacidad',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        FutureBuilder<PrivacyNotice>(
          future: _notice,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Column(
                children: [
                  const Text('No se pudo consultar el aviso de privacidad.'),
                  TextButton(
                    onPressed: () => setState(() {
                      _notice = widget.repository.readNotice();
                    }),
                    child: const Text('Reintentar'),
                  ),
                ],
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final notice = snapshot.data!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!notice.configured)
                  const Text(
                    'La institución todavía no ha completado su aviso de privacidad. Consulta a la administración antes de registrar datos personales reales.',
                  ),
                if (notice.responsible.isNotEmpty)
                  Text('Responsable: ${notice.responsible}'),
                if (notice.version.isNotEmpty)
                  Text('Versión: ${notice.version}'),
                const SizedBox(height: 16),
                if (notice.text.isNotEmpty) SelectableText(notice.text),
                if (notice.contact.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  SelectableText(
                    'Contacto para acceso, rectificación, cancelación u oposición: ${notice.contact}',
                  ),
                  TextButton(
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: notice.contact),
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Contacto copiado.')),
                        );
                      }
                    },
                    child: const Text('Copiar contacto'),
                  ),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Volver'),
        ),
      ],
    ),
  );
}
