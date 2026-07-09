import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:crm_train/utills/app_colors.dart';

class GarbageDisposalLogScreen extends StatefulWidget {
  final String stationId;
  final String stationName;
  const GarbageDisposalLogScreen({super.key, required this.stationId, required this.stationName});

  @override
  State<StatefulWidget> createState() => _GarbageDisposalLogScreenState();
}

class _GarbageDisposalLogScreenState extends State<GarbageDisposalLogScreen> {
  String _selectedDate = DateFormat('dd-MM-yyyy').format(DateTime.now());
  bool _showAddForm = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GARBAGE DISPOSAL LOG', style: TextStyle(color: Colors.white)),
        backgroundColor: kRailwayBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [TextButton.icon(onPressed: () => setState(() => _showAddForm = !_showAddForm), icon: const Icon(Icons.add, color: Colors.white), label: const Text('Add Record', style: TextStyle(color: Colors.white)))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: DropdownButtonFormField(value: 'Bhopal Junction', decoration: const InputDecoration(labelText: 'Station', isDense: true), items: ['Bhopal Junction'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (_) {})),
            const SizedBox(width: 8),
            Expanded(child: InkWell(onTap: () async {
              final picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2024), lastDate: DateTime.now());
              if (picked != null) setState(() => _selectedDate = DateFormat('dd-MM-yyyy').format(picked));
            }, child: InputDecorator(decoration: const InputDecoration(labelText: 'Date', isDense: true, suffixIcon: Icon(Icons.calendar_today, size: 18)), child: Text(_selectedDate)))),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            _gStat('Total', '12', kRailwayBlue),
            _gStat('Wet', '800 kg', Colors.brown),
            _gStat('Dry', '400 kg', Colors.grey),
            _gStat('Recycled', '200 kg', Colors.green),
            _gStat('Disposed', '1000 kg', Colors.teal),
          ]),
          const SizedBox(height: 12),
          Card(elevation: 2, child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('COLLECTION LOG', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Table(columnWidths: const {0: FlexColumnWidth(0.8), 1: FlexColumnWidth(1.2), 2: FlexColumnWidth(0.8), 3: FlexColumnWidth(0.6), 4: FlexColumnWidth(1), 5: FlexColumnWidth(0.8)}, children: [
              const TableRow(children: [Text('Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), Text('Area', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), Text('Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), Text('Qty', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), Text('Segregation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))]),
              _gRow('08:00', 'PF-1 Toilet', 'Wet', '50 kg', '✅ Done', '✅ Done', Colors.green),
              _gRow('09:00', 'PF-1 Surface', 'Dry', '30 kg', '✅ Done', '✅ Done', Colors.green),
              _gRow('10:00', 'PF-2 Toilet', 'Wet', '40 kg', '⚠️ Mixed', '⚠️', kWarningOrange),
            ]),
          ]))),
          if (_showAddForm) ...[
            const SizedBox(height: 12),
            Card(elevation: 2, child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('ADD RECORD', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              DropdownButtonFormField(value: 'PF-1 Toilet Block', decoration: const InputDecoration(labelText: 'Area', isDense: true), items: ['PF-1 Toilet Block', 'PF-1 Surface', 'PF-2 Toilet'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (_) {}),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: DropdownButtonFormField(value: 'Wet Waste', decoration: const InputDecoration(labelText: 'Waste Type', isDense: true), items: ['Wet Waste', 'Dry Waste', 'Hazardous'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (_) {})),
                const SizedBox(width: 8),
                Expanded(child: TextFormField(decoration: const InputDecoration(labelText: 'Quantity (kg)', isDense: true), initialValue: '50')),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: TextFormField(decoration: const InputDecoration(labelText: 'Disposal Time', isDense: true), initialValue: '12:00 PM')),
                const SizedBox(width: 8),
                Expanded(child: TextFormField(decoration: const InputDecoration(labelText: 'Disposal Point', isDense: true), initialValue: 'Garbage Collection Point PF-1')),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 18),
                const SizedBox(width: 8),
                const Text('Segregated', style: TextStyle(fontSize: 12)),
                const Spacer(),
                Switch(value: true, onChanged: (_) {}),
              ]),
              const SizedBox(height: 8),
              OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.camera_alt, size: 18), label: const Text('Add Photo Evidence', style: TextStyle(fontSize: 12))),
              const SizedBox(height: 8),
              TextField(decoration: InputDecoration(labelText: 'Remarks', hintText: 'Enter disposal remarks...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), isDense: true), maxLines: 2, controller: TextEditingController(text: 'Waste collected and disposed properly.')),
            ]))),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.check), label: const Text('RECORD DISPOSAL'))),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.assessment), label: const Text('Garbage Report'))),
            ]),
          ],
        ]),
      ),
    );
  }

  Widget _gStat(String label, String value, Color color) {
    return Expanded(child: Container(margin: const EdgeInsets.all(2), padding: const EdgeInsets.symmetric(vertical: 8), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Column(children: [Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)), Text(label, style: TextStyle(fontSize: 10, color: color))])));
  }

  TableRow _gRow(String t, String a, String type, String qty, String seg, String status, Color c) {
    return TableRow(children: [Text(t, style: const TextStyle(fontSize: 11)), Text(a, style: const TextStyle(fontSize: 11)), Text(type, style: const TextStyle(fontSize: 11)), Text(qty, style: const TextStyle(fontSize: 11)), Text(seg, style: TextStyle(fontSize: 11, color: seg == '✅ Done' ? Colors.green : kWarningOrange)), Text(status, style: TextStyle(fontSize: 11, color: c))]);
  }
}
