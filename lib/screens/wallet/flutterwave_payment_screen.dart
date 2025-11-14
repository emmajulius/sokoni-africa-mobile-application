import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../services/wallet_service.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';

class FlutterwavePaymentScreen extends StatefulWidget {
  final String paymentUrl;
  final int transactionId;

  const FlutterwavePaymentScreen({
    super.key,
    required this.paymentUrl,
    required this.transactionId,
  });

  @override
  State<FlutterwavePaymentScreen> createState() => _FlutterwavePaymentScreenState();
}

class _FlutterwavePaymentScreenState extends State<FlutterwavePaymentScreen> {
  final WalletService _walletService = WalletService();
  late final WebViewController _webViewController;
  bool _isVerifying = false;
  bool _isLoadingPage = true;
  bool _hasCompletedFlow = false;
  bool _isOnFlutterwavePage = false;
  Timer? _cancelCheckTimer;

  @override
  void initState() {
    super.initState();
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (mounted) {
              setState(() => _isLoadingPage = true);
            }
            // Inject JavaScript IMMEDIATELY to block dialogs before Flutterwave's code runs
            _injectCancelInterceptor();
            // Check URL on page start
            _handleNavigation(url);
          },
          onPageFinished: (url) async {
            // Inject comprehensive JavaScript to intercept all cancel dialogs
            await _injectCancelInterceptor();
            
            // Check if we're on Flutterwave page
            final uri = Uri.tryParse(url);
            if (uri != null) {
              final host = uri.host.toLowerCase();
              final isFlutterwave = host.contains('flutterwave') || 
                                   host.contains('rave') ||
                                   host.contains('flw') ||
                                   url.contains('checkout-v3-ui');
              
              if (mounted) {
                setState(() {
                  _isOnFlutterwavePage = isFlutterwave;
                });
              }
              
              // Start polling for cancel actions if on Flutterwave page
              if (isFlutterwave && !_hasCompletedFlow) {
                _startCancelPolling();
              } else {
                _stopCancelPolling();
              }
            }
            
            // Check if cancel was clicked by evaluating JavaScript
            _checkForCancelAction();
            
            // Check URL after page finishes loading
            final handled = _handleNavigation(url);
            if (!handled && mounted) {
              setState(() => _isLoadingPage = false);
            }
          },
          onNavigationRequest: (navigation) {
            final url = navigation.url.toLowerCase();
            
            // Detect our special cancel URL
            if (url.contains('sokoni://cancel-payment') || url == 'sokoni://cancel-payment') {
              if (!_hasCompletedFlow) {
                // Show our custom dialog instead of navigating
                _showCancelPaymentDialog();
                return NavigationDecision.prevent;
              }
            }
            
            // If user is trying to navigate away from Flutterwave page
            // Show our custom dialog instead of browser's default
            if (!_hasCompletedFlow && navigation.isMainFrame) {
              final uri = Uri.tryParse(navigation.url);
              if (uri != null) {
                final host = uri.host.toLowerCase();
                final scheme = uri.scheme.toLowerCase();
                
                // Skip our special URLs and our backend callback
                if (scheme == 'sokoni' || scheme == 'http' || scheme == 'https') {
                  // Check if trying to navigate away from Flutterwave
                  final isFlutterwaveDomain = host.contains('flutterwave') || 
                                             host.contains('rave') ||
                                             host.contains('flw') ||
                                             navigation.url.contains('checkout-v3-ui');
                  final isOurBackend = host.contains('192.168.1.186') || 
                                      host.contains('localhost') ||
                                      host.contains('127.0.0.1') ||
                                      navigation.url.contains('/api/wallet/topup/callback');
                  
                  // If we're on Flutterwave and trying to navigate to non-backend URL
                  if (isFlutterwaveDomain && !isOurBackend && scheme != 'sokoni') {
                    // This might be a cancel action - show our dialog
                    _showCancelPaymentDialog();
                    return NavigationDecision.prevent;
                  }
                }
              }
            }
            
            final handled = _handleNavigation(navigation.url);
            if (handled) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onUrlChange: (urlChange) {
            // Monitor URL changes (catches redirects that NavigationDelegate might miss)
            if (urlChange.url != null && !_hasCompletedFlow) {
              final url = urlChange.url!.toLowerCase();
              // Check if URL contains our cancel indicator
              if (url.contains('sokoni-cancel') || 
                  url.contains('sokoni_cancel') ||
                  url.contains('#sokoni-cancel')) {
                _showCancelPaymentDialog();
                return;
              }
              // Also check for cancel flag via JavaScript
              _checkForCancelAction();
              _handleNavigation(urlChange.url!);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }
  
  Future<void> _injectCancelInterceptor() async {
    try {
      // Aggressive JavaScript to completely prevent browser dialogs
      // and intercept cancel actions before Flutterwave's code runs
      await _webViewController.runJavaScript('''
        (function() {
          console.log('🔒 Installing Flutterwave dialog blocker...');
          
          // IMMEDIATELY override confirm() and alert() before any other code runs
          // This must happen before Flutterwave's JavaScript loads
          // Block ALL dialogs to prevent browser from showing URL
          
          // Override confirm() - return false immediately (no dialog)
          var blockedConfirm = function(message) {
            console.log('🚫 BLOCKED confirm: ' + message);
            // Set cancel flag if it's a cancel-related message
            var msg = String(message || '').toLowerCase();
            if (msg.includes('cancel') || msg.includes('payment') || 
                msg.includes('sure') || msg.includes('want')) {
              window._flutterwaveCancelClicked = true;
            }
            return false; // Always return false - no dialog shown
          };
          
          window.confirm = blockedConfirm;
          Window.prototype.confirm = blockedConfirm;
          
          // Try to make it non-overridable (some browsers allow this)
          try {
            Object.defineProperty(window, 'confirm', {
              value: blockedConfirm,
              writable: false,
              configurable: false
            });
            Object.defineProperty(Window.prototype, 'confirm', {
              value: blockedConfirm,
              writable: false,
              configurable: false
            });
          } catch(e) {
            console.log('Could not make confirm non-overridable: ' + e);
          }
          
          // Also override alert() just in case
          window.alert = function(message) {
            console.log('🚫 BLOCKED alert: ' + message);
            // Don't show alert dialogs either
          };
          Window.prototype.alert = window.alert;
          
          // Completely remove beforeunload handler
          window.onbeforeunload = function() {
            return null; // Returning null prevents the dialog
          };
          
          // Override addEventListener to block beforeunload listeners
          var originalAddEventListener = EventTarget.prototype.addEventListener;
          EventTarget.prototype.addEventListener = function(type, listener, options) {
            if (type === 'beforeunload' || type === 'unload') {
              console.log('🚫 Blocked ' + type + ' listener');
              // Don't add the listener - this prevents the dialog
              return;
            }
            return originalAddEventListener.call(this, type, listener, options);
          };
          
          // Intercept ALL clicks at the document level using capture phase (runs FIRST)
          // This ensures we catch cancel buttons before Flutterwave's handlers
          document.addEventListener('click', function(e) {
            if (!e.target) return;
            
            // Check the clicked element and all its parents (up to 5 levels)
            var element = e.target;
            var maxDepth = 5;
            var depth = 0;
            
            while (element && depth < maxDepth) {
              // Get all text content from element and its children
              var text = (element.textContent || element.innerText || '').toLowerCase().trim();
              var className = String(element.className || '').toLowerCase();
              var id = String(element.id || '').toLowerCase();
              var ariaLabel = String(element.getAttribute('aria-label') || '').toLowerCase();
              var tagName = element.tagName || '';
              
              // Check if this element or its text suggests it's a cancel/close button
              var looksLikeCancel = (
                text.includes('cancel') || 
                text.includes('close') ||
                text === '×' || text === 'x' || text === '✕' ||
                className.includes('cancel') || 
                className.includes('close') ||
                id.includes('cancel') || 
                id.includes('close') ||
                ariaLabel.includes('cancel') || 
                ariaLabel.includes('close')
              );
              
              // Check if it's a clickable element
              var isClickable = (
                tagName === 'BUTTON' || 
                tagName === 'A' ||
                element.getAttribute('role') === 'button' ||
                element.onclick !== null ||
                element.getAttribute('onclick') !== null ||
                element.closest('button') !== null ||
                element.closest('a') !== null
              );
              
              if (looksLikeCancel && isClickable) {
                console.log('🚫 INTERCEPTED CANCEL BUTTON CLICK');
                // CRITICAL: Stop everything immediately - prevents Flutterwave's dialog
                e.stopImmediatePropagation();
                e.preventDefault();
                e.stopPropagation();
                
                // Set flag immediately so Flutter can detect it
                window._flutterwaveCancelClicked = true;
                window._cancelTimestamp = Date.now();
                
                console.log('✅ Cancel flag set, Flutter will detect it');
                return false;
              }
              
              element = element.parentElement;
              depth++;
            }
          }, true); // Capture phase - runs BEFORE any other handlers
          
          // Also monitor for dynamically added cancel buttons
          var observer = new MutationObserver(function() {
            // Re-scan for cancel buttons periodically
            document.querySelectorAll('button, a, [role="button"]').forEach(function(btn) {
              var text = (btn.textContent || '').toLowerCase();
              var className = (btn.className || '').toLowerCase();
              if (text.includes('cancel') || className.includes('cancel') ||
                  text.includes('close') || className.includes('close')) {
                // Ensure our click handler is attached (capture phase)
                btn.addEventListener('click', function(e) {
                  e.stopImmediatePropagation();
                  e.preventDefault();
                  window._userCancelled = true;
                  return false;
                }, true);
              }
            });
          });
          
          if (document.body) {
            observer.observe(document.body, { childList: true, subtree: true });
          }
          
          console.log('✅ Dialog blocker installed');
        })();
      ''');
      
      // Re-inject periodically to ensure it stays active and can't be overridden
      // Flutterwave might try to restore the original confirm() function
      Future.delayed(const Duration(milliseconds: 500), () async {
        if (mounted && !_hasCompletedFlow) {
          try {
            await _webViewController.runJavaScript('''
              window.confirm = function() { 
                window._flutterwaveCancelClicked = true;
                return false; 
              };
              Window.prototype.confirm = window.confirm;
              window.onbeforeunload = function() { return null; };
            ''');
          } catch (e) {
            // Ignore
          }
        }
      });
      
      // Re-inject after 1 second to catch scripts that load late
      Future.delayed(const Duration(seconds: 1), () async {
        if (mounted && !_hasCompletedFlow) {
          try {
            await _webViewController.runJavaScript('''
              window.confirm = function() { 
                window._flutterwaveCancelClicked = true;
                return false; 
              };
              Window.prototype.confirm = window.confirm;
            ''');
          } catch (e) {
            // Ignore
          }
        }
      });
      
      // Re-inject after 2 seconds to ensure it stays active
      Future.delayed(const Duration(seconds: 2), () async {
        if (mounted && !_hasCompletedFlow && _isOnFlutterwavePage) {
          await _injectCancelInterceptor();
        }
      });
    } catch (e) {
      print('JavaScript injection error: $e');
    }
  }
  
  void _startCancelPolling() {
    _stopCancelPolling(); // Stop any existing timer
    if (_hasCompletedFlow) return;
    
    // Poll every 200ms to check for cancel action - faster detection
    _cancelCheckTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) async {
      if (_hasCompletedFlow || !mounted) {
        _stopCancelPolling();
        return;
      }
      await _checkForCancelAction();
    });
  }
  
