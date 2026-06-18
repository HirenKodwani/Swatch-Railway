import 'package:flutter/material.dart';
import 'package:crm_train/model/user_model.dart';
import 'package:crm_train/utills/app_colors.dart';

class CaManageAssignmentsScreen extends StatefulWidget {
  final UserModel user;

  const CaManageAssignmentsScreen({super.key, required this.user});

  @override
  State<CaManageAssignmentsScreen> createState() => _CaManageAssignmentsScreenState();
}

class _CaManageAssignmentsScreenState extends State<CaManageAssignmentsScreen> {
  // Placeholder data for coaches
  final List<Map<String, dynamic>> coaches = [
    {
      'coach': 'A1',
      'janitor': 'Amit Singh',
      'attendant': 'Rahul V',
      'tasks': ['Toilet Cleaning', 'Aisle Mopping', 'Garbage Collection', 'Linen Distribution']
    },
    {
      'coach': 'B1',
      'janitor': 'Amit Singh',
      'attendant': 'Not Assigned',
      'tasks': ['Toilet Cleaning', 'Aisle Mopping', 'Garbage Collection', 'Linen Distribution']
    },
    {
      'coach': 'S1',
      'janitor': 'Suresh D',
      'attendant': null, // Not applicable for non-AC
      'tasks': ['Toilet Cleaning', 'Aisle Mopping', 'Garbage Collection']
    },
    {
      'coach': 'S2',
      'janitor': 'Not Assigned',
      'attendant': null,
      'tasks': ['Toilet Cleaning', 'Aisle Mopping', 'Garbage Collection']
    },
  ];

  // Dummy worker lists
  final List<String> janitors = ['Amit Singh', 'Suresh D', 'Manoj V', 'Not Assigned'];
  final List<String> attendants = ['Rahul V', 'Karan P', 'Not Assigned'];
  
  // Standard task catalog
  final List<String> allTasks = [
    'Toilet Cleaning',
    'Aisle Mopping',
    'Garbage Collection',
    'Window Cleaning',
    'Mirror Cleaning',
    'Linen Distribution' // AC only usually, but let admin toggle
  ];

  bool _isAcCoach(String coachName) {
    // Basic logic: AC coaches typically start with A, B, H, M, C, E.
    // Non-AC are usually S (Sleeper), D (Second Seating), UR/GS.
    final upper = coachName.toUpperCase();
    return upper.startsWith('A') || 
           upper.startsWith('B') || 
           upper.startsWith('H') || 
           upper.startsWith('M') || 
           upper.startsWith('C') || 
           upper.startsWith('E');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Manage Tasks & Assignments',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: kRailwayBlue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _buildTrainHeader(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: coaches.length,
              itemBuilder: (context, index) {
                return _buildCoachAssignmentCard(coaches[index]);
              },
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
      decoration: BoxDecoration(
        color: kRailwayBlue,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Train: 12456 - ExpressB',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Assign Janitors to all coaches and Attendants to AC coaches. Edit specific tasks required for each coach.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoachAssignmentCard(Map<String, dynamic> coachData) {
    final bool isAc = _isAcCoach(coachData['coach']);

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
                        coachData['coach'],
                        style: const TextStyle(
                          color: kRailwayBlue,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
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
                        child: Text(
                          'AC Coach',
                          style: TextStyle(fontSize: 10, color: Colors.blue[800], fontWeight: FontWeight.bold),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Text(
                          'Non-AC',
                          style: TextStyle(fontSize: 10, color: Colors.orange[800], fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: kRailwayBlue),
                  onPressed: () => _openEditDialog(coachData),
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
                    'Janitor: ${coachData['janitor']}',
                    style: TextStyle(
                      fontWeight: coachData['janitor'] == 'Not Assigned' ? FontWeight.normal : FontWeight.bold,
                      color: coachData['janitor'] == 'Not Assigned' ? kErrorRed : Colors.black87,
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
                      ? 'Attendant: ${coachData['attendant']}' 
                      : 'Attendant: Not Applicable (Non-AC)',
                    style: TextStyle(
                      fontWeight: isAc && coachData['attendant'] != 'Not Assigned' ? FontWeight.bold : FontWeight.normal,
                      color: !isAc 
                          ? Colors.grey 
                          : (coachData['attendant'] == 'Not Assigned' ? kWarningOrange : Colors.black87),
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
              children: (coachData['tasks'] as List<String>).map((t) {
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

  void _openEditDialog(Map<String, dynamic> coachData) {
    final bool isAc = _isAcCoach(coachData['coach']);
    
    // Create local copies for the dialog state
    String tempJanitor = coachData['janitor'];
    String? tempAttendant = coachData['attendant'];
    List<String> tempTasks = List.from(coachData['tasks']);

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('Edit Coach ${coachData['coach']}'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Assign Janitor', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: tempJanitor,
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                        items: janitors.map((j) => DropdownMenuItem(value: j, child: Text(j))).toList(),
                        onChanged: (val) {
                          if (val != null) setStateDialog(() => tempJanitor = val);
                        },
                      ),
                      const SizedBox(height: 20),
                      
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
                      DropdownButtonFormField<String>(
                        value: tempAttendant,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          fillColor: isAc ? Colors.white : Colors.grey[200],
                          filled: !isAc,
                        ),
                        items: isAc 
                            ? attendants.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList()
                            : const [DropdownMenuItem(value: null, child: Text('Not Applicable'))],
                        onChanged: isAc ? (val) {
                          setStateDialog(() => tempAttendant = val);
                        } : null,
                        disabledHint: const Text('Non-AC Coach'),
                      ),
                      const SizedBox(height: 20),
                      
                      const Text('Edit Coach Tasks', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: allTasks.map((task) {
                            final isSelected = tempTasks.contains(task);
                            return CheckboxListTile(
                              title: Text(task, style: const TextStyle(fontSize: 14)),
                              value: isSelected,
                              activeColor: kRailwayBlue,
                              dense: true,
                              onChanged: (checked) {
                                setStateDialog(() {
                                  if (checked == true) {
                                    tempTasks.add(task);
                                  } else {
                                    tempTasks.remove(task);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
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
                  onPressed: () {
                    // Save logic
                    setState(() {
                      coachData['janitor'] = tempJanitor;
                      coachData['attendant'] = tempAttendant;
                      coachData['tasks'] = tempTasks;
                    });
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Updated ${coachData['coach']} successfully'), backgroundColor: kSuccessGreen),
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
  }
}
