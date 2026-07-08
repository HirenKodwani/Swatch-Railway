import 'package:flutter/material.dart';
import 'package:crm_train/model/station_models.dart';
import 'package:crm_train/services/api_services.dart';
import 'package:crm_train/utills/app_colors.dart';
import 'station_cleaning_form_screen.dart';

class StationCleaningFormListScreen extends StatefulWidget {
  final String stationId;
  final String stationName;
  const StationCleaningFormListScreen({super.key, required this.stationId, required this.stationName});

  @override
  State<StationCleaningFormListScreen> createState() => _StationCleaningFormListScreenState();
}

class _StationCleaningFormListScreenState extends State<StationCleaningFormListScreen> {
  bool _isLoading = false;
  String _selectedStatus = 'all';
  List<StationCleaningForm> _forms = [];

  @override
  void initState() {
    super.initState();
    _loadForms();
  }

  Future<void> _loadForms() async {
    setState(() => _isLoading = true);
    try {
      final list = await ApiService.getStationCleaningForms(
        stationId: widget.stationId,
        status: _selectedStatus != 'all' ? _selectedStatus : null,
      );
      setState(() => _forms = list);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load forms: $e'), backgroundColor: kErrorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _statusColor(StationFormStatus status) {
    switch (status) {
      case StationFormStatus.draft: return Colors.grey;
      case StationFormStatus.submitted: return kWarningOrange;
      case StationFormStatus.approved: return kSuccessGreen;
      case StationFormStatus.scored: return Colors.purple;
      case StationFormStatus.locked: return Colors.blueGrey;
      case StationFormStatus.rejected: return kErrorRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cleaning Forms - ${widget.stationName}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: kRailwayBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadForms)],
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: DropdownButton<String>(
                value: _selectedStatus,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Statuses')),
                  DropdownMenuItem(value: 'draft', child: Text('Draft')),
                  DropdownMenuItem(value: 'submitted', child: Text('Submitted')),
                  DropdownMenuItem(value: 'approved', child: Text('Approved')),
                  DropdownMenuItem(value: 'scored', child: Text('Scored')),
                  DropdownMenuItem(value: 'locked', child: Text('Locked')),
                  DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                ],
                onChanged: (v) { if (v != null) setState(() => _selectedStatus = v); _loadForms(); },
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _forms.isEmpty
                    ? const Center(child: Text('No cleaning forms found'))
                    : RefreshIndicator(
                        onRefresh: _loadForms,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _forms.length,
                          itemBuilder: (context, i) {
                            final f = _forms[i];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(
                                    builder: (_) => StationCleaningFormScreen(
                                      stationId: widget.stationId,
                                      stationName: widget.stationName,
                                      existing: f,
                                    ),
                                  )).then((_) => _loadForms());
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [
                                        Expanded(
                                          child: Text(f.formId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _statusColor(f.status).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: _statusColor(f.status)),
                                          ),
                                          child: Text(f.statusLabel, style: TextStyle(color: _statusColor(f.status), fontSize: 11, fontWeight: FontWeight.bold)),
                                        ),
                                      ]),
                                      const SizedBox(height: 6),
                                      Text('Area: ${f.areaName} | Shift: ${f.shift.toUpperCase()}', style: const TextStyle(color: kTextSecondary, fontSize: 13)),
                                      const SizedBox(height: 4),
                                      Row(children: [
                                        Text('Date: ${f.cleaningDate}', style: const TextStyle(fontSize: 12, color: kTextSecondary)),
                                        const Spacer(),
                                        if (f.score != null) Text('Score: ${f.score!.toStringAsFixed(0)}%  ${f.grade ?? ''}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _statusColor(f.status))),
                                      ]),
                                    ],
                                  ),
                                ),
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
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => StationCleaningFormScreen(
              stationId: widget.stationId,
              stationName: widget.stationName,
            ),
          )).then((_) => _loadForms());
        },
      ),
    );
  }
}
