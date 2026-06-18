import 'package:flutter/material.dart';
import 'package:crm_train/model/user_model.dart';
import 'package:crm_train/utills/app_colors.dart';

import '../../../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class AttendantLinenScreen extends StatefulWidget {
  final UserModel user;

  const AttendantLinenScreen({super.key, required this.user});

  @override
  State<AttendantLinenScreen> createState() => _AttendantLinenScreenState();
}

class _AttendantLinenScreenState extends State<AttendantLinenScreen> {
  // Placeholder data for AC coaches assigned
  final List<String> myAcCoaches = ['A1', 'A2', 'B1']; // A=First/Second AC, B=Third AC

  String selectedCoach = 'A1';

  final List<Map<String, dynamic>> linenItems = [
    {'item': 'Bedsheet', 'distributed': 0, 'returned': 0, 'missing': 0, 'damaged': 0, 'target': 72},
    {'item': 'Pillow Cover', 'distributed': 0, 'returned': 0, 'missing': 0, 'damaged': 0, 'target': 72},
    {'item': 'Blanket', 'distributed': 0, 'returned': 0, 'missing': 0, 'damaged': 0, 'target': 72},
    {'item': 'Towel', 'distributed': 0, 'returned': 0, 'missing': 0, 'damaged': 0, 'target': 72},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Linen Workflow (Attendant)',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: kRailwayBlue,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCoachSelector(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: linenItems.length,
              itemBuilder: (context, index) {
                return _buildLinenItemCard(linenItems[index]);
              },
            ),
          ),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildCoachSelector() {
    return Container(
      color: Colors.white,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Coach',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: myAcCoaches.map((coach) {
                final isSelected = selectedCoach == coach;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(coach),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          selectedCoach = coach;
                        });
                      }
                    },
                    selectedColor: kRailwayBlue,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinenItemCard(Map<String, dynamic> item) {
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
              children: [
                const Icon(Icons.local_laundry_service, color: kRailwayBlue),
                const SizedBox(width: 8),
                Text(
                  item['item'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Target: ${item['target']}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Distribution', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const Divider(),
            _buildCounterRow('Distributed', item['distributed'], (newVal) {
              setState(() => item['distributed'] = newVal);
            }),
            const SizedBox(height: 16),
            const Text('Collection Status', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const Divider(),
            _buildCounterRow('Returned (Clean)', item['returned'], (newVal) {
              setState(() => item['returned'] = newVal);
            }),
            _buildCounterRow('Missing', item['missing'], (newVal) {
              setState(() => item['missing'] = newVal);
            }),
            _buildCounterRow('Damaged', item['damaged'], (newVal) {
              setState(() => item['damaged'] = newVal);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCounterRow(String label, int value, ValueChanged<int> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              color: Colors.grey[600],
              onPressed: () {
                if (value > 0) {
                  onChanged(value - 1);
                }
              },
            ),
            SizedBox(
              width: 40,
              child: Text(
                value.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              color: kRailwayBlue,
              onPressed: () {
                onChanged(value + 1);
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          // Submit linen data
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: kRailwayBlue,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          'Submit Linen Status',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
