import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tressle_app_1/Services/auth_service.dart';
import 'package:tressle_app_1/UI/loginScreen.dart';

class EmailVerificationScreen extends StatefulWidget {
  final AuthService authService;
  
  const EmailVerificationScreen({
    Key? key,
    required this.authService,
  }) : super(key: key);

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  Timer? _timer;
  bool _isEmailVerified = false;
  bool _isChecking = false;
  String _userEmail = '';

  @override
  void initState() {
    super.initState();
    _initializeUser();
    _startAutoCheck();
  }

  void _initializeUser() {
    final user = widget.authService.currentUser;
    if (user != null) {
      setState(() {
        _userEmail = user.email ?? '';
        _isEmailVerified = user.emailVerified;
      });
    }
  }

  void _startAutoCheck() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _checkEmailVerification();
    });
  }

  Future<void> _checkEmailVerification() async {
    if (_isChecking || _isEmailVerified) return;

    setState(() {
      _isChecking = true;
    });

    bool isVerified = await widget.authService.checkEmailVerified();

    setState(() {
      _isEmailVerified = isVerified;
      _isChecking = false;
    });

    if (isVerified) {
      _timer?.cancel();
    }
  }

  Future<void> _resendVerificationEmail() async {
    final result = await widget.authService.sendEmailVerification();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _goToLogin() {
    // Navigate to login screen
    // Replace with your actual navigation logic
    Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Verify Email'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Email Icon with Status
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _isEmailVerified 
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isEmailVerified ? Icons.mark_email_read : Icons.email_outlined,
                  size: 80,
                  color: _isEmailVerified ? Colors.green : Colors.orange,
                ),
              ),
              
              const SizedBox(height: 32),

              // Title
              Text(
                _isEmailVerified 
                    ? 'Email Verified!' 
                    : 'Verify Your Email',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              // Description
              Text(
                _isEmailVerified
                    ? 'Your email has been successfully verified.\nYou can now proceed to login.'
                    : 'We\'ve sent a verification link to:',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),

              if (!_isEmailVerified) ...[
                const SizedBox(height: 8),
                Text(
                  _userEmail,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Status Indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _isEmailVerified 
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isEmailVerified ? Colors.green : Colors.orange,
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isChecking && !_isEmailVerified)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.orange),
                        ),
                      )
                    else
                      Icon(
                        _isEmailVerified ? Icons.check_circle : Icons.pending,
                        color: _isEmailVerified ? Colors.green : Colors.orange,
                      ),
                    const SizedBox(width: 8),
                    Text(
                      _isEmailVerified 
                          ? 'Verified' 
                          : 'Checking every 3 seconds...',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _isEmailVerified ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // Continue to Login Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isEmailVerified ? _goToLogin : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isEmailVerified 
                        ? Colors.green 
                        : Colors.grey[300],
                    foregroundColor: _isEmailVerified 
                        ? Colors.white 
                        : Colors.grey[500],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: _isEmailVerified ? 2 : 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Continue to Login',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_isEmailVerified) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Resend Email Button
              if (!_isEmailVerified)
                TextButton(
                  onPressed: _resendVerificationEmail,
                  child: const Text(
                    'Resend Verification Email',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}