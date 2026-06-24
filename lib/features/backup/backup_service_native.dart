import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Saves zip bytes to the Downloads (or Documents) folder on native platforms.
/// Returns the full file path where the file was saved.
Future<String> saveZipToDownloads(List<int> zipBytes, String fileName) async {
  Directory? saveDir;

  // Try Downloads directory first (Windows / Android)
  try {
    saveDir = await getDownloadsDirectory();
  } catch (_) {}

  // Fallback to application documents directory
  saveDir ??= await getApplicationDocumentsDirectory();

  final filePath = '${saveDir.path}${Platform.pathSeparator}$fileName';
  await File(filePath).writeAsBytes(zipBytes);
  return filePath;
}
