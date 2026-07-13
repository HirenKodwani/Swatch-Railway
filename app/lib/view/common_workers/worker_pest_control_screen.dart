import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utills/app_colors.dart';
import '../../services/api_services.dart';

class WorkerPestControlScreen extends StatefulWidget {
  final String? stationId;
  final String? stationName;

  const WorkerPestControlScreen({super.key, this.stationId, this.stationName});

  @override
  State<WorkerPestControlScreen> createState() => _WorkerPestControlScreenState();
}

class _WorkerPestControlScreenState extends State<WorkerPestControlScreen> {
  bool _isLoading = false;
  bool _isRecording = false;
  List _records = [];
  String? _error;

  final _formKey = GlobalKey<FormState>();
  final _areaCtrl = TextEditingController();
  final _zoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _chemicalsCtrl = TextEditingController();
  String _pestType = 'Rodent';
  String _severity = 'LOW';

  final _pestTypes = ['Rodent', 'Cockroach', 'Mosquito', 'Fly', 'Termite', 'Ant', 'Lizard', 'Other'];
  final _severities = ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'];
  final _treatments = ['Baiting', 'Spraying', 'Fumigation', 'Trapping', 'Sealing', 'Other'];

  String _treatmentMethod = 'Baiting';

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final token = await _getAuthToken();
      if (token == null) {
        setState(() { _records = []; _isLoading = false; });
        return;
      }
      final resp = await http.get(
        Uri.parse('${ApiService.baseUrl}/api/station-pest-control/records'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (mounted) {
        if (resp.statusCode == 200) {
          final data = json.decode(resp.body);
          setState(() { _records = data['data'] ?? []; _isLoading = false; });
        } else {
          setState(() { _error = 'Failed to load: ${resp.statusCode}'; _isLoading = false; });
        }
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token') ?? prefs.getString('token');
  }

  Future<void> _submitRecord() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isRecording = true);
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('Not logged in');
      final body = {
        'stationId': widget.stationId ?? 'current_station_id',
        'stationName': widget.stationName ?? 'Current Station',
        'area': _areaCtrl.text,
        'zone': _zoneCtrl.text,
        'pestType': _pestType,
        'severity': _severity,
        'treatmentMethod': _treatmentMethod,
        'chemicalsUsed': _chemicalsCtrl.text.isNotEmpty ? _chemicalsCtrl.text.split(',').map((e) => e.trim()).toList() : [],
        'notes': _notesCtrl.text,
      };
      final resp = await http.post(
        Uri.parse('${ApiService.baseUrl}/api/station-pest-control/record'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: json.encode(body),
      );
      if (mounted) {
        if (resp.statusCode == 201 || resp.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pest control record submitted'), backgroundColor: Colors.green));
          Navigator.pop(context);
          _loadRecords();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${resp.body}'), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isRecording = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.stationName != null ? 'Pest Control - ${widget.stationName}' : 'Pest / Rodent Control', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: kRailwayBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.add, color: Colors.white), onPressed: () => _showRecordDialog()),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bug_report_outlined, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      const Text('No pest control records yet', style: TextStyle(color: Colors.grey, fontSize: 16)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _showRecordDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('Record Pest Activity'),
                        style: ElevatedButton.styleFrom(backgroundColor: kRailwayBlue, foregroundColor: Colors.white),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _records.length,
                  itemBuilder: (context, index) => Card(
                    child: ListTile(
                      leading: Icon(Icons.bug_report, color: kRailwayBlue),
                      title: Text(_records[index]['pestType'] ?? 'Unknown'),
                      subtitle: Text('Area: ${_records[index]['area'] ?? 'N/A'}'),
                      trailing: Text(_records[index]['status'] ?? ''),
                    ),
                  ),
                ),
    );
  }

  void _showRecordDialog() {
    _areaCtrl.clear();
    _zoneCtrl.clear();
    _notesCtrl.clear();
    _chemicalsCtrl.clear();
    _pestType = 'Rodent';
    _severity = 'LOW';
    _treatmentMethod = 'Baiting';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 20, right: 20, top: 20,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Record Pest / Rodent Activity', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _pestType,
                  decoration: const InputDecoration(labelText: 'Pest Type', border: OutlineInputBorder()),
                  items: _pestTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => setState(() => _pestType = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _severity,
                  decoration: const InputDecoration(labelText: 'Severity', border: OutlineInputBorder()),
                  items: _severities.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setState(() => _severity = v!),
                ),
                const SizedBox(height: 12),
                TextFormField(controller: _areaCtrl, decoration: const InputDecoration(labelText: 'Area / Location', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextFormField(controller: _zoneCtrl, decoration: const InputDecoration(labelText: 'Zone', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _treatmentMethod,
                  decoration: const InputDecoration(labelText: 'Treatment Method', border: OutlineInputBorder()),
                  items: _treatments.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => setState(() => _treatmentMethod = v!),
                ),
                const SizedBox(height: 12),
                TextFormField(controller: _chemicalsCtrl, decoration: const InputDecoration(labelText: 'Chemicals Used (comma separated)', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextFormField(controller: _notesCtrl, decoration: const InputDecoration(labelText: 'Additional Notes', border: OutlineInputBorder()), maxLines: 3),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isRecording ? null : _submitRecord,
                    child: _isRecording ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Submit Record'),
                    style: ElevatedButton.styleFrom(backgroundColor: kRailwayBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}