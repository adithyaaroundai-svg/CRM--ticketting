/// Web stub — native file saving is not used on web.
/// The actual web download is handled directly in backup_service.dart via dart:html.
Future<String> saveZipToDownloads(List<int> zipBytes, String fileName) async {
  throw UnsupportedError('saveZipToDownloads is not available on web.');
}
