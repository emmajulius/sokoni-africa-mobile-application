import 'package:flutter/material.dart';
import '../../services/language_service.dart';

class TermsPrivacyScreen extends StatefulWidget {
  const TermsPrivacyScreen({super.key});

  @override
  State<TermsPrivacyScreen> createState() => _TermsPrivacyScreenState();
}

class _TermsPrivacyScreenState extends State<TermsPrivacyScreen> {
  final LanguageService _languageService = LanguageService();

  @override
  void initState() {
    super.initState();
    _languageService.addListener(_onLanguageChanged);
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.termsPrivacy ?? 'Terms & Privacy'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0F0F0F),
                    Color(0xFF1A1A1A),
                  ],
                )
              : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFF9FAFB),
                    Colors.white,
                  ],
                ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Terms of Service
              _buildSection(
                context: context,
                title: l10n?.termsOfService ?? 'Terms of Service',
                content: '''
${l10n != null ? l10n.lastUpdated.replaceAll('{year}', DateTime.now().year.toString()) : 'Last updated: ${DateTime.now().year}'}

${l10n?.welcomeToSokoniAfrica ?? 'Welcome to Sokoni Africa. By using our platform, you agree to the following terms:'}

1. ${l10n?.accountResponsibility ?? 'Account Responsibility'}
   - ${l10n?.maintainAccountConfidentiality ?? 'You are responsible for maintaining the confidentiality of your account'}
   - ${l10n?.provideAccurateInformation ?? 'You must provide accurate and complete information'}
   - ${l10n?.mustBe18YearsOld ?? 'You must be at least 18 years old to use our services'}

2. ${l10n?.userConduct ?? 'User Conduct'}
   - ${l10n?.notUsePlatformIllegal ?? 'You agree not to use the platform for illegal purposes'}
   - ${l10n?.notPostFalseInformation ?? 'You will not post false, misleading, or fraudulent information'}
   - ${l10n?.respectOtherUsers ?? 'You will respect other users and their rights'}

3. ${l10n?.productListings ?? 'Product Listings'}
   - ${l10n?.productDescriptionsAccurate ?? 'All product descriptions must be accurate'}
   - ${l10n?.sellersResponsibleQuality ?? 'Sellers are responsible for product quality and delivery'}
   - ${l10n?.sokoniReservesRightRemove ?? 'Sokoni Africa reserves the right to remove listings that violate our policies'}

4. ${l10n?.payments ?? 'Payments'}
   - ${l10n?.allTransactionsProcessedSecurely ?? 'All transactions are processed securely'}
   - ${l10n?.refundsSubjectToPolicy ?? 'Refunds are subject to our refund policy'}
   - ${l10n?.reserveRightSuspendAccounts ?? 'We reserve the right to suspend accounts for payment issues'}

5. ${l10n?.limitationOfLiability ?? 'Limitation of Liability'}
   - ${l10n?.sokoniNotLiableTransactions ?? 'Sokoni Africa is not liable for transactions between users'}
   - ${l10n?.providePlatformNotParty ?? 'We provide a platform for buying and selling but are not a party to transactions'}
   - ${l10n?.usersResponsibleResolvingDisputes ?? 'Users are responsible for resolving disputes'}

6. ${l10n?.changesToTerms ?? 'Changes to Terms'}
   - ${l10n?.mayUpdateTermsTime ?? 'We may update these terms from time to time'}
   - ${l10n?.continuedUseConstitutesAcceptance ?? 'Continued use of the platform constitutes acceptance of changes'}
              ''',
            ),
            const SizedBox(height: 32),
              // Privacy Policy
              _buildSection(
                context: context,
                title: l10n?.privacyPolicy ?? 'Privacy Policy',
                content: '''
${l10n != null ? l10n.lastUpdated.replaceAll('{year}', DateTime.now().year.toString()) : 'Last updated: ${DateTime.now().year}'}

${l10n?.yourPrivacyImportant ?? 'Your privacy is important to us. This policy explains how we collect, use, and protect your information:'}

1. ${l10n?.informationWeCollect ?? 'Information We Collect'}
   - ${l10n?.personalInformation ?? 'Personal information (name, email, phone number)'}
   - ${l10n?.accountInformation ?? 'Account information (username, password)'}
   - ${l10n?.transactionHistory ?? 'Transaction history'}
   - ${l10n?.deviceInformationUsageData ?? 'Device information and usage data'}

2. ${l10n?.howWeUseInformation ?? 'How We Use Your Information'}
   - ${l10n?.provideImproveServices ?? 'To provide and improve our services'}
   - ${l10n?.processTransactions ?? 'To process transactions'}
   - ${l10n?.communicateAboutAccount ?? 'To communicate with you about your account'}
   - ${l10n?.sendPromotionalOffers ?? 'To send promotional offers (with your consent)'}
   - ${l10n?.ensurePlatformSecurity ?? 'To ensure platform security'}

3. ${l10n?.informationSharing ?? 'Information Sharing'}
   - ${l10n?.doNotSellPersonalInformation ?? 'We do not sell your personal information'}
   - ${l10n?.mayShareServiceProviders ?? 'We may share information with service providers who assist us'}
   - ${l10n?.mayDiscloseRequiredByLaw ?? 'We may disclose information if required by law'}

4. ${l10n?.dataSecurity ?? 'Data Security'}
   - ${l10n?.implementSecurityMeasures ?? 'We implement security measures to protect your data'}
   - ${l10n?.noMethodTransmissionSecure ?? 'However, no method of transmission is 100% secure'}
   - ${l10n?.responsibleKeepingCredentialsSecure ?? 'You are responsible for keeping your account credentials secure'}

5. ${l10n?.yourRights ?? 'Your Rights'}
   - ${l10n?.accessUpdatePersonalInformation ?? 'You can access and update your personal information'}
   - ${l10n?.requestDeletionAccount ?? 'You can request deletion of your account'}
   - ${l10n?.optOutMarketingCommunications ?? 'You can opt-out of marketing communications'}

6. ${l10n?.cookiesTracking ?? 'Cookies and Tracking'}
   - ${l10n?.useCookiesImproveExperience ?? 'We use cookies to improve your experience'}
   - ${l10n?.controlCookieSettingsBrowser ?? 'You can control cookie settings in your browser'}

7. ${l10n?.childrensPrivacy ?? 'Children\'s Privacy'}
   - ${l10n?.servicesNotIntendedUnder18 ?? 'Our services are not intended for users under 18'}
   - ${l10n?.doNotKnowinglyCollectChildren ?? 'We do not knowingly collect information from children'}

8. ${l10n?.contactUs ?? 'Contact Us'}
   ${l10n?.questionsAboutPolicy ?? 'If you have questions about this policy, please contact us at support@sokoni.africa'}
              ''',
            ),
            const SizedBox(height: 32),
              // Accept Button
              Container(
                margin: const EdgeInsets.only(top: 16),
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: isDark
                      ? LinearGradient(
                          colors: [
                            Colors.white,
                            Colors.white.withOpacity(0.9),
                          ],
                        )
                      : LinearGradient(
                          colors: [
                            const Color(0xFF667EEA),
                            const Color(0xFF667EEA).withOpacity(0.9),
                          ],
                        ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.white.withOpacity(0.2)
                          : const Color(0xFF667EEA).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(16),
                      child: Container(
                      alignment: Alignment.center,
                      child: Text(
                        l10n?.iUnderstand ?? 'I Understand',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: isDark
                              ? const Color(0xFF667EEA)
                              : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required String content,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sectionColor = title.contains('Terms')
        ? const Color(0xFF2196F3)
        : const Color(0xFF9C27B0);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Colors.white.withOpacity(0.05),
                  Colors.white.withOpacity(0.02),
                ]
              : [
                  sectionColor.withOpacity(0.08),
                  sectionColor.withOpacity(0.03),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : sectionColor.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : sectionColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      sectionColor.withOpacity(0.2),
                      sectionColor.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: sectionColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  title.contains('Terms')
                      ? Icons.description_rounded
                      : Icons.privacy_tip_rounded,
                  color: sectionColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: TextStyle(
              fontSize: 15,
              height: 1.7,
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

