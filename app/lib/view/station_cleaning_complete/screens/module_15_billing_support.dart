import 'package:flutter/material.dart';
import 'package:crm_train/utills/app_colors.dart';

class BillingSupportDashboard extends StatelessWidget {
  final String stationId;
  final String stationName;
  final String? contractId;
  const BillingSupportDashboard({super.key, required this.stationId, required this.stationName, this.contractId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BILLING SUPPORT', style: TextStyle(color: Colors.white)), backgroundColor: kRailwayBlue, iconTheme: const IconThemeData(color: Colors.white)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Card(elevation: 2, child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Contract: CON-2024-001  |  Period: January 2024', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const Text('Contractor: ABC Facility Services  |  Station: Bhopal Junction', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ]))),
          const SizedBox(height: 12),
          Row(children: [
            _bStat('Readiness', '85%', Colors.green),
            _bStat('Complete', '8/12', kRailwayBlue),
            _bStat('Pending', '2/12', kWarningOrange),
            _bStat('Missing', '2/12', kErrorRed),
            _bStat('Score', '85%', Colors.teal),
          ]),
          const SizedBox(height: 12),
          Card(elevation: 2, child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('COMPLIANCE CHECKLIST', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            ...[
              {'label': 'Invoice Generated', 'status': '✅', 'action': 'View'},
              {'label': 'GST Invoice', 'status': '✅', 'action': 'View'},
              {'label': 'Wage Sheet', 'status': '✅', 'action': 'View'},
              {'label': 'Bank Statement', 'status': '✅', 'action': 'View'},
              {'label': 'Police Verification', 'status': '✅', 'action': 'View'},
              {'label': 'Medical Certificate', 'status': '✅', 'action': 'View'},
              {'label': 'Biometric Attendance Sheet', 'status': '✅', 'action': 'View'},
              {'label': 'Inspection Reports', 'status': '⚠️', 'action': 'Upload Pending'},
              {'label': 'Scorecard Reports', 'status': '⚠️', 'action': 'Upload Pending'},
            ].map((item) => ListTile(
              dense: true,
              leading: Icon(item['status'] == '✅' ? Icons.check_circle : Icons.warning, color: item['status'] == '✅' ? Colors.green : kWarningOrange, size: 20),
              title: Text(item['label']!, style: const TextStyle(fontSize: 12)),
              trailing: Text(item['action']!, style: TextStyle(fontSize: 11, color: item['action'] == 'View' ? kRailwayBlue : kWarningOrange, fontWeight: FontWeight.w600)),
            )),
          ]))),
          const SizedBox(height: 12),
          Card(elevation: 2, child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('PERFORMANCE SUMMARY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Table(columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(1), 2: FlexColumnWidth(1)}, children: [
              const TableRow(children: [Text('Metric', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), Text('Value', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))]),
              _perfRow('Avg Attendance', '89%', Colors.green),
              _perfRow('Task Completion', '85%', Colors.green),
              _perfRow('Cleanliness Score', '82%', Colors.green),
              _perfRow('Inspection Score', '85%', Colors.green),
              _perfRow('Feedback Score', '4.2/5.0', Colors.green),
              _perfRow('Complaint Resolution', '92%', Colors.green),
            ]),
          ]))),
          const SizedBox(height: 12),
          Card(elevation: 2, child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('PENALTY / DEDUCTION SUMMARY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: kRailwayBlue.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)), child: Column(children: [
              _moneyRow('Contract Value', '₹10,00,000'),
              _moneyRow('Performance', '82%'),
              _moneyRow('Grade', 'B'),
              _moneyRow('Deduction', '5%'),
              _moneyRow('Amount', '₹50,000'),
              const Divider(),
              _moneyRow('Final Payable', '₹9,50,000'),
            ])),
          ]))),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.assessment), label: const Text('Generate Billing Report'))),
            const SizedBox(width: 8),
            Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.download), label: const Text('Download All'))),
            const SizedBox(width: 8),
            Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.email), label: const Text('Send to Admin'))),
          ]),
        ]),
      ),
    );
  }

  Widget _bStat(String label, String value, Color color) {
    return Expanded(child: Container(margin: const EdgeInsets.all(2), padding: const EdgeInsets.symmetric(vertical: 8), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Column(children: [Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)), Text(label, style: TextStyle(fontSize: 10, color: color))])));
  }

  TableRow _perfRow(String metric, String value, Color color) {
    return TableRow(children: [Text(metric, style: const TextStyle(fontSize: 11)), Text(value, style: const TextStyle(fontSize: 11)), Row(children: [Icon(Icons.check_circle, size: 14, color: color), Text(' Good', style: TextStyle(fontSize: 11, color: color))])]);
  }

  Widget _moneyRow(String label, String value) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(fontSize: 12)), Text(value, style: TextStyle(fontSize: 12, fontWeight: label == 'Final Payable' ? FontWeight.bold : FontWeight.normal, color: label == 'Final Payable' ? kRailwayBlue : null))]));
  }
}
