import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:crm_train/utills/app_colors.dart';

class CreateInspectionScreen extends StatefulWidget {
  final String stationId;
  final String stationName;
  const CreateInspectionScreen({super.key, required this.stationId, required this.stationName});

  @override
  State<StatefulWidget> createState() => _CreateInspectionScreenState();
}

class _CreateInspectionScreenState extends State<CreateInspectionScreen> {
  String _selectedDate = DateFormat('dd-MM-yyyy').format(DateTime.now());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CREATE INSPECTION', style: TextStyle(color: Colors.white)), backgroundColor: kRailwayBlue, iconTheme: const IconThemeData(color: Colors.white)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildDetails(),
          const SizedBox(height: 12),
          _buildChecklist(),
          const SizedBox(height: 12),
          _buildScoreSummary(),
          const SizedBox(height: 12),
          _buildDeficiencies(),
          const SizedBox(height: 12),
          _buildPhotoEvidence(),
          const SizedBox(height: 12),
          _buildRemarks(),
          const SizedBox(height: 12),
          _buildActions(),
        ]),
      ),
    );
  }

  Widget _buildDetails() {
    return Card(elevation: 2, child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('INSPECTION DETAILS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      const SizedBox(height: 8),
      DropdownButtonFormField(value: 'Daily Inspection', decoration: const InputDecoration(labelText: 'Type', isDense: true), items: ['Daily Inspection', 'Surprise Inspection', 'Ad Hoc Visit', 'Complaint-Based', 'Monthly Review'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 12)))).toList(), onChanged: (_) {}),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: DropdownButtonFormField(value: 'Bhopal Junction', decoration: const InputDecoration(labelText: 'Station', isDense: true), items: ['Bhopal Junction'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (_) {})),
        const SizedBox(width: 8),
        Expanded(child: DropdownButtonFormField(value: 'PF-1', decoration: const InputDecoration(labelText: 'Platform', isDense: true), items: ['PF-1', 'PF-2'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (_) {})),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: DropdownButtonFormField(value: 'Toilet Block', decoration: const InputDecoration(labelText: 'Area', isDense: true), items: ['Toilet Block', 'Surface', 'Waiting Hall'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (_) {})),
        const SizedBox(width: 8),
        Expanded(child: InkWell(onTap: () async {
          final picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2024), lastDate: DateTime.now());
          if (picked != null) setState(() => _selectedDate = DateFormat('dd-MM-yyyy').format(picked));
        }, child: InputDecorator(decoration: const InputDecoration(labelText: 'Date', isDense: true, suffixIcon: Icon(Icons.calendar_today, size: 18)), child: Text(_selectedDate)))),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: TextFormField(decoration: const InputDecoration(labelText: 'Time', hintText: '10:00 AM', isDense: true), initialValue: '10:00 AM')),
        const SizedBox(width: 8),
        Expanded(child: TextFormField(decoration: const InputDecoration(labelText: 'Inspector', isDense: true), initialValue: 'Rajesh Sharma')),
      ]),
    ])));
  }

  Widget _buildChecklist() {
    final items = <Map<String, dynamic>>[
      {'label': 'Floor Cleanliness', 'score': '4/5', 'status': 'Good', 'color': Colors.green},
      {'label': 'Toilet Hygiene', 'score': '3/5', 'status': 'Needs Attention', 'color': kWarningOrange},
      {'label': 'Wash Basin Cleanliness', 'score': '4/5', 'status': 'Good', 'color': Colors.green},
      {'label': 'Mirror Cleanliness', 'score': '5/5', 'status': 'Excellent', 'color': Colors.green},
      {'label': 'Consumables Availability', 'score': '2/5', 'status': 'Poor', 'color': kErrorRed},
      {'label': 'Odour Control', 'score': '3/5', 'status': 'Needs Attention', 'color': kWarningOrange},
    ];
    return Card(elevation: 2, child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('CHECKLIST', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      const SizedBox(height: 8),
      ...items.map((item) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(children: [
          const Icon(Icons.check_box, size: 18, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(child: Text(item['label'] as String, style: const TextStyle(fontSize: 12))),
          Text('Score: ${item['score']}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: item['color'] as Color)),
          const SizedBox(width: 8),
          Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: (item['color'] as Color).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)), child: Text(item['status'] as String, style: TextStyle(fontSize: 10, color: item['color'] as Color))),
        ]),
      )),
    ])));
  }

  Widget _buildScoreSummary() {
    return Card(elevation: 2, child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: kWarningOrange.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)), child: const Column(children: [Text('21/30', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: kWarningOrange)), Text('(70%)', style: TextStyle(fontSize: 11))])),
      const SizedBox(width: 16),
      const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Grade: C', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kWarningOrange)),
        Text('Status: ⚠️ Needs Improvement', style: TextStyle(fontSize: 12)),
      ]),
    ])));
  }

  Widget _buildDeficiencies() {
    return Card(elevation: 2, child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('DEFICIENCIES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      const SizedBox(height: 8),
      ListTile(dense: true, leading: const Icon(Icons.error_outline, color: kErrorRed), title: const Text('Soap dispensers empty', style: TextStyle(fontSize: 12)), subtitle: const Text('Action: Refill immediately  |  Status: ⏳ Pending', style: TextStyle(fontSize: 10))),
      ListTile(dense: true, leading: const Icon(Icons.error_outline, color: kWarningOrange), title: const Text('Water stains on basin', style: TextStyle(fontSize: 12)), subtitle: const Text('Action: Clean thoroughly  |  Status: ⏳ Pending', style: TextStyle(fontSize: 10))),
    ])));
  }

  Widget _buildPhotoEvidence() {
    return Card(elevation: 2, child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
      OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.camera_alt), label: const Text('Add Photos', style: TextStyle(fontSize: 12))),
      const SizedBox(width: 8),
      const Chip(label: Text('2 photos attached', style: TextStyle(fontSize: 11))),
    ])));
  }

  Widget _buildRemarks() {
    return Card(elevation: 2, child: Padding(padding: const EdgeInsets.all(12), child: TextField(
      decoration: InputDecoration(labelText: 'Inspector Remarks', hintText: 'Enter inspection remarks...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
      maxLines: 3,
      controller: TextEditingController(text: 'Overall cleanliness acceptable but consumables need attention. Re-inspection required in 2 days.'),
    )));
  }

  Widget _buildActions() {
    return Row(children: [
      Expanded(child: ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.check), label: const Text('SUBMIT INSPECTION'))),
      const SizedBox(width: 8),
      Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.save), label: const Text('SAVE DRAFT'))),
    ]);
  }
}

