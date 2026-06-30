import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utills/app_colors.dart';
import '../../services/api_services.dart';

class WorkerMachineScreen extends StatefulWidget {
  const WorkerMachineScreen({super.key});

  @override
  State<WorkerMachineScreen> createState() => _WorkerMachineScreenState();
}

class _WorkerMachineScreenState extends State<WorkerMachineScreen> {
  bool _isLoading = false;
  List _machines = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMachines();
  }

  Future<void> _loadMachines() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      setState(() { _machines = []; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Machine / Material', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: kRailwayBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _loadMachines),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _machines.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.precision_manufacturing_outlined, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      const Text('No machines deployed', style: TextStyle(color: Colors.grey, fontSize: 16)),
                      const Text('Machines assigned by supervisor will appear here', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _machines.length,
                  itemBuilder: (context, index) {
                    final m = _machines[index];
                    return Card(
                      child: ListTile(
                        leading: Icon(Icons.precision_manufacturing, color: kRailwayBlue),
                        title: Text(m['machineName'] ?? 'Machine'),
                        subtitle: Text('Qty: ${m['quantity']} | ${m['status'] ?? 'DEPLOYED'}'),
                        trailing: Chip(label: Text(m['status'] ?? ''), backgroundColor: m['status'] == 'DEPLOYED' ? Colors.green[100] : Colors.orange[100]),
                      ),
                    );
                  },
                ),
    );
  }
}