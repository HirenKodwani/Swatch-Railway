import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../controller/cts_form_controller.dart';

class CTSStep2Attendance extends GetView<CTSFormController> {
  const CTSStep2Attendance({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Attendance (Cleaning Staff + Supervisor)',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Obx(
            () => ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: (controller.currentStep.value + 1) / 4,
                backgroundColor: Colors.grey.shade300,
                color: Colors.blue,
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Enter staff who attended this job (max 25)',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 12),
          _buildStaffCountSelector(),
          const SizedBox(height: 16),
          Obx(
            () => controller.staffMembers.isNotEmpty
                ? _buildStaffTable()
                : _buildEmptyState(),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffCountSelector() {
    return Row(
      children: [
        const Icon(Icons.people, size: 20),
        const SizedBox(width: 8),
        const Text(
          'Number of Staff:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 70,
          child: Obx(
            () => DropdownButtonFormField<int>(
              value: controller.staffMembers.isEmpty
                  ? null
                  : controller.staffMembers.length,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                isDense: true,
              ),
              hint: const Text('0', style: TextStyle(fontSize: 14)),
              isExpanded: true,
              items: List.generate(25, (i) => i + 1)
                  .map(
                    (count) => DropdownMenuItem(
                      value: count,
                      child: Text(
                        '$count',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  controller.updateStaffCount(value);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStaffTable() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.blue),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Fill in staff details in the table below',
                  style: TextStyle(fontSize: 12, color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildTableHeader(),
        _buildTableBody(),
      ],
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 40,
            child: Text('#', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Staff Name *',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: Text(
              'Staff ID',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text('Role', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              'Remarks',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableBody() {
    return Obx(
      () => Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(8),
            bottomRight: Radius.circular(8),
          ),
        ),
        child: ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: controller.staffMembers.length,
          itemBuilder: (ctx, idx) {
            final staff = controller.staffMembers[idx];
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: idx < controller.staffMembers.length - 1
                      ? BorderSide(color: Colors.grey.shade200)
                      : BorderSide.none,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 40,
                    child: Text(
                      '${idx + 1}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: staff.nameController,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Name',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: staff.staffIdController,
                      style: const TextStyle(fontSize: 14),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'ID',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: staff.roleController,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Cleaner/Supervisor',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: staff.remarksController,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Remarks',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.people_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'Select number of staff from the dropdown above',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
