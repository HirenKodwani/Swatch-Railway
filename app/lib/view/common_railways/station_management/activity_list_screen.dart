import 'package:flutter/material.dart';
import 'package:crm_train/model/activity_model.dart';
import 'package:crm_train/repositories/activity_repository.dart';
import 'package:crm_train/utills/app_colors.dart';
import 'activity_form_screen.dart';

class ActivityListScreen extends StatefulWidget {
  const ActivityListScreen({super.key});

  @override
  State<ActivityListScreen> createState() => _ActivityListScreenState();
}

class _ActivityListScreenState extends State<ActivityListScreen> {
  List<Activity> _all = [];
  List<Activity> _filtered = [];
  bool _isLoading = true;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      _all = await ActivityRepository.getAll();
      _applyFilter();
    } catch (e) {
      if (e.toString().contains('AUTH_ERROR')) {
        _error = 'AUTH_ERROR';
      } else {
        _error = e.toString();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    setState(() {
      _filtered = _all.where((a) {
        if (_query.isEmpty) return true;
        final q = _query.toLowerCase();
        return a.activityName.toLowerCase().contains(q) ||
            a.activityType.toLowerCase().contains(q);
      }).toList();
    });
  }

  Color _statusColor(Activity a) {
    return a.status == 'active' ? kSuccessGreen : Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Master', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: kRailwayBlue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error == 'AUTH_ERROR'
              ? const Center(child: Text('Authentication error'))
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
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Search activities...',
                              prefixIcon: const Icon(Icons.search),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                            onChanged: (v) { _query = v; _applyFilter(); },
                          ),
                        ),
                        Expanded(
                          child: _filtered.isEmpty
                              ? const Center(child: Text('No activities found'))
                              : ListView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  itemCount: _filtered.length,
                                  itemBuilder: (context, i) {
                                    final a = _filtered[i];
                                    return Card(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      margin: const EdgeInsets.only(bottom: 12),
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.all(16),
                                        title: Text(a.activityName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 4),
                                            Text('Type: ${a.activityType}', style: const TextStyle(color: kTextSecondary, fontSize: 13)),
                                            if (a.unit.isNotEmpty) Text('Unit: ${a.unit}', style: const TextStyle(color: kTextSecondary, fontSize: 13)),
                                            const SizedBox(height: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: _statusColor(a).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(a.status, style: TextStyle(color: _statusColor(a), fontWeight: FontWeight.bold, fontSize: 12)),
                                            ),
                                          ],
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit, color: Colors.blue),
                                              onPressed: () async {
                                                final r = await Navigator.push<bool>(
                                                  context,
                                                  MaterialPageRoute(builder: (_) => ActivityFormScreen(existing: a)),
                                                );
                                                if (r == true) _load();
                                              },
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete, color: kErrorRed),
                                              onPressed: () async {
                                                final confirm = await showDialog<bool>(
                                                  context: context,
                                                  builder: (ctx) => AlertDialog(
                                                    title: const Text('Delete Activity'),
                                                    content: Text('Delete "${a.activityName}"?'),
                                                    actions: [
                                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                                      ElevatedButton(
                                                        onPressed: () => Navigator.pop(ctx, true),
                                                        style: ElevatedButton.styleFrom(backgroundColor: kErrorRed),
                                                        child: const Text('Delete', style: TextStyle(color: Colors.white)),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                                if (confirm == true && a.uid != null) {
                                                  try {
                                                    await ActivityRepository.delete(a.uid!);
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(content: Text('Activity deleted'), backgroundColor: kSuccessGreen),
                                                    );
                                                    _load();
                                                  } catch (e) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(content: Text('Error: $e'), backgroundColor: kErrorRed),
                                                    );
                                                  }
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: kRailwayBlue,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          final r = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const ActivityFormScreen()));
          if (r == true) _load();
        },
      ),
    );
  }
}
