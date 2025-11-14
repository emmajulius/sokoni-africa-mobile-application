import 'package:flutter/material.dart';
import 'package:country_flags/country_flags.dart';
import '../../services/language_service.dart';
import '../../utils/constants.dart';

class LanguageRegionScreen extends StatefulWidget {
  const LanguageRegionScreen({super.key});

  @override
  State<LanguageRegionScreen> createState() => _LanguageRegionScreenState();
}

class _LanguageRegionScreenState extends State<LanguageRegionScreen> {
  final LanguageService _languageService = LanguageService();
  String? _selectedLanguage;
  String? _selectedRegion;
  
  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
    _languageService.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    _languageService.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    if (mounted) {
      // Force rebuild when language changes
      setState(() {
        _loadCurrentSettings();
      });
    }
  }
  
  void _loadCurrentSettings() {
    final currentLanguage = _languageService.languageCode == 'sw' 
        ? AppConstants.languageSwahili 
        : AppConstants.languageEnglish;
    _selectedLanguage = currentLanguage;
    _selectedRegion = 'Tanzania'; // Default region
  }
  
  String _getCountryCodeForRegion(String region) {
    switch (region) {
      case 'Tanzania':
        return 'TZ';
      case 'Kenya':
        return 'KE';
      case 'Uganda':
        return 'UG';
      case 'Rwanda':
        return 'RW';
      default:
        return 'TZ';
    }
  }
  
  Future<void> _saveLanguage(String language) async {
    await _languageService.setLanguage(language);
    // Language will update automatically via listener
    if (mounted) {
      final l10n = AppLocalizations.of(context) ?? 
                   AppLocalizations(_languageService.currentLocale);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text(l10n.languageUpdatedSuccessfully),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context) ?? 
                 AppLocalizations(_languageService.currentLocale);
    
    return Scaffold(
      backgroundColor: isDark 
          ? const Color(0xFF121212)
          : const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(l10n.languageAndRegion),
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
                      color: const Color(0xFF2196F3).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.language_rounded,
                      size: 32,
                      color: Color(0xFF2196F3),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context) ?? 
                                   AppLocalizations(_languageService.currentLocale);
                      return Text(
                        l10n.languageAndRegion,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: isDark 
                              ? Colors.white 
                              : Colors.grey[900],
                          letterSpacing: -0.5,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context) ?? 
                                   AppLocalizations(_languageService.currentLocale);
                      return Text(
                        l10n.customizeAppPreferences,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark 
                              ? Colors.grey[400] 
                              : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            // Content
            Container(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Language Section
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF9C27B0).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.translate_rounded,
                          color: Color(0xFF9C27B0),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Builder(
                        builder: (context) {
                          final l10n = AppLocalizations.of(context) ?? 
                                       AppLocalizations(_languageService.currentLocale);
                          return Text(
                            l10n.language,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.grey[900],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context) ?? 
                                   AppLocalizations(_languageService.currentLocale);
                      return Column(
                        children: [
                          _buildLanguageOption(
                            title: l10n.swahili,
                            subtitle: 'Kiswahili',
                            value: AppConstants.languageSwahili,
                            isSelected: _selectedLanguage == AppConstants.languageSwahili,
                            onTap: () => _saveLanguage(AppConstants.languageSwahili),
                            isDark: isDark,
                            countryCode: 'TZ',
                            color: const Color(0xFF4CAF50),
                          ),
                          const SizedBox(height: 12),
                          _buildLanguageOption(
                            title: l10n.english,
                            subtitle: l10n.english,
                            value: AppConstants.languageEnglish,
                            isSelected: _selectedLanguage == AppConstants.languageEnglish,
                            onTap: () => _saveLanguage(AppConstants.languageEnglish),
                            isDark: isDark,
                            countryCode: 'GB',
                            color: const Color(0xFF2196F3),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  // Region Section
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF9800).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.public_rounded,
                          color: Color(0xFFFF9800),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Builder(
                        builder: (context) {
                          final l10n = AppLocalizations.of(context) ?? 
                                       AppLocalizations(_languageService.currentLocale);
                          return Text(
                            l10n.region,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.grey[900],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [
                                Colors.grey[850]!.withOpacity(0.7),
                                Colors.grey[850]!.withOpacity(0.5),
                              ]
                            : [
                                Colors.white,
                                Colors.grey[50]!,
                              ],
                      ),
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
                      value: _selectedRegion,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.grey[900],
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        labelText: l10n.selectRegion,
                        labelStyle: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                        border: InputBorder.none,
                        prefixIcon: _selectedRegion != null
                            ? Padding(
                                padding: const EdgeInsets.all(10),
                                child: CountryFlag.fromCountryCode(
                                  _getCountryCodeForRegion(_selectedRegion!),
                                  width: 24,
                                  height: 18,
                                ),
                              )
                            : Container(
                                padding: const EdgeInsets.all(10),
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF9800).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFFFF9800).withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.location_on_rounded,
                                  color: Color(0xFFFF9800),
                                  size: 20,
                                ),
                              ),
                      ),
                      dropdownColor: isDark ? Colors.grey[850] : Colors.white,
                      icon: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      // Custom selected item builder - shows only text (flag is in prefixIcon)
                      // This prevents duplicate flags - prefixIcon shows flag, selected text shows only country name
                      selectedItemBuilder: (BuildContext context) {
                        final l10n = AppLocalizations.of(context) ?? 
                                     AppLocalizations(_languageService.currentLocale);
                        return [
                          l10n.tanzania,
                          l10n.kenya,
                          l10n.uganda,
                          l10n.rwanda,
                        ].map<Widget>((String region) {
                          return Text(
                            region,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.grey[900],
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        }).toList();
                      },
                      items: [
                        DropdownMenuItem(
                          value: 'Tanzania',
                          child: Builder(
                            builder: (context) {
                              final l10n = AppLocalizations.of(context) ?? 
                                           AppLocalizations(_languageService.currentLocale);
                              return Row(
                                children: [
                                  CountryFlag.fromCountryCode(
                                    'TZ',
                                    width: 24,
                                    height: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(l10n.tanzania),
                                ],
                              );
                            },
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Kenya',
                          child: Builder(
                            builder: (context) {
                              final l10n = AppLocalizations.of(context) ?? 
                                           AppLocalizations(_languageService.currentLocale);
                              return Row(
                                children: [
                                  CountryFlag.fromCountryCode(
                                    'KE',
                                    width: 24,
                                    height: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(l10n.kenya),
                                ],
                              );
                            },
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Uganda',
                          child: Builder(
                            builder: (context) {
                              final l10n = AppLocalizations.of(context) ?? 
                                           AppLocalizations(_languageService.currentLocale);
                              return Row(
                                children: [
                                  CountryFlag.fromCountryCode(
                                    'UG',
                                    width: 24,
                                    height: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(l10n.uganda),
                                ],
                              );
                            },
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Rwanda',
                          child: Builder(
                            builder: (context) {
                              final l10n = AppLocalizations.of(context) ?? 
                                           AppLocalizations(_languageService.currentLocale);
                              return Row(
                                children: [
                                  CountryFlag.fromCountryCode(
                                    'RW',
                                    width: 24,
                                    height: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(l10n.rwanda),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedRegion = value;
                        });
                        final l10n = AppLocalizations.of(context) ?? 
                                     AppLocalizations(_languageService.currentLocale);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, color: Colors.white),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(l10n.regionUpdatedSuccessfully),
                                ),
                              ],
                            ),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(Radius.circular(12)),
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption({
    required String title,
    required String subtitle,
    required String value,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    required String countryCode,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? color.withOpacity(0.15)
              : (isDark 
                  ? Colors.grey[850]!.withOpacity(0.5)
                  : Colors.white),
          border: Border.all(
            color: isSelected 
                ? color
                : (isDark 
                    ? Colors.grey[800]!
                    : Colors.grey[200]!),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? color.withOpacity(0.2)
                  : Colors.black.withOpacity(isDark ? 0.2 : 0.05),
              blurRadius: isSelected ? 12 : 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark 
                    ? Colors.grey[800]!.withOpacity(0.3)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark 
                      ? Colors.grey[700]!
                      : Colors.grey[300]!,
                  width: 1,
                ),
              ),
              child: CountryFlag.fromCountryCode(
                countryCode,
                width: 32,
                height: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.grey[900],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

