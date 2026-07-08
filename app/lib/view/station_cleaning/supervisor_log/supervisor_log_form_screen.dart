import 'package:crm_train/model/station_cleaning_models.dart';
import 'package:crm_train/repositories/supervisor_log_repository.dart';
import 'package:crm_train/utills/app_colors.dart';
import 'package:flutter/material.dart';

class SupervisorLogFormScreen extends StatefulWidget {
  final SupervisorLog? log;
  final String stationId;
  final String stationName;
  const SupervisorLogFormScreen({super.key, this.log, required this.stationId, required this.stationName});

  @override
  State<SupervisorLogFormScreen> createState() => _SupervisorLogFormScreenState();
}

class _SupervisorLogFormScreenState extends State<SupervisorLogFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late TextEditingController _areaCtrl;
  late TextEditingController _handoverNotesCtrl;
  late TextEditingController _issueCtrl;
  late TextEditingController _materialCtrl;
  late TextEditingController _machineCtrl;
  late TextEditingController _rejectionReasonCtrl;

  List<String> _issues = [];
  List<String> _materials = [];
  List<String> _machines = [];
  List<String> _photos = [];

  bool get isEdit => widget.log != null;

  @override
  void initState() {
    super.initState();
    final l = widget.log;
    _areaCtrl = TextEditingController(text: '');
    _handoverNotesCtrl = TextEditingController(text: l?.handoverNotes ?? '');
    _issueCtrl = TextEditingController();
    _materialCtrl = TextEditingController();
    _machineCtrl = TextEditingController();
    _rejectionReasonCtrl = TextEditingController();

    if (l != null) {
      _issues = l.issues.map((e) => e.toString()).toList();
      _materials = l.materialUsed.map((e) => e.toString()).toList();
      _machines = l.machinesDeployed.map((e) => e.toString()).toList();
      _photos = l.photos.map((e) => e.toString()).toList();
    }
  }

  @override
  void dispose() {
    _areaCtrl.dispose();
    _handoverNotesCtrl.dispose();
    _issueCtrl.dispose();
    _materialCtrl.dispose();
    _machineCtrl.dispose();
    _rejectionReasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final formattedDate = "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";
      final payload = {
        'stationId': widget.stationId,
        'date': formattedDate,
        'shift': 'morning',
        'supervisorName': '',
        'issues': _issues,
        'materialUsed': _materials,
        'machinesDeployed': _machines,
        'photos': _photos,
        'handoverNotes': _handoverNotesCtrl.text.trim(),
      };

      if (isEdit) {
        final l = widget.log!;
        await SupervisorLogRepository.submit(l.uid);
      } else {
        await SupervisorLogRepository.create(payload);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEdit ? 'Log updated' : 'Log created'), backgroundColor: kSuccessGreen),
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      await SupervisorLogRepository.submit(widget.log!.uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Log submitted'), backgroundColor: kSuccessGreen),
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _acknowledge() async {
    setState(() => _isLoading = true);
    try {
      await SupervisorLogRepository.acknowledge(widget.log!.uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Log acknowledged'), backgroundColor: kSuccessGreen),
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _accept() async {
    setState(() => _isLoading = true);
    try {
      await SupervisorLogRepository.accept(widget.log!.uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Log accepted'), backgroundColor: kSuccessGreen),
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _reject() async {
    final reason = _rejectionReasonCtrl.text.trim();
    if (reason.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await SupervisorLogRepository.reject(widget.log!.uid, reason);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Log rejected'), backgroundColor: kErrorRed),
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addItem(String text, List<String> list, TextEditingController ctrl) {
    if (text.isNotEmpty) {
      setState(() {
        list.add(text);
        ctrl.clear();
      });
    }
  }

  void _simulateAddPhoto() {
    setState(() {
      _photos.add('https://picsum.photos/400/300?random=${DateTime.now().millisecondsSinceEpoch}');
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.log;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Supervisor Log Detail' : 'New Supervisor Log', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                      TextFormField(
                        controller: _areaCtrl,
                        decoration: const InputDecoration(labelText: 'Area / Zone', border: OutlineInputBorder()),
                        enabled: !isEdit,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _handoverNotesCtrl,
                        decoration: const InputDecoration(labelText: 'Handover Notes', border: OutlineInputBorder()),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Issues', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _issueCtrl,
                              decoration: const InputDecoration(labelText: 'Add issue', border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.add_circle, color: kRailwayBlue),
                            onPressed: () => _addItem(_issueCtrl.text.trim(), _issues, _issueCtrl),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: _issues.map((i) => Chip(
                          label: Text(i),
                          onDeleted: () => setState(() => _issues.remove(i)),
                        )).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Material Used', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _materialCtrl,
                              decoration: const InputDecoration(labelText: 'Add material', border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.add_circle, color: kRailwayBlue),
                            onPressed: () => _addItem(_materialCtrl.text.trim(), _materials, _materialCtrl),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: _materials.map((m) => Chip(
                          label: Text(m),
                          onDeleted: () => setState(() => _materials.remove(m)),
                        )).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Machines Deployed', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _machineCtrl,
                              decoration: const InputDecoration(labelText: 'Add machine', border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.add_circle, color: kRailwayBlue),
                            onPressed: () => _addItem(_machineCtrl.text.trim(), _machines, _machineCtrl),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: _machines.map((m) => Chip(
                          label: Text(m),
                          onDeleted: () => setState(() => _machines.remove(m)),
                        )).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Photos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ..._photos.map((url) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => Dialog(child: Image.network(url)),
                                  );
                                },
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Image.network(url, fit: BoxFit.cover),
                                ),
                              ),
                            )),
                            GestureDetector(
                              onTap: _simulateAddPhoto,
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(child: Icon(Icons.add_a_photo, size: 36, color: Colors.grey)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (l != null && l.rejectionReason != null && l.rejectionReason!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: kErrorRed.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Rejection Reason: ${l.rejectionReason}', style: const TextStyle(color: kErrorRed, fontWeight: FontWeight.bold)),
                ),
              ],
              const SizedBox(height: 24),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else ...[
                if (l == null || l.status == 'DRAFT')
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(backgroundColor: kRailwayBlue, foregroundColor: Colors.white),
                      child: const Text('Save & Submit'),
                    ),
                  ),
                if (l != null && l.status == 'SUBMITTED') ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _acknowledge,
                          style: ElevatedButton.styleFrom(backgroundColor: kWarningOrange, foregroundColor: Colors.white),
                          child: const Text('Acknowledge'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _accept,
                          style: ElevatedButton.styleFrom(backgroundColor: kSuccessGreen, foregroundColor: Colors.white),
                          child: const Text('Accept'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Reject Log'),
                                content: TextField(
                                  controller: _rejectionReasonCtrl,
                                  decoration: const InputDecoration(hintText: 'Enter reason for rejection'),
                                ),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _reject();
                                    },
                                    child: const Text('Reject'),
                                  ),
                                ],
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: kErrorRed, foregroundColor: Colors.white),
                          child: const Text('Reject'),
                        ),
                      ),
                    ],
                  ),
                ],
                if (l != null && l.status == 'ACKNOWLEDGED') ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _accept,
                      style: ElevatedButton.styleFrom(backgroundColor: kSuccessGreen, foregroundColor: Colors.white),
                      child: const Text('Accept'),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
