import 'package:flutter/material.dart';
import 'package:crm_train/model/frequency_model.dart';
import 'package:crm_train/repositories/frequency_repository.dart';
import 'package:crm_train/utills/app_colors.dart';
import 'frequency_form_screen.dart';

class FrequencyListScreen extends StatefulWidget {
  const FrequencyListScreen({super.key});

  @override
  State<FrequencyListScreen> createState() => _FrequencyListScreenState();
}

class _FrequencyListScreenState extends State<FrequencyListScreen> {
  List<Frequency> _all = [];
  List<Frequency> _filtered = [];
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
      _all = await FrequencyRepository.getAll();
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
      _filtered = _all.where((f) {
        if (_query.isEmpty) return true;
        final q = _query.toLowerCase();
        return f.frequencyName.toLowerCase().contains(q);
      }).toList();
    });
  }

  Color _statusColor(Frequency f) {
    return f.status == 'active' ? kSuccessGreen : Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Frequency Master', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                              hintText: 'Search frequencies...',
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
                              ? const Center(child: Text('No frequencies found'))
                              : ListView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  itemCount: _filtered.length,
                                  itemBuilder: (context, i) {
                                    final f = _filtered[i];
                                    return Card(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      margin: const EdgeInsets.only(bottom: 12),
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.all(16),
                                        title: Text(f.frequencyName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 4),
                                            if (f.timesPerDay > 0)
                                              Text('${f.timesPerDay}x per day', style: const TextStyle(color: kTextSecondary, fontSize: 13)),
                                            if (f.daysBetween > 0)
                                              Text('Every ${f.daysBetween} days', style: const TextStyle(color: kTextSecondary, fontSize: 13)),
                                            const SizedBox(height: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: _statusColor(f).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(f.status, style: TextStyle(color: _statusColor(f), fontWeight: FontWeight.bold, fontSize: 12)),
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
                                                  MaterialPageRoute(builder: (_) => FrequencyFormScreen(existing: f)),
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
                                                    title: const Text('Delete Frequency'),
                                                    content: Text('Delete "${f.frequencyName}"?'),
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
                                                if (confirm == true && f.uid != null) {
                                                  try {
                                                    await FrequencyRepository.delete(f.uid!);
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(content: Text('Frequency deleted'), backgroundColor: kSuccessGreen),
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
          final r = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const FrequencyFormScreen()));
          if (r == true) _load();
        },
      ),
    );
  }
}
