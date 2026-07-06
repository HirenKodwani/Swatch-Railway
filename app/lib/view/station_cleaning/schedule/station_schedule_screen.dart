import 'package:crm_train/model/station_models.dart';
import 'package:crm_train/services/api_services.dart';
import 'package:crm_train/utills/app_colors.dart';
import 'package:flutter/material.dart';

class StationScheduleScreen extends StatefulWidget {
  final String stationId;
  final String stationName;
  const StationScheduleScreen({super.key, required this.stationId, required this.stationName});

  @override
  State<StationScheduleScreen> createState() => _StationScheduleScreenState();
}

class _StationScheduleScreenState extends State<StationScheduleScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<StationCleaningSchedule> _schedules = [];
  List<StationArea> _areas = [];
  List<StationZone> _zones = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiService.getStationSchedules(widget.stationId),
        ApiService.getStationAreas(widget.stationId),
      ]);
      setState(() {
        _schedules = results[0] as List<StationCleaningSchedule>;
        _areas = results[1] as List<StationArea>;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Load failed: $e'), backgroundColor: kErrorRed),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Schedules - ${widget.stationName}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: kRailwayBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Schedules'),
            Tab(text: 'Create'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildListTab(),
          _buildCreateTab(),
        ],
      ),
    );
  }

  Widget _buildListTab() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_schedules.isEmpty) return const Center(child: Text('No schedules found'));
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        itemCount: _schedules.length,
        itemBuilder: (context, idx) {
          final s = _schedules[idx];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: kRailwayBlue.withOpacity(0.15),
                child: Icon(Icons.schedule, color: kRailwayBlue),
              ),
              title: Text('Area: ${s.areaId}', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${s.frequencyLabel} | ${s.shift} | ${s.startTime}-${s.endTime}\nDays: ${s.daysOfWeek.isEmpty ? "All" : s.daysOfWeek.join(", ")}'),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }

  Widget _buildCreateTab() {
    return _ScheduleForm(
      stationId: widget.stationId,
      stationName: widget.stationName,
      areas: _areas,
      onCreated: () {
        _load();
        _tabController.animateTo(0);
      },
    );
  }
}

class _ScheduleForm extends StatefulWidget {
  final String stationId;
  final String stationName;
  final List<StationArea> areas;
  final VoidCallback onCreated;
  const _ScheduleForm({required this.stationId, required this.stationName, required this.areas, required this.onCreated});

  @override
  State<_ScheduleForm> createState() => _ScheduleFormState();
}

class _ScheduleFormState extends State<_ScheduleForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  String? _selectedAreaId;
  String? _selectedZoneId;
  CleaningFrequency _frequency = CleaningFrequency.daily;
  String _shift = 'Morning';
  final _entityNameCtrl = TextEditingController();
  final _supervisorNameCtrl = TextEditingController();
  final _startTimeCtrl = TextEditingController();
  final _endTimeCtrl = TextEditingController();
  final List<String> _selectedDays = [];

  final List<String> _shifts = ['Morning', 'Afternoon', 'Night'];
  final List<String> _weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void dispose() {
    _entityNameCtrl.dispose();
    _supervisorNameCtrl.dispose();
    _startTimeCtrl.dispose();
    _endTimeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final startHr = int.tryParse(_startTimeCtrl.text.split(':').first) ?? 6;
      final startMin = int.tryParse(_startTimeCtrl.text.split(':').last) ?? 0;
      final endHr = int.tryParse(_endTimeCtrl.text.split(':').first) ?? 14;
      final endMin = int.tryParse(_endTimeCtrl.text.split(':').last) ?? 0;
      final startDt = DateTime(2000, 1, 1, startHr, startMin);
      final endDt = DateTime(2000, 1, 1, endHr, endMin);
      final diff = endDt.difference(startDt);
      await ApiService.createStationSchedule({
        'stationId': widget.stationId,
        'areaId': _selectedAreaId ?? '',
        'zoneId': _selectedZoneId ?? '',
        'frequency': _frequency.name,
        'shift': _shift,
        'entityName': _entityNameCtrl.text.trim(),
        'supervisorName': _supervisorNameCtrl.text.trim(),
        'startTime': _startTimeCtrl.text.trim(),
        'endTime': _endTimeCtrl.text.trim(),
        'daysOfWeek': _selectedDays,
        'estimatedHours': diff.inHours,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Schedule created'), backgroundColor: kSuccessGreen),
        );
        widget.onCreated();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: kErrorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Schedule Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedAreaId,
                      decoration: const InputDecoration(labelText: 'Area', border: OutlineInputBorder()),
                      items: widget.areas.map((a) => DropdownMenuItem(value: a.uid ?? a.name, child: Text(a.name))).toList()
                        ..insert(0, const DropdownMenuItem(value: null, child: Text('Select Area'))),
                      onChanged: (val) => setState(() => _selectedAreaId = val),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<CleaningFrequency>(
                      value: _frequency,
                      decoration: const InputDecoration(labelText: 'Frequency', border: OutlineInputBorder()),
                      items: CleaningFrequency.values.map((f) => DropdownMenuItem(
                        value: f,
                        child: Text(f.name[0].toUpperCase() + f.name.substring(1)),
                      )).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _frequency = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _shift,
                      decoration: const InputDecoration(labelText: 'Shift', border: OutlineInputBorder()),
                      items: _shifts.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _shift = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _startTimeCtrl,
                            decoration: const InputDecoration(labelText: 'Start Time (HH:mm)', border: OutlineInputBorder()),
                            keyboardType: TextInputType.datetime,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _endTimeCtrl,
                            decoration: const InputDecoration(labelText: 'End Time (HH:mm)', border: OutlineInputBorder()),
                            keyboardType: TextInputType.datetime,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _entityNameCtrl,
                      decoration: const InputDecoration(labelText: 'Entity / Contractor Name', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _supervisorNameCtrl,
                      decoration: const InputDecoration(labelText: 'Supervisor Name', border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Days of Week', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _weekDays.map((day) {
                        final selected = _selectedDays.contains(day);
                        return FilterChip(
                          label: Text(day),
                          selected: selected,
                          selectedColor: kRailwayBlue.withOpacity(0.2),
                          checkmarkColor: kRailwayBlue,
                          onSelected: (val) {
                            setState(() {
                              if (val) {
                                _selectedDays.add(day);
                              } else {
                                _selectedDays.remove(day);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    if (_selectedDays.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text('(All days selected if none chosen)', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: kRailwayBlue, foregroundColor: Colors.white),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Create Schedule', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
