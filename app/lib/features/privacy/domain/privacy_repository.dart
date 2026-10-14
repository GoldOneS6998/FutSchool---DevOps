class PrivacyNotice {
  const PrivacyNotice({
    this.responsible = '',
    this.contact = '',
    this.text = '',
    this.version = '',
  });
  final String responsible;
  final String contact;
  final String text;
  final String version;
  bool get configured =>
      responsible.trim().isNotEmpty &&
      contact.trim().isNotEmpty &&
      text.trim().isNotEmpty &&
      version.trim().isNotEmpty;
}

abstract class PrivacyRepository {
  Future<PrivacyNotice> readNotice();
}
