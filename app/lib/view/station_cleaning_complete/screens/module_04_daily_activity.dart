import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:crm_train/utills/app_colors.dart';

class ActivityRecordingScreen extends StatefulWidget {
  final String stationId;
  final String stationName;
  const ActivityRecordingScreen({super.key, required this.stationId, required this.stationName});

  @override
  State<StatefulWidget> createState() => _ActivityRecordingScreenState();
}

class _ActivityRecordingScreenState extends State<ActivityRecordingScreen> {
  String _selectedDate = DateFormat('dd-MM-yyyy').format(DateTime.now());
  String _selectedStatus = 'Completed';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DAILY ACTIVITY RECORDING', style: TextStyle(color: Colors.white)), backgroundColor: kRailwayBlue, iconTheme: const IconThemeData(color: Colors.white)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilters(),
            const SizedBox(height: 12),
            _buildAreaSelection(),
            const SizedBox(height: 12),
            _buildActivityDetails(),
            const SizedBox(height: 12),
            _buildPhotoEvidence(),
            const SizedBox(height: 12),
            _buildCompletionStatus(),
            const SizedBox(height: 12),
            _buildRemarks(),
            const SizedBox(height: 12),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Card(
      elevation: 2, child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [
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
          Expanded(child: DropdownButtonFormField(value: 'PF-1', decoration: const InputDecoration(labelText: 'Platform', isDense: true), items: ['PF-1', 'PF-2'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (_) {})),
          const SizedBox(width: 8),
          Expanded(child: DropdownButtonFormField(value: 'Morning', decoration: const InputDecoration(labelText: 'Shift', isDense: true), items: ['Morning', 'Afternoon', 'Night'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (_) {})),
        ]),
      ])),
    );
  }

  Widget _buildAreaSelection() {
    return Card(
      elevation: 2, child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('SELECT AREA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        CheckboxListTile(title: const Text('PF-1 Toilet Block', style: TextStyle(fontSize: 13)), subtitle: const Text('Frequency: Every 2 Hrs  Priority: High', style: TextStyle(fontSize: 10)), value: true, onChanged: (_) {}, dense: true, controlAffinity: ListTileControlAffinity.leading),
        CheckboxListTile(title: const Text('PF-1 Surface', style: TextStyle(fontSize: 13)), subtitle: const Text('Frequency: Daily  Priority: Medium', style: TextStyle(fontSize: 10)), value: true, onChanged: (_) {}, dense: true, controlAffinity: ListTileControlAffinity.leading),
        CheckboxListTile(title: const Text('PF-1 Water Booth', style: TextStyle(fontSize: 13)), subtitle: const Text('Frequency: 4 Hrs  Priority: Low', style: TextStyle(fontSize: 10)), value: false, onChanged: (_) {}, dense: true, controlAffinity: ListTileControlAffinity.leading),
      ])),
    );
  }

  Widget _buildActivityDetails() {
    return Card(
      elevation: 2, child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('ACTIVITY DETAILS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        DropdownButtonFormField(value: 'Cleaning', decoration: const InputDecoration(labelText: 'Activity', isDense: true), items: ['Cleaning', 'Sweeping', 'Mopping', 'Disinfection'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (_) {}),
        const SizedBox(height: 8),
        TextFormField(decoration: const InputDecoration(labelText: 'Time', hintText: '08:00 AM', isDense: true), initialValue: '08:00 AM'),
        const SizedBox(height: 8),
        DropdownButtonFormField(value: 'Amit Kumar', decoration: const InputDecoration(labelText: 'Worker', isDense: true), items: ['Amit Kumar', 'Rohit Sharma', 'Suresh Patel'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (_) {}),
      ])),
    );
  }

  Widget _buildPhotoEvidence() {
    return Card(
      elevation: 2, child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('PHOTO EVIDENCE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        Row(children: [
          OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.camera_alt, size: 18), label: const Text('Before Photo', style: TextStyle(fontSize: 12))),
          const SizedBox(width: 8),
          OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.photo_library, size: 18), label: const Text('Gallery', style: TextStyle(fontSize: 12))),
        ]),
        const SizedBox(height: 4),
        Row(children: [
          OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.camera_alt, size: 18), label: const Text('After Photo', style: TextStyle(fontSize: 12))),
          const SizedBox(width: 8),
          OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.photo_library, size: 18), label: const Text('Gallery', style: TextStyle(fontSize: 12))),
        ]),
      ])),
    );
  }

  Widget _buildCompletionStatus() {
    final statuses = ['Completed', 'In Progress', 'Partially Completed', 'Rejected', 'Resubmitted', 'Pending'];
    return Card(
      elevation: 2, child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('COMPLETION STATUS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 6, children: statuses.map((s) => ChoiceChip(
          label: Text(s, style: TextStyle(fontSize: 11, color: _statusChipColor(s))),
          selected: _selectedStatus == s,
          onSelected: (v) => setState(() => _selectedStatus = s),
          selectedColor: _statusChipColor(s).withValues(alpha: 0.2),
        )).toList()),
      ])),
    );
  }

  Color _statusChipColor(String s) {
    switch (s) {
      case 'Completed': return Colors.green;
      case 'In Progress': return kRailwayBlue;
      case 'Partially Completed': return kWarningOrange;
      case 'Rejected': return kErrorRed;
      case 'Resubmitted': return Colors.purple;
      case 'Pending': return Colors.grey;
      default: return Colors.grey;
    }
  }

  Widget _buildRemarks() {
    return Card(
      elevation: 2, child: Padding(padding: const EdgeInsets.all(12), child: TextField(
        decoration: InputDecoration(labelText: 'Remarks', hintText: 'Enter activity remarks...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
        maxLines: 3,
      )),
    );
  }

  Widget _buildActions() {
    return Row(children: [
      Expanded(child: ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.check), label: const Text('SUBMIT ACTIVITY'))),
      const SizedBox(width: 8),
      Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.save), label: const Text('SAVE DRAFT'))),
    ]);
  }
}
