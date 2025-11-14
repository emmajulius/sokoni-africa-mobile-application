import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Service for compressing and resizing images before upload
class ImageCompressionService {
  static final ImageCompressionService _instance = ImageCompressionService._internal();
  factory ImageCompressionService() => _instance;
  ImageCompressionService._internal();

  /// Compress and resize an image file
  /// 
  /// [file] - The XFile to compress
  /// [maxWidth] - Maximum width (default: 800 for faster uploads)
  /// [maxHeight] - Maximum height (default: 800 for faster uploads)
  /// [quality] - Compression quality 0-100 (default: 75 for better compression)
  /// [minWidth] - Minimum width to maintain (default: 300)
  /// [minHeight] - Minimum height to maintain (default: 300)
  /// 
  /// Returns compressed image as XFile
  Future<XFile> compressImage({
    required XFile file,
    int maxWidth = 800,
    int maxHeight = 800,
    int quality = 75,
    int minWidth = 300,
    int minHeight = 300,
  }) async {
    try {
      // Read original file
      final bytes = await file.readAsBytes();
      final originalSize = bytes.length;
      
      if (kDebugMode) {
        print('📷 Compressing image: ${file.name}');
        print('   Original size: ${(originalSize / 1024).toStringAsFixed(2)} KB');
      }

      // Get file info
      final filePath = file.path;
      final fileName = path.basenameWithoutExtension(filePath);

      // Skip compression for very small images (< 100KB) - more aggressive compression
      if (originalSize < 100 * 1024) {
        if (kDebugMode) {
          print('   Image is already small, skipping compression');
        }
        return file;
      }

      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final targetPath = path.join(
        tempDir.path,
        '${fileName}_compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      // Compress image
      XFile? compressedFile;
      
      if (Platform.isAndroid || Platform.isIOS) {
        // Use flutter_image_compress for mobile
        // Note: FlutterImageCompress uses minWidth/minHeight to resize.
        // To limit max size, we set minWidth/minHeight to the max values
        // and the image will be resized proportionally if larger
        final result = await FlutterImageCompress.compressAndGetFile(
          filePath,
          targetPath,
          quality: quality,
          minWidth: maxWidth, // Use maxWidth as minWidth to limit size
          minHeight: maxHeight, // Use maxHeight as minHeight to limit size
          format: CompressFormat.jpeg,
          keepExif: false,
        );

        if (result != null) {
          compressedFile = XFile(result.path);
        }
      } else {
        // For web, use a simpler approach (web doesn't support flutter_image_compress well)
        // Return original file for web - compression will be done on backend
        if (kDebugMode) {
          print('   Web platform detected, skipping client-side compression');
        }
        return file;
      }

      if (compressedFile == null) {
        if (kDebugMode) {
          print('   Compression failed, using original file');
        }
        return file;
      }

      // Check compressed file size
      final compressedBytes = await compressedFile.readAsBytes();
      final compressedSize = compressedBytes.length;
      final compressionRatio = ((1 - compressedSize / originalSize) * 100).toStringAsFixed(1);

      if (kDebugMode) {
        print('   Compressed size: ${(compressedSize / 1024).toStringAsFixed(2)} KB');
        print('   Compression ratio: $compressionRatio%');
      }

      // If compression didn't reduce size significantly, use original
      if (compressedSize >= originalSize * 0.9) {
        if (kDebugMode) {
          print('   Compression not effective, using original file');
        }
        return file;
      }

      return compressedFile;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error compressing image: $e');
        print('   Using original file');
      }
      // Return original file if compression fails
      return file;
    }
  }

  /// Compress multiple images
  /// Optimized defaults for faster uploads
  Future<List<XFile>> compressImages({
    required List<XFile> files,
    int maxWidth = 800,
    int maxHeight = 800,
    int quality = 75,
  }) async {
    final compressedFiles = <XFile>[];
    
    for (var file in files) {
      try {
        final compressed = await compressImage(
          file: file,
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          quality: quality,
        );
        compressedFiles.add(compressed);
      } catch (e) {
        if (kDebugMode) {
          print('❌ Failed to compress ${file.name}: $e');
        }
        // Add original file if compression fails
        compressedFiles.add(file);
      }
    }
    
    return compressedFiles;
  }

  /// Get image dimensions (approximate)
  Future<Map<String, int>> getImageDimensions(XFile file) async {
    try {
      // Simple check - for accurate dimensions, you'd need image package
      // This is a basic implementation
      return {
        'width': 0,
        'height': 0,
      };
    } catch (e) {
      return {'width': 0, 'height': 0};
    }
  }

  /// Check if image needs compression
  Future<bool> needsCompression(XFile file, {int maxSizeKB = 500}) async {
    try {
      final bytes = await file.readAsBytes();
      final sizeKB = bytes.length / 1024;
      return sizeKB > maxSizeKB;
    } catch (e) {
      return false;
    }
  }
}

