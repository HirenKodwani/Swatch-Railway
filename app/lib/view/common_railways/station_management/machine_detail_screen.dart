import 'package:flutter/material.dart';
import 'package:crm_train/repositories/base_repository.dart';
import 'package:crm_train/utills/app_colors.dart';

class MachineDetailScreen extends StatefulWidget {
  final Map<String, dynamic> machine;
  const MachineDetailScreen({super.key, required this.machine});

  @override
  State<MachineDetailScreen> createState() => _MachineDetailScreenState();
}

class _MachineDetailScreenState extends State<MachineDetailScreen> {
  List<Map<String, dynamic>> _deployments = [];
  List<Map<String, dynamic>> _downtime = [];
  List<Map<String, dynamic>> _maintenance = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    try {
      final deployResult = await BaseRepository.apiCall(
        method: 'GET',
        path: '/api/machines/deployments',
        queryParams: {'machineId': widget.machine['uid']},
        parser: (d) => d,
      );
      _deployments = (deployResult['deployments'] as List? ?? []).map((e) => e as Map<String, dynamic>).toList();

      final downtimeResult = await BaseRepository.apiCall(
        method: 'GET',
        path: '/api/machines/downtime',
        queryParams: {'machineId': widget.machine['uid']},
        parser: (d) => d,
      );
      _downtime = (downtimeResult['records'] as List? ?? []).map((e) => e as Map<String, dynamic>).toList();

      final maintResult = await BaseRepository.apiCall(
        method: 'GET',
        path: '/api/machines/maintenance',
        queryParams: {'machineId': widget.machine['uid']},
        parser: (d) => d,
      );
      _maintenance = (maintResult['records'] as List? ?? []).map((e) => e as Map<String, dynamic>).toList();
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.machine;
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(m['machineName'] ?? 'Machine Details', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: kRailwayBlue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(m),
                  const SizedBox(height: 12),
                  _buildDeploymentsCard(),
                  const SizedBox(height: 12),
                  _buildDowntimeCard(),
                  const SizedBox(height: 12),
                  _buildMaintenanceCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard(Map<String, dynamic> m) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: kRailwayBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.precision_manufacturing, color: kRailwayBlue, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(m['machineName'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (m['status'] == 'active' ? kSuccessGreen : kWarningOrange).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(m['status'] ?? 'unknown', style: TextStyle(
                  color: m['status'] == 'active' ? kSuccessGreen : kWarningOrange,
                  fontWeight: FontWeight.bold, fontSize: 12,
                )),
              ),
            ]),
            const Divider(height: 20),
            _detailRow('Type', m['machineType'] ?? '-'),
            _detailRow('Serial No.', m['serialNumber'] ?? '-'),
            _detailRow('Model', m['model'] ?? '-'),
            _detailRow('Station', m['stationId'] ?? '-'),
          ],
        ),
      ),
    );
  }

  Widget _buildDeploymentsCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.teal.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.send, color: Colors.teal, size: 20),
              ),
              const SizedBox(width: 10),
              Text('Deployments (${_deployments.length})', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ]),
            const Divider(height: 20),
            if (_deployments.isEmpty)
              const Text('No deployments', style: TextStyle(color: Colors.grey))
            else
              ..._deployments.map((d) => ListTile(
                dense: true,
                title: Text(d['workerName'] ?? 'Assigned', style: const TextStyle(fontSize: 13)),
                subtitle: Text('${d['startDate'] ?? ''} - ${d['endDate'] ?? 'Active'}', style: const TextStyle(fontSize: 11)),
                trailing: Text(d['status'] ?? '', style: const TextStyle(fontSize: 11, color: kTextSecondary)),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildDowntimeCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: kErrorRed.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.error_outline, color: kErrorRed, size: 20),
              ),
              const SizedBox(width: 10),
              Text('Downtime (${_downtime.length})', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ]),
            const Divider(height: 20),
            if (_downtime.isEmpty)
              const Text('No downtime recorded', style: TextStyle(color: Colors.grey))
            else
              ..._downtime.map((d) => ListTile(
                dense: true,
                title: Text(d['reason'] ?? 'Unknown', style: const TextStyle(fontSize: 13)),
                subtitle: Text('${d['startTime'] ?? ''} - ${d['endTime'] ?? 'Ongoing'}', style: const TextStyle(fontSize: 11)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (d['resolved'] == true ? kSuccessGreen : kErrorRed).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(d['resolved'] == true ? 'Resolved' : 'Open', style: TextStyle(fontSize: 10, color: d['resolved'] == true ? kSuccessGreen : kErrorRed)),
                ),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildMaintenanceCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: kWarningOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.build, color: kWarningOrange, size: 20),
              ),
              const SizedBox(width: 10),
              Text('Maintenance (${_maintenance.length})', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ]),
            const Divider(height: 20),
            if (_maintenance.isEmpty)
              const Text('No maintenance scheduled', style: TextStyle(color: Colors.grey))
            else
              ..._maintenance.map((m) => ListTile(
                dense: true,
                title: Text(m['type'] ?? 'Maintenance', style: const TextStyle(fontSize: 13)),
                subtitle: Text('Scheduled: ${m['scheduledDate'] ?? ''} | ${m['status'] ?? ''}', style: const TextStyle(fontSize: 11)),
              )),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: kTextSecondary, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
        ],
      ),
    );
  }
}
