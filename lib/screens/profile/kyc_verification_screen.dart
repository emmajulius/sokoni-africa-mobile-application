import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../services/kyc_service.dart';
import '../../services/auth_service.dart';
import '../../services/language_service.dart';

class KYCVerificationScreen extends StatefulWidget {
  const KYCVerificationScreen({super.key});

  @override
  State<KYCVerificationScreen> createState() => _KYCVerificationScreenState();
}

class _KYCVerificationScreenState extends State<KYCVerificationScreen> {
  final KYCService _kycService = KYCService();
  final AuthService _authService = AuthService();
  final LanguageService _languageService = LanguageService();
  final ImagePicker _picker = ImagePicker();
  
  bool _isLoading = true;
  bool _isVerified = false;
  bool _hasDocument = false;
  String? _documentStatus;
  String? _documentUrl;
  String? _documentType;
  Uint8List? _selectedImageBytes;
  XFile? _selectedImage;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _languageService.addListener(_onLanguageChanged);
    _checkGuestAccess();
  }

  @override
  void dispose() {
    _languageService.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _checkGuestAccess() async {
    await _authService.initialize();
    if (_authService.isGuest) {
      // Guest users cannot access KYC verification
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n?.kycOnlyForRegisteredUsers ?? 'KYC verification is only available for registered users. Please sign in to continue.'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      });
      return;
    }
    _loadKYCStatus();
  }

  Future<void> _loadKYCStatus() async {
    setState(() => _isLoading = true);
    try {
      await _authService.initialize();
      if (_authService.isAuthenticated && _authService.authToken != null) {
        final status = await _kycService.getKYCStatus();
        setState(() {
          _isVerified = status['is_verified'] ?? false;
          _hasDocument = status['has_document'] ?? false;
          _documentStatus = status['document_status'];
          
          if (status['documents'] != null && (status['documents'] as List).isNotEmpty) {
            final doc = (status['documents'] as List).first;
            _documentUrl = doc['document_url'];
            _documentType = doc['document_type'];
          }
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading KYC status: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDocument() async {
    try {
      // Show dialog to choose between camera and gallery
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: isDark ? Colors.grey[800] : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            AppLocalizations.of(context)?.selectDocumentSource ?? 'Select Document Source',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.grey[900],
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.grey[600]! : Colors.blue[200]!,
                  ),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2196F3).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF2196F3)),
                  ),
                  title: Text(
                    AppLocalizations.of(context)?.camera ?? 'Camera',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.grey[900],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.grey[600]! : Colors.green[200]!,
                  ),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.photo_library_rounded, color: Color(0xFF4CAF50)),
                  ),
                  title: Text(
                    AppLocalizations.of(context)?.gallery ?? 'Gallery',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.grey[900],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ),
            ],
          ),
        ),
      );

      if (source == null) return;

      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 2000,
        maxHeight: 2000,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImage = image;
          _selectedImageBytes = bytes;
        });
        await _uploadDocument();
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n != null 
                ? '${l10n.errorPickingDocument}: $e'
                : 'Error picking document: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadDocument() async {
    if (_selectedImage == null) return;

    if (!_authService.isAuthenticated || _authService.authToken == null) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n?.pleaseLoginToUploadKYC ?? 'Please login to upload KYC document'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      await _kycService.uploadKYCDocument(
        document: _selectedImage!,
        documentType: 'id_card', // Default to ID card, only one document needed
      );
      
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.documentUploadedSuccessfully ?? 'Document uploaded successfully! It will be reviewed shortly.'),
            backgroundColor: Colors.green,
          ),
        );
        // Reload status
        await _loadKYCStatus();
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n != null
                ? '${l10n.failedToUploadDocument}: $e'
                : 'Failed to upload document: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _selectedImage = null;
          _selectedImageBytes = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    
    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark 
            ? const Color(0xFF121212)
            : const Color(0xFFF5F7FA),
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).primaryColor,
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: isDark 
          ? const Color(0xFF121212)
          : const Color(0xFFF5F7FA),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 20.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          Colors.grey[850]!,
                          Colors.grey[900]!,
                        ]
                      : [
                          const Color(0xFFF5F7FA),
                          const Color(0xFFE8ECF1),
                        ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF9C27B0).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.verified_user_rounded,
                      size: 32,
                      color: Color(0xFF9C27B0),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n?.kycAccountVerification ?? 'KYC & Account Verification',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: isDark 
                          ? Colors.white 
                          : Colors.grey[900],
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status Card
                  Container(
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: _isVerified
                            ? [
                                const Color(0xFF4CAF50).withOpacity(0.1),
                                const Color(0xFF66BB6A).withOpacity(0.1),
                              ]
                            : [
                                const Color(0xFFFF9800).withOpacity(0.1),
                                const Color(0xFFFFB74D).withOpacity(0.1),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isVerified
                            ? const Color(0xFF4CAF50).withOpacity(0.3)
                            : const Color(0xFFFF9800).withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _isVerified
                                ? const Color(0xFF4CAF50).withOpacity(0.2)
                                : const Color(0xFFFF9800).withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isVerified ? Icons.verified_rounded : Icons.pending_rounded,
                            color: _isVerified
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFFFF9800),
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isVerified 
                                    ? (l10n?.accountVerified ?? 'Account Verified')
                                    : (l10n?.verificationPending ?? 'Verification Pending'),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: isDark 
                                      ? Colors.white 
                                      : (_isVerified ? Colors.green[900] : Colors.orange[900]),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isVerified
                                    ? (l10n?.accountVerifiedSuccessfully ?? 'Your account has been verified successfully')
                                    : (l10n?.completeVerificationToUnlock ?? 'Complete verification to unlock all features'),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark 
                                      ? Colors.grey[400] 
                                      : (_isVerified ? Colors.green[700] : Colors.orange[700]),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n?.verificationDocument ?? 'Verification Document',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.grey[900],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.blue[900]!.withOpacity(0.2)
                          : Colors.blue[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? Colors.blue[700]!.withOpacity(0.3)
                            : Colors.blue[200]!,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2196F3).withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.info_outline_rounded,
                            color: Color(0xFF2196F3),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n?.kycDocumentInfo ?? 'Only one document is required for verification. Upload a clear photo of your National ID, Passport, or Driver\'s License.',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark 
                                  ? Colors.grey[300] 
                                  : Colors.blue[900],
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Document Preview
                  if (_selectedImageBytes != null || _documentUrl != null)
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: isDark 
                            ? Colors.grey[800] 
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark 
                              ? Colors.grey[700]! 
                              : Colors.grey[200]!,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2196F3).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.description_rounded,
                                  color: Color(0xFF2196F3),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _documentType?.replaceAll('_', ' ').toUpperCase() ?? 'Document',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: isDark ? Colors.white : Colors.grey[900],
                                  ),
                                ),
                              ),
                              if (_documentStatus != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _documentStatus == 'approved'
                                        ? const Color(0xFF4CAF50)
                                        : _documentStatus == 'rejected'
                                            ? Colors.red
                                            : const Color(0xFFFF9800),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _documentStatus!.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: _selectedImageBytes != null
                                ? Image.memory(
                                    _selectedImageBytes!,
                                    height: 200,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  )
                                : _documentUrl != null
                                    ? Image.network(
                                        _documentUrl!,
                                        height: 200,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            height: 200,
                                            decoration: BoxDecoration(
                                              color: isDark 
                                                  ? Colors.grey[700] 
                                                  : Colors.grey[300],
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              Icons.description_rounded,
                                              size: 64,
                                              color: isDark 
                                                  ? Colors.grey[500] 
                                                  : Colors.grey[600],
                                            ),
                                          );
                                        },
                                      )
                                    : const SizedBox(),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isUploading || _isVerified ? null : _pickDocument,
                      icon: _isUploading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.upload_file_rounded),
                      label: Text(
                        _isUploading
                            ? (l10n?.uploading ?? 'Uploading...')
                            : _hasDocument
                                ? (l10n?.replaceDocument ?? 'Replace Document')
                                : (l10n?.uploadDocument ?? 'Upload Document'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9C27B0),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                  if (_documentStatus == 'pending') ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.orange[900]!.withOpacity(0.2)
                            : Colors.orange[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? Colors.orange[700]!.withOpacity(0.3)
                              : Colors.orange[200]!,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF9800).withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.hourglass_empty_rounded,
                              color: Color(0xFFFF9800),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              l10n?.documentUnderReview ?? 'Your document is under review. You will be notified once verification is complete.',
                              style: TextStyle(
                                color: isDark 
                                    ? Colors.orange[300] 
                                    : Colors.orange[700],
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}

