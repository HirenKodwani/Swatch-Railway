import 'package:crm_train/model/station_cleaning_models.dart';
import 'package:crm_train/repositories/inspection_repository.dart';
import 'package:crm_train/utills/app_colors.dart';
import 'package:flutter/material.dart';
import 'inspection_form_screen.dart';

class InspectionListScreen extends StatefulWidget {
  final String stationId;
  final String stationName;
  const InspectionListScreen({super.key, required this.stationId, required this.stationName});

  @override
  State<InspectionListScreen> createState() => _InspectionListScreenState();
}

class _InspectionListScreenState extends State<InspectionListScreen> {
  bool _isLoading = false;
  String _selectedStatus = 'all';
  DateTime _selectedDate = DateTime.now();
  List<StationInspection> _inspections = [];

  @override
  void initState() {
    super.initState();
    _loadInspections();
  }

  Future<void> _loadInspections() async {
    setState(() => _isLoading = true);
    try {
      final formattedDate =
          "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";
      final query = {
        'stationId': widget.stationId,
        'date': formattedDate,
        if (_selectedStatus != 'all') 'status': _selectedStatus,
      };
      final list = await InspectionRepository.list(query);
      setState(() => _inspections = list);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load inspections: $e'), backgroundColor: kErrorRed),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Color _statusColor(String status) {
    switch (InspectionStatus.values.firstWhere((e) => e.name == status, orElse: () => InspectionStatus.scheduled)) {
      case InspectionStatus.scheduled:
        return Colors.grey;
      case InspectionStatus.inProgress:
        return Colors.blue;
      case InspectionStatus.completed:
        return Colors.teal;
      case InspectionStatus.approved:
        return kSuccessGreen;
      case InspectionStatus.rejected:
        return kErrorRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inspections - ${widget.stationName}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: kRailwayBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadInspections),
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
                      value: _selectedStatus,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All Status')),
                        DropdownMenuItem(value: 'scheduled', child: Text('Scheduled')),
                        DropdownMenuItem(value: 'inProgress', child: Text('In Progress')),
                        DropdownMenuItem(value: 'completed', child: Text('Completed')),
                        DropdownMenuItem(value: 'approved', child: Text('Approved')),
                        DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedStatus = val);
                          _loadInspections();
                        }
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today, color: kRailwayBlue),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 90)),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                        _loadInspections();
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
                : _inspections.isEmpty
                    ? const Center(child: Text('No inspections found'))
                    : RefreshIndicator(
                        onRefresh: _loadInspections,
                        child: ListView.builder(
                          itemCount: _inspections.length,
                          itemBuilder: (context, idx) {
                            final insp = _inspections[idx];
                            final statusEnum = InspectionStatus.values.firstWhere(
                              (e) => e.name == insp.status,
                              orElse: () => InspectionStatus.scheduled,
                            );
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: ListTile(
                                title: Text('${insp.inspectionType.toUpperCase()} Inspection', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Inspector: ${insp.inspectorName}'),
                                    Text('Date: ${insp.scheduledDate}'),
                                    Text('Deficiencies: ${insp.deficiencies.length}', style: const TextStyle(color: kErrorRed, fontSize: 12)),
                                  ],
                                ),
                                isThreeLine: true,
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _statusColor(insp.status).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: _statusColor(insp.status)),
                                  ),
                                  child: Text(
                                    statusEnum.name.toUpperCase(),
                                    style: TextStyle(color: _statusColor(insp.status), fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => InspectionFormScreen(
                                        inspection: insp,
                                        stationId: widget.stationId,
                                        stationName: widget.stationName,
                                      ),
                                    ),
                                  ).then((_) => _loadInspections());
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
              builder: (_) => InspectionFormScreen(
                stationId: widget.stationId,
                stationName: widget.stationName,
              ),
            ),
          ).then((_) => _loadInspections());
        },
      ),
    );
  }
}
