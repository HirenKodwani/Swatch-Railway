import 'package:crm_train/model/station_cleaning_models.dart';
import 'package:crm_train/repositories/supervisor_log_repository.dart';
import 'package:crm_train/utills/app_colors.dart';
import 'package:flutter/material.dart';
import 'supervisor_log_form_screen.dart';

class SupervisorLogListScreen extends StatefulWidget {
  final String stationId;
  final String stationName;
  const SupervisorLogListScreen({super.key, required this.stationId, required this.stationName});

  @override
  State<SupervisorLogListScreen> createState() => _SupervisorLogListScreenState();
}

class _SupervisorLogListScreenState extends State<SupervisorLogListScreen> {
  bool _isLoading = false;
  String _selectedShift = 'all';
  DateTime _selectedDate = DateTime.now();
  List<SupervisorLog> _logs = [];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    try {
      final formattedDate = "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";
      final query = <String, String>{
        'stationId': widget.stationId,
        'date': formattedDate,
      };
      if (_selectedShift != 'all') query['shift'] = _selectedShift;
      final list = await SupervisorLogRepository.list(query);
      setState(() => _logs = list);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load logs: $e'), backgroundColor: kErrorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'DRAFT': return Colors.grey;
      case 'SUBMITTED': return kRailwayBlue;
      case 'ACKNOWLEDGED': return kWarningOrange;
      case 'ACCEPTED': return kSuccessGreen;
      case 'RETURNED': return Colors.purple;
      case 'REJECTED': return kErrorRed;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sup. Log - ${widget.stationName}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: kRailwayBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLogs,
          ),
        ],
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButton<String>(
                      value: _selectedShift,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All Shifts')),
                        DropdownMenuItem(value: 'morning', child: Text('Morning')),
                        DropdownMenuItem(value: 'afternoon', child: Text('Afternoon')),
                        DropdownMenuItem(value: 'night', child: Text('Night')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedShift = val);
                          _loadLogs();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.calendar_today, color: kRailwayBlue),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 90)),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                        _loadLogs();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _logs.isEmpty
                    ? const Center(child: Text('No supervisor logs found'))
                    : RefreshIndicator(
                        onRefresh: _loadLogs,
                        child: ListView.builder(
                          itemCount: _logs.length,
                          itemBuilder: (context, idx) {
                            final log = _logs[idx];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: ListTile(
                                title: Text(log.supervisorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('${log.date} | Shift: ${log.shift.toUpperCase()}'),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _statusColor(log.status).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: _statusColor(log.status)),
                                  ),
                                  child: Text(
                                    log.status,
                                    style: TextStyle(color: _statusColor(log.status), fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SupervisorLogFormScreen(
                                        log: log,
                                        stationId: widget.stationId,
                                        stationName: widget.stationName,
                                      ),
                                    ),
                                  ).then((_) => _loadLogs());
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
              builder: (_) => SupervisorLogFormScreen(
                stationId: widget.stationId,
                stationName: widget.stationName,
              ),
            ),
          ).then((_) => _loadLogs());
        },
      ),
    );
  }
}
