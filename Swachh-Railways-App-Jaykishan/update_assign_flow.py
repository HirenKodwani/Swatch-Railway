import sys
import re

file_path = 'lib/view/obhs_screens/obhs_runs_list_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace getWorkers with getRailwayWorkers
content = content.replace('await OBHSRepository.getWorkers()', 'await OBHSRepository.getRailwayWorkers()')

# We need to rewrite the _assignWorkerFlow method
# First, let's locate it
pattern = r'(  Future<void> _assignWorkerFlow\(RunInstanceModel instance, int coachIndex\) async \{.*?)\n  bool _isAcCoach'
match = re.search(pattern, content, re.DOTALL)
if match:
    old_method = match.group(1)
    
    new_method = '''  Future<void> _assignWorkerFlow(RunInstanceModel instance, int coachIndex) async {
    final coach = instance.coaches[coachIndex];
    final bool isAc = _isAcCoach(coach.coachType);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final workers = await OBHSRepository.getRailwayWorkers();
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      // Initial state for dialog
      RailwayWorkerModel? selectedJanitor = workers.cast<RailwayWorkerModel?>().firstWhere((w) => w?.uid == coach.janitorId, orElse: () => null);
      RailwayWorkerModel? selectedAttendant = workers.cast<RailwayWorkerModel?>().firstWhere((w) => w?.uid == coach.attendantId, orElse: () => null);
      List<String> selectedJanitorTasks = List.from(coach.janitorTasks ?? ['Floor Cleaning', 'Toilet Cleaning', 'Dustbin Cleaning']);
      List<String> selectedAttendantTasks = List.from(coach.attendantTasks ?? ['Passenger Assistance', 'Linen Distribution']);

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
        'Passenger Assistance',
        'Linen Distribution',
        'Linen Collection',
        'Coach Monitoring',
        'Water Availability Check',
        'Toilet Monitoring',
        'Passenger Complaint Handling',
        'Minor Cleaning Checks',
      ];
      
      bool isJanitorTab = true;

      await showDialog(
        context: context,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (context, setStateDialog) {
              return AlertDialog(
                title: Text('Edit Assignment: Coach ${coach.coachPosition}'),
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
                            value: selectedJanitor,
                            decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                            items: workers.map((w) => DropdownMenuItem(value: w, child: Text(w.fullName))).toList(),
                            onChanged: (val) => setStateDialog(() => selectedJanitor = val),
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
                                final isSelected = selectedJanitorTasks.contains(task);
                                return CheckboxListTile(
                                  title: Text(task, style: const TextStyle(fontSize: 14)),
                                  value: isSelected,
                                  activeColor: kRailwayBlue,
                                  dense: true,
                                  onChanged: (checked) {
                                    setStateDialog(() {
                                      if (checked == true) {
                                        selectedJanitorTasks.add(task);
                                      } else {
                                        selectedJanitorTasks.remove(task);
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
                                  child: Text('(AC Only)', style: TextStyle(color: Colors.red, fontSize: 12)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<RailwayWorkerModel>(
                            value: selectedAttendant,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              isDense: true,
                              fillColor: isAc ? Colors.white : Colors.grey[200],
                              filled: !isAc,
                            ),
                            items: isAc 
                                ? workers.map((w) => DropdownMenuItem(value: w, child: Text(w.fullName))).toList()
                                : const [],
                            onChanged: isAc ? (val) => setStateDialog(() => selectedAttendant = val) : null,
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
                                final isSelected = selectedAttendantTasks.contains(task);
                                return CheckboxListTile(
                                  title: Text(task, style: const TextStyle(fontSize: 14)),
                                  value: isSelected,
                                  activeColor: kRailwayBlue,
                                  dense: true,
                                  onChanged: isAc ? (checked) {
                                    setStateDialog(() {
                                      if (checked == true) {
                                        selectedAttendantTasks.add(task);
                                      } else {
                                        selectedAttendantTasks.remove(task);
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

                      final updatedCoaches = List<CoachAssignment>.from(instance.coaches);
                      updatedCoaches[coachIndex] = updatedCoaches[coachIndex].copyWith(
                        janitorId: selectedJanitor?.uid,
                        janitorName: selectedJanitor?.fullName,
                        attendantId: selectedAttendant?.uid,
                        attendantName: selectedAttendant?.fullName,
                        janitorTasks: selectedJanitorTasks,
                        attendantTasks: selectedAttendantTasks,
                      );

                      await OBHSRepository.updateRunInstance(
                        runInstanceId: instance.runInstanceId ?? instance.id ?? '',
                        coaches: updatedCoaches,
                      );

                      if (!mounted) return;
                      Navigator.pop(context); // close saving dialog
                      Navigator.pop(context); // close bottom sheet
                      _loadRunInstances(); // reload list
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Coach assignments updated successfully!'), backgroundColor: Colors.green),
                      );
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: kRailwayBlue),
                    child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
                  ),
                ],
              );
            }
          );
        },
      );

    } catch (e) {
      if (mounted) {
        // Find navigator safely
        if (Navigator.canPop(context)) {
            Navigator.pop(context); // close loading dialog
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
'''
    
    content = content.replace(old_method, new_method)
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
else:
    print("Method _assignWorkerFlow not found!")
