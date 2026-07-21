import 'dart:html' as html;
import 'dart:typed_data';

Future<void> openDocument(Uint8List bytes, String mimeType, String fileName) async {
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.window.open(url, '_blank');
}