class InspectionDashboardScreen extends StatelessWidget {
  final String stationId;
  final String stationName;
  const InspectionDashboardScreen({super.key, required this.stationId, required this.stationName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('INSPECTION DASHBOARD', style: TextStyle(color: Colors.white)), backgroundColor: kRailwayBlue, iconTheme: const IconThemeData(color: Colors.white)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: DropdownButtonFormField(value: 'Bhopal Junction', decoration: const InputDecoration(labelText: 'Station', isDense: true), items: ['Bhopal Junction'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (_) {})),
            const SizedBox(width: 8),
            Expanded(child: DropdownButtonFormField(value: 'Jan 2024', decoration: const InputDecoration(labelText: 'Period', isDense: true), items: ['Jan 2024'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (_) {})),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            _statCard('Total', '45', kRailwayBlue),
            _statCard('Daily', '25', Colors.green),
            _statCard('Surprise', '8', kWarningOrange),
            _statCard('Ad Hoc', '6', Colors.purple),
            _statCard('Monthly', '6', Colors.teal),
          ]),
          const SizedBox(height: 12),
          Card(elevation: 2, child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('SCORE TREND', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            SizedBox(height: 100, child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              _trendBar('W1', 0.95, Colors.green),
              _trendBar('W2', 0.88, Colors.green),
              _trendBar('W3', 0.85, kRailwayBlue),
              _trendBar('W4', 0.82, kWarningOrange),
            ])),
          ]))),
          const SizedBox(height: 12),
          Card(elevation: 2, child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('RECENT INSPECTIONS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Table(columnWidths: const {0: FlexColumnWidth(1), 1: FlexColumnWidth(1.5), 2: FlexColumnWidth(0.8), 3: FlexColumnWidth(0.5), 4: FlexColumnWidth(1.5)}, children: [
              const TableRow(children: [Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), Text('Area', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), Text('Score', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), Text('Grade', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))]),
              TableRow(children: [const Text('15-Jan', style: TextStyle(fontSize: 11)), const Text('PF-1 Toilet', style: TextStyle(fontSize: 11)), const Text('70%', style: TextStyle(fontSize: 11)), const Text('C', style: TextStyle(fontSize: 11)), Row(children: [Icon(Icons.warning, size: 14, color: kWarningOrange), const Text(' Needs Imp.', style: TextStyle(fontSize: 11))])]),
              TableRow(children: [const Text('14-Jan', style: TextStyle(fontSize: 11)), const Text('PF-1 Surface', style: TextStyle(fontSize: 11)), const Text('85%', style: TextStyle(fontSize: 11)), const Text('B', style: TextStyle(fontSize: 11)), Row(children: [Icon(Icons.check_circle, size: 14, color: Colors.green), const Text(' Good', style: TextStyle(fontSize: 11))])]),
              TableRow(children: [const Text('13-Jan', style: TextStyle(fontSize: 11)), const Text('Waiting Hall', style: TextStyle(fontSize: 11)), const Text('65%', style: TextStyle(fontSize: 11)), const Text('C', style: TextStyle(fontSize: 11)), Row(children: [Icon(Icons.warning, size: 14, color: kWarningOrange), const Text(' Needs Imp.', style: TextStyle(fontSize: 11))])]),
            ]),
          ]))),
          const SizedBox(height: 12),
          Card(elevation: 2, child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('DEFICIENCIES TRACKING', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              const Text('Total: 12   Open: 5   Closed: 7', style: TextStyle(fontSize: 12)),
              const Text('Avg Closure: 2.5 days   SLA: 90%', style: TextStyle(fontSize: 12)),
            ])),
            Container(width: 60, height: 60, decoration: BoxDecoration(color: kWarningOrange.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(30)), child: const Center(child: Text('12', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: kWarningOrange)))),
          ]))),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.download), label: const Text('Export Report'))),
            const SizedBox(width: 8),
            Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.refresh), label: const Text('Refresh'))),
          ]),
        ]),
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(child: Container(margin: const EdgeInsets.all(2), padding: const EdgeInsets.symmetric(vertical: 8), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Column(children: [Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)), Text(label, style: TextStyle(fontSize: 10, color: color))])));
  }

  Widget _trendBar(String label, double pct, Color color) {
    return Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
      Text('${(pct * 100).toInt()}%', style: const TextStyle(fontSize: 9)),
      Container(height: 80 * pct, width: 24, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
      Text(label, style: const TextStyle(fontSize: 9)),
    ]));
  }
}