  void _stopCancelPolling() {
    _cancelCheckTimer?.cancel();
    _cancelCheckTimer = null;
  }
  
  Future<void> _checkForCancelAction() async {
    if (_hasCompletedFlow || !mounted) return;
    
    try {
      // Check if cancel was clicked by evaluating JavaScript
      final result = await _webViewController.runJavaScriptReturningResult(
        'window._flutterwaveCancelClicked === true ? "cancel" : "no"'
      );
      
      if (result.toString().contains('cancel')) {
        // Reset the flag
        await _webViewController.runJavaScript('window._flutterwaveCancelClicked = false;');
        // Stop polling
        _stopCancelPolling();
        // Show our dialog
        if (mounted && !_hasCompletedFlow) {
          _showCancelPaymentDialog();
        }
      }
    } catch (e) {
      // Ignore errors - JavaScript might not be ready
    }
  }
  
  void _showCancelPaymentDialog() {
    if (_hasCompletedFlow) return;
    
    // Stop polling when showing dialog
    _stopCancelPolling();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: const Text(
          'Are you sure you want to cancel this payment.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Resume polling if still on Flutterwave page
              if (_isOnFlutterwavePage && !_hasCompletedFlow) {
                _startCancelPolling();
              }
            },
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, false);
              _hasCompletedFlow = true;
              _stopCancelPolling();
            },
            child: const Text('Yes', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _stopCancelPolling();
    super.dispose();
  }

  bool _handleNavigation(String url) {
    if (_hasCompletedFlow) return false;
    
    try {
      final uri = Uri.parse(url);
      final host = uri.host.toLowerCase();
      final path = uri.path.toLowerCase();
      
      // Get our backend base URL host
      final backendUri = Uri.parse(AppConstants.baseUrl);
      final backendHost = backendUri.host.toLowerCase();
      final backendAuthority = backendUri.authority.toLowerCase(); // includes port if specified
      
      // Check if this is our backend URL (not Flutterwave)
      // Match by host or full authority (host:port)
      final isOurBackend = host == backendHost || 
                          uri.authority.toLowerCase() == backendAuthority ||
                          (backendUri.hasPort && uri.hasPort && 
                           uri.port == backendUri.port && host == backendHost);
      
      // Check if this is Flutterwave domain (we should NOT process these)
      final isFlutterwaveDomain = host.contains('flutterwave') || 
                                   host.contains('rave') ||
                                   host.contains('flw');
      
      // Only process if it's our backend, not Flutterwave
      if (isFlutterwaveDomain) {
        // Still on Flutterwave - just update loading state, don't do anything else
        if (mounted) {
          setState(() {
            _isLoadingPage = false;
          });
        }
        return false; // Allow navigation to continue
      }
      
      // Check for callback URL pattern on OUR backend only
      final isCallbackUrl = isOurBackend && 
          (path.contains('/api/wallet/topup/callback') ||
           path.contains('/wallet/topup/callback'));
      
      if (!isCallbackUrl) {
        // Not on callback URL yet - just update loading state
        if (mounted) {
          setState(() {
            _isLoadingPage = false;
          });
        }
        return false;
      }
      
      // We're on our backend callback URL - check status
      final queryParams = uri.queryParameters;
      final status = queryParams['status']?.toLowerCase() ?? '';
      
      if (status == 'successful' || status == 'success') {
        // Payment successful - verify payment (but don't mark as completed yet)
        if (mounted) {
          setState(() {
            _isLoadingPage = false;
          });
        }
        // Give backend a moment to process the callback, then verify
        Future.delayed(const Duration(seconds: 2), () {
          _verifyPaymentWithRetry();
        });
        return false; // Allow the page to load to show success message
      } else if (status == 'cancelled' || status == 'canceled') {
        // Payment cancelled
        _hasCompletedFlow = true;
        if (mounted) {
          setState(() {
            _isLoadingPage = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment cancelled.'),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.pop(context, false);
        }
        return true;
      } else if (status == 'failed') {
        // Payment failed
        _hasCompletedFlow = true;
        if (mounted) {
          setState(() {
            _isLoadingPage = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment failed. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.pop(context, false);
        }
        return true;
      } else {
        // Callback URL but no clear status - might be pending
        if (mounted) {
          setState(() {
            _isLoadingPage = false;
          });
        }
        // Don't mark as completed - payment might still be processing
        return false;
      }
    } catch (e) {
      // URL parsing failed - just allow navigation
      print('Error parsing URL: $e');
      if (mounted) {
        setState(() {
          _isLoadingPage = false;
        });
      }
      return false;
    }
  }

  Future<void> _verifyPaymentWithRetry({int maxRetries = 5, int delaySeconds = 3}) async {
    if (_isVerifying) return;
    setState(() => _isVerifying = true);

    try {
      final authService = AuthService();
      await authService.initialize();

      if (authService.authToken == null) {
        throw Exception('Please log in to verify payment');
      }

      // Try verification with retries
      bool verified = false;
      Map<String, dynamic>? lastResult;
      
      for (int attempt = 0; attempt < maxRetries; attempt++) {
        if (attempt > 0) {
          // Wait before retrying
          await Future.delayed(Duration(seconds: delaySeconds));
        }
        
        try {
          lastResult = await _walletService.verifyTopup(widget.transactionId);
          
          if (lastResult['success'] == true) {
            verified = true;
            break;
          }
          
          // If transaction is already completed but verification returned false,
          // check if it's a different error
          final message = lastResult['message']?.toString().toLowerCase() ?? '';
          if (message.contains('already completed') || message.contains('transaction already')) {
            verified = true;
            break;
          }
        } catch (e) {
          // If it's not the last attempt, continue retrying
          if (attempt < maxRetries - 1) {
            continue;
          }
          // Last attempt failed, rethrow
          rethrow;
        }
      }

      if (verified && mounted) {
        // Only mark as completed AFTER successful verification
        _hasCompletedFlow = true;
        _stopCancelPolling(); // Stop polling when verified
        setState(() {
          _isVerifying = false;
        });
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(lastResult?['message'] ?? 'Payment verified successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else if (mounted) {
        // Verification failed after retries, but payment might still be processing
        // Don't mark as completed - allow user to retry verification
        setState(() {
          _isVerifying = false;
          // Keep _hasCompletedFlow as false so user can retry
        });
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Payment Processing'),
            content: const Text(
              'Your payment is being processed. Please check your wallet balance in a few moments.\n\n'
              'If the amount is not credited within 5 minutes, please contact support.\n\n'
              'You can also use the "Verify Payment" button to check the status again.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog only, keep payment screen open
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVerifying = false;
          // Don't set _hasCompletedFlow - allow user to retry verification
        });

        String errorMessage = e.toString();
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring(11);
        }

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Verification Failed'),
            content: Text(
              errorMessage.contains('Authorization') || errorMessage.contains('not authenticated')
                  ? 'Please log in again to verify payment. Your payment may still be processing.\n\nYou can use the "Verify Payment" button to retry.'
                  : 'Verification failed: $errorMessage\n\nNote: Your payment may still be processing. Please check your wallet balance or use the "Verify Payment" button to try again.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog only, keep payment screen open
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _hasCompletedFlow,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (!didPop && !_hasCompletedFlow) {
          _showCancelPaymentDialog();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Complete Payment'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _showCancelPaymentDialog,
          ),
        actions: [
          if (!_isVerifying && !_hasCompletedFlow)
            TextButton.icon(
              onPressed: _verifyPaymentWithRetry,
              icon: const Icon(Icons.check_circle, size: 18),
              label: const Text('Verify Payment'),
            ),
          if (_isVerifying)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _webViewController),
            if (_isLoadingPage)
              const Center(
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}
