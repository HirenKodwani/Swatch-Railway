import 'package:flutter/material.dart';

import '../../../utills/app_colors.dart';


class CommonAlertScreen extends StatelessWidget {
  const CommonAlertScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> notifications = [
      {
        'message':
        'Scorecard SC-001 requires your acceptance within 23 minutes to avoid auto-approval',
        'time': '612d ago',
      },
      {
        'message':
        'Your premises form PF-004 has been submitted for railway review',
        'time': '612d ago',
      },
      {
        'message':
        'Scorecard SC-002 was auto-approved due to 30-minute timeout expiry',
        'time': '613d ago',
      },
      {
        'message':
        'Updated cleaning guidelines for mechanized coach maintenance are now available',
        'time': '614d ago',
      },
      {
        'message':
        'Coach form CF-003 received excellent scorecard rating (Grade A - 95%)',
        'time': '615d ago',
      },
    ];

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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('No Alerts Found.')
          ],
        ),
      ),
    );
  }
}
