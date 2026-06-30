import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utills/app_colors.dart';

class WorkerGarbageScreen extends StatefulWidget {
  const WorkerGarbageScreen({super.key});

  @override
  State<WorkerGarbageScreen> createState() => _WorkerGarbageScreenState();
}

class _WorkerGarbageScreenState extends State<WorkerGarbageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _areaCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _agencyCtrl = TextEditingController();
  final _vehicleCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _isRecording = false;
  String _wasteType = 'General';
  String _disposalMethod = 'Landfill';

  final _wasteTypes = ['General', 'Wet', 'Dry', 'Recyclable', 'Hazardous', 'Bio-medical', 'E-waste'];
  final _disposalMethods = ['Landfill', 'Recycling', 'Composting', 'Incineration', 'Contractor pickup'];

  @override
  void dispose() {
    _areaCtrl.dispose();
    _qtyCtrl.dispose();
    _agencyCtrl.dispose();
    _vehicleCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitRecord() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isRecording = true);
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Garbage disposal recorded'), backgroundColor: Colors.green));
        Navigator.pop(context);
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
        title: const Text('Garbage Disposal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF4CAF50),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Record Garbage Disposal', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Enter details of garbage disposal at your station', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _wasteType,
                decoration: const InputDecoration(labelText: 'Waste Type', border: OutlineInputBorder(), prefixIcon: Icon(Icons.delete_outline)),
                items: _wasteTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setState(() => _wasteType = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _qtyCtrl,
                decoration: const InputDecoration(labelText: 'Quantity (kg)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.scale)),
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _areaCtrl,
                decoration: const InputDecoration(labelText: 'Area / Platform', border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_on)),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _disposalMethod,
                decoration: const InputDecoration(labelText: 'Disposal Method', border: OutlineInputBorder(), prefixIcon: Icon(Icons.recycling)),
                items: _disposalMethods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (v) => setState(() => _disposalMethod = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(controller: _agencyCtrl, decoration: const InputDecoration(labelText: 'Disposal Agency', border: OutlineInputBorder(), prefixIcon: Icon(Icons.business))),
              const SizedBox(height: 12),
              TextFormField(controller: _vehicleCtrl, decoration: const InputDecoration(labelText: 'Vehicle No.', border: OutlineInputBorder(), prefixIcon: Icon(Icons.local_shipping))),
              const SizedBox(height: 12),
              TextFormField(controller: _notesCtrl, decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder(), prefixIcon: Icon(Icons.notes)), maxLines: 2),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isRecording ? null : _submitRecord,
                  icon: _isRecording ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save),
                  label: Text(_isRecording ? 'Saving...' : 'Submit Record'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}