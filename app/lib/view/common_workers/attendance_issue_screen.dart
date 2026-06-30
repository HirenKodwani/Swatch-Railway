import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/worker_controller.dart';
import '../../utills/app_colors.dart';

class AttendanceIssueScreen extends StatefulWidget {
  final String attendanceType;
  const AttendanceIssueScreen({super.key, required this.attendanceType});

  @override
  State<AttendanceIssueScreen> createState() => _AttendanceIssueScreenState();
}

class _AttendanceIssueScreenState extends State<AttendanceIssueScreen> {
  final _controller = Get.find<WorkerController>();
  final _remarkController = TextEditingController();
  String? _selectedIssueType;

  final List<String> _issueTypes = [
    'Train Delayed',
    'Train Not Arrived',
    'Platform Changed',
    'Coach Not Accessible',
    'Face Verification Failed',
    'GPS Verification Failed',
    'Network Issue',
    'Medical Emergency',
    'Roster Change',
    'Other'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Attendance Issue', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.redAccent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Encountered an issue?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Tell us what happened so we can adjust your attendance record.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            
            DropdownButtonFormField<String>(
              value: _selectedIssueType,
              decoration: InputDecoration(
                labelText: 'Issue Type',
                prefixIcon: const Icon(Icons.report_problem),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: _issueTypes.map((type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedIssueType = value),
            ),
            const SizedBox(height: 20),
            
            TextField(
              controller: _remarkController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Worker Remark',
                hintText: 'e.g. Train running 2 hours late.',
                alignLabelWithHint: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 30),
            
            Obx(() => SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _controller.isLoading.value || _selectedIssueType == null
                    ? null
                    : () async {
                        await _controller.reportAttendanceIssue(
                          issueType: _selectedIssueType!,
                          remark: _remarkController.text,
                          attendanceType: widget.attendanceType,
                        );
                        Get.back();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _controller.isLoading.value
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Submit Issue',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}
