import 'package:crm_train/model/station_cleaning_models.dart';
import 'package:crm_train/repositories/daily_activity_repository.dart';
import 'package:crm_train/utills/app_colors.dart';
import 'package:flutter/material.dart';
import 'activity_record_form_screen.dart';

class DailyActivityListScreen extends StatefulWidget {
  final String stationId;
  final String stationName;
  const DailyActivityListScreen({super.key, required this.stationId, required this.stationName});

  @override
  State<DailyActivityListScreen> createState() => _DailyActivityListScreenState();
}

class _DailyActivityListScreenState extends State<DailyActivityListScreen> {
  bool _isLoading = false;
  String _selectedShift = 'all';
  String _selectedStatus = 'all';
  DateTime _selectedDate = DateTime.now();
  List<DailyActivityRecord> _activities = [];

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    setState(() => _isLoading = true);
    try {
      final formattedDate = "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";
      final query = {
        'stationId': widget.stationId,
        'date': formattedDate,
        if (_selectedShift != 'all') 'shift': _selectedShift,
        if (_selectedStatus != 'all') 'status': _selectedStatus,
      };
      final list = await DailyActivityRepository.list(query);
      setState(() {
        _activities = list;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load activities: $e'), backgroundColor: kErrorRed),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Color _statusColor(DailyActivityStatus status) {
    switch (status) {
      case DailyActivityStatus.pending: return Colors.orange;
      case DailyActivityStatus.inProgress: return Colors.blue;
      case DailyActivityStatus.completed: return Colors.teal;
      case DailyActivityStatus.partiallyCompleted: return Colors.indigo;
      case DailyActivityStatus.rejected: return kErrorRed;
      case DailyActivityStatus.resubmitted: return Colors.purple;
      case DailyActivityStatus.approved: return kSuccessGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Daily Activities - ${widget.stationName}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: kRailwayBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadActivities,
          )
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
                          _loadActivities();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButton<String>(
                      value: _selectedStatus,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All Status')),
                        DropdownMenuItem(value: 'pending', child: Text('Pending')),
                        DropdownMenuItem(value: 'completed', child: Text('Completed')),
                        DropdownMenuItem(value: 'approved', child: Text('Approved')),
                        DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedStatus = val);
                          _loadActivities();
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
                        firstDate: DateTime.now().subtract(const Duration(days: 30)),
                        lastDate: DateTime.now().add(const Duration(days: 7)),
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                        _loadActivities();
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
                : _activities.isEmpty
                    ? const Center(child: Text('No daily activities configured/recorded for this date.'))
                    : ListView.builder(
                        itemCount: _activities.length,
                        itemBuilder: (context, idx) {
                          final act = _activities[idx];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: ListTile(
                              title: Text(act.activityName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Area: ${act.areaName} | Shift: ${act.shift.toUpperCase()}'),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _statusColor(act.status).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: _statusColor(act.status)),
                                ),
                                child: Text(
                                  act.status.name.toUpperCase(),
                                  style: TextStyle(color: _statusColor(act.status), fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ActivityRecordFormScreen(
                                      activityRecord: act,
                                      stationId: widget.stationId,
                                      stationName: widget.stationName,
                                    ),
                                  ),
                                ).then((_) => _loadActivities());
                              },
                            ),
                          );
                        },
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
              builder: (_) => ActivityRecordFormScreen(
                stationId: widget.stationId,
                stationName: widget.stationName,
              ),
            ),
          ).then((_) => _loadActivities());
        },
      ),
    );
  }
}
