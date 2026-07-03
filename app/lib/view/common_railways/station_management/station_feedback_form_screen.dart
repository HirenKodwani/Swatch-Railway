import 'package:flutter/material.dart';
import 'package:crm_train/model/station_feedback_model.dart';
import 'package:crm_train/repositories/station_feedback_repository.dart';
import 'package:crm_train/utills/app_colors.dart';

class StationFeedbackFormScreen extends StatefulWidget {
  final String stationId;
  final String stationName;
  const StationFeedbackFormScreen({
    super.key,
    required this.stationId,
    this.stationName = '',
  });

  @override
  State<StationFeedbackFormScreen> createState() => _StationFeedbackFormScreenState();
}

class _StationFeedbackFormScreenState extends State<StationFeedbackFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _commentCtrl = TextEditingController();
  final _otpCtrls = List.generate(6, (_) => TextEditingController());

  int _step = 0; // 0: phone+otp, 1: feedback form, 2: done
  int _rating = 3;
  String _category = feedbackCategories[0];
  bool _isSending = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _commentCtrl.dispose();
    for (final c in _otpCtrls) c.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_phoneCtrl.text.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid 10-digit mobile'), backgroundColor: kErrorRed),
      );
      return;
    }
    setState(() => _isSending = true);
    try {
      await StationFeedbackRepository.sendOtp(_phoneCtrl.text, stationId: widget.stationId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP sent to your mobile'), backgroundColor: kSuccessGreen),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: kErrorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpCtrls.map((c) => c.text).join();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter complete 6-digit OTP'), backgroundColor: kErrorRed),
      );
      return;
    }
    setState(() => _isSending = true);
    try {
      final result = await StationFeedbackRepository.verifyOtp(_phoneCtrl.text, otp);
      if (result['success'] == true) {
        setState(() => _step = 1);
      } else {
        throw Exception(result['error'] ?? 'Verification failed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: kErrorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      await StationFeedbackRepository.submit({
        'stationId': widget.stationId,
        'category': _category,
        'rating': _rating,
        'comments': _commentCtrl.text.trim(),
        'phone': _phoneCtrl.text,
      });
      setState(() => _step = 2);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: kErrorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _nextOtpField(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      FocusScope.of(context).nextFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Station Feedback', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: kRailwayBlue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _step == 0 ? _buildOtpStep() : _step == 1 ? _buildFeedbackStep() : _buildDoneStep(),
      ),
    );
  }

  Widget _buildOtpStep() {
    return Column(
      children: [
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Icon(Icons.phone_iphone, size: 48, color: kRailwayBlue),
                const SizedBox(height: 12),
                const Text('Verify your mobile number', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(widget.stationName, style: const TextStyle(color: kTextSecondary)),
                const SizedBox(height: 16),
                TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  decoration: const InputDecoration(
                    labelText: 'Mobile Number *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _isSending ? null : _sendOtp,
                    style: ElevatedButton.styleFrom(backgroundColor: kRailwayBlue, foregroundColor: Colors.white),
                    child: _isSending
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Send OTP'),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Enter OTP', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (i) => SizedBox(
                    width: 40,
                    child: TextField(
                      controller: _otpCtrls[i],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      decoration: InputDecoration(
                        counterText: '',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onChanged: (v) => _nextOtpField(v, i),
                    ),
                  )),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _isSending ? null : _verifyOtp,
                    style: ElevatedButton.styleFrom(backgroundColor: kSuccessGreen, foregroundColor: Colors.white),
                    child: _isSending
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Verify OTP'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackStep() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Rate Cleanliness', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(widget.stationName, style: const TextStyle(color: kTextSecondary)),
                  const Divider(height: 20),
                  DropdownButtonFormField<String>(
                    value: _category,
                    decoration: const InputDecoration(labelText: 'Category *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.category)),
                    items: feedbackCategories.map((c) => DropdownMenuItem(value: c, child: Text(feedbackCategoryLabel(c)))).toList(),
                    onChanged: (v) { if (v != null) setState(() => _category = v); },
                  ),
                  const SizedBox(height: 20),
                  const Text('Rating *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final starIdx = i + 1;
                      return IconButton(
                        icon: Icon(starIdx <= _rating ? Icons.star : Icons.star_border, color: kWarningOrange, size: 36),
                        onPressed: () => setState(() => _rating = starIdx),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _commentCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Comments',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.comment),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitFeedback,
              style: ElevatedButton.styleFrom(backgroundColor: kSuccessGreen, foregroundColor: Colors.white),
              child: _isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Submit Feedback'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoneStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 60),
        const Icon(Icons.check_circle, size: 80, color: kSuccessGreen),
        const SizedBox(height: 16),
        const Text('Thank You!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Your feedback for ${widget.stationName} has been recorded.',
          style: const TextStyle(fontSize: 15, color: kTextSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(backgroundColor: kRailwayBlue, foregroundColor: Colors.white),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
