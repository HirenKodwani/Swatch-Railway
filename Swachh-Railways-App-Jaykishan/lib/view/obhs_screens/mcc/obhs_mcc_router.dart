import 'package:flutter/material.dart';
import 'package:crm_train/model/user_model.dart';

import 'cm_dashboard_screen.dart';
import 'ca_dashboard_screen.dart';
import 'cts_train_view_screen.dart';
import 'cs_field_execution_screen.dart';
import 'janitor_home_screen.dart';
import 'attendant_linen_screen.dart';
import 'attendant_home_screen.dart';

class ObhsMccRouter extends StatelessWidget {
  final UserModel user;

  const ObhsMccRouter({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    switch (user.role) {
      case 'CM':
        return CmDashboardScreen(user: user);
      case 'CA':
        return CaDashboardScreen(user: user);
      case 'CTS':
        return CtsTrainViewScreen(user: user);
      case 'CS':
        return CsFieldExecutionScreen(user: user);
      case 'Janitor':
        return JanitorHomeScreen(user: user);
      case 'Attendant':
        return AttendantHomeScreen(user: user);
      default:
        return const Scaffold(
          body: Center(
            child: Text('Role not recognized in MCC workflow.'),
          ),
        );
    }
  }
}
