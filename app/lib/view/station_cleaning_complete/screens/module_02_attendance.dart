import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:crm_train/utills/app_colors.dart';

class AttendanceManagementScreen extends StatefulWidget {
  final String stationId;
  final String stationName;
  const AttendanceManagementScreen({super.key, required this.stationId, required this.stationName});

  @override
  State<StatefulWidget> createState() => _AttendanceManagementScreenState();
}

class _AttendanceManagementScreenState extends State<AttendanceManagementScreen> {
  String _selectedDate = DateFormat('dd-MM-yyyy').format(DateTime.now());
  String _selectedShift = 'Morning';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ATTENDANCE MANAGEMENT', style: TextStyle(color: Colors.white)), backgroundColor: kRailwayBlue, iconTheme: const IconThemeData(color: Colors.white)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilters(),
            const SizedBox(height: 12),
            _buildSummaryCards(),
            const SizedBox(height: 12),
            _buildAttendanceList(),
            const SizedBox(height: 12),
            _buildBiometricSection(),
            const SizedBox(height: 12),
            _buildManualFallback(),
            const SizedBox(height: 12),
            _buildPlannedVsActual(),
            const SizedBox(height: 12),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () async {
                  final picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2024), lastDate: DateTime.now());
                  if (picked != null) setState(() => _selectedDate = DateFormat('dd-MM-yyyy').format(picked));
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Date', isDense: true, suffixIcon: Icon(Icons.calendar_today, size: 18)),
                  child: Text(_selectedDate),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedShift,
                decoration: const InputDecoration(labelText: 'Shift', isDense: true),
                items: ['Morning', 'Afternoon', 'Night'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => _selectedShift = v!),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: 'All',
                decoration: const InputDecoration(labelText: 'Mode', isDense: true),
                items: ['All', 'Biometric', 'Manual'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (_) {},
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(children: [
      _summaryCard('Total', '25', kRailwayBlue),
      _summaryCard('Present', '18', Colors.green),
      _summaryCard('Late', '3', kWarningOrange),
      _summaryCard('Absent', '2', kErrorRed),
      _summaryCard('Leave', '2', Colors.grey),
    ]);
  }

  Widget _summaryCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(2),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
        child: Column(children: [Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)), Text(label, style: TextStyle(fontSize: 10, color: color))]),
      ),
    );
  }

  Widget _buildAttendanceList() {
    final workers = [
      {'name': 'Amit Kumar', 'shift': 'Morn', 'status': 'Present', 'time': '08:00', 'mode': 'Biometric'},
      {'name': 'Rohit Sharma', 'shift': 'Morn', 'status': 'Late', 'time': '08:15', 'mode': 'Manual'},
      {'name': 'Suresh Patel', 'shift': 'Morn', 'status': 'Absent', 'time': '-', 'mode': '-'},
      {'name': 'Deepak Verma', 'shift': 'Morn', 'status': 'Present', 'time': '07:55', 'mode': 'Biometric'},
      {'name': 'Priya Patel', 'shift': 'Morn', 'status': 'On Leave', 'time': '-', 'mode': '-'},
    ];

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('WORKER ATTENDANCE LIST', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const Divider(),
            Table(
              columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(0.8), 2: FlexColumnWidth(1.2), 3: FlexColumnWidth(0.8), 4: FlexColumnWidth(1), 5: FlexColumnWidth(0.5)},
              children: [
                const TableRow(children: [Text('Worker', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), Text('Shift', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), Text('Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), Text('Mode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), Text('Img', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))]),
                ...workers.map((w) => TableRow(children: [
                  Text(w['name']!, style: const TextStyle(fontSize: 11)),
                  Text(w['shift']!, style: const TextStyle(fontSize: 11)),
                  Row(children: [
                    Icon(_statusIcon(w['status']!), size: 14, color: _statusColor(w['status']!)),
                    const SizedBox(width: 4),
                    Text(w['status']!, style: TextStyle(fontSize: 11, color: _statusColor(w['status']!))),
                  ]),
                  Text(w['time']!, style: const TextStyle(fontSize: 11)),
                  Text(w['mode']!, style: const TextStyle(fontSize: 11)),
                  const Icon(Icons.image, size: 16, color: kRailwayBlue),
                ])),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'Present': return Icons.check_circle;
      case 'Late': return Icons.warning;
      case 'Absent': return Icons.cancel;
      case 'On Leave': return Icons.event_busy;
      default: return Icons.help;
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'Present': return Colors.green;
      case 'Late': return kWarningOrange;
      case 'Absent': return kErrorRed;
      case 'On Leave': return Colors.grey;
      default: return Colors.grey;
    }
  }

  Widget _buildBiometricSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [Icon(Icons.fingerprint, color: kRailwayBlue), SizedBox(width: 8), Text('BIOMETRIC INTEGRATION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))]),
            const SizedBox(height: 8),
            Row(children: [
              ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.sync, size: 18), label: const Text('Sync Biometric', style: TextStyle(fontSize: 12))),
              const SizedBox(width: 16),
              const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Last Sync: 08:30 AM', style: TextStyle(fontSize: 11)),
                Text('Device: ✅ Connected', style: TextStyle(fontSize: 11, color: Colors.green)),
                Text('Records: 18/20', style: TextStyle(fontSize: 11)),
              ]),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildManualFallback() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [Icon(Icons.edit_note, color: kWarningOrange), SizedBox(width: 8), Text('MANUAL FALLBACK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))]),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(labelText: 'Reason for manual entry', hintText: 'Biometric machine down...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), isDense: true),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            Row(children: [
              OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.camera_alt, size: 18), label: const Text('Take Photo', style: TextStyle(fontSize: 12))),
              const SizedBox(width: 8),
              ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.check, size: 18), label: const Text('Mark Attendance', style: TextStyle(fontSize: 12))),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildPlannedVsActual() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('PLANNED VS ACTUAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Table(columnWidths: const {0: FlexColumnWidth(1.5), 1: FlexColumnWidth(1), 2: FlexColumnWidth(1), 3: FlexColumnWidth(1), 4: FlexColumnWidth(1.5)}, children: [
              const TableRow(children: [Text('Shift', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), Text('Planned', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), Text('Actual', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), Text('Variance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))]),
              _plannedRow('Morning', '15', '12', '-3', kWarningOrange),
              _plannedRow('Afternoon', '10', '10', '0', Colors.green),
              _plannedRow('Night', '5', '5', '0', Colors.green),
            ]),
          ],
        ),
      ),
    );
  }

  TableRow _plannedRow(String shift, String planned, String actual, String variance, Color color) {
    return TableRow(children: [
      Text(shift, style: const TextStyle(fontSize: 11)),
      Text(planned, style: const TextStyle(fontSize: 11)),
      Text(actual, style: const TextStyle(fontSize: 11)),
      Text(variance, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      Row(children: [Icon(variance == '0' ? Icons.check_circle : Icons.warning, size: 14, color: color), Text(variance == '0' ? ' Full' : ' Shortage', style: TextStyle(fontSize: 11, color: color))]),
    ]);
  }

  Widget _buildActions() {
    return Row(children: [
      Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.download), label: const Text('Export Report'))),
      const SizedBox(width: 8),
      Expanded(child: ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.checklist), label: const Text('Mark Bulk'))),
      const SizedBox(width: 8),
      Expanded(child: OutlinedButton.icon(onPressed: () => setState(() {}), icon: const Icon(Icons.refresh), label: const Text('Refresh'))),
    ]);
  }
}

