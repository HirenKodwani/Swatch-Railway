import 'package:crm_train/model/station_cleaning_models.dart';
import 'package:crm_train/repositories/pest_control_repository.dart';
import 'package:crm_train/utills/app_colors.dart';
import 'package:flutter/material.dart';
import 'pest_control_form_screen.dart';

class PestControlListScreen extends StatefulWidget {
  final String stationId;
  final String stationName;
  const PestControlListScreen({super.key, required this.stationId, required this.stationName});

  @override
  State<PestControlListScreen> createState() => _PestControlListScreenState();
}

class _PestControlListScreenState extends State<PestControlListScreen> {
  bool _isLoading = false;
  List<PestTreatment> _plans = [];
  String? _filterStatus;
  String? _filterType;

  final List<String> _treatmentTypes = ['fumigation', 'spraying', 'baiting', 'fogging', 'other'];
  final List<PestTreatmentStatus> _statusOptions = PestTreatmentStatus.values;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final query = <String, String>{'stationId': widget.stationId};
      if (_filterStatus != null) query['status'] = _filterStatus!;
      if (_filterType != null) query['treatmentType'] = _filterType!;
      final list = await PestControlRepository.listPlans(query);
      setState(() => _plans = list);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load pest control plans: $e'), backgroundColor: kErrorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING_REVIEW':
      case 'PENDINGREVIEW':
        return kWarningOrange;
      case 'APPROVED':
        return kSuccessGreen;
      case 'REJECTED':
        return kErrorRed;
      case 'FOLLOW_UP':
      case 'FOLLOWUP':
        return Colors.purple;
      case 'CLOSED':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    return status.replaceAll('_', ' ').toUpperCase();
  }

  Future<void> _reviewPlan(PestTreatment plan, String newStatus) async {
    final remarksController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${newStatus.replaceAll('_', ' ')} Plan'),
        content: TextField(
          controller: remarksController,
          decoration: const InputDecoration(
            labelText: 'Remarks (optional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, remarksController.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: kRailwayBlue, foregroundColor: Colors.white),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    if (result == null || !mounted) return;
    setState(() => _isLoading = true);
    try {
      await PestControlRepository.reviewPlan(plan.uid, newStatus, result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Plan $newStatus'), backgroundColor: kSuccessGreen),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Review failed: $e'), backgroundColor: kErrorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pest Control - ${widget.stationName}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: kRailwayBlue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButton<String>(
                      value: _filterStatus,
                      hint: const Text('All Status'),
                      isExpanded: true,
                      items: _statusOptions.map((s) => DropdownMenuItem(
                        value: s.name,
                        child: Text(s.name.replaceAll('_', ' ').toUpperCase()),
                      )).toList()..insert(0, const DropdownMenuItem(value: null, child: Text('All Status'))),
                      onChanged: (val) {
                        setState(() => _filterStatus = val);
                        _load();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButton<String>(
                      value: _filterType,
                      hint: const Text('All Types'),
                      isExpanded: true,
                      items: _treatmentTypes.map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(t[0].toUpperCase() + t.substring(1)),
                      )).toList()..insert(0, const DropdownMenuItem(value: null, child: Text('All Types'))),
                      onChanged: (val) {
                        setState(() => _filterType = val);
                        _load();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _plans.isEmpty
                    ? const Center(child: Text('No pest control plans found'))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          itemCount: _plans.length,
                          itemBuilder: (context, idx) {
                            final plan = _plans[idx];
                            final statusColor = _statusColor(plan.status);
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: ListTile(
                                title: Text(plan.treatmentType[0].toUpperCase() + plan.treatmentType.substring(1), style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('${plan.scheduledDate.toString().split(' ')[0]} | ${plan.chemicalUsed ?? 'N/A'}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: statusColor),
                                      ),
                                      child: Text(
                                        _statusLabel(plan.status),
                                        style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    if (plan.status.toUpperCase() == 'PENDING_REVIEW' || plan.status.toUpperCase() == 'PENDINGREVIEW') ...[
                                      const SizedBox(width: 8),
                                      TextButton(
                                        onPressed: () => _reviewPlan(plan, 'approved'),
                                        style: TextButton.styleFrom(foregroundColor: kSuccessGreen, padding: const EdgeInsets.symmetric(horizontal: 8)),
                                        child: const Text('Review', style: TextStyle(fontSize: 11)),
                                      ),
                                    ],
                                  ],
                                ),
                                onTap: () {
                                  if (plan.status.toUpperCase() == 'PENDING_REVIEW' || plan.status.toUpperCase() == 'PENDINGREVIEW') {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Review Plan'),
                                        content: const Text('Choose action:'),
                                        actions: [
                                          TextButton(
                                            onPressed: () { Navigator.pop(ctx); _reviewPlan(plan, 'approved'); },
                                            child: const Text('Approve', style: TextStyle(color: kSuccessGreen)),
                                          ),
                                          TextButton(
                                            onPressed: () { Navigator.pop(ctx); _reviewPlan(plan, 'rejected'); },
                                            child: const Text('Reject', style: TextStyle(color: kErrorRed)),
                                          ),
                                          TextButton(
                                            onPressed: () { Navigator.pop(ctx); _reviewPlan(plan, 'followUp'); },
                                            child: const Text('Follow Up', style: TextStyle(color: Colors.purple)),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: kRailwayBlue,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PestControlFormScreen(
                stationId: widget.stationId,
                stationName: widget.stationName,
              ),
            ),
          ).then((_) => _load());
        },
      ),
    );
  }
}
