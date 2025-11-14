// Helper to create File on mobile, or return null on web
import 'package:flutter/foundation.dart' show kIsWeb;

// Conditional import - File only exists on non-web platforms
import 'dart:io' if (dart.library.html) 'file_helper_stub.dart' show File;

// Helper to create File on mobile, or return null on web
dynamic createFile(String path) {
  if (kIsWeb) {
    return null; // File not available on web
  } else {
    // File is available via dart:io on non-web platforms
    return File(path);
  }
}
