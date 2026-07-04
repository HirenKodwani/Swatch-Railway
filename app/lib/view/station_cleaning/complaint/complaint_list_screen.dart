import 'package:crm_train/model/station_cleaning_models.dart';
import 'package:crm_train/repositories/complaint_repository.dart';
import 'package:crm_train/utills/app_colors.dart';
import 'package:flutter/material.dart';
import 'complaint_form_screen.dart';

class ComplaintListScreen extends StatefulWidget {
  final String stationId;
  final String stationName;
  const ComplaintListScreen({super.key, required this.stationId, required this.stationName});

  @override
  State<ComplaintListScreen> createState() => _ComplaintListScreenState();
}

class _ComplaintListScreenState extends State<ComplaintListScreen> {
  bool _isLoading = false;
  String _selectedStatus = 'all';
  List<Complaint> _complaints = [];

  @override
  void initState() {
    super.initState();
    _loadComplaints();
  }

  Future<void> _loadComplaints() async {
    setState(() => _isLoading = true);
    try {
      final query = {
        'stationId': widget.stationId,
        if (_selectedStatus != 'all') 'status': _selectedStatus,
      };
      final list = await ComplaintRepository.list(query);
      setState(() => _complaints = list);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load complaints: $e'), backgroundColor: kErrorRed),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Color _statusColor(String status) {
    switch (ComplaintStatus.values.firstWhere((e) => e.name == status, orElse: () => ComplaintStatus.reported)) {
      case ComplaintStatus.reported:
        return kErrorRed;
      case ComplaintStatus.assigned:
        return kWarningOrange;
      case ComplaintStatus.inProgress:
        return Colors.blue;
      case ComplaintStatus.resolved:
        return Colors.teal;
      case ComplaintStatus.closed:
        return kSuccessGreen;
      case ComplaintStatus.reopened:
        return Colors.purple;
      case ComplaintStatus.rejected:
        return Colors.grey;
      case ComplaintStatus.escalated:
        return const Color(0xFFB71C1C);
      case ComplaintStatus.railwayVerified:
        return kSuccessGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Complaints - ${widget.stationName}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: kRailwayBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadComplaints),
        ],
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: DropdownButton<String>(
                value: _selectedStatus,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Status')),
                  DropdownMenuItem(value: 'reported', child: Text('Reported')),
                  DropdownMenuItem(value: 'assigned', child: Text('Assigned')),
                  DropdownMenuItem(value: 'inProgress', child: Text('In Progress')),
                  DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                  DropdownMenuItem(value: 'closed', child: Text('Closed')),
                  DropdownMenuItem(value: 'reopened', child: Text('Reopened')),
                  DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                  DropdownMenuItem(value: 'escalated', child: Text('Escalated')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedStatus = val);
                    _loadComplaints();
                  }
                },
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _complaints.isEmpty
                    ? const Center(child: Text('No complaints found'))
                    : RefreshIndicator(
                        onRefresh: _loadComplaints,
                        child: ListView.builder(
                          itemCount: _complaints.length,
                          itemBuilder: (context, idx) {
                            final comp = _complaints[idx];
                            final statusEnum = ComplaintStatus.values.firstWhere(
                              (e) => e.name == comp.status,
                              orElse: () => ComplaintStatus.reported,
                            );
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              shape: comp.slaBreached
                                  ? RoundedRectangleBorder(
                                      side: BorderSide(color: kErrorRed, width: 2),
                                      borderRadius: BorderRadius.circular(8),
                                    )
                                  : null,
                              child: ListTile(
                                title: Text(comp.category, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(comp.description.length > 80
                                        ? '${comp.description.substring(0, 80)}...'
                                        : comp.description),
                                    if (comp.slaDeadline != null)
                                      Text('SLA: ${comp.slaDeadline}', style: TextStyle(
                                        color: comp.slaBreached ? kErrorRed : Colors.grey,
                                        fontSize: 11,
                                      )),
                                  ],
                                ),
                                isThreeLine: true,
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _statusColor(comp.status).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: _statusColor(comp.status)),
                                  ),
                                  child: Text(
                                    statusEnum.name.toUpperCase(),
                                    style: TextStyle(color: _statusColor(comp.status), fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ComplaintFormScreen(
                                        complaint: comp,
                                        stationId: widget.stationId,
                                        stationName: widget.stationName,
                                      ),
                                    ),
                                  ).then((_) => _loadComplaints());
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
              builder: (_) => ComplaintFormScreen(
                stationId: widget.stationId,
                stationName: widget.stationName,
              ),
            ),
          ).then((_) => _loadComplaints());
        },
      ),
    );
  }
}
