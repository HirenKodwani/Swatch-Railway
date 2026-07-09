import 'package:flutter/material.dart';

import '../../../utills/app_colors.dart';

class ContractorMasterAlertScreen extends StatelessWidget {
  const ContractorMasterAlertScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600, fontSize: 20),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: kRailwayBlue,
        elevation: 0.5,

      ),

      body: Center(
        child: Text('No Notification Found !'),
      ),

    );
  }
}
