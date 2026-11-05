import 'dart:typed_data';
import 'package:url_launcher/url_launcher.dart';

Future<void> openDocument(Uint8List bytes, String mimeType, String fileName) async {
  throw UnsupportedError('Document opening not supported on this platform');
}

Future<void> openDocumentUrl(String url, String fileName) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    throw UnsupportedError('Could not launch URL: $url');
  }
}

Future<void> openDocumentBytes(Uint8List bytes, String mimeType, String fileName) async {
  throw UnsupportedError('Document bytes opening not supported on this platform');
}
