import 'package:crm_train/model/station_cleaning_models.dart';
import 'package:crm_train/model/railway_worker_model.dart';
import 'package:crm_train/repositories/station_attendance_repository.dart';
import 'package:crm_train/repositories/obhs_repository.dart';
import 'package:crm_train/utills/app_colors.dart';
import 'package:flutter/material.dart';

class StationAttendanceScreen extends StatefulWidget {
  final String stationId;
  final String stationName;
  const StationAttendanceScreen({super.key, required this.stationId, required this.stationName});

  @override
  State<StationAttendanceScreen> createState() => _StationAttendanceScreenState();
}

class _StationAttendanceScreenState extends State<StationAttendanceScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedShift = 'morning';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  List<RailwayWorkerModel> _workers = [];
  final Map<String, AttendanceStatus> _attendanceStates = {};
  final Map<String, String> _reasons = {};

  @override
  void initState() {
    super.initState();
    _loadWorkers();
  }

  Future<void> _loadWorkers() async {
    setState(() => _isLoading = true);
    try {
      final workersList = await OBHSRepository.getWorkers();
      setState(() {
        _workers = workersList;
        for (var w in _workers) {
          final uid = w.uid;
          if (uid.isNotEmpty) {
            _attendanceStates[uid] = AttendanceStatus.present;
          }
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load workers: $e'), backgroundColor: kErrorRed),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }


  Future<void> _submitAttendance() async {
    setState(() => _isLoading = true);
    try {
      final formattedDate = "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";
      final payload = {
        'stationId': widget.stationId,
        'date': formattedDate,
        'shift': _selectedShift,
        'workers': _workers.map((w) {
          final uid = w.uid;
          return {
            'workerId': uid,
            'workerName': w.fullName,
            'status': _attendanceStates[uid]?.name ?? 'present',
            'captureMode': 'manual',
            'reason': _reasons[uid] ?? '',
          };
        }).toList(),
      };
      await StationAttendanceRepository.bulkMark(payload);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attendance submitted successfully!'), backgroundColor: kSuccessGreen),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: $e'), backgroundColor: kErrorRed),
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
        title: Text('Mark Attendance - ${widget.stationName}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: kRailwayBlue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading && _workers.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  Card(
                    margin: const EdgeInsets.all(16),
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedShift,
                              decoration: const InputDecoration(labelText: 'Shift', border: OutlineInputBorder()),
                              items: const [
                                DropdownMenuItem(value: 'morning', child: Text('Morning (06:00 - 14:00)')),
                                DropdownMenuItem(value: 'afternoon', child: Text('Afternoon (14:00 - 22:00)')),
                                DropdownMenuItem(value: 'night', child: Text('Night (22:00 - 06:00)')),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedShift = val);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: const Icon(Icons.calendar_today, color: kRailwayBlue),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate,
                                firstDate: DateTime.now().subtract(const Duration(days: 7)),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setState(() => _selectedDate = picked);
                              }
                            },
                          ),
                          Text(
                            "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _workers.length,
                      itemBuilder: (context, idx) {
                        final w = _workers[idx];
                        final uid = w.uid;
                        final name = w.fullName;
                        final designation = w.designation ?? 'Field Staff';

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Column(
                              children: [
                                ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: kRailwayBlue.withOpacity(0.1),
                                    child: const Icon(Icons.person, color: kRailwayBlue),
                                  ),
                                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text(designation),
                                  trailing: DropdownButton<AttendanceStatus>(
                                    value: _attendanceStates[uid],
                                    items: AttendanceStatus.values.map((status) {
                                      return DropdownMenuItem(
                                        value: status,
                                        child: Text(status.name.toUpperCase()),
                                      );
                                    }).toList(),
                                    onChanged: (status) {
                                      if (status != null) {
                                        setState(() {
                                          _attendanceStates[uid] = status;
                                        });
                                      }
                                    },
                                  ),
                                ),
                                if (_attendanceStates[uid] != AttendanceStatus.present)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                    child: TextFormField(
                                      decoration: const InputDecoration(
                                        labelText: 'Reason for absence/late',
                                        border: UnderlineInputBorder(),
                                      ),
                                      onChanged: (val) => _reasons[uid] = val,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitAttendance,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kRailwayBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Submit Attendance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
