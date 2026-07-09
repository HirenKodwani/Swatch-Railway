import 'package:flutter/material.dart';
import 'package:crm_train/utills/app_colors.dart';
import 'forms/cts_form_screen_v2.dart';
import 'forms/new_coach_form.dart';
import 'forms/new_premises_form.dart';

class SelectFormTypeScreen extends StatelessWidget {
  const SelectFormTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        title: const Text(
          'New Manpower Form',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: kRailwayBlue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Form Type',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Choose the type of cleaning form you want to create',
              style: TextStyle(fontSize: 15, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            _buildFormCard(
              context,
              icon: Icons.train,
              iconColor: Colors.green,
              title: 'Coach Cleaning',
              subtitle: 'Mechanized Coach Cleaning & Watering',
              info: 'Multi-step form • Advanced equipment tracking',
              highlightColor: Colors.green,
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => NewCoachFormScreen()));
              },
            ),
            const SizedBox(height: 16),
            _buildFormCard(
              context,
              icon: Icons.apartment,
              iconColor: Colors.purple,
              title: 'Premises Cleaning',
              subtitle: 'Depot Premises Cleaning',
              info: 'Quick form • General cleaning tasks',
              highlightColor: Colors.purple,
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => PremisesCleaningForm()));
              },
            ),
            const SizedBox(height: 16),
            _buildFormCard(
              context,
              icon: Icons.directions_railway,
              iconColor: Colors.orange,
              title: 'CTS Train Halt Cleaning',
              subtitle: 'Train Halt Cleaning Job Sheet',
              info: 'Execution form • Attendance & disposal tracking',
              highlightColor: Colors.orange,
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => NewCTSFormScreen()));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard(
      BuildContext context, {
        required IconData icon,
        required Color iconColor,
        required String title,
        required String subtitle,
        required String info,
        required Color highlightColor,
        required VoidCallback onTap,
      }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: highlightColor.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: highlightColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: highlightColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 15, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          info,
                          style: const TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}