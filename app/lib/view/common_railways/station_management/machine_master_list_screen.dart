import 'package:flutter/material.dart';
import 'package:crm_train/services/api_services.dart';
import 'package:crm_train/utills/app_colors.dart';
import 'machine_master_form_screen.dart';

class MachineMasterListScreen extends StatefulWidget {
  const MachineMasterListScreen({super.key});

  @override
  State<MachineMasterListScreen> createState() => _MachineMasterListScreenState();
}

class _MachineMasterListScreenState extends State<MachineMasterListScreen> {
  List _machines = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      _machines = await ApiService.getMachines();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _delete(String uid) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Machine?'),
        content: const Text('This will deactivate the machine.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: kErrorRed), child: const Text('Delete', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ApiService.deleteMachine(uid);
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: kErrorRed));
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'active': return kSuccessGreen;
      case 'inactive': return Colors.grey;
      case 'under_maintenance': return kWarningOrange;
      default: return Colors.grey;
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'active': return 'Active';
      case 'inactive': return 'Inactive';
      case 'under_maintenance': return 'Maintenance';
      default: return status ?? 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Machine Master', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: kRailwayBlue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: kErrorRed),
                      const SizedBox(height: 12),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : _machines.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.precision_manufacturing_outlined, size: 80, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          const Text('No machines registered', style: TextStyle(color: Colors.grey, fontSize: 16)),
                          const SizedBox(height: 8),
                          Text('Add machines used in station cleaning', style: TextStyle(color: Colors.grey[400])),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _machines.length,
                        itemBuilder: (context, index) {
                          final m = _machines[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: kRailwayBlue.withOpacity(0.1),
                                child: Icon(Icons.precision_manufacturing, color: kRailwayBlue),
                              ),
                              title: Text(m['machineName'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${m['machineType'] ?? ''} | ${m['serialNumber'] ?? ''}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _statusColor(m['status']).withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(_statusLabel(m['status']), style: TextStyle(fontSize: 11, color: _statusColor(m['status']), fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 4),
                                  PopupMenuButton<String>(
                                    onSelected: (v) {
                                      if (v == 'edit') {
                                        Navigator.push(context, MaterialPageRoute(builder: (_) => MachineMasterFormScreen(machine: m)));
                                      } else if (v == 'delete') {
                                        _delete(m['uid'] ?? '');
                                      }
                                    },
                                    itemBuilder: (_) => [
                                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                                    ],
                                  ),
                                ],
                              ),
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MachineMasterFormScreen(machine: m))),
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MachineMasterFormScreen())),
        backgroundColor: kRailwayBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
