import 'dart:convert';

import 'captain_models.dart';

class CaptainValidation {
  static const streamLimit = 200;
  static const maxLogoBytes = 50 * 1024;
  static void id(String value) {
    if (!RegExp(r'^[a-zA-Z0-9_-]{1,128}$').hasMatch(value)) {
      throw const CaptainFailure('El identificador no es válido.');
    }
  }

  static void name(String value, {int min = 2, int max = 80}) {
    final name = value.trim();
    if (name.length < min ||
        name.length > max ||
        name.contains('\n') ||
        name.contains('\r')) {
      throw CaptainFailure('Escribe un nombre de $min a $max caracteres.');
    }
  }

  static void team({
    required String name,
    required String description,
    String? logoBase64,
  }) {
    CaptainValidation.name(name);
    if (description.trim().length > 1000) {
      throw const CaptainFailure(
        'La descripción permite hasta 1000 caracteres.',
      );
    }
    if (logoBase64 == null) return;
    if (logoBase64.length > 68268) {
      throw const CaptainFailure(
        'El escudo debe ser PNG o JPEG de máximo 50 KB.',
      );
    }
    try {
      final bytes = base64Decode(logoBase64);
      final png =
          bytes.length >= 8 &&
          bytes[0] == 137 &&
          bytes[1] == 80 &&
          bytes[2] == 78 &&
          bytes[3] == 71 &&
          bytes[4] == 13 &&
          bytes[5] == 10 &&
          bytes[6] == 26 &&
          bytes[7] == 10;
      final jpeg =
          bytes.length >= 3 &&
          bytes[0] == 255 &&
          bytes[1] == 216 &&
          bytes[2] == 255;
      if (bytes.length > maxLogoBytes ||
          (!png && !jpeg) ||
          base64Encode(bytes) != logoBase64) {
        throw const FormatException();
      }
    } catch (_) {
      throw const CaptainFailure(
        'El escudo debe ser PNG o JPEG de máximo 50 KB.',
      );
    }
  }

  static void player({required String name, required int jerseyNumber}) {
    CaptainValidation.name(name, max: 100);
    if (jerseyNumber < 0 || jerseyNumber > 99) {
      throw const CaptainFailure(
        'El número de camiseta debe estar entre 0 y 99.',
      );
    }
  }

  static void settings(AppSettings value) {
    if (value.announcement.trim().length > 1000 ||
        value.privacyResponsible.trim().length > 200 ||
        value.privacyContact.trim().length > 200 ||
        value.privacyNotice.trim().length > 10000 ||
        value.privacyVersion.trim().length > 40) {
      throw const CaptainFailure(
        'Alguno de los textos de configuración supera el límite permitido.',
      );
    }
    if (value.privacyContact.contains('\n') ||
        value.privacyContact.contains('\r')) {
      throw const CaptainFailure(
        'El contacto debe escribirse en una sola línea.',
      );
    }
  }
}
