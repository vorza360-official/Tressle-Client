import 'package:flutter/material.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Terms & Conditions'),
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
              'Terms of Service',
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

            // Introduction
            Text(
              'Welcome to Tressle! These Terms of Service ("Terms") govern your use of the Tressle platform (the "Platform") operated by vorza360 SMC Pvt. Ltd. By accessing or using Tressle, you agree to be bound by these Terms.',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            SizedBox(height: 24),

            // Section 1
            _buildSection(
              number: '1',
              title: 'Acceptance of Terms',
              content:
                  'By creating an account or using the Platform, you confirm that you accept these Terms and agree to comply with them. If you do not agree to these Terms, you must not use our Platform.',
            ),

            // Section 2
            _buildSection(
              number: '2',
              title: 'Eligibility',
              content:
                  'You must be at least 18 years old to use Tressle. By using the Platform, you represent and warrant that you have the right, authority, and capacity to enter into these Terms and to abide by all of the terms and conditions set forth herein.',
            ),

            // Section 3
            _buildSection(
              number: '3',
              title: 'Account Registration',
              content:
                  'You must provide accurate, current, and complete information during registration. You are responsible for safeguarding your password and for all activities that occur under your account. You agree to notify us immediately of any unauthorized use of your account.',
            ),

            // Section 4
            _buildSection(
              number: '4',
              title: 'Services Description',
              content:
                  'Tressle is a digital marketplace that connects clients ("Clients") with independent beauty and grooming service providers ("Shops"). We facilitate bookings, payments, and communication between Clients and Shops. We are not a service provider ourselves and are not responsible for the services provided by Shops.',
            ),

            // Section 5
            _buildSection(
              number: '5',
              title: 'Booking and Payments',
              content:
                  'All bookings made through the Platform are subject to acceptance by the Shop. Payments are processed through secure third-party payment processors. Tressle may charge a service fee for transactions. Cancellation policies are set by individual Shops and will be displayed at the time of booking.',
            ),

            // Section 6
            _buildSection(
              number: '6',
              title: 'User Responsibilities',
              content:
                  'Users agree to use the Platform only for lawful purposes. You agree not to post false, misleading, or inappropriate content. Shops are responsible for the quality of services provided and for complying with all applicable laws and regulations.',
            ),

            // Section 7
            _buildSection(
              number: '7',
              title: 'Intellectual Property',
              content:
                  'All content on the Platform, including text, graphics, logos, and software, is the property of Tressle or its licensors and is protected by intellectual property laws. You may not use, reproduce, or distribute any content without our prior written permission.',
            ),

            // Section 8
            _buildSection(
              number: '8',
              title: 'Limitation of Liability',
              content:
                  'To the maximum extent permitted by law, Tressle shall not be liable for any indirect, incidental, special, consequential, or punitive damages resulting from your use of the Platform. Our total liability shall not exceed the amount paid by you to Tressle in the last 6 months.',
            ),

            // Section 9
            _buildSection(
              number: '9',
              title: 'Termination',
              content:
                  'We may suspend or terminate your account at any time for any reason, including if we believe you have violated these Terms. You may terminate your account at any time by contacting support.',
            ),

            // Section 10
            _buildSection(
              number: '10',
              title: 'Changes to Terms',
              content:
                  'We may modify these Terms at any time. We will notify you of significant changes via email or through the Platform. Your continued use of the Platform after changes constitutes acceptance of the new Terms.',
            ),

            // Section 11
            _buildSection(
              number: '11',
              title: 'Governing Law',
              content:
                  'These Terms shall be governed by and construed in accordance with the laws of Pakistan, without regard to its conflict of law provisions.',
            ),

            SizedBox(height: 32),
            Divider(),
            SizedBox(height: 16),
            Text(
              'Contact Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 12),
            _buildContactItem(icon: Icons.email, text: 'support@tressle.io'),
            SizedBox(height: 8),
            _buildContactItem(icon: Icons.phone, text: '+923084102839'),
            SizedBox(height: 8),
            _buildContactItem(icon: Icons.language, text: 'http://tressle.io'),
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

  Widget _buildContactItem({required IconData icon, required String text}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Color(0xFF00A693)),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 16, color: Colors.grey[800]),
          ),
        ),
      ],
    );
  }
}
