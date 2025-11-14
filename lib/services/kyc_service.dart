import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/constants.dart';
import 'auth_service.dart';

class KYCService {
  static final KYCService _instance = KYCService._internal();
  factory KYCService() => _instance;
  KYCService._internal();

  final String baseUrl = AppConstants.baseUrl;

  // Upload KYC document
  Future<Map<String, dynamic>> uploadKYCDocument({
    required XFile document,
    String documentType = 'id_card',
  }) async {
    try {
      final authService = AuthService();
      await authService.initialize();
      final token = authService.authToken;

      if (token == null) {
        throw Exception('Authentication required. Please login first.');
      }

      final uri = Uri.parse('$baseUrl/api/kyc/upload');

      print('📤 Uploading KYC document: ${document.name}...');

      var request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['document_type'] = documentType;

      // Determine content type
      String contentType = 'image/jpeg';
      if (document.name.toLowerCase().endsWith('.pdf')) {
        contentType = 'application/pdf';
      } else if (document.name.toLowerCase().endsWith('.png')) {
        contentType = 'image/png';
      }

      // Add document file
      final bytes = await document.readAsBytes();
      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: document.name,
        contentType: MediaType.parse(contentType),
      );
      request.files.add(multipartFile);

      final response = await request.send().timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception('Upload timeout');
        },
      );

      final responseBody = await response.stream.bytesToString();
      print('📤 KYC upload response status: ${response.statusCode}');
      print('📤 KYC upload response body: $responseBody');

      if (response.statusCode == 201) {
        final data = json.decode(responseBody);
        print('✅ Successfully uploaded KYC document');
        return data;
      } else {
        final error = json.decode(responseBody);
        throw Exception(error['detail'] ?? 'Failed to upload KYC document: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error uploading KYC document: $e');
      rethrow;
    }
  }

  // Get KYC verification status
  Future<Map<String, dynamic>> getKYCStatus() async {
    try {
      final authService = AuthService();
      await authService.initialize();
      final token = authService.authToken;

      if (token == null) {
        throw Exception('Authentication required. Please login first.');
      }

      final uri = Uri.parse('$baseUrl/api/kyc/status');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Failed to get KYC status');
      }
    } catch (e) {
      print('❌ Error getting KYC status: $e');
      rethrow;
    }
  }

  // Get all KYC documents
  Future<List<Map<String, dynamic>>> getKYCDocuments() async {
    try {
      final authService = AuthService();
      await authService.initialize();
      final token = authService.authToken;

      if (token == null) {
        throw Exception('Authentication required. Please login first.');
      }

      final uri = Uri.parse('$baseUrl/api/kyc/documents');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Failed to get KYC documents');
      }
    } catch (e) {
      print('❌ Error getting KYC documents: $e');
      rethrow;
    }
  }

  // Delete KYC document
  Future<void> deleteKYCDocument(int documentId) async {
    try {
      final authService = AuthService();
      await authService.initialize();
      final token = authService.authToken;

      if (token == null) {
        throw Exception('Authentication required. Please login first.');
      }

      final uri = Uri.parse('$baseUrl/api/kyc/documents/$documentId');

      final response = await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode != 204) {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Failed to delete KYC document');
      }
    } catch (e) {
      print('❌ Error deleting KYC document: $e');
      rethrow;
    }
  }
}

