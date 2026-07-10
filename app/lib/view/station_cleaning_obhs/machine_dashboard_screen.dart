import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../model/station_cleaning_models.dart';
import '../../repositories/machine_tracking_repository.dart';
import '../../services/api_services.dart';
import '../../utills/app_colors.dart';

class MachineDashboardScreen extends StatefulWidget {
  const MachineDashboardScreen({super.key});

  @override
  State<MachineDashboardScreen> createState() => _MachineDashboardScreenState();
}

class _MachineDashboardScreenState extends State<MachineDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<MachineDeployment> _deployments = [];
  List<MachineDowntime> _downtimes = [];
  List<MachineMaintenance> _maintenances = [];
  List<Map<String, dynamic>> _machines = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final results = await Future.wait([
        MachineTrackingRepository.listDeployments({}),
        MachineTrackingRepository.listDowntime({}),
        MachineTrackingRepository.listMaintenance({}),
        ApiService.getMachines(),
      ]);
      if (mounted) {
        setState(() {
          _deployments = results[0] as List<MachineDeployment>;
          _downtimes = results[1] as List<MachineDowntime>;
          _maintenances = results[2] as List<MachineMaintenance>;
          _machines = (results[3] as List).map<Map<String, dynamic>>((e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{}).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString().replaceAll('Exception: ', ''); _isLoading = false; });
    }
  }

  Future<void> _deployMachine() async {
    final nameCtrl = TextEditingController();
    final idCtrl = TextEditingController();
    final conditionCtrl = TextEditingController(text: 'Working');
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deploy Machine'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: idCtrl, decoration: const InputDecoration(labelText: 'Machine ID', border: OutlineInputBorder(), isDense: true)),
            const SizedBox(height: 8),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Machine Name', border: OutlineInputBorder(), isDense: true)),
            const SizedBox(height: 8),
            TextField(controller: conditionCtrl, decoration: const InputDecoration(labelText: 'Condition', border: OutlineInputBorder(), isDense: true)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: kRailwayBlue),
            child: const Text('Deploy', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (result == true) {
      try {
        await MachineTrackingRepository.deploy({
          'machineId': idCtrl.text,
          'machineName': nameCtrl.text,
          'condition': conditionCtrl.text,
        });
        if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Machine deployed'), backgroundColor: kSuccessGreen)); _loadAll(); }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: kErrorRed));
      }
    }
  }

  Future<void> _returnMachine(String uid) async {
    try {
      await MachineTrackingRepository.returnMachine(uid);
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Machine returned'), backgroundColor: kSuccessGreen)); _loadAll(); }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: kErrorRed));
    }
  }

  Future<void> _logDowntime() async {
    final machineCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Downtime'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: machineCtrl, decoration: const InputDecoration(labelText: 'Machine Name', border: OutlineInputBorder(), isDense: true)),
            const SizedBox(height: 8),
            TextField(controller: reasonCtrl, decoration: const InputDecoration(labelText: 'Reason', border: OutlineInputBorder(), isDense: true), maxLines: 2),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: kWarningOrange),
            child: const Text('Log', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (result == true) {
      try {
        await MachineTrackingRepository.logDowntime({
          'machineName': machineCtrl.text,
          'reason': reasonCtrl.text,
          'startTime': DateTime.now().toIso8601String(),
        });
        if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Downtime logged'), backgroundColor: kSuccessGreen)); _loadAll(); }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: kErrorRed));
      }
    }
  }

  Future<void> _resolveDowntime(String uid) async {
    try {
      await MachineTrackingRepository.resolveDowntime(uid);
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Downtime resolved'), backgroundColor: kSuccessGreen)); _loadAll(); }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: kErrorRed));
    }
  }

  Future<void> _scheduleMaintenance() async {
    final machineCtrl = TextEditingController();
    final typeCtrl = TextEditingController(text: 'General');
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Schedule Maintenance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: machineCtrl, decoration: const InputDecoration(labelText: 'Machine Name', border: OutlineInputBorder(), isDense: true)),
            const SizedBox(height: 8),
            TextField(controller: typeCtrl, decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder(), isDense: true)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: kRailwayBlue),
            child: const Text('Schedule', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (result == true) {
      try {
        await MachineTrackingRepository.scheduleMaintenance({
          'machineName': machineCtrl.text,
          'maintenanceType': typeCtrl.text,
          'scheduledDate': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        });
        if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Maintenance scheduled'), backgroundColor: kSuccessGreen)); _loadAll(); }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: kErrorRed));
      }
    }
  }

  Future<void> _completeMaintenance(String uid) async {
    try {
      await MachineTrackingRepository.completeMaintenance(uid);
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Maintenance completed'), backgroundColor: kSuccessGreen)); _loadAll(); }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: kErrorRed));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Machine Tracking', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: kRailwayBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Deployments'),
            Tab(text: 'Downtime'),
            Tab(text: 'Maintenance'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: kErrorRed, size: 60),
                      const SizedBox(height: 16),
                      Text(_error!, style: const TextStyle(color: kErrorRed)),
                      ElevatedButton(onPressed: _loadAll, child: const Text('Retry')),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDeploymentsTab(),
                    _buildDowntimeTab(),
                    _buildMaintenanceTab(),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) _deployMachine();
          else if (_tabController.index == 1) _logDowntime();
          else _scheduleMaintenance();
        },
        backgroundColor: kRailwayBlue,
        child: Icon(
          _tabController.index == 0 ? Icons.add : _tabController.index == 1 ? Icons.warning : Icons.build,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildDeploymentsTab() {
    if (_deployments.isEmpty) {
      return const Center(child: Text('No machines deployed', style: TextStyle(color: Colors.grey)));
    }
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _deployments.length,
        itemBuilder: (_, i) {
          final d = _deployments[i];
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: d.status == 'DEPLOYED' ? kSuccessGreen.withOpacity(0.1) : Colors.grey[100],
                child: Icon(Icons.precision_manufacturing, color: d.status == 'DEPLOYED' ? kSuccessGreen : Colors.grey),
              ),
              title: Text(d.machineName, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Deployed: ${d.deployedAt}\nCondition: ${d.condition}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              trailing: d.status == 'DEPLOYED'
                  ? TextButton(onPressed: () => _returnMachine(d.uid), child: const Text('Return', style: TextStyle(fontSize: 12)))
                  : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: const Text('Returned', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDowntimeTab() {
    if (_downtimes.isEmpty) {
      return const Center(child: Text('No downtime records', style: TextStyle(color: Colors.grey)));
    }
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _downtimes.length,
        itemBuilder: (_, i) {
          final d = _downtimes[i];
          final isOpen = d.status == 'OPEN';
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isOpen ? kErrorRed.withOpacity(0.1) : kSuccessGreen.withOpacity(0.1),
                child: Icon(Icons.error_outline, color: isOpen ? kErrorRed : kSuccessGreen, size: 20),
              ),
              title: Text(d.machineName, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${d.reason}\n${d.totalHours.toStringAsFixed(1)} hrs | Penalty: \u20B9${d.penaltyAmount.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              trailing: isOpen
                  ? TextButton(onPressed: () => _resolveDowntime(d.uid), child: const Text('Resolve', style: TextStyle(fontSize: 12, color: kSuccessGreen)))
                  : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: kSuccessGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: const Text('Resolved', style: TextStyle(fontSize: 11, color: kSuccessGreen)),
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMaintenanceTab() {
    if (_maintenances.isEmpty) {
      return const Center(child: Text('No maintenance records', style: TextStyle(color: Colors.grey)));
    }
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _maintenances.length,
        itemBuilder: (_, i) {
          final m = _maintenances[i];
          final isScheduled = m.status == 'SCHEDULED' || m.status == 'scheduled';
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isScheduled ? kWarningOrange.withOpacity(0.1) : kSuccessGreen.withOpacity(0.1),
                child: Icon(Icons.build, color: isScheduled ? kWarningOrange : kSuccessGreen, size: 20),
              ),
              title: Text(m.machineName, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${m.maintenanceType} | Scheduled: ${m.scheduledDate}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              trailing: isScheduled
                  ? TextButton(onPressed: () => _completeMaintenance(m.uid), child: const Text('Complete', style: TextStyle(fontSize: 12, color: kSuccessGreen)))
                  : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: kSuccessGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: const Text('Done', style: TextStyle(fontSize: 11, color: kSuccessGreen)),
                    ),
            ),
          );
        },
      ),
    );
  }
}
