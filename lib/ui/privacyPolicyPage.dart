import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Privacy Policy'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How We Keep Your Information Safe',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00A693),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Last Updated: 19/12/25',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            SizedBox(height: 24),
            Text(
              'This Privacy Policy explains how Tressle, operated by vorza360 SMC Pvt. Ltd., collects, uses, and protects your personal data when you use our platform (our app or website). By using Tressle, you agree to these simple rules. Tressle is the digital marketplace connecting clients and independent Shops.',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            SizedBox(height: 24),

            // Section 1
            _buildSection(
              number: '1',
              title: 'Information We Collect',
              content:
                  'We collect information needed to run the platform. This includes data you give us when you sign up, like your name, email, phone number, and password. If you are a Shop, we also collect your business name, address, service prices, and staff details. When you book a service, we collect appointment and payment details (which are processed securely by partners). We also automatically collect technical details like your phone type, IP address, and how you use the platform, often using "cookies" and tracking tools to improve the service.',
            ),

            // Section 2
            _buildSection(
              number: '2',
              title: 'How We Use Your Information',
              content:
                  'We use your information to manage core services like creating your account, processing simple booking, and sending you reminders or updates. We also use it to improve your experience by personalizing recommendations, tracking analytics, stopping fraud, and making the platform secure. For Shops, we use information to publicly display your services and track your performance on your dashboard.',
            ),

            // Section 3
            _buildSection(
              number: '3',
              title: 'How We Share Information',
              content:
                  'We only share your data when necessary to operate the platform or when legally required. When you book a service, we share your name and contact details with the selected Shop. We share limited data with trusted partners who help us run the platform, such as payment processors and hosting services. We will share information if a law or court order tells us to, or if it is needed to enforce our rules or protect Tressle\'s rights. We promise we do not sell your personal information.',
            ),

            // Section 4
            _buildSection(
              number: '4',
              title: 'Data Storage & Security',
              content:
                  'We use strong, industry-standard tools like encryption and secure servers to keep your data safe. While we work hard to protect your information, no digital system can be 100% secure. We store your data only for as long as we need it to provide our services, or for longer periods if required by law or for important business reasons like fighting fraud.',
            ),

            // Section 5
            _buildSection(
              number: '5',
              title: 'Your Rights & Choices',
              content:
                  'You have control over your information. You can access and update your account data anytime on the platform. You can ask us to correct or delete your data or close your account by contacting our support team. You can also choose not to receive our marketing emails, but we will still send you important service updates.',
            ),

            // Section 6
            _buildSection(
              number: '6',
              title: 'Cookies & Tracking Technologies',
              content:
                  'We use "cookies" and similar tools to make the platform work better, remember your preferences, and analyze how users interact with the app. You can usually manage or disable cookies in your browser settings, but please know that this might stop some features from working correctly.',
            ),

            // Section 7
            _buildSection(
              number: '7',
              title: 'Children\'s Privacy',
              content:
                  'Tressle is built for adults running or booking business services. We do not knowingly collect personal information from anyone under the age of 13.',
            ),

            // Section 8
            _buildSection(
              number: '8',
              title: 'Business Obligations Regarding User Data',
              content:
                  'Shops using the platform must protect all Client information they receive through bookings or communication. Shops must only use that data for the legitimate service they are providing and cannot sell or misuse it. Breaking these rules could lead to account suspension.',
            ),

            // Section 9
            _buildSection(
              number: '9',
              title: 'International Transfers',
              content:
                  'If you access Tressle from outside Pakistan, your information may be transferred to and stored in countries whose data protection laws are different from your home country. By using the platform, you agree to these transfers so we can provide and improve the service globally.',
            ),

            // Section 10
            _buildSection(
              number: '10',
              title: 'Changes to This Privacy Policy',
              content:
                  'Tressle may update this Privacy Policy if laws change or if we add new features to the platform. If we make important changes, we will notify you through email or a clear notice on the app. Your continued use of the platform means you accept the updated rules.',
            ),

            SizedBox(height: 32),
            Divider(),
            SizedBox(height: 16),
            Text(
              'For more information, visit our website:',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                // You can add URL launch functionality here
                // launch('http://tressle.io/privacy-policy/');
              },
              child: Text(
                'http://tressle.io/privacy-policy/',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF00A693),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String number,
    required String title,
    required String content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Color(0xFF00A693),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  number,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    content,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
