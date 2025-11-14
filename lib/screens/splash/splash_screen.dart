import 'package:flutter/material.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  final Widget child;
  final VoidCallback onComplete;

  const SplashScreen({
    super.key,
    required this.child,
    required this.onComplete,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _cursorController;
  late Animation<double> _cursorOpacity;
  
  String _displayText = '';
  final String _fullText = 'Connecting Africa Through Trade and Trust';
  int _currentIndex = 0;
  Timer? _typingTimer;
  Timer? _finishTimer;
  Timer? _safetyTimer;
  bool _typingComplete = false;

  @override
  void initState() {
    super.initState();
    
    _cursorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    
    _cursorOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cursorController,
      curve: Curves.easeInOut,
    ));
    
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _startTypingAnimation();
      }
    });

    // Safety timer in case typing animation fails to complete
    _safetyTimer = Timer(const Duration(seconds: 8), () {
      if (mounted) {
        widget.onComplete();
      }
    });
  }

  void _startTypingAnimation() {
    const typingInterval = Duration(milliseconds: 70);
    _typingTimer = Timer.periodic(typingInterval, (timer) {
      if (_currentIndex < _fullText.length) {
        setState(() {
          _displayText = _fullText.substring(0, _currentIndex + 1);
          _currentIndex++;
        });
      } else {
        timer.cancel();
        _cursorController.stop();
        setState(() {
          _typingComplete = true;
        });
        _scheduleFinish();
      }
    });
  }

  void _scheduleFinish() {
    if (_finishTimer != null) return;
    _finishTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) {
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _finishTimer?.cancel();
    _safetyTimer?.cancel();
    _cursorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    
    // Calculate responsive dimensions
    // Use 95% of width, but ensure height is appropriate for the image aspect ratio
    final containerWidth = screenWidth * 0.95;
    // Reserve less space for animated text at bottom to increase image height
    // Ensure we never have negative height
    final reservedSpace = 120.0;
    final availableHeight = (screenHeight - reservedSpace).clamp(0.0, double.infinity);
    final containerHeight = availableHeight > screenHeight * 0.95 
        ? screenHeight * 0.95 
        : availableHeight;
    
    // Ensure containerHeight is always positive
    final safeContainerHeight = containerHeight.clamp(0.0, screenHeight);
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // Splash image centered (from splash2.jpeg) - responsive size with white background
              Center(
                child: Container(
                  width: containerWidth,
                  height: safeContainerHeight,
                  color: Colors.white, // White background to match splash screen
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: (screenHeight * 0.08).clamp(0.0, safeContainerHeight * 0.5), // Safe padding that won't exceed container height
                    ),
                    child: Image.asset(
                      'assets/images/splash.png',
                      fit: BoxFit.contain, // Maintains aspect ratio, fits within container
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
              ),
              // Animated text below the image - responsive positioning
              Positioned(
                bottom: screenHeight * 0.15, // Moved text up (15% from bottom instead of 10%)
                left: 0,
                right: 0,
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.06, // Responsive horizontal padding (6% of width)
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Typing text with blinking cursor - beautiful animation
                        AnimatedBuilder(
                          animation: _cursorOpacity,
                          builder: (context, child) {
                            final cursorOpacity = _cursorOpacity.value.clamp(0.0, 1.0);
                            // Responsive font size based on screen width
                            final fontSize = screenWidth < 400 
                                ? 18.0  // Small screens
                                : screenWidth < 600 
                                    ? 20.0  // Medium screens
                                    : 22.0; // Large screens
                            
                            return RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: _displayText,
                                    style: TextStyle(
                                      fontSize: fontSize,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                      letterSpacing: 1.0,
                                      height: 1.6,
                                      shadows: [
                                        Shadow(
                                          offset: const Offset(0, 1),
                                          blurRadius: 2,
                                          color: Colors.blue.withOpacity(0.2),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Blinking cursor
                                  if (!_typingComplete)
                                    TextSpan(
                                      text: '|',
                                      style: TextStyle(
                                        fontSize: fontSize,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF4A90E2).withOpacity(cursorOpacity),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                        // Subtle underline effect for completed text
                        if (_typingComplete)
                          TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeOut,
                            builder: (context, value, child) {
                              final clampedValue = value.clamp(0.0, 1.0);
                              return Opacity(
                                opacity: clampedValue,
                                child: Container(
                                  margin: const EdgeInsets.only(top: 12),
                                  height: 3,
                                  width: screenWidth * 0.4 * clampedValue, // Responsive width
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFF4A90E2).withOpacity(0.2),
                                        const Color(0xFF4A90E2),
                                        const Color(0xFF4A90E2).withOpacity(0.2),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF4A90E2).withOpacity(0.3),
                                        blurRadius: 4,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
