export 'document_viewer_stub.dart'
    if (dart.library.html) 'document_viewer_web.dart'
    if (dart.library.io) 'document_viewer_mobile.dart';
