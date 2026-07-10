import 'package:flutter/material.dart';
import 'package:crm_train/model/user_model.dart';
import 'package:crm_train/model/run_instance_model.dart';
import 'package:crm_train/model/railway_worker_model.dart';
import 'package:crm_train/repositories/obhs_repository.dart';
import 'package:crm_train/utills/app_colors.dart';
import 'package:crm_train/view/obhs_screens/mcc/qr_feedback_generator_screen.dart';

class CaManageAssignmentsScreen extends StatefulWidget {
  final UserModel user;
  final String? runInstanceId;
  final RunInstanceModel? initialInstance;

  const CaManageAssignmentsScreen({
    super.key,
    required this.user,
    this.runInstanceId,
    this.initialInstance,
  });

  @override
  State<CaManageAssignmentsScreen> createState() => _CaManageAssignmentsScreenState();
}

class _CaManageAssignmentsScreenState extends State<CaManageAssignmentsScreen> {
  List<CoachAssignment> coaches = [];
  List<RailwayWorkerModel> workers = [];
  bool isLoading = true;
  String? errorMessage;
  RunInstanceModel? currentInstance;

  final List<String> allTasks = [
    'Toilet Cleaning',
    'Aisle Mopping',
    'Garbage Collection',
    'Window Cleaning',
    'Mirror Cleaning',
    'Linen Distribution'
  ];

  bool _isAcCoach(String coachName) {
    final upper = coachName.toUpperCase();
    return upper.startsWith('A') || 
           upper.startsWith('B') || 
           upper.startsWith('H') || 
           upper.startsWith('M') || 
           upper.startsWith('C') || 
           upper.startsWith('E');
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() { isLoading = true; errorMessage = null; });

      final fetchedWorkers = await OBHSRepository.getWorkers();
      RunInstanceModel? instance;

      if (widget.initialInstance != null) {
        instance = widget.initialInstance;
      } else {
        final allRuns = await OBHSRepository.getAllRunInstances();
        if (widget.runInstanceId != null) {
          instance = allRuns.cast<RunInstanceModel?>().firstWhere(
            (r) => r?.runInstanceId == widget.runInstanceId || r?.id == widget.runInstanceId,
            orElse: () => null,
          );
        } else {
          // Auto-pick first active or PLANNED instance
          instance = allRuns.cast<RunInstanceModel?>().firstWhere(
            (r) => r?.status == 'Active' || r?.status == 'PLANNED' || r?.status == 'ALLOCATED' || r?.status == 'READY',
            orElse: () => allRuns.isNotEmpty ? allRuns.first : null,
          );
        }
      }

      if (instance == null) {
        setState(() {
          errorMessage = 'Run instance not found.';
          isLoading = false;
        });
        return;
      }

