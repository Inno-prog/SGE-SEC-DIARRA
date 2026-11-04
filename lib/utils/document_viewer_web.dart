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

/// Legacy method for downloading and opening bytes (kept for compatibility)
Future<void> openDocumentBytes(Uint8List bytes, String mimeType, String fileName) async {
  // For web, we'll use the URL approach instead
  // This is kept for non-web platforms if needed
  throw UnimplementedError('Use openDocumentUrl on web');
}

/// Platform-aware openDocument - on web, use openDocumentUrl instead
Future<void> openDocument(Uint8List bytes, String mimeType, String fileName) async {
  throw UnsupportedError('On web, use openDocumentUrl instead');
}
