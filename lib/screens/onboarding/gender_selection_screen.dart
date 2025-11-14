import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../services/language_service.dart';
import '../auth/login_screen.dart';

class GenderSelectionScreen extends StatefulWidget {
  final String language;

  const GenderSelectionScreen({
    super.key,
    required this.language,
  });

  @override
  State<GenderSelectionScreen> createState() => _GenderSelectionScreenState();
}

class _GenderSelectionScreenState extends State<GenderSelectionScreen> with TickerProviderStateMixin {
  String? selectedGender;
  final LanguageService _languageService = LanguageService();
  
  late AnimationController _headerController;
  late AnimationController _bannerController;
  late AnimationController _optionsController;
  late AnimationController _buttonController;
  
  // Header animations
  late Animation<double> _iconFadeAnimation;
  late Animation<double> _iconScaleAnimation;
  late Animation<double> _titleFadeAnimation;
  late Animation<Offset> _titleSlideAnimation;
  late Animation<double> _subtitleFadeAnimation;
  
  // Banner animations
  late Animation<double> _bannerFadeAnimation;
  late Animation<Offset> _bannerSlideAnimation;
  
  // Options animations
  late Animation<double> _optionsFadeAnimation;
  
  // Button animations
  late Animation<double> _buttonFadeAnimation;
  late Animation<double> _buttonScaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _languageService.addListener(_onLanguageChanged);
    
    // Initialize animation controllers
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _bannerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
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
    
    // Banner animations
    _bannerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _bannerController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOut),
      ),
    );
    
    _bannerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _bannerController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOut),
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
      if (mounted) _bannerController.forward();
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _optionsController.forward();
    });
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) _buttonController.forward();
    });
  }
  
  @override
  void dispose() {
    _headerController.dispose();
    _bannerController.dispose();
    _optionsController.dispose();
    _buttonController.dispose();
    _languageService.removeListener(_onLanguageChanged);
    super.dispose();
  }
  
  void _onLanguageChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? 
                 AppLocalizations(_languageService.currentLocale);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
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
                            Icons.person_outline_rounded,
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
                          l10n.selectYourGender,
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
                        'Please select your gender',
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
              const SizedBox(height: 16),
              // Info Banner with animations
              FadeTransition(
                opacity: _bannerFadeAnimation,
                child: SlideTransition(
                  position: _bannerSlideAnimation,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.orange[900]!.withOpacity(0.2)
                          : Colors.orange[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? Colors.orange[700]!.withOpacity(0.3)
                            : Colors.orange[200]!,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 20,
                          color: isDark ? Colors.orange[300] : Colors.orange[700],
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'NOTE: Our app does not support LGBTQ activities',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.orange[200] : Colors.orange[900],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Gender Options with staggered animations
              FadeTransition(
                opacity: _optionsFadeAnimation,
                child: Column(
                  children: [
                    _buildGenderOption(
                      title: l10n.ladiesGirls,
                      subtitle: l10n.ladiesDesc,
                      value: AppConstants.genderFemale,
                      icon: Icons.woman_rounded,
                      index: 0,
                    ),
                    _buildGenderOption(
                      title: l10n.gentsBoys,
                      subtitle: l10n.gentsDesc,
                      value: AppConstants.genderMale,
                      icon: Icons.man_rounded,
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
                      gradient: selectedGender != null
                          ? const LinearGradient(
                              colors: [
                                Color(0xFF2196F3),
                                Color(0xFF1976D2),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: selectedGender == null
                          ? (isDark ? Colors.grey[800] : Colors.grey[300])
                          : null,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: selectedGender != null
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
                        onTap: selectedGender == null
                            ? null
                            : () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LoginScreen(
                                      gender: selectedGender!,
                                      language: widget.language,
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
                                  color: selectedGender != null
                                      ? Colors.white
                                      : (isDark ? Colors.grey[600] : Colors.grey[700]),
                                ),
                              ),
                              if (selectedGender != null) ...[
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

  Widget _buildGenderOption({
    required String title,
    required String subtitle,
    required String value,
    required IconData icon,
    required int index,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = selectedGender == value;
    
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
                  onTap: () {
                    setState(() {
                      selectedGender = value;
                    });
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
                            icon,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.blue[300] : const Color(0xFF2196F3)),
                            size: 32,
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

