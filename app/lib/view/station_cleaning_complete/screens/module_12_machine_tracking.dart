import 'package:flutter/material.dart';
import 'package:crm_train/utills/app_colors.dart';

class MachineTrackingScreen extends StatefulWidget {
  final String stationId;
  final String stationName;
  const MachineTrackingScreen({super.key, required this.stationId, required this.stationName});

  @override
  State<StatefulWidget> createState() => _MachineTrackingScreenState();
}

class _MachineTrackingScreenState extends State<MachineTrackingScreen> {
  bool _showDowntimeForm = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MACHINE TRACKING', style: TextStyle(color: Colors.white)), backgroundColor: kRailwayBlue, iconTheme: const IconThemeData(color: Colors.white)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: DropdownButtonFormField(value: 'Bhopal Junction', decoration: const InputDecoration(labelText: 'Station', isDense: true), items: ['Bhopal Junction'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (_) {})),
            const SizedBox(width: 8),
            Expanded(child: DropdownButtonFormField(value: 'All', decoration: const InputDecoration(labelText: 'Status', isDense: true), items: ['All', 'Working', 'Down', 'Maintenance'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (_) {})),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            _mStat('Total', '5', kRailwayBlue),
            _mStat('Working', '3', Colors.green),
            _mStat('Down', '1', kErrorRed),
            _mStat('Maint.', '1', kWarningOrange),
            _mStat('Downtime', '20 hrs', kErrorRed),
          ]),
          const SizedBox(height: 12),
          Card(elevation: 2, child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('MACHINE LIST', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Table(columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(1), 2: FlexColumnWidth(1), 3: FlexColumnWidth(1.5)}, children: [
              const TableRow(children: [Text('Machine Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), Text('Downtime', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), Text('Area Used', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))]),
              _machineRow('Scrubbing Machine', '✅ Working', '0 hrs', 'PF-1 Toilet', Colors.green),
              _machineRow('Platform Sweeper', '⚠️ Maint.', '8 hrs', 'PF-1 Surface', kWarningOrange),
              _machineRow('Toilet Cleaner', '🔴 Broken', '12 hrs', 'PF-2 Toilet', kErrorRed),
              _machineRow('Floor Polisher', '✅ Working', '0 hrs', 'Waiting Hall', Colors.green),
            ]),
          ]))),
          const SizedBox(height: 12),
          Card(elevation: 2, child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('LOG DOWNTIME', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            DropdownButtonFormField(value: 'Platform Sweeper', decoration: const InputDecoration(labelText: 'Machine', isDense: true), items: ['Platform Sweeper', 'Scrubbing Machine', 'Toilet Cleaner'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (_) {}),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: TextFormField(decoration: const InputDecoration(labelText: 'Start Time', isDense: true), initialValue: '15-01-2024 09:00 AM')),
              const SizedBox(width: 8),
              Expanded(child: TextFormField(decoration: const InputDecoration(labelText: 'End Time', isDense: true), initialValue: '15-01-2024 05:00 PM')),
            ]),
            const SizedBox(height: 8),
            TextField(decoration: InputDecoration(labelText: 'Reason', hintText: 'Enter downtime reason...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), isDense: true), maxLines: 2, controller: TextEditingController(text: 'Motor failure - repair in progress')),
            const SizedBox(height: 8),
            OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.camera_alt, size: 18), label: const Text('Add Photo Evidence', style: TextStyle(fontSize: 12))),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.check), label: const Text('LOG DOWNTIME'))),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.assessment), label: const Text('Downtime Report'))),
            ]),
          ]))),
          const SizedBox(height: 12),
          Card(elevation: 2, child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('REPAIR / REPLACEMENT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: kWarningOrange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: const Text('Remarks: Motor needs replacement. Estimated cost: ₹15,000', style: TextStyle(fontSize: 12))),
            const SizedBox(height: 8),
            Row(children: [
              OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.replay, size: 18), label: const Text('Request Replacement', style: TextStyle(fontSize: 12))),
              const SizedBox(width: 8),
              OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.build, size: 18), label: const Text('Schedule Repair', style: TextStyle(fontSize: 12))),
            ]),
          ]))),
        ]),
      ),
    );
  }

  Widget _mStat(String label, String value, Color color) {
    return Expanded(child: Container(margin: const EdgeInsets.all(2), padding: const EdgeInsets.symmetric(vertical: 8), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Column(children: [Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)), Text(label, style: TextStyle(fontSize: 10, color: color))])));
  }

  TableRow _machineRow(String name, String status, String downtime, String area, Color color) {
    return TableRow(children: [Text(name, style: const TextStyle(fontSize: 11)), Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)), Text(downtime, style: const TextStyle(fontSize: 11)), Text(area, style: const TextStyle(fontSize: 11))]);
  }
}
