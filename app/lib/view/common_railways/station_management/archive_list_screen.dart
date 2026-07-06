import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../utills/app_colors.dart';
import '../../../services/api_services.dart';

class ArchiveListScreen extends StatefulWidget {
  const ArchiveListScreen({super.key});

  @override
  State<ArchiveListScreen> createState() => _ArchiveListScreenState();
}

class _ArchiveListScreenState extends State<ArchiveListScreen> {
  bool _isLoading = false;
  List _archives = [];
  String? _error;
  String _selectedType = 'All';

  final _types = [
    'All', 'cleaning_forms', 'attendance', 'daily_activities',
    'scorecards', 'complaints', 'inspections', 'execution_logs'
  ];

  @override
  void initState() {
    super.initState();
    _loadArchives();
  }

  Future<void> _loadArchives() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await ApiService.listArchives(
        archiveType: _selectedType == 'All' ? null : _selectedType,
      );
      if (mounted) {
        setState(() { _archives = data['archives'] ?? []; _isLoading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  String _typeLabel(String t) {
    switch (t) {
      case 'cleaning_forms': return 'Cleaning Forms';
      case 'attendance': return 'Attendance';
      case 'daily_activities': return 'Daily Activities';
      case 'scorecards': return 'Scorecards';
      case 'complaints': return 'Complaints';
      case 'inspections': return 'Inspections';
      case 'execution_logs': return 'Execution Logs';
      default: return t;
    }
  }

  IconData _typeIcon(String t) {
    switch (t) {
      case 'cleaning_forms': return Icons.cleaning_services;
      case 'attendance': return Icons.fact_check;
      case 'daily_activities': return Icons.assignment_turned_in;
      case 'scorecards': return Icons.score;
      case 'complaints': return Icons.report_problem;
      case 'inspections': return Icons.visibility;
      case 'execution_logs': return Icons.list_alt;
      default: return Icons.archive;
    }
  }

  Color _typeColor(String t) {
    switch (t) {
      case 'cleaning_forms': return kRailwayBlue;
      case 'attendance': return Colors.indigo;
      case 'daily_activities': return Colors.teal;
      case 'scorecards': return Colors.purple;
      case 'complaints': return kErrorRed;
      case 'inspections': return kWarningOrange;
      case 'execution_logs': return Colors.brown;
      default: return Colors.grey;
    }
  }

  Future<void> _triggerArchiveDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => _ArchiveTriggerDialog(
        onTrigger: (sid, type, month, year) async {
          return ApiService.triggerArchive(sid, type, month, year);
        },
      ),
    );

    if (result != null && mounted) {
      _loadArchives();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Archive created'), backgroundColor: kSuccessGreen),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Archives', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.brown[700],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _types.map((t) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_typeLabel(t)),
                    selected: _selectedType == t,
                    onSelected: (v) => setState(() { _selectedType = t; _loadArchives(); }),
                    selectedColor: _typeColor(t),
                    labelStyle: TextStyle(color: _selectedType == t ? Colors.white : Colors.black87, fontSize: 12),
                  ),
                )).toList(),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                            const SizedBox(height: 16),
                            Text(_error!, style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 8),
                            ElevatedButton(onPressed: _loadArchives, child: const Text('Retry')),
                          ],
                        ),
                      )
                    : _archives.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.archive_outlined, size: 80, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            const Text('No archives yet', style: TextStyle(color: Colors.grey, fontSize: 16)),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: _triggerArchiveDialog,
                              icon: const Icon(Icons.add),
                              label: const Text('Trigger Archive'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _archives.length,
                        itemBuilder: (context, index) {
                          final a = _archives[index];
                          final type = a['archiveType'] ?? '';
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _typeColor(type).withOpacity(0.1),
                                child: Icon(_typeIcon(type), color: _typeColor(type)),
                              ),
                              title: Text('${_typeLabel(type)} — ${a['stationName'] ?? 'N/A'}',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              subtitle: Text(
                                '${a['month']}/${a['year']} • ${a['recordCount']} records • ${a['archivedAt']?.toString().substring(0, 10) ?? ''}',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                              onTap: () => _viewArchiveDetail(a['uid']),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _triggerArchiveDialog,
        backgroundColor: Colors.brown[700],
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Trigger', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _viewArchiveDetail(String uid) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ArchiveDetailScreen(archiveUid: uid)),
    );
  }
}

