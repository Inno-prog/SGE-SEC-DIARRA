import 'dart:io';
import 'dart:typed_data';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants/api_constants.dart';

String _absoluteUrl(String url) {
  if (url.startsWith('http')) return url;
  final base = ApiConstants.baseUrl.replaceFirst('/api/v1', '');
  return '$base$url';
}

Future<void> openDocument(Uint8List bytes, String mimeType, String fileName) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$fileName');
  await file.writeAsBytes(bytes);
  await OpenFile.open(file.path);
}

Future<void> openDocumentUrl(String url, String fileName) async {
  final uri = Uri.parse(_absoluteUrl(url));
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    throw UnsupportedError('Could not launch URL: $url');
  }
}

/// Saves the file to a temporary location and opens the system share sheet,
/// which on desktop offers a "Save As" action and on mobile lets the user
/// save/share the file.
Future<void> downloadDocumentBytes(Uint8List bytes, String mimeType, String fileName) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$fileName');
  await file.writeAsBytes(bytes);
  await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], subject: fileName));
}