      setState(() {
        currentInstance = instance;
        coaches = List.from(instance!.coaches);
        workers = fetchedWorkers;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load data: $e';
        isLoading = false;
      });
    }
  }

  List<RailwayWorkerModel> get _janitors =>
      workers.where((w) => (w.role.toLowerCase() == 'janitor' || w.role == 'JANITOR' || w.role.toLowerCase() == 'worker' || w.role.toLowerCase() == 'railway worker' || w.role.toLowerCase() == 'contractor worker')).toList();

  List<RailwayWorkerModel> get _attendants =>
      workers.where((w) => (w.role.toLowerCase() == 'attendant' || w.role.toLowerCase() == 'worker' || w.role.toLowerCase() == 'railway worker' || w.role.toLowerCase() == 'contractor worker')).toList();

  String _workerName(String? workerId) {
    if (workerId == null) return 'Not Assigned';
    final match = workers.cast<RailwayWorkerModel?>().firstWhere(
      (w) => w?.uid == workerId, orElse: () => null);
    return match?.fullName ?? 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Manage Tasks & Assignments',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: kRailwayBlue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (currentInstance != null)
            IconButton(
              icon: const Icon(Icons.qr_code_2),
              tooltip: 'Generate Feedback QR',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QrFeedbackGeneratorScreen(instance: currentInstance!),
                  ),
                );
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!, style: const TextStyle(color: kErrorRed)))
              : Column(
                  children: [
                    _buildTrainHeader(),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: coaches.length,
                        itemBuilder: (context, index) =>
                            _buildCoachAssignmentCard(coaches[index], index),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildTrainHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: kRailwayBlue,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Train: ${currentInstance?.trainNo ?? 'N/A'} - ${currentInstance?.trainName ?? ''}',
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Assign Janitors to all coaches and Attendants to AC coaches. Edit specific tasks required for each coach.',
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildCoachAssignmentCard(CoachAssignment coach, int index) {
    final coachLabel = coach.coachPosition.toString();
    final bool isAc = _isAcCoach(coach.coachType);
    final janitorName = _workerName(coach.janitorId);
    final attendantName = coach.attendantId != null ? _workerName(coach.attendantId) : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: kRailwayBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        coach.coachType.isEmpty ? 'C$coachLabel' : '${coach.coachType}$coachLabel',
                        style: const TextStyle(color: kRailwayBlue, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (isAc)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Text('AC Coach',
                            style: TextStyle(fontSize: 10, color: Colors.blue[800], fontWeight: FontWeight.bold)),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Text('Non-AC',
                            style: TextStyle(fontSize: 10, color: Colors.orange[800], fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: kRailwayBlue),
                  onPressed: () => _openEditDialog(index),
                  tooltip: 'Edit Tasks & Assignment',
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.cleaning_services, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Janitor: $janitorName',
                    style: TextStyle(
                      fontWeight: coach.janitorId == null ? FontWeight.normal : FontWeight.bold,
                      color: coach.janitorId == null ? kErrorRed : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.local_laundry_service, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isAc
                        ? 'Attendant: ${attendantName ?? "Not Assigned"}'
                        : 'Attendant: Not Applicable (Non-AC)',
                    style: TextStyle(
                      fontWeight: isAc && attendantName != null ? FontWeight.bold : FontWeight.normal,
                      color: !isAc ? Colors.grey : (attendantName == null ? kWarningOrange : Colors.black87),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Assigned Tasks:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [...(coach.janitorTasks ?? []), ...(coach.attendantTasks ?? [])].map((t) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(t, style: const TextStyle(fontSize: 11)),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _openEditDialog(int index) {
    final coach = coaches[index];
    final bool isAc = _isAcCoach(coach.coachType);

    String? tempJanitorId = coach.janitorId;
    String? tempAttendantId = coach.attendantId;
    
    List<String> tempJanitorTasks = List.from(coach.janitorTasks ?? ['Floor Cleaning', 'Toilet Cleaning', 'Dustbin Cleaning']);
    List<String> tempAttendantTasks = List.from(coach.attendantTasks ?? ['Linen Tasks', 'Security Tasks']);

    final List<String> allJanitorTasks = [
      'Floor Cleaning',
      'Toilet Cleaning',
      'Wash Basin Cleaning',
      'Dustbin Cleaning',
      'Vestibule Cleaning',
      'Emergency Cleaning',
      'Bio-Toilet Cleaning',
      'Coach Deep Cleaning',
    ];

    final List<String> allAttendantTasks = [
      'Linen Tasks',
      'Security Tasks',
    ];

    bool isJanitorTab = true;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('Edit Coach ${coach.coachPosition}'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Role Selector Toggle
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setStateDialog(() => isJanitorTab = true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: isJanitorTab ? kRailwayBlue : Colors.grey[200],
                                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                                  border: Border.all(color: isJanitorTab ? kRailwayBlue : Colors.grey[300]!),
                                ),
                                alignment: Alignment.center,
                                child: Text('Janitor', style: TextStyle(color: isJanitorTab ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setStateDialog(() => isJanitorTab = false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: !isJanitorTab ? kRailwayBlue : Colors.grey[200],
                                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                                  border: Border.all(color: !isJanitorTab ? kRailwayBlue : Colors.grey[300]!),
                                ),
                                alignment: Alignment.center,
                                child: Text('Attendant', style: TextStyle(color: !isJanitorTab ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      if (isJanitorTab) ...[
                        const Text('Assign Janitor', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<RailwayWorkerModel>(
                          value: _janitors.cast<RailwayWorkerModel?>().firstWhere(
                              (w) => w?.uid == tempJanitorId, orElse: () => null),
                          decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                          items: _janitors.map((w) =>
                              DropdownMenuItem(value: w, child: Text(w.fullName))).toList(),
                          onChanged: (val) => setStateDialog(() => tempJanitorId = val?.uid),
                          hint: const Text('Select Janitor'),
                        ),
                        const SizedBox(height: 20),
                        const Text('Janitor Tasks (Cleaning)', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: allJanitorTasks.map((task) {
                              final isSelected = tempJanitorTasks.contains(task);
                              return CheckboxListTile(
                                title: Text(task, style: const TextStyle(fontSize: 14)),
                                value: isSelected,
                                activeColor: kRailwayBlue,
                                dense: true,
                                onChanged: (checked) {
                                  setStateDialog(() {
                                    if (checked == true) {
                                      tempJanitorTasks.add(task);
                                    } else {
                                      tempJanitorTasks.remove(task);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      ] else ...[
                        Row(
                          children: [
                            const Text('Assign Attendant', style: TextStyle(fontWeight: FontWeight.bold)),
                            if (!isAc)
                              const Padding(
                                padding: EdgeInsets.only(left: 8.0),
                                child: Text('(AC Only)', style: TextStyle(color: kErrorRed, fontSize: 12)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<RailwayWorkerModel>(
                          value: _attendants.cast<RailwayWorkerModel?>().firstWhere(
                              (w) => w?.uid == tempAttendantId, orElse: () => null),
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            fillColor: isAc ? Colors.white : Colors.grey[200],
                            filled: !isAc,
                          ),
                          items: isAc
                              ? _attendants.map((w) =>
                                  DropdownMenuItem(value: w, child: Text(w.fullName))).toList()
                              : [],
                          onChanged: isAc ? (val) => setStateDialog(() => tempAttendantId = val?.uid) : null,
                          hint: Text(isAc ? 'Select Attendant' : 'Not Applicable'),
                          disabledHint: const Text('Non-AC Coach'),
                        ),
                        const SizedBox(height: 20),
                        const Text('Attendant Tasks (Linen/Safety)', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: allAttendantTasks.map((task) {
                              final isSelected = tempAttendantTasks.contains(task);
                              return CheckboxListTile(
                                title: Text(task, style: const TextStyle(fontSize: 14)),
                                value: isSelected,
                                activeColor: kRailwayBlue,
                                dense: true,
                                onChanged: isAc ? (checked) {
                                  setStateDialog(() {
                                    if (checked == true) {
                                      tempAttendantTasks.add(task);
                                    } else {
                                      tempAttendantTasks.remove(task);
                                    }
                                  });
                                } : null,
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(child: CircularProgressIndicator()),
                    );

                    try {
                      final updatedCoaches = List<CoachAssignment>.from(coaches);
                      updatedCoaches[index] = updatedCoaches[index].copyWith(
                        janitorId: tempJanitorId,
                        janitorName: tempJanitorId != null
                            ? _workerName(tempJanitorId)
                            : null,
                        attendantId: isAc ? tempAttendantId : null,
                        attendantName: isAc && tempAttendantId != null
                            ? _workerName(tempAttendantId)
                            : null,
                        janitorTasks: tempJanitorTasks,
                        attendantTasks: tempAttendantTasks,
                      );

                      final instanceId = currentInstance?.runInstanceId ?? currentInstance?.id;
                      if (instanceId != null) {
                        await OBHSRepository.updateRunInstance(
                          runInstanceId: instanceId,
                          coaches: updatedCoaches,
                        );
                      } else {
                        debugPrint('Warning: Attempted to update coach assignment without a valid Run Instance ID');
                      }

                      if (!mounted) return;
                      if (Navigator.canPop(context)) Navigator.pop(context); // close loading
                      setState(() => coaches = updatedCoaches);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Updated Coach ${coach.coachPosition} successfully'),
                          backgroundColor: kSuccessGreen,
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      if (Navigator.canPop(context)) Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e'), backgroundColor: kErrorRed),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: kRailwayBlue),
                  child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

}