class _ArchiveTriggerDialog extends StatefulWidget {
  final Future<Map<String, dynamic>> Function(String stationId, String type, int month, int year) onTrigger;

  const _ArchiveTriggerDialog({required this.onTrigger});

  @override
  State<_ArchiveTriggerDialog> createState() => _ArchiveTriggerDialogState();
}

class _ArchiveTriggerDialogState extends State<_ArchiveTriggerDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedStationId;
  String _selectedType = 'cleaning_forms';
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  bool _isLoading = false;
  bool _isTriggering = false;
  List _stations = [];

  @override
  void initState() {
    super.initState();
    _loadStations();
  }

  Future<void> _loadStations() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getStations();
      if (mounted) setState(() { _stations = data; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  final _types = [
    'cleaning_forms', 'attendance', 'daily_activities',
    'scorecards', 'complaints', 'inspections', 'execution_logs'
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Trigger Archive'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Station', border: OutlineInputBorder()),
                value: _selectedStationId,
                items: _isLoading
                    ? [const DropdownMenuItem(value: null, child: Text('Loading...'))]
                    : _stations.map<DropdownMenuItem<String>>((s) => DropdownMenuItem(
                        value: s.uid ?? s.stationCode,
                        child: Text(s.stationName ?? ''),
                      )).toList(),
                onChanged: (v) {
                  setState(() { _selectedStationId = v; });
                },
                validator: (v) => v == null ? 'Select station' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Archive Type', border: OutlineInputBorder()),
                value: _selectedType,
                items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t.replaceAll('_', ' ')))).toList(),
                onChanged: (v) => setState(() => _selectedType = v!),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      decoration: const InputDecoration(labelText: 'Month', border: OutlineInputBorder()),
                      value: _selectedMonth,
                      items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}'))),
                      onChanged: (v) => setState(() => _selectedMonth = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      decoration: const InputDecoration(labelText: 'Year', border: OutlineInputBorder()),
                      value: _selectedYear,
                      items: List.generate(5, (i) {
                        final y = DateTime.now().year - i;
                        return DropdownMenuItem(value: y, child: Text('$y'));
                      }),
                      onChanged: (v) => setState(() => _selectedYear = v!),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isTriggering ? null : () async {
            if (!_formKey.currentState!.validate()) return;
            setState(() => _isTriggering = true);
            try {
              final result = await widget.onTrigger(_selectedStationId!, _selectedType, _selectedMonth, _selectedYear);
              if (context.mounted) Navigator.pop(context, result);
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: kErrorRed));
                setState(() => _isTriggering = false);
              }
            }
          },
          child: _isTriggering ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Archive'),
        ),
      ],
    );
  }
}

class ArchiveDetailScreen extends StatefulWidget {
  final String archiveUid;

  const ArchiveDetailScreen({super.key, required this.archiveUid});

  @override
  State<ArchiveDetailScreen> createState() => _ArchiveDetailScreenState();
}

class _ArchiveDetailScreenState extends State<ArchiveDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _archive;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await ApiService.getArchiveById(widget.archiveUid);
      if (mounted) setState(() { _archive = data; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Archive Detail', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.brown[700],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : _archive == null
                  ? const Center(child: Text('Archive not found'))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_archive!['stationName'] ?? 'N/A',
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                _infoRow('Type', _archive!['archiveType']?.toString().replaceAll('_', ' ') ?? ''),
                                _infoRow('Period', '${_archive!['month']}/${_archive!['year']}'),
                                _infoRow('Records', '${_archive!['recordCount'] ?? 0}'),
                                _infoRow('Status', _archive!['status'] ?? ''),
                                _infoRow('Archived By', _archive!['archivedByName'] ?? ''),
                                _infoRow('Date', _archive!['archivedAt']?.toString().substring(0, 10) ?? ''),
                              ],
                            ),
                          ),
                        ),
                        if (_archive!['data'] is List && (_archive!['data'] as List).isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 16, bottom: 8),
                            child: Text('Records (${(_archive!['data'] as List).length})',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        if (_archive!['data'] is List)
                          ...(_archive!['data'] as List).map((r) => Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r['id'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text(jsonEncode(r), style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                                ],
                              ),
                            ),
                          )),
                      ],
                    ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label, style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
