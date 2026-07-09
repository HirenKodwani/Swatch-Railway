import 'package:crm_train/model/station_models.dart';
import 'package:crm_train/services/api_services.dart';
import 'package:crm_train/utills/app_colors.dart';
import 'package:flutter/material.dart';

class StationMasterScreen extends StatefulWidget {
  final Station? existingStation;
  const StationMasterScreen({super.key, this.existingStation});

  @override
  State<StationMasterScreen> createState() => _StationMasterScreenState();
}

class _StationMasterScreenState extends State<StationMasterScreen> {
  final _formKey = GlobalKey<FormState>();
  bool isSaving = false;

  late TextEditingController _codeCtrl;
  late TextEditingController _nameCtrl;
  late TextEditingController _zoneCtrl;
  late TextEditingController _divisionCtrl;
  late TextEditingController _latCtrl;
  late TextEditingController _lngCtrl;
  late TextEditingController _addrCtrl;

  StationCategory _category = StationCategory.b;
  StationType _type = StationType.regular;
  bool _active = true;

  bool get isEdit => widget.existingStation != null;

  @override
  void initState() {
    super.initState();
    final s = widget.existingStation;
    _codeCtrl = TextEditingController(text: s?.stationCode ?? '');
    _nameCtrl = TextEditingController(text: s?.stationName ?? '');
    _zoneCtrl = TextEditingController(text: s?.zone ?? '');
    _divisionCtrl = TextEditingController(text: s?.division ?? '');
    _latCtrl = TextEditingController(text: s?.latitude.toString() ?? '');
    _lngCtrl = TextEditingController(text: s?.longitude.toString() ?? '');
    _addrCtrl = TextEditingController(text: s?.address ?? '');
    if (s != null) {
      _category = s.category;
      _type = s.stationType;
      _active = s.active;
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _zoneCtrl.dispose();
    _divisionCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _addrCtrl.dispose();
    super.dispose();
  }

  void _getLocation() {
    _latCtrl.text = '12.9716';
    _lngCtrl.text = '77.5946';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isSaving = true);
    try {
      final data = {
        'stationCode': _codeCtrl.text.trim(),
        'stationName': _nameCtrl.text.trim(),
        'zone': _zoneCtrl.text.trim(),
        'division': _divisionCtrl.text.trim(),
        'category': _category.name,
        'stationType': _type.name,
        'active': _active,
        'latitude': double.tryParse(_latCtrl.text) ?? 0,
        'longitude': double.tryParse(_lngCtrl.text) ?? 0,
        'address': _addrCtrl.text.trim(),
      };
      if (isEdit) {
        await ApiService.updateStation(widget.existingStation!.uid!, data);
      } else {
        await ApiService.createStation(data);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEdit ? 'Station updated' : 'Station created'), backgroundColor: kSuccessGreen),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: kErrorRed),
        );
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${isEdit ? 'Edit' : 'Add'} Station', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: kRailwayBlue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: kRailwayBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.info, color: kRailwayBlue, size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Text('Basic Information', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      ]),
                      const Divider(height: 20),
                      TextFormField(
                        controller: _codeCtrl,
                        decoration: const InputDecoration(labelText: 'Station Code *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.tag)),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(labelText: 'Station Name *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.train)),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.teal.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.category, color: Colors.teal, size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Text('Classification', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      ]),
                      const Divider(height: 20),
                      TextFormField(
                        controller: _zoneCtrl,
                        decoration: const InputDecoration(labelText: 'Zone *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.map)),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _divisionCtrl,
                        decoration: const InputDecoration(labelText: 'Division *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.map_outlined)),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<StationCategory>(
                        value: _category,
                        decoration: const InputDecoration(labelText: 'Category *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.star)),
                        items: StationCategory.values.map((c) => DropdownMenuItem(value: c, child: Text(c.name.toUpperCase()))).toList(),
                        onChanged: (v) { if (v != null) setState(() => _category = v); },
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<StationType>(
                        value: _type,
                        decoration: const InputDecoration(labelText: 'Station Type *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.account_balance)),
                        items: StationType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.name[0].toUpperCase() + t.name.substring(1)))).toList(),
                        onChanged: (v) { if (v != null) setState(() => _type = v); },
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        title: const Text('Active'),
                        subtitle: Text(_active ? 'Station is operational' : 'Station is disabled'),
                        value: _active,
                        onChanged: (v) => setState(() => _active = v),
                        activeColor: kSuccessGreen,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: kWarningOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.location_on, color: kWarningOrange, size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Text('GPS Location', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      ]),
                      const Divider(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _latCtrl,
                              decoration: const InputDecoration(labelText: 'Latitude', border: OutlineInputBorder(), prefixIcon: Icon(Icons.explore)),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _lngCtrl,
                              decoration: const InputDecoration(labelText: 'Longitude', border: OutlineInputBorder(), prefixIcon: Icon(Icons.explore)),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _getLocation,
                        icon: const Icon(Icons.my_location),
                        label: const Text('Get Location'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: kInfo.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.home, color: kInfo, size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Text('Address', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      ]),
                      const Divider(height: 20),
                      TextFormField(
                        controller: _addrCtrl,
                        decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_city)),
                        maxLines: 3,
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
                  onPressed: isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(backgroundColor: kRailwayBlue, foregroundColor: Colors.white),
                  child: isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(isEdit ? 'Update Station' : 'Create Station'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
