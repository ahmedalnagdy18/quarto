import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:quarto/features/cafe/presentation/screens/cafe_screen.dart';
import 'package:quarto/features/dashboard/presentation/screens/new_dashboard_page.dart';

class MainAppPage extends StatefulWidget {
  const MainAppPage({super.key});

  @override
  State<MainAppPage> createState() => _MainProjectPageState();
}

class _MainProjectPageState extends State<MainAppPage> {
  final List<Widget> pages = [
    const CafeScreen(),
    const NewDashboardPage(),
    const CafeScreen(),
  ];

  int selectedIndex = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // الخلفية
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Image.asset(
              "images/bg.png",
              fit: BoxFit.cover,
            ),
          ),

          // الصفحة
          pages[selectedIndex],

          // bottom navigation
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 20,
                    sigmaY: 20,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 20,
                    ),
                    width: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withOpacity(0.4)),
                      color: Colors.white.withOpacity(0.08),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          children: [
                            InkWell(
                              onTap: () => _onItemTapped(0),
                              child: Icon(
                                selectedIndex == 0
                                    ? Icons.local_cafe
                                    : Icons.local_cafe_outlined,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Cafe",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: selectedIndex == 0
                                    ? FontWeight.bold
                                    : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            InkWell(
                              onTap: () => _onItemTapped(1),
                              child: Icon(
                                selectedIndex == 1
                                    ? Icons.sports_esports
                                    : Icons.sports_esports_outlined,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "PlayStation",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: selectedIndex == 1
                                    ? FontWeight.bold
                                    : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            InkWell(
                              onTap: () => _onItemTapped(2),
                              child: Icon(
                                selectedIndex == 2
                                    ? Icons.analytics
                                    : Icons.analytics_outlined,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Analytics",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: selectedIndex == 2
                                    ? FontWeight.bold
                                    : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onItemTapped(int value) {
    setState(() {
      selectedIndex = value;
    });
  }
}
