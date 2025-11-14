import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../utils/constants.dart';
import '../../services/language_service.dart';
import 'gender_selection_screen.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> with TickerProviderStateMixin {
  String? selectedLanguage;
  final LanguageService _languageService = LanguageService();
  
  late AnimationController _headerController;
  late AnimationController _optionsController;
  late AnimationController _buttonController;
  
  // Header animations
  late Animation<double> _iconFadeAnimation;
  late Animation<double> _iconScaleAnimation;
  late Animation<double> _titleFadeAnimation;
  late Animation<Offset> _titleSlideAnimation;
  late Animation<double> _subtitleFadeAnimation;
  
  // Options animations
  late Animation<double> _optionsFadeAnimation;
  
  // Button animations
  late Animation<double> _buttonFadeAnimation;
  late Animation<double> _buttonScaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _languageService.addListener(_onLanguageChanged);
    _loadCurrentLanguage();
    
    // Initialize animation controllers
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _optionsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    // Icon animations
    _iconFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _headerController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );
    
    _iconScaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _headerController,
        curve: const Interval(0.0, 0.4, curve: Curves.elasticOut),
      ),
    );
    
    // Title animations
    _titleFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _headerController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
      ),
    );
    
    _titleSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _headerController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
      ),
    );
    
    // Subtitle animations
    _subtitleFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _headerController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );
    
    // Options animations
    _optionsFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _optionsController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOut),
      ),
    );
    
    // Button animations
    _buttonFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _buttonController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOut),
      ),
    );
    
    _buttonScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _buttonController,
        curve: const Interval(0.0, 1.0, curve: Curves.elasticOut),
      ),
    );
    
    // Start animations in sequence
    _headerController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _optionsController.forward();
    });
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) _buttonController.forward();
    });
  }
  
  @override
  void dispose() {
    _headerController.dispose();
    _optionsController.dispose();
    _buttonController.dispose();
    _languageService.removeListener(_onLanguageChanged);
    super.dispose();
  }
  
  void _onLanguageChanged() {
    if (mounted) {
      // Force rebuild to get new locale
      setState(() {});
    }
  }
  
  void _loadCurrentLanguage() {
    final currentLanguage = _languageService.languageCode == 'sw' 
        ? AppConstants.languageSwahili 
        : AppConstants.languageEnglish;
    if (selectedLanguage != currentLanguage) {
      selectedLanguage = currentLanguage;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use LanguageService to get current locale, ensuring we always have the latest
    final currentLocale = _languageService.currentLocale;
    // Get AppLocalizations from context first, fallback to creating new instance
    // When MaterialApp rebuilds with new locale, AppLocalizations.of(context) will return new locale
    final l10n = AppLocalizations.of(context) ?? AppLocalizations(currentLocale);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Ensure selectedLanguage matches current language from service
    _loadCurrentLanguage();
    
    return Scaffold(
      backgroundColor: isDark 
          ? const Color(0xFF121212)
          : const Color(0xFFF5F7FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section with animations
              Padding(
                padding: const EdgeInsets.fromLTRB(0.0, 16.0, 0.0, 32.0),
                child: Column(
                  children: [
                    FadeTransition(
                      opacity: _iconFadeAnimation,
                      child: ScaleTransition(
                        scale: _iconScaleAnimation,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.grey[800]!.withOpacity(0.3)
                                : const Color(0xFF2196F3).withOpacity(0.1),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: isDark
                                    ? Colors.black.withOpacity(0.2)
                                    : const Color(0xFF2196F3).withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.language_rounded,
                            size: 48,
                            color: isDark ? Colors.white : const Color(0xFF2196F3),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FadeTransition(
                      opacity: _titleFadeAnimation,
                      child: SlideTransition(
                        position: _titleSlideAnimation,
                        child: Text(
                          l10n.chooseLanguage,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.blue[300] : const Color(0xFF2196F3),
                            letterSpacing: -1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FadeTransition(
                      opacity: _subtitleFadeAnimation,
                      child: Text(
                        l10n.chooseLanguage,
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.blue[300] : const Color(0xFF1976D2),
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Language Options with staggered animations
              FadeTransition(
                opacity: _optionsFadeAnimation,
                child: Column(
                  children: [
                    _buildLanguageOption(
                      title: l10n.swahili,
                      subtitle: l10n.swahiliDesc,
                      value: AppConstants.languageSwahili,
                      index: 0,
                    ),
                    _buildLanguageOption(
                      title: l10n.english,
                      subtitle: l10n.englishDesc,
                      value: AppConstants.languageEnglish,
                      index: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Continue Button with animations
              FadeTransition(
                opacity: _buttonFadeAnimation,
                child: ScaleTransition(
                  scale: _buttonScaleAnimation,
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: selectedLanguage != null
                          ? const LinearGradient(
                              colors: [
                                Color(0xFF2196F3),
                                Color(0xFF1976D2),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: selectedLanguage == null
                          ? (isDark ? Colors.grey[800] : Colors.grey[300])
                          : null,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: selectedLanguage != null
                          ? [
                              BoxShadow(
                                color: const Color(0xFF2196F3).withOpacity(0.4),
                                blurRadius: 15,
                                offset: const Offset(0, 6),
                              ),
                            ]
                          : null,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: selectedLanguage == null
                            ? null
                            : () async {
                                final navigator = Navigator.of(context);
                                final selectedLang = selectedLanguage!;
                                
                                // Save language preference
                                await _languageService.setLanguage(selectedLang);
                                // Wait for MaterialApp to rebuild with new locale
                                await SchedulerBinding.instance.endOfFrame;
                                await Future.delayed(const Duration(milliseconds: 200));
                                // Force rebuild of current screen to show updated language
                                if (!mounted) return;
                                setState(() {});
                                // Wait one more frame before navigating
                                await SchedulerBinding.instance.endOfFrame;
                                if (!mounted) return;
                                // Navigate to next screen
                                navigator.push(
                                  MaterialPageRoute(
                                    builder: (context) => GenderSelectionScreen(
                                      language: selectedLang,
                                    ),
                                  ),
                                );
                              },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                l10n.continueText,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                  color: selectedLanguage != null
                                      ? Colors.white
                                      : (isDark ? Colors.grey[600] : Colors.grey[700]),
                                ),
                              ),
                              if (selectedLanguage != null) ...[
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption({
    required String title,
    required String subtitle,
    required String value,
    required int index,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = selectedLanguage == value;
    
    // Create delayed animation for each option
    final optionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _optionsController,
        curve: Interval(
          0.1 + (index * 0.4),
          0.6 + (index * 0.4),
          curve: Curves.easeOut,
        ),
      ),
    );
    
    return AnimatedBuilder(
      animation: optionAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - optionAnimation.value)),
          child: Opacity(
            opacity: optionAnimation.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.only(bottom: 16),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    // Update selected language first
                    setState(() {
                      selectedLanguage = value;
                    });
                    
                    // Immediately update language when selected - this triggers MaterialApp rebuild
                    await _languageService.setLanguage(value);
                    
                    // Force rebuild of this screen to reflect language change immediately
                    if (mounted) {
                      setState(() {});
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark
                              ? Colors.blue[800]!
                              : const Color(0xFF2196F3))
                          : (isDark ? Colors.grey[800] : Colors.white),
                      border: Border.all(
                        color: isSelected
                            ? (isDark
                                ? Colors.blue[600]!
                                : const Color(0xFF2196F3))
                            : (isDark
                                ? Colors.blue[700]!.withOpacity(0.3)
                                : Colors.blue[100]!),
                        width: isSelected ? 2.5 : 1.5,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF2196F3).withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark
                                    ? Colors.blue[600]!
                                    : Colors.white.withOpacity(0.3))
                                : (isDark
                                    ? Colors.blue[900]!.withOpacity(0.3)
                                    : const Color(0xFF2196F3).withOpacity(0.1)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.language_rounded,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.blue[300] : const Color(0xFF2196F3)),
                            size: 28,
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
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark ? Colors.white : Colors.grey[900]),
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                subtitle,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isSelected
                                      ? Colors.white.withOpacity(0.9)
                                      : (isDark ? Colors.grey[400] : Colors.grey[600]),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.blue[300]
                                  : Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check_rounded,
                              color: isDark
                                  ? Colors.blue[900]
                                  : const Color(0xFF2196F3),
                              size: 20,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

