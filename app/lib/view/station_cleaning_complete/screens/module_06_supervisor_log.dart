import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:crm_train/utills/app_colors.dart';

class SupervisorDailyLogScreen extends StatefulWidget {
  final String stationId;
  final String stationName;
  const SupervisorDailyLogScreen({super.key, required this.stationId, required this.stationName});

  @override
  State<StatefulWidget> createState() => _SupervisorDailyLogScreenState();
}

class _SupervisorDailyLogScreenState extends State<SupervisorDailyLogScreen> {
  String _selectedDate = DateFormat('dd-MM-yyyy').format(DateTime.now());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SUPERVISOR DAILY LOG', style: TextStyle(color: Colors.white)), backgroundColor: kRailwayBlue, iconTheme: const IconThemeData(color: Colors.white)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildHeader(),
          const SizedBox(height: 12),
          _buildActivitiesDone(),
          const SizedBox(height: 12),
          _buildAttendance(),
          const SizedBox(height: 12),
          _buildMachineUsage(),
          const SizedBox(height: 12),
          _buildIssues(),
          const SizedBox(height: 12),
          _buildUnresolvedWork(),
          const SizedBox(height: 12),
          _buildHandoverNotes(),
          const SizedBox(height: 12),
          _buildActions(),
        ]),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(elevation: 2, child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [
      Row(children: [
        Expanded(child: DropdownButtonFormField(value: 'Bhopal Junction', decoration: const InputDecoration(labelText: 'Station', isDense: true), items: ['Bhopal Junction'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (_) {})),
        const SizedBox(width: 8),
        Expanded(child: InkWell(onTap: () async {
          final picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2024), lastDate: DateTime.now());
          if (picked != null) setState(() => _selectedDate = DateFormat('dd-MM-yyyy').format(picked));
        }, child: InputDecorator(decoration: const InputDecoration(labelText: 'Date', isDense: true, suffixIcon: Icon(Icons.calendar_today, size: 18)), child: Text(_selectedDate)))),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: DropdownButtonFormField(value: 'Morning', decoration: const InputDecoration(labelText: 'Shift', isDense: true), items: ['Morning', 'Afternoon', 'Night'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (_) {})),
        const SizedBox(width: 8),
        Expanded(child: TextFormField(decoration: const InputDecoration(labelText: 'Supervisor', isDense: true), initialValue: 'Rajesh Sharma')),
      ]),
    ])));
  }

  Widget _buildActivitiesDone() {
    return Card(elevation: 2, child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('ACTIVITIES DONE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      const SizedBox(height: 8),
      ...[
        'PF-1 Toilet Block - Cleaning - 08:00 AM - Completed',
        'PF-1 Surface - Sweeping - 09:00 AM - Completed',
        'PF-2 Toilet Block - Cleaning - 10:00 AM - In Progress',
      ].map((a) => CheckboxListTile(
        title: Text(a, style: const TextStyle(fontSize: 12)),
        value: true,
        onChanged: (_) {},
        dense: true,
        controlAffinity: ListTileControlAffinity.leading,
      )),
      OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.add, size: 16), label: const Text('Add Activity', style: TextStyle(fontSize: 12))),
    ])));
  }

  Widget _buildAttendance() {
    return Card(elevation: 2, child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('MANPOWER ATTENDANCE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      const SizedBox(height: 8),
      Table(columnWidths: const {0: FlexColumnWidth(1.5), 1: FlexColumnWidth(1), 2: FlexColumnWidth(1), 3: FlexColumnWidth(0.8), 4: FlexColumnWidth(0.8), 5: FlexColumnWidth(1)}, children: [
        const TableRow(children: [Text('Shift', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), Text('Planned', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), Text('Present', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), Text('Late', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), Text('Absent', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), Text('On Leave', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))]),
        TableRow(children: [const Text('Morning', style: TextStyle(fontSize: 11)), const Text('15', style: TextStyle(fontSize: 11)), const Text('12', style: TextStyle(fontSize: 11)), const Text('2', style: TextStyle(fontSize: 11)), const Text('1', style: TextStyle(fontSize: 11)), const Text('0', style: TextStyle(fontSize: 11))]),
      ]),
      const SizedBox(height: 4),
      TextButton.icon(onPressed: () {}, icon: const Icon(Icons.visibility, size: 16), label: const Text('View Full Attendance', style: TextStyle(fontSize: 11))),
    ])));
  }

  Widget _buildMachineUsage() {
    return Card(elevation: 2, child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('MACHINE USAGE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      const SizedBox(height: 8),
      Table(columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(1.5), 2: FlexColumnWidth(0.5), 3: FlexColumnWidth(1)}, children: [
        const TableRow(children: [Text('Machine Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), Text('Area Used', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), Text('Hrs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))]),
        TableRow(children: [const Text('Scrubbing Machine', style: TextStyle(fontSize: 11)), const Text('PF-1 Toilet', style: TextStyle(fontSize: 11)), const Text('2', style: TextStyle(fontSize: 11)), Row(children: [Icon(Icons.check_circle, size: 14, color: Colors.green), const Text(' Working', style: TextStyle(fontSize: 11))])]),
        TableRow(children: [const Text('Platform Sweeper', style: TextStyle(fontSize: 11)), const Text('PF-1 Surface', style: TextStyle(fontSize: 11)), const Text('1', style: TextStyle(fontSize: 11)), Row(children: [Icon(Icons.build, size: 14, color: kWarningOrange), const Text(' Maint.', style: TextStyle(fontSize: 11))])]),
      ]),
      const SizedBox(height: 4),
      OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.add, size: 16), label: const Text('Add Machine Usage', style: TextStyle(fontSize: 12))),
    ])));
  }

  Widget _buildIssues() {
    return Card(elevation: 2, child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('ISSUES ENCOUNTERED', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      const SizedBox(height: 8),
      ListTile(dense: true, leading: const Icon(Icons.error, color: kErrorRed, size: 18), title: const Text('Platform Sweeper broken - Maintenance team notified', style: TextStyle(fontSize: 11))),
      ListTile(dense: true, leading: const Icon(Icons.warning, color: kWarningOrange, size: 18), title: const Text('Water supply issue in PF-2 Toilet - Plumbing team called', style: TextStyle(fontSize: 11))),
      OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.add, size: 16), label: const Text('Add Issue', style: TextStyle(fontSize: 12))),
    ])));
  }

  Widget _buildUnresolvedWork() {
    return Card(elevation: 2, child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('UNRESOLVED WORK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      const SizedBox(height: 8),
      const ListTile(dense: true, leading: Icon(Icons.pending, color: kWarningOrange), title: Text('PF-2 Toilet cleaning pending (worker absent)', style: TextStyle(fontSize: 11))),
      const ListTile(dense: true, leading: Icon(Icons.pending, color: kWarningOrange), title: Text('Platform Sweeper repair pending', style: TextStyle(fontSize: 11))),
    ])));
  }

  Widget _buildHandoverNotes() {
    return Card(elevation: 2, child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('HANDOVER NOTES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      const SizedBox(height: 8),
      TextField(
        decoration: InputDecoration(hintText: 'Enter handover notes for next shift...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
        maxLines: 4,
        controller: TextEditingController(text: 'Handover to Evening Shift (Suresh Singh):\n- PF-2 Toilet pending cleaning\n- Machine repair request submitted\n- All other tasks completed'),
      ),
    ])));
  }

  Widget _buildActions() {
    return Row(children: [
      Expanded(child: ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.check), label: const Text('SUBMIT LOG'))),
      const SizedBox(width: 8),
      Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.save), label: const Text('SAVE DRAFT'))),
      const SizedBox(width: 8),
      Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.share), label: const Text('Share'))),
    ]);
  }
}
