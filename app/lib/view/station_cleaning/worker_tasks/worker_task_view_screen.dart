import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crm_train/services/api_services.dart';
import 'package:crm_train/helper/api_error_handler.dart';

class WorkerTaskViewScreen extends StatefulWidget {
  final String workerId;
  final String workerName;

  const WorkerTaskViewScreen({
    super.key,
    required this.workerId,
    required this.workerName,
  });

  @override
  State<WorkerTaskViewScreen> createState() => _WorkerTaskViewScreenState();
}

class _WorkerTaskViewScreenState extends State<WorkerTaskViewScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _tasks = [];
  String? _error;
  String _selectedDate = DateTime.now().toIso8601String().split('T')[0];
  bool _startInProgress = false;

  final List<String> _statusChips = ['all', 'pending', 'in_progress', 'completed', 'approved', 'rejected'];
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) throw Exception('AUTH_ERROR');

      final queryParams = <String, String>{
        'workerId': widget.workerId,
        'date': _selectedDate,
      };

      final uri = Uri.parse('${ApiService.baseUrl}/api/tasks-v2').replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final list = body['tasks'] as List<dynamic>? ?? body['data'] as List<dynamic>? ?? [];
        setState(() {
          _tasks = list.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('AUTH_ERROR');
      } else {
        throw Exception(ApiErrorHandler.getErrorMessage(response.body, response.statusCode));
      }
    } catch (e) {
      setState(() {
        _error = e.toString().contains('AUTH_ERROR') ? 'Session expired' : e.toString();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredTasks {
    var list = _tasks;
    if (_statusFilter != 'all') {
      list = list.where((t) => t['status'] == _statusFilter).toList();
    }
    list.sort((a, b) => ((a['scheduledTime'] ?? '00:00') as String).compareTo(b['scheduledTime'] ?? '00:00'));
    return list;
  }

  Future<void> _startTask(String taskId) async {
    setState(() => _startInProgress = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) throw Exception('AUTH_ERROR');

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/api/tasks-v2/$taskId/start'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task started')));
        _loadTasks();
      } else {
        throw Exception(ApiErrorHandler.getErrorMessage(response.body, response.statusCode));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _startInProgress = false);
    }
  }

  Future<void> _completeTask(String taskId) async {
    final photoCtrl = TextEditingController();
    final remarksCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Complete Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: photoCtrl, decoration: const InputDecoration(labelText: 'After Photo URL', hintText: 'Paste image URL after cleaning')),
            TextField(controller: remarksCtrl, decoration: const InputDecoration(labelText: 'Remarks (optional)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (photoCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('After photo is required')));
                return;
              }
              try {
                final prefs = await SharedPreferences.getInstance();
                final token = prefs.getString('token');
                if (token == null) throw Exception('AUTH_ERROR');

                final response = await http.post(
                  Uri.parse('${ApiService.baseUrl}/api/tasks-v2/$taskId/complete'),
                  headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
                  body: jsonEncode({'afterPhoto': photoCtrl.text, 'remarks': remarksCtrl.text}),
                ).timeout(const Duration(seconds: 30));

                if (response.statusCode == 200) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task completed')));
                  _loadTasks();
                } else {
                  throw Exception(ApiErrorHandler.getErrorMessage(response.body, response.statusCode));
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _resubmitTask(String taskId) async {
    final photoCtrl = TextEditingController();
    final remarksCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resubmit Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: photoCtrl, decoration: const InputDecoration(labelText: 'After Photo URL (updated)')),
            TextField(controller: remarksCtrl, decoration: const InputDecoration(labelText: 'Remarks')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (photoCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('After photo is required')));
                return;
              }
              try {
                final prefs = await SharedPreferences.getInstance();
                final token = prefs.getString('token');
                if (token == null) throw Exception('AUTH_ERROR');

                final response = await http.post(
                  Uri.parse('${ApiService.baseUrl}/api/tasks-v2/$taskId/resubmit'),
                  headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
                  body: jsonEncode({'afterPhoto': photoCtrl.text, 'remarks': remarksCtrl.text}),
                ).timeout(const Duration(seconds: 30));

                if (response.statusCode == 200) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task resubmitted for review')));
                  _loadTasks();
                } else {
                  throw Exception(ApiErrorHandler.getErrorMessage(response.body, response.statusCode));
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Resubmit'),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'assigned': return Colors.blue;
      case 'in_progress': return Colors.amber.shade700;
      case 'completed': return Colors.green;
      case 'approved': return Colors.teal;
      case 'rejected': return Colors.red;
      case 'resubmitted': return Colors.purple;
      default: return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'pending': return Icons.schedule;
      case 'in_progress': return Icons.cleaning_services;
      case 'completed': return Icons.check_circle_outline;
      case 'approved': return Icons.verified;
      case 'rejected': return Icons.cancel;
      case 'resubmitted': return Icons.replay;
      default: return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tasks - ${widget.workerName}')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.parse(_selectedDate),
                        firstDate: DateTime(2024),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked.toIso8601String().split('T')[0]);
                        _loadTasks();
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Date', prefixIcon: Icon(Icons.calendar_today)),
                      child: Text(_selectedDate),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(icon: const Icon(Icons.refresh), onPressed: _loadTasks),
              ],
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: _statusChips.map((s) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FilterChip(
                  label: Text(s.replaceAll('_', ' ')),
                  selected: _statusFilter == s,
                  onSelected: (v) { setState(() => _statusFilter = s); },
                ),
              )).toList(),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text('Error: $_error'))
                    : _filteredTasks.isEmpty
                        ? const Center(child: Text('No tasks found'))
                        : RefreshIndicator(
                            onRefresh: _loadTasks,
                            child: ListView.builder(
                              itemCount: _filteredTasks.length,
                              itemBuilder: (ctx, i) {
                                final t = _filteredTasks[i];
                                final status = t['status'] ?? 'pending';
                                final areaName = t['areaName'] ?? '';
                                final time = t['scheduledTime'] ?? '--:--';
                                final rejectionReason = t['rejectionReason'];

                                return Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  child: ExpansionTile(
                                    leading: Icon(_statusIcon(status), color: _statusColor(status), size: 28),
                                    title: Text('$time - ${areaName.isNotEmpty ? areaName : 'Area'}',
                                        style: const TextStyle(fontWeight: FontWeight.w500)),
                                    subtitle: Text('Status: $status'),
                                    children: [
                                      if (rejectionReason != null)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                          child: Text('Rejection: $rejectionReason',
                                              style: const TextStyle(color: Colors.red)),
                                        ),
                                      Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          children: [
                                            if (status == 'pending')
                                              ElevatedButton.icon(
                                                icon: const Icon(Icons.play_arrow, size: 16),
                                                label: Text(_startInProgress ? '...' : 'Start'),
                                                onPressed: _startInProgress ? null : () => _startTask(t['uid'] ?? t['id']),
                                              ),
                                            if (status == 'in_progress')
                                              ElevatedButton.icon(
                                                icon: const Icon(Icons.check, size: 16),
                                                label: const Text('Complete'),
                                                onPressed: () => _completeTask(t['uid'] ?? t['id']),
                                              ),
                                            if (status == 'rejected')
                                              ElevatedButton.icon(
                                                icon: const Icon(Icons.replay, size: 16),
                                                label: const Text('Resubmit'),
                                                onPressed: () => _resubmitTask(t['uid'] ?? t['id']),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
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
