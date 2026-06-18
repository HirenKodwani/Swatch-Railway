import 'package:flutter/material.dart';
import 'package:crm_train/model/user_model.dart';
import 'package:crm_train/utills/app_colors.dart';

import 'obhs_task_execution_sheet.dart';
import 'package:crm_train/utills/app_colors.dart';

class ObhsCoachChecklistScreen extends StatefulWidget {
  final UserModel user;
  final String coachLabel;

  const ObhsCoachChecklistScreen({super.key, required this.user, required this.coachLabel});

  @override
  State<ObhsCoachChecklistScreen> createState() => _ObhsCoachChecklistScreenState();
}

class _ObhsCoachChecklistScreenState extends State<ObhsCoachChecklistScreen> {
  // Placeholder task data demonstrating Parent -> Child relationship
  final List<Map<String, dynamic>> parentTasks = [
    {
      'id': 't1',
      'name': 'Toilet Cleaning',
      'icon': Icons.bathroom,
      'isExpanded': true,
      'children': [
        {'id': 'c1', 'name': 'Toilet 1', 'status': 'completed'},
        {'id': 'c2', 'name': 'Toilet 2', 'status': 'completed'},
        {'id': 'c3', 'name': 'Toilet 3', 'status': 'pending'},
        {'id': 'c4', 'name': 'Toilet 4', 'status': 'pending'},
      ],
    },
    {
      'id': 't2',
      'name': 'Garbage Collection',
      'icon': Icons.delete_outline,
      'isExpanded': false,
      'children': [
        {'id': 'c5', 'name': 'Dustbin 1 (Door A)', 'status': 'in_progress'},
        {'id': 'c6', 'name': 'Dustbin 2 (Door B)', 'status': 'pending'},
      ],
    },
    {
      'id': 't3',
      'name': 'Aisle Cleaning',
      'icon': Icons.cleaning_services,
      'isExpanded': false,
      'children': [
        {'id': 'c7', 'name': 'Full Aisle Mopping', 'status': 'pending'},
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Coach ${widget.coachLabel} Checklist',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              'Train: 12456 | Worker: Assigned Worker',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
        backgroundColor: kRailwayBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: parentTasks.length,
        itemBuilder: (context, index) {
          return _buildParentTaskCard(parentTasks[index]);
        },
      ),
    );
  }

  Widget _buildParentTaskCard(Map<String, dynamic> parent) {
    final List children = parent['children'];
    final int total = children.length;
    final int completed = children.where((c) => c['status'] == 'completed').length;
    final bool isAllCompleted = total > 0 && completed == total;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isAllCompleted ? kSuccessGreen.withOpacity(0.5) : Colors.grey[200]!,
          width: isAllCompleted ? 2 : 1,
        ),
      ),
      elevation: 1,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: parent['isExpanded'],
          onExpansionChanged: (expanded) {
            setState(() {
              parent['isExpanded'] = expanded;
            });
          },
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isAllCompleted ? kSuccessGreen.withOpacity(0.1) : kRailwayBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              parent['icon'],
              color: isAllCompleted ? kSuccessGreen : kRailwayBlue,
            ),
          ),
          title: Text(
            parent['name'],
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: Text(
            '$completed of $total sub-tasks completed',
            style: TextStyle(
              fontSize: 12,
              color: isAllCompleted ? kSuccessGreen : Colors.grey[600],
              fontWeight: isAllCompleted ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          trailing: isAllCompleted
              ? const Icon(Icons.check_circle, color: kSuccessGreen)
              : Icon(
                  parent['isExpanded'] ? Icons.expand_less : Icons.expand_more,
                  color: Colors.grey,
                ),
          children: [
            const Divider(height: 1),
            ...children.map((child) => _buildChildTaskRow(child)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildChildTaskRow(Map<String, dynamic> child) {
    Color statusColor;
    String statusText;

    switch (child['status']) {
      case 'completed':
        statusColor = kSuccessGreen;
        statusText = 'DONE';
        break;
      case 'in_progress':
        statusColor = kWarningOrange;
        statusText = 'IN PROGRESS';
        break;
      case 'rejected':
        statusColor = kErrorRed;
        statusText = 'REJECTED';
        break;
      case 'escalated':
        statusColor = Colors.purple;
        statusText = 'ESCALATED';
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'PENDING';
    }

    return InkWell(
      onTap: () {
        // Open Task Execution Sheet
        _openTaskExecutionSheet(child);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
        ),
        child: Row(
          children: [
            // Line connector visual
            Container(
              width: 2,
              height: 20,
              color: Colors.grey[300],
              margin: const EdgeInsets.only(right: 16, left: 8),
            ),
            Expanded(
              child: Text(
                child['name'],
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: statusColor.withOpacity(0.5)),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _openTaskExecutionSheet(Map<String, dynamic> childTask) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ObhsTaskExecutionSheet(task: childTask),
    );
  }
}
