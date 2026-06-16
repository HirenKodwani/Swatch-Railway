import 'package:crm_train/services/api_services.dart';
import 'package:crm_train/utills/app_colors.dart';
import 'package:crm_train/model/billing_models.dart';
import 'package:flutter/material.dart';

class MonthlyBillScreen extends StatefulWidget {
  final String billId;
  const MonthlyBillScreen({super.key, required this.billId});

  @override
  State<MonthlyBillScreen> createState() => _MonthlyBillScreenState();
}

class _MonthlyBillScreenState extends State<MonthlyBillScreen> {
  BillingReport? bill;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadBill();
  }

  Future<void> _loadBill() async {
    setState(() { isLoading = true; error = null; });
    try {
      final result = await ApiService.getBillingReportDetail(widget.billId);
      if (mounted) setState(() { bill = result; isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { isLoading = false; error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.billId.length > 16 ? widget.billId.substring(0, 16) : widget.billId, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: kRailwayBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.download), onPressed: bill != null ? () => _downloadPdf() : null, tooltip: 'Download PDF'),
          IconButton(icon: const Icon(Icons.share), onPressed: bill != null ? () {} : null, tooltip: 'Share'),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text('Error: $error'))
              : bill == null
                  ? const Center(child: Text('Bill not found'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildBillHeader(),
                          const SizedBox(height: 20),
                          _buildContractDetails(),
                          const SizedBox(height: 20),
                          _buildScoreBreakdown(),
                          const SizedBox(height: 20),
                          _buildDeductionsCard(),
                          const SizedBox(height: 20),
                          _buildSummaryCard(),
                          const SizedBox(height: 20),
                          _buildAuditLog(),
                          if (bill!.status == 'PENDING') ...[const SizedBox(height: 20), _buildActions()],
                        ],
                      ),
                    ),
    );
  }

  Widget _buildBillHeader() {
    final statusColor = bill!.status == 'APPROVED' ? Colors.green : (bill!.status == 'REJECTED' ? Colors.red : Colors.orange);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: kRailwayBannerGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: kRailwayBlue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          const Icon(Icons.receipt_long, color: Colors.white, size: 48),
          const SizedBox(height: 12),
          Text(widget.billId, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('${bill!.period} • Grade ${bill!.grade}', style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor),
            ),
            child: Text(bill!.status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildContractDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(2, 3))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Contract Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Divider(),
          _detailRow('Contract', bill!.contractNumber),
          _detailRow('Contractor', bill!.entityName),
          _detailRow('Division', bill!.division),
          _detailRow('Period', bill!.period),
          _detailRow('Contract Value', '₹${_formatAmount(bill!.contractValue)}'),
          _detailRow('Overall Score', '${bill!.overallScore}% (${bill!.grade})'),
        ],
      ),
    );
  }

  Widget _buildScoreBreakdown() {
    final sb = bill!.scoreBreakdown;
    if (sb == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(2, 3))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Performance Score Breakdown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Divider(),
          ...sb.entries.map((e) => _scoreRow(e.key, (e.value as num).toDouble())),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Overall Score', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green)),
                child: Text('${bill!.overallScore}% (${bill!.grade})', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeductionsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(2, 3))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Deductions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                child: Text('Total: ₹${_formatAmount(bill!.totalDeduction)}', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
          const Divider(),
          ...bill!.deductions.map((d) => _deductionRow(d.description, '₹${_formatAmount(d.amount)}')),
          const SizedBox(height: 8),
          _scoreRow('Performance Deduction', bill!.performanceDeductionPct),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.teal.shade700, Colors.teal.shade500]),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.teal.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          const Text('FINAL PAYABLE AMOUNT', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 8),
          Text('₹${_formatAmount(bill!.finalPayable)}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Contract Value: ₹${_formatAmount(bill!.contractValue)} - Deductions: ₹${_formatAmount(bill!.totalDeduction)}', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildAuditLog() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(2, 3))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Audit Trail', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Divider(),
          ...bill!.auditLog.map((a) => _auditEntry(a.action, a.performedByName, _formatDate(a.timestamp), a.details)),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _approveBill(),
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Approve Bill'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _rejectBill(),
            icon: const Icon(Icons.close, size: 18),
            label: const Text('Reject'),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
        ),
      ],
    );
  }

  Future<void> _approveBill() async {
    try {
      await ApiService.approveBill(widget.billId);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bill approved'), backgroundColor: Colors.green));
      _loadBill();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _rejectBill() async {
    final reasonCtrl = TextEditingController();
    if (!mounted) return;
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Bill'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Provide reason:'),
          const SizedBox(height: 12),
          TextField(controller: reasonCtrl, maxLines: 3, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Enter rejection reason')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, reasonCtrl.text.trim()), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Reject')),
        ],
      ),
    );
    if (reason == null || reason.isEmpty) return;
    try {
      await ApiService.rejectBill(widget.billId, reason: reason);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bill rejected'), backgroundColor: Colors.red));
      _loadBill();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _downloadPdf() async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF download initiated...')));
  }

  Widget _detailRow(String label, String value) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(
      children: [
        SizedBox(width: 120, child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
      ],
    ));
  }

  Widget _scoreRow(String label, double value) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Row(
      children: [
        Expanded(flex: 3, child: Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade700))),
        Expanded(flex: 1, child: Text('${value.toStringAsFixed(1)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
      ],
    ));
  }

  Widget _deductionRow(String label, String amount) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(
      children: [
        Icon(Icons.remove_circle_outline, size: 14, color: Colors.red.shade400),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700))),
        Text(amount, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red.shade700)),
      ],
    ));
  }

  Widget _auditEntry(String action, String by, String time, String details) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: kRailwayBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: Icon(Icons.history, size: 14, color: kRailwayBlue)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Text(action, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue.shade700)), const Spacer(), Text(time, style: TextStyle(fontSize: 10, color: Colors.grey.shade500))]),
          Text('By: $by', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          Text(details, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        ])),
      ],
    ));
  }

  String _formatDate(DateTime dt) {
    return '${dt.day} ${['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][dt.month-1]} ${dt.year}';
  }

  String _formatAmount(double amount) {
    if (amount >= 10000000) return '${(amount / 10000000).toStringAsFixed(2)}Cr';
    if (amount >= 100000) return '${(amount / 100000).toStringAsFixed(2)}L';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}K';
    return amount.toStringAsFixed(0);
  }
}