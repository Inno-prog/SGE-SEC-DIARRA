import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;
import '../core/constants/api_constants.dart';

/// Resolve a stored document URL to an absolute URL. Relative paths (uploaded
/// files like /uploads/documents/...) are prefixed with the server origin.
String _absoluteUrl(String url) {
  if (url.startsWith('http')) return url;
  final base = ApiConstants.baseUrl.replaceFirst('/api/v1', '');
  return '$base$url';
}

/// Opens a document URL in a new tab (for web) — browser renders it inline,
/// no download is triggered.
Future<void> openDocumentUrl(String url, String fileName) async {
  final anchor = web.HTMLAnchorElement()
    ..href = _absoluteUrl(url)
    ..target = '_blank'
    ..rel = 'noopener noreferrer';
  anchor.click();
}

/// Opens document bytes in a new tab for viewing (for web) — browser renders inline.
/// Uses a blob URL without the 'download' attribute so the browser displays it.
Future<void> openDocument(Uint8List bytes, String mimeType, String fileName) async {
  final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: mimeType.toJS.toDart));
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..target = '_blank'
    ..rel = 'noopener noreferrer';
  anchor.click();
  // Revoke after a short delay to allow the browser to load the document
  Future.delayed(const Duration(seconds: 5), () => web.URL.revokeObjectURL(url));
}

/// Downloads a document as a file (for web) — triggers the browser download.
Future<void> downloadDocumentBytes(Uint8List bytes, String mimeType, String fileName) async {
  final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: mimeType.toJS.toDart));
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = fileName;
  anchor.click();
  web.URL.revokeObjectURL(url);
}
