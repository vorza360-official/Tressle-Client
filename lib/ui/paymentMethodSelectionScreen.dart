import 'package:flutter/material.dart';

class PaymentMethods2 extends StatefulWidget {
  const PaymentMethods2({Key? key}) : super(key: key);

  @override
  _PaymentMethods2State createState() => _PaymentMethods2State();
}

class _PaymentMethods2State extends State<PaymentMethods2> {
  int selectedPaymentMethod = 5; // Only Cash is selected by default

  void _onOtherMethodTapped() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'These payment methods are not currently available in your region',
        ),
        duration: Duration(seconds: 3),
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
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 16, top: 8),
            child: Text(
              'Payment',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontFamily: "Adamina",
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Visa Card
                PaymentMethodTile(
                  index: 0,
                  selectedIndex: selectedPaymentMethod,
                  onTap: _onOtherMethodTapped,
                  icon: 'assets/icons/visa_icon.png',
                  title: 'Visa ending in 1234',
                  subtitle: 'Expiry 06/2024',
                ),
                const SizedBox(height: 12),

                // Mastercard
                PaymentMethodTile(
                  index: 1,
                  selectedIndex: selectedPaymentMethod,
                  onTap: _onOtherMethodTapped,
                  icon: 'assets/icons/master_card_icon.png',
                  title: 'Mastercard ending in 1234',
                  subtitle: 'Expiry 06/2024',
                ),
                const SizedBox(height: 12),

                // Apple Pay
                PaymentMethodTile(
                  index: 2,
                  selectedIndex: selectedPaymentMethod,
                  onTap: _onOtherMethodTapped,
                  icon: 'assets/icons/apple_pay_icon.png',
                  title: 'Visa ending in 1234',
                  subtitle: 'Expiry 06/2024',
                ),
                const SizedBox(height: 12),

                // Stripe
                PaymentMethodTile(
                  index: 3,
                  selectedIndex: selectedPaymentMethod,
                  onTap: _onOtherMethodTapped,
                  icon: 'assets/icons/stripe_icon.png',
                  title: 'Stripe (Visa ending 1234)',
                  subtitle: 'Expiry 06/2024',
                ),
                const SizedBox(height: 12),

                // PayPal
                PaymentMethodTile(
                  index: 4,
                  selectedIndex: selectedPaymentMethod,
                  onTap: _onOtherMethodTapped,
                  icon: 'assets/icons/paypal_icon.png',
                  title: 'PayPal (Visa ending 1234)',
                  subtitle: 'Expiry 06/2024',
                ),
                const SizedBox(height: 12),

                // Cash - Only this one is selectable
                PaymentMethodTile(
                  index: 5,
                  selectedIndex: selectedPaymentMethod,
                  onTap: () {
                    setState(() {
                      selectedPaymentMethod = 5;
                    });
                  },
                  icon: 'assets/icons/cash_icon.png',
                  title: 'Cash',
                  subtitle: '',
                ),
              ],
            ),
          ),

          // Select Button (pops the screen)
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Simply go back after selection
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal[700],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Select',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
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

// Reusable tile (same as your original)
class PaymentMethodTile extends StatelessWidget {
  final int index;
  final int selectedIndex;
  final VoidCallback onTap;
  final String icon;
  final String title;
  final String subtitle;

  const PaymentMethodTile({
    Key? key,
    required this.index,
    required this.selectedIndex,
    required this.onTap,
    required this.icon,
    required this.title,
    required this.subtitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isSelected = index == selectedIndex;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.teal.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Colors.teal.withOpacity(0.4)
                : Colors.grey[200]!,
            width: 1,
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
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    'Set as default',
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected
                          ? const Color(0xFF00A693)
                          : Colors.black54,
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
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
