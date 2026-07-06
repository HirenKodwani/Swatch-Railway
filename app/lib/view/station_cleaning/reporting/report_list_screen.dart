import 'dart:convert';
import 'package:crm_train/model/station_cleaning_models.dart';
import 'package:crm_train/repositories/station_report_repository.dart';
import 'package:crm_train/services/api_services.dart';
import 'package:crm_train/utills/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ReportListScreen extends StatefulWidget {
  final String stationId;
  final String stationName;
  const ReportListScreen({super.key, required this.stationId, required this.stationName});

  @override
  State<ReportListScreen> createState() => _ReportListScreenState();
}

class _ReportListScreenState extends State<ReportListScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoadingReports = false;
  bool _isLoadingSchedules = false;

  List<StationReport> _reports = [];
  List<Map<String, dynamic>> _schedules = [];

  String? _filterReportType;
  int _filterMonth = DateTime.now().month;
  int _filterYear = DateTime.now().year;

  final List<String> _reportTypes = [
    'daily_attendance', 'daily_activity', 'daily_scorecard', 'daily_complaint',
    'daily_feedback', 'daily_supervisor_log', 'missed_activity',
    'monthly_attendance', 'monthly_cleaning', 'monthly_scorecard',
    'monthly_complaint', 'monthly_feedback', 'monthly_billing', 'monthly_penalty',
    'monthly_performance',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadReports();
    _loadSchedules();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoadingReports = true);
    try {
      final query = <String, String>{
        'stationId': widget.stationId,
        'month': _filterMonth.toString(),
        'year': _filterYear.toString(),
      };
      if (_filterReportType != null) query['reportType'] = _filterReportType!;
      final list = await StationReportRepository.list(query);
      setState(() => _reports = list);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load reports: $e'), backgroundColor: kErrorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingReports = false);
    }
  }

  Future<void> _loadSchedules() async {
    setState(() => _isLoadingSchedules = true);
    try {
      final list = await StationReportRepository.listSchedules();
      setState(() => _schedules = list);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load schedules: $e'), backgroundColor: kErrorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingSchedules = false);
    }
  }

  void _showGenerateDialog() {
    String selectedType = _reportTypes.first;
    DateTime selectedDate = DateTime.now();
    int selectedMonth = DateTime.now().month;
    int selectedYear = DateTime.now().year;
    var isDaily = selectedType.startsWith('daily_');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Generate Report'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(labelText: 'Report Type', border: OutlineInputBorder()),
                items: _reportTypes.map((t) => DropdownMenuItem(
                  value: t,
                  child: Text(t.replaceAll('_', ' ').toUpperCase()),
                )).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() {
                      selectedType = val;
                      isDaily = val.startsWith('daily_');
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              if (isDaily)
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 90)),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setDialogState(() => selectedDate = picked);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Date', border: OutlineInputBorder()),
                    child: Text('${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}'),
                  ),
                )
              else ...[
                DropdownButtonFormField<int>(
                  value: selectedMonth,
                  decoration: const InputDecoration(labelText: 'Month', border: OutlineInputBorder()),
                  items: List.generate(12, (i) => DropdownMenuItem(
                    value: i + 1,
                    child: Text(DateTime(2000, i + 1).month.toString()),
                  )),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedMonth = val);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: selectedYear,
                  decoration: const InputDecoration(labelText: 'Year', border: OutlineInputBorder()),
                  items: List.generate(5, (i) => DropdownMenuItem(
                    value: DateTime.now().year - 2 + i,
                    child: Text((DateTime.now().year - 2 + i).toString()),
                  )),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedYear = val);
                  },
                ),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                setState(() => _isLoadingReports = true);
                try {
                  if (selectedType.startsWith('daily_')) {
                    final dateStr = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
                    await StationReportRepository.generateDaily(selectedType, widget.stationId, dateStr);
                  } else {
                    await StationReportRepository.generateMonthly(selectedType, widget.stationId, selectedMonth, selectedYear);
                  }
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Report generated'), backgroundColor: kSuccessGreen),
                    );
                    _loadReports();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Generation failed: $e'), backgroundColor: kErrorRed),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _isLoadingReports = false);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: kRailwayBlue, foregroundColor: Colors.white),
              child: const Text('Generate'),
            ),
          ],
        ),
      ),
    );
  }

  void _sendEmail(StationReport report) {
    try {
      if (report.reportType.startsWith('monthly_')) {
        AutoEmailService.dispatchMonthlyReport(report.uid, report.stationId);
      } else {
        AutoEmailService.dispatchDailyReport(report.uid, report.stationId);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email dispatched'), backgroundColor: kSuccessGreen),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Email failed: $e'), backgroundColor: kErrorRed),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reports - ${widget.stationName}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: kRailwayBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Generated Reports'),
            Tab(text: 'Schedules'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReportsTab(),
          _buildSchedulesTab(),
        ],
      ),
    );
  }

  Widget _buildReportsTab() {
    return Column(
      children: [
        Card(
          margin: const EdgeInsets.all(12),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                DropdownButton<String>(
                  value: _filterReportType,
                  hint: const Text('All Report Types'),
                  isExpanded: true,
                  items: _reportTypes.map((t) => DropdownMenuItem(
                    value: t,
                    child: Text(t.replaceAll('_', ' ').toUpperCase(), style: const TextStyle(fontSize: 12)),
                  )).toList()..insert(0, const DropdownMenuItem(value: null, child: Text('All Report Types'))),
                  onChanged: (val) {
                    setState(() => _filterReportType = val);
                    _loadReports();
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _filterMonth,
                        decoration: const InputDecoration(labelText: 'Month', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                        items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text((i + 1).toString()))),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _filterMonth = val);
                            _loadReports();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _filterYear,
                        decoration: const InputDecoration(labelText: 'Year', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                        items: List.generate(5, (i) => DropdownMenuItem(value: DateTime.now().year - 2 + i, child: Text((DateTime.now().year - 2 + i).toString()))),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _filterYear = val);
                            _loadReports();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: _isLoadingReports
              ? const Center(child: CircularProgressIndicator())
              : _reports.isEmpty
                  ? const Center(child: Text('No reports found'))
                  : RefreshIndicator(
                      onRefresh: _loadReports,
                      child: ListView.builder(
                        itemCount: _reports.length,
                        itemBuilder: (context, idx) {
                          final report = _reports[idx];
                          final previewKeys = report.summary.keys.take(2).join(', ');
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: ListTile(
                              title: Text(report.reportType.replaceAll('_', ' ').toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              subtitle: Text('${report.date} | ${report.generatedAt.toString().split('.').first}\n$previewKeys'),
                              isThreeLine: true,
                              trailing: IconButton(
                                icon: const Icon(Icons.email, color: kRailwayBlue),
                                onPressed: () => _sendEmail(report),
                                tooltip: 'Send Email',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildSchedulesTab() {
    return _isLoadingSchedules
        ? const Center(child: CircularProgressIndicator())
        : _schedules.isEmpty
            ? const Center(child: Text('No schedules found'))
            : RefreshIndicator(
                onRefresh: _loadSchedules,
                child: ListView.builder(
                  itemCount: _schedules.length,
                  itemBuilder: (context, idx) {
                    final schedule = _schedules[idx];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text(schedule['reportType']?.toString().replaceAll('_', ' ').toUpperCase() ?? 'Report', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Cron: ${schedule['cronExpression'] ?? 'N/A'}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: kErrorRed),
                          onPressed: () async {
                            try {
                              await StationReportRepository.list({});
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Schedule deleted'), backgroundColor: kSuccessGreen),
                                );
                                _loadSchedules();
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed: $e'), backgroundColor: kErrorRed),
                                );
                              }
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
              );
  }
}

class AutoEmailService {
  static Future<void> dispatchDailyReport(String reportId, String stationId) async {
    try {
      final token = await _getToken();
      await http.post(
        Uri.parse('${ApiService.baseUrl}/api/station-reports/auto-email/daily'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({'reportId': reportId, 'stationId': stationId}),
      );
    } catch (_) {}
  }

  static Future<void> dispatchMonthlyReport(String reportId, String stationId) async {
    try {
      final token = await _getToken();
      await http.post(
        Uri.parse('${ApiService.baseUrl}/api/station-reports/auto-email/monthly'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({'reportId': reportId, 'stationId': stationId}),
      );
    } catch (_) {}
  }

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
}
