import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:crm_train/repositories/station_feedback_repository.dart';
import 'package:crm_train/services/api_services.dart';
import 'package:crm_train/utills/app_colors.dart';

class FeedbackQrScreen extends StatefulWidget {
  final String stationId;
  final String stationName;
  const FeedbackQrScreen({super.key, required this.stationId, required this.stationName});

  @override
  State<FeedbackQrScreen> createState() => _FeedbackQrScreenState();
}

class _FeedbackQrScreenState extends State<FeedbackQrScreen> {
  String? _feedbackUrl;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadQrData();
  }

  Future<void> _loadQrData() async {
    setState(() => _isLoading = true);
    try {
      final data = await StationFeedbackRepository.getQrData(widget.stationId);
      setState(() {
        _feedbackUrl = (data['feedbackUrl'] ?? data['url'] ?? '').toString();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayUrl = _feedbackUrl ?? '${ApiService.baseUrl}/feedback/${widget.stationId}';
    return Scaffold(
      appBar: AppBar(
        title: Text('Feedback QR - ${widget.stationName}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: kRailwayBlue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: kErrorRed),
                      const SizedBox(height: 12),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _loadQrData, child: const Text('Retry')),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              const Icon(Icons.qr_code_2, size: 48, color: kRailwayBlue),
                              const SizedBox(height: 12),
                              Text(widget.stationName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              const Text('Scan to give feedback', style: TextStyle(color: kTextSecondary)),
                              const SizedBox(height: 24),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: QrImageView(
                                  data: displayUrl,
                                  version: QrVersions.auto,
                                  size: 220,
                                  eyeStyle: const QrEyeStyle(color: kRailwayBlue, eyeShape: QrEyeShape.square),
                                  dataModuleStyle: const QrDataModuleStyle(color: kRailwayBlue, dataModuleShape: QrDataModuleShape.square),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        displayUrl,
                                        style: const TextStyle(fontSize: 12, color: kTextSecondary),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.copy, size: 20),
                                      onPressed: () {
                                        Clipboard.setData(ClipboardData(text: displayUrl));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('URL copied to clipboard'), backgroundColor: kSuccessGreen),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Instructions', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                              const Divider(),
                              _instructionRow(Icons.print, 'Print this QR code and display at station premises'),
                              _instructionRow(Icons.phone_iphone, 'Passengers scan with their phone camera'),
                              _instructionRow(Icons.rate_review, 'Submit feedback on cleanliness & facilities'),
                              _instructionRow(Icons.share, 'Share URL via WhatsApp or other channels'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _instructionRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: kRailwayBlue),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
