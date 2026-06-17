import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/api_services.dart';
import '../../../utills/app_colors.dart';

class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  List<Map<String, dynamic>> _logs = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  String? _selectedAction;
  int _total = 0;

  static const _actionColors = {
    'PASSWORD_CHANGED': Colors.orange,
    'COMPLAINT_ASSIGNED': Colors.blue,
    'COMPLAINT_ESCALATED': Colors.red,
    'COMPLAINT_AUTO_ROUTED': Colors.teal,
    'APPROVED': Colors.green,
    'REJECTED': Colors.red,
    'CREATED': Colors.blueGrey,
    'SUBMITTED': Colors.indigo,
    'SCORED': Colors.purple,
    'LOCKED': Colors.brown,
    'INVOICE_GENERATED': Colors.amber,
    'GENERATED': Colors.grey,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      _logs = await ApiService.getAuditLogs(action: _selectedAction, limit: 100);
      try { _stats = await ApiService.getAuditLogStats(); } catch (_) {}
      _total = _stats['total'] as int? ?? _logs.length;
    } catch (e) {
      //
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Color _colorForAction(String action) {
    return _actionColors.entries.firstWhere(
      (e) => action.contains(e.key),
      orElse: () => const MapEntry('', Colors.grey),
    ).value;
  }

  String _formatTime(dynamic ts) {
    if (ts == null) return 'N/A';
    try {
      return DateFormat('dd-MMM-yyyy hh:mm a').format(DateTime.parse(ts));
    } catch (_) {
      return '$ts';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        title: const Text('Audit Logs'),
        backgroundColor: kRailwayBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (v) {
              _selectedAction = v;
              _load();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: null, child: Text('All Actions')),
              ..._actionColors.keys.map((a) => PopupMenuItem(value: a, child: Text(a))),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: Row(
              children: [
                const Icon(Icons.history, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Text('$_total total entries', style: const TextStyle(color: Colors.black54)),
                if (_selectedAction != null) ...[
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(_selectedAction!, style: const TextStyle(fontSize: 11)),
                    onDeleted: () { _selectedAction = null; _load(); },
                    deleteIcon: const Icon(Icons.close, size: 16),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _logs.isEmpty
                    ? const Center(child: Text('No audit logs found'))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _logs.length,
                          itemBuilder: (_, i) {
                            final log = _logs[i];
                            final action = log['action'] as String? ?? 'UNKNOWN';
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: _colorForAction(action).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(Icons.circle, size: 12, color: _colorForAction(action)),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(action, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _colorForAction(action))),
                                          const SizedBox(height: 4),
                                          Text(log['details'] as String? ?? '', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                                          const SizedBox(height: 4),
                                          Text('${log['performedByName'] ?? 'System'} • ${_formatTime(log['timestamp'])}',
                                              style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}