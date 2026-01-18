import 'package:shadcn_flutter/shadcn_flutter.dart';

/// In-app Terms of Service screen
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      headers: [
        AppBar(
          title: const Text('Terms of Service'),
        ),
      ],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Terms of Service',
              style: theme.typography.h2,
            ),
            const SizedBox(height: 8),
            Text('Effective Date: January 16, 2026').muted(),
            const SizedBox(height: 24),

            // Introduction
            _buildParagraph(
              theme,
              'These Terms of Service ("Terms") govern your use of the Vaultscapes app (hereinafter the "Application"), accessible via web link or mobile devices, created by Shivam Singh (hereinafter the "Service Provider") as an Open Source service. The Application is provided "AS IS".',
            ),
            const SizedBox(height: 24),

            // Section 1
            _buildSectionTitle(theme, '1. Acceptance of Terms'),
            _buildParagraph(
              theme,
              'By accessing or using the Application, you agree to these Terms. If you do not agree, do not use the Application.',
            ),
            const SizedBox(height: 24),

            // Section 2
            _buildSectionTitle(theme, '2. Access and Use'),
            _buildBulletPoint(
              theme,
              'Web Access: No account or sign-in is required. The Application is immediately available upon visiting the link.',
            ),
            _buildBulletPoint(
              theme,
              'Mobile Access: The Application can be used fully without authentication. By default, it opens to the general homepage.',
            ),
            _buildBulletPoint(
              theme,
              'Optional Sign-In (Mobile Only): For convenience, you may choose to sign in using Google OAuth or GitHub OAuth. This is entirely optional and skippable. Signing in enables personalization features, such as selecting your semester to display relevant content on the homepage.',
            ),
            const SizedBox(height: 12),
            _buildParagraph(
              theme,
              'You agree to use the Application only for lawful, personal, non-commercial purposes.',
            ),
            const SizedBox(height: 24),

            // Section 3
            _buildSectionTitle(theme, '3. Optional Accounts'),
            _buildBulletPoint(
              theme,
              'Account creation is never required. If you opt to sign in via Google or GitHub on mobile:',
            ),
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBulletPoint(
                    theme,
                    'You are responsible for maintaining the confidentiality of your provider account credentials.',
                  ),
                  _buildBulletPoint(
                    theme,
                    'You may revoke access or stop using the feature at any time via your Google/GitHub settings or by uninstalling the Application.',
                  ),
                ],
              ),
            ),
            _buildBulletPoint(
              theme,
              'The Service Provider may suspend or terminate access to personalized features if these Terms are violated.',
            ),
            const SizedBox(height: 24),

            // Section 4
            _buildSectionTitle(theme, '4. Open Source Nature'),
            _buildParagraph(
              theme,
              'The Application is open-source software. Source code is available under the applicable open-source license. These Terms do not restrict rights granted by that license.',
            ),
            const SizedBox(height: 24),

            // Section 5
            _buildSectionTitle(theme, '5. Intellectual Property'),
            _buildParagraph(
              theme,
              'Rights in the Application (excluding user-accessed academic resources) belong to the Service Provider or licensors. Resources viewed may have separate copyrights — respect those rights.',
            ),
            const SizedBox(height: 24),

            // Section 6
            _buildSectionTitle(theme, '6. No Warranty'),
            _buildParagraph(
              theme,
              'The Application is provided "AS IS" without warranties of any kind, express or implied, including merchantability, fitness for a particular purpose, or non-infringement.',
            ),
            const SizedBox(height: 24),

            // Section 7
            _buildSectionTitle(theme, '7. Limitation of Liability'),
            _buildParagraph(
              theme,
              'To the fullest extent permitted by law, the Service Provider is not liable for any indirect, incidental, special, consequential, or punitive damages arising from your use of the Application.',
            ),
            const SizedBox(height: 24),

            // Section 8
            _buildSectionTitle(theme, '8. Termination'),
            _buildParagraph(
              theme,
              'The Service Provider may terminate or suspend access (including personalized features) at any time without notice for breach of these Terms.',
            ),
            const SizedBox(height: 24),

            // Section 9
            _buildSectionTitle(theme, '9. Changes to Terms'),
            _buildParagraph(
              theme,
              'Terms may be updated with a new effective date posted here. Continued use constitutes acceptance.',
            ),
            const SizedBox(height: 24),

            // Section 10
            _buildSectionTitle(theme, '10. Governing Law'),
            _buildParagraph(
              theme,
              'These Terms are governed by the laws of India. Disputes shall be subject to the exclusive jurisdiction of courts in Chennai, Tamil Nadu, India.',
            ),
            const SizedBox(height: 24),

            // Section 11
            _buildSectionTitle(theme, '11. Contact'),
            _buildParagraph(
              theme,
              'Questions about these Terms: vaultscapes@gmail.com',
            ),
            const SizedBox(height: 24),

            // Footer
            Divider(),
            const SizedBox(height: 16),
            Text(
              'By using the Application, you acknowledge that you have read and agree to these Terms of Service.',
              style: theme.typography.small.copyWith(fontStyle: FontStyle.italic),
            ).muted(),
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
