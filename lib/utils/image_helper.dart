import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Helper class for image handling with caching and thumbnails
class ImageHelper {
  /// Get optimized thumbnail URL from full image URL
  /// - Cloudinary: injects transformation (fast CDN thumbnail)
  /// - Legacy backend: points to pre-generated thumbnail file
  static String? getThumbnailUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return null;
    
    final lowerUrl = imageUrl.toLowerCase();

    // Handle Cloudinary URLs using transformation presets
    // Smaller size for faster loading (300x300 instead of 420x420)
    if (lowerUrl.contains('res.cloudinary.com')) {
      return _cloudinaryTransform(
        imageUrl,
        transformation: 'c_fill,w_300,h_300,q_70,f_auto',
      );
    }

    // Handle legacy backend URLs (local storage)
    if (imageUrl.contains('/products/')) {
      final parts = imageUrl.split('/products/');
      if (parts.length == 2) {
        final filename = parts[1];
        return '${parts[0]}/products/thumbnails/thumb_$filename';
      }
    }
    
    // If thumbnail URL format not found, return original
    return imageUrl;
  }


  /// Apply Cloudinary transformation by injecting the segment after `/upload/`
  static String? _cloudinaryTransform(String imageUrl, {required String transformation}) {
    final parts = imageUrl.split('/upload/');
    if (parts.length == 2) {
      return '${parts[0]}/upload/$transformation/${parts[1]}';
    }
    return imageUrl;
  }

  /// Build a cached network image widget with placeholder and error handling
  /// Uses thumbnail for list views, full image for detail views
  static Widget buildCachedImage({
    required String imageUrl,
    bool useThumbnail = false,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
    Duration fadeInDuration = const Duration(milliseconds: 300),
  }) {
    // Use thumbnail URL if requested
    final url = useThumbnail ? (getThumbnailUrl(imageUrl) ?? imageUrl) : imageUrl;

    // Helper to safely convert double to int (handles Infinity/NaN)
    int? safeToInt(double? value) {
      if (value == null) return null;
      if (!value.isFinite) return null; // Skip Infinity/NaN
      return value.toInt();
    }

    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 150), // Faster fade
      placeholder: (context, url) => placeholder ?? _buildPlaceholder(),
      errorWidget: (context, url, error) => errorWidget ?? _buildErrorWidget(),
      // Cache settings - smaller cache for faster loading
      memCacheWidth: safeToInt(width) ?? 300,
      memCacheHeight: safeToInt(height) ?? 300,
      maxWidthDiskCache: safeToInt(width) ?? 400,
      maxHeightDiskCache: safeToInt(height) ?? 400,
    );
  }

  /// Build placeholder widget - simplified for faster rendering
  static Widget _buildPlaceholder() {
    // Simple gradient placeholder - no network calls for faster display
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.grey[200]!,
            Colors.grey[100]!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  /// Build error widget
  static Widget _buildErrorWidget() {
    return Container(
      color: Colors.grey[200],
      child: Icon(
        Icons.broken_image,
        color: Colors.grey[400],
        size: 24,
      ),
    );
  }

  /// Build progressive image (low quality first, then high quality)
  static Widget buildProgressiveImage({
    required String imageUrl,
    String? thumbnailUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    // Use thumbnail if available, otherwise use full image
    final lowResUrl = thumbnailUrl ?? getThumbnailUrl(imageUrl) ?? imageUrl;
    final highResUrl = imageUrl;

    // If thumbnail and full image are the same, just use cached network image
    if (lowResUrl == highResUrl) {
      return buildCachedImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
      );
    }

    // Helper to safely convert double to int (handles Infinity/NaN)
    int? safeToInt(double? value) {
      if (value == null) return null;
      if (!value.isFinite) return null; // Skip Infinity/NaN
      return value.toInt();
    }

    // Progressive loading: show thumbnail first as placeholder, then full image
    // Use a simpler approach: load thumbnail first, then full image when ready
    return CachedNetworkImage(
      imageUrl: highResUrl,
      width: width,
      height: height,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 300),
      memCacheWidth: safeToInt(width),
      memCacheHeight: safeToInt(height),
      maxWidthDiskCache: safeToInt(width) ?? 800,
      maxHeightDiskCache: safeToInt(height) ?? 800,
      // Use thumbnail as placeholder for faster initial display
      placeholder: (context, url) => CachedNetworkImage(
        imageUrl: lowResUrl,
        width: width,
        height: height,
        fit: fit,
        memCacheWidth: safeToInt(width) ?? 200,
        memCacheHeight: safeToInt(height) ?? 200,
      ),
    );
  }

}

