import 'dart:developer';

import 'package:hisabi/controller/voice_entry_controller.dart';
import 'package:hisabi/view/home/home_page.dart';
import 'package:hisabi/view/profile/profile_page.dart';
import 'package:hisabi/view/transactions/add_transactions_page.dart';
import 'package:hisabi/view/transactions/analytics_page.dart';
import 'package:hisabi/view/transactions/transactions_page.dart';
import 'package:flutter/material.dart';
import 'package:floating_bottom_bar/animated_bottom_navigation_bar.dart'
    hide AppColors;
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:hisabi/view/widgets/listening_oveerlay.dart';
import '../../constants/app_colors.dart';

class MainPage extends StatefulWidget {
  final int initialIndex;

  const MainPage({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  late FloatingBottomBarController _barController;

  final _pages = [
    HomePage(),
    TransactionsPage(),
    AnalyticsPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    // pick up the passed-in tab
    _currentIndex = widget.initialIndex;
    _barController = FloatingBottomBarController(initialIndex: _currentIndex);
  }

  @override
  Widget build(BuildContext context) {
      final vc = Get.find<AutoListenController>();

    return Scaffold(
      // ─── 1 ─── let your bar float above body
      extendBody: true,

     body: Stack(
      children: [
        // 1) your existing content
        SafeArea(
          bottom: false,
          child: _pages[_currentIndex],
        ),

        // 2) the listening overlay
        Obx(() => vc.isListening.value
            ? const ListeningOverlay()
            : const SizedBox.shrink()),
      ],
    ),

      // reserve the notch hole under the center icon
      floatingActionButton: const SizedBox(height: 56, width: 56),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // ─── BOTTOM NAV BAR ──────────────────────────────────────────────────
      bottomNavigationBar: Transform.translate(
        // if you still see a small gap, you can nudge the bar down/up here:
        offset: const Offset(0, 0), // e.g. (0, 5) to move it down 5px
        child: AnimatedBottomNavigationBar(
          key: ValueKey(_currentIndex),        // ← force rebuild on index change
          barColor: AppColors.white, // see your page behind it
          controller: _barController,

          bottomBar: [
            BottomBarItem(
              icon: const Icon(Icons.home, color: Colors.grey),
              iconSelected: Icon(Icons.home, color: AppColors.primary),
              title: 'Home',
              dotColor: AppColors.primary,
              onTap: (i) {
                _barController.initialIndex = i;
                setState(() => _currentIndex = i);
                log('Home: $i');
              },
            ),
            BottomBarItem(
              icon: const Icon(Icons.list, color: Colors.grey),
              iconSelected: Icon(Icons.list, color: AppColors.primary),
              title: 'Transactions',
              dotColor: AppColors.primary,
              onTap: (i) {
                _barController.initialIndex = i;
                setState(() => _currentIndex = i);
                log('Txns: $i');
              },
            ),
            BottomBarItem(
              icon: const Icon(
                Icons.bar_chart_rounded,
                color: Colors.grey, // unselected color
              ),
              iconSelected: Icon(
                Icons.bar_chart_rounded,
                color: AppColors.primary, // selected color
              ),
              title: 'Analytics',
              dotColor: AppColors.primary,
              onTap: (i) {
                _barController.initialIndex = i;
                setState(() => _currentIndex = i);
                log('Analytics: $i');
              },
            ),
            BottomBarItem(
              icon: const Icon(
                Icons.person,
                color: Colors.grey, // unselected color
              ),
              iconSelected: Icon(
                Icons.person,
                color: AppColors.primary, // selected color
              ),
              title: 'Profile',
              dotColor: AppColors.primary,
              onTap: (i) {
                _barController.initialIndex = i;
                setState(() => _currentIndex = i);
                log('Profile: $i');
              },
            ),
          ],

          bottomBarCenterModel: BottomBarCenterModel(
            centerBackgroundColor: AppColors.primary,

            // wrap the icon so tap goes straight to AddPage
            centerIcon: FloatingCenterButton(
              child: GestureDetector(
                onTap: () async {
                  Get.to(() => AddTransactionPage())?.then((_) {
                    setState(() {
                      // 🔄 Recreate with the “current” tab index
                      _barController = FloatingBottomBarController(
                        initialIndex: _currentIndex,
                      );
                    });
                  });
                },
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),

            // no children, so it never expands
            centerIconChild: const [],
          ),
        ),
      ),
    );
  }
}
