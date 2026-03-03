import 'package:flutter/material.dart';
import 'package:tressle_app_1/UI/HomeScreen.dart';
import 'package:tressle_app_1/UI/Widgets/historyBooking.dart';
import 'package:tressle_app_1/UI/Widgets/upCommingBooking.dart';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool isHistorySelected = false;

  // Add PageController
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: isHistorySelected ? 1 : 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _switchPage(int page) {
    setState(() {
      isHistorySelected = page == 1;
    });
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => MainScreen(index: 0)),
          (Route<dynamic> route) => false,
        );
        return false; // Prevents default back button behavior
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey[100],
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _switchPage(0),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: !isHistorySelected
                                  ? Colors.teal[700]
                                  : Colors.transparent,
                              boxShadow: !isHistorySelected
                                  ? [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.2),
                                        spreadRadius: 1,
                                        blurRadius: 3,
                                        offset: Offset(0, 1),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Center(
                              child: Text(
                                'Upcoming',
                                style: TextStyle(
                                  fontFamily: "Adamina",
                                  color: !isHistorySelected
                                      ? Colors.white
                                      : Colors.grey[600],
                                  fontWeight: !isHistorySelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _switchPage(1),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: isHistorySelected
                                  ? Colors.teal[700]
                                  : Colors.transparent,
                            ),
                            child: Center(
                              child: Text(
                                'History',
                                style: TextStyle(
                                  fontFamily: "Adamina",
                                  color: isHistorySelected
                                      ? Colors.white
                                      : Colors.grey[600],
                                  fontWeight: isHistorySelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      isHistorySelected = index == 1;
                    });
                  },
                  children: [
                    UpCommingBookingWidget(), // Page 0
                    HistoryBookingWidget(), // Page 1
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
