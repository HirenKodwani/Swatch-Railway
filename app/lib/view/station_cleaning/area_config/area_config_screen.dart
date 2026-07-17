import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crm_train/model/platform_model.dart';
import 'package:crm_train/repositories/platform_repository.dart';
import 'package:crm_train/services/api_services.dart';
import 'package:crm_train/helper/api_error_handler.dart';
import 'package:crm_train/utills/app_colors.dart';

class AreaConfigScreen extends StatefulWidget {
  final String stationId;
  final String stationName;
  final String? platformId;

  const AreaConfigScreen({
    super.key,
    required this.stationId,
    required this.stationName,
    this.platformId,
  });

  @override
  State<AreaConfigScreen> createState() => _AreaConfigScreenState();
}

class _AreaConfigScreenState extends State<AreaConfigScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _areas = [];
  List<Platform> _platforms = [];
  Platform? _selectedPlatform;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPlatforms();
  }

  Future<void> _loadPlatforms() async {
    try {
      final platforms = await PlatformRepository.getByStation(widget.stationId);
      Platform? preSelected;
      if (widget.platformId != null) {
        preSelected = platforms.where((p) => p.uid == widget.platformId).firstOrNull;
      }
      if (mounted) {
        setState(() {
          _platforms = platforms;
          _selectedPlatform = preSelected;
        });
      }
    } catch (_) {}
    _loadAreas();
  }

  Future<void> _loadAreas() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) throw Exception('AUTH_ERROR');

      final queryParams = <String, String>{'stationId': widget.stationId};
      if (_selectedPlatform?.uid != null) {
        queryParams['platformId'] = _selectedPlatform!.uid!;
      } else if (widget.platformId != null) {
        queryParams['platformId'] = widget.platformId!;
      }

      final uri = Uri.parse('${ApiService.baseUrl}/api/areas').replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final list = body['data'] as List<dynamic>? ?? body['areas'] as List<dynamic>? ?? [];
        setState(() {
          _areas = list.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('AUTH_ERROR');
      } else {
        throw Exception(ApiErrorHandler.getErrorMessage(response.body, response.statusCode));
      }
    } catch (e) {
      setState(() {
        _error = e.toString().contains('AUTH_ERROR') ? 'Session expired' : e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _showConfigDialog({Map<String, dynamic>? area}) async {
    final nameCtrl = TextEditingController(text: area?['areaName'] ?? '');
    final codeCtrl = TextEditingController(text: area?['areaCode'] ?? '');
    final freqCtrl = TextEditingController(text: area?['cleaningFrequency'] ?? area?['frequency'] ?? 'daily');
    final shiftCtrl = TextEditingController(text: area?['defaultShift'] ?? 'morning');
    final workersCtrl = TextEditingController(text: (area?['defaultWorkers'] ?? 1).toString());
    final priorityCtrl = TextEditingController(text: (area?['priority'] ?? 3).toString());
    List<String> times = (area?['frequencyTimes'] as List<dynamic>?)?.cast<String>() ?? ['08:00'];
    bool isEditing = area != null;
    String areaId = area?['uid'] ?? area?['id'] ?? '';
    Platform? dialogSelectedPlatform = area != null
        ? _platforms.where((p) => p.uid == (area['platformId'] ?? area['platform'])).firstOrNull
        : _selectedPlatform;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Configure Area' : 'Add Area'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_platforms.isNotEmpty) ...[
                  DropdownButtonFormField<Platform>(
                    value: dialogSelectedPlatform,
                    decoration: const InputDecoration(
                      labelText: 'Platform',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.view_quilt),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('No Platform')),
                      ..._platforms.map((p) => DropdownMenuItem(
                        value: p,
                        child: Text(p.displayName, overflow: TextOverflow.ellipsis),
                      )),
                    ],
                    onChanged: (v) => setDialogState(() => dialogSelectedPlatform = v),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Area Name')),
                TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Area Code', hintText: 'e.g. PF1-WAIT')),
                TextField(controller: freqCtrl, decoration: const InputDecoration(labelText: 'Frequency'),),
                Text('Frequency Times:'),
                Wrap(
                  spacing: 4,
                  children: times.map((t) => Chip(
                    label: Text(t),
                    onDeleted: () { setDialogState(() => times.remove(t)); },
                  )).toList(),
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Add Time (HH:MM)'),
                  onSubmitted: (v) { if (v.isNotEmpty) setDialogState(() => times.add(v)); },
                ),
                TextField(controller: shiftCtrl, decoration: const InputDecoration(labelText: 'Default Shift')),
                TextField(controller: workersCtrl, decoration: const InputDecoration(labelText: 'Default Workers'), keyboardType: TextInputType.number),
                TextField(controller: priorityCtrl, decoration: const InputDecoration(labelText: 'Priority (1-5)'), keyboardType: TextInputType.number),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final data = {
                  'areaName': nameCtrl.text,
                  'areaCode': codeCtrl.text,
                  'stationId': widget.stationId,
                  'platformId': dialogSelectedPlatform?.uid,
                  'cleaningFrequency': freqCtrl.text,
                  'frequencyTimes': times,
                  'defaultShift': shiftCtrl.text,
                  'defaultWorkers': int.tryParse(workersCtrl.text) ?? 1,
                  'priority': int.tryParse(priorityCtrl.text) ?? 3,
                };

                try {
                  final prefs = await SharedPreferences.getInstance();
                  final token = prefs.getString('token');
                  if (token == null) throw Exception('AUTH_ERROR');

                  final url = isEditing
                      ? '${ApiService.baseUrl}/api/areas/$areaId/configure'
                      : '${ApiService.baseUrl}/api/areas';
                  final response = isEditing
                      ? await http.put(Uri.parse(url), headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'}, body: jsonEncode(data))
                      : await http.post(Uri.parse(url), headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'}, body: jsonEncode(data));

                  if (response.statusCode == 200 || response.statusCode == 201) {
                    Navigator.pop(ctx);
                    _loadAreas();
                  } else {
                    throw Exception(ApiErrorHandler.getErrorMessage(response.body, response.statusCode));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              child: Text(isEditing ? 'Update' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Areas - ${widget.stationName}')),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showConfigDialog(),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : Column(
                  children: [
                    if (_platforms.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        color: Colors.white,
                        child: DropdownButtonFormField<Platform>(
                          value: _selectedPlatform,
                          decoration: const InputDecoration(
                            labelText: 'Platform',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.view_quilt),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            isDense: true,
                          ),
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem(value: null, child: Text('All Platforms')),
                            ..._platforms.map((p) => DropdownMenuItem(
                              value: p,
                              child: Text(p.displayName, overflow: TextOverflow.ellipsis),
                            )),
                          ],
                          onChanged: (v) {
                            setState(() => _selectedPlatform = v);
                            _loadAreas();
                          },
                        ),
                      ),
                    Expanded(
                      child: _areas.isEmpty
                          ? const Center(child: Text('No areas configured'))
                          : RefreshIndicator(
                              onRefresh: _loadAreas,
                              child: ListView.builder(
                                itemCount: _areas.length,
                                itemBuilder: (ctx, i) {
                                  final area = _areas[i];
                                  final freq = area['cleaningFrequency'] ?? area['frequency'] ?? 'daily';
                                  final times = (area['frequencyTimes'] as List<dynamic>?)?.join(', ') ?? '08:00';
                                  final platform = _platforms.where((p) => p.uid == (area['platformId'] ?? area['platform'])).firstOrNull;
                                  return Card(
                                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    child: ListTile(
                                      title: Row(
                                        children: [
                                          Expanded(child: Text(area['areaName'] ?? area['name'] ?? 'Unnamed Area')),
                                          if (platform != null)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: kRailwayBlue.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: kRailwayBlue.withOpacity(0.3)),
                                              ),
                                              child: Text(
                                                platform.displayName,
                                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: kRailwayBlue),
                                              ),
                                            ),
                                        ],
                                      ),
                                      subtitle: Text('Code: ${area['areaCode'] ?? '-'} | Freq: $freq ($times) | Shift: ${area['defaultShift'] ?? 'morning'}'),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit, size: 20),
                                            onPressed: () => _showConfigDialog(area: area),
                                          ),
                                          if (area['qrCode'] != null)
                                            IconButton(
                                              icon: const Icon(Icons.qr_code, size: 20),
                                              onPressed: () => _showQRCode(area['qrCode']),
                                            ),
                                        ],
                                      ),
                                      onTap: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Area: ${area['areaName'] ?? area['name']} | Frequency: $freq | Workers: ${area['defaultWorkers'] ?? 1}')),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }

  void _showQRCode(String qrCode) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Area QR Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.qr_code, size: 200),
            const SizedBox(height: 16),
            SelectableText(qrCode, style: const TextStyle(fontSize: 12)),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    );
  }
}
