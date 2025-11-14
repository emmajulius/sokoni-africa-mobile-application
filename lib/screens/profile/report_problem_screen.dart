import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/auth_service.dart';
import '../../services/language_service.dart';

class ReportProblemScreen extends StatefulWidget {
  const ReportProblemScreen({super.key});

  @override
  State<ReportProblemScreen> createState() => _ReportProblemScreenState();
}

class _ReportProblemScreenState extends State<ReportProblemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  final AuthService _authService = AuthService();
  final LanguageService _languageService = LanguageService();
  static const String _supportEmail = 'emmajulius2512@gmail.com';
  String? _selectedCategory;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _languageService.addListener(_onLanguageChanged);
    _checkGuestAccess();
  }

  @override
  void dispose() {
    _languageService.removeListener(_onLanguageChanged);
    _subjectController.dispose();
    _descriptionController.dispose();
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
      // Guest users cannot report problems
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n?.reportingProblemsOnlyRegistered ?? 'Reporting problems is only available for registered users. Please sign in to continue.'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      });
      return;
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.initialize();
      final userName = _authService.fullName ?? _authService.username ?? 'Sokoni Africa user';
      final userEmail = _authService.email ?? 'Not provided';
      final userPhone = _authService.phone ?? 'Not provided';

      final category = _selectedCategory ?? 'general';
      final subjectText = _subjectController.text.trim();
      final description = _descriptionController.text.trim();

      final subject = '[${category.toUpperCase()}] $subjectText';
      final body = 'Hi Sokoni Africa Support,\n\n'
          'A new support report has been submitted via the app.\n\n'
          'Category: $category\n'
          'Subject: $subjectText\n'
          'Description:\n$description\n\n'
          'User information:\n'
          'Name: $userName\n'
          'Email: $userEmail\n'
          'Phone: $userPhone\n\n'
          'Submitted on: ${DateTime.now().toLocal()}\n\n'
          'Best regards,\n$userName';

      final emailUri = Uri(
        scheme: 'mailto',
        path: _supportEmail,
        queryParameters: {
          'subject': subject,
          'body': body,
        },
      );

      final launched = await launchUrl(emailUri, mode: LaunchMode.externalApplication);

      final l10n = AppLocalizations.of(context);
      if (!launched) {
        await Clipboard.setData(const ClipboardData(text: _supportEmail));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n != null ? l10n.unableToOpenEmailApp.replaceAll('{email}', _supportEmail) : 'Unable to open your email app. We copied $_supportEmail so you can email us manually.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n?.openingEmailAppPleaseSend ?? 'Opening your email app. Please send the email to complete your report.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      final l10n = AppLocalizations.of(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n?.failedToSubmitReport ?? 'Failed to submit report'}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: isDark 
          ? const Color(0xFF121212)
          : const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(l10n?.reportProblem ?? 'Report a Problem'),
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Compact Header with Gradient
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
                      color: const Color(0xFFFF5722).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.report_problem_rounded,
                      size: 32,
                      color: Color(0xFFFF5722),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n?.reportProblem ?? 'Report a Problem',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: isDark 
                          ? Colors.white 
                          : Colors.grey[900],
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n?.helpUsImproveReportingIssues ?? 'Help us improve by reporting any issues',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark 
                          ? Colors.grey[400] 
                          : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Form Content
            Container(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category Dropdown Card
                    Container(
                      decoration: BoxDecoration(
                        color: isDark 
                            ? Colors.grey[850]!.withOpacity(0.5)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark 
                              ? Colors.grey[800]!
                              : Colors.grey[200]!,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedCategory,
                        decoration: InputDecoration(
                          labelText: l10n?.category ?? 'Category',
                          labelStyle: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                          border: InputBorder.none,
                          prefixIcon: Container(
                            padding: const EdgeInsets.all(10),
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF5722).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.category_rounded,
                              color: Color(0xFFFF5722),
                              size: 20,
                            ),
                          ),
                        ),
                        dropdownColor: isDark ? Colors.grey[850] : Colors.white,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.grey[900],
                          fontSize: 15,
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'bug',
                            child: Text(l10n?.bugReport ?? 'Bug Report'),
                          ),
                          DropdownMenuItem(
                            value: 'feature',
                            child: Text(l10n?.featureRequest ?? 'Feature Request'),
                          ),
                          DropdownMenuItem(
                            value: 'payment',
                            child: Text(l10n?.paymentIssue ?? 'Payment Issue'),
                          ),
                          DropdownMenuItem(
                            value: 'order',
                            child: Text(l10n?.orderIssue ?? 'Order Issue'),
                          ),
                          DropdownMenuItem(
                            value: 'other',
                            child: Text(l10n?.other ?? 'Other'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return l10n?.pleaseSelectCategory ?? 'Please select a category';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Subject Field Card
                    Container(
                      decoration: BoxDecoration(
                        color: isDark 
                            ? Colors.grey[850]!.withOpacity(0.5)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark 
                              ? Colors.grey[800]!
                              : Colors.grey[200]!,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: TextFormField(
                        controller: _subjectController,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.grey[900],
                          fontSize: 15,
                        ),
                        decoration: InputDecoration(
                          labelText: l10n?.subject ?? 'Subject',
                          labelStyle: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                          border: InputBorder.none,
                          prefixIcon: Container(
                            padding: const EdgeInsets.all(10),
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2196F3).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.title_rounded,
                              color: Color(0xFF2196F3),
                              size: 20,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n?.pleaseEnterSubject ?? 'Please enter a subject';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Description Field Card
                    Container(
                      decoration: BoxDecoration(
                        color: isDark 
                            ? Colors.grey[850]!.withOpacity(0.5)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark 
                              ? Colors.grey[800]!
                              : Colors.grey[200]!,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: TextFormField(
                        controller: _descriptionController,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.grey[900],
                          fontSize: 15,
                        ),
                        decoration: InputDecoration(
                          labelText: l10n?.description ?? 'Description',
                          labelStyle: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                          border: InputBorder.none,
                          alignLabelWithHint: true,
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF9C27B0).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.description_rounded,
                                color: Color(0xFF9C27B0),
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                        maxLines: 6,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n?.pleaseDescribeProblem ?? 'Please describe the problem';
                          }
                          if (value.length < 20) {
                            return l10n?.pleaseProvideMoreDetails ?? 'Please provide more details (at least 20 characters)';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitReport,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5722),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                          disabledBackgroundColor: Colors.grey[400],
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                l10n?.submitReport ?? 'Submit Report',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Help Text
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.blue[900] : Colors.blue[50])!.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: (isDark ? Colors.blue[800] : Colors.blue[200])!.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 18,
                            color: isDark ? Colors.blue[300] : Colors.blue[700],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n?.reportSentViaEmail ?? 'Your report will be sent via email to our support team',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.blue[300] : Colors.blue[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

