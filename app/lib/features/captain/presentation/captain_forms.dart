import 'dart:convert';
import 'dart:ui' as ui;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'captain_design.dart';

typedef SaveCaptainTeam = Future<void> Function(
  String name,
  String description,
  String? logoBase64,
);

class CaptainTeamForm extends StatefulWidget {
  const CaptainTeamForm({
    super.key,
    required this.onSave,
    this.name = '',
    this.description = '',
    this.logoBase64,
    this.editing = false,
  });
  final SaveCaptainTeam onSave;
  final String name;
  final String description;
  final String? logoBase64;
  final bool editing;

  @override
  State<CaptainTeamForm> createState() => _CaptainTeamFormState();
}

class _CaptainTeamFormState extends State<CaptainTeamForm> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.name);
  late final _description = TextEditingController(text: widget.description);
  late String? _logo = widget.logoBase64;
  bool _saving = false;
  bool _choosingLogo = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _chooseLogo() async {
    if (_saving || _choosingLogo) return;
    setState(() => _choosingLogo = true);
    try {
      final file = await openFile(
        acceptedTypeGroups: const [
          XTypeGroup(
            label: 'Logo PNG o JPEG',
            extensions: ['png', 'jpg', 'jpeg'],
            mimeTypes: ['image/png', 'image/jpeg'],
            uniformTypeIdentifiers: ['public.png', 'public.jpeg'],
          ),
        ],
      );
      if (file == null) return;
      if (await file.length() > 50 * 1024) {
        throw const FormatException('El logo debe pesar como máximo 50 KB.');
      }
      final bytes = await file.readAsBytes();
      final logo = await validatedCaptainLogo(bytes);
      if (mounted) {
        setState(() {
          _logo = logo;
          _error = null;
        });
      }
    } on FormatException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No se pudo abrir el logo. Usa un PNG o JPEG.');
      }
    } finally {
      if (mounted) setState(() => _choosingLogo = false);
    }
  }

  Future<void> _save() async {
    if (_saving || _choosingLogo || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(_name.text.trim(), _description.text.trim(), _logo);
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'No se pudo guardar el equipo. Intenta de nuevo.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: CaptainScaffold(
      title: widget.editing ? 'Editar equipo' : 'Registrar equipo',
      children: [
        Form(
          key: _form,
          child: CaptainCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  key: const ValueKey('captain-team-name'),
                  controller: _name,
                  enabled: !_saving,
                  maxLength: 80,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del equipo',
                  ),
                  validator: captainNameValidator,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  key: const ValueKey('captain-team-description'),
                  controller: _description,
                  enabled: !_saving,
                  maxLength: 600,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                ),
                const SizedBox(height: 20),
                const Text('Logo', style: TextStyle(color: captainText)),
                const SizedBox(height: 8),
                if (_logo != null) ...[
                  Center(child: CaptainTeamLogo(logoBase64: _logo, size: 80)),
                  const SizedBox(height: 12),
                ],
                OutlinedButton.icon(
                  key: const ValueKey('captain-select-logo'),
                  onPressed: _saving || _choosingLogo ? null : _chooseLogo,
                  icon: const Icon(Icons.upload_outlined),
                  label: Text(
                    _choosingLogo ? 'Abriendo...' : 'Subir logo PNG o JPEG',
                  ),
                ),
                if (_logo != null)
                  TextButton(
                    onPressed: _saving
                        ? null
                        : () => setState(() => _logo = null),
                    child: const Text('Quitar logo'),
                  ),
                const Text(
                  'Opcional. Máximo 50 KB y 1024 × 1024 píxeles. '
                  'Elige un logo sin datos personales.',
                  style: TextStyle(color: captainMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (_error != null) CaptainFormError(_error!),
        CaptainSaveButton(
          key: const ValueKey('captain-save-team'),
          saving: _saving,
          onPressed: _choosingLogo ? null : _save,
          label: widget.editing ? 'Guardar equipo' : 'Registrar equipo',
        ),
      ],
    ),
  );
}

/// Bounds bytes and dimensions before pixel decoding; SVG/URLs are never
/// accepted as user logos, preventing script content and remote image tracking.
Future<String> validatedCaptainLogo(Uint8List bytes) async {
  if (bytes.length > 50 * 1024 || bytes.length < 8) {
    throw const FormatException('El logo debe pesar entre 8 bytes y 50 KB.');
  }
  const signature = [137, 80, 78, 71, 13, 10, 26, 10];
  final png = List.generate(
    8,
    (index) => bytes[index] == signature[index],
  ).every((match) => match);
  final jpeg = bytes[0] == 255 && bytes[1] == 216 && bytes[2] == 255;
  if (!png && !jpeg) {
    throw const FormatException('Selecciona un archivo PNG o JPEG válido.');
  }
  ui.ImmutableBuffer? buffer;
  ui.ImageDescriptor? descriptor;
  ui.Codec? codec;
  try {
    buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    descriptor = await ui.ImageDescriptor.encoded(buffer);
    if (descriptor.width < 1 ||
        descriptor.height < 1 ||
        descriptor.width > 1024 ||
        descriptor.height > 1024) {
      throw const FormatException(
        'El logo no puede superar 1024 × 1024 píxeles.',
      );
    }
    codec = await descriptor.instantiateCodec();
    final frame = await codec.getNextFrame();
    frame.image.dispose();
    return base64Encode(bytes);
  } on FormatException {
    rethrow;
  } catch (_) {
    throw const FormatException('La imagen está dañada o no es compatible.');
  } finally {
    codec?.dispose();
    descriptor?.dispose();
    buffer?.dispose();
  }
}

