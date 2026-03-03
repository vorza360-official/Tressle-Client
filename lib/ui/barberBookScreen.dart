import 'package:flutter/material.dart';

class BarberShopScreen extends StatefulWidget {
  const BarberShopScreen({Key? key}) : super(key: key);

  @override
  State<BarberShopScreen> createState() => _BarberShopScreenState();
}

class _BarberShopScreenState extends State<BarberShopScreen> {
  // State for checkboxes
  Map<String, bool> services = {
    'Haircut': false,
    'Shave': false,
    'Hair Color': false,
    'Beard': false,
    'Massage': false,
    'Highlights': false,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Hero Image Section
          Container(
            height: 200,
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: const DecorationImage(
                image: AssetImage('assets/images/dummy_image_map.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // About Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'About',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam...',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Services Grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 8,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 12,
                  children: services.keys.map((service) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          services[service] = !services[service]!;
                        });
                      },
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: services[service]! 
                                  ? Colors.teal[700] 
                                  : Colors.transparent,
                              border: Border.all(
                                color: services[service]! 
                                    ? Colors.teal[700]! 
                                    : Colors.grey[400]!,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: services[service]!
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 14,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            service,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          
          const Spacer(),
          
          // Book Appointment Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  // Get selected services
                  List<String> selectedServices = services.entries
                      .where((entry) => entry.value)
                      .map((entry) => entry.key)
                      .toList();
                  
                  // Show selected services (you can replace with navigation)
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        selectedServices.isEmpty
                            ? 'No services selected'
                            : 'Selected: ${selectedServices.join(', ')}',
                      ),
                      backgroundColor: Colors.teal[700],
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal[700],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Book Appointment - \$250',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
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

// Usage example:
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Barber Shop',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        fontFamily: 'Roboto',
      ),
      home: const BarberShopScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}