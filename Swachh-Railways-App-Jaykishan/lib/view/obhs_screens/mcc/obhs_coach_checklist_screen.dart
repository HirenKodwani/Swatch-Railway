import 'package:flutter/material.dart';
import 'package:crm_train/model/user_model.dart';
import 'package:crm_train/utills/app_colors.dart';
import 'package:crm_train/repositories/worker_repo.dart';

import 'obhs_task_execution_sheet.dart';

class ObhsCoachChecklistScreen extends StatefulWidget {
  final UserModel user;
  final String coachLabel;
  final String? runInstanceId;

  const ObhsCoachChecklistScreen({
    super.key,
    required this.user,
    required this.coachLabel,
    this.runInstanceId,
  });

  @override
  State<ObhsCoachChecklistScreen> createState() => _ObhsCoachChecklistScreenState();
}

class _ObhsCoachChecklistScreenState extends State<ObhsCoachChecklistScreen> {
  List<Map<String, dynamic>> _tasks = [];
  bool _loading = true;
  String? _error;
  String _selectedTab = 'due';

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    if (widget.runInstanceId == null) return;
    setState(() => _loading = true);
    try {
      final resp = await WorkerRepository.getObhsTasksBoard(
        runInstanceId: widget.runInstanceId!,
      );
      if (resp['success'] == true) {
        final cats = resp['categories'] as Map<String, dynamic>? ?? {};
        // Flatten all tasks from all tabs
        final all = <Map<String, dynamic>>[];
        cats.forEach((_, v) {
          if (v is List) all.addAll(v.cast<Map<String, dynamic>>());
        });
        _tasks = all;
      }
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  List<Map<String, dynamic>> get _filteredTasks {
    if (_selectedTab == 'all') return _tasks;
    return _tasks.where((t) => (t['status'] ?? '').toString().toLowerCase() == _selectedTab).toList();
  }

  Map<String, List<Map<String, dynamic>>> get _groupedByType {
    final result = <String, List<Map<String, dynamic>>>{};
    for (final t in _filteredTasks) {
      final type = t['taskType'] ?? 'Other';
      result.putIfAbsent(type, () => []).add(t);
    }
    return result;
  }

  String _statusLabel(Map<String, dynamic> task) {
    final s = (task['status'] ?? '').toString();
    if (s == 'Completed') return 'DONE';
    if (s == 'Overdue') return 'OVERDUE';
    if (s == 'Due') return 'DUE';
    return 'PENDING';
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'DONE': return kSuccessGreen;
      case 'OVERDUE': return kErrorRed;
      case 'DUE': return kWarningOrange;
      default: return Colors.grey;
    }
  }

  IconData _iconForType(String type) {
    if (type.contains('Toilet')) return Icons.bathroom;
    if (type.contains('Garbage') || type.contains('garbage')) return Icons.delete_outline;
    if (type.contains('Coach') || type.contains('Aisle')) return Icons.cleaning_services;
    if (type.contains('Linen')) return Icons.bed;
    if (type.contains('Water')) return Icons.water_drop;
    if (type.contains('Safety')) return Icons.shield;
    if (type.contains('Repair')) return Icons.build;
    if (type.contains('Night')) return Icons.nightlight_round;
    return Icons.task_alt;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Coach ${widget.coachLabel} Checklist',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            Text('${_tasks.length} tasks', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
          ],
        ),
        backgroundColor: kRailwayBlue, iconTheme: const IconThemeData(color: Colors.white), elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _fetchTasks),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text('$_error', textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _fetchTasks, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        _buildTabBar(),
        Expanded(
          child: _groupedByType.isEmpty
              ? Center(child: Text('No ${_selectedTab != 'all' ? _selectedTab : ''} tasks', style: TextStyle(color: Colors.grey[500])))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: _groupedByType.entries.map((entry) => _buildGroupCard(entry.key, entry.value)).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildTabChip('Due', 'due'),
          const SizedBox(width: 8),
          _buildTabChip('Overdue', 'overdue'),
          const SizedBox(width: 8),
          _buildTabChip('All', 'all'),
        ],
      ),
    );
  }

  Widget _buildTabChip(String label, String value) {
    final active = _selectedTab == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? kRailwayBlue : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(color: active ? Colors.white : Colors.black87, fontWeight: FontWeight.w600, fontSize: 13)),
      ),
    );
  }

  Widget _buildGroupCard(String type, List<Map<String, dynamic>> children) {
    final total = children.length;
    final completed = children.where((c) => (c['status'] ?? '').toString() == 'Completed').length;
    final isAllDone = total > 0 && completed == total;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isAllDone ? kSuccessGreen.withOpacity(0.5) : Colors.grey[200]!, width: isAllDone ? 2 : 1)),
      elevation: 1,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isAllDone ? kSuccessGreen.withOpacity(0.1) : kRailwayBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_iconForType(type), color: isAllDone ? kSuccessGreen : kRailwayBlue),
          ),
          title: Text(type, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          subtitle: Text('$completed of $total sub-tasks completed',
              style: TextStyle(fontSize: 12, color: isAllDone ? kSuccessGreen : Colors.grey[600],
                  fontWeight: isAllDone ? FontWeight.bold : FontWeight.normal)),
          trailing: isAllDone
              ? const Icon(Icons.check_circle, color: kSuccessGreen)
              : const Icon(Icons.expand_more, color: Colors.grey),
          children: [
            const Divider(height: 1),
            ...children.map((child) => _buildChildRow(child)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildChildRow(Map<String, dynamic> child) {
    final label = _statusLabel(child);
    final color = _statusColor(label);
    final freq = child['frequencyIndex'] ?? '';

    return InkWell(
      onTap: () => _openTaskSheet(child),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[100]!))),
        child: Row(
          children: [
            Container(width: 2, height: 20, color: Colors.grey[300], margin: const EdgeInsets.only(right: 16, left: 8)),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
                  children: [
                    TextSpan(text: child['taskType'] ?? ''),
                    if (freq.toString().isNotEmpty)
                      TextSpan(text: ' — $freq', style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.normal)),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: color.withOpacity(0.5)),
              ),
              child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _openTaskSheet(Map<String, dynamic> task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ObhsTaskExecutionSheet(
        task: task,
        runInstanceId: widget.runInstanceId ?? '',
        coachNo: widget.coachLabel,
      ),
    ).then((submitted) {
      if (submitted == true) _fetchTasks();
    });
  }
}
