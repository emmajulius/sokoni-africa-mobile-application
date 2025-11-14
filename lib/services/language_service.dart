import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../utils/constants.dart';

class AppLocalizations {
  final Locale locale;
  
  AppLocalizations(this.locale);
  
  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }
  
  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();
  
  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // Onboarding
      'selectLanguage': 'Select Language',
      'chooseLanguage': 'Choose your preferred language',
      'swahili': 'Swahili',
      'swahiliDesc': 'Kama ni mswahili chagua hii',
      'english': 'English',
      'englishDesc': 'For english speakers only',
      'continue': 'Continue',
      'getStarted': 'Get Started',
      
      // Gender Selection
      'selectGender': 'Select Gender',
      'selectYourGender': 'Select your gender',
      'ladiesGirls': 'Ladies / Girls',
      'ladiesDesc': 'Select this if you are a Woman / Girl',
      'gentsBoys': 'Gents / Boys',
      'gentsDesc': 'Select this if you are a Man / Boy',
      
      // User Type
      'selectAccountType': 'Select Account Type',
      'howToUseSokoni': 'How would you like to use Sokoni?',
      'sokoniClient': 'Sokoni Client',
      'clientDesc': 'Buy from Anyone without Selling',
      'sokoniSupplier': 'Sokoni Supplier',
      'supplierDesc': 'Sell to Anyone without Buying',
      'sokoniRetailer': 'Sokoni Retailer',
      'retailerDesc': 'Buy from Suppliers, Sell to Clients',
      
      // Login
      'welcomeAboard': 'Welcome Aboard',
      'selectHowToContinue': 'Please Select how you\'d like to continue',
      'termsNote': 'We assume you have read and understood our Terms & Conditions & Privacy Policy',
      'google': 'Google',
      'or': 'OR',
      'phoneNumberHint': 'Please enter a valid Phone number in the input below, We\'ll alert you if the number is used by someone else.',
      'phoneNumber': 'Phone Number',
      'continueAsGuest': 'Continue as Guest',
      'loggedInAsGuest': 'Logged in as guest',
      'guestLoginFailed': 'Guest login failed',
      'signIn': 'Sign In',
      'username': 'Username',
      'usernameOrEmail': 'Username or Email',
      'enterUsernameOrEmail': 'Enter username or email',
      'password': 'Password',
      'enterPassword': 'Enter password',
      'forgotPassword': 'Forgot Password?',
      'dontHaveAccount': 'Don\'t have an account?',
      'signUp': 'Sign Up',
      'loginSuccessful': 'Login successful!',
      'welcomeUser': 'Welcome, {name}!',
      'startingGoogleSignIn': 'Starting Google Sign-In...',
      'googleSignInFailed': 'Google Sign-In failed',
      'googleAccountAlreadyRegistered': 'This Google account is already registered. Please use regular login.',
      'usernameAlreadyTaken': 'Username already taken. Please contact support.',
      'accountAlreadyExists': 'Account already exists. Please use regular login.',
      'connectionError': 'Connection error. Please check your internet connection and try again.',
      'googleAuthFailed': 'Google authentication failed. The token may have expired. Please try signing in again.',
      'googleSignInConfigError': 'Google Sign-In configuration error.',
      'serverError': 'Server error. Please try again later.',
      'googleSignInFailedTryAgain': 'Google Sign-In failed. Please try again or use regular login.',
      'googleSignInNetworkTitle': 'Stable connection needed',
      'googleSignInNetworkMessageSignIn': 'A stable network connection is required for Google sign in. Please check your internet connection and try again, or use the normal sign in option instead.',
      'googleSignInNetworkMessageSignUp': 'A stable network connection is required for Google sign up. Please check your internet connection and try again, or use the normal sign up option instead.',
      'useNormalSignIn': 'Use normal sign in',
      'useNormalSignUp': 'Use normal sign up',
      'googleSignInSetupRequired': 'Google Sign-In Setup Required',
      'ok': 'OK',
      'completeGoogleSignIn': 'To complete your Google sign-in, please select how you want to use Sokoni Africa.',
      'buyer': 'Buyer',
      'seller': 'Seller',
      'both': 'Both',
      'userTypeNotFound': 'User type not found in account. Please contact support.',
      'failedToGetGoogleToken': 'Failed to get Google authentication token. Please try signing in again.',
      'googleSignInNotConfigured': 'Google Sign-In is not configured for this platform. Update AppConstants.googleClientIdWeb and the meta tag in web/index.html.',
      'pleaseEnterUsername': 'Please enter a username',
      'usernameTooShort': 'Username must be at least 3 characters',
      'pleaseEnterPassword': 'Please enter a password',
      'passwordTooShort': 'Password must be at least 6 characters',
      'invalidCredentials': 'Invalid credentials. Please check your username and password.',
      'loginFailed': 'Login failed. Please try again.',
      'welcomeBack': 'Welcome Back!',
      'signInToContinueShopping': 'Sign in to continue shopping',
      'usernameEmailOrPhone': 'Username, Email, or Phone',
      'enterUsernameEmailOrPhone': 'Enter username, email, or phone',
      'pleaseEnterUsernameEmailOrPhone': 'Please enter your username, email, or phone',
      'enterYourPassword': 'Enter your password',
      'pleaseEnterYourPassword': 'Please enter your password',
      'passwordMustBeAtLeast6': 'Password must be at least 6 characters',
      'passwordMustBe72OrLess': 'Password must be 72 characters or less',
      'continueWithGoogle': 'Continue with Google',
      'googleSignInUnavailable': 'Google Sign-In Unavailable',
      'accountDoesntHavePassword': 'This account doesn\'t have a password. Please use Google Sign-In or reset your password.',
      'incorrectCredentials': 'Incorrect username, email, phone, or password. Please check your credentials and try again.',
      'userNotFound': 'User not found. Please check your username, email, or phone number, or sign up for a new account.',
      'accountInactive': 'Your account is inactive. Please contact support.',
      'connectionTimeout': 'Connection timeout. Please check your internet connection and try again.',
      'networkError': 'Network error. Please check your internet connection and try again.',
      'loginFailedTitle': 'Login Failed',
      'googleSignInConfigErrorDetails': 'Please check:\n1. Client ID is set in web/index.html\n2. Client ID is correct (not the placeholder)\n3. Redirect URI is configured in Google Console\n4. Your app URL is in authorized JavaScript origins',
      
      // Phone Verification
      'weFlexSecurity': 'We Flex Security',
      'provideOTP': 'Please provide the OTP that was sent to your number',
      'sentTo': 'Sent to',
      'didntReceiveCode': 'Didn\'t receive code?',
      'resendOTP': 'Resend OTP',
      'changePhoneNumber': 'Change Phone Number',
      'verifyPhone': 'Verify Phone',
      
      // Main Navigation
      'home': 'Home',
      'search': 'Search',
      'cart': 'Cart',
      'inventory': 'Inventory',
      'messages': 'Messages',
      'profile': 'Profile',
      
      // Feed
      'sokoniAfrica': 'Sokoni Africa',
      'testAPI': 'Test API',
      'noProductsFound': 'No products found',
      'retry': 'Retry',
      'discoverAndShop': 'Discover & Shop',
      'discoverRealProducts': 'Discover real products straight from African sellers.\nNo stress, just pure hustle vibes.',
      'secure': 'Secure',
      'fastDelivery': 'Fast Delivery',
      'trusted': 'Trusted',
      'all': 'All',
      'electronics': 'Electronics',
      'fashion': 'Fashion',
      'food': 'Food',
      'beauty': 'Beauty',
      'homeKitchen': 'Home/Kitchen',
      'sports': 'Sports',
      'automotives': 'Automotives',
      'books': 'Books',
      'kids': 'Kids',
      'agriculture': 'Agriculture',
      'artCraft': 'Art/Craft',
      'computerSoftware': 'Computer/Software',
      'healthWellness': 'Health/Wellness',
      'unableToGetLocation': 'Unable to get your location. Please enable location services.',
      'errorGettingLocation': 'Error getting location',
      'locationPermissionRequired': 'Location Permission Required',
      'locationPermissionMessage': 'To show products near you, we need access to your location. Please enable location permissions in your device settings.',
      'openSettings': 'Open Settings',
      'errorLoadingProducts': 'Error loading products',
      'enableLocationBasedSorting': 'Enable location-based sorting',
      'disableLocationBasedSorting': 'Disable location-based sorting',
      
      // Product Detail
      'addToCart': 'Add to Cart',
      'messageSeller': 'Message Seller',
      'follow': 'Follow',
      'description': 'Description',
      'price': 'Price',
      'category': 'Category',
      'location': 'Location',
      'signInRequired': 'Sign In Required',
      'signInToAction': 'You need to sign in to {action}. Would you like to sign in now?',
      'cancel': 'Cancel',
      'likes': 'Likes',
      'comments': 'Comments',
      'rating': 'Rating',
      'productAddedToCart': 'Product added to cart successfully🎉',
      
      // Cart
      'cartNotAvailable': 'Cart Not Available',
      'cartNotAvailableMsg': 'As a {type}, you can only sell products, not buy them.',
      'cartEmpty': 'Your cart is empty',
      'selectedTotal': 'Selected Total',
      'shipping': 'Shipping',
      'tax': 'Tax',
      'discount': 'Discount',
      'totalAmount': 'Total Amount',
      'checkout': 'Checkout',
      'supplier': 'Supplier',
      'user': 'User',
      
      // Search
      'searchProducts': 'Search products...',
      'searchForProducts': 'Search for products',
      'showingResults': '112k Results\nShowing Results for "Search Query"',
      
      // Profile
      'guestUser': 'Guest User',
      'browseAsGuest': 'Browse as guest',
      'signInToContinue': 'Sign In to Continue',
      'followers': 'followers',
      'soldProducts': 'sold products',
      'myInventory': 'My Inventory',
      'inventoryDesc': 'View, Create & Manage Your Products',
      'customerOrders': 'Customer Orders',
      'customerOrdersDesc': 'View and manage orders from your customers',
      'myOrders': 'My Orders',
      'myOrdersDesc': 'View and manage your purchase orders',
      'walletPayment': 'Wallet & Payment Methods',
      'walletDesc': 'Manage your saved payment methods',
      'myAddresses': 'My Addresses',
      'addressesDesc': 'View and manage your saved shipping addresses',
      'settings': 'Settings',
      'settingsDesc': 'Manage your account settings',
      'manageAccountPreferences': 'Manage your account preferences',
      'personalInformation': 'Personal Information',
      'updatePersonalDetails': 'Update your personal details like name, username, email, and phone number to keep your account information current.',
      'updateProfile': 'Update Profile',
      'businessInformation': 'Business Information',
      'updateBusinessDetails': 'Update your Business details like Shop Name, Shop Type, to keep your account information current.',
      'updateBusinessDetailsTitle': 'Update Business Details',
      'updateBusinessDetailsSubtitle': 'Update your Business details like Shop Name, Shop Type, to keep your account information current.',
      'setPickupLocation': 'Set Pickup Location',
      'setPickupLocationSubtitle': 'Set your business location for shipping. Buyers can use Sokoni Africa Logistics if location is set.',
      'setPickupLocationDesc': 'Set your business location for shipping. Buyers can use Sokoni Africa Logistics if location is set.',
      'general': 'General',
      'salesAnalytics': 'Sales Analytics',
      'notification': 'Notification',
      'notifications': 'Notifications',
      'unreadNotificationsCount': '{count} unread notification',
      'allCaughtUp': 'All caught up!',
      'loadingNotifications': 'Loading notifications...',
      'noNotificationsYet': 'No notifications yet',
      'youreAllCaughtUp': 'You\'re all caught up!',
      'markAllAsRead': 'Mark all as read',
      'deleteAll': 'Delete all',
      'deleteNotification': 'Delete Notification',
      'areYouSureDeleteNotification': 'Are you sure you want to delete this notification?',
      'notificationDeleted': 'Notification deleted',
      'errorDeletingNotification': 'Error deleting notification',
      'deleteAllNotifications': 'Delete All Notifications',
      'areYouSureDeleteAllNotifications': 'Are you sure you want to delete all {count} notifications? This action cannot be undone.',
      'deletedNotificationsCount': 'Deleted {count} notification(s)',
      'errorDeletingNotifications': 'Error deleting notifications',
      'errorLoadingNotifications': 'Error loading notifications',
      'errorMarkingAllAsRead': 'Error marking all as read',
      'errorLoadingProduct': 'Error loading product',
      'pleaseSignInToFollowUsers': 'Please sign in to follow users',
      'youAreNowFollowing': 'You are now following {username}',
      'youUnfollowed': 'You unfollowed {username}',
      'failedToFollow': 'Failed to follow',
      'following': 'Following',
      'readMore': 'Read more',
      'readLess': 'Read less',
      'activityNotifications': 'Activity Notifications',
      'enableDisablePushNotifications': 'Enable or disable push notifications for real-time updates',
      'activityNotificationsEnabled': 'Activity notifications enabled',
      'activityNotificationsDisabled': 'Activity notifications disabled',
      'promotionsOffers': 'Promotions & Offers',
      'getPushNotificationsForOffers': 'Get push notifications whenever there are offers',
      'promotionsNotificationsEnabled': 'Promotions notifications enabled',
      'promotionsNotificationsDisabled': 'Promotions notifications disabled',
      'directEmailNotification': 'Direct Email Notification',
      'getNotifiedViaEmail': 'Get notified via email for important account activities',
      'emailNotificationsEnabled': 'Email notifications enabled',
      'emailNotificationsDisabled': 'Email notifications disabled',
      'appearancePreferences': 'Appearance & Preferences',
      'darkMode': 'Dark Mode',
      'reduceEyeStrain': 'Reduce eye strain and improve readability',
      'darkModeEnabled': 'Dark mode enabled',
      'darkModeDisabled': 'Dark mode disabled',
      'languageRegion': 'Language & Region',
      'accountSupport': 'Account & Support',
      'kycAccountVerification': 'KYC & Account Verification',
      'helpCenter': 'Help Center',
      'reportProblem': 'Report a Problem',
      'termsPrivacy': 'Terms & Privacy',
      'logOut': 'Log Out',
      'areYouSureLogOut': 'Are you sure you want to log out?',
      'failedToUpdateSetting': 'Failed to update setting. Please try again.',
      'signInToUnlock': 'Sign in to unlock all features',
      'signInMessage': 'Create an account to add items to cart, make purchases, manage orders, and more.',
      'signInNow': 'Sign In Now',
      
      // Inventory
      'manageYourProducts': 'Manage your products',
      'totalProducts': 'Total Products',
      'active': 'Active',
      'pending': 'Pending',
      'createProduct': 'Create Product',
      'createYourFirstProduct': 'Create your first product to get started',
      'deleteProduct': 'Delete Product',
      'areYouSureDeleteProduct': 'Are you sure you want to delete "{product}"? This action cannot be undone.',
      'productDeleted': 'Product deleted successfully',
      'failedToDeleteProduct': 'Failed to delete product',
      'noProductsYet': 'No products yet',
      'addYourFirstProduct': 'Add your first product to start selling',
      'addProduct': 'Add Product',
      'delete': 'Delete',
      
      // Customer Orders
      'manageOrdersFromCustomers': 'Manage orders from your customers',
      'pleaseLogInSellerAccount': 'Please log in with a seller account to view customer orders.',
      'onlySellersCanView': 'Only sellers can view customer orders.',
      'failedToInitialiseCustomerOrders': 'Failed to initialise customer orders: {error}',
      'invalidOrderIdentifier': 'Invalid order identifier. Please refresh the screen.',
      'statusUpdatedTo': 'Status updated to {status}',
      'unableToUpdateStatus': 'Unable to update status: {error}',
      'unableToLoadCustomerOrders': 'Unable to load customer orders',
      'sellerAccessRequired': 'Seller access required',
      'noCustomerOrdersYet': 'No customer orders yet',
      'whenBuyersPlaceOrders': 'When buyers place orders for your products they will appear here.',
      'switchToSellerAccount': 'Switch to a seller account to manage customer orders and keep buyers updated.',
      'tryAgain': 'Try again',
      'refreshOrders': 'Refresh orders',
      'checkAgain': 'Check again',
      'order': 'Order',
      'item': 'item',
      'items': 'items',
      'accept': 'Accept',
      'reject': 'Reject',
      'markAsShipped': 'Mark as Shipped',
      'awaitingDeliveryConfirmation': 'Awaiting delivery confirmation',
      'noItemsAttachedToOrder': 'No items attached to this order.',
      'moreItem': 'more item',
      'moreItems': 'more items',
      
      // My Orders
      'trackAndManagePurchases': 'Track and manage your purchases',
      'orderHistoryOnlyForRegistered': 'Order history is only available for registered users.',
      'unableToLoadOrders': 'Unable to load your orders',
      'somethingWentWrong': 'Something went wrong. Please try again.',
      'noOrdersYet': 'No orders yet',
      'browseProductsAndPlaceOrder': 'Browse products and place an order to see it here.',
      'product': 'Product',
      'products': 'Products',
      'shippingTo': 'Shipping to:',
      'viewDetails': 'View Details',
      'track': 'Track',
      'trackingUpdatesAvailableSoon': 'Tracking updates will be available soon.',
      'placedOn': 'Placed on',
      'payment': 'Payment',
      'subtotal': 'Subtotal',
      'total': 'Total',
      'confirmDelivery': 'Confirm Delivery',
      'confirming': 'Confirming...',
      'invalidOrderIdentifierRefresh': 'Invalid order identifier. Please refresh and try again.',
      'thanksDeliveryConfirmed': 'Thanks! Delivery confirmed and payment released to the seller.',
      'failedToConfirmDelivery': 'Failed to confirm delivery: {error}',
      'qty': 'Qty:',
      'noItemsAvailable': 'No items available',
      
      // Wallet
      'wallet': 'Wallet',
      'walletPaymentMethods': 'Wallet & Payment Methods',
      'manageYourWallet': 'Manage your wallet balance and transactions',
      'walletOnlyForRegistered': 'Wallet is only available for registered users. Please sign in to continue.',
      'unableToConnectToServer': 'Unable to connect to server. Please check your internet connection and ensure the backend server is running.',
      'walletEndpointNotFound': 'Wallet endpoint not found. Please ensure the backend server is updated.',
      'serverErrorWalletTables': 'Server error. The wallet tables may not be created. Please run the database migration.',
      'pleaseLogInAgainWallet': 'Please log in again to access your wallet.',
      'errorLoadingWallet': 'Error loading wallet',
      'topUp': 'Top Up',
      'cashOut': 'Cash Out',
      'cashout': 'Cashout',
      'transactionHistory': 'Transaction History',
      'recentTransactions': 'Recent Transactions',
      'viewAll': 'View All',
      'balance': 'Balance',
      'sokocoinBalance': 'Sokocoin Balance',
      'keepGrowingYourBalance': 'Keep growing your SOK balance to unlock more opportunities.',
      'availableBalance': 'Available Balance',
      'pendingBalance': 'Pending Balance',
      'totalEarned': 'Total Earned',
      'totalSpent': 'Total Spent',
      'noTransactionsYet': 'No transactions yet',
      'errorLoadingTransactions': 'Error loading transactions',
      'topUpTransaction': 'Top-up',
      'cashoutTransaction': 'Cashout',
      'purchaseTransaction': 'Purchase',
      'earnedTransaction': 'Earned',
      'refundTransaction': 'Refund',
      'feeTransaction': 'Fee',
      'deleteSelected': 'Delete Selected',
      'cancelSelection': 'Cancel Selection',
      'selectTransactions': 'Select Transactions',
      'deleteSelectedTransactions': 'Delete Selected Transactions',
      'areYouSureDeleteSelectedTransactions': 'Are you sure you want to delete',
      'transaction': 'transaction',
      'deleted': 'Deleted',
      
      // Addresses
      'addressManagementOnlyForRegistered': 'Address management is only available for registered users. Please sign in to continue.',
      'failedToLoadAddresses': 'Failed to load addresses: {error}',
      'addAddress': 'Add Address',
      'editAddress': 'Edit Address',
      'deleteAddress': 'Delete Address',
      'areYouSureDeleteAddress': 'Are you sure you want to delete this address?',
      'addressDeleted': 'Address deleted successfully',
      'failedToDeleteAddress': 'Failed to delete address',
      'setAsDefault': 'Set as Default',
      'defaultAddress': 'Default Address',
      'pickupLocation': 'Pickup Location',
      'address': 'Address',
      'city': 'City',
      'region': 'Region',
      'postalCode': 'Postal Code',
      'saveAddress': 'Save Address',
      'addressSaved': 'Address saved successfully',
      'failedToSaveAddress': 'Failed to save address',
      
      // Update Profile
      'profileUpdatesOnlyForRegistered': 'Profile updates are only available for registered users. Please sign in to continue.',
      'updateYourProfile': 'Update your profile information',
      'selectImageSource': 'Select Image Source',
      'camera': 'Camera',
      'gallery': 'Gallery',
      'profilePicture': 'Profile Picture',
      'username': 'Username',
      'save': 'Save',
      'profileUpdated': 'Profile updated successfully',
      'failedToUpdateProfile': 'Failed to update profile',
      
      // Update Business
      'businessDetailsUpdated': 'Business details updated successfully!',
      'shopName': 'Shop Name',
      'shopType': 'Shop Type',
      'website': 'Website',
      
      // Sales Analytics
      'youNeedToBeLoggedInAsSeller': 'You need to be logged in as a seller to view sales analytics.',
      'failedToLoadAnalytics': 'Failed to load analytics: {error}',
      'daily': 'Daily',
      'weekly': 'Weekly',
      'monthly': 'Monthly',
      'yearly': 'Yearly',
      'all': 'All',
      'totalSales': 'Total Sales',
      'totalRevenue': 'Total Revenue',
      'totalOrders': 'Total Orders',
      'averageOrderValue': 'Average Order Value',
      'topSellingProducts': 'Top Selling Products',
      'revenueTrends': 'Revenue Trends',
      
      // KYC Verification
      'kycVerificationOnlyForRegistered': 'KYC verification is only available for registered users. Please sign in to continue.',
      'selectDocumentSource': 'Select Document Source',
      'uploadDocument': 'Upload Document',
      'documentType': 'Document Type',
      'nationalId': 'National ID',
      'passport': 'Passport',
      'driversLicense': 'Driver\'s License',
      'documentStatus': 'Document Status',
      'underReview': 'Under Review',
      'approved': 'Approved',
      'rejected': 'Rejected',
      'verified': 'Verified',
      'notVerified': 'Not Verified',
      'documentUploaded': 'Document uploaded successfully',
      'failedToUploadDocument': 'Failed to upload document',
      
      // Help Center
      'findAnswersToCommonQuestions': 'Find answers to common questions',
      'searchForHelp': 'Search for help...',
      'noResultsFound': 'No results found',
      'trySearchingWithDifferentKeywords': 'Try searching with different keywords',
      'stillNeedHelp': 'Still need help?',
      'contactOurSupportTeam': 'Contact our support team for personalized assistance',
      'email': 'Email',
      'call': 'Call',
      'openingYourEmailApp': 'Opening your email app...',
      'couldNotOpenEmailApp': 'Could not open an email app.',
      'emailAddressCopiedToClipboard': 'Email address copied to clipboard: {email}',
      'couldNotOpenDialer': 'Could not open the dialer. Support number copied: {number}',
      'unableToMakeCall': 'Unable to make a call ({error}). Support number copied: {number}',
      'faq': 'FAQ',
      'answer': 'Answer',
      'wasThisHelpful': 'Was this helpful?',
      'yesHelpful': 'Yes, Helpful',
      'notHelpful': 'Not Helpful',
      'thankYouForYourFeedback': 'Thank you for your feedback!',
      
      // Report Problem
      'reportingProblemsOnlyForRegistered': 'Reporting problems is only available for registered users. Please sign in to continue.',
      'reportAProblem': 'Report a Problem',
      'describeYourIssue': 'Describe your issue and we\'ll help you resolve it',
      'selectCategory': 'Select Category',
      'general': 'General',
      'technical': 'Technical',
      'account': 'Account',
      'enterSubject': 'Enter subject',
      'pleaseEnterSubject': 'Please enter a subject',
      'enterDescription': 'Enter description',
      'pleaseEnterDescription': 'Please enter a description',
      'submitReport': 'Submit Report',
      'reportSubmitted': 'Report submitted successfully',
      'failedToSubmitReport': 'Failed to submit report',
      'couldNotOpenEmailAppForReport': 'Could not open an email app. Email address copied to clipboard.',
      
      // Terms & Privacy
      'termsPrivacy': 'Terms & Privacy',
      'termsOfService': 'Terms of Service',
      'privacyPolicy': 'Privacy Policy',
      'lastUpdated': 'Last updated: {year}',
      'welcomeToSokoniAfrica': 'Welcome to Sokoni Africa. By using our platform, you agree to the following terms:',
      'accountResponsibility': 'Account Responsibility',
      'userConduct': 'User Conduct',
      'productListings': 'Product Listings',
      'payments': 'Payments',
      'limitationOfLiability': 'Limitation of Liability',
      'changesToTerms': 'Changes to Terms',
      'yourPrivacyIsImportant': 'Your privacy is important to us. This policy explains how we collect, use, and protect your information:',
      'informationWeCollect': 'Information We Collect',
      'howWeUseYourInformation': 'How We Use Your Information',
      'informationSharing': 'Information Sharing',
      'dataSecurity': 'Data Security',
      'yourRights': 'Your Rights',
      'contactUs': 'Contact Us',
      
      // Signup
      'createAccount': 'Create Account',
      'joinSokoniAfricaToday': 'Join Sokoni Africa today',
      'chooseUsername': 'Choose a username',
      'email': 'Email',
      'enterEmail': 'Enter your email',
      'pleaseEnterEmail': 'Please enter your email',
      'pleaseEnterValidEmail': 'Please enter a valid email',
      'enterPhoneNumber': 'Enter phone number',
      'createPassword': 'Create a password',
      'confirmPassword': 'Confirm Password',
      'reEnterPassword': 'Re-enter your password',
      'passwordsDoNotMatch': 'Passwords do not match',
      'alreadyHaveAccount': 'Already have an account?',
      'signupSuccessful': 'Sign up successful!',
      'registrationFailed': 'Registration failed. Please try again.',
      'passwordTooLong': 'Password must be 72 characters or less',
      'passwordMustBeAtLeast': 'Password must be at least 6 characters',
      'confirmYourPassword': 'Confirm your password',
      'pleaseConfirmYourPassword': 'Please confirm your password',
      
      // Forgot Password
      'resetPassword': 'Reset Password',
      'enterPhoneToReceiveOTP': 'Enter your phone number to receive OTP for password reset',
      'enterEmailToReceiveCode': 'Enter the email associated with your account to receive a reset code.',
      'sendOTP': 'Send OTP',
      'sendResetEmail': 'Send Reset Email',
      'emailAddress': 'Email Address',
      'backToLogin': 'Back to Login',
      'otpSentSuccessfully': 'OTP sent successfully',
      'failedToSendOTP': 'Failed to send OTP',
      'resetEmailSentSuccessfully': 'Reset email sent successfully',
      'failedToSendResetEmail': 'Failed to send reset email',
      'phoneOTP': 'Phone OTP',
      'receiveCodeBySMS': 'Receive code by SMS',
      'receiveCodeViaEmail': 'Receive code via email',
      'thisEmailNotRegistered': 'This email is not registered. Please enter the email linked to your account or use the phone option.',
      'emailResetNotAvailable': 'Email reset is not available yet. Please use the phone number option instead.',
      'enterValidEmail': 'Please enter a valid email',
      'you@example.com': 'you@example.com',
      'enterOTP': 'Enter OTP',
      'verifyOTP': 'Verify OTP',
      'enterNewPassword': 'Enter New Password',
      'createNewPassword': 'Create your new password',
      'newPassword': 'New Password',
      'confirmNewPassword': 'Confirm New Password',
      'resetPasswordSuccessfully': 'Password reset successfully!',
      'failedToResetPassword': 'Failed to reset password',
      'pleaseEnterOTP': 'Please enter OTP',
      'pleaseEnter6DigitOTP': 'Please enter 6-digit OTP',
      'weSentVerificationCode': 'We sent a verification code to {contact}',
      'otpEntered': 'OTP entered. Now enter your new password.',
      'enterOTPCode': 'Enter OTP Code',
      
      // Create Product
      'productType': 'Product Type',
      'liveAuction': 'Live Auction',
      'productImages': 'Product Images',
      'addUpToImages': 'Add up to 10 images. First image will be the main product image.',
      'addPhoto': 'Add Photo',
      'productDetails': 'Product Details',
      'productTitle': 'Product Title',
      'titleHint': 'For fast accessibility use a short & easy title.',
      'unitType': 'Unit Type',
      'priceHint': 'Update this frequently.',
      'descriptionHint': 'Update this frequently.',
      'settingsFeatures': 'Settings & Features',
      'wingaMode': 'Winga Mode',
      'wingaDesc': 'Enable this, 3rd party clients can post your products',
      'warranty': 'Warranty',
      'warrantyDesc': 'Enable product Annual warranty to gain more trust',
      'privateProduct': 'Private Product',
      'privateDesc': 'Only your Followers can see this product',
      'adultContent': 'Adult Content',
      'adultDesc': 'Only users above 18+ can see this product',
      'pleaseAddImage': 'Please add at least one product image',
      'productCreated': 'Product created with {count} image(s)!',
      'maximumImages': 'Maximum 10 images allowed',
      'chooseFromGallery': 'Choose from Gallery',
      'takePhoto': 'Take a Photo',
      'removeAllImages': 'Remove All Images',
      'main': 'Main',
      
      // Language & Region
      'languageAndRegion': 'Language & Region',
      'customizeAppPreferences': 'Customize your app preferences',
      'language': 'Language',
      'region': 'Region',
      'selectRegion': 'Select Region',
      'languageUpdatedSuccessfully': 'Language updated successfully!',
      'regionUpdatedSuccessfully': 'Region updated successfully!',
      'tanzania': 'Tanzania',
      'kenya': 'Kenya',
      'uganda': 'Uganda',
      'rwanda': 'Rwanda',
      
      // Inventory
      'myInventory': 'My Inventory',
      'manageYourProducts': 'Manage your products',
      'totalProducts': 'Total Products',
      'active': 'Active',
      'noProductsYet': 'No products yet',
      'areYouSureDeleteProduct': 'Are you sure you want to delete "{title}"? This action cannot be undone.',
      'deletedProduct': 'Deleted "{title}"',
      'failedToDeleteProduct': 'Failed to delete product',
      
      // Customer Orders
      'customerOrders': 'Customer Orders',
      'manageOrdersFromCustomers': 'Manage orders from your customers',
      'pleaseLogInSellerAccount': 'Please log in with a seller account to view customer orders.',
      'onlySellersCanView': 'Only sellers can view customer orders.',
      'unableToLoadCustomerOrders': 'Unable to load customer orders',
      'failedToInitialiseCustomerOrders': 'Failed to initialise customer orders',
      'noCustomerOrdersYet': 'No customer orders yet',
      'whenBuyersPlaceOrders': 'When buyers place orders for your products they will appear here.',
      'switchToSellerAccount': 'Switch to a seller account to manage customer orders and keep buyers updated.',
      'sellerAccessRequired': 'Seller access required',
      'tryAgain': 'Try again',
      'refreshOrders': 'Refresh orders',
      'checkAgain': 'Check again',
      'accept': 'Accept',
      'reject': 'Reject',
      'markAsShipped': 'Mark as Shipped',
      'awaitingDeliveryConfirmation': 'Awaiting delivery confirmation',
      'statusUpdatedTo': 'Status updated to {status}',
      'unableToUpdateStatus': 'Unable to update status',
      'invalidOrderIdentifier': 'Invalid order identifier. Please refresh the screen.',
      'orderStatusPending': 'Pending',
      'orderStatusConfirmed': 'Confirmed',
      'orderStatusProcessing': 'Processing',
      'orderStatusShipped': 'Shipped',
      'orderStatusDelivered': 'Delivered',
      'orderStatusCancelled': 'Cancelled',
      'buyer': 'Buyer',
      'order': 'Order',
      'items': 'items',
      'item': 'item',
      'noItemsAttached': 'No items attached to this order.',
      'moreItems': '+{count} more item{s}',
      
      // My Orders
      'myOrders': 'My Orders',
      'trackAndManagePurchases': 'Track and manage your purchases',
      'orderHistoryOnlyRegistered': 'Order history is only available for registered users.',
      'unableToLoadYourOrders': 'Unable to load your orders',
      'noOrdersYet': 'No orders yet',
      'browseProductsPlaceOrder': 'Browse products and place an order to see it here.',
      'viewDetails': 'View Details',
      'track': 'Track',
      'confirmDelivery': 'Confirm Delivery',
      'confirming': 'Confirming...',
      'shippingTo': 'Shipping to:',
      'placedOn': 'Placed on',
      'payment': 'Malipo',
      'orderItems': 'Items',
      'subtotal': 'Subtotal',
      'total': 'Total',
      'thanksDeliveryConfirmed': 'Thanks! Delivery confirmed and payment released to the seller.',
      'failedToConfirmDelivery': 'Failed to confirm delivery',
      'invalidOrderIdentifierRefresh': 'Invalid order identifier. Please refresh and try again.',
      'trackingUpdatesAvailableSoon': 'Tracking updates will be available soon.',
      'noItemsAvailable': 'No items available',
      'qty': 'Qty: {quantity}',
      'sokocoin': 'Sokocoin',
      
      // Wallet
      'wallet': 'Wallet',
      'sokocoinBalance': 'Sokocoin Balance',
      'keepGrowingSOKBalance': 'Keep growing your SOK balance to unlock more opportunities.',
      'topUp': 'Top Up',
      'cashout': 'Cashout',
      'totalEarned': 'Total Earned',
      'totalSpent': 'Total Spent',
      'recentTransactions': 'Recent Transactions',
      'viewAll': 'View All',
      'noTransactionsYet': 'No transactions yet',
      'errorLoadingTransactions': 'Error loading transactions',
      'walletPaymentMethods': 'Wallet & Payment Methods',
      'walletPaymentMethodsOnlyRegistered': 'Wallet and payment methods are only available for registered users.',
      'errorLoadingWallet': 'Error loading wallet',
      'topUpTransaction': 'Top-up',
      'cashoutTransaction': 'Cashout',
      'purchaseTransaction': 'Purchase',
      'earnedTransaction': 'Earned',
      'refundTransaction': 'Refund',
      'feeTransaction': 'Fee',
      'filterTransactions': 'Filter transactions',
      'exchangeRate': 'Exchange Rate',
      'areYouSureDeleteTransaction': 'Are you sure you want to delete this transaction?',
      'noteCompletedTransactionsCannotBeDeleted': 'Note: This is a completed transaction. Deleting it will remove it from your history but may affect your records.',
      'deleteTransaction': 'Delete Transaction',
      'transactionDeletedSuccessfully': 'Transaction deleted successfully',
      'deleteAllTransactions': 'Delete All Transactions',
      'areYouSureDeleteAllTransactions': 'Are you sure you want to delete all transactions?',
      'thisWillDeleteAllFailedCancelledPending': 'This will delete all failed, cancelled, and pending transactions.',
      'noteCompletedTransactionsWillBeKept': 'Note: Completed transactions will be kept as they affect your wallet balance.',
      'totalTransactions': 'Total transactions',
      'filtered': 'Filtered',
      'allTypes': 'All Types',
      'allStatuses': 'All Statuses',
      'clearAll': 'Clear All',
      'apply': 'Apply',
      'yourTransactionHistoryWillAppearHere': 'Your transaction history will appear here',
      
      // Topup
      'topUpWallet': 'Top Up Wallet',
      'topUpWalletInfo': 'Top up your wallet with Sokocoin using Flutterwave payment gateway.',
      'amount': 'Amount',
      'enterAmount': 'Enter amount',
      'pleaseEnterAmount': 'Please enter an amount',
      'pleaseEnterValidAmount': 'Please enter a valid amount',
      'minimumAmountIs100': 'Minimum amount is 100',
      'currency': 'Currency',
      'paymentMethod': 'Payment Method',
      'creditDebitCard': 'Credit/Debit Card',
      'mobileMoney': 'Mobile Money',
      'bankTransfer': 'Bank Transfer',
      'mobileMoneyPhoneNumber': 'Mobile Money Phone Number',
      'continueToPayment': 'Continue to Payment',
      'paymentCompletedSuccessfully': 'Payment completed successfully!',
      'paymentNotCompleted': 'Payment not completed.',
      'topUpCompletedTestMode': 'Top-up completed in test mode.',
      'failedToInitializePayment': 'Failed to initialize payment',
      'paymentError': 'Payment Error',
      'possibleCauses': 'Possible causes:',
      'paymentGatewayNotConfigured': 'Payment gateway not configured',
      'networkConnectionIssue': 'Network connection issue',
      'invalidPaymentDetails': 'Invalid payment details',
      'pleaseTryAgainOrContactSupport': 'Please try again or contact support if the issue persists.',
      'pleaseEnterMobileMoneyPhone': 'Please enter the mobile money phone number.',
      'usePhoneRegisteredWallet': 'Use the phone number registered to your Tanzanian mobile wallet.',
      'ensurePhoneMatchesWallet': 'Ensure the phone number matches your mobile money account.',
      'examplePhoneNumber': 'e.g. 2557XXXXXXXX',
      'enterPhoneWithCountryCode': 'Enter phone number with country code',
      'invalidPaymentURL': 'Invalid payment URL received.',
      'couldNotOpenPaymentPage': 'Could not open payment page.',
      'completePayment': 'Complete Payment',
      'newTabOpenedFlutterwave': 'A new tab has been opened with the Flutterwave checkout. Complete the payment there, then click "Verify Payment" below.',
      'verifyPayment': 'Verify Payment',
      'paymentNotVerifiedYet': 'Payment not verified yet. Please complete the payment and try again.',
      
      // Cashout
      'cashoutTitle': 'Cashout',
      'availableBalance': 'Available Balance',
      'sokocoinAmount': 'Sokocoin Amount',
      'enterAmountToCashout': 'Enter amount to cashout',
      'pleaseEnterAmountToCashout': 'Please enter an amount',
      'pleaseEnterValidAmountToCashout': 'Please enter a valid amount',
      'amountExceedsBalance': 'Amount exceeds available balance',
      'minimumCashoutIs10': 'Minimum cashout is 10 SOK',
      'insufficientSokocoinBalance': 'Insufficient Sokocoin balance',
      'payoutMethod': 'Payout Method',
      'accountNumber': 'Account Number',
      'pleaseEnterAccountNumber': 'Please enter account number',
      'bankName': 'Bank Name',
      'pleaseEnterBankName': 'Please enter bank name',
      'accountName': 'Account Name',
      'pleaseEnterAccountName': 'Please enter account name',
      'initiateCashout': 'Initiate Cashout',
      'cashoutError': 'Cashout Error',
      'invalidPayoutAccountDetails': 'Invalid payout account details',
      'paymentGatewayConfigurationIssue': 'Payment gateway configuration issue',
      'pleaseCheckPayoutDetails': 'Please check your payout details and try again.',
      'pleaseCheckPayoutDetailsOrContact': 'Please check your payout details and try again or contact support if the issue persists.',
      'cashoutInitiatedSuccessfully': 'Cashout initiated successfully',
      'failedToInitiateCashout': 'Failed to initiate cashout',
      'willBeWithdrawn': '≈ {amount} will be withdrawn.',
      'formatPhoneNumber': 'Format: {code}XXXXXXXX',
      'enterAccountNumber': 'Enter account number',
      'enterBankName': 'Enter bank name',
      'enterAccountHolderName': 'Enter account holder name',
      
      // Addresses
      'myAddresses': 'My Addresses',
      'manageDeliveryAddresses': 'Manage your delivery addresses',
      'pickupLocationSet': 'Pickup Location Set',
      'pickupLocationRequired': 'Pickup Location Required',
      'businessLocationSet': 'Your business location is set. Buyers can use Sokoni Africa Logistics for shipping.',
      'setDefaultAddressEnableShipping': 'Set your default address to enable shipping. Location will be captured automatically when you save.',
      'noAddressesSaved': 'No addresses saved',
      'addYourFirstAddress': 'Add your first address to get started',
      'addAddress': 'Add Address',
      'editAddress': 'Edit Address',
      'deleteAddress': 'Delete Address',
      'areYouSureDeleteAddress': 'Are you sure you want to delete "{title}"?',
      'setAsDefault': 'Set as Default',
      'default': 'Default',
      'addressTitle': 'Address Title',
      'homeWorkEtc': 'Home, Work, etc.',
      'pleaseEnterAddressTitle': 'Please enter address title',
      'pleaseEnterFullName': 'Please enter full name',
      'streetAddress': 'Street Address',
      'pleaseEnterStreetAddress': 'Please enter street address',
      'city': 'City',
      'pleaseEnterCity': 'Please enter city',
      'regionState': 'Region/State',
      'pleaseEnterRegion': 'Please enter region',
      'postalCode': 'Postal Code',
      'pleaseEnterPostalCode': 'Please enter postal code',
      'setAsDefaultAddress': 'Set as default address',
      'onlyDefaultAddressUsedCheckout': 'Only the default address will be used in checkout',
      'saveAddress': 'Save Address',
      'savingAddress': 'Saving address...',
      'addressSavedSuccessfully': 'Address saved successfully! It will appear in checkout.',
      'addressAndPickupLocationSaved': 'Address and pickup location saved! Buyers can now use shipping.',
      'failedToSaveAddress': 'Failed to save address',
      'addressSavedLocationLater': 'Address saved. Add location later if you want Sokoni Africa delivery to calculate distance.',
      'gettingLocationShipping': 'Getting your location for shipping pickup point...',
      'locationCapturedShipping': 'Location captured for shipping pickup point',
      'couldNotGetLocation': 'Could not get location. Please enable location services and try again. Shipping will not be available until location is set.',
      'addressManagementOnlyRegistered': 'Address management is only available for registered users. Please sign in to continue.',
      'manageYourDeliveryAddresses': 'Manage your delivery addresses',
      'postalCodeLabel': 'Postal Code: {code}',
      
      // Settings
      'settings': 'Settings',
      'manageAccountPreferences': 'Manage your account preferences',
      'personalInformation': 'Personal Information',
      'updatePersonalDetails': 'Update your personal details like name, username, email, and phone number to keep your account information current.',
      'updateProfile': 'Update Profile',
      'businessInformation': 'Business Information',
      'updateBusinessDetails': 'Update your Business details like Shop Name, Shop Type, to keep your account information current.',
      'updateBusinessDetailsTitle': 'Update Business Details',
      'setPickupLocation': 'Set Pickup Location',
      'setBusinessLocationShipping': 'Set your business location for shipping. Buyers can use Sokoni Africa Logistics if location is set.',
      'general': 'General',
      'notification': 'Notification',
      'activityNotifications': 'Activity Notifications',
      'enableDisablePushNotifications': 'Enable or disable push notifications for real-time updates',
      'activityNotificationsEnabled': 'Activity notifications enabled',
      'activityNotificationsDisabled': 'Activity notifications disabled',
      'promotionsOffers': 'Promotions & Offers',
      'getPushNotificationsOffers': 'Get push notifications whenever there are offers',
      'promotionsNotificationsEnabled': 'Promotions notifications enabled',
      'promotionsNotificationsDisabled': 'Promotions notifications disabled',
      'directEmailNotification': 'Direct Email Notification',
      'getNotifiedEmailActivities': 'Get notified via email for important account activities',
      'emailNotificationsEnabled': 'Email notifications enabled',
      'emailNotificationsDisabled': 'Email notifications disabled',
      'appearancePreferences': 'Appearance & Preferences',
      'darkMode': 'Dark Mode',
      'reduceEyeStrainReadability': 'Reduce eye strain and improve readability',
      'darkModeEnabled': 'Dark mode enabled',
      'darkModeDisabled': 'Dark mode disabled',
      'languageRegion': 'Language & Region',
      'accountSupport': 'Account & Support',
      'kycAccountVerification': 'KYC & Account Verification',
      'helpCenter': 'Help Center',
      'reportProblem': 'Report a Problem',
      'termsPrivacy': 'Terms & Privacy',
      'logOut': 'Log Out',
      'areYouSureLogOut': 'Are you sure you want to log out?',
      'failedToUpdateSetting': 'Failed to update setting. Please try again.',
      'salesAnalytics': 'Sales Analytics',
      
      // Update Profile
      'updateProfileTitle': 'Update Profile',
      'managePersonalInformation': 'Manage your personal information',
      'selectImageSource': 'Select Image Source',
      'camera': 'Camera',
      'gallery': 'Gallery',
      'fullNameLabel': 'Full Name',
      'pleaseEnterYourFullName': 'Please enter your full name',
      'usernameLabel': 'Username',
      'pleaseEnterUsername': 'Please enter a username',
      'emailLabel': 'Email',
      'pleaseEnterYourEmail': 'Please enter your email',
      'pleaseEnterValidEmail': 'Please enter a valid email',
      'phoneNumberLabel': 'Phone Number',
      'saveChanges': 'Save Changes',
      'changesSavedImmediately': 'Changes will be saved to your account immediately',
      'profileUpdatedSuccessfully': 'Profile updated successfully!',
      'failedToUpdateProfile': 'Failed to update profile',
      'pleaseLoginToUpdateProfile': 'Please login to update your profile',
      'pleaseLoginToUploadProfilePicture': 'Please login to upload profile picture',
      'errorPickingImage': 'Error picking image',
      'profilePictureUploadedSuccessfully': 'Profile picture uploaded successfully!',
      'failedToUploadImage': 'Failed to upload image',
      'profileUpdatesOnlyRegistered': 'Profile updates are only available for registered users. Please sign in to continue.',
      
      // Update Business
      'updateBusinessDetailsTitle': 'Update Business Details',
      'manageBusinessInformation': 'Manage your business information',
      'shopName': 'Shop Name',
      'pleaseEnterShopName': 'Please enter your shop name',
      'shopType': 'Shop Type',
      'pleaseSelectShopType': 'Please select shop type',
      'retail': 'Retail',
      'wholesale': 'Wholesale',
      'manufacturer': 'Manufacturer',
      'serviceProvider': 'Service Provider',
      'businessDescription': 'Business Description',
      'businessAddress': 'Business Address',
      'websiteOptional': 'Website (Optional)',
      'businessInformationHelpsCustomers': 'Business information helps customers find and trust your store',
      'businessDetailsUpdatedSuccessfully': 'Business details updated successfully!',
      'logoUploadFeatureComingSoon': 'Logo upload feature coming soon',
      
      // Sales Analytics
      'salesAnalyticsTitle': 'Sales Analytics',
      'trackBusinessPerformance': 'Track your business performance',
      'youNeedSellerAccount': 'You need to be logged in as a seller to view sales analytics.',
      'needToBeLoggedInAsSeller': 'You need to be logged in as a seller to view sales analytics.',
      'unableToLoadAnalytics': 'Unable to load analytics',
      'failedToLoadAnalytics': 'Failed to load analytics',
      'noAnalyticsDataAvailable': 'No analytics data available',
      'salesDataWillAppear': 'Sales data will appear here once you start receiving orders.',
      'salesDataWillAppearHere': 'Sales data will appear here once you start receiving orders.',
      'noSalesDataForPeriod': 'No sales data available for this period',
      'unknownProduct': 'Unknown Product',
      'totalRevenue': 'Total Revenue',
      'totalOrders': 'Total Orders',
      'avgOrderValue': 'Avg Order Value',
      'productsSold': 'Products Sold',
      'customers': 'Customers',
      'salesOverview': 'Sales Overview',
      'noSalesDataPeriod': 'No sales data available for this period',
      'orderStatus': 'Order Status',
      'topProducts': 'Top Products',
      'sold': 'sold',
      'daily': 'Daily',
      'weekly': 'Weekly',
      'monthly': 'Monthly',
      'yearly': 'Yearly',
      'all': 'All',
      
      // KYC Verification
      'kycAccountVerificationTitle': 'KYC & Account Verification',
      'accountVerified': 'Account Verified',
      'verificationPending': 'Verification Pending',
      'accountVerifiedSuccessfully': 'Your account has been verified successfully',
      'completeVerificationUnlockFeatures': 'Complete verification to unlock all features',
      'completeVerificationToUnlock': 'Complete verification to unlock all features',
      'verificationDocument': 'Verification Document',
      'onlyOneDocumentRequired': 'Only one document is required for verification. Upload a clear photo of your National ID, Passport, or Driver\'s License.',
      'kycDocumentInfo': 'Only one document is required for verification. Upload a clear photo of your National ID, Passport, or Driver\'s License.',
      'kycOnlyForRegisteredUsers': 'KYC verification is only available for registered users. Please sign in to continue.',
      'uploadDocument': 'Upload Document',
      'replaceDocument': 'Replace Document',
      'uploading': 'Uploading...',
      'documentUnderReview': 'Your document is under review. You will be notified once verification is complete.',
      'documentUploadedSuccessfully': 'Document uploaded successfully! It will be reviewed shortly.',
      'failedToUploadDocument': 'Failed to upload document',
      'selectDocumentSource': 'Select Document Source',
      'kycVerificationOnlyRegistered': 'KYC verification is only available for registered users. Please sign in to continue.',
      'pleaseLoginToUploadKYC': 'Please login to upload KYC document',
      'errorPickingDocument': 'Error picking document',
      'approved': 'APPROVED',
      'rejected': 'REJECTED',
      'pendingStatus': 'PENDING',
      
      // Help Center
      'helpCenterTitle': 'Help Center',
      'findAnswersCommonQuestions': 'Find answers to common questions',
      'searchForHelp': 'Search for help...',
      'noResultsFound': 'No results found',
      'trySearchingDifferentKeywords': 'Try searching with different keywords',
      'stillNeedHelp': 'Still need help?',
      'contactSupportTeam': 'Contact our support team for personalized assistance',
      'email': 'Email',
      'call': 'Call',
      'openingEmailApp': 'Opening your email app...',
      'couldNotOpenEmailApp': 'Could not open an email app.',
      'supportNumberCopied': 'Support number copied: {number}',
      'couldNotOpenDialer': 'Could not open the dialer. Support number copied: {number}',
      'unableToMakeCall': 'Unable to make a call ({error}). Support number copied: {number}',
      
      // Report Problem
      'reportProblemTitle': 'Report a Problem',
      'helpUsImproveReportingIssues': 'Help us improve by reporting any issues',
      'category': 'Category',
      'pleaseSelectCategory': 'Please select a category',
      'bugReport': 'Bug Report',
      'featureRequest': 'Feature Request',
      'paymentIssue': 'Payment Issue',
      'orderIssue': 'Order Issue',
      'pleaseEnterSubject': 'Please enter a subject',
      'pleaseDescribeProblem': 'Please describe the problem',
      'pleaseProvideMoreDetails': 'Please provide more details (at least 20 characters)',
      'submitReport': 'Submit Report',
      'reportSentViaEmail': 'Your report will be sent via email to our support team',
      'unableToOpenEmailApp': 'Unable to open your email app. We copied {email} so you can email us manually.',
      'openingEmailAppPleaseSend': 'Opening your email app. Please send the email to complete your report.',
      'failedToSubmitReport': 'Failed to submit report',
      'reportingProblemsOnlyRegistered': 'Reporting problems is only available for registered users. Please sign in to continue.',
      
      // Terms Privacy
      'termsPrivacyTitle': 'Terms & Privacy',
      'termsOfService': 'Terms of Service',
      'privacyPolicy': 'Privacy Policy',
      'lastUpdated': 'Last updated: {year}',
      'welcomeToSokoniAfrica': 'Welcome to Sokoni Africa. By using our platform, you agree to the following terms:',
      'accountResponsibility': 'Account Responsibility',
      'maintainAccountConfidentiality': 'You are responsible for maintaining the confidentiality of your account',
      'provideAccurateInformation': 'You must provide accurate and complete information',
      'mustBe18YearsOld': 'You must be at least 18 years old to use our services',
      'userConduct': 'User Conduct',
      'notUsePlatformIllegal': 'You agree not to use the platform for illegal purposes',
      'notPostFalseInformation': 'You will not post false, misleading, or fraudulent information',
      'respectOtherUsers': 'You will respect other users and their rights',
      'productListings': 'Product Listings',
      'productDescriptionsAccurate': 'All product descriptions must be accurate',
      'sellersResponsibleQuality': 'Sellers are responsible for product quality and delivery',
      'sokoniReservesRightRemove': 'Sokoni Africa reserves the right to remove listings that violate our policies',
      'payments': 'Payments',
      'allTransactionsProcessedSecurely': 'All transactions are processed securely',
      'refundsSubjectToPolicy': 'Refunds are subject to our refund policy',
      'reserveRightSuspendAccounts': 'We reserve the right to suspend accounts for payment issues',
      'limitationOfLiability': 'Limitation of Liability',
      'sokoniNotLiableTransactions': 'Sokoni Africa is not liable for transactions between users',
      'providePlatformNotParty': 'We provide a platform for buying and selling but are not a party to transactions',
      'usersResponsibleResolvingDisputes': 'Users are responsible for resolving disputes',
      'changesToTerms': 'Changes to Terms',
      'mayUpdateTermsTime': 'We may update these terms from time to time',
      'continuedUseConstitutesAcceptance': 'Continued use of the platform constitutes acceptance of changes',
      'yourPrivacyImportant': 'Your privacy is important to us. This policy explains how we collect, use, and protect your information:',
      'informationWeCollect': 'Information We Collect',
      'personalInformation': 'Personal information (name, email, phone number)',
      'accountInformation': 'Account information (username, password)',
      'transactionHistory': 'Transaction history',
      'deviceInformationUsageData': 'Device information and usage data',
      'howWeUseInformation': 'How We Use Your Information',
      'provideImproveServices': 'To provide and improve our services',
      'processTransactions': 'To process transactions',
      'communicateAboutAccount': 'To communicate with you about your account',
      'sendPromotionalOffers': 'To send promotional offers (with your consent)',
      'ensurePlatformSecurity': 'To ensure platform security',
      'informationSharing': 'Information Sharing',
      'doNotSellPersonalInformation': 'We do not sell your personal information',
      'mayShareServiceProviders': 'We may share information with service providers who assist us',
      'mayDiscloseRequiredByLaw': 'We may disclose information if required by law',
      'dataSecurity': 'Data Security',
      'implementSecurityMeasures': 'We implement security measures to protect your data',
      'noMethodTransmissionSecure': 'However, no method of transmission is 100% secure',
      'responsibleKeepingCredentialsSecure': 'You are responsible for keeping your account credentials secure',
      'yourRights': 'Your Rights',
      'accessUpdatePersonalInformation': 'You can access and update your personal information',
      'requestDeletionAccount': 'You can request deletion of your account',
      'optOutMarketingCommunications': 'You can opt-out of marketing communications',
      'cookiesTracking': 'Cookies and Tracking',
      'useCookiesImproveExperience': 'We use cookies to improve your experience',
      'controlCookieSettingsBrowser': 'You can control cookie settings in your browser',
      'childrensPrivacy': 'Children\'s Privacy',
      'servicesNotIntendedUnder18': 'Our services are not intended for users under 18',
      'doNotKnowinglyCollectChildren': 'We do not knowingly collect information from children',
      'contactUs': 'Contact Us',
      'questionsAboutPolicy': 'If you have questions about this policy, please contact us at support@sokoni.africa',
      'iUnderstand': 'I Understand',
      
      // Common
      'error': 'Error',
      'success': 'Success',
      'loading': 'Loading',
      'loadingProducts': 'Loading products...',
      'settingsOnlyForRegisteredUsers': 'Settings are only available for registered users. Please sign in to continue.',
      'posts': 'Posts',
      'sold': 'Sold',
    },
    'sw': {
      // Onboarding
      'selectLanguage': 'Chagua Lugha',
      'chooseLanguage': 'Chagua lugha unayopendelea',
      'swahili': 'Kiswahili',
      'swahiliDesc': 'Kama ni mswahili chagua hii',
      'english': 'Kiingereza',
      'englishDesc': 'Kwa wazungumzaji wa Kiingereza peke yake',
      'continue': 'Endelea',
      'getStarted': 'Anza',
      
      // Gender Selection
      'selectGender': 'Chagua Jinsia',
      'selectYourGender': 'Chagua jinsia yako',
      'ladiesGirls': 'Wanawake / Wasichana',
      'ladiesDesc': 'Chagua hii ikiwa wewe ni Mwanamke / Msichana',
      'gentsBoys': 'Wanaume / Wavulana',
      'gentsDesc': 'Chagua hii ikiwa wewe ni Mwanamume / Mvulana',
      
      // User Type
      'selectAccountType': 'Chagua Aina ya Akaunti',
      'howToUseSokoni': 'Ungependa kutumia Sokoni vipi?',
      'sokoniClient': 'Mteja wa Sokoni',
      'clientDesc': 'Nunua kutoka kwa Mtu yeyote bila Kuuza',
      'sokoniSupplier': 'Msambazaji wa Sokoni',
      'supplierDesc': 'Uza kwa Mtu yeyote bila Kununua',
      'sokoniRetailer': 'Muuzaji wa Sokoni',
      'retailerDesc': 'Nunua kutoka kwa Wasambazaji, Uze kwa Wateja',
      
      // Login
      'welcomeAboard': 'Karibu Abordi',
      'selectHowToContinue': 'Tafadhali Chagua jinsi unavyotaka kuendelea',
      'termsNote': 'Tunadhani umesoma na kuelewa Masharti na Hali na Sera ya Faragha',
      'google': 'Google',
      'or': 'AU',
      'phoneNumberHint': 'Tafadhali ingiza nambari ya simu halali katika sehemu iliyo hapa chini, Tutakujulisha ikiwa nambari hiyo imetumika na mtu mwingine.',
      'phoneNumber': 'Nambari ya Simu',
      'continueAsGuest': 'Endelea kama Mgeni',
      'loggedInAsGuest': 'Umeingia kama mgeni',
      'guestLoginFailed': 'Kuingia kama mgeni kumeshindwa',
      'signIn': 'Ingia',
      'username': 'Jina la Mtumiaji',
      'usernameOrEmail': 'Jina la Mtumiaji au Barua pepe',
      'enterUsernameOrEmail': 'Ingiza jina la mtumiaji au barua pepe',
      'password': 'Nenosiri',
      'enterPassword': 'Ingiza nenosiri',
      'forgotPassword': 'Umesahau Nenosiri?',
      'dontHaveAccount': 'Huna akaunti?',
      'signUp': 'Jisajili',
      'loginSuccessful': 'Kuingia kumefanikiwa!',
      'welcomeUser': 'Karibu, {name}!',
      'startingGoogleSignIn': 'Kuanza Kuingia kwa Google...',
      'googleSignInFailed': 'Kuingia kwa Google kumeshindwa',
      'googleAccountAlreadyRegistered': 'Akaunti hii ya Google tayari imesajiliwa. Tafadhali tumia kuingia kwa kawaida.',
      'usernameAlreadyTaken': 'Jina la mtumiaji tayari limetumiwa. Tafadhali wasiliana na msaada.',
      'accountAlreadyExists': 'Akaunti tayari ipo. Tafadhali tumia kuingia kwa kawaida.',
      'connectionError': 'Hitilafu ya muunganisho. Tafadhali angalia muunganisho wako wa intaneti na ujaribu tena.',
      'googleAuthFailed': 'Uthibitishaji wa Google umeshindwa. Token inaweza kuisha muda. Tafadhali ujaribu kuingia tena.',
      'googleSignInConfigError': 'Hitilafu ya usanidi wa Kuingia kwa Google.',
      'serverError': 'Hitilafu ya seva. Tafadhali ujaribu tena baadaye.',
      'googleSignInFailedTryAgain': 'Kuingia kwa Google kumeshindwa. Tafadhali ujaribu tena au tumia kuingia kwa kawaida.',
      'googleSignInNetworkTitle': 'Muunganisho thabiti unahitajika',
      'googleSignInNetworkMessageSignIn': 'Muunganisho wa intaneti thabiti unahitajika kwa kuingia kwa Google. Tafadhali hakikisha mtandao wako uko sawa kisha ujaribu tena, au tumia njia ya kawaida ya kuingia.',
      'googleSignInNetworkMessageSignUp': 'Muunganisho wa intaneti thabiti unahitajika kwa kujisajili kwa Google. Tafadhali hakikisha mtandao wako uko sawa kisha ujaribu tena, au tumia njia ya kawaida ya kujisajili.',
      'useNormalSignIn': 'Tumia kuingia kwa kawaida',
      'useNormalSignUp': 'Tumia kujisajili kwa kawaida',
      'googleSignInSetupRequired': 'Usanidi wa Kuingia kwa Google Unahitajika',
      'ok': 'SAWA',
      'completeGoogleSignIn': 'Ili kukamilisha kuingia kwa Google, tafadhali chagua jinsi unavyotaka kutumia Sokoni Afrika.',
      'buyer': 'Mnunuzi',
      'seller': 'Muuzaji',
      'both': 'Zote mbili',
      'userTypeNotFound': 'Aina ya mtumiaji haijapatikana katika akaunti. Tafadhali wasiliana na msaada.',
      'failedToGetGoogleToken': 'Kushindwa kupata token ya uthibitishaji wa Google. Tafadhali ujaribu kuingia tena.',
      'googleSignInNotConfigured': 'Kuingia kwa Google hakijasanidiwa kwa jukwaa hili. Sasisha AppConstants.googleClientIdWeb na tag ya meta katika web/index.html.',
      'pleaseEnterUsername': 'Tafadhali ingiza jina la mtumiaji',
      'usernameTooShort': 'Jina la mtumiaji lazima liwe angalau herufi 3',
      'pleaseEnterPassword': 'Tafadhali ingiza nenosiri',
      'passwordTooShort': 'Nenosiri lazima liwe angalau herufi 6',
      'invalidCredentials': 'Vitambulisho batili. Tafadhali angalia jina la mtumiaji na nenosiri lako.',
      'loginFailed': 'Kuingia kumeshindwa. Tafadhali ujaribu tena.',
      'welcomeBack': 'Karibu Tena!',
      'signInToContinueShopping': 'Ingia ili kuendelea kununua',
      'usernameEmailOrPhone': 'Jina la Mtumiaji, Barua pepe, au Simu',
      'enterUsernameEmailOrPhone': 'Ingiza jina la mtumiaji, barua pepe, au simu',
      'pleaseEnterUsernameEmailOrPhone': 'Tafadhali ingiza jina la mtumiaji, barua pepe, au simu yako',
      'enterYourPassword': 'Ingiza nenosiri lako',
      'pleaseEnterYourPassword': 'Tafadhali ingiza nenosiri lako',
      'passwordMustBeAtLeast6': 'Nenosiri lazima liwe angalau herufi 6',
      'passwordMustBe72OrLess': 'Nenosiri lazima liwe herufi 72 au chini',
      'continueWithGoogle': 'Endelea na Google',
      'googleSignInUnavailable': 'Kuingia kwa Google Haupatikani',
      'accountDoesntHavePassword': 'Akaunti hii haina nenosiri. Tafadhali tumia Kuingia kwa Google au weka upya nenosiri lako.',
      'incorrectCredentials': 'Jina la mtumiaji, barua pepe, simu, au nenosiri sio sahihi. Tafadhali angalia vitambulisho vyako na ujaribu tena.',
      'userNotFound': 'Mtumiaji hajapatikana. Tafadhali angalia jina la mtumiaji, barua pepe, au nambari ya simu yako, au jisajili kwa akaunti mpya.',
      'accountInactive': 'Akaunti yako haijaamilishwa. Tafadhali wasiliana na msaada.',
      'connectionTimeout': 'Muda wa muunganisho umeisha. Tafadhali angalia muunganisho wako wa intaneti na ujaribu tena.',
      'networkError': 'Hitilafu ya mtandao. Tafadhali angalia muunganisho wako wa intaneti na ujaribu tena.',
      'loginFailedTitle': 'Kuingia Kumeshindwa',
      'googleSignInConfigErrorDetails': 'Tafadhali angalia:\n1. Kitambulisho cha Mteja kimewekwa katika web/index.html\n2. Kitambulisho cha Mteja ni sahihi (sio kichwa cha maandishi)\n3. URI ya Kuelekeza imesanidiwa katika Google Console\n4. URL ya programu yako iko katika asili za JavaScript zinaruhusiwa',
      
      // Phone Verification
      'weFlexSecurity': 'Sekuriti ya We Flex',
      'provideOTP': 'Tafadhali toa OTP iliyotumwa kwa nambari yako',
      'sentTo': 'Imetumwa kwa',
      'didntReceiveCode': 'Hukupokea msimbo?',
      'resendOTP': 'Tuma tena OTP',
      'changePhoneNumber': 'Badilisha Nambari ya Simu',
      'verifyPhone': 'Thibitisha Simu',
      
      // Main Navigation
      'home': 'Nyumbani',
      'search': 'Tafuta',
      'cart': 'Mkoba',
      'inventory': 'Hifadhi',
      'messages': 'Ujumbe',
      'profile': 'Wasifu',
      
      // Feed
      'sokoniAfrica': 'Sokoni Afrika',
      'testAPI': 'Jaribu API',
      'noProductsFound': 'Hakuna bidhaa zilizopatikana',
      'retry': 'Jaribu tena',
      'discoverAndShop': 'Gundua na Nunua',
      'discoverRealProducts': 'Gundua bidhaa za kweli kutoka kwa wauzaji wa Afrika.\nHakuna msongo wa mawazo, tu nishati ya kazi tu.',
      'secure': 'Salama',
      'fastDelivery': 'Uwasilishaji wa Haraka',
      'trusted': 'Kuaminika',
      'all': 'Zote',
      'electronics': 'Elektroniki',
      'fashion': 'Mitindo',
      'food': 'Chakula',
      'beauty': 'Urembo',
      'homeKitchen': 'Nyumbani/Jikoni',
      'sports': 'Michezo',
      'automotives': 'Magari',
      'books': 'Vitabu',
      'kids': 'Watoto',
      'agriculture': 'Kilimo',
      'artCraft': 'Sanaa/Ufundi',
      'computerSoftware': 'Kompyuta/Programu',
      'healthWellness': 'Afya na Ustawi',
      'unableToGetLocation': 'Haiwezekani kupata eneo lako. Tafadhali wezesha huduma za eneo.',
      'errorGettingLocation': 'Hitilafu ya kupata eneo',
      'locationPermissionRequired': 'Ruhusa ya Eneo Inahitajika',
      'locationPermissionMessage': 'Ili kuonyesha bidhaa karibu nawe, tunahitaji ufikiaji wa eneo lako. Tafadhali wezesha ruhusa za eneo katika mipangilio ya kifaa chako.',
      'openSettings': 'Fungua Mipangilio',
      'errorLoadingProducts': 'Hitilafu ya kupakia bidhaa',
      'enableLocationBasedSorting': 'Washa upangaji kulingana na eneo',
      'disableLocationBasedSorting': 'Zima upangaji kulingana na eneo',
      
      // Product Detail
      'addToCart': 'Ongeza kwenye Mkoba',
      'messageSeller': 'Tumia Ujumbe kwa Muuzaji',
      'follow': 'Fuata',
      'description': 'Maelezo',
      'price': 'Bei',
      'category': 'Jamii',
      'location': 'Eneo',
      'signInRequired': 'Kuingia Kunahtajika',
      'signInToAction': 'Unahitaji kuingia ili {action}. Ungependa kuingia sasa?',
      'cancel': 'Ghairi',
      'likes': 'Likes',
      'comments': 'Maoni',
      'rating': 'Ukadiriaji',
      'productAddedToCart': 'Bidhaa imeongezwa kwenye mkoba kwa mafanikio🎉',
      
      // Cart
      'cartNotAvailable': 'Mkoba Haupatikani',
      'cartNotAvailableMsg': 'Kama {type}, unaweza kuuza bidhaa tu, sio kununua.',
      'cartEmpty': 'Mkoba wako ni tupu',
      'selectedTotal': 'Jumla ya Kuchaguliwa',
      'shipping': 'Usafiri',
      'tax': 'Ushuru',
      'discount': 'Punguzo',
      'totalAmount': 'Jumla ya Kiasi',
      'checkout': 'Maliza',
      'supplier': 'Msambazaji',
      'user': 'Mtumiaji',
      
      // Search
      'searchProducts': 'Tafuta bidhaa...',
      'searchForProducts': 'Tafuta bidhaa',
      'showingResults': 'Matokeo 112k\nInaonyesha Matokeo kwa "Swali la Utafutaji"',
      
      // Profile
      'guestUser': 'Mtumiaji Mgeni',
      'browseAsGuest': 'Vinjari kama mgeni',
      'signInToContinue': 'Ingia ili Kuendelea',
      'followers': 'Wafuasi',
      'soldProducts': 'bidhaa zilizouzwa',
      'myInventory': 'Hifadhi Yangu',
      'inventoryDesc': 'Angalia, Unda na Simamia Bidhaa Zako',
      'customerOrders': 'Maagizo ya Wateja',
      'customerOrdersDesc': 'Angalia na simamia maagizo kutoka kwa wateja wako',
      'myOrders': 'Maagizo Yangu',
      'myOrdersDesc': 'Angalia na simamia maagizo yako ya ununuzi',
      'walletPayment': 'Pochi na Njia za Malipo',
      'walletDesc': 'Simamia njia zako za malipo zilizohifadhiwa',
      'myAddresses': 'Anwani Zangu',
      'addressesDesc': 'Angalia na simamia anwani zako za usafiri zilizohifadhiwa',
      'settings': 'Mipangilio',
      'settingsDesc': 'Simamia mipangilio ya akaunti yako',
      'signInToUnlock': 'Ingia ili kufungua hifadhi zote',
      'signInMessage': 'Unda akaunti ili kuongeza bidhaa kwenye mkoba, fanya ununuzi, simamia maagizo, na zaidi.',
      'signInNow': 'Ingia Sasa',
      'manageAccountPreferences': 'Simamia mapendeleo ya akaunti yako',
      'personalInformation': 'Taarifa za Kibinafsi',
      'updatePersonalDetails': 'Sasisha maelezo yako ya kibinafsi kama jina, jina la mtumiaji, barua pepe, na nambari ya simu ili kuweka taarifa za akaunti yako za sasa.',
      'updateProfile': 'Sasisha Wasifu',
      'businessInformation': 'Taarifa za Biashara',
      'updateBusinessDetails': 'Sasisha maelezo ya Biashara yako kama Jina la Duka, Aina ya Duka, ili kuweka taarifa za akaunti yako za sasa.',
      'updateBusinessDetailsTitle': 'Sasisha Maelezo ya Biashara',
      'updateBusinessDetailsSubtitle': 'Sasisha maelezo ya Biashara yako kama Jina la Duka, Aina ya Duka, ili kuweka taarifa za akaunti yako za sasa.',
      'setPickupLocation': 'Weka Eneo la Kuchukua',
      'setPickupLocationSubtitle': 'Weka eneo la biashara yako kwa usafiri. Wanunuzi wanaweza kutumia Sokoni Africa Logistics ikiwa eneo limewekwa.',
      'setPickupLocationDesc': 'Weka eneo la biashara yako kwa usafiri. Wanunuzi wanaweza kutumia Sokoni Africa Logistics ikiwa eneo limewekwa.',
      'general': 'Jumla',
      'salesAnalytics': 'Uchambuzi wa Mauzo',
      'notification': 'Arifa',
      'notifications': 'Arifa',
      'unreadNotificationsCount': 'Arifa {count} zisizosomwa',
      'allCaughtUp': 'Uko tayari!',
      'loadingNotifications': 'Inapakia arifa...',
      'noNotificationsYet': 'Hakuna arifa bado',
      'youreAllCaughtUp': 'Uko tayari!',
      'markAllAsRead': 'Weka zote kama zimesomwa',
      'deleteAll': 'Futa zote',
      'deleteNotification': 'Futa Arifa',
      'areYouSureDeleteNotification': 'Je, una uhakika unataka kufuta arifa hii?',
      'notificationDeleted': 'Arifa imefutwa',
      'errorDeletingNotification': 'Hitilafu ya kufuta arifa',
      'deleteAllNotifications': 'Futa Arifa Zote',
      'areYouSureDeleteAllNotifications': 'Je, una uhakika unataka kufuta arifa {count} zote? Kitendo hiki hakiwezi kufutwa.',
      'deletedNotificationsCount': 'Arifa {count} zimefutwa',
      'errorDeletingNotifications': 'Hitilafu ya kufuta arifa',
      'errorLoadingNotifications': 'Hitilafu ya kupakia arifa',
      'errorMarkingAllAsRead': 'Hitilafu ya kuweka zote kama zimesomwa',
      'errorLoadingProduct': 'Hitilafu ya kupakia bidhaa',
      'pleaseSignInToFollowUsers': 'Tafadhali ingia ili kufuata watumiaji',
      'youAreNowFollowing': 'Sasa unamfuata {username}',
      'youUnfollowed': 'Hukumfuata tena {username}',
      'failedToFollow': 'Kushindwa kufuata',
      'following': 'Unamfuata',
      'readMore': 'Soma zaidi',
      'readLess': 'Soma kidogo',
      'activityNotifications': 'Arifa za Shughuli',
      'enableDisablePushNotifications': 'Washa au zima arifa za kushinikiza kwa sasisho za wakati halisi',
      'activityNotificationsEnabled': 'Arifa za shughuli zimewashwa',
      'activityNotificationsDisabled': 'Arifa za shughuli zimezimwa',
      'promotionsOffers': 'Matangazo na Matoleo',
      'getPushNotificationsForOffers': 'Pata arifa za kushinikiza wakati wowote kuna matoleo',
      'promotionsNotificationsEnabled': 'Arifa za matangazo zimewashwa',
      'promotionsNotificationsDisabled': 'Arifa za matangazo zimezimwa',
      'directEmailNotification': 'Arifa ya Barua pepe ya Moja kwa Moja',
      'getNotifiedViaEmail': 'Pata arifa kwa barua pepe kwa shughuli muhimu za akaunti',
      'emailNotificationsEnabled': 'Arifa za barua pepe zimewashwa',
      'emailNotificationsDisabled': 'Arifa za barua pepe zimezimwa',
      'appearancePreferences': 'Mwonekano na Mapendeleo',
      'darkMode': 'Hali ya Giza',
      'reduceEyeStrain': 'Punguza msongo wa macho na kuboresha uwezo wa kusoma',
      'darkModeEnabled': 'Hali ya giza imewashwa',
      'darkModeDisabled': 'Hali ya giza imezimwa',
      'languageRegion': 'Lugha na Eneo',
      'accountSupport': 'Akaunti na Msaada',
      'kycAccountVerification': 'KYC na Uthibitishaji wa Akaunti',
      'helpCenter': 'Kituo cha Msaada',
      'reportProblem': 'Ripoti Tatizo',
      'termsPrivacy': 'Masharti na Faragha',
      'logOut': 'Toka',
      'areYouSureLogOut': 'Je, una uhakika unataka kutoka?',
      'failedToUpdateSetting': 'Kushindwa kusasisha mpangilio. Tafadhali ujaribu tena.',
      
      // Inventory
      'manageYourProducts': 'Simamia bidhaa zako',
      'totalProducts': 'Jumla ya Bidhaa',
      'active': 'Inaendelea',
      'pending': 'Inasubiri',
      'createProduct': 'Unda Bidhaa',
      'createYourFirstProduct': 'Unda bidhaa yako ya kwanza kuanza',
      'refresh': 'Onyesha Upya',
      'errorLoadingProducts': 'Hitilafu ya kupakia bidhaa',
      'deleteProduct': 'Futa Bidhaa',
      'areYouSureDeleteProduct': 'Je, una uhakika unataka kufuta "{product}"? Kitendo hiki hakiwezi kufutwa.',
      'productDeleted': 'Bidhaa imefutwa kwa mafanikio',
      'failedToDeleteProduct': 'Kushindwa kufuta bidhaa',
      'noProductsYet': 'Hakuna bidhaa bado',
      'addYourFirstProduct': 'Ongeza bidhaa yako ya kwanza ili kuanza kuuza',
      'addProduct': 'Ongeza Bidhaa',
      'delete': 'Futa',
      
      // Customer Orders
      'manageOrdersFromCustomers': 'Simamia maagizo kutoka kwa wateja wako',
      'pleaseLogInSellerAccount': 'Tafadhali ingia na akaunti ya muuzaji ili kuona maagizo ya wateja.',
      'onlySellersCanView': 'Wauzaji peke yao wanaweza kuona maagizo ya wateja.',
      'failedToInitialiseCustomerOrders': 'Kushindwa kuanzisha maagizo ya wateja: {error}',
      'invalidOrderIdentifier': 'Kitambulisho cha agizo sio sahihi. Tafadhali onyesha upya skrini.',
      'statusUpdatedTo': 'Hali imesasishwa hadi {status}',
      'unableToUpdateStatus': 'Haiwezekani kusasisha hali: {error}',
      'unableToLoadCustomerOrders': 'Haiwezekani kupakia maagizo ya wateja',
      'sellerAccessRequired': 'Ufikiaji wa muuzaji unahitajika',
      'noCustomerOrdersYet': 'Hakuna maagizo ya wateja bado',
      'whenBuyersPlaceOrders': 'Wanunuzi wanapoagiza bidhaa zako zitaonekana hapa.',
      'switchToSellerAccount': 'Badilisha kwa akaunti ya muuzaji ili kusimamia maagizo ya wateja na kuweka wanunuzi wamesasishwa.',
      'tryAgain': 'Jaribu tena',
      'refreshOrders': 'Onyesha upya maagizo',
      'checkAgain': 'Angalia tena',
      'order': 'Agizo',
      'item': 'kitu',
      'items': 'vitu',
      'accept': 'Kubali',
      'reject': 'Kataa',
      'markAsShipped': 'Weka kama Imetumwa',
      'awaitingDeliveryConfirmation': 'Inasubiri uthibitishaji wa uwasilishaji',
      'pending': 'Inasubiri',
      'confirmed': 'Imehakikiwa',
      'processing': 'Inachakata',
      'shipped': 'Imetumwa',
      'delivered': 'Imeletwa',
      'cancelled': 'Imeghairiwa',
      'noItemsAttachedToOrder': 'Hakuna vitu vilivyounganishwa na agizo hili.',
      'moreItem': 'kitu zaidi',
      'moreItems': 'vitu zaidi',
      
      // My Orders
      'trackAndManagePurchases': 'Fuata na simamia ununuzi wako',
      'orderHistoryOnlyForRegistered': 'Historia ya maagizo inapatikana kwa watumiaji waliosajiliwa tu.',
      'signInToContinue': 'Ingia ili Kuendelea',
      'unableToLoadOrders': 'Haiwezekani kupakia maagizo yako',
      'somethingWentWrong': 'Kitu kimekosekana. Tafadhali ujaribu tena.',
      'noOrdersYet': 'Hakuna maagizo bado',
      'browseProductsAndPlaceOrder': 'Vinjari bidhaa na uweke agizo ili uone hapa.',
      'product': 'Bidhaa',
      'products': 'Bidhaa',
      'shippingTo': 'Kusafirisha kwenda:',
      'viewDetails': 'Angalia Maelezo',
      'track': 'Fuata',
      'trackingUpdatesAvailableSoon': 'Sasisho za ufuatiliaji zitapatikana hivi karibuni.',
      'placedOn': 'Imewekwa tarehe',
      'payment': 'Malipo',
      'subtotal': 'Jumla ndogo',
      'shipping': 'Usafiri',
      'discount': 'Punguzo',
      'total': 'Jumla',
      'confirmDelivery': 'Thibitisha Uwasilishaji',
      'confirming': 'Inathibitisha...',
      'invalidOrderIdentifierRefresh': 'Kitambulisho cha agizo sio sahihi. Tafadhali onyesha upya na ujaribu tena.',
      'thanksDeliveryConfirmed': 'Asante! Uwasilishaji umehakikiwa na malipo yametolewa kwa muuzaji.',
      'failedToConfirmDelivery': 'Kushindwa kuthibitisha uwasilishaji: {error}',
      'qty': 'Idadi:',
      'noItemsAvailable': 'Hakuna vitu vinavyopatikana',
      
      // Wallet
      'wallet': 'Pochi',
      'walletPaymentMethods': 'Pochi na Njia za Malipo',
      'manageYourWallet': 'Simamia salio la pochi yako na manunuzi',
      'walletOnlyForRegistered': 'Pochi inapatikana kwa watumiaji waliosajiliwa tu. Tafadhali ingia ili kuendelea.',
      'unableToConnectToServer': 'Haiwezekani kuunganisha na seva. Tafadhali angalia muunganisho wako wa intaneti na hakikisha seva ya backend inaendesha.',
      'walletEndpointNotFound': 'Mwisho wa pochi haujapatikana. Tafadhali hakikisha seva ya backend imesasishwa.',
      'serverErrorWalletTables': 'Hitilafu ya seva. Jedwali za pochi zinaweza kuwa hazijaundwa. Tafadhali endesha uhamishaji wa hifadhidata.',
      'pleaseLogInAgainWallet': 'Tafadhali ingia tena ili kufikia pochi yako.',
      'errorLoadingWallet': 'Hitilafu ya kupakia pochi',
      'topUp': 'Jaza',
      'cashOut': 'Toa Pesa',
      'cashout': 'Tolea',
      'transactionHistory': 'Historia ya Manunuzi',
      'recentTransactions': 'Muamala wa Hivi Karibuni',
      'viewAll': 'Angalia Zote',
      'balance': 'Salio',
      'sokocoinBalance': 'Salio la Sokocoin',
      'keepGrowingYourBalance': 'Endelea kuongeza salio lako la SOK ili kufungua fursa zaidi.',
      'availableBalance': 'Salio Linazopatikana',
      'pendingBalance': 'Salio Linasubiri',
      'totalEarned': 'Jumla ya Mapato',
      'totalSpent': 'Jumla ya Matumizi',
      'noTransactionsYet': 'Hakuna muamala bado',
      'errorLoadingTransactions': 'Hitilafu ya kupakia muamala',
      'topUpTransaction': 'Jaza',
      'cashoutTransaction': 'Tolea',
      'purchaseTransaction': 'Ununuzi',
      'earnedTransaction': 'Imepatikana',
      'refundTransaction': 'Rudisha',
      'feeTransaction': 'Ada',
      'retry': 'Jaribu Tena',
      'deleteSelected': 'Futa Zilizochaguliwa',
      'cancelSelection': 'Ghairi Uchaguzi',
      'selectTransactions': 'Chagua Manunuzi',
      'deleteSelectedTransactions': 'Futa Manunuzi Zilizochaguliwa',
      'areYouSureDeleteSelectedTransactions': 'Je, una uhakika unataka kufuta',
      'transaction': 'muamala',
      'deleted': 'Imefutwa',
      
      // Addresses
      'addressManagementOnlyForRegistered': 'Usimamizi wa anwani unapatikana kwa watumiaji waliosajiliwa tu. Tafadhali ingia ili kuendelea.',
      'failedToLoadAddresses': 'Kushindwa kupakia anwani: {error}',
      'addAddress': 'Ongeza Anwani',
      'editAddress': 'Hariri Anwani',
      'deleteAddress': 'Futa Anwani',
      'areYouSureDeleteAddress': 'Je, una uhakika unataka kufuta anwani hii?',
      'addressDeleted': 'Anwani imefutwa kwa mafanikio',
      'failedToDeleteAddress': 'Kushindwa kufuta anwani',
      'setAsDefault': 'Weka kama Chaguo-msingi',
      'defaultAddress': 'Anwani ya Chaguo-msingi',
      'pickupLocation': 'Eneo la Kuchukua',
      'fullName': 'Jina Kamili',
      'phoneNumber': 'Nambari ya Simu',
      'address': 'Anwani',
      'city': 'Jiji',
      'region': 'Mkoa',
      'postalCode': 'Msimbo wa Posta',
      'saveAddress': 'Hifadhi Anwani',
      'addressSaved': 'Anwani imehifadhiwa kwa mafanikio',
      'failedToSaveAddress': 'Kushindwa kuhifadhi anwani',
      
      // Update Profile
      'profileUpdatesOnlyForRegistered': 'Sasisho za wasifu zinapatikana kwa watumiaji waliosajiliwa tu. Tafadhali ingia ili kuendelea.',
      'updateYourProfile': 'Sasisha taarifa za wasifu wako',
      'selectImageSource': 'Chagua Chanzo cha Picha',
      'camera': 'Kamera',
      'gallery': 'Jukwaa la Picha',
      'profilePicture': 'Picha ya Wasifu',
      'username': 'Jina la Mtumiaji',
      'save': 'Hifadhi',
      'profileUpdated': 'Wasifu umesasishwa kwa mafanikio',
      'failedToUpdateProfile': 'Kushindwa kusasisha wasifu',
      
      // Update Business
      'businessDetailsUpdated': 'Maelezo ya biashara yamesasishwa kwa mafanikio!',
      'shopName': 'Jina la Duka',
      'shopType': 'Aina ya Duka',
      'description': 'Maelezo',
      'website': 'Tovuti',
      
      // Sales Analytics
      'youNeedToBeLoggedInAsSeller': 'Unahitaji kuingia kama muuzaji ili kuona uchambuzi wa mauzo.',
      'needToBeLoggedInAsSeller': 'Unahitaji kuingia kama muuzaji ili kuona uchambuzi wa mauzo.',
      'trackBusinessPerformance': 'Fuatilia utendakazi wa biashara yako',
      'unableToLoadAnalytics': 'Haiwezekani kupakia uchambuzi',
      'failedToLoadAnalytics': 'Kushindwa kupakia uchambuzi: {error}',
      'noAnalyticsDataAvailable': 'Hakuna data ya uchambuzi inayopatikana',
      'salesDataWillAppearHere': 'Data ya mauzo itaonekana hapa mara tu utakapokuwa umepokea maagizo.',
      'noSalesDataForPeriod': 'Hakuna data ya mauzo inayopatikana kwa kipindi hiki',
      'unknownProduct': 'Bidhaa Isiyojulikana',
      'refresh': 'Onyesha Upya',
      'daily': 'Kila Siku',
      'weekly': 'Kila Wiki',
      'monthly': 'Kila Mwezi',
      'yearly': 'Kila Mwaka',
      'all': 'Zote',
      'totalSales': 'Jumla ya Mauzo',
      'totalRevenue': 'Jumla ya Mapato',
      'totalOrders': 'Jumla ya Maagizo',
      'avgOrderValue': 'Thamani ya Wastani ya Agizo',
      'averageOrderValue': 'Thamani ya Wastani ya Agizo',
      'productsSold': 'Bidhaa Zilizouzwa',
      'customers': 'Wateja',
      'salesOverview': 'Muhtasari wa Mauzo',
      'orderStatus': 'Hali ya Agizo',
      'topProducts': 'Bidhaa Bora',
      'topSellingProducts': 'Bidhaa Zinazouza Zaidi',
      'revenueTrends': 'Mienendo ya Mapato',
      
      // KYC Verification
      'kycVerificationOnlyForRegistered': 'Uthibitishaji wa KYC unapatikana kwa watumiaji waliosajiliwa tu. Tafadhali ingia ili kuendelea.',
      'kycOnlyForRegisteredUsers': 'Uthibitishaji wa KYC unapatikana kwa watumiaji waliosajiliwa tu. Tafadhali ingia ili kuendelea.',
      'accountVerified': 'Akaunti Imethibitishwa',
      'verificationPending': 'Uthibitishaji Unasubiri',
      'accountVerifiedSuccessfully': 'Akaunti yako imethibitishwa kwa mafanikio',
      'completeVerificationToUnlock': 'Kamilisha uthibitishaji ili kufungua vipengele vyote',
      'verificationDocument': 'Hati ya Uthibitishaji',
      'kycDocumentInfo': 'Hati moja tu inahitajika kwa uthibitishaji. Pakia picha wazi ya Kitambulisho chako cha Taifa, Pasi, au Leseni ya Udereva.',
      'uploading': 'Inapakia...',
      'replaceDocument': 'Badilisha Hati',
      'uploadDocument': 'Pakia Hati',
      'documentUnderReview': 'Hati yako inakaguliwa. Utataarifiwa mara tu uthibitishaji utakapokamilika.',
      'documentUploadedSuccessfully': 'Hati imepakiwa kwa mafanikio! Itakaguliwa hivi karibuni.',
      'selectDocumentSource': 'Chagua Chanzo cha Hati',
      'camera': 'Kamera',
      'gallery': 'Jukwaa la Picha',
      'errorPickingDocument': 'Hitilafu ya kuchagua hati',
      'pleaseLoginToUploadKYC': 'Tafadhali ingia ili kupakia hati ya KYC',
      'documentType': 'Aina ya Hati',
      'nationalId': 'Kitambulisho cha Taifa',
      'passport': 'Pasi',
      'driversLicense': 'Leseni ya Udereva',
      'documentStatus': 'Hali ya Hati',
      'pending': 'Inasubiri',
      'underReview': 'Inakaguliwa',
      'approved': 'Imeidhinishwa',
      'rejected': 'Imekataliwa',
      'verified': 'Imehakikiwa',
      'notVerified': 'Haijahakikiwa',
      'documentUploaded': 'Hati imepakiwa kwa mafanikio',
      'failedToUploadDocument': 'Kushindwa kupakia hati',
      
      // Help Center
      'findAnswersToCommonQuestions': 'Pata majibu ya maswali ya kawaida',
      'searchForHelp': 'Tafuta msaada...',
      'noResultsFound': 'Hakuna matokeo yaliyopatikana',
      'trySearchingWithDifferentKeywords': 'Jaribu kutafuta kwa maneno muhimu tofauti',
      'stillNeedHelp': 'Bado unahitaji msaada?',
      'contactOurSupportTeam': 'Wasiliana na timu yetu ya msaada kwa msaada wa kibinafsi',
      'email': 'Barua pepe',
      'call': 'Piga Simu',
      'openingYourEmailApp': 'Inafungua programu yako ya barua pepe...',
      'couldNotOpenEmailApp': 'Haiwezekani kufungua programu ya barua pepe.',
      'emailAddressCopiedToClipboard': 'Anwani ya barua pepe imenakiliwa kwenye ubao wa kunakili: {email}',
      'couldNotOpenDialer': 'Haiwezekani kufungua kipiga simu. Nambari ya msaada imenakiliwa: {number}',
      'unableToMakeCall': 'Haiwezekani kupiga simu ({error}). Nambari ya msaada imenakiliwa: {number}',
      'faq': 'Maswali Yanayoulizwa Mara kwa Mara',
      'answer': 'Jibu',
      'wasThisHelpful': 'Hii ilisaidia?',
      'yesHelpful': 'Ndiyo, Ilisaidia',
      'notHelpful': 'Haikusaidia',
      'thankYouForYourFeedback': 'Asante kwa maoni yako!',
      
      // Report Problem
      'reportingProblemsOnlyForRegistered': 'Kuripoti matatizo kunapatikana kwa watumiaji waliosajiliwa tu. Tafadhali ingia ili kuendelea.',
      'reportAProblem': 'Ripoti Tatizo',
      'describeYourIssue': 'Eleza tatizo lako na tutakusaidia kulitatua',
      'category': 'Jamii',
      'selectCategory': 'Chagua Jamii',
      'general': 'Jumla',
      'technical': 'Kiufundi',
      'payment': 'Malipo',
      'order': 'Agizo',
      'account': 'Akaunti',
      'other': 'Nyingine',
      'subject': 'Somo',
      'enterSubject': 'Ingiza somo',
      'pleaseEnterSubject': 'Tafadhali ingiza somo',
      'description': 'Maelezo',
      'enterDescription': 'Ingiza maelezo',
      'pleaseEnterDescription': 'Tafadhali ingiza maelezo',
      'submitReport': 'Wasilisha Ripoti',
      'reportSubmitted': 'Ripoti imewasilishwa kwa mafanikio',
      'failedToSubmitReport': 'Kushindwa kuwasilisha ripoti',
      'couldNotOpenEmailAppForReport': 'Haiwezekani kufungua programu ya barua pepe. Anwani ya barua pepe imenakiliwa kwenye ubao wa kunakili.',
      
      // Terms & Privacy
      'termsPrivacy': 'Masharti na Faragha',
      'termsOfService': 'Masharti ya Huduma',
      'privacyPolicy': 'Sera ya Faragha',
      'lastUpdated': 'Iliyosasishwa mwisho: {year}',
      'welcomeToSokoniAfrica': 'Karibu Sokoni Afrika. Kwa kutumia jukwaa letu, unakubali masharti yafuatayo:',
      'accountResponsibility': 'Jukumu la Akaunti',
      'userConduct': 'Tabia ya Mtumiaji',
      'productListings': 'Orodha ya Bidhaa',
      'payments': 'Malipo',
      'limitationOfLiability': 'Kikomo cha Jukumu',
      'changesToTerms': 'Mabadiliko ya Masharti',
      'yourPrivacyIsImportant': 'Faragha yako ni muhimu kwetu. Sera hii inaeleza jinsi tunavyokusanya, kutumia, na kulinda taarifa zako:',
      'informationWeCollect': 'Taarifa Tunazokusanya',
      'howWeUseYourInformation': 'Jinsi Tunavyotumia Taarifa Zako',
      'informationSharing': 'Kushiriki Taarifa',
      'dataSecurity': 'Usalama wa Data',
      'yourRights': 'Haki Zako',
      'contactUs': 'Wasiliana Nasi',
      
      // Signup
      'createAccount': 'Unda Akaunti',
      'joinSokoniAfricaToday': 'Jiunge na Sokoni Afrika leo',
      'chooseUsername': 'Chagua jina la mtumiaji',
      'email': 'Barua pepe',
      'enterEmail': 'Ingiza barua pepe yako',
      'pleaseEnterEmail': 'Tafadhali ingiza barua pepe yako',
      'pleaseEnterValidEmail': 'Tafadhali ingiza barua pepe halali',
      'enterPhoneNumber': 'Ingiza nambari ya simu',
      'createPassword': 'Unda nenosiri',
      'confirmPassword': 'Thibitisha Nenosiri',
      'reEnterPassword': 'Ingiza tena nenosiri lako',
      'passwordsDoNotMatch': 'Nenosiri hazifanani',
      'alreadyHaveAccount': 'Tayari una akaunti?',
      'signupSuccessful': 'Kujisajili kumefanikiwa!',
      'registrationFailed': 'Kujisajili kumeshindwa. Tafadhali ujaribu tena.',
      'passwordTooLong': 'Nenosiri lazima liwe herufi 72 au chini',
      'passwordMustBeAtLeast': 'Nenosiri lazima liwe angalau herufi 6',
      'confirmYourPassword': 'Thibitisha nenosiri lako',
      'pleaseConfirmYourPassword': 'Tafadhali thibitisha nenosiri lako',
      
      // Forgot Password
      'resetPassword': 'Weka Upya Nenosiri',
      'enterPhoneToReceiveOTP': 'Ingiza nambari yako ya simu ili kupokea OTP ya kuweka upya nenosiri',
      'enterEmailToReceiveCode': 'Ingiza barua pepe inayohusishwa na akaunti yako ili kupokea msimbo wa kuweka upya.',
      'sendOTP': 'Tuma OTP',
      'sendResetEmail': 'Tuma Barua pepe ya Kuweka Upya',
      'emailAddress': 'Anwani ya Barua pepe',
      'backToLogin': 'Rudi kwenye Kuingia',
      'otpSentSuccessfully': 'OTP imetumwa kwa mafanikio',
      'failedToSendOTP': 'Kushindwa kutuma OTP',
      'resetEmailSentSuccessfully': 'Barua pepe ya kuweka upya imetumwa kwa mafanikio',
      'failedToSendResetEmail': 'Kushindwa kutuma barua pepe ya kuweka upya',
      'phoneOTP': 'OTP ya Simu',
      'receiveCodeBySMS': 'Pokea msimbo kwa SMS',
      'receiveCodeViaEmail': 'Pokea msimbo kwa barua pepe',
      'thisEmailNotRegistered': 'Barua pepe hii haijasajiliwa. Tafadhali ingiza barua pepe inayohusishwa na akaunti yako au tumia chaguo la simu.',
      'emailResetNotAvailable': 'Kuweka upya kwa barua pepe bado haipatikani. Tafadhali tumia chaguo la nambari ya simu.',
      'enterValidEmail': 'Tafadhali ingiza barua pepe halali',
      'you@example.com': 'wewe@mfano.com',
      'enterOTP': 'Ingiza OTP',
      'verifyOTP': 'Thibitisha OTP',
      'enterNewPassword': 'Ingiza Nenosiri Jipya',
      'createNewPassword': 'Unda nenosiri lako jipya',
      'newPassword': 'Nenosiri Jipya',
      'confirmNewPassword': 'Thibitisha Nenosiri Jipya',
      'resetPasswordSuccessfully': 'Nenosiri limewekwa upya kwa mafanikio!',
      'failedToResetPassword': 'Kushindwa kuweka upya nenosiri',
      'pleaseEnterOTP': 'Tafadhali ingiza OTP',
      'pleaseEnter6DigitOTP': 'Tafadhali ingiza OTP ya tarakimu 6',
      'weSentVerificationCode': 'Tumetuma msimbo wa uthibitishaji kwa {contact}',
      'otpEntered': 'OTP imeingizwa. Sasa ingiza nenosiri lako jipya.',
      'enterOTPCode': 'Ingiza Msimbo wa OTP',
      
      // Create Product
      'createProduct': 'Unda Bidhaa',
      'productType': 'Aina ya Bidhaa',
      'product': 'Bidhaa',
      'liveAuction': 'Mnada wa Moja kwa Moja',
      'productImages': 'Picha za Bidhaa',
      'addUpToImages': 'Ongeza hadi picha 10. Picha ya kwanza itakuwa picha kuu ya bidhaa.',
      'addPhoto': 'Ongeza Picha',
      'productDetails': 'Maelezo ya Bidhaa',
      'productTitle': 'Kichwa cha Bidhaa',
      'titleHint': 'Kwa upatikanaji wa haraka tumia kichwa kifupi na rahisi.',
      'unitType': 'Aina ya Kitengo',
      'priceHint': 'Sasisha hii mara kwa mara.',
      'descriptionHint': 'Sasisha hii mara kwa mara.',
      'settingsFeatures': 'Mipangilio na Vipengele',
      'wingaMode': 'Hali ya Winga',
      'wingaDesc': 'Washa hii, wateja wa nje wanaweza kuweka bidhaa zako',
      'warranty': 'Dhamana',
      'warrantyDesc': 'Washa dhamana ya mwaka ya bidhaa ili kupata uaminifu zaidi',
      'privateProduct': 'Bidhaa ya Kibinafsi',
      'privateDesc': 'Wafuasi wako peke yake wanaweza kuona bidhaa hii',
      'adultContent': 'Maudhui ya Watu Wazima',
      'adultDesc': 'Watumiaji wenye umri wa miaka 18+ peke yake wanaweza kuona bidhaa hii',
      'pleaseAddImage': 'Tafadhali ongeza angalau picha moja ya bidhaa',
      'productCreated': 'Bidhaa imeundwa na picha {count}!',
      'maximumImages': 'Kiwango cha juu cha picha 10 kuruhusiwa',
      'chooseFromGallery': 'Chagua kutoka kwa Makusanyo',
      'takePhoto': 'Chukua Picha',
      'removeAllImages': 'Ondoa Picha Zote',
      'main': 'Kuu',
      
      // Language & Region
      'languageAndRegion': 'Lugha na Eneo',
      'customizeAppPreferences': 'Badilisha mapendeleo ya programu yako',
      'language': 'Lugha',
      'region': 'Eneo',
      'selectRegion': 'Chagua Eneo',
      'languageUpdatedSuccessfully': 'Lugha imesasishwa kwa mafanikio!',
      'regionUpdatedSuccessfully': 'Eneo limesasishwa kwa mafanikio!',
      'tanzania': 'Tanzania',
      'kenya': 'Kenya',
      'uganda': 'Uganda',
      'rwanda': 'Rwanda',
      
      // Topup
      'topUpWallet': 'Jaza Pochi',
      'topUpWalletInfo': 'Jaza pochi yako na Sokocoin kwa kutumia lango la malipo la Flutterwave.',
      'pleaseEnterMobileMoneyPhone': 'Tafadhali ingiza nambari ya simu ya pesa za simu.',
      'paymentNotVerifiedYet': 'Malipo hayajathibitishwa bado. Tafadhali maliza malipo na ujaribu tena.',
      'completePayment': 'Maliza Malipo',
      'newTabOpenedFlutterwave': 'Tabo mpya imefunguliwa na checkout ya Flutterwave. Maliza malipo hapo, kisha bofya "Thibitisha Malipo" hapa chini.',
      'verifyPayment': 'Thibitisha Malipo',
      'invalidPaymentURL': 'URL ya malipo sio sahihi.',
      'couldNotOpenPaymentPage': 'Haiwezekani kufungua ukurasa wa malipo.',
      
      // Cashout
      'cashoutTitle': 'Tolea',
      'sokocoinAmount': 'Kiasi cha Sokocoin',
      'enterAmountToCashout': 'Ingiza kiasi cha kutolea',
      'pleaseEnterAmountToCashout': 'Tafadhali ingiza kiasi',
      'pleaseEnterValidAmountToCashout': 'Tafadhali ingiza kiasi halali',
      'amountExceedsBalance': 'Kiasi kinazidi salio linazopatikana',
      'minimumCashoutIs10': 'Kiwango cha chini cha kutolea ni 10 SOK',
      'insufficientSokocoinBalance': 'Salio la Sokocoin halitoshi',
      'payoutMethod': 'Njia ya Malipo',
      'accountNumber': 'Nambari ya Akaunti',
      'pleaseEnterAccountNumber': 'Tafadhali ingiza nambari ya akaunti',
      'bankName': 'Jina la Benki',
      'pleaseEnterBankName': 'Tafadhali ingiza jina la benki',
      'accountName': 'Jina la Akaunti',
      'pleaseEnterAccountName': 'Tafadhali ingiza jina la akaunti',
      'initiateCashout': 'Anzisha Kutolea',
      'cashoutError': 'Hitilafu ya Kutolea',
      'invalidPayoutAccountDetails': 'Maelezo ya akaunti ya malipo sio sahihi',
      'paymentGatewayConfigurationIssue': 'Tatizo la usanidi wa lango la malipo',
      'pleaseCheckPayoutDetails': 'Tafadhali angalia maelezo yako ya malipo na ujaribu tena.',
      'pleaseCheckPayoutDetailsOrContact': 'Tafadhali angalia maelezo yako ya malipo na ujaribu tena au wasiliana na msaada ikiwa tatizo linaendelea.',
      'cashoutInitiatedSuccessfully': 'Kutolea kumeanzishwa kwa mafanikio',
      'failedToInitiateCashout': 'Kushindwa kuanzisha kutolea',
      'willBeWithdrawn': '≈ {amount} itatolewa.',
      'formatPhoneNumber': 'Muundo: {code}XXXXXXXX',
      'enterAccountNumber': 'Ingiza nambari ya akaunti',
      'enterBankName': 'Ingiza jina la benki',
      'enterAccountHolderName': 'Ingiza jina la mmiliki wa akaunti',
      
      // Transaction History
      'filterTransactions': 'Chuja Manunuzi',
      'deleteAll': 'Futa Zote',
      'yourTransactionHistoryWillAppearHere': 'Historia yako ya manunuzi itaonekana hapa',
      'type': 'Aina',
      'reference': 'Marejeo',
      'exchangeRate': 'Kiwango cha Ubadilishaji',
      'areYouSureDeleteTransaction': 'Je, una uhakika unataka kufuta muamala huu?',
      'noteCompletedTransactionsCannotBeDeleted': 'Kumbuka: Hii ni muamala uliokamilika. Kuufuta kutaondoa kutoka kwenye historia yako lakini kunaweza kuathiri rekodi zako.',
      'deleteTransaction': 'Futa Muamala',
      'transactionDeletedSuccessfully': 'Muamala umefutwa kwa mafanikio',
      'deleteAllTransactions': 'Futa Manunuzi Yote',
      'areYouSureDeleteAllTransactions': 'Je, una uhakika unataka kufuta manunuzi yote?',
      'thisWillDeleteAllFailedCancelledPending': 'Hii itafuta manunuzi yote yaliyoshindwa, yaliyofutwa, na yanayosubiri.',
      'noteCompletedTransactionsWillBeKept': 'Kumbuka: Manunuzi yaliyokamilika yatahifadhiwa kwani yanaathiri salio lako la pochi.',
      'totalTransactions': 'Jumla ya Manunuzi',
      'filtered': 'Yamechujwa',
      'allTypes': 'Aina Zote',
      'allStatuses': 'Hali Zote',
      'apply': 'Tumia',
      'clearAll': 'Futa Zote',
      'transactionType': 'Aina ya Muamala',
      'status': 'Hali',
      'completed': 'Imekamilika',
      'failed': 'Imeshindwa',
      
      // Common
      'error': 'Hitilafu',
      'success': 'Mafanikio',
      'loading': 'Inapakia',
      'loadingProducts': 'Inapakia bidhaa...',
      'settingsOnlyForRegisteredUsers': 'Mipangilio inapatikana kwa watumiaji waliosajiliwa tu. Tafadhali ingia ili kuendelea.',
      'posts': 'Machapisho',
      'sold': 'Zilizouzwa',
    },
  };
  
  String translate(String key, {Map<String, String>? params}) {
    String value = _localizedValues[locale.languageCode]?[key] ?? 
                   _localizedValues['en']?[key] ?? 
                   key;
    
    if (params != null) {
      params.forEach((paramKey, paramValue) {
        value = value.replaceAll('{$paramKey}', paramValue);
      });
    }
    
    return value;
  }
  
  // Getters for translations
  String get selectLanguage => translate('selectLanguage');
  String get chooseLanguage => translate('chooseLanguage');
  String get swahili => translate('swahili');
  String get swahiliDesc => translate('swahiliDesc');
  String get english => translate('english');
  String get englishDesc => translate('englishDesc');
  String get continueText => translate('continue');
  String get getStarted => translate('getStarted');
  String get selectGender => translate('selectGender');
  String get selectYourGender => translate('selectYourGender');
  String get ladiesGirls => translate('ladiesGirls');
  String get ladiesDesc => translate('ladiesDesc');
  String get gentsBoys => translate('gentsBoys');
  String get gentsDesc => translate('gentsDesc');
  String get selectAccountType => translate('selectAccountType');
  String get howToUseSokoni => translate('howToUseSokoni');
  String get sokoniClient => translate('sokoniClient');
  String get clientDesc => translate('clientDesc');
  String get sokoniSupplier => translate('sokoniSupplier');
  String get supplierDesc => translate('supplierDesc');
  String get sokoniRetailer => translate('sokoniRetailer');
  String get retailerDesc => translate('retailerDesc');
  String get welcomeAboard => translate('welcomeAboard');
  String get selectHowToContinue => translate('selectHowToContinue');
  String get termsNote => translate('termsNote');
  String get google => translate('google');
  String get or => translate('or');
  String get phoneNumberHint => translate('phoneNumberHint');
  String get phoneNumber => translate('phoneNumber');
  String get continueAsGuest => translate('continueAsGuest');
  String get loggedInAsGuest => translate('loggedInAsGuest');
  String get guestLoginFailed => translate('guestLoginFailed');
  String get weFlexSecurity => translate('weFlexSecurity');
  String get provideOTP => translate('provideOTP');
  String sentTo(String number) => '${translate('sentTo')}: $number';
  String get didntReceiveCode => translate('didntReceiveCode');
  String get resendOTP => translate('resendOTP');
  String get changePhoneNumber => translate('changePhoneNumber');
  String get verifyPhone => translate('verifyPhone');
  String get home => translate('home');
  String get search => translate('search');
  String get cart => translate('cart');
  String get inventory => translate('inventory');
  String get messages => translate('messages');
  String get profile => translate('profile');
  String get sokoniAfrica => translate('sokoniAfrica');
  String get testAPI => translate('testAPI');
  String get noProductsFound => translate('noProductsFound');
  String get retry => translate('retry');
  String get discoverAndShop => translate('discoverAndShop');
  String get discoverRealProducts => translate('discoverRealProducts');
  String get secure => translate('secure');
  String get fastDelivery => translate('fastDelivery');
  String get trusted => translate('trusted');
  String get all => translate('all');
  String get electronics => translate('electronics');
  String get fashion => translate('fashion');
  String get food => translate('food');
  String get beauty => translate('beauty');
  String get homeKitchen => translate('homeKitchen');
  String get sports => translate('sports');
  String get automotives => translate('automotives');
  String get books => translate('books');
  String get kids => translate('kids');
  String get agriculture => translate('agriculture');
  String get artCraft => translate('artCraft');
  String get computerSoftware => translate('computerSoftware');
  String get healthWellness => translate('healthWellness');
  String get unableToGetLocation => translate('unableToGetLocation');
  String get errorGettingLocation => translate('errorGettingLocation');
  String get locationPermissionRequired => translate('locationPermissionRequired');
  String get locationPermissionMessage => translate('locationPermissionMessage');
  String get openSettings => translate('openSettings');
  String get errorLoadingProducts => translate('errorLoadingProducts');
  String get enableLocationBasedSorting => translate('enableLocationBasedSorting');
  String get disableLocationBasedSorting => translate('disableLocationBasedSorting');
  String get addToCart => translate('addToCart');
  String get messageSeller => translate('messageSeller');
  String get follow => translate('follow');
  String get description => translate('description');
  String get price => translate('price');
  String get category => translate('category');
  String get location => translate('location');
  String get seller => translate('seller');
  String get signInRequired => translate('signInRequired');
  String signInToAction(String action) => translate('signInToAction', params: {'action': action});
  String get cancel => translate('cancel');
  String get signIn => translate('signIn');
  String get username => translate('username');
  String get usernameOrEmail => translate('usernameOrEmail');
  String get enterUsernameOrEmail => translate('enterUsernameOrEmail');
  String get password => translate('password');
  String get enterPassword => translate('enterPassword');
  String get forgotPassword => translate('forgotPassword');
  String get dontHaveAccount => translate('dontHaveAccount');
  String get signUp => translate('signUp');
  String get loginSuccessful => translate('loginSuccessful');
  String welcomeUser(String name) => translate('welcomeUser', params: {'name': name});
  String get startingGoogleSignIn => translate('startingGoogleSignIn');
  String get googleSignInFailed => translate('googleSignInFailed');
  String get googleAccountAlreadyRegistered => translate('googleAccountAlreadyRegistered');
  String get usernameAlreadyTaken => translate('usernameAlreadyTaken');
  String get accountAlreadyExists => translate('accountAlreadyExists');
  String get connectionError => translate('connectionError');
  String get googleAuthFailed => translate('googleAuthFailed');
  String get googleSignInConfigError => translate('googleSignInConfigError');
  String get serverError => translate('serverError');
  String get googleSignInFailedTryAgain => translate('googleSignInFailedTryAgain');
  String get googleSignInNetworkTitle => translate('googleSignInNetworkTitle');
  String get googleSignInNetworkMessageSignIn => translate('googleSignInNetworkMessageSignIn');
  String get googleSignInNetworkMessageSignUp => translate('googleSignInNetworkMessageSignUp');
  String get useNormalSignIn => translate('useNormalSignIn');
  String get useNormalSignUp => translate('useNormalSignUp');
  String get googleSignInSetupRequired => translate('googleSignInSetupRequired');
  String get ok => translate('ok');
  String get completeGoogleSignIn => translate('completeGoogleSignIn');
  String get buyer => translate('buyer');
  String get both => translate('both');
  String get userTypeNotFound => translate('userTypeNotFound');
  String get failedToGetGoogleToken => translate('failedToGetGoogleToken');
  String get googleSignInNotConfigured => translate('googleSignInNotConfigured');
  String get pleaseEnterUsername => translate('pleaseEnterUsername');
  String get usernameTooShort => translate('usernameTooShort');
  String get pleaseEnterPassword => translate('pleaseEnterPassword');
  String get passwordTooShort => translate('passwordTooShort');
  String get invalidCredentials => translate('invalidCredentials');
  String get loginFailed => translate('loginFailed');
  String get welcomeBack => translate('welcomeBack');
  String get signInToContinueShopping => translate('signInToContinueShopping');
  String get usernameEmailOrPhone => translate('usernameEmailOrPhone');
  String get enterUsernameEmailOrPhone => translate('enterUsernameEmailOrPhone');
  String get pleaseEnterUsernameEmailOrPhone => translate('pleaseEnterUsernameEmailOrPhone');
  String get enterYourPassword => translate('enterYourPassword');
  String get pleaseEnterYourPassword => translate('pleaseEnterYourPassword');
  String get passwordMustBeAtLeast6 => translate('passwordMustBeAtLeast6');
  String get passwordMustBe72OrLess => translate('passwordMustBe72OrLess');
  String get continueWithGoogle => translate('continueWithGoogle');
  String get googleSignInUnavailable => translate('googleSignInUnavailable');
  String get accountDoesntHavePassword => translate('accountDoesntHavePassword');
  String get incorrectCredentials => translate('incorrectCredentials');
  String get userNotFound => translate('userNotFound');
  String get accountInactive => translate('accountInactive');
  String get connectionTimeout => translate('connectionTimeout');
  String get networkError => translate('networkError');
  String get loginFailedTitle => translate('loginFailedTitle');
  String get googleSignInConfigErrorDetails => translate('googleSignInConfigErrorDetails');
  String get createAccount => translate('createAccount');
  String get joinSokoniAfricaToday => translate('joinSokoniAfricaToday');
  String get chooseUsername => translate('chooseUsername');
  String get email => translate('email');
  String get enterEmail => translate('enterEmail');
  String get pleaseEnterEmail => translate('pleaseEnterEmail');
  String get pleaseEnterValidEmail => translate('pleaseEnterValidEmail');
  String get enterPhoneNumber => translate('enterPhoneNumber');
  String get createPassword => translate('createPassword');
  String get confirmPassword => translate('confirmPassword');
  String get reEnterPassword => translate('reEnterPassword');
  String get passwordsDoNotMatch => translate('passwordsDoNotMatch');
  String get alreadyHaveAccount => translate('alreadyHaveAccount');
  String get signupSuccessful => translate('signupSuccessful');
  String get registrationFailed => translate('registrationFailed');
  String get passwordTooLong => translate('passwordTooLong');
  String get passwordMustBeAtLeast => translate('passwordMustBeAtLeast');
  String get confirmYourPassword => translate('confirmYourPassword');
  String get pleaseConfirmYourPassword => translate('pleaseConfirmYourPassword');
  String get resetPassword => translate('resetPassword');
  String get enterPhoneToReceiveOTP => translate('enterPhoneToReceiveOTP');
  String get enterEmailToReceiveCode => translate('enterEmailToReceiveCode');
  String get sendOTP => translate('sendOTP');
  String get sendResetEmail => translate('sendResetEmail');
  String get emailAddress => translate('emailAddress');
  String get backToLogin => translate('backToLogin');
  String get otpSentSuccessfully => translate('otpSentSuccessfully');
  String get failedToSendOTP => translate('failedToSendOTP');
  String get resetEmailSentSuccessfully => translate('resetEmailSentSuccessfully');
  String get failedToSendResetEmail => translate('failedToSendResetEmail');
  String get phoneOTP => translate('phoneOTP');
  String get receiveCodeBySMS => translate('receiveCodeBySMS');
  String get receiveCodeViaEmail => translate('receiveCodeViaEmail');
  String get thisEmailNotRegistered => translate('thisEmailNotRegistered');
  String get emailResetNotAvailable => translate('emailResetNotAvailable');
  String get enterValidEmail => translate('enterValidEmail');
  String get youExampleCom => translate('you@example.com');
  String get enterOTP => translate('enterOTP');
  String get verifyOTP => translate('verifyOTP');
  String get enterNewPassword => translate('enterNewPassword');
  String get createNewPassword => translate('createNewPassword');
  String get newPassword => translate('newPassword');
  String get confirmNewPassword => translate('confirmNewPassword');
  String get resetPasswordSuccessfully => translate('resetPasswordSuccessfully');
  String get failedToResetPassword => translate('failedToResetPassword');
  String get pleaseEnterOTP => translate('pleaseEnterOTP');
  String get pleaseEnter6DigitOTP => translate('pleaseEnter6DigitOTP');
  String weSentVerificationCode(String contact) => translate('weSentVerificationCode').replaceAll('{contact}', contact);
  String get otpEntered => translate('otpEntered');
  String get enterOTPCode => translate('enterOTPCode');
  String get likes => translate('likes');
  String get comments => translate('comments');
  String get rating => translate('rating');
  String get productAddedToCart => translate('productAddedToCart');
  String get cartNotAvailable => translate('cartNotAvailable');
  String cartNotAvailableMsg(String type) => translate('cartNotAvailableMsg', params: {'type': type});
  String get cartEmpty => translate('cartEmpty');
  String get selectedTotal => translate('selectedTotal');
  String get shipping => translate('shipping');
  String get tax => translate('tax');
  String get discount => translate('discount');
  String get totalAmount => translate('totalAmount');
  String get checkout => translate('checkout');
  String get supplier => translate('supplier');
  String get user => translate('user');
  String get searchProducts => translate('searchProducts');
  String get searchForProducts => translate('searchForProducts');
  String get showingResults => translate('showingResults');
  String get guestUser => translate('guestUser');
  String get browseAsGuest => translate('browseAsGuest');
  String get signInToContinue => translate('signInToContinue');
  String get followers => translate('followers');
  String get soldProducts => translate('soldProducts');
  String get myInventory => translate('myInventory');
  String get inventoryDesc => translate('inventoryDesc');
  String get manageYourProducts => translate('manageYourProducts');
  String get totalProducts => translate('totalProducts');
  String get active => translate('active');
  String get pending => translate('pending');
  String get createProduct => translate('createProduct');
  String get createYourFirstProduct => translate('createYourFirstProduct');
  String get refresh => translate('refresh');
  String get deleteProduct => translate('deleteProduct');
  String areYouSureDeleteProduct(String product) => translate('areYouSureDeleteProduct', params: {'product': product});
  String get productDeleted => translate('productDeleted');
  String get failedToDeleteProduct => translate('failedToDeleteProduct');
  String get noProductsYet => translate('noProductsYet');
  String get addYourFirstProduct => translate('addYourFirstProduct');
  String get addProduct => translate('addProduct');
  String get delete => translate('delete');
  String get customerOrders => translate('customerOrders');
  String get customerOrdersDesc => translate('customerOrdersDesc');
  String get manageOrdersFromCustomers => translate('manageOrdersFromCustomers');
  String get pleaseLogInSellerAccount => translate('pleaseLogInSellerAccount');
  String get onlySellersCanView => translate('onlySellersCanView');
  String get failedToInitialiseCustomerOrders => translate('failedToInitialiseCustomerOrders');
  String get invalidOrderIdentifier => translate('invalidOrderIdentifier');
  String statusUpdatedTo(String status) => translate('statusUpdatedTo', params: {'status': status});
  String unableToUpdateStatus(String error) => translate('unableToUpdateStatus', params: {'error': error});
  String get unableToLoadCustomerOrders => translate('unableToLoadCustomerOrders');
  String get sellerAccessRequired => translate('sellerAccessRequired');
  String get noCustomerOrdersYet => translate('noCustomerOrdersYet');
  String get whenBuyersPlaceOrders => translate('whenBuyersPlaceOrders');
  String get switchToSellerAccount => translate('switchToSellerAccount');
  String get tryAgain => translate('tryAgain');
  String get refreshOrders => translate('refreshOrders');
  String get checkAgain => translate('checkAgain');
  String get order => translate('order');
  String get item => translate('item');
  String get items => translate('items');
  String get accept => translate('accept');
  String get reject => translate('reject');
  String get markAsShipped => translate('markAsShipped');
  String get awaitingDeliveryConfirmation => translate('awaitingDeliveryConfirmation');
  String get confirmed => translate('confirmed');
  String get processing => translate('processing');
  String get shipped => translate('shipped');
  String get delivered => translate('delivered');
  String get cancelled => translate('cancelled');
  String get noItemsAttachedToOrder => translate('noItemsAttachedToOrder');
  String get moreItem => translate('moreItem');
  String get moreItems => translate('moreItems');
  String get myOrders => translate('myOrders');
  String get myOrdersDesc => translate('myOrdersDesc');
  String get trackAndManagePurchases => translate('trackAndManagePurchases');
  String get orderHistoryOnlyForRegistered => translate('orderHistoryOnlyForRegistered');
  String get unableToLoadOrders => translate('unableToLoadOrders');
  String get somethingWentWrong => translate('somethingWentWrong');
  String get noOrdersYet => translate('noOrdersYet');
  String get browseProductsAndPlaceOrder => translate('browseProductsAndPlaceOrder');
  String get product => translate('product');
  String get products => translate('products');
  String get shippingTo => translate('shippingTo');
  String get viewDetails => translate('viewDetails');
  String get track => translate('track');
  String get trackingUpdatesAvailableSoon => translate('trackingUpdatesAvailableSoon');
  String get placedOn => translate('placedOn');
  String get payment => translate('payment');
  String get subtotal => translate('subtotal');
  String get total => translate('total');
  String get confirmDelivery => translate('confirmDelivery');
  String get confirming => translate('confirming');
  String get invalidOrderIdentifierRefresh => translate('invalidOrderIdentifierRefresh');
  String get thanksDeliveryConfirmed => translate('thanksDeliveryConfirmed');
  String failedToConfirmDelivery(String error) => translate('failedToConfirmDelivery', params: {'error': error});
  String get qty => translate('qty');
  String get noItemsAvailable => translate('noItemsAvailable');
  String get wallet => translate('wallet');
  String get walletPayment => translate('walletPayment');
  String get walletDesc => translate('walletDesc');
  String get walletPaymentMethods => translate('walletPaymentMethods');
  String get walletPaymentMethodsOnlyRegistered => translate('walletPaymentMethodsOnlyRegistered');
  String get manageYourWallet => translate('manageYourWallet');
  String get walletOnlyForRegistered => translate('walletOnlyForRegistered');
  String get unableToConnectToServer => translate('unableToConnectToServer');
  String get walletEndpointNotFound => translate('walletEndpointNotFound');
  String get serverErrorWalletTables => translate('serverErrorWalletTables');
  String get pleaseLogInAgainWallet => translate('pleaseLogInAgainWallet');
  String get errorLoadingWallet => translate('errorLoadingWallet');
  String get topUp => translate('topUp');
  String get cashOut => translate('cashOut');
  String get cashout => translate('cashout');
  String get transactionHistory => translate('transactionHistory');
  String get recentTransactions => translate('recentTransactions');
  String get viewAll => translate('viewAll');
  String get balance => translate('balance');
  String get sokocoinBalance => translate('sokocoinBalance');
  String get keepGrowingYourBalance => translate('keepGrowingYourBalance');
  String get availableBalance => translate('availableBalance');
  String get pendingBalance => translate('pendingBalance');
  String get totalEarned => translate('totalEarned');
  String get totalSpent => translate('totalSpent');
  String get noTransactionsYet => translate('noTransactionsYet');
  String get errorLoadingTransactions => translate('errorLoadingTransactions');
  String get topUpTransaction => translate('topUpTransaction');
  String get cashoutTransaction => translate('cashoutTransaction');
  String get purchaseTransaction => translate('purchaseTransaction');
  String get earnedTransaction => translate('earnedTransaction');
  String get refundTransaction => translate('refundTransaction');
  String get feeTransaction => translate('feeTransaction');
  String get myAddresses => translate('myAddresses');
  String get addressesDesc => translate('addressesDesc');
  String get settings => translate('settings');
  String get settingsDesc => translate('settingsDesc');
  String get manageAccountPreferences => translate('manageAccountPreferences');
  String get personalInformation => translate('personalInformation');
  String get updatePersonalDetails => translate('updatePersonalDetails');
  String get updateProfile => translate('updateProfile');
  String get businessInformation => translate('businessInformation');
  String get updateBusinessDetails => translate('updateBusinessDetails');
  String get updateBusinessDetailsTitle => translate('updateBusinessDetailsTitle');
  String get updateBusinessDetailsSubtitle => translate('updateBusinessDetailsSubtitle');
  String get setPickupLocation => translate('setPickupLocation');
  String get setPickupLocationSubtitle => translate('setPickupLocationSubtitle');
  String get setPickupLocationDesc => translate('setPickupLocationDesc');
  String get general => translate('general');
  String get salesAnalytics => translate('salesAnalytics');
  String get trackBusinessPerformance => translate('trackBusinessPerformance');
  String get needToBeLoggedInAsSeller => translate('needToBeLoggedInAsSeller');
  String get unableToLoadAnalytics => translate('unableToLoadAnalytics');
  String get failedToLoadAnalytics => translate('failedToLoadAnalytics');
  String get noAnalyticsDataAvailable => translate('noAnalyticsDataAvailable');
  String get salesDataWillAppearHere => translate('salesDataWillAppearHere');
  String get noSalesDataForPeriod => translate('noSalesDataForPeriod');
  String get totalRevenue => translate('totalRevenue');
  String get totalOrders => translate('totalOrders');
  String get avgOrderValue => translate('avgOrderValue');
  String get productsSold => translate('productsSold');
  String get customers => translate('customers');
  String get salesOverview => translate('salesOverview');
  String get orderStatus => translate('orderStatus');
  String get topProducts => translate('topProducts');
  String get unknownProduct => translate('unknownProduct');
  String get daily => translate('daily');
  String get weekly => translate('weekly');
  String get monthly => translate('monthly');
  String get yearly => translate('yearly');
  String get notification => translate('notification');
  String get notifications => translate('notifications');
  String get unreadNotificationsCount => translate('unreadNotificationsCount');
  String get allCaughtUp => translate('allCaughtUp');
  String get loadingNotifications => translate('loadingNotifications');
  String get noNotificationsYet => translate('noNotificationsYet');
  String get youreAllCaughtUp => translate('youreAllCaughtUp');
  String get markAllAsRead => translate('markAllAsRead');
  String get deleteAll => translate('deleteAll');
  String get deleteNotification => translate('deleteNotification');
  String get areYouSureDeleteNotification => translate('areYouSureDeleteNotification');
  String get notificationDeleted => translate('notificationDeleted');
  String get errorDeletingNotification => translate('errorDeletingNotification');
  String get deleteAllNotifications => translate('deleteAllNotifications');
  String get areYouSureDeleteAllNotifications => translate('areYouSureDeleteAllNotifications');
  String get deletedNotificationsCount => translate('deletedNotificationsCount');
  String get errorDeletingNotifications => translate('errorDeletingNotifications');
  String get errorLoadingNotifications => translate('errorLoadingNotifications');
  String get errorMarkingAllAsRead => translate('errorMarkingAllAsRead');
  String get errorLoadingProduct => translate('errorLoadingProduct');
  String get pleaseSignInToFollowUsers => translate('pleaseSignInToFollowUsers');
  String get youAreNowFollowing => translate('youAreNowFollowing');
  String get youUnfollowed => translate('youUnfollowed');
  String get failedToFollow => translate('failedToFollow');
  String get following => translate('following');
  String get readMore => translate('readMore');
  String get readLess => translate('readLess');
  String get activityNotifications => translate('activityNotifications');
  String get enableDisablePushNotifications => translate('enableDisablePushNotifications');
  String get activityNotificationsEnabled => translate('activityNotificationsEnabled');
  String get activityNotificationsDisabled => translate('activityNotificationsDisabled');
  String get promotionsOffers => translate('promotionsOffers');
  String get getPushNotificationsForOffers => translate('getPushNotificationsForOffers');
  String get promotionsNotificationsEnabled => translate('promotionsNotificationsEnabled');
  String get promotionsNotificationsDisabled => translate('promotionsNotificationsDisabled');
  String get directEmailNotification => translate('directEmailNotification');
  String get getNotifiedViaEmail => translate('getNotifiedViaEmail');
  String get emailNotificationsEnabled => translate('emailNotificationsEnabled');
  String get emailNotificationsDisabled => translate('emailNotificationsDisabled');
  String get appearancePreferences => translate('appearancePreferences');
  String get darkMode => translate('darkMode');
  String get reduceEyeStrain => translate('reduceEyeStrain');
  String get darkModeEnabled => translate('darkModeEnabled');
  String get darkModeDisabled => translate('darkModeDisabled');
  String get languageRegion => translate('languageRegion');
  String get accountSupport => translate('accountSupport');
  String get kycAccountVerification => translate('kycAccountVerification');
  String get kycOnlyForRegisteredUsers => translate('kycOnlyForRegisteredUsers');
  String get accountVerified => translate('accountVerified');
  String get verificationPending => translate('verificationPending');
  String get accountVerifiedSuccessfully => translate('accountVerifiedSuccessfully');
  String get completeVerificationToUnlock => translate('completeVerificationToUnlock');
  String get verificationDocument => translate('verificationDocument');
  String get kycDocumentInfo => translate('kycDocumentInfo');
  String get uploading => translate('uploading');
  String get replaceDocument => translate('replaceDocument');
  String get uploadDocument => translate('uploadDocument');
  String get documentUnderReview => translate('documentUnderReview');
  String get selectDocumentSource => translate('selectDocumentSource');
  String get camera => translate('camera');
  String get gallery => translate('gallery');
  String get errorPickingDocument => translate('errorPickingDocument');
  String get pleaseLoginToUploadKYC => translate('pleaseLoginToUploadKYC');
  String get documentUploadedSuccessfully => translate('documentUploadedSuccessfully');
  String get failedToUploadDocument => translate('failedToUploadDocument');
  String get helpCenter => translate('helpCenter');
  String get findAnswersCommonQuestions => translate('findAnswersToCommonQuestions');
  String get searchForHelp => translate('searchForHelp');
  String get noResultsFound => translate('noResultsFound');
  String get trySearchingDifferentKeywords => translate('trySearchingWithDifferentKeywords');
  String get stillNeedHelp => translate('stillNeedHelp');
  String get contactSupportTeam => translate('contactOurSupportTeam');
  String get call => translate('call');
  String get openingEmailApp => translate('openingYourEmailApp');
  String get couldNotOpenEmailApp => translate('couldNotOpenEmailApp');
  String get emailAddressCopiedToClipboard => translate('emailAddressCopiedToClipboard');
  String get couldNotOpenDialer => translate('couldNotOpenDialer');
  String get unableToMakeCall => translate('unableToMakeCall');
  String get faq => translate('faq');
  String get answer => translate('answer');
  String get wasThisHelpful => translate('wasThisHelpful');
  String get yesHelpful => translate('yesHelpful');
  String get notHelpful => translate('notHelpful');
  String get thankYouForYourFeedback => translate('thankYouForYourFeedback');
  String get reportProblem => translate('reportProblem');
  String get helpUsImproveReportingIssues => translate('helpUsImproveReportingIssues');
  String get bugReport => translate('bugReport');
  String get featureRequest => translate('featureRequest');
  String get paymentIssue => translate('paymentIssue');
  String get orderIssue => translate('orderIssue');
  String get pleaseSelectCategory => translate('pleaseSelectCategory');
  String get pleaseEnterSubject => translate('pleaseEnterSubject');
  String get pleaseDescribeProblem => translate('pleaseDescribeProblem');
  String get pleaseProvideMoreDetails => translate('pleaseProvideMoreDetails');
  String get submitReport => translate('submitReport');
  String get reportSentViaEmail => translate('reportSentViaEmail');
  String get openingEmailAppPleaseSend => translate('openingEmailAppPleaseSend');
  String get failedToSubmitReport => translate('failedToSubmitReport');
  String get reportingProblemsOnlyRegistered => translate('reportingProblemsOnlyRegistered');
  String get unableToOpenEmailApp => translate('unableToOpenEmailApp');
  String get other => translate('other');
  String get subject => translate('subject');
  String get termsPrivacy => translate('termsPrivacy');
  String get termsOfService => translate('termsOfService');
  String get privacyPolicy => translate('privacyPolicy');
  String get lastUpdated => translate('lastUpdated');
  String get welcomeToSokoniAfrica => translate('welcomeToSokoniAfrica');
  String get accountResponsibility => translate('accountResponsibility');
  String get maintainAccountConfidentiality => translate('maintainAccountConfidentiality');
  String get provideAccurateInformation => translate('provideAccurateInformation');
  String get mustBe18YearsOld => translate('mustBe18YearsOld');
  String get userConduct => translate('userConduct');
  String get notUsePlatformIllegal => translate('notUsePlatformIllegal');
  String get notPostFalseInformation => translate('notPostFalseInformation');
  String get respectOtherUsers => translate('respectOtherUsers');
  String get productListings => translate('productListings');
  String get productDescriptionsAccurate => translate('productDescriptionsAccurate');
  String get sellersResponsibleQuality => translate('sellersResponsibleQuality');
  String get sokoniReservesRightRemove => translate('sokoniReservesRightRemove');
  String get payments => translate('payments');
  String get allTransactionsProcessedSecurely => translate('allTransactionsProcessedSecurely');
  String get refundsSubjectToPolicy => translate('refundsSubjectToPolicy');
  String get reserveRightSuspendAccounts => translate('reserveRightSuspendAccounts');
  String get limitationOfLiability => translate('limitationOfLiability');
  String get sokoniNotLiableTransactions => translate('sokoniNotLiableTransactions');
  String get providePlatformNotParty => translate('providePlatformNotParty');
  String get usersResponsibleResolvingDisputes => translate('usersResponsibleResolvingDisputes');
  String get changesToTerms => translate('changesToTerms');
  String get mayUpdateTermsTime => translate('mayUpdateTermsTime');
  String get continuedUseConstitutesAcceptance => translate('continuedUseConstitutesAcceptance');
  String get yourPrivacyImportant => translate('yourPrivacyImportant');
  String get informationWeCollect => translate('informationWeCollect');
  String get accountInformation => translate('accountInformation');
  String get deviceInformationUsageData => translate('deviceInformationUsageData');
  String get howWeUseInformation => translate('howWeUseInformation');
  String get provideImproveServices => translate('provideImproveServices');
  String get processTransactions => translate('processTransactions');
  String get communicateAboutAccount => translate('communicateAboutAccount');
  String get sendPromotionalOffers => translate('sendPromotionalOffers');
  String get ensurePlatformSecurity => translate('ensurePlatformSecurity');
  String get informationSharing => translate('informationSharing');
  String get doNotSellPersonalInformation => translate('doNotSellPersonalInformation');
  String get mayShareServiceProviders => translate('mayShareServiceProviders');
  String get mayDiscloseRequiredByLaw => translate('mayDiscloseRequiredByLaw');
  String get dataSecurity => translate('dataSecurity');
  String get implementSecurityMeasures => translate('implementSecurityMeasures');
  String get noMethodTransmissionSecure => translate('noMethodTransmissionSecure');
  String get responsibleKeepingCredentialsSecure => translate('responsibleKeepingCredentialsSecure');
  String get yourRights => translate('yourRights');
  String get accessUpdatePersonalInformation => translate('accessUpdatePersonalInformation');
  String get requestDeletionAccount => translate('requestDeletionAccount');
  String get optOutMarketingCommunications => translate('optOutMarketingCommunications');
  String get cookiesTracking => translate('cookiesTracking');
  String get useCookiesImproveExperience => translate('useCookiesImproveExperience');
  String get controlCookieSettingsBrowser => translate('controlCookieSettingsBrowser');
  String get childrensPrivacy => translate('childrensPrivacy');
  String get servicesNotIntendedUnder18 => translate('servicesNotIntendedUnder18');
  String get doNotKnowinglyCollectChildren => translate('doNotKnowinglyCollectChildren');
  String get contactUs => translate('contactUs');
  String get questionsAboutPolicy => translate('questionsAboutPolicy');
  String get iUnderstand => translate('iUnderstand');
  String get logOut => translate('logOut');
  String get areYouSureLogOut => translate('areYouSureLogOut');
  String get failedToUpdateSetting => translate('failedToUpdateSetting');
  String get signInToUnlock => translate('signInToUnlock');
  String get signInMessage => translate('signInMessage');
  String get signInNow => translate('signInNow');
  String get productType => translate('productType');
  String get liveAuction => translate('liveAuction');
  String get productImages => translate('productImages');
  String get addUpToImages => translate('addUpToImages');
  String get addPhoto => translate('addPhoto');
  String get productDetails => translate('productDetails');
  String get productTitle => translate('productTitle');
  String get titleHint => translate('titleHint');
  String get unitType => translate('unitType');
  String get priceHint => translate('priceHint');
  String get descriptionHint => translate('descriptionHint');
  String get settingsFeatures => translate('settingsFeatures');
  String get wingaMode => translate('wingaMode');
  String get wingaDesc => translate('wingaDesc');
  String get warranty => translate('warranty');
  String get warrantyDesc => translate('warrantyDesc');
  String get privateProduct => translate('privateProduct');
  String get privateDesc => translate('privateDesc');
  String get adultContent => translate('adultContent');
  String get adultDesc => translate('adultDesc');
  String get pleaseAddImage => translate('pleaseAddImage');
  String productCreated(int count) => translate('productCreated', params: {'count': count.toString()});
  String get maximumImages => translate('maximumImages');
  String get chooseFromGallery => translate('chooseFromGallery');
  String get takePhoto => translate('takePhoto');
  String get removeAllImages => translate('removeAllImages');
  String get main => translate('main');
  String get error => translate('error');
  String get success => translate('success');
  String get loading => translate('loading');
  String get languageAndRegion => translate('languageAndRegion');
  String get customizeAppPreferences => translate('customizeAppPreferences');
  String get language => translate('language');
  String get region => translate('region');
  String get selectRegion => translate('selectRegion');
  String get languageUpdatedSuccessfully => translate('languageUpdatedSuccessfully');
  String get regionUpdatedSuccessfully => translate('regionUpdatedSuccessfully');
  String get tanzania => translate('tanzania');
  String get kenya => translate('kenya');
  String get uganda => translate('uganda');
  String get rwanda => translate('rwanda');
  String get loadingProducts => translate('loadingProducts');
  String get settingsOnlyForRegisteredUsers => translate('settingsOnlyForRegisteredUsers');
  String get posts => translate('posts');
  String get sold => translate('sold');
  
  // Topup
  String get topUpWallet => translate('topUpWallet');
  String get topUpWalletInfo => translate('topUpWalletInfo');
  String get amount => translate('amount');
  String get enterAmount => translate('enterAmount');
  String get pleaseEnterAmount => translate('pleaseEnterAmount');
  String get pleaseEnterValidAmount => translate('pleaseEnterValidAmount');
  String get minimumAmountIs100 => translate('minimumAmountIs100');
  String get currency => translate('currency');
  String get paymentMethod => translate('paymentMethod');
  String get creditDebitCard => translate('creditDebitCard');
  String get mobileMoney => translate('mobileMoney');
  String get bankTransfer => translate('bankTransfer');
  String get mobileMoneyPhoneNumber => translate('mobileMoneyPhoneNumber');
  String get continueToPayment => translate('continueToPayment');
  String get paymentCompletedSuccessfully => translate('paymentCompletedSuccessfully');
  String get paymentNotCompleted => translate('paymentNotCompleted');
  String get topUpCompletedTestMode => translate('topUpCompletedTestMode');
  String get failedToInitializePayment => translate('failedToInitializePayment');
  String get paymentError => translate('paymentError');
  String get possibleCauses => translate('possibleCauses');
  String get paymentGatewayNotConfigured => translate('paymentGatewayNotConfigured');
  String get networkConnectionIssue => translate('networkConnectionIssue');
  String get invalidPaymentDetails => translate('invalidPaymentDetails');
  String get pleaseTryAgainOrContactSupport => translate('pleaseTryAgainOrContactSupport');
  String get pleaseEnterMobileMoneyPhone => translate('pleaseEnterMobileMoneyPhone');
  String get usePhoneRegisteredWallet => translate('usePhoneRegisteredWallet');
  String get ensurePhoneMatchesWallet => translate('ensurePhoneMatchesWallet');
  String get examplePhoneNumber => translate('examplePhoneNumber');
  String get enterPhoneWithCountryCode => translate('enterPhoneWithCountryCode');
  String get paymentNotVerifiedYet => translate('paymentNotVerifiedYet');
  String get completePayment => translate('completePayment');
  String get newTabOpenedFlutterwave => translate('newTabOpenedFlutterwave');
  String get verifyPayment => translate('verifyPayment');
  String get invalidPaymentURL => translate('invalidPaymentURL');
  String get couldNotOpenPaymentPage => translate('couldNotOpenPaymentPage');
  
  // Cashout
  String get cashoutTitle => translate('cashoutTitle');
  String get sokocoinAmount => translate('sokocoinAmount');
  String get enterAmountToCashout => translate('enterAmountToCashout');
  String get pleaseEnterAmountToCashout => translate('pleaseEnterAmountToCashout');
  String get pleaseEnterValidAmountToCashout => translate('pleaseEnterValidAmountToCashout');
  String get amountExceedsBalance => translate('amountExceedsBalance');
  String get minimumCashoutIs10 => translate('minimumCashoutIs10');
  String get insufficientSokocoinBalance => translate('insufficientSokocoinBalance');
  String get payoutMethod => translate('payoutMethod');
  String get accountNumber => translate('accountNumber');
  String get pleaseEnterAccountNumber => translate('pleaseEnterAccountNumber');
  String get bankName => translate('bankName');
  String get pleaseEnterBankName => translate('pleaseEnterBankName');
  String get accountName => translate('accountName');
  String get pleaseEnterAccountName => translate('pleaseEnterAccountName');
  String get initiateCashout => translate('initiateCashout');
  String get cashoutError => translate('cashoutError');
  String get invalidPayoutAccountDetails => translate('invalidPayoutAccountDetails');
  String get paymentGatewayConfigurationIssue => translate('paymentGatewayConfigurationIssue');
  String get pleaseCheckPayoutDetails => translate('pleaseCheckPayoutDetails');
  String get pleaseCheckPayoutDetailsOrContact => translate('pleaseCheckPayoutDetailsOrContact');
  String get cashoutInitiatedSuccessfully => translate('cashoutInitiatedSuccessfully');
  String get failedToInitiateCashout => translate('failedToInitiateCashout');
  String get willBeWithdrawn => translate('willBeWithdrawn');
  String get formatPhoneNumber => translate('formatPhoneNumber');
  String get enterAccountNumber => translate('enterAccountNumber');
  String get enterBankName => translate('enterBankName');
  String get enterAccountHolderName => translate('enterAccountHolderName');
  
  // Transaction History
  String get filterTransactions => translate('filterTransactions');
  String get yourTransactionHistoryWillAppearHere => translate('yourTransactionHistoryWillAppearHere');
  String get type => translate('type');
  String get reference => translate('reference');
  String get deleteSelected => translate('deleteSelected');
  String get cancelSelection => translate('cancelSelection');
  String get selectTransactions => translate('selectTransactions');
  String get deleteSelectedTransactions => translate('deleteSelectedTransactions');
  String get areYouSureDeleteSelectedTransactions => translate('areYouSureDeleteSelectedTransactions');
  String get transaction => translate('transaction');
  String get deleted => translate('deleted');
  String get exchangeRate => translate('exchangeRate');
  String get areYouSureDeleteTransaction => translate('areYouSureDeleteTransaction');
  String get noteCompletedTransactionsCannotBeDeleted => translate('noteCompletedTransactionsCannotBeDeleted');
  String get deleteTransaction => translate('deleteTransaction');
  String get transactionDeletedSuccessfully => translate('transactionDeletedSuccessfully');
  String get deleteAllTransactions => translate('deleteAllTransactions');
  String get areYouSureDeleteAllTransactions => translate('areYouSureDeleteAllTransactions');
  String get thisWillDeleteAllFailedCancelledPending => translate('thisWillDeleteAllFailedCancelledPending');
  String get noteCompletedTransactionsWillBeKept => translate('noteCompletedTransactionsWillBeKept');
  String get totalTransactions => translate('totalTransactions');
  String get filtered => translate('filtered');
  String get allTypes => translate('allTypes');
  String get allStatuses => translate('allStatuses');
  String get apply => translate('apply');
  String get clearAll => translate('clearAll');
  String get transactionType => translate('transactionType');
  String get status => translate('status');
  String get completed => translate('completed');
  String get failed => translate('failed');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();
  
  @override
  bool isSupported(Locale locale) => ['en', 'sw'].contains(locale.languageCode);
  
  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }
  
  @override
  bool shouldReload(_AppLocalizationsDelegate old) => true;
}

