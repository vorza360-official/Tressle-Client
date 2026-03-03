import 'package:flutter/material.dart';
import 'package:tressle_app_1/UI/reviewBookingScreen.dart';
import 'package:tressle_app_1/UI/updatePaymentScreen.dart';

class PaymentScreen extends StatefulWidget {
  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  int selectedPaymentMethod = 5; // Default to Cash (index 5)

  void _showSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'This feature is coming soon, only cash will be accepted for now',
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        centerTitle: false,
        actions: [],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '    Payment',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontFamily: "Adamina",
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(16),
              children: [
                // Visa Card
                PaymentMethodTile(
                  index: 0,
                  selectedIndex: selectedPaymentMethod,
                  onTap: () => _showSnackBar(context),
                  icon: 'assets/icons/visa_icon.png',
                  title: 'Visa ending in 1234',
                  subtitle: 'Expiry 06/2024',
                  isDefault: false,
                ),
                SizedBox(height: 12),

                // Mastercard
                PaymentMethodTile(
                  index: 1,
                  selectedIndex: selectedPaymentMethod,
                  onTap: () => _showSnackBar(context),
                  icon: 'assets/icons/master_card_icon.png',
                  title: 'Mastercard ending in 1234',
                  subtitle: 'Expiry 06/2024',
                ),
                SizedBox(height: 12),

                // Apple Pay
                PaymentMethodTile(
                  index: 2,
                  selectedIndex: selectedPaymentMethod,
                  onTap: () => _showSnackBar(context),
                  icon: 'assets/icons/apple_pay_icon.png',
                  title: 'Visa ending in 1234',
                  subtitle: 'Expiry 06/2024',
                ),
                SizedBox(height: 12),

                // Stripe
                PaymentMethodTile(
                  index: 3,
                  selectedIndex: selectedPaymentMethod,
                  onTap: () => _showSnackBar(context),
                  icon: 'assets/icons/stripe_icon.png',
                  title: 'Stripe (Visa ending 1234)',
                  subtitle: 'Expiry 06/2024',
                ),
                SizedBox(height: 12),

                // PayPal
                PaymentMethodTile(
                  index: 4,
                  selectedIndex: selectedPaymentMethod,
                  onTap: () => _showSnackBar(context),
                  icon: 'assets/icons/paypal_icon.png',
                  title: 'PayPal (Visa ending 1234)',
                  subtitle: 'Expiry 06/2024',
                ),
                SizedBox(height: 12),

                // Cash
                PaymentMethodTile(
                  index: 5,
                  selectedIndex: selectedPaymentMethod,
                  onTap: () => setState(() => selectedPaymentMethod = 5),
                  icon: 'assets/icons/cash_icon.png',
                  title: 'Cash',
                  subtitle: '',
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReviewBookingScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal[700],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Pay Now',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PaymentMethodTile extends StatelessWidget {
  final int index;
  final int selectedIndex;
  final VoidCallback onTap;
  final String icon;
  final String title;
  final String subtitle;
  final bool isDefault;

  const PaymentMethodTile({
    Key? key,
    required this.index,
    required this.selectedIndex,
    required this.onTap,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isDefault = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isSelected = index == selectedIndex;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.purpleAccent.withOpacity(0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Colors.purpleAccent.withOpacity(0.4)
                : Colors.grey[200]!,
            width: isSelected ? 1 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
              child: Image.asset(icon),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  SizedBox(height: 12),
                  Text(
                    'Set as default',
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Color(0xFF00A693) : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.teal.shade700 : Colors.transparent,
                border: Border.all(
                  color: isSelected ? Colors.teal.shade700 : Colors.grey[300]!,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForPayment() {
    switch (index) {
      case 0:
        return Icons.credit_card;
      case 1:
        return Icons.credit_card;
      case 2:
        return Icons.apple;
      case 3:
        return Icons.one_k;
      case 4:
        return Icons.payment;
      case 5:
        return Icons.account_balance_wallet;
      default:
        return Icons.credit_card;
    }
  }

  Color _getColorForPayment() {
    switch (index) {
      case 0:
        return Colors.blue;
      case 1:
        return Colors.orange;
      case 2:
        return Colors.black;
      case 3:
        return Colors.purple;
      case 4:
        return Colors.blue[800]!;
      case 5:
        return Colors.green;
      default:
        return Colors.blue;
    }
  }
}
