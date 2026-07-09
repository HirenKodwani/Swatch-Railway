import 'package:crm_train/repositories/evidence_repository.dart';
import 'package:crm_train/utills/app_colors.dart';
import 'package:flutter/material.dart';

class EvidenceUploadScreen extends StatefulWidget {
  final String stationId;
  final String stationName;
  const EvidenceUploadScreen({super.key, required this.stationId, required this.stationName});

  @override
  State<EvidenceUploadScreen> createState() => _EvidenceUploadScreenState();
}

class _EvidenceUploadScreenState extends State<EvidenceUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  String _evidenceType = 'before_photo';
  String _base64Image = '';
  late TextEditingController _remarksCtrl;
  late TextEditingController _imageUrlCtrl;

  final List<String> _types = ['before_photo', 'after_photo', 'inspection', 'complaint'];

  @override
  void initState() {
    super.initState();
    _remarksCtrl = TextEditingController();
    _imageUrlCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _remarksCtrl.dispose();
    _imageUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _upload() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await EvidenceRepository.upload({
        'stationId': widget.stationId,
        'evidenceType': _evidenceType,
        'base64Image': _base64Image,
        'imageUrl': _imageUrlCtrl.text.trim(),
        'remarks': _remarksCtrl.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Evidence uploaded'), backgroundColor: kSuccessGreen),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: kErrorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Evidence', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: _evidenceType,
                        decoration: const InputDecoration(labelText: 'Evidence Type *', border: OutlineInputBorder()),
                        items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t.replaceAll('_', ' ').toUpperCase()))).toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _evidenceType = v);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _imageUrlCtrl,
                        decoration: const InputDecoration(labelText: 'Image URL (simulated)', border: OutlineInputBorder()),
                        onChanged: (v) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _remarksCtrl,
                        decoration: const InputDecoration(labelText: 'Remarks', border: OutlineInputBorder()),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              if (_imageUrlCtrl.text.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Preview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Image.network(_imageUrlCtrl.text.trim(), fit: BoxFit.contain),
                ),
              ],
              const SizedBox(height: 24),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _upload,
                    style: ElevatedButton.styleFrom(backgroundColor: kRailwayBlue, foregroundColor: Colors.white),
                    child: const Text('Upload Evidence'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
