import 'package:crm_train/model/station_cleaning_models.dart';
import 'package:crm_train/repositories/garbage_repository.dart';
import 'package:crm_train/utills/app_colors.dart';
import 'package:flutter/material.dart';
import 'garbage_form_screen.dart';

class GarbageManagementScreen extends StatefulWidget {
  final String stationId;
  final String stationName;
  const GarbageManagementScreen({super.key, required this.stationId, required this.stationName});

  @override
  State<GarbageManagementScreen> createState() => _GarbageManagementScreenState();
}

class _GarbageManagementScreenState extends State<GarbageManagementScreen> {
  bool _isLoading = false;
  List<GarbageCollection> _records = [];
  DateTime _filterDate = DateTime.now();
  String? _filterStatus;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final query = <String, String>{
        'stationId': widget.stationId,
        'date': '${_filterDate.year}-${_filterDate.month.toString().padLeft(2, '0')}-${_filterDate.day.toString().padLeft(2, '0')}',
      };
      if (_filterStatus != null) query['status'] = _filterStatus!;
      final list = await GarbageRepository.listStationGarbage(query);
      setState(() => _records = list);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load garbage records: $e'), backgroundColor: kErrorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'RECORDED':
        return kRailwayBlue;
      case 'VERIFIED':
        return kWarningOrange;
      case 'APPROVED':
        return kSuccessGreen;
      case 'DISPOSED':
        return Colors.grey;
      case 'REJECTED':
        return kErrorRed;
      default:
        return Colors.grey;
    }
  }

  double get _totalWet => _records.fold(0, (sum, r) => sum + r.wetKg);
  double get _totalDry => _records.fold(0, (sum, r) => sum + r.dryKg);
  double get _totalHazardous => _records.fold(0, (sum, r) => sum + r.hazardousKg);

  Future<void> _performAction(GarbageCollection record, String newStatus) async {
    setState(() => _isLoading = true);
    try {
      await GarbageRepository.recordStationGarbage({
        'uid': record.uid,
        'status': newStatus,
        'stationId': widget.stationId,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to $newStatus'), backgroundColor: kSuccessGreen),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action failed: $e'), backgroundColor: kErrorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Widget> _actionButtons(GarbageCollection record) {
    final status = record.status.toUpperCase();
    final buttons = <Widget>[];
    if (status == 'RECORDED') {
      buttons.add(ElevatedButton(
        onPressed: () => _performAction(record, 'verified'),
        style: ElevatedButton.styleFrom(backgroundColor: kWarningOrange, foregroundColor: Colors.white),
        child: const Text('Verify'),
      ));
    }
    if (status == 'VERIFIED') {
      buttons.add(ElevatedButton(
        onPressed: () => _performAction(record, 'approved'),
        style: ElevatedButton.styleFrom(backgroundColor: kSuccessGreen, foregroundColor: Colors.white),
        child: const Text('Approve'),
      ));
    }
    if (status == 'APPROVED') {
      buttons.add(ElevatedButton(
        onPressed: () => _performAction(record, 'disposed'),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.grey, foregroundColor: Colors.white),
        child: const Text('Mark Disposed'),
      ));
    }
    if (status == 'RECORDED' || status == 'VERIFIED') {
      buttons.add(ElevatedButton(
        onPressed: () => _performAction(record, 'rejected'),
        style: ElevatedButton.styleFrom(backgroundColor: kErrorRed, foregroundColor: Colors.white),
        child: const Text('Reject'),
      ));
    }
    return buttons;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Garbage - ${widget.stationName}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: kRailwayBlue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.delete_sweep, color: kRailwayBlue),
                      const SizedBox(width: 8),
                      const Text('Total Waste Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.calendar_today, color: kRailwayBlue),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _filterDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 90)),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() => _filterDate = picked);
                            _load();
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _summaryTile('Wet', _totalWet, Colors.brown),
                      _summaryTile('Dry', _totalDry, Colors.blueGrey),
                      _summaryTile('Hazardous', _totalHazardous, kErrorRed),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: DropdownButton<String>(
                value: _filterStatus,
                hint: const Text('All Status'),
                isExpanded: true,
                items: GarbageStatus.values.map((s) => DropdownMenuItem(
                  value: s.name,
                  child: Text(s.name.toUpperCase()),
                )).toList()..insert(0, const DropdownMenuItem(value: null, child: Text('All Status'))),
                onChanged: (val) {
                  setState(() => _filterStatus = val);
                  _load();
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _records.isEmpty
                    ? const Center(child: Text('No garbage records found'))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          itemCount: _records.length,
                          itemBuilder: (context, idx) {
                            final record = _records[idx];
                            final color = _statusColor(record.status);
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: ListTile(
                                title: Text(record.collectionDate, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('Wet: ${record.wetKg}kg | Dry: ${record.dryKg}kg | Haz: ${record.hazardousKg}kg${record.disposalAgency != null ? ' | ${record.disposalAgency}' : ''}'),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: color),
                                  ),
                                  child: Text(record.status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                                onTap: () {
                                  final buttons = _actionButtons(record);
                                  if (buttons.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('No actions available for this record')),
                                    );
                                    return;
                                  }
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: Text('${record.collectionDate} - ${record.status.toUpperCase()}'),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Collected by: ${record.collectedBy}'),
                                          Text('Wet: ${record.wetKg}kg | Dry: ${record.dryKg}kg | Hazardous: ${record.hazardousKg}kg'),
                                          if (record.disposalAgency != null) Text('Agency: ${record.disposalAgency}'),
                                          if (record.vehicleNumber != null) Text('Vehicle: ${record.vehicleNumber}'),
                                          const SizedBox(height: 16),
                                          ...buttons,
                                        ],
                                      ),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
                                      ],
                                    ),
                                  );
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
              builder: (_) => GarbageFormScreen(
                stationId: widget.stationId,
                stationName: widget.stationName,
              ),
            ),
          ).then((_) => _load());
        },
      ),
    );
  }

  Widget _summaryTile(String label, double value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 4),
        Text('${value.toStringAsFixed(1)} kg', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}
