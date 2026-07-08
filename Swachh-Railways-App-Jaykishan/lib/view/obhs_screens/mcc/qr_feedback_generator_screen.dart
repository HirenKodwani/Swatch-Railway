import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:crm_train/model/run_instance_model.dart';
import 'package:crm_train/utills/app_colors.dart';

class QrFeedbackGeneratorScreen extends StatelessWidget {
  final RunInstanceModel instance;

  const QrFeedbackGeneratorScreen({super.key, required this.instance});

  @override
  Widget build(BuildContext context) {
    // This URL will point to our web feedback portal
    // Assuming the base URL for the portal is predefined
    const String portalBaseUrl = "https://smell-railways.web.app/feedback";
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Journey Feedback QR'),
        backgroundColor: kRailwayBlue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      instance.trainName ?? "Unknown Train",
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Train No: ${instance.trainNo}',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Scan to provide Feedback',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: QrImageView(
                        data: "$portalBaseUrl?runInstanceId=${instance.runInstanceId ?? instance.id}",
                        version: QrVersions.auto,
                        size: 250.0,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'This QR is valid for the current journey only.',
                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Instructions for MCC:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const ListTile(
              leading: Icon(Icons.print, color: kRailwayBlue),
              title: Text('Print this QR and paste it in the coach near the entrance or toilets.'),
            ),
            const ListTile(
              leading: Icon(Icons.mobile_friendly, color: kRailwayBlue),
              title: Text('Passengers can scan this from their own phone to rate the cleanliness.'),
            ),
          ],
        ),
      ),
    );
  }
}
