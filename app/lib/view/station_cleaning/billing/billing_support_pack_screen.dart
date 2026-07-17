import 'package:crm_train/model/station_cleaning_models.dart';
import 'package:crm_train/providers/auth_provider.dart';
import 'package:crm_train/repositories/station_billing_repository.dart';
import 'package:crm_train/services/api_services.dart';
import 'package:crm_train/utills/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BillingSupportPackScreen extends StatefulWidget {
  final String? contractId;
  final String stationId;
  final String stationName;
  const BillingSupportPackScreen({super.key, this.contractId, required this.stationId, required this.stationName});

  @override
  State<BillingSupportPackScreen> createState() => _BillingSupportPackScreenState();
}

class _BillingSupportPackScreenState extends State<BillingSupportPackScreen> {
  bool _isLoading = false;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  StationBillingPack? _billingPack;
  final TextEditingController _rejectionReasonCtrl = TextEditingController();
  String? _resolvedContractId;

  @override
  void initState() {
    super.initState();
    _resolvedContractId = widget.contractId;
    if (_resolvedContractId == null || _resolvedContractId!.isEmpty) {
      _resolveContractId();
    }
  }

  Future<void> _resolveContractId() async {
    setState(() => _isLoading = true);
    try {
      final contracts = await ApiService.getActiveContracts();
      final contract = contracts.firstWhere(
        (c) => c.stationIds.contains(widget.stationId),
        orElse: () => throw Exception('No active contract found for this station'),
      );
      setState(() {
        _resolvedContractId = contract.uid;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to resolve contract: $e'), backgroundColor: kErrorRed),
      );
    }
  }

  @override
  void dispose() {
    _rejectionReasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchOrGenerate() async {
    if (_resolvedContractId == null || _resolvedContractId!.isEmpty) {
      await _resolveContractId();
    }
    if (_resolvedContractId == null || _resolvedContractId!.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final pack = await StationBillingRepository.generate(
        _resolvedContractId!,
        widget.stationId,
        _selectedMonth,
        _selectedYear,
      );
      setState(() {
        _billingPack = pack;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load/generate billing pack: $e'), backgroundColor: kErrorRed),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateComplianceCheckbox(String key, bool val) async {
    if (_billingPack == null) return;
    final updatedChecklist = Map<String, dynamic>.from(_billingPack!.complianceChecklist);
    updatedChecklist[key] = val;
    try {
      await StationBillingRepository.updateCompliance(_billingPack!.uid, updatedChecklist);
      _fetchOrGenerate();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update compliance: $e'), backgroundColor: kErrorRed),
      );
    }
  }

  Future<void> _submitPack() async {
    if (_billingPack == null) return;
    try {
      await StationBillingRepository.submit(_billingPack!.uid);
      _fetchOrGenerate();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Submission failed: $e'), backgroundColor: kErrorRed),
      );
    }
  }

  Future<void> _approvePack() async {
    if (_billingPack == null) return;
    try {
      await StationBillingRepository.approve(_billingPack!.uid);
      _fetchOrGenerate();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Approval failed: $e'), backgroundColor: kErrorRed),
      );
    }
  }

  Future<void> _rejectPack() async {
    if (_billingPack == null) return;
    try {
      await StationBillingRepository.reject(_billingPack!.uid, _rejectionReasonCtrl.text.trim());
      _fetchOrGenerate();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rejection failed: $e'), backgroundColor: kErrorRed),
      );
    }
  }

  bool _can(String permission) {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user == null) return false;
    final r = (user.role ?? '').toUpperCase().replaceAll(' ', '_');
    const perms = {
      'SUPER_ADMIN': {'GENERATE', 'VIEW', 'MANAGE', 'APPROVE', 'PAY'},
      'COMPANY_MASTER': {'GENERATE', 'VIEW', 'MANAGE', 'APPROVE', 'PAY'},
      'RAILWAY_MASTER': {'GENERATE', 'VIEW', 'MANAGE', 'APPROVE', 'PAY'},
      'ADMIN': {'GENERATE', 'VIEW', 'MANAGE', 'APPROVE', 'PAY'},
      'RAILWAY_ADMIN': {'GENERATE', 'VIEW', 'MANAGE', 'APPROVE', 'PAY'},
      'CONTRACTOR_MASTER': {'GENERATE', 'VIEW', 'MANAGE', 'APPROVE', 'PAY'},
      'CONTRACTOR_ADMIN': {'GENERATE', 'VIEW', 'APPROVE', 'PAY'},
    };
    return (perms[r] ?? <String>{}).contains(permission);
  }

  Future<void> _recordPayment() async {
    final amountCtrl = TextEditingController();
    final refCtrl = TextEditingController();
    String mode = 'bank_transfer';
    final modes = ['bank_transfer', 'cheque', 'cash', 'online'];
    final recorded = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Record Payment'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount *', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: mode,
                decoration: const InputDecoration(labelText: 'Mode *', border: OutlineInputBorder()),
                items: modes.map((m) => DropdownMenuItem(value: m, child: Text(m.replaceAll('_', ' ').toUpperCase()))).toList(),
                onChanged: (v) { if (v != null) mode = v; },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: refCtrl,
                decoration: const InputDecoration(labelText: 'Reference (optional)', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final amount = double.tryParse(amountCtrl.text.trim());
              if (amount == null || amount <= 0) return;
              Navigator.pop(ctx, {'amount': amountCtrl.text.trim(), 'mode': mode, 'reference': refCtrl.text.trim()});
            },
            child: const Text('Record Payment'),
          ),
        ],
      ),
    );
    if (recorded == null) return;
    try {
      await StationBillingRepository.recordPayment(
        _billingPack!.uid,
        amount: double.parse(recorded['amount']!),
        mode: recorded['mode']!,
        reference: recorded['reference'],
      );
      _fetchOrGenerate();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment recorded'), backgroundColor: kSuccessGreen),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed: $e'), backgroundColor: kErrorRed),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Billing Support Pack', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: kRailwayBlue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedMonth,
                      decoration: const InputDecoration(labelText: 'Month', border: OutlineInputBorder()),
                      items: List.generate(12, (index) {
                        return DropdownMenuItem(value: index + 1, child: Text((index + 1).toString()));
                      }),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedMonth = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedYear,
                      decoration: const InputDecoration(labelText: 'Year', border: OutlineInputBorder()),
                      items: [2025, 2026, 2027].map((y) {
                        return DropdownMenuItem(value: y, child: Text(y.toString()));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedYear = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _fetchOrGenerate,
                    style: ElevatedButton.styleFrom(backgroundColor: kRailwayBlue, foregroundColor: Colors.white),
                    child: const Text('Go'),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _billingPack == null
                    ? const Center(child: Text('Select month/year and tap Go to generate support pack.'))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Contractor: ${_billingPack!.contractorName}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text('Contract Value (Monthly Base): ₹${_billingPack!.monthlyContractValue}'),
                            Text('Billable Amount: ₹${_billingPack!.billableAmount}', style: const TextStyle(fontSize: 16, color: kSuccessGreen, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            Card(
                              color: kRailwayBlue.withOpacity(0.05),
                              child: ListTile(
                                title: const Text('Status of Billing Pack'),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(color: kRailwayBlue, borderRadius: BorderRadius.circular(6)),
                                  child: Text(_billingPack!.status, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text('Compliance Document Checklist', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            ..._billingPack!.complianceChecklist.keys.map((key) {
                              return CheckboxListTile(
                                title: Text(key.replaceAll('Attached', '').toUpperCase()),
                                value: _billingPack!.complianceChecklist[key] == true,
                                onChanged: (val) {
                                  if (val != null) {
                                    _updateComplianceCheckbox(key, val);
                                  }
                                },
                              );
                            }),
                            const SizedBox(height: 16),
                            if (_billingPack!.status == 'DRAFT' && _can('MANAGE'))
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: _submitPack,
                                  style: ElevatedButton.styleFrom(backgroundColor: kRailwayBlue, foregroundColor: Colors.white),
                                  child: const Text('Submit Pack for Review'),
                                ),
                              ),
                            if (_billingPack!.status == 'SUBMITTED' && _can('APPROVE')) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _approvePack,
                                      style: ElevatedButton.styleFrom(backgroundColor: kSuccessGreen, foregroundColor: Colors.white),
                                      child: const Text('Approve Pack'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Reject Billing Pack'),
                                            content: TextField(
                                              controller: _rejectionReasonCtrl,
                                              decoration: const InputDecoration(hintText: 'Enter reason for rejection'),
                                            ),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  _rejectPack();
                                                },
                                                child: const Text('Reject'),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(backgroundColor: kErrorRed, foregroundColor: Colors.white),
                                      child: const Text('Reject Pack'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (_billingPack!.status == 'APPROVED' && _can('PAY')) ...[
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton.icon(
                                  onPressed: _recordPayment,
                                  icon: const Icon(Icons.payment),
                                  style: ElevatedButton.styleFrom(backgroundColor: kSuccessGreen, foregroundColor: Colors.white),
                                  label: const Text('Record Payment'),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
