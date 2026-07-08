import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crm_train/model/billing_models.dart';
import 'package:crm_train/services/api_services.dart';
import 'package:crm_train/utills/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import 'package:crm_train/services/pdf_report_service.dart';

class BillingReportScreen extends StatefulWidget {
  const BillingReportScreen({super.key});

  @override
  State<BillingReportScreen> createState() => _BillingReportScreenState();
}

class _BillingReportScreenState extends State<BillingReportScreen> {
  List<BillingReport> reports = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() { isLoading = true; });
    try {
      final result = await ApiService.getBillingReports();
      if (mounted) setState(() { reports = result; isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Billing Reports', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: kRailwayBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadReports, tooltip: 'Refresh'),
          IconButton(icon: const Icon(Icons.filter_list), onPressed: () => _showFilterDialog(context)),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Generate & Export Reports', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildReportCard(context, Icons.description, 'Monthly Billing Report', 'Complete monthly billing summary with deductions', 'PDF • Excel • CSV', 'Monthly', () => _generateMonthlyReport()),
                _buildReportCard(context, Icons.assignment, 'Contract Billing Report', 'Contract-wise detailed billing with performance scores', 'PDF • Excel', 'Per Contract', () => _generateContractReport()),
                _buildReportCard(context, Icons.warning_amber, 'Penalty Report', 'Detailed penalty breakdown and analytics', 'PDF • Excel', 'Monthly', () => _generatePenaltyReport()),
                _buildReportCard(context, Icons.business, 'Division Billing Report', 'Division-wise billing summary and trends', 'PDF • Excel • CSV', 'Quarterly', () => _generateDivisionReport()),
                _buildReportCard(context, Icons.person, 'Contractor Billing Report', 'Contractor-wise billing history and payments', 'PDF • Excel', 'Per Contractor', () => _generateContractorReport()),
                _buildReportCard(context, Icons.receipt_long, 'Invoice Register', 'Register of all generated invoices', 'PDF • Excel • CSV', 'All Time', () => _generateInvoiceRegister()),
                _buildReportCard(context, Icons.trending_up, 'Billing Audit Report', 'Complete audit trail of billing calculations', 'PDF', 'Custom', () => _generateAuditReport()),
              ],
            ),
    );
  }

  Future<void> _generateMonthlyReport() async {
    await _saveAndSharePdf((bill) async {
      final bytes = await PDFReportService.generateBillingReportPdf(bill.toJson(), bill.deductions.map((d) => d.toJson()).toList());
      return bytes;
    }, 'billing_report');
  }

  Future<void> _saveAndSharePdf(Future<List<int>> Function(BillingReport bill) genPdf, String prefix) async {
    if (reports.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No billing data available'))); return; }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generating...'), backgroundColor: Colors.blue));
      try {
        final bill = reports.first;
        final bytes = await genPdf(bill);
        final fileName = '${prefix}_${bill.period.replaceAll(' ', '_')}.pdf';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved: $fileName'), backgroundColor: Colors.green));
          await Share.shareXFiles([XFile.fromData(Uint8List.fromList(bytes), name: fileName, mimeType: 'application/pdf')], text: 'Billing Report - ${bill.period}');
        }
      } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _saveAndShareCsv(String Function() genCsv, String fileName) async {
    if (reports.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No billing data available'))); return; }
      try {
        final content = genCsv();
        final bytes = utf8.encode(content);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved: $fileName'), backgroundColor: Colors.green));
          await Share.shareXFiles([XFile.fromData(Uint8List.fromList(bytes), name: fileName, mimeType: 'text/csv')], text: 'Billing Report - $fileName');
        }
      } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _generateContractReport() async {
    await _saveAndShareCsv(() {
      final buf = StringBuffer('Contract,Entity,Period,Score,Grade,Contract Value,Deductions,Final Payable,Status\n');
      for (final r in reports) { buf.writeln('${r.contractNumber},${r.entityName},${r.period},${r.overallScore},${r.grade},${r.contractValue},${r.totalDeduction},${r.finalPayable},${r.status}'); }
      return buf.toString();
    }, 'contract_billing_report.csv');
  }

  Future<void> _generatePenaltyReport() async {
    await _saveAndSharePdf((bill) async {
      final bytes = await PDFReportService.generateBillingReportPdf(bill.toJson(), bill.deductions.map((d) => d.toJson()).toList());
      return bytes;
    }, 'penalty_report');
  }

  Future<void> _generateDivisionReport() async {
    await _saveAndShareCsv(() {
      final buf = StringBuffer('Division,Period,Total Contracts,Total Value,Total Deductions,Total Payable\n');
      final grouped = <String, List<BillingReport>>{};
      for (final r in reports) { grouped.putIfAbsent(r.division, () => []).add(r); }
      grouped.forEach((div, list) {
        final totalVal = list.fold(0.0, (s, r) => s + r.contractValue);
        final totalDed = list.fold(0.0, (s, r) => s + r.totalDeduction);
        final totalPay = list.fold(0.0, (s, r) => s + r.finalPayable);
        buf.writeln('$div,${list.first.period},${list.length},$totalVal,$totalDed,$totalPay');
      });
      return buf.toString();
    }, 'division_billing_report.csv');
  }

  Future<void> _generateContractorReport() async {
    await _saveAndShareCsv(() {
      final buf = StringBuffer('Entity,Contract,Period,Score,Grade,Amount,Status\n');
      for (final r in reports) { buf.writeln('${r.entityName},${r.contractNumber},${r.period},${r.overallScore},${r.grade},${r.finalPayable},${r.status}'); }
      return buf.toString();
    }, 'contractor_billing_report.csv');
  }

  Future<void> _generateInvoiceRegister() async {
    await _saveAndShareCsv(() {
      final buf = StringBuffer('Invoice,Contract,Entity,Period,Amount,Status\n');
      for (final r in reports) { buf.writeln('${r.invoiceNumber ?? 'N/A'},${r.contractNumber},${r.entityName},${r.period},${r.finalPayable},${r.status}'); }
      return buf.toString();
    }, 'invoice_register.csv');
  }

  Future<void> _generateAuditReport() async {
    await _saveAndSharePdf((bill) async {
      final bytes = await PDFReportService.generateBillingReportPdf(bill.toJson(), bill.deductions.map((d) => d.toJson()).toList());
      return bytes;
    }, 'audit_report');
  }

  Widget _buildReportCard(BuildContext context, IconData icon, String title, String description, String formats, String period, VoidCallback onGenerate) {
    return Card(margin: const EdgeInsets.only(bottom: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: kRailwayBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: kRailwayBlue, size: 24)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            Text(description, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)), child: Text(period, style: TextStyle(fontSize: 10, color: Colors.blue.shade700, fontWeight: FontWeight.bold))),
        ]),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(formats, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ElevatedButton.icon(onPressed: onGenerate, icon: const Icon(Icons.download, size: 16), label: const Text('Generate', style: TextStyle(fontSize: 12)), style: ElevatedButton.styleFrom(backgroundColor: kRailwayBlue, foregroundColor: Colors.white)),
        ]),
      ])),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Filter Reports'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButtonFormField<String>(decoration: const InputDecoration(labelText: 'Division', border: OutlineInputBorder()), items: ['All Divisions'].map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(), onChanged: (v) {}),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(decoration: const InputDecoration(labelText: 'Period', border: OutlineInputBorder()), items: ['This Month', 'Last Month', 'This Quarter', 'This Year'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(), onChanged: (v) {}),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), ElevatedButton(onPressed: () { Navigator.pop(ctx); _loadReports(); }, child: const Text('Apply'))],
      ),
    );
  }
}