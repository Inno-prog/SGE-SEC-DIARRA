import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

/// Opens a document URL in a new tab (for web)
Future<void> openDocumentUrl(String url, String fileName) async {
  // Ensure URL is absolute
  final absoluteUrl = url.startsWith('http')
      ? url
      : 'http://localhost:3000$url'; // Adjust base URL as needed

  final anchor = web.HTMLAnchorElement()
    ..href = absoluteUrl
    ..target = '_blank'
    ..rel = 'noopener noreferrer';
  anchor.click();
}

/// Downloads and opens document bytes (for web)
Future<void> openDocumentBytes(Uint8List bytes, String mimeType, String fileName) async {
  final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: mimeType.toJS.toDart));
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = fileName;
  anchor.click();
  web.URL.revokeObjectURL(url);
}

/// Platform-aware openDocument - on web, uses openDocumentBytes
Future<void> openDocument(Uint8List bytes, String mimeType, String fileName) async {
  await openDocumentBytes(bytes, mimeType, fileName);
}
