import 'package:flutter/material.dart';
import 'package:crm_train/utills/app_colors.dart';

class SubmitFeedbackScreen extends StatelessWidget {
  final String stationId;
  final String stationName;
  const SubmitFeedbackScreen({super.key, required this.stationId, required this.stationName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PASSENGER FEEDBACK', style: TextStyle(color: Colors.white)), backgroundColor: kRailwayBlue, iconTheme: const IconThemeData(color: Colors.white)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Card(elevation: 2, child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('LOCATION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            DropdownButtonFormField(value: 'Bhopal Junction', decoration: const InputDecoration(labelText: 'Station', isDense: true), items: ['Bhopal Junction'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (_) {}),
            const SizedBox(height: 8),
            DropdownButtonFormField(value: 'PF-1 Toilet Block', decoration: const InputDecoration(labelText: 'Area', isDense: true), items: ['PF-1 Toilet Block', 'PF-1 Surface', 'Waiting Hall'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (_) {}),
          ]))),
          const SizedBox(height: 12),
          Card(elevation: 2, child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('VERIFICATION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Container(height: 80, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)), child: const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.qr_code_scanner, size: 40, color: Colors.grey), Text('Scan QR Code', style: TextStyle(fontSize: 11))]))),
            const SizedBox(height: 8),
            const Text('or Enter OTP:', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            Row(children: [
              Expanded(child: TextFormField(decoration: InputDecoration(hintText: 'Enter OTP', isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(6))), style: const TextStyle(fontSize: 16, letterSpacing: 8))),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: () {}, child: const Text('Verify', style: TextStyle(fontSize: 12))),
            ]),
          ]))),
          const SizedBox(height: 12),
          Card(elevation: 2, child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('RATING', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            DropdownButtonFormField(value: 'Toilet Cleanliness', decoration: const InputDecoration(labelText: 'Category', isDense: true), items: ['Toilet Cleanliness', 'Platform Cleanliness', 'Waiting Room Cleanliness', 'Garbage/Dustbin', 'Smell/Odour', 'Water Booth', 'Staff Behaviour', 'Other'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 12)))).toList(), onChanged: (_) {}),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) => IconButton(onPressed: () {}, icon: Icon(i < 4 ? Icons.star : Icons.star_border, color: Colors.amber, size: 36)))),
          ]))),
          const SizedBox(height: 12),
          TextField(decoration: InputDecoration(labelText: 'Comments', hintText: 'Share your experience...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))), maxLines: 3),
          const SizedBox(height: 12),
          Card(elevation: 2, child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
            OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.camera_alt, size: 18), label: const Text('Take Photo', style: TextStyle(fontSize: 12))),
            const SizedBox(width: 8),
            OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.photo_library, size: 18), label: const Text('Gallery', style: TextStyle(fontSize: 12))),
          ]))),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.check), label: const Text('SUBMIT FEEDBACK'))),
            const SizedBox(width: 8),
            Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL'))),
          ]),
        ]),
      ),
    );
  }
}

class FeedbackDashboardScreen extends StatelessWidget {
  final String stationId;
  final String stationName;
  const FeedbackDashboardScreen({super.key, required this.stationId, required this.stationName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FEEDBACK DASHBOARD', style: TextStyle(color: Colors.white)), backgroundColor: kRailwayBlue, iconTheme: const IconThemeData(color: Colors.white)),
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
            _fCard('Total', '156', kRailwayBlue),
            _fCard('Positive', '132', Colors.green),
            _fCard('Negative', '24', kErrorRed),
            _fCard('Avg', '4.2/5.0', Colors.amber.shade700),
            _fCard('Trend', '📈', Colors.green),
          ]),
          const SizedBox(height: 12),
          Card(elevation: 2, child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('RATING DISTRIBUTION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            ...[5, 4, 3, 2, 1].map((s) => Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Row(children: [
              Text('$s Star', style: const TextStyle(fontSize: 11)),
              const SizedBox(width: 8),
              Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: [0.45, 0.30, 0.15, 0.07, 0.03][5 - s], backgroundColor: Colors.grey.shade200, color: Colors.amber, minHeight: 12))),
              const SizedBox(width: 8),
              Text('${([45, 30, 15, 7, 3][5 - s])}%', style: const TextStyle(fontSize: 11)),
            ]))),
          ]))),
          const SizedBox(height: 12),
          Card(elevation: 2, child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('CATEGORY-WISE BREAKDOWN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Table(columnWidths: const {0: FlexColumnWidth(2.5), 1: FlexColumnWidth(1), 2: FlexColumnWidth(1.5)}, children: [
              const TableRow(children: [Text('Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), Text('Avg Rating', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))]),
              TableRow(children: [const Text('Toilet Cleanliness', style: TextStyle(fontSize: 11)), const Text('4.5/5.0', style: TextStyle(fontSize: 11)), Row(children: [Icon(Icons.check_circle, size: 14, color: Colors.green), const Text(' Good', style: TextStyle(fontSize: 11))])]),
              TableRow(children: [const Text('Platform Cleanliness', style: TextStyle(fontSize: 11)), const Text('4.2/5.0', style: TextStyle(fontSize: 11)), Row(children: [Icon(Icons.check_circle, size: 14, color: Colors.green), const Text(' Good', style: TextStyle(fontSize: 11))])]),
              TableRow(children: [const Text('Waiting Room', style: TextStyle(fontSize: 11)), const Text('3.8/5.0', style: TextStyle(fontSize: 11)), Row(children: [Icon(Icons.warning, size: 14, color: kWarningOrange), const Text(' Needs Attention', style: TextStyle(fontSize: 11))])]),
              TableRow(children: [const Text('Garbage/Dustbin', style: TextStyle(fontSize: 11)), const Text('4.0/5.0', style: TextStyle(fontSize: 11)), Row(children: [Icon(Icons.check_circle, size: 14, color: Colors.green), const Text(' Good', style: TextStyle(fontSize: 11))])]),
            ]),
          ]))),
          const SizedBox(height: 12),
          Card(elevation: 2, child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('NEGATIVE FEEDBACK FLAGGING', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kErrorRed)),
            const SizedBox(height: 8),
            ListTile(dense: true, leading: const Icon(Icons.flag, color: kErrorRed), title: const Text('Waiting Room - 2/5 - "Dirty floor"', style: TextStyle(fontSize: 12)), subtitle: const Text('15-Jan-2024', style: TextStyle(fontSize: 11))),
            ListTile(dense: true, leading: const Icon(Icons.flag, color: kWarningOrange), title: const Text('Toilet - 1/5 - "No soap, dirty basin"', style: TextStyle(fontSize: 12)), subtitle: const Text('14-Jan-2024', style: TextStyle(fontSize: 11))),
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

  Widget _fCard(String label, String value, Color color) {
    return Expanded(child: Container(margin: const EdgeInsets.all(2), padding: const EdgeInsets.symmetric(vertical: 8), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Column(children: [Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)), Text(label, style: TextStyle(fontSize: 10, color: color))])));
  }
}
