import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:crm_train/utills/app_colors.dart';

class PestControlLogScreen extends StatefulWidget {
  final String stationId;
  final String stationName;
  const PestControlLogScreen({super.key, required this.stationId, required this.stationName});

  @override
  State<StatefulWidget> createState() => _PestControlLogScreenState();
}

class _PestControlLogScreenState extends State<PestControlLogScreen> {
  bool _showAddForm = false;
  String _selectedDate = DateFormat('dd-MM-yyyy').format(DateTime.now());
  String _nextDueDate = DateFormat('dd-MM-yyyy').format(DateTime.now().add(const Duration(days: 30)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PEST CONTROL LOG', style: TextStyle(color: Colors.white)),
        backgroundColor: kRailwayBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [TextButton.icon(onPressed: () => setState(() => _showAddForm = !_showAddForm), icon: const Icon(Icons.add, color: Colors.white), label: const Text('Add Treatment', style: TextStyle(color: Colors.white)))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: DropdownButtonFormField(value: 'Bhopal Junction', decoration: const InputDecoration(labelText: 'Station', isDense: true), items: ['Bhopal Junction'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (_) {})),
            const SizedBox(width: 8),
            Expanded(child: DropdownButtonFormField(value: 'All Areas', decoration: const InputDecoration(labelText: 'Area', isDense: true), items: ['All Areas', 'PF-1', 'PF-2', 'Waiting Hall'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (_) {})),
            const SizedBox(width: 8),
            Expanded(child: DropdownButtonFormField(value: 'Jan 2024', decoration: const InputDecoration(labelText: 'Period', isDense: true), items: ['Jan 2024'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (_) {})),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            _pStat('Total', '12', kRailwayBlue),
            _pStat('Rodent', '5', Colors.brown),
            _pStat('Pest', '4', kWarningOrange),
            _pStat('Termite', '3', Colors.teal),
            _pStat('Next Due', '5', kErrorRed),
          ]),
          const SizedBox(height: 12),
          Card(elevation: 2, child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('TREATMENT LOG', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Table(columnWidths: const {0: FlexColumnWidth(1), 1: FlexColumnWidth(1.2), 2: FlexColumnWidth(1), 3: FlexColumnWidth(1.2), 4: FlexColumnWidth(1.2)}, children: [
              const TableRow(children: [Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), Text('Area', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), Text('Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), Text('Agency', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))]),
              _pRow('15-Jan', 'PF-1', 'Rodent', 'ABC Pest', '✅ Completed', Colors.green),
              _pRow('14-Jan', 'Waiting', 'Pest', 'XYZ Pest', '✅ Completed', Colors.green),
              _pRow('12-Jan', 'PF-2', 'Termite', 'ABC Pest', '🔄 In Progress', kWarningOrange),
            ]),
          ]))),
          if (_showAddForm) ...[
            const SizedBox(height: 12),
            Card(elevation: 2, child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('ADD TREATMENT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: InkWell(onTap: () async {
                  final picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2024), lastDate: DateTime.now().add(const Duration(days: 365)));
                  if (picked != null) setState(() => _selectedDate = DateFormat('dd-MM-yyyy').format(picked));
                }, child: InputDecorator(decoration: const InputDecoration(labelText: 'Date', isDense: true, suffixIcon: Icon(Icons.calendar_today, size: 18)), child: Text(_selectedDate)))),
                const SizedBox(width: 8),
                Expanded(child: DropdownButtonFormField(value: 'PF-1 Toilet Block', decoration: const InputDecoration(labelText: 'Area', isDense: true), items: ['PF-1 Toilet Block', 'PF-1 Surface', 'Waiting Hall'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (_) {})),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: DropdownButtonFormField(value: 'Rodent Control', decoration: const InputDecoration(labelText: 'Type', isDense: true), items: ['Rodent Control', 'Pest Control', 'Termite Control', 'Disinfection'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (_) {})),
                const SizedBox(width: 8),
                Expanded(child: DropdownButtonFormField(value: 'Rodent Bait - 10 kg', decoration: const InputDecoration(labelText: 'Chemical', isDense: true), items: ['Rodent Bait - 10 kg', 'Insecticide Spray', 'Termite Solution'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (_) {})),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: TextFormField(decoration: const InputDecoration(labelText: 'Agency', isDense: true), initialValue: 'ABC Pest Control')),
                const SizedBox(width: 8),
                Expanded(child: InkWell(onTap: () async {
                  final picked = await showDatePicker(context: context, initialDate: DateTime.now().add(const Duration(days: 30)), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                  if (picked != null) setState(() => _nextDueDate = DateFormat('dd-MM-yyyy').format(picked));
                }, child: InputDecorator(decoration: const InputDecoration(labelText: 'Next Due Date', isDense: true, suffixIcon: Icon(Icons.calendar_today, size: 18)), child: Text(_nextDueDate)))),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.camera_alt, size: 18), label: const Text('Add Photos', style: TextStyle(fontSize: 12))),
                const SizedBox(width: 8),
                OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.upload_file, size: 18), label: const Text('Upload Document', style: TextStyle(fontSize: 12))),
              ]),
              const SizedBox(height: 8),
              TextField(decoration: InputDecoration(labelText: 'Remarks', hintText: 'Enter treatment remarks...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), isDense: true), maxLines: 2, controller: TextEditingController(text: 'Rodent activity observed near dustbin zone. Treated.')),
            ]))),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.check), label: const Text('SAVE TREATMENT'))),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.send), label: const Text('Send Report'))),
            ]),
          ],
        ]),
      ),
    );
  }

  Widget _pStat(String label, String value, Color color) {
    return Expanded(child: Container(margin: const EdgeInsets.all(2), padding: const EdgeInsets.symmetric(vertical: 8), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Column(children: [Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)), Text(label, style: TextStyle(fontSize: 10, color: color))])));
  }

  TableRow _pRow(String d, String a, String t, String ag, String s, Color c) {
    return TableRow(children: [Text(d, style: const TextStyle(fontSize: 11)), Text(a, style: const TextStyle(fontSize: 11)), Text(t, style: const TextStyle(fontSize: 11)), Text(ag, style: const TextStyle(fontSize: 11)), Text(s, style: TextStyle(fontSize: 11, color: c, fontWeight: FontWeight.w600))]);
  }
}
