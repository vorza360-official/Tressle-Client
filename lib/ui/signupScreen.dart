import 'package:flutter/material.dart';
import 'package:tressle_app_1/services/auth_service.dart';
import 'package:tressle_app_1/ui/emailVerificationScreen.dart';
import 'package:tressle_app_1/ui/loginScreen.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _rememberMe = false;
  bool _passwordVisible = false;
  bool _isLoading = false;
  String selectedCountryCode = '+92';
  String selectedCountryFlag = '🇵🇰';
  String selectedCountryName = 'Pakistan';

  // List of countries with their data
  final List<Map<String, String>> countries = [
    {'name': 'Afghanistan', 'code': '+93', 'flag': '🇦🇫'},
    {'name': 'Albania', 'code': '+355', 'flag': '🇦🇱'},
    {'name': 'Algeria', 'code': '+213', 'flag': '🇩🇿'},
    {'name': 'Andorra', 'code': '+376', 'flag': '🇦🇩'},
    {'name': 'Angola', 'code': '+244', 'flag': '🇦🇴'},
    {'name': 'Antigua and Barbuda', 'code': '+1-268', 'flag': '🇦🇬'},
    {'name': 'Argentina', 'code': '+54', 'flag': '🇦🇷'},
    {'name': 'Armenia', 'code': '+374', 'flag': '🇦🇲'},
    {'name': 'Australia', 'code': '+61', 'flag': '🇦🇺'},
    {'name': 'Austria', 'code': '+43', 'flag': '🇦🇹'},
    {'name': 'Azerbaijan', 'code': '+994', 'flag': '🇦🇿'},
    {'name': 'Bahamas', 'code': '+1-242', 'flag': '🇧🇸'},
    {'name': 'Bahrain', 'code': '+973', 'flag': '🇧🇭'},
    {'name': 'Bangladesh', 'code': '+880', 'flag': '🇧🇩'},
    {'name': 'Barbados', 'code': '+1-246', 'flag': '🇧🇧'},
    {'name': 'Belarus', 'code': '+375', 'flag': '🇧🇾'},
    {'name': 'Belgium', 'code': '+32', 'flag': '🇧🇪'},
    {'name': 'Belize', 'code': '+501', 'flag': '🇧🇿'},
    {'name': 'Benin', 'code': '+229', 'flag': '🇧🇯'},
    {'name': 'Bhutan', 'code': '+975', 'flag': '🇧🇹'},
    {'name': 'Bolivia', 'code': '+591', 'flag': '🇧🇴'},
    {'name': 'Bosnia and Herzegovina', 'code': '+387', 'flag': '🇧🇦'},
    {'name': 'Botswana', 'code': '+267', 'flag': '🇧🇼'},
    {'name': 'Brazil', 'code': '+55', 'flag': '🇧🇷'},
    {'name': 'Brunei', 'code': '+673', 'flag': '🇧🇳'},
    {'name': 'Bulgaria', 'code': '+359', 'flag': '🇧🇬'},
    {'name': 'Burkina Faso', 'code': '+226', 'flag': '🇧🇫'},
    {'name': 'Burundi', 'code': '+257', 'flag': '🇧🇮'},
    {'name': 'Cambodia', 'code': '+855', 'flag': '🇰🇭'},
    {'name': 'Cameroon', 'code': '+237', 'flag': '🇨🇲'},
    {'name': 'Canada', 'code': '+1', 'flag': '🇨🇦'},
    {'name': 'Cape Verde', 'code': '+238', 'flag': '🇨🇻'},
    {'name': 'Central African Republic', 'code': '+236', 'flag': '🇨🇫'},
    {'name': 'Chad', 'code': '+235', 'flag': '🇹🇩'},
    {'name': 'Chile', 'code': '+56', 'flag': '🇨🇱'},
    {'name': 'China', 'code': '+86', 'flag': '🇨🇳'},
    {'name': 'Colombia', 'code': '+57', 'flag': '🇨🇴'},
    {'name': 'Comoros', 'code': '+269', 'flag': '🇰🇲'},
    {'name': 'Congo', 'code': '+242', 'flag': '🇨🇬'},
    {'name': 'Congo (DRC)', 'code': '+243', 'flag': '🇨🇩'},
    {'name': 'Costa Rica', 'code': '+506', 'flag': '🇨🇷'},
    {'name': 'Croatia', 'code': '+385', 'flag': '🇭🇷'},
    {'name': 'Cuba', 'code': '+53', 'flag': '🇨🇺'},
    {'name': 'Cyprus', 'code': '+357', 'flag': '🇨🇾'},
    {'name': 'Czech Republic', 'code': '+420', 'flag': '🇨🇿'},
    {'name': 'Denmark', 'code': '+45', 'flag': '🇩🇰'},
    {'name': 'Djibouti', 'code': '+253', 'flag': '🇩🇯'},
    {'name': 'Dominica', 'code': '+1-767', 'flag': '🇩🇲'},
    {'name': 'Dominican Republic', 'code': '+1-809', 'flag': '🇩🇴'},
    {'name': 'East Timor', 'code': '+670', 'flag': '🇹🇱'},
    {'name': 'Ecuador', 'code': '+593', 'flag': '🇪🇨'},
    {'name': 'Egypt', 'code': '+20', 'flag': '🇪🇬'},
    {'name': 'El Salvador', 'code': '+503', 'flag': '🇸🇻'},
    {'name': 'Equatorial Guinea', 'code': '+240', 'flag': '🇬🇶'},
    {'name': 'Eritrea', 'code': '+291', 'flag': '🇪🇷'},
    {'name': 'Estonia', 'code': '+372', 'flag': '🇪🇪'},
    {'name': 'Eswatini', 'code': '+268', 'flag': '🇸🇿'},
    {'name': 'Ethiopia', 'code': '+251', 'flag': '🇪🇹'},
    {'name': 'Fiji', 'code': '+679', 'flag': '🇫🇯'},
    {'name': 'Finland', 'code': '+358', 'flag': '🇫🇮'},
    {'name': 'France', 'code': '+33', 'flag': '🇫🇷'},
    {'name': 'Gabon', 'code': '+241', 'flag': '🇬🇦'},
    {'name': 'Gambia', 'code': '+220', 'flag': '🇬🇲'},
    {'name': 'Georgia', 'code': '+995', 'flag': '🇬🇪'},
    {'name': 'Germany', 'code': '+49', 'flag': '🇩🇪'},
    {'name': 'Ghana', 'code': '+233', 'flag': '🇬🇭'},
    {'name': 'Greece', 'code': '+30', 'flag': '🇬🇷'},
    {'name': 'Grenada', 'code': '+1-473', 'flag': '🇬🇩'},
    {'name': 'Guatemala', 'code': '+502', 'flag': '🇬🇹'},
    {'name': 'Guinea', 'code': '+224', 'flag': '🇬🇳'},
    {'name': 'Guinea-Bissau', 'code': '+245', 'flag': '🇬🇼'},
    {'name': 'Guyana', 'code': '+592', 'flag': '🇬🇾'},
    {'name': 'Haiti', 'code': '+509', 'flag': '🇭🇹'},
    {'name': 'Honduras', 'code': '+504', 'flag': '🇭🇳'},
    {'name': 'Hungary', 'code': '+36', 'flag': '🇭🇺'},
    {'name': 'Iceland', 'code': '+354', 'flag': '🇮🇸'},
    {'name': 'India', 'code': '+91', 'flag': '🇮🇳'},
    {'name': 'Indonesia', 'code': '+62', 'flag': '🇮🇩'},
    {'name': 'Iran', 'code': '+98', 'flag': '🇮🇷'},
    {'name': 'Iraq', 'code': '+964', 'flag': '🇮🇶'},
    {'name': 'Ireland', 'code': '+353', 'flag': '🇮🇪'},
    {'name': 'Israel', 'code': '+972', 'flag': '🇮🇱'},
    {'name': 'Italy', 'code': '+39', 'flag': '🇮🇹'},
    {'name': 'Ivory Coast', 'code': '+225', 'flag': '🇨🇮'},
    {'name': 'Jamaica', 'code': '+1-876', 'flag': '🇯🇲'},
    {'name': 'Japan', 'code': '+81', 'flag': '🇯🇵'},
    {'name': 'Jordan', 'code': '+962', 'flag': '🇯🇴'},
    {'name': 'Kazakhstan', 'code': '+7', 'flag': '🇰🇿'},
    {'name': 'Kenya', 'code': '+254', 'flag': '🇰🇪'},
    {'name': 'Kiribati', 'code': '+686', 'flag': '🇰🇮'},
    {'name': 'Kosovo', 'code': '+383', 'flag': '🇽🇰'},
    {'name': 'Kuwait', 'code': '+965', 'flag': '🇰🇼'},
    {'name': 'Kyrgyzstan', 'code': '+996', 'flag': '🇰🇬'},
    {'name': 'Laos', 'code': '+856', 'flag': '🇱🇦'},
    {'name': 'Latvia', 'code': '+371', 'flag': '🇱🇻'},
    {'name': 'Lebanon', 'code': '+961', 'flag': '🇱🇧'},
    {'name': 'Lesotho', 'code': '+266', 'flag': '🇱🇸'},
    {'name': 'Liberia', 'code': '+231', 'flag': '🇱🇷'},
    {'name': 'Libya', 'code': '+218', 'flag': '🇱🇾'},
    {'name': 'Liechtenstein', 'code': '+423', 'flag': '🇱🇮'},
    {'name': 'Lithuania', 'code': '+370', 'flag': '🇱🇹'},
    {'name': 'Luxembourg', 'code': '+352', 'flag': '🇱🇺'},
    {'name': 'Madagascar', 'code': '+261', 'flag': '🇲🇬'},
    {'name': 'Malawi', 'code': '+265', 'flag': '🇲🇼'},
    {'name': 'Malaysia', 'code': '+60', 'flag': '🇲🇾'},
    {'name': 'Maldives', 'code': '+960', 'flag': '🇲🇻'},
    {'name': 'Mali', 'code': '+223', 'flag': '🇲🇱'},
    {'name': 'Malta', 'code': '+356', 'flag': '🇲🇹'},
    {'name': 'Marshall Islands', 'code': '+692', 'flag': '🇲🇭'},
    {'name': 'Mauritania', 'code': '+222', 'flag': '🇲🇷'},
    {'name': 'Mauritius', 'code': '+230', 'flag': '🇲🇺'},
    {'name': 'Mexico', 'code': '+52', 'flag': '🇲🇽'},
    {'name': 'Micronesia', 'code': '+691', 'flag': '🇫🇲'},
    {'name': 'Moldova', 'code': '+373', 'flag': '🇲🇩'},
    {'name': 'Monaco', 'code': '+377', 'flag': '🇲🇨'},
    {'name': 'Mongolia', 'code': '+976', 'flag': '🇲🇳'},
    {'name': 'Montenegro', 'code': '+382', 'flag': '🇲🇪'},
    {'name': 'Morocco', 'code': '+212', 'flag': '🇲🇦'},
    {'name': 'Mozambique', 'code': '+258', 'flag': '🇲🇿'},
    {'name': 'Myanmar', 'code': '+95', 'flag': '🇲🇲'},
    {'name': 'Namibia', 'code': '+264', 'flag': '🇳🇦'},
    {'name': 'Nauru', 'code': '+674', 'flag': '🇳🇷'},
    {'name': 'Nepal', 'code': '+977', 'flag': '🇳🇵'},
    {'name': 'Netherlands', 'code': '+31', 'flag': '🇳🇱'},
    {'name': 'New Zealand', 'code': '+64', 'flag': '🇳🇿'},
    {'name': 'Nicaragua', 'code': '+505', 'flag': '🇳🇮'},
    {'name': 'Niger', 'code': '+227', 'flag': '🇳🇪'},
    {'name': 'Nigeria', 'code': '+234', 'flag': '🇳🇬'},
    {'name': 'North Korea', 'code': '+850', 'flag': '🇰🇵'},
    {'name': 'North Macedonia', 'code': '+389', 'flag': '🇲🇰'},
    {'name': 'Norway', 'code': '+47', 'flag': '🇳🇴'},
    {'name': 'Oman', 'code': '+968', 'flag': '🇴🇲'},
    {'name': 'Pakistan', 'code': '+92', 'flag': '🇵🇰'},
    {'name': 'Palau', 'code': '+680', 'flag': '🇵🇼'},
    {'name': 'Palestine', 'code': '+970', 'flag': '🇵🇸'},
    {'name': 'Panama', 'code': '+507', 'flag': '🇵🇦'},
    {'name': 'Papua New Guinea', 'code': '+675', 'flag': '🇵🇬'},
    {'name': 'Paraguay', 'code': '+595', 'flag': '🇵🇾'},
    {'name': 'Peru', 'code': '+51', 'flag': '🇵🇪'},
    {'name': 'Philippines', 'code': '+63', 'flag': '🇵🇭'},
    {'name': 'Poland', 'code': '+48', 'flag': '🇵🇱'},
    {'name': 'Portugal', 'code': '+351', 'flag': '🇵🇹'},
    {'name': 'Qatar', 'code': '+974', 'flag': '🇶🇦'},
    {'name': 'Romania', 'code': '+40', 'flag': '🇷🇴'},
    {'name': 'Russia', 'code': '+7', 'flag': '🇷🇺'},
    {'name': 'Rwanda', 'code': '+250', 'flag': '🇷🇼'},
    {'name': 'Saint Kitts and Nevis', 'code': '+1-869', 'flag': '🇰🇳'},
    {'name': 'Saint Lucia', 'code': '+1-758', 'flag': '🇱🇨'},
    {
      'name': 'Saint Vincent and the Grenadines',
      'code': '+1-784',
      'flag': '🇻🇨',
    },
    {'name': 'Samoa', 'code': '+685', 'flag': '🇼🇸'},
    {'name': 'San Marino', 'code': '+378', 'flag': '🇸🇲'},
    {'name': 'Sao Tome and Principe', 'code': '+239', 'flag': '🇸🇹'},
    {'name': 'Saudi Arabia', 'code': '+966', 'flag': '🇸🇦'},
    {'name': 'Senegal', 'code': '+221', 'flag': '🇸🇳'},
    {'name': 'Serbia', 'code': '+381', 'flag': '🇷🇸'},
    {'name': 'Seychelles', 'code': '+248', 'flag': '🇸🇨'},
    {'name': 'Sierra Leone', 'code': '+232', 'flag': '🇸🇱'},
    {'name': 'Singapore', 'code': '+65', 'flag': '🇸🇬'},
    {'name': 'Slovakia', 'code': '+421', 'flag': '🇸🇰'},
    {'name': 'Slovenia', 'code': '+386', 'flag': '🇸🇮'},
    {'name': 'Solomon Islands', 'code': '+677', 'flag': '🇸🇧'},
    {'name': 'Somalia', 'code': '+252', 'flag': '🇸🇴'},
    {'name': 'South Africa', 'code': '+27', 'flag': '🇿🇦'},
    {'name': 'South Korea', 'code': '+82', 'flag': '🇰🇷'},
    {'name': 'South Sudan', 'code': '+211', 'flag': '🇸🇸'},
    {'name': 'Spain', 'code': '+34', 'flag': '🇪🇸'},
    {'name': 'Sri Lanka', 'code': '+94', 'flag': '🇱🇰'},
    {'name': 'Sudan', 'code': '+249', 'flag': '🇸🇩'},
    {'name': 'Suriname', 'code': '+597', 'flag': '🇸🇷'},
    {'name': 'Sweden', 'code': '+46', 'flag': '🇸🇪'},
    {'name': 'Switzerland', 'code': '+41', 'flag': '🇨🇭'},
    {'name': 'Syria', 'code': '+963', 'flag': '🇸🇾'},
    {'name': 'Taiwan', 'code': '+886', 'flag': '🇹🇼'},
    {'name': 'Tajikistan', 'code': '+992', 'flag': '🇹🇯'},
    {'name': 'Tanzania', 'code': '+255', 'flag': '🇹🇿'},
    {'name': 'Thailand', 'code': '+66', 'flag': '🇹🇭'},
    {'name': 'Togo', 'code': '+228', 'flag': '🇹🇬'},
    {'name': 'Tonga', 'code': '+676', 'flag': '🇹🇴'},
    {'name': 'Trinidad and Tobago', 'code': '+1-868', 'flag': '🇹🇹'},
    {'name': 'Tunisia', 'code': '+216', 'flag': '🇹🇳'},
    {'name': 'Turkey', 'code': '+90', 'flag': '🇹🇷'},
    {'name': 'Turkmenistan', 'code': '+993', 'flag': '🇹🇲'},
    {'name': 'Tuvalu', 'code': '+688', 'flag': '🇹🇻'},
    {'name': 'Uganda', 'code': '+256', 'flag': '🇺🇬'},
    {'name': 'Ukraine', 'code': '+380', 'flag': '🇺🇦'},
    {'name': 'United Arab Emirates', 'code': '+971', 'flag': '🇦🇪'},
    {'name': 'United Kingdom', 'code': '+44', 'flag': '🇬🇧'},
    {'name': 'United States', 'code': '+1', 'flag': '🇺🇸'},
    {'name': 'Uruguay', 'code': '+598', 'flag': '🇺🇾'},
    {'name': 'Uzbekistan', 'code': '+998', 'flag': '🇺🇿'},
    {'name': 'Vanuatu', 'code': '+678', 'flag': '🇻🇺'},
    {'name': 'Vatican City', 'code': '+379', 'flag': '🇻🇦'},
    {'name': 'Venezuela', 'code': '+58', 'flag': '🇻🇪'},
    {'name': 'Vietnam', 'code': '+84', 'flag': '🇻🇳'},
    {'name': 'Yemen', 'code': '+967', 'flag': '🇾🇪'},
    {'name': 'Zambia', 'code': '+260', 'flag': '🇿🇲'},
    {'name': 'Zimbabwe', 'code': '+263', 'flag': '🇿🇼'},
  ];
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Country',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: countries.length,
                    itemBuilder: (context, index) {
                      final country = countries[index];
                      final isSelected =
                          country['code'] == selectedCountryCode &&
                          country['name'] == selectedCountryName;

                      return ListTile(
                        leading: Text(
                          country['flag']!,
                          style: TextStyle(fontSize: 32),
                        ),
                        title: Text(country['name']!),
                        trailing: Text(
                          country['code']!,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        selected: isSelected,
                        selectedTileColor: Colors.blue.withOpacity(0.1),
                        onTap: () {
                          setState(() {
                            selectedCountryCode = country['code']!;
                            selectedCountryFlag = country['flag']!;
                            selectedCountryName = country['name']!;
                          });
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showMessage(String title, String message, {bool isError = false}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  // Handle Google Sign In
  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      final result = await _authService.signInWithGoogle();

      if (result['success']) {
        if (result['isNewUser'] && result['needsProfileCompletion']) {
          // New Google user - needs phone verification
          _showMessage(
            'Profile Completion Required',
            'Please add your phone number to complete your profile',
          );
          // You can navigate to a phone verification screen here
        } else {
          // Existing user - navigate to home
          _showMessage('Success', 'Google sign in successful');
          // Navigate to home screen
          // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen()));
        }
      } else {
        _showMessage('Error', result['message'], isError: true);
      }
    } catch (e) {
      _showMessage('Error', 'An unexpected error occurred', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Handle Email/Password Sign Up
  Future<void> _handleEmailSignUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final fullName =
          '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final phone = _phoneController.text.trim();

      final result = await _authService.createUserWithEmail(
        email: email,
        password: password,
        fullName: fullName,
        phoneNumber: phone,
        countryCode: selectedCountryCode,
        countryName: selectedCountryName,
      );

      if (result['success']) {
        _showMessage('Success', result['message']);

        // Show dialog informing user to verify email
        // showDialog(
        //   context: context,
        //   barrierDismissible: false,
        //   builder: (context) => AlertDialog(
        //     title: Text('Verify Your Email'),
        //     content: Text(
        //       'A verification link has been sent to your email address. Please verify your email to continue.',
        //     ),
        //     actions: [
        //       TextButton(
        //         onPressed: () {
        //           Navigator.pop(context);
        //           Navigator.pushReplacement(
        //             context,
        //             MaterialPageRoute(builder: (context) => LoginScreen()),
        //           );
        //         },
        //         child: Text('Go to Login'),
        //       ),
        //     ],
        //   ),
        // );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                EmailVerificationScreen(authService: _authService),
          ),
        );
      } else {
        _showMessage('Error', result['message'], isError: true);
      }
    } catch (e) {
      _showMessage('Error', 'An unexpected error occurred', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  InputDecoration compactDecoration({
    required String hint,
    Widget? suffix,
    String? prefixText,
  }) {
    return InputDecoration(
      isDense: true,
      hintText: hint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      helperText: '',
      errorStyle: const TextStyle(height: 0, fontSize: 0),
      prefixText: prefixText,
      prefixStyle: const TextStyle(fontSize: 14, height: 1.0),
      suffix: suffix,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.teal[700]!, width: 1),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Bar
                SizedBox(height: 40),

                // Title
                Text(
                  'Sign Up',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w400,
                    fontFamily: "Adamina",
                  ),
                ),
                Text(
                  'Sign up to join',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                SizedBox(height: 15),

                // Social Buttons
                Row(
                  children: [
                    // Google Button
                    Expanded(
                      child: Container(
                        height: 40,
                        child: OutlinedButton(
                          onPressed: () {
                            _handleGoogleSignIn();
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.grey[200],
                            side: BorderSide(color: Colors.white, width: 1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 16),
                          ),
                          child: _isLoading
                              ? CircularProgressIndicator(
                                  strokeWidth: 1,
                                  color: Colors.black,
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Google "G" logo
                                    Image.asset(
                                      "assets/icons/google_icon.png",
                                      height: 18,
                                      width: 18,
                                    ),
                                    SizedBox(width: 5),
                                    Text(
                                      'Sign up with Google',
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    // Facebook Button
                    Expanded(
                      child: Container(
                        height: 40,
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            elevation: 0,
                          ),
                          child: Row(
                            spacing: 5,
                            children: [
                              Image.asset(
                                "assets/icons/facebook_icon.png",
                                height: 18,
                                width: 18,
                              ),
                              Text(
                                'Sign up with Facebook',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 15),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 5,
                  children: [
                    Container(height: 1, width: 60, color: Colors.black),
                    Text(
                      'or sign up with',
                      style: TextStyle(color: Colors.black),
                    ),
                    Container(height: 1, width: 60, color: Colors.black),
                    Container(height: 2, color: Colors.grey.shade500),
                  ],
                ),
                SizedBox(height: 15),

                // Form Fields
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('First Name'),
                          const SizedBox(height: 5),
                          TextFormField(
                            controller: _firstNameController,
                            decoration: compactDecoration(hint: 'Alexanil'),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Required' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Last Name'),
                          const SizedBox(height: 5),
                          TextFormField(
                            controller: _lastNameController,
                            decoration: compactDecoration(hint: 'Doe'),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Required' : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                Text(
                  'Email Address',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: compactDecoration(hint: 'johnDoe@example.com'),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value)) {
                      return 'Invalid email';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 7),

                Text(
                  'Create Password',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_passwordVisible,
                  decoration: compactDecoration(
                    hint: 'Atleast 8 characters',
                    suffix: InkWell(
                      onTap: () {
                        setState(() {
                          _passwordVisible = !_passwordVisible;
                        });
                      },
                      child: Icon(
                        _passwordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        size: 18,
                      ),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (v.length < 8) return 'Min 8 characters';
                    return null;
                  },
                ),
                SizedBox(height: 7),

                Text(
                  'Phone number',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: _showCountryPicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Text(selectedCountryFlag),
                            const SizedBox(width: 4),
                            const Icon(Icons.keyboard_arrow_down, size: 16),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.number,
                        textAlignVertical: TextAlignVertical.center,
                        decoration: compactDecoration(
                          hint: '00 000000',
                          prefixText: '$selectedCountryCode ',
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (v.length < 6) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),

                Row(
                  children: [
                    Checkbox(
                      focusColor: Colors.teal[700],
                      value: _rememberMe,
                      onChanged: (value) {
                        setState(() {
                          _rememberMe = value!;
                        });
                      },
                    ),
                    Text('Remember Me', style: TextStyle(color: Colors.black)),
                  ],
                ),

                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        // Form is valid, proceed with sign up
                        _handleEmailSignUp();
                        // Navigator.push(
                        //   context,
                        //   MaterialPageRoute(builder: (context) => LoginScreen()),
                        // );
                      }
                    },
                    child: _isLoading
                        ? CircularProgressIndicator(
                            strokeWidth: 1,
                            color: Colors.white,
                          )
                        : Text(
                            'Sign up',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal[700],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 7),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Already have an account? '),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LoginScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'Login here',
                          style: TextStyle(
                            color: Colors.teal[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
