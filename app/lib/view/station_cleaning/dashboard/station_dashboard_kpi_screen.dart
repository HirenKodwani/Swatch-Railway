import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crm_train/utills/app_colors.dart';
import 'package:crm_train/model/station_cleaning_models.dart';
import 'package:crm_train/services/api_services.dart';

class StationDashboardKpiScreen extends StatefulWidget {
  final String stationId;
  final String stationName;
  const StationDashboardKpiScreen({super.key, required this.stationId, required this.stationName});

  @override
  State<StationDashboardKpiScreen> createState() => _StationDashboardKpiScreenState();
}

class _StationDashboardKpiScreenState extends State<StationDashboardKpiScreen> {
  bool _isLoading = true;
  DashboardKpis? _kpis;
  String? _error;
  bool _filtersVisible = false;

  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedShift = 'all';
  final _areaCtrl = TextEditingController();
  final _contractorCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() {
    _areaCtrl.dispose();
    _contractorCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final params = <String, String>{};
      if (_startDate != null) params['startDate'] = _startDate!.toIso8601String().split('T')[0];
      if (_endDate != null) params['endDate'] = _endDate!.toIso8601String().split('T')[0];
      if (_selectedShift != 'all') params['shift'] = _selectedShift;
      if (_areaCtrl.text.trim().isNotEmpty) params['area'] = _areaCtrl.text.trim();
      if (_contractorCtrl.text.trim().isNotEmpty) params['contractor'] = _contractorCtrl.text.trim();
      final uri = Uri.parse('${ApiService.baseUrl}/api/dashboard/station/${widget.stationId}').replace(queryParameters: params.isNotEmpty ? params : null);
      final res = await http.get(uri, headers: {'Content-Type': 'application/json', if (token != null) 'Authorization': 'Bearer $token'});
      if (res.statusCode == 200) {
        final raw = jsonDecode(res.body)['data'] ?? jsonDecode(res.body);
        setState(() { _kpis = DashboardKpis.fromJson(raw); _isLoading = false; });
      } else throw Exception('Failed to load dashboard');
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.stationName} Dashboard', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: kRailwayBlue, iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(_filtersVisible ? Icons.filter_alt_off : Icons.filter_alt),
            onPressed: () => setState(() => _filtersVisible = !_filtersVisible),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                  const SizedBox(height: 12), Text(_error!), const SizedBox(height: 8),
                  ElevatedButton(onPressed: _load, child: const Text('Retry')),
                ]))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(children: [
                    if (_filtersVisible) _buildFilterBar(),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(children: [
                        _buildScoreGauge(),
                        const SizedBox(height: 16),
                        _kpiRow('Average Score', '${_kpis!.averageScore}%', kSuccessGreen, Icons.star, '${_kpis!.averageScore}/100'),
                        _kpiRow('Attendance Rate', '${_kpis!.attendanceRate}%', kRailwayBlue, Icons.people, '${_kpis!.attendanceRate}%'),
                        _kpiRow('Avg. Feedback', _kpis!.averageFeedback.toStringAsFixed(1), Colors.orange, Icons.feedback, '/5'),
                        _kpiRow('Open Complaints', '${_kpis!.openComplaints}', kErrorRed, Icons.report, 'needs action'),
                        _kpiRow('Maintenance', '${_kpis!.inMaintenance}', Colors.blueGrey, Icons.build, 'machines'),
                        _kpiRow('Activity Completion', '${_kpis!.activityCompletionRate}%', Colors.teal, Icons.checklist, ''),
                        _kpiRow('Planned Variance', '${_kpis!.plannedVsActual > 0 ? '-' : ''}${_kpis!.plannedVsActual}', _kpis!.plannedVsActual > 0 ? kErrorRed : Colors.green, Icons.compare_arrows, 'workers'),
                        _kpiRow('Missed Alerts', '${_kpis!.missedAlerts}', _kpis!.missedAlerts > 0 ? kWarningOrange : Colors.green, Icons.warning, ''),
                        _kpiRow('Billing Packs', '${_kpis!.billingReady}', kSuccessGreen, Icons.receipt, 'ready'),
                        _kpiRow('Reports Sent', '${_kpis!.reportsSent}', Colors.purple, Icons.assessment, 'total'),
                      ]),
                    ),
                  ]),
                ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(context: context, initialDate: _startDate ?? DateTime.now().subtract(const Duration(days: 30)), firstDate: DateTime(2020), lastDate: DateTime.now());
                        if (picked != null) setState(() => _startDate = picked);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Start Date', border: OutlineInputBorder(), isDense: true),
                        child: Text(_startDate != null ? _startDate!.toIso8601String().split('T')[0] : 'Select', style: const TextStyle(fontSize: 13)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(context: context, initialDate: _endDate ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime.now());
                        if (picked != null) setState(() => _endDate = picked);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'End Date', border: OutlineInputBorder(), isDense: true),
                        child: Text(_endDate != null ? _endDate!.toIso8601String().split('T')[0] : 'Select', style: const TextStyle(fontSize: 13)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedShift,
                      decoration: const InputDecoration(labelText: 'Shift', border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All Shifts', style: TextStyle(fontSize: 13))),
                        DropdownMenuItem(value: 'morning', child: Text('Morning', style: TextStyle(fontSize: 13))),
                        DropdownMenuItem(value: 'afternoon', child: Text('Afternoon', style: TextStyle(fontSize: 13))),
                        DropdownMenuItem(value: 'night', child: Text('Night', style: TextStyle(fontSize: 13))),
                      ],
                      onChanged: (v) { if (v != null) setState(() => _selectedShift = v); },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _areaCtrl,
                      decoration: const InputDecoration(labelText: 'Area', border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _contractorCtrl,
                      decoration: const InputDecoration(labelText: 'Contractor', border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _load,
                    style: ElevatedButton.styleFrom(backgroundColor: kRailwayBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
                    child: const Text('Apply', style: TextStyle(fontSize: 13)),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _startDate = null;
                        _endDate = null;
                        _selectedShift = 'all';
                        _areaCtrl.clear();
                        _contractorCtrl.clear();
                      });
                      _load();
                    },
                    child: const Text('Clear', style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreGauge() {
    final score = _kpis!.averageScore;
    final color = score >= 80 ? kSuccessGreen : score >= 60 ? kWarningOrange : kErrorRed;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('Overall Station Score', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              width: 120, height: 120,
              child: Stack(alignment: Alignment.center, children: [
                SizedBox(width: 120, height: 120, child: CircularProgressIndicator(value: score / 100, strokeWidth: 10, backgroundColor: Colors.grey.shade200, valueColor: AlwaysStoppedAnimation(color))),
                Text('$score', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color)),
              ]),
            ),
            const SizedBox(height: 8),
            Text('Attendance: ${_kpis!.attendanceRate}% | Feedback: ${_kpis!.averageFeedback.toStringAsFixed(1)}', style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _kpiRow(String label, String value, Color color, IconData icon, String subtitle) {
    return Card(margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
        trailing: Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ),
    );
  }
}
