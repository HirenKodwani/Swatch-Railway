import 'package:crm_train/model/billing_models.dart';
import 'package:crm_train/services/api_services.dart';
import 'package:crm_train/utills/app_colors.dart';
import 'package:crm_train/view/common_railways/billing/monthly_bill_screen.dart';
import 'package:flutter/material.dart';

class BillingApprovalScreen extends StatefulWidget {
  const BillingApprovalScreen({super.key});

  @override
  State<BillingApprovalScreen> createState() => _BillingApprovalScreenState();
}

class _BillingApprovalScreenState extends State<BillingApprovalScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<BillingReport> allBills = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool silent = false}) async {
    if (!silent) setState(() { isLoading = true; });
    try {
      final reports = await ApiService.getBillingReports();
      if (mounted) setState(() { allBills = reports; if (!silent) isLoading = false; });
    } catch (e) {
      if (mounted && !silent) setState(() { isLoading = false; });
    }
  }

  List<BillingReport> get pendingBills => allBills.where((b) => b.status == 'PENDING').toList();
  List<BillingReport> get approvedBills => allBills.where((b) => b.status == 'APPROVED' || b.status == 'REJECTED').toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill Approvals', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: kRailwayBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData, tooltip: 'Refresh'),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(text: 'Pending (${pendingBills.length})', icon: const Icon(Icons.hourglass_empty, size: 18)),
            Tab(text: 'Processed (${approvedBills.length})', icon: const Icon(Icons.check_circle, size: 18)),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPendingList(),
                _buildProcessedList(),
              ],
            ),
    );
  }

  Widget _buildPendingList() {
    if (pendingBills.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.check_circle_outline, size: 64, color: Colors.green.shade300),
        const SizedBox(height: 16),
        const Text('No pending bills', style: TextStyle(fontSize: 16, color: Colors.grey)),
      ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pendingBills.length,
      itemBuilder: (_, i) => _buildBillCard(pendingBills[i]),
    );
  }

  Widget _buildProcessedList() {
    if (approvedBills.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.info_outline, size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        const Text('No processed bills', style: TextStyle(fontSize: 16, color: Colors.grey)),
      ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: approvedBills.length,
      itemBuilder: (_, i) => _buildProcessedCard(approvedBills[i]),
    );
  }

  Widget _buildBillCard(BillingReport bill) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MonthlyBillScreen(billId: bill.uid))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(bill.uid.length > 12 ? bill.uid.substring(0, 12) : bill.uid, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: const Text('Pending', style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold))),
                ],
              ),
              const SizedBox(height: 8),
              _detailRow('Contract', bill.contractNumber),
              _detailRow('Contractor', bill.entityName),
              _detailRow('Period', bill.period),
              _detailRow('Amount', '₹${_formatAmount(bill.finalPayable)}'),
              _detailRow('Score', '${bill.overallScore}% (${bill.grade})'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: ElevatedButton.icon(onPressed: () => _approveBill(bill.uid), icon: const Icon(Icons.check, size: 18), label: const Text('Approve'), style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white))),
                  const SizedBox(width: 12),
                  Expanded(child: OutlinedButton.icon(onPressed: () => _rejectBill(bill.uid), icon: const Icon(Icons.close, size: 18), label: const Text('Reject'), style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProcessedCard(BillingReport bill) {
    final isApproved = bill.status == 'APPROVED';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MonthlyBillScreen(billId: bill.uid))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: (isApproved ? Colors.green : Colors.red).withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(isApproved ? Icons.check_circle : Icons.cancel, color: isApproved ? Colors.green : Colors.red, size: 28)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(bill.uid.length > 12 ? bill.uid.substring(0, 12) : bill.uid, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('${bill.entityName} • ${bill.period}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                Text('Score: ${bill.overallScore}% | ₹${_formatAmount(bill.finalPayable)}', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                if (bill.approvedBy != null) Text('By: ${bill.approvedBy}', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ])),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: (isApproved ? Colors.green : Colors.red).withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(bill.status, style: TextStyle(color: isApproved ? Colors.green : Colors.red, fontSize: 10, fontWeight: FontWeight.bold))),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _approveBill(String billId) async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Approve Bill'),
      content: const Text('Are you sure?'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Approve'))],
    ));
    if (confirm != true) return;
    try {
      await ApiService.approveBill(billId);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bill approved'), backgroundColor: Colors.green));
      _loadData(silent: true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _rejectBill(String billId) async {
    final reasonCtrl = TextEditingController();
    final reason = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Reject Bill'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Provide reason:'),
        const SizedBox(height: 12),
        TextField(controller: reasonCtrl, maxLines: 3, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Enter reason')),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), ElevatedButton(onPressed: () => Navigator.pop(ctx, reasonCtrl.text.trim()), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Reject'))],
    ));
    if (reason == null || reason.isEmpty) return;
    try {
      await ApiService.rejectBill(billId, reason: reason);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bill rejected'), backgroundColor: Colors.red));
      _loadData(silent: true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Widget _detailRow(String label, String value) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Row(
      children: [SizedBox(width: 100, child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600))), Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)))],
    ));
  }

  String _formatAmount(double amount) {
    if (amount >= 10000000) return '${(amount / 10000000).toStringAsFixed(2)}Cr';
    if (amount >= 100000) return '${(amount / 100000).toStringAsFixed(2)}L';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}K';
    return amount.toStringAsFixed(0);
  }
}