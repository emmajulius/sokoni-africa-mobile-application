import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:crypto/crypto.dart';
import '../utils/constants.dart';
import 'image_compression_service.dart';

/// Service for uploading media directly to Cloudinary
/// This bypasses the backend server for faster uploads
class CloudinaryService {
  static final CloudinaryService _instance = CloudinaryService._internal();
  factory CloudinaryService() => _instance;
  CloudinaryService._internal();

  final String cloudName = AppConstants.cloudinaryCloudName;
  final String apiKey = AppConstants.cloudinaryApiKey;
  final String apiSecret = AppConstants.cloudinaryApiSecret;
  final String uploadPreset = AppConstants.cloudinaryUploadPreset;

  /// Generate Cloudinary signature for authenticated uploads
  String _generateSignature(Map<String, dynamic> params) {
    // Remove null values
    final cleanParams = Map.fromEntries(
      params.entries.where((entry) => entry.value != null && entry.value.toString().isNotEmpty)
    );
    
    // Sort parameters
    final sortedParams = Map.fromEntries(
      cleanParams.entries.toList()..sort((a, b) => a.key.compareTo(b.key))
    );
    
    // Create query string
    final queryString = sortedParams.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    
    if (kDebugMode) {
      print('   Signature params (sorted): $sortedParams');
      print('   Signature string: $queryString$apiSecret');
    }
    
    // Add API secret
    final signatureString = '$queryString$apiSecret';
    
    // Generate SHA1 hash
    final bytes = utf8.encode(signatureString);
    final digest = sha1.convert(bytes);
    
    return digest.toString();
  }

  /// Upload a single image to Cloudinary
  /// Returns the secure URL of the uploaded image
  Future<String> uploadImage(
    XFile imageFile, {
    String folder = AppConstants.cloudinaryProductsFolder,
    Function(int, int)? onProgress,
    int maxWidth = 1200,
    int maxHeight = 1200,
    int quality = 80,
  }) async {
    try {
      // Compress image first for faster upload
      final compressionService = ImageCompressionService();
      final compressedFile = await compressionService.compressImage(
        file: imageFile,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        quality: quality,
      );

      final bytes = await compressedFile.readAsBytes();
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final publicId = '${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(8)}';

      // Prepare parameters for signature (ONLY include parameters that Cloudinary requires in signature)
      // Include overwrite so folder/public_id pair stays unique
      final signatureParams = <String, dynamic>{
        'timestamp': timestamp,
        'folder': folder,
        'public_id': publicId,
        'overwrite': 'false',
      };

      // Use signed upload (more reliable, works immediately without preset)
      // We have API secret, so signed upload is the best option
      final signature = _generateSignature(signatureParams);
      final uploadUrl = 'https://api.cloudinary.com/v1_1/$cloudName/image/upload';
      
      // Fields to send: signature params + required auth fields
      final fields = {
        'api_key': apiKey,
        'timestamp': timestamp,
        'signature': signature,
        'folder': folder,
        'public_id': publicId,
        'overwrite': 'false',
      };

      print('   Using signed upload (API key + signature)');
      print('   Upload URL: $uploadUrl');
      print('   Cloud Name: $cloudName');
      print('   API Key: ${apiKey.substring(0, 5)}...');
      print('   Signature: ${signature.substring(0, 10)}...');
      print('   Fields count: ${fields.length}');
      print('   Params used for signature: $signatureParams');
      if (kDebugMode) {
        print('   All fields: $fields');
      }

      print('☁️ Uploading image to Cloudinary: ${compressedFile.name}');
      print('   Size: ${(bytes.length / 1024).toStringAsFixed(2)} KB');
      print('   Folder: $folder');

      // Create multipart request
      final request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
      request.fields.addAll(fields);
      // Add file as multipart file
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: compressedFile.name,
      ));

      // Send request with progress tracking
      final streamedResponse = await request.send();
      
      // Track upload progress if callback provided
      if (onProgress != null) {
        final totalBytes = bytes.length;
        int sentBytes = 0;
        streamedResponse.stream.listen(
          (chunk) {
            sentBytes += chunk.length;
            onProgress(sentBytes, totalBytes);
          },
        );
      }
      
      final response = await http.Response.fromStream(streamedResponse);

      print('   Response status: ${response.statusCode}');
      if (response.statusCode != 200) {
        print('   Response body: ${response.body}');
        print('   Response headers: ${response.headers}');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final secureUrl = data['secure_url'] as String? ?? data['url'] as String?;
        
        if (secureUrl == null || secureUrl.isEmpty) {
          throw Exception('Cloudinary returned empty URL. Response: ${response.body}');
        }
        
        if (kDebugMode) {
          print('✅ Image uploaded successfully to Cloudinary');
          print('   URL: $secureUrl');
          print('   Public ID: ${data['public_id']}');
        }
        
        return secureUrl;
      } else {
        // Log full error details
        print('   ❌ Cloudinary upload failed!');
        print('   Status Code: ${response.statusCode}');
        print('   Response Body: ${response.body}');
        print('   Response Headers: ${response.headers}');
        
        try {
          final error = json.decode(response.body);
          final errorMessage = error['error']?['message'] ?? error['message'] ?? response.statusCode.toString();
          final fullError = 'Cloudinary upload failed (${response.statusCode}): $errorMessage\nFull response: ${response.body}';
          print('   Parsed Error: $fullError');
          throw Exception(fullError);
        } catch (e) {
          final fullError = 'Cloudinary upload failed (${response.statusCode}): ${response.body}';
          print('   Raw Error: $fullError');
          throw Exception(fullError);
        }
      }
    } catch (e, stackTrace) {
      print('❌ Error uploading image to Cloudinary: $e');
      print('   Error type: ${e.runtimeType}');
      print('   Full error: ${e.toString()}');
      if (kDebugMode) {
        print('   Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

  /// Upload multiple images to Cloudinary
  /// Returns list of secure URLs
  Future<List<String>> uploadImages(
    List<XFile> imageFiles, {
    String folder = AppConstants.cloudinaryProductsFolder,
    Function(int, int)? onProgress,
    int maxWidth = 1200,
    int maxHeight = 1200,
    int quality = 80,
  }) async {
    final urls = <String>[];
    int uploaded = 0;
    final total = imageFiles.length;

    print('☁️ Starting upload of $total images to Cloudinary...');
    print('   Cloud Name: $cloudName');
    print('   Upload Preset: $uploadPreset');
    print('   Is Configured: $isConfigured');
    print('   Configuration Status: $configurationStatus');

    for (var file in imageFiles) {
      try {
        if (onProgress != null) {
          onProgress(uploaded, total);
        }

        print('☁️ Uploading ${uploaded + 1}/$total: ${file.name}');

        final url = await uploadImage(
          file,
          folder: folder,
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          quality: quality,
        );
        urls.add(url);
        uploaded++;

        print('✅ Successfully uploaded $uploaded/$total images');

        if (onProgress != null) {
          onProgress(uploaded, total);
        }
      } catch (e, stackTrace) {
        print('❌ Failed to upload ${file.name}: $e');
        print('   Error type: ${e.runtimeType}');
        print('   Error details: ${e.toString()}');
        if (kDebugMode) {
          print('   Stack trace: $stackTrace');
        }
        // Continue with other images even if one fails
      }
    }

    if (urls.isEmpty && imageFiles.isNotEmpty) {
      throw Exception('No images were uploaded successfully. Check Cloudinary configuration and preset.');
    }

    return urls;
  }

  /// Upload a video to Cloudinary
  /// Returns the secure URL and thumbnail URL
  Future<Map<String, String>> uploadVideo(
    XFile videoFile, {
    String folder = AppConstants.cloudinaryStoriesFolder,
    Function(int, int)? onProgress,
    int maxFileSize = 100 * 1024 * 1024, // 100MB default
  }) async {
    try {
      final bytes = await videoFile.readAsBytes();
      final fileSizeMB = bytes.length / (1024 * 1024);

      if (bytes.length > maxFileSize) {
        throw Exception('Video file too large: ${fileSizeMB.toStringAsFixed(2)}MB. Maximum: ${(maxFileSize / (1024 * 1024)).toStringAsFixed(2)}MB');
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final publicId = '${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(8)}';

      // Prepare parameters for video upload (must include api_key for signature)
      final params = <String, dynamic>{
        'timestamp': timestamp,
        'folder': folder,
        'public_id': publicId,
        'overwrite': 'false',
        'resource_type': 'video',
        'eager': 'w_400,h_300,c_fill,q_auto', // Generate thumbnail
      };

      // Use signed upload for videos (more reliable)
      final signature = _generateSignature(params);
      final uploadUrl = 'https://api.cloudinary.com/v1_1/$cloudName/video/upload';
      final fields = {
        'api_key': apiKey,
        'timestamp': timestamp,
        'signature': signature,
        'folder': folder,
        'public_id': publicId,
        'eager': 'w_400,h_300,c_fill,q_auto',
      };

      if (kDebugMode) {
        print('   Using signed upload for video');
      }

      if (kDebugMode) {
        print('☁️ Uploading video to Cloudinary: ${videoFile.name}');
        print('   Size: ${fileSizeMB.toStringAsFixed(2)} MB');
        print('   Folder: $folder');
      }

      // Create multipart request
      final request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
      request.fields.addAll(fields);
      // Add file as multipart file
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: videoFile.name,
      ));

      // Send request with progress tracking
      final streamedResponse = await request.send();
      
      // Track upload progress if callback provided
      if (onProgress != null) {
        final totalBytes = bytes.length;
        int sentBytes = 0;
        streamedResponse.stream.listen(
          (chunk) {
            sentBytes += chunk.length;
            onProgress(sentBytes, totalBytes);
          },
        );
      }
      
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final secureUrl = data['secure_url'] as String? ?? data['url'] as String;
        final thumbnailUrl = data['eager'] != null && (data['eager'] as List).isNotEmpty
            ? (data['eager'] as List)[0]['secure_url'] as String
            : secureUrl.replaceAll('.mp4', '.jpg').replaceAll('.mov', '.jpg');

        if (kDebugMode) {
          print('✅ Video uploaded successfully to Cloudinary');
          print('   URL: $secureUrl');
          print('   Thumbnail: $thumbnailUrl');
        }

        return {
          'url': secureUrl,
          'thumbnail_url': thumbnailUrl,
          'public_id': data['public_id'] as String,
        };
      } else {
        final error = json.decode(response.body);
        throw Exception('Cloudinary upload failed: ${error['error']?['message'] ?? response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error uploading video to Cloudinary: $e');
      }
      rethrow;
    }
  }

  /// Delete an image/video from Cloudinary
  Future<void> deleteMedia(String publicId, {String resourceType = 'image'}) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final params = <String, dynamic>{
        'public_id': publicId,
        'timestamp': timestamp,
        'resource_type': resourceType,
      };

      final signature = _generateSignature(params);
      final url = 'https://api.cloudinary.com/v1_1/$cloudName/$resourceType/destroy';

      final response = await http.post(
        Uri.parse(url),
        body: {
          'public_id': publicId,
          'api_key': apiKey,
          'timestamp': timestamp,
          'signature': signature,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['result'] == 'ok') {
          if (kDebugMode) {
            print('✅ Successfully deleted from Cloudinary: $publicId');
          }
        } else {
          throw Exception('Failed to delete: ${data['result']}');
        }
      } else {
        throw Exception('Delete failed with status: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error deleting from Cloudinary: $e');
      }
      rethrow;
    }
  }

  /// Generate a random string for public IDs
  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return List.generate(
      length,
      (index) => chars[(random + index) % chars.length],
    ).join();
  }

  /// Check if Cloudinary is properly configured
  bool get isConfigured {
    // Check if cloud name and API key are set (not default placeholders)
    final hasCloudName = cloudName.isNotEmpty && cloudName != 'your-cloud-name';
    final hasApiKey = apiKey.isNotEmpty && apiKey != 'your-api-key';
    
    // Either upload preset OR API secret must be configured
    final hasPreset = uploadPreset.isNotEmpty && uploadPreset != 'your-api-secret';
    final hasSecret = apiSecret.isNotEmpty && apiSecret != 'your-api-secret';
    
    return hasCloudName && hasApiKey && (hasPreset || hasSecret);
  }
  
  /// Get configuration status for debugging
  Map<String, bool> get configurationStatus {
    return {
      'cloudName': cloudName.isNotEmpty && cloudName != 'your-cloud-name',
      'apiKey': apiKey.isNotEmpty && apiKey != 'your-api-key',
      'uploadPreset': uploadPreset.isNotEmpty && uploadPreset != 'your-api-secret',
      'apiSecret': apiSecret.isNotEmpty && apiSecret != 'your-api-secret',
      'isConfigured': isConfigured,
    };
  }
}

