import 'package:crm_train/model/billing_models.dart';
import 'package:crm_train/services/api_services.dart';
import 'package:crm_train/utills/app_colors.dart';
import 'package:crm_train/view/common_railways/billing/monthly_bill_screen.dart';
import 'package:flutter/material.dart';

class SupervisorBillingDashboard extends StatefulWidget {
  const SupervisorBillingDashboard({super.key});

  @override
  State<SupervisorBillingDashboard> createState() => _SupervisorBillingDashboardState();
}

class _SupervisorBillingDashboardState extends State<SupervisorBillingDashboard> {
  Map<String, dynamic>? data;
  List<BillingReport> reports = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { isLoading = true; });
    try {
      final results = await Future.wait([
        ApiService.getSupervisorBillingData(),
        ApiService.getBillingReports(),
      ]);
      if (mounted) setState(() { data = results[0] as Map<String, dynamic>; reports = results[1] as List<BillingReport>; isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Billing Overview', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: kRailwayBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData, tooltip: 'Refresh')],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : data == null
              ? const Center(child: Text('Could not load data'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      _buildOverviewCards(),
                      const SizedBox(height: 20),
                      const Text('Contract Performance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      ...reports.take(5).map((r) => _buildPerformanceCard(r)),
                      if (reports.isEmpty) const Padding(padding: EdgeInsets.all(16), child: Text('No billing data available', style: TextStyle(color: Colors.grey))),
                      const SizedBox(height: 20),
                      const Text('Monthly Billing Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      ...reports.take(6).map((r) => _buildMonthSummary(r)),
                    ],
                  ),
                ),
    );
  }

  Widget _buildOverviewCards() {
    return Row(children: [
      Expanded(child: _statCard('Active Contracts', '${data!['activeContracts'] ?? 0}', Colors.blue)),
      const SizedBox(width: 12),
      Expanded(child: _statCard('Total Bills', '${data!['totalBills'] ?? 0}', kRailwayBlue)),
      const SizedBox(width: 12),
      Expanded(child: _statCard('Penalties', '₹${_formatAmount((data!['totalPenalties'] ?? 0).toDouble())}', Colors.red)),
    ]);
  }

  Widget _statCard(String title, String value, Color color) {
    return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(2, 3))]),
      child: Column(children: [Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)), const SizedBox(height: 4), Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: Colors.grey.shade600))]));
  }

  Widget _buildPerformanceCard(BillingReport r) {
    final scoreColor = r.overallScore >= 90 ? Colors.green : (r.overallScore >= 80 ? Colors.blue : (r.overallScore >= 70 ? Colors.orange : Colors.red));
    return Card(margin: const EdgeInsets.only(bottom: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MonthlyBillScreen(billId: r.uid))),
        child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r.contractNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Text(r.entityName, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            const SizedBox(height: 4),
            Text('${r.period} • ₹${_formatAmount(r.contractValue)}', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ])),
          Container(width: 50, height: 50, decoration: BoxDecoration(shape: BoxShape.circle, color: scoreColor.withOpacity(0.1), border: Border.all(color: scoreColor, width: 2)),
            child: Center(child: Text('${r.overallScore.toInt()}', style: TextStyle(fontWeight: FontWeight.bold, color: scoreColor, fontSize: 16)))),
        ]))),
      ),
    );
  }

  Widget _buildMonthSummary(BillingReport r) {
    return Card(margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MonthlyBillScreen(billId: r.uid))),
        child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r.period, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Text('${r.contractNumber} • ${r.grade}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('₹${_formatAmount(r.finalPayable)}', style: const TextStyle(fontWeight: FontWeight.bold, color: kRailwayBlue, fontSize: 13)),
            Text('Deductions: ₹${_formatAmount(r.totalDeduction)}', style: TextStyle(fontSize: 11, color: Colors.red.shade400)),
          ]),
        ]))),
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 10000000) return '${(amount / 10000000).toStringAsFixed(2)}Cr';
    if (amount >= 100000) return '${(amount / 100000).toStringAsFixed(2)}L';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}K';
    return amount.toStringAsFixed(0);
  }
}