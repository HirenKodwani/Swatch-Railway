import 'package:flutter/material.dart';
import 'package:crm_train/repositories/base_repository.dart';
import 'package:crm_train/utills/app_colors.dart';

class TaskApprovalScreen extends StatefulWidget {
  final String? stationId;
  final String? stationName;
  const TaskApprovalScreen({super.key, this.stationId, this.stationName});

  @override
  State<TaskApprovalScreen> createState() => _TaskApprovalScreenState();
}

class _TaskApprovalScreenState extends State<TaskApprovalScreen> {
  List<Map<String, dynamic>> _pendingRuns = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPending();
  }

  Future<void> _loadPending() async {
    setState(() => _isLoading = true);
    try {
      final result = await BaseRepository.apiCall(
        method: 'GET',
        path: '/api/station-runs',
        // Fetch completed runs that need approval
        queryParams: {'status': 'completed'},
        parser: (d) => d,
      );
      final raw = result['runs'] ?? result['data'] as List? ?? [];
      _pendingRuns = List<Map<String, dynamic>>.from(raw);
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _approveRun(Map<String, dynamic> run) async {
    final notesCtrl = TextEditingController();
    final notes = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve Station Run'),
        content: TextField(
          controller: notesCtrl,
          decoration: const InputDecoration(labelText: 'Supervisor Notes (optional)', border: OutlineInputBorder()),
          maxLines: 2,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, notesCtrl.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: kSuccessGreen),
            child: const Text('Approve', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (notes == null) return;
    try {
      await BaseRepository.apiCall(
        method: 'PUT',
        path: '/api/station-runs/${run['uid'] ?? run['id']}',
        body: {'status': 'approved', 'supervisorNotes': notes.isNotEmpty ? notes : 'Approved'},
        parser: (d) => d,
      );
      _loadPending();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Station Run approved'), backgroundColor: kSuccessGreen));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: kErrorRed));
      }
    }
  }

  Future<void> _rejectRun(Map<String, dynamic> run) async {
    final reasonCtrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rejection Reason'),
        content: TextField(
          controller: reasonCtrl,
          decoration: const InputDecoration(labelText: 'Reason *', border: OutlineInputBorder()),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (reasonCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx, reasonCtrl.text.trim());
            },
            style: ElevatedButton.styleFrom(backgroundColor: kErrorRed),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (reason == null) return;
    try {
      await BaseRepository.apiCall(
        method: 'PUT',
        path: '/api/station-runs/${run['uid'] ?? run['id']}',
        body: {'status': 'rejected', 'rejectionReason': reason},
        parser: (d) => d,
      );
      _loadPending();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Station Run rejected'), backgroundColor: kWarningOrange));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: kErrorRed));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Station Run Approval', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: kRailwayBlue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: kErrorRed),
                      Text(_error!),
                      ElevatedButton(onPressed: _loadPending, child: const Text('Retry')),
                    ],
                  ),
                )
              : _pendingRuns.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.task_alt, size: 80, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          const Text('No pending Station Runs', style: TextStyle(color: Colors.grey, fontSize: 16)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadPending,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _pendingRuns.length,
                        itemBuilder: (context, index) {
                          final run = _pendingRuns[index];
                          final stationName = run['stationName'] ?? 'Station';
                          final shift = run['shiftType'] ?? run['shift'] ?? '';
                          final date = run['date'] ?? '';
                          
                          return Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            margin: const EdgeInsets.only(bottom: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(color: kRailwayBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                        child: const Icon(Icons.business, color: kRailwayBlue, size: 18),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('$stationName ($shift)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                            Text(date, style: const TextStyle(fontSize: 11, color: kTextSecondary)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  const Divider(height: 1),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton.icon(
                                        onPressed: () => _rejectRun(run),
                                        icon: const Icon(Icons.close, color: kErrorRed, size: 18),
                                        label: const Text('Reject', style: TextStyle(color: kErrorRed)),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton.icon(
                                        onPressed: () => _approveRun(run),
                                        icon: const Icon(Icons.check, size: 18),
                                        label: const Text('Approve'),
                                        style: ElevatedButton.styleFrom(backgroundColor: kSuccessGreen, foregroundColor: Colors.white),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
