import 'package:crm_train/model/station_cleaning_models.dart';
import 'package:crm_train/repositories/machine_tracking_repository.dart';
import 'package:crm_train/utills/app_colors.dart';
import 'package:flutter/material.dart';

class MachineTrackingScreen extends StatefulWidget {
  final String stationId;
  final String stationName;
  const MachineTrackingScreen({super.key, required this.stationId, required this.stationName});

  @override
  State<MachineTrackingScreen> createState() => _MachineTrackingScreenState();
}

class _MachineTrackingScreenState extends State<MachineTrackingScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoadingDeployments = false;
  bool _isLoadingDowntime = false;
  bool _isLoadingMaintenance = false;

  List<MachineDeployment> _deployments = [];
  List<MachineDowntime> _downtimeRecords = [];
  List<MachineMaintenance> _maintenanceRecords = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDeployments();
    _loadDowntime();
    _loadMaintenance();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _deployStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'DEPLOYED':
        return kSuccessGreen;
      case 'RETURNED':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Color _downtimeStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'OPEN':
        return kErrorRed;
      case 'RESOLVED':
        return kSuccessGreen;
      default:
        return Colors.grey;
    }
  }

  Color _maintenanceStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'SCHEDULED':
        return kWarningOrange;
      case 'COMPLETED':
        return kSuccessGreen;
      default:
        return Colors.grey;
    }
  }

  Future<void> _loadDeployments() async {
    setState(() => _isLoadingDeployments = true);
    try {
      final list = await MachineTrackingRepository.listDeployments({'stationId': widget.stationId});
      setState(() => _deployments = list);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load deployments: $e'), backgroundColor: kErrorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingDeployments = false);
    }
  }

  Future<void> _loadDowntime() async {
    setState(() => _isLoadingDowntime = true);
    try {
      final list = await MachineTrackingRepository.listDowntime({'stationId': widget.stationId});
      setState(() => _downtimeRecords = list);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load downtime: $e'), backgroundColor: kErrorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingDowntime = false);
    }
  }

  Future<void> _loadMaintenance() async {
    setState(() => _isLoadingMaintenance = true);
    try {
      final list = await MachineTrackingRepository.listMaintenance({'stationId': widget.stationId});
      setState(() => _maintenanceRecords = list);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load maintenance: $e'), backgroundColor: kErrorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingMaintenance = false);
    }
  }

  void _showDeployDialog() {
    final machineIdCtrl = TextEditingController();
    final machineNameCtrl = TextEditingController();
    final conditionCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deploy Machine'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: machineIdCtrl, decoration: const InputDecoration(labelText: 'Machine ID', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(controller: machineNameCtrl, decoration: const InputDecoration(labelText: 'Machine Name', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(controller: conditionCtrl, decoration: const InputDecoration(labelText: 'Condition', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (machineIdCtrl.text.isEmpty || machineNameCtrl.text.isEmpty) return;
              Navigator.pop(ctx);
              try {
                await MachineTrackingRepository.deploy({
                  'stationId': widget.stationId,
                  'machineId': machineIdCtrl.text.trim(),
                  'machineName': machineNameCtrl.text.trim(),
                  'condition': conditionCtrl.text.trim(),
                  'deployedAt': DateTime.now().toIso8601String(),
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Machine deployed'), backgroundColor: kSuccessGreen),
                  );
                  _loadDeployments();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Deploy failed: $e'), backgroundColor: kErrorRed),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: kRailwayBlue, foregroundColor: Colors.white),
            child: const Text('Deploy'),
          ),
        ],
      ),
    );
  }

  void _showDowntimeDialog() {
    final machineIdCtrl = TextEditingController();
    final machineNameCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    DateTime startTime = DateTime.now();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Log Downtime'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: machineIdCtrl, decoration: const InputDecoration(labelText: 'Machine ID', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(controller: machineNameCtrl, decoration: const InputDecoration(labelText: 'Machine Name', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(controller: reasonCtrl, decoration: const InputDecoration(labelText: 'Reason', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: startTime,
                    firstDate: DateTime.now().subtract(const Duration(days: 30)),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    final timePicked = await showTimePicker(
                      context: ctx,
                      initialTime: TimeOfDay.fromDateTime(startTime),
                    );
                    if (timePicked != null) {
                      setDialogState(() {
                        startTime = DateTime(picked.year, picked.month, picked.day, timePicked.hour, timePicked.minute);
                      });
                    }
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Start Time', border: OutlineInputBorder()),
                  child: Text(startTime.toString()),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (machineIdCtrl.text.isEmpty || reasonCtrl.text.isEmpty) return;
                Navigator.pop(ctx);
                try {
                  await MachineTrackingRepository.logDowntime({
                    'stationId': widget.stationId,
                    'machineId': machineIdCtrl.text.trim(),
                    'machineName': machineNameCtrl.text.trim(),
                    'reason': reasonCtrl.text.trim(),
                    'startTime': startTime.toIso8601String(),
                  });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Downtime logged'), backgroundColor: kSuccessGreen),
                    );
                    _loadDowntime();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed: $e'), backgroundColor: kErrorRed),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: kRailwayBlue, foregroundColor: Colors.white),
              child: const Text('Log'),
            ),
          ],
        ),
      ),
    );
  }

  void _showMaintenanceDialog() {
    final machineIdCtrl = TextEditingController();
    final machineNameCtrl = TextEditingController();
    final typeCtrl = TextEditingController();
    DateTime scheduledDate = DateTime.now();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Schedule Maintenance'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: machineIdCtrl, decoration: const InputDecoration(labelText: 'Machine ID', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(controller: machineNameCtrl, decoration: const InputDecoration(labelText: 'Machine Name', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(controller: typeCtrl, decoration: const InputDecoration(labelText: 'Maintenance Type', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: scheduledDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setDialogState(() => scheduledDate = picked);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Scheduled Date', border: OutlineInputBorder()),
                  child: Text('${scheduledDate.year}-${scheduledDate.month.toString().padLeft(2, '0')}-${scheduledDate.day.toString().padLeft(2, '0')}'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (machineIdCtrl.text.isEmpty || typeCtrl.text.isEmpty) return;
                Navigator.pop(ctx);
                try {
                  await MachineTrackingRepository.scheduleMaintenance({
                    'stationId': widget.stationId,
                    'machineId': machineIdCtrl.text.trim(),
                    'machineName': machineNameCtrl.text.trim(),
                    'maintenanceType': typeCtrl.text.trim(),
                    'scheduledDate': '${scheduledDate.year}-${scheduledDate.month.toString().padLeft(2, '0')}-${scheduledDate.day.toString().padLeft(2, '0')}',
                  });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Maintenance scheduled'), backgroundColor: kSuccessGreen),
                    );
                    _loadMaintenance();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed: $e'), backgroundColor: kErrorRed),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: kRailwayBlue, foregroundColor: Colors.white),
              child: const Text('Schedule'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeploymentsTab() {
    return Stack(
      children: [
        _isLoadingDeployments
            ? const Center(child: CircularProgressIndicator())
            : _deployments.isEmpty
                ? const Center(child: Text('No deployments'))
                : RefreshIndicator(
                    onRefresh: _loadDeployments,
                    child: ListView.builder(
                      itemCount: _deployments.length,
                      itemBuilder: (context, idx) {
                        final d = _deployments[idx];
                        final color = _deployStatusColor(d.status);
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: ListTile(
                            title: Text(d.machineName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Deployed: ${d.deployedAt} | ${d.condition}'),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: color),
                              ),
                              child: Text(d.status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                            onTap: d.status.toUpperCase() == 'DEPLOYED'
                                ? () async {
                                    try {
                                      await MachineTrackingRepository.returnMachine(d.uid);
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Machine returned'), backgroundColor: kSuccessGreen),
                                        );
                                        _loadDeployments();
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Failed: $e'), backgroundColor: kErrorRed),
                                        );
                                      }
                                    }
                                  }
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            mini: true,
            backgroundColor: kRailwayBlue,
            child: const Icon(Icons.add, color: Colors.white),
            onPressed: _showDeployDialog,
          ),
        ),
      ],
    );
  }

  Widget _buildDowntimeTab() {
    return Stack(
      children: [
        _isLoadingDowntime
            ? const Center(child: CircularProgressIndicator())
            : _downtimeRecords.isEmpty
                ? const Center(child: Text('No downtime records'))
                : RefreshIndicator(
                    onRefresh: _loadDowntime,
                    child: ListView.builder(
                      itemCount: _downtimeRecords.length,
                      itemBuilder: (context, idx) {
                        final d = _downtimeRecords[idx];
                        final color = _downtimeStatusColor(d.status);
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: ListTile(
                            title: Text(d.machineName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${d.reason} | ${d.totalHours}h | Penalty: \$${d.penaltyAmount.toStringAsFixed(2)}'),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: color),
                              ),
                              child: Text(d.status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                            onTap: d.status.toUpperCase() == 'OPEN'
                                ? () async {
                                    try {
                                      await MachineTrackingRepository.resolveDowntime(d.uid);
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Downtime resolved'), backgroundColor: kSuccessGreen),
                                        );
                                        _loadDowntime();
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Failed: $e'), backgroundColor: kErrorRed),
                                        );
                                      }
                                    }
                                  }
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            mini: true,
            backgroundColor: kRailwayBlue,
            child: const Icon(Icons.add, color: Colors.white),
            onPressed: _showDowntimeDialog,
          ),
        ),
      ],
    );
  }

  Widget _buildMaintenanceTab() {
    return Stack(
      children: [
        _isLoadingMaintenance
            ? const Center(child: CircularProgressIndicator())
            : _maintenanceRecords.isEmpty
                ? const Center(child: Text('No maintenance records'))
                : RefreshIndicator(
                    onRefresh: _loadMaintenance,
                    child: ListView.builder(
                      itemCount: _maintenanceRecords.length,
                      itemBuilder: (context, idx) {
                        final m = _maintenanceRecords[idx];
                        final color = _maintenanceStatusColor(m.status);
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: ListTile(
                            title: Text(m.machineName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${m.maintenanceType} | ${m.scheduledDate}'),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: color),
                              ),
                              child: Text(m.status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                            onTap: m.status.toUpperCase() == 'SCHEDULED'
                                ? () async {
                                    try {
                                      await MachineTrackingRepository.completeMaintenance(m.uid);
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Maintenance completed'), backgroundColor: kSuccessGreen),
                                        );
                                        _loadMaintenance();
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Failed: $e'), backgroundColor: kErrorRed),
                                        );
                                      }
                                    }
                                  }
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            mini: true,
            backgroundColor: kRailwayBlue,
            child: const Icon(Icons.add, color: Colors.white),
            onPressed: _showMaintenanceDialog,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Machines - ${widget.stationName}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: kRailwayBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Deployments'),
            Tab(text: 'Downtime'),
            Tab(text: 'Maintenance'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDeploymentsTab(),
          _buildDowntimeTab(),
          _buildMaintenanceTab(),
        ],
      ),
    );
  }
}
