import 'package:crm_train/repositories/obhs_repository.dart';
import 'package:crm_train/utills/app_colors.dart';
import 'package:flutter/material.dart';

class OBHSAttendanceListScreen extends StatefulWidget {
  const OBHSAttendanceListScreen({super.key});

  @override
  State<OBHSAttendanceListScreen> createState() => _OBHSAttendanceListScreenState();
}

class _OBHSAttendanceListScreenState extends State<OBHSAttendanceListScreen> {
  List<Map<String, dynamic>> _records = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final records = await OBHSRepository.getAttendanceList();
      if (mounted) setState(() { _records = records; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString().replaceAll('Exception: ', ''); _isLoading = false; });
    }
  }

  List<Map<String, dynamic>> get _filteredRecords {
    if (_searchQuery.isEmpty) return _records;
    final q = _searchQuery.toLowerCase();
    return _records.where((r) =>
      (r['workerName'] ?? '').toString().toLowerCase().contains(q) ||
      (r['runInstanceId'] ?? '').toString().toLowerCase().contains(q) ||
      (r['identityAuditStatus'] ?? '').toString().toLowerCase().contains(q)
    ).toList();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'VERIFIED_SUCCESS': return kSuccessGreen;
      case 'MID_VERIFIED': return Colors.blue;
      case 'PENDING_VERIFICATION': return kWarningOrange;
      case 'MISMATCH_ALERT': return kErrorRed;
      case 'NOT_STARTED': return Colors.grey;
      default: return Colors.grey;
    }
  }

  String _attendanceSummary(Map<String, dynamic> record) {
    final parts = <String>[];
    if (record['isStartMarked'] == true) parts.add('Start');
    if (record['isMidMarked'] == true) parts.add('Mid');
    if (record['isEndMarked'] == true) parts.add('End');
    return parts.isEmpty ? 'No attendance' : parts.join(' → ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OBHS Attendance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: kRailwayBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAttendance),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by worker, run instance...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true, fillColor: Colors.grey.shade50,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text(_error!, style: TextStyle(color: Colors.grey.shade600)),
                          const SizedBox(height: 12),
                          ElevatedButton(onPressed: _loadAttendance, child: const Text('Retry')),
                        ],
                      ))
                    : _filteredRecords.isEmpty
                        ? Center(child: Text('No attendance records found', style: TextStyle(color: Colors.grey.shade500)))
                        : RefreshIndicator(
                            onRefresh: _loadAttendance,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                              itemCount: _filteredRecords.length,
                              itemBuilder: (context, index) {
                                final r = _filteredRecords[index];
                                final status = r['identityAuditStatus'] ?? 'NOT_STARTED';
                                return Card(
                                  margin: const EdgeInsets.only(top: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 1,
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 20,
                                              backgroundColor: kRailwayBlue.withOpacity(0.1),
                                              child: Text(
                                                (r['workerName'] ?? '?').toString().substring(0, 1).toUpperCase(),
                                                style: const TextStyle(fontWeight: FontWeight.bold, color: kRailwayBlue),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(r['workerName'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                                  Text('Run: ${(r['runInstanceId'] ?? '').toString().length > 20 ? '...${(r['runInstanceId'] ?? '').toString().substring((r['runInstanceId'] ?? '').toString().length - 20)}' : (r['runInstanceId'] ?? '')}',
                                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: _statusColor(status).withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(status.replaceAll('_', ' '), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _statusColor(status))),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            _attendanceChip('Start', r['isStartMarked'] == true),
                                            const SizedBox(width: 8),
                                            _attendanceChip('Mid', r['isMidMarked'] == true),
                                            const SizedBox(width: 8),
                                            _attendanceChip('End', r['isEndMarked'] == true),
                                          ],
                                        ),
                                        if (r['updatedAt'] != null) ...[
                                          const SizedBox(height: 8),
                                          Text('Last updated: ${r['updatedAt']}', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                                        ],
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

  Widget _attendanceChip(String label, bool marked) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: marked ? kSuccessGreen.withOpacity(0.15) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(marked ? Icons.check_circle : Icons.radio_button_unchecked, size: 14, color: marked ? kSuccessGreen : Colors.grey),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: marked ? kSuccessGreen : Colors.grey.shade600)),
        ],
      ),
    );
  }
}