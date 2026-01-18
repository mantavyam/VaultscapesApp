import 'package:shadcn_flutter/shadcn_flutter.dart';

/// In-app Privacy Policy screen
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      headers: [
        AppBar(
          title: const Text('Privacy Policy'),
        ),
      ],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Privacy Policy',
              style: theme.typography.h2,
            ),
            const SizedBox(height: 8),
            Text('Effective Date: January 16, 2026').muted(),
            const SizedBox(height: 24),

            // Introduction
            _buildParagraph(
              theme,
              'This Privacy Policy applies to the Vaultscapes app (hereinafter referred to as the "Application"), accessible via web link or mobile devices, created by Shivam Singh (hereinafter referred to as the "Service Provider") as an Open Source service. This service is provided "AS IS".',
            ),
            const SizedBox(height: 24),

            // Access Without Account
            _buildSectionTitle(theme, 'Access Without Account'),
            _buildParagraph(
              theme,
              'The Application does not require account creation or registration to use its core features.',
            ),
            const SizedBox(height: 8),
            _buildBulletPoint(
              theme,
              'When accessing via web link, the Application is immediately available with no sign-in needed.',
            ),
            _buildBulletPoint(
              theme,
              'On mobile, you can download and use the Application fully without authentication. By default, the Application opens to the general homepage.',
            ),
            const SizedBox(height: 24),

            // Optional Authentication
            _buildSectionTitle(theme, 'Optional Authentication (Mobile Only)'),
            _buildParagraph(
              theme,
              'For user convenience, the mobile version offers an optional sign-in feature using Google OAuth or GitHub OAuth. This is entirely skippable — you can continue using the Application without signing in.',
            ),
            const SizedBox(height: 8),
            _buildParagraph(
              theme,
              'Signing in allows you to set personal preferences, such as selecting your semester number to customize the homepage with relevant content for that semester instead of the default view.',
            ),
            const SizedBox(height: 12),
            _buildParagraph(theme, 'If you choose to sign in:'),
            const SizedBox(height: 8),
            _buildBulletPoint(
              theme,
              'The Application receives only limited profile information from the chosen provider (typically your name, username, and/or email address) strictly to enable this personalization feature.',
            ),
            _buildBulletPoint(
              theme,
              'No additional personal data is requested or collected.',
            ),
            _buildBulletPoint(
              theme,
              'This information is used solely to apply your preferences within the Application and is not used for marketing, analytics, or any other purpose.',
            ),
            const SizedBox(height: 24),

            // Information Collection
            _buildSectionTitle(theme, 'Information Collection and Use'),
            _buildParagraph(
              theme,
              'When using the Application without signing in (web or mobile), no personal information is collected or stored.',
            ),
            const SizedBox(height: 8),
            _buildParagraph(
              theme,
              'When signed in (optional, mobile only), the limited provider-provided information is used only for the personalization feature described above.',
            ),
            const SizedBox(height: 24),

            // Location
            _buildSectionTitle(
                theme, 'Does the Application collect precise real-time location information?'),
            _buildParagraph(
              theme,
              'No. The Application does not collect any location data from your device.',
            ),
            const SizedBox(height: 24),

            // Third Party
            _buildSectionTitle(theme, 'Third-Party Access'),
            _buildBulletPoint(
              theme,
              'No data is shared with third parties except during optional sign-in, where Google or GitHub acts solely as the authentication provider.',
            ),
            _buildBulletPoint(
              theme,
              'The chosen provider may receive standard OAuth authentication details, but the Application does not share any additional user data with them or any other party.',
            ),
            const SizedBox(height: 24),

            // Data Storage
            _buildSectionTitle(theme, 'Data Storage and Security'),
            _buildParagraph(
              theme,
              'Any optional preference data linked to your chosen sign-in provider is stored securely and only for the purpose of personalizing your experience. The Service Provider takes reasonable measures to protect this limited information, though no method of transmission or storage is 100% secure.',
            ),
            const SizedBox(height: 24),

            // Opt-Out
            _buildSectionTitle(theme, 'Opt-Out and Data Management'),
            _buildBulletPoint(
              theme,
              'You can stop all data processing by skipping sign-in or by revoking access through your Google/GitHub settings and uninstalling the Application.',
            ),
            _buildBulletPoint(
              theme,
              'Standard uninstall processes available on your device or app marketplace may be used.',
            ),
            _buildBulletPoint(
              theme,
              'To delete any stored preferences linked to your optional account, contact the Service Provider.',
            ),
            const SizedBox(height: 24),

            // Children
            _buildSectionTitle(theme, 'Children'),
            _buildParagraph(
              theme,
              'The Application does not knowingly collect personal information from children under 13. Users must be at least 16 years old (or have parental consent where required) to use the optional sign-in feature.',
            ),
            const SizedBox(height: 24),

            // Changes
            _buildSectionTitle(theme, 'Changes'),
            _buildParagraph(
              theme,
              'This Privacy Policy may be updated from time to time. Changes will be posted on this page with a new effective date. Continued use of the Application after changes constitutes acceptance.',
            ),
            const SizedBox(height: 24),

            // Consent
            _buildSectionTitle(theme, 'Your Consent'),
            _buildParagraph(
              theme,
              'By using the Application, you consent to this Privacy Policy.',
            ),
            const SizedBox(height: 24),

            // Contact
            _buildSectionTitle(theme, 'Contact Us'),
            _buildParagraph(
              theme,
              'For questions about this policy or to request deletion of optional preference data, contact: vaultscapes@gmail.com',
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: theme.typography.h4,
      ),
    );
  }

  Widget _buildParagraph(ThemeData theme, String text) {
    return Text(
      text,
      style: theme.typography.p,
    );
  }

  Widget _buildBulletPoint(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('•  ', style: theme.typography.p),
          Expanded(
            child: Text(text, style: theme.typography.p),
          ),
        ],
      ),
    );
  }
}