class ManualFallbackScreen extends StatelessWidget {
  final String stationId;
  final String stationName;
  const ManualFallbackScreen({super.key, required this.stationId, required this.stationName});

  @override
  Widget build(BuildContext context) {
    final workers = ['Amit Kumar', 'Rohit Sharma', 'Suresh Patel', 'Deepak Verma', 'Priya Patel'];
    return Scaffold(
      appBar: AppBar(title: const Text('MANUAL ATTENDANCE', style: TextStyle(color: Colors.white)), backgroundColor: kRailwayBlue, iconTheme: const IconThemeData(color: Colors.white)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: kErrorRed.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: kErrorRed)),
              child: const Row(children: [Icon(Icons.warning, color: kErrorRed), SizedBox(width: 8), Text('BIOMETRIC MACHINE STATUS: ❌ OUT OF ORDER', style: TextStyle(fontWeight: FontWeight.bold, color: kErrorRed))]),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('SELECT WORKER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    ...workers.map((w) => CheckboxListTile(
                      title: Text(w, style: const TextStyle(fontSize: 13)),
                      secondary: Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(icon: const Icon(Icons.camera_alt, size: 18), onPressed: () {}),
                        IconButton(icon: const Icon(Icons.check_circle, color: Colors.green, size: 18), onPressed: () {}),
                      ]),
                      value: true,
                      onChanged: (_) {},
                      dense: true,
                      controlAffinity: ListTileControlAffinity.leading,
                    )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ENTRY DETAILS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    TextFormField(decoration: const InputDecoration(labelText: 'Entry Time', hintText: '08:30 AM', isDense: true), initialValue: '08:30 AM'),
                    const SizedBox(height: 8),
                    TextFormField(decoration: const InputDecoration(labelText: 'Reason', hintText: 'Biometric machine down - manual entry', isDense: true), initialValue: 'Biometric machine down - manual entry'),
                    const SizedBox(height: 8),
                    TextFormField(decoration: const InputDecoration(labelText: 'Verified By', hintText: 'Rajesh Sharma', isDense: true), initialValue: 'Rajesh Sharma (Supervisor)'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.check), label: const Text('SUBMIT MANUAL ATTENDANCE'))),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL'))),
            ]),
          ],
        ),
      ),
    );
  }
}
