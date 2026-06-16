import 'package:crm_train/controllers/worker_controller.dart';
import 'package:crm_train/model/user_model.dart';
import 'package:crm_train/view/common_workers/worker_attendance_screen.dart';
import 'package:crm_train/view/common_workers/worker_complaints_screen.dart';
import 'package:crm_train/view/common_workers/worker_mobile_home_screen.dart';
import 'package:crm_train/view/common_workers/worker_rating_screen.dart';
import 'package:crm_train/view/common_workers/worker_task_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import '../../utills/app_colors.dart';

class WorkerMobileNavBar extends StatefulWidget {
  final UserModel user;

  const WorkerMobileNavBar({super.key, required this.user});

  @override
  State<WorkerMobileNavBar> createState() => _WorkerMobileNavBarState();
}

class _WorkerMobileNavBarState extends State<WorkerMobileNavBar> {
  late WorkerController workerController;

  @override
  void initState() {
    super.initState();

    workerController = Get.put(WorkerController());
    workerController.setUser(widget.user);
  }

  @override
  void dispose() {
    Get.delete<WorkerController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PersistentTabView(
      context,
      screens: _buildScreens(),
      items: _buildNavItems(),
      confineToSafeArea: true,
      backgroundColor: Colors.white,
      handleAndroidBackButtonPress: true,
      resizeToAvoidBottomInset: true,
      stateManagement: true,
      decoration: NavBarDecoration(
        borderRadius: BorderRadius.circular(15.0),
        colorBehindNavBar: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      navBarStyle: NavBarStyle.style12,
    );
  }

  List<Widget> _buildScreens() {
    return [
      WorkerMobileHomeScreen(),
      WorkerTaskScreen(),
      WorkerAttendanceScreen(),
      WorkerComplaintsScreen(),
      // isOfficialMode: false → Passenger rating by default.
      // Pass true when user role is TTE / Official.
      const WorkerRatingScreen(isOfficialMode: false),
    ];
  }

  List<PersistentBottomNavBarItem> _buildNavItems() {
    return [
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.dashboard_rounded),
        title: "Home",
        activeColorPrimary: kRailwayBlue,
        inactiveColorPrimary: Colors.grey,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.event_note_rounded),
        title: "Tasks",
        activeColorPrimary: kRailwayBlue,
        inactiveColorPrimary: Colors.grey,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.description),
        title: "Attendance",
        activeColorPrimary: kRailwayBlue,
        inactiveColorPrimary: Colors.grey,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.report_rounded),
        title: "Complaints",
        activeColorPrimary: kRailwayBlue,
        inactiveColorPrimary: Colors.grey,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.star_rounded),
        title: "Ratings",
        activeColorPrimary: kRailwayBlue,
        inactiveColorPrimary: Colors.grey,
      ),
    ];
  }
}