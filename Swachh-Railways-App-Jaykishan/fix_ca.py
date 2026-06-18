import sys
import re

file_path = r'lib\view\obhs_screens\mcc\ca_manage_assignments_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace tasks usage in UI
content = content.replace(
    'children: (coach.tasks ?? allTasks).map((t) {',
    'children: [...(coach.janitorTasks ?? []), ...(coach.attendantTasks ?? [])].map((t) {'
)

# Replace _openEditDialog completely
pattern = r'(  void _openEditDialog\(int index\) \{.*?)^\}'
match = re.search(pattern, content, re.DOTALL | re.MULTILINE)

if match:
    old_method = match.group(1) + '}\n'
    new_method = '''  void _openEditDialog(int index) {
    final coach = coaches[index];
    final bool isAc = _isAcCoach(coach.coachType);

    String? tempJanitorId = coach.janitorId;
    String? tempAttendantId = coach.attendantId;
    
    List<String> tempJanitorTasks = List.from(coach.janitorTasks ?? ['Floor Cleaning', 'Toilet Cleaning', 'Dustbin Cleaning']);
    List<String> tempAttendantTasks = List.from(coach.attendantTasks ?? ['Passenger Assistance', 'Linen Distribution']);

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

                      if (currentInstance?.runInstanceId != null) {
                        await OBHSRepository.updateRunInstance(
                          runInstanceId: currentInstance!.runInstanceId!,
                          coaches: updatedCoaches,
                        );
                      }

                      if (!mounted) return;
                      Navigator.pop(context); // close loading
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
'''
    
    content = content.replace(old_method, new_method)
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
else:
    print("Method _openEditDialog not found!")
