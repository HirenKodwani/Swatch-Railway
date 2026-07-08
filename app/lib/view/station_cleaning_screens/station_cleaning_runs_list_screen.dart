import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../model/station_run_model.dart';
import '../../repositories/station_run_repository.dart';
import '../../utills/app_colors.dart';
import 'station_cleaning_create_run_screen.dart';

class StationCleaningRunsListScreen extends StatefulWidget {
  const StationCleaningRunsListScreen({super.key});

  @override
  State<StationCleaningRunsListScreen> createState() => _StationCleaningRunsListScreenState();
}

class _StationCleaningRunsListScreenState extends State<StationCleaningRunsListScreen> {
  List<StationCleaningRunModel> allInstances = [];
  List<StationCleaningRunModel> filteredInstances = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadRuns();
  }

  Future<void> _loadRuns() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final instances = await StationRunRepository.getAllStationRuns();
      if (mounted) {
        setState(() {
          allInstances = instances;
          _isLoading = false;
          _applyFilters();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    setState(() {
      filteredInstances = allInstances.where((instance) {
        return _searchQuery.isEmpty ||
            instance.stationName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            instance.runInstanceId.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    });
  }

  void _navigateToCreate() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const StationCleaningCreateRunScreen()),
    ).then((result) {
      if (result == true) _loadRuns();
    });
  }

  void _editInstance(StationCleaningRunModel instance) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => StationCleaningCreateRunScreen(editInstance: instance)),
    ).then((result) {
      if (result == true) _loadRuns();
    });
  }

  Future<void> _deleteInstance(StationCleaningRunModel instance) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Run'),
        content: Text('Delete run instance ${instance.runInstanceId}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: kErrorRed),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
      await StationRunRepository.deleteStationRun(instance.id ?? instance.runInstanceId);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted successfully'), backgroundColor: kSuccessGreen));
        _loadRuns();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: kErrorRed));
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active': return kSuccessGreen;
      case 'pending': return kWarningOrange;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Station Cleaning Runs', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: kRailwayBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _loadRuns),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: kErrorRed, size: 60),
                    const SizedBox(height: 16),
                    Text(_error!, style: const TextStyle(color: kErrorRed)),
                    ElevatedButton(onPressed: _loadRuns, child: const Text('Retry'))
                  ],
                ))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search station or ID...',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        onChanged: (v) { _searchQuery = v; _applyFilters(); },
                      ),
                    ),
                    Expanded(
                      child: filteredInstances.isEmpty
                          ? const Center(child: Text('No runs found.'))
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: filteredInstances.length,
                              itemBuilder: (context, index) {
                                final item = filteredInstances[index];
                                return Card(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(16),
                                    title: Text('${item.runInstanceId} - ${item.stationName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 8),
                                        Text('Date: ${item.date} | Shift: ${item.shift}'),
                                        Text('Platforms Assigned: ${item.platforms.length}'),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(color: _getStatusColor(item.status).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                                          child: Text(item.status, style: TextStyle(color: _getStatusColor(item.status), fontWeight: FontWeight.bold, fontSize: 12)),
                                        )
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _editInstance(item)),
                                        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteInstance(item)),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreate,
        backgroundColor: kRailwayBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Create Run', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