class CaptainTeamLogo extends StatefulWidget {
  const CaptainTeamLogo({super.key, this.logoBase64, this.size = 40});
  final String? logoBase64;
  final double size;

  @override
  State<CaptainTeamLogo> createState() => _CaptainTeamLogoState();
}

class _CaptainTeamLogoState extends State<CaptainTeamLogo> {
  late Future<Uint8List?> _bytes = _readLogo(widget.logoBase64);

  @override
  void didUpdateWidget(CaptainTeamLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.logoBase64 != widget.logoBase64) {
      _bytes = _readLogo(widget.logoBase64);
    }
  }

  Future<Uint8List?> _readLogo(String? logo) async {
    if (logo == null || logo.length > 70000) return null;
    try {
      final bytes = base64Decode(logo);
      // Firestore is an untrusted input too: recheck dimensions before the
      // renderer allocates pixels, even for images saved outside this UI.
      await validatedCaptainLogo(bytes);
      return bytes;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fallback = const CaptainAsset('shield');
    return Container(
      width: widget.size,
      height: widget.size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: captainGreen,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: FutureBuilder<Uint8List?>(
        future: _bytes,
        builder: (context, snapshot) => snapshot.data == null
            ? fallback
            : Image.memory(
                snapshot.data!,
                fit: BoxFit.contain,
                cacheWidth: 128,
                errorBuilder: (context, error, stackTrace) => fallback,
              ),
      ),
    );
  }
}

class CaptainPlayerForm extends StatefulWidget {
  const CaptainPlayerForm({
    super.key,
    required this.onSave,
    required this.positions,
    this.name = '',
    this.position,
    this.number,
    this.editing = false,
  });
  final Future<void> Function(String name, String position, int number) onSave;
  final List<String> positions;
  final String name;
  final String? position;
  final int? number;
  final bool editing;
  @override
  State<CaptainPlayerForm> createState() => _CaptainPlayerFormState();
}

class _CaptainPlayerFormState extends State<CaptainPlayerForm> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.name);
  late final _number = TextEditingController(
    text: widget.number?.toString() ?? '',
  );
  late String? _position = widget.position;
  bool _saving = false;
  String? _error;
  @override
  void dispose() {
    _name.dispose();
    _number.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(
        _name.text.trim(),
        _position!,
        int.parse(_number.text),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'No se pudo guardar el jugador. Intenta de nuevo.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: CaptainScaffold(
      title: widget.editing ? 'Editar jugador' : 'Agregar jugador',
      children: [
        Form(
          key: _form,
          child: CaptainCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  key: const ValueKey('captain-player-name'),
                  controller: _name,
                  enabled: !_saving,
                  maxLength: 80,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de jugador',
                  ),
                  validator: captainNameValidator,
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  key: const ValueKey('captain-player-position'),
                  initialValue: _position,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Posición'),
                  items: widget.positions
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _position = value),
                  validator: (value) =>
                      value == null ? 'Selecciona una posición.' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  key: const ValueKey('captain-player-number'),
                  controller: _number,
                  enabled: !_saving,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 2,
                  decoration: const InputDecoration(
                    labelText: 'Número de camiseta',
                  ),
                  validator: (value) {
                    final number = int.tryParse(value ?? '');
                    return number == null || number < 0 || number > 99
                        ? 'Usa un número entre 0 y 99.'
                        : null;
                  },
                ),
                const SizedBox(height: 12),
                const Text(
                  'Registra únicamente participantes adultos. No necesitamos '
                  'fecha de nacimiento, identificación ni datos médicos.',
                  style: TextStyle(color: captainMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (_error != null) CaptainFormError(_error!),
        CaptainSaveButton(
          key: const ValueKey('captain-save-player'),
          saving: _saving,
          onPressed: _save,
          label: 'Guardar jugador',
        ),
      ],
    ),
  );
}

String? captainNameValidator(String? value) {
  final name = (value ?? '').trim();
  if (name.length < 2 || name.length > 80) {
    return 'Escribe entre 2 y 80 caracteres.';
  }
  if (RegExp(r'[\x00-\x1F\x7F]').hasMatch(name)) {
    return 'Evita caracteres de control.';
  }
  return null;
}

class CaptainFormError extends StatelessWidget {
  const CaptainFormError(this.message, {super.key});
  final String message;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Semantics(
      liveRegion: true,
      child: Text(message, style: const TextStyle(color: Color(0xFFFFB4AB))),
    ),
  );
}

class CaptainSaveButton extends StatelessWidget {
  const CaptainSaveButton({
    super.key,
    required this.label,
    required this.saving,
    required this.onPressed,
  });
  final String label;
  final bool saving;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: saving ? null : onPressed,
    child: saving
        ? const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Guardando...'),
            ],
          )
        : Text(label),
  );
}
