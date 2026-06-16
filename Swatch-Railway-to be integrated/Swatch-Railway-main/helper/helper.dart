import 'package:flutter/material.dart';
import 'package:crm_train/model/user_model.dart';

import '../view/common_railways/main_nav_screen.dart';
import '../view/common_workers/worker_mobile_nav_bar.dart';

void navigateUser(BuildContext context, UserModel user) {
  if (user.role == 'Railway Worker') {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => WorkerMobileNavBar(user: user),
      ),
    );
  } else {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MainNavScreen(user: user),
      ),
    );
  }
}
