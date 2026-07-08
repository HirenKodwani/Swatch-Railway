import 'package:flutter/material.dart';
import 'package:crm_train/model/material_model.dart';
import 'package:crm_train/repositories/material_repository.dart';
import 'package:crm_train/utills/app_colors.dart';

class MaterialReorderApprovalScreen extends StatefulWidget {
  final String? stationId;
  const MaterialReorderApprovalScreen({super.key, this.stationId});

  @override
  State<MaterialReorderApprovalScreen> createState() => _MaterialReorderApprovalScreenState();
}

class _MaterialReorderApprovalScreenState extends State<MaterialReorderApprovalScreen> {
  List<StockAlert> _alerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      _alerts = await MaterialRepository.getAlerts(stationId: widget.stationId);
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Reorder Approvals', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: kRailwayBlue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _alerts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      const Text('All stock levels are adequate', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _alerts.length,
                    itemBuilder: (context, index) {
                      final a = _alerts[index];
                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: kErrorRed.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                    child: const Icon(Icons.inventory_2, color: kErrorRed, size: 20),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(a.materialName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                        Text('${a.materialType} | ${a.unit}', style: const TextStyle(fontSize: 12, color: kTextSecondary)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  _stockBar('Current', a.currentStock, kErrorRed),
                                  const SizedBox(width: 8),
                                  _stockBar('Reorder', a.reorderLevel, kWarningOrange),
                                  const SizedBox(width: 8),
                                  _stockBar('Shortage', a.shortage, kErrorRed),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: a.reorderLevel > 0 ? (a.currentStock / a.reorderLevel).clamp(0, 1) : 0,
                                  backgroundColor: kErrorRed.withOpacity(0.1),
                                  valueColor: const AlwaysStoppedAnimation(kErrorRed),
                                  minHeight: 6,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.close, size: 16),
                                    label: const Text('Dismiss'),
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Alert dismissed'), backgroundColor: kInfo),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.shopping_cart, size: 16),
                                    label: const Text('Approve Reorder'),
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Reorder approved for ${a.materialName}'), backgroundColor: kSuccessGreen),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(backgroundColor: kRailwayBlue, foregroundColor: Colors.white),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _stockBar(String label, double value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value.toStringAsFixed(0), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 10, color: kTextSecondary)),
        ],
      ),
    );
  }
}