// Wrapper delegate that ensures MaterialLocalizations fallback for Swahili
class _SafeMaterialLocalizationsDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  const _SafeMaterialLocalizationsDelegate();
  
  static const _englishDelegate = GlobalMaterialLocalizations.delegate;

  @override
  bool isSupported(Locale locale) => true; // Always support, will fallback

  @override
  Future<MaterialLocalizations> load(Locale locale) async {
    // If Swahili, load English MaterialLocalizations as fallback
    if (locale.languageCode == 'sw') {
      return await _englishDelegate.load(const Locale('en'));
    }
    // Otherwise use default delegate
    return await _englishDelegate.load(locale);
  }

  @override
  bool shouldReload(_SafeMaterialLocalizationsDelegate old) => false;
}

// Export the safe delegate
const safeMaterialLocalizationsDelegate = _SafeMaterialLocalizationsDelegate();

class LanguageService extends ChangeNotifier {
  static final LanguageService _instance = LanguageService._internal();
  factory LanguageService() => _instance;
  LanguageService._internal();
  
  Locale _currentLocale = const Locale('en');
  
  Locale get currentLocale => _currentLocale;
  
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString(AppConstants.keyLanguage);
    // Handle both 'swahili'/'english' and 'sw'/'en' formats
    if (savedLanguage == null || savedLanguage.isEmpty) {
      _currentLocale = const Locale('en');
    } else if (savedLanguage == 'swahili' || savedLanguage == 'sw') {
      _currentLocale = const Locale('sw');
    } else {
      _currentLocale = const Locale('en');
    }
    notifyListeners();
  }
  
  Future<void> setLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyLanguage, language);
    final newLocale = Locale(language == 'swahili' ? 'sw' : 'en');
    
    // Always update locale and notify listeners, even if same
    // This ensures MaterialApp rebuilds and all screens get updated locale
    if (_currentLocale != newLocale) {
      _currentLocale = newLocale;
    }
    
    // Force notify all listeners to rebuild the app immediately
    // This will trigger MaterialApp rebuild in main.dart via _onLanguageChanged
    // MaterialApp will rebuild with new locale, and all screens will get new AppLocalizations
    notifyListeners();
    
    // Small delay to ensure all listeners have processed the change
    await Future.delayed(const Duration(milliseconds: 50));
  }
  
  String get languageCode => _currentLocale.languageCode;
  bool get isSwahili => _currentLocale.languageCode == 'sw';
  bool get isEnglish => _currentLocale.languageCode == 'en';
}

