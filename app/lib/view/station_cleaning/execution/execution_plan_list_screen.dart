import 'package:crm_train/model/station_cleaning_models.dart';
import 'package:crm_train/repositories/execution_repository.dart';
import 'package:crm_train/utills/app_colors.dart';
import 'package:flutter/material.dart';
import 'execution_plan_form_screen.dart';

class ExecutionPlanListScreen extends StatefulWidget {
  final String stationId;
  final String stationName;
  const ExecutionPlanListScreen({super.key, required this.stationId, required this.stationName});

  @override
  State<ExecutionPlanListScreen> createState() => _ExecutionPlanListScreenState();
}

class _ExecutionPlanListScreenState extends State<ExecutionPlanListScreen> {
  bool _isLoading = false;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  List<ExecutionPlan> _plans = [];

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    setState(() => _isLoading = true);
    try {
      final query = {
        'stationId': widget.stationId,
        'month': _selectedMonth.toString(),
        'year': _selectedYear.toString(),
      };
      final list = await ExecutionRepository.listPlans(query);
      setState(() => _plans = list);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load plans: $e'), backgroundColor: kErrorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'DRAFT': return kWarningOrange;
      case 'SUBMITTED': return kRailwayBlue;
      case 'APPROVED': return kSuccessGreen;
      case 'REJECTED': return kErrorRed;
      default: return Colors.grey;
    }
  }

  String _shiftSummary(ExecutionPlan plan) {
    final m = plan.shiftPlan['morning']?.toString() ?? '0';
    final a = plan.shiftPlan['afternoon']?.toString() ?? '0';
    final n = plan.shiftPlan['night']?.toString() ?? '0';
    return 'M:$m A:$a N:$n';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Execution Plan - ${widget.stationName}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: kRailwayBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPlans,
          ),
        ],
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButton<int>(
                      value: _selectedMonth,
                      isExpanded: true,
                      items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text(DateTime(0, i + 1).monthName()))),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedMonth = val);
                          _loadPlans();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButton<int>(
                      value: _selectedYear,
                      isExpanded: true,
                      items: [
                        for (int y = DateTime.now().year - 2; y <= DateTime.now().year + 1; y++)
                          DropdownMenuItem(value: y, child: Text(y.toString())),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedYear = val);
                          _loadPlans();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _plans.isEmpty
                    ? const Center(child: Text('No plans found for this period'))
                    : RefreshIndicator(
                        onRefresh: _loadPlans,
                        child: ListView.builder(
                          itemCount: _plans.length,
                          itemBuilder: (context, idx) {
                            final plan = _plans[idx];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: ListTile(
                                title: Text('Plan ${plan.month}/${plan.year} v${plan.version}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(_shiftSummary(plan)),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _statusColor(plan.status).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: _statusColor(plan.status)),
                                  ),
                                  child: Text(
                                    plan.status,
                                    style: TextStyle(color: _statusColor(plan.status), fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ExecutionPlanFormScreen(
                                        plan: plan,
                                        stationId: widget.stationId,
                                        stationName: widget.stationName,
                                      ),
                                    ),
                                  ).then((_) => _loadPlans());
                                },
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: kRailwayBlue,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ExecutionPlanFormScreen(
                stationId: widget.stationId,
                stationName: widget.stationName,
              ),
            ),
          ).then((_) => _loadPlans());
        },
      ),
    );
  }
}

extension on DateTime {
  String monthName() {
    switch (month) {
      case 1: return 'Jan';
      case 2: return 'Feb';
      case 3: return 'Mar';
      case 4: return 'Apr';
      case 5: return 'May';
      case 6: return 'Jun';
      case 7: return 'Jul';
      case 8: return 'Aug';
      case 9: return 'Sep';
      case 10: return 'Oct';
      case 11: return 'Nov';
      case 12: return 'Dec';
      default: return '';
    }
  }
}
