import 'package:flutter/material.dart';
import 'package:crm_train/model/user_model.dart';
import 'package:crm_train/utills/app_colors.dart';

class ObhsAttendanceScreen extends StatefulWidget {
  final UserModel user;

  const ObhsAttendanceScreen({super.key, required this.user});

  @override
  State<ObhsAttendanceScreen> createState() => _ObhsAttendanceScreenState();
}

class _ObhsAttendanceScreenState extends State<ObhsAttendanceScreen> {
  bool isGpsVerified = false;
  bool isFaceVerified = false;
  bool isVerifyingGps = false;
  bool isVerifyingFace = false;

  void _verifyGps() async {
    setState(() => isVerifyingGps = true);
    // Mock network/GPS delay
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        isGpsVerified = true;
        isVerifyingGps = false;
      });
    }
  }

  void _verifyFace() async {
    setState(() => isVerifyingFace = true);
    // Mock face scan delay
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        isFaceVerified = true;
        isVerifyingFace = false;
      });
    }
  }

  void _submitAttendance() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Attendance Marked Successfully!'),
        backgroundColor: kSuccessGreen,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Mark Attendance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: kRailwayBlue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Daily Attendance',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kRailwayBlue),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'You must verify your location and face to mark attendance.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),

            // GPS Verification Card
            _buildVerificationCard(
              title: 'Location Verification',
              subtitle: isGpsVerified ? 'GPS Location Match: Train 12456' : 'Verify your current location',
              icon: Icons.location_on,
              isVerified: isGpsVerified,
              isVerifying: isVerifyingGps,
              onVerify: _verifyGps,
            ),
            const SizedBox(height: 24),

            // Face Verification Card
            _buildVerificationCard(
              title: 'Face Verification',
              subtitle: isFaceVerified ? 'Face Matched successfully' : 'Scan your face',
              icon: Icons.face,
              isVerified: isFaceVerified,
              isVerifying: isVerifyingFace,
              onVerify: _verifyFace,
            ),

            const Spacer(),
            
            ElevatedButton(
              onPressed: (isGpsVerified && isFaceVerified) ? _submitAttendance : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: kRailwayBlue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Mark Present',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isVerified,
    required bool isVerifying,
    required VoidCallback onVerify,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isVerified ? kSuccessGreen : Colors.grey[300]!, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isVerified ? kSuccessGreen.withOpacity(0.1) : kRailwayBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: isVerified ? kSuccessGreen : kRailwayBlue, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          if (isVerified)
            const Icon(Icons.check_circle, color: kSuccessGreen, size: 32)
          else if (isVerifying)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: kRailwayBlue),
            )
          else
            TextButton(
              onPressed: onVerify,
              style: TextButton.styleFrom(
                backgroundColor: kRailwayBlue.withOpacity(0.1),
                foregroundColor: kRailwayBlue,
              ),
              child: const Text('Verify'),
            ),
        ],
      ),
    );
  }
}
