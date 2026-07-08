import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../controller/cts_form_controller.dart';
import 'labeled_field.dart';

class CTSStep3Disposal extends GetView<CTSFormController> {
  const CTSStep3Disposal({super.key});

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
            'Garbage Disposal & Exceptions',
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
          _buildGarbageDisposedToggle(),
          const SizedBox(height: 12),
          Obx(
            () => controller.garbageDisposed.value
                ? _buildDisposalLocationField()
                : const SizedBox(),
          ),
          _buildOccupiedToiletsField(),
          const SizedBox(height: 16),
          _buildNotesField(),
        ],
      ),
    );
  }

  Widget _buildGarbageDisposedToggle() {
    return Obx(
      () => Row(
        children: [
          const Expanded(
            child: Text(
              'Garbage Disposed to Nominated Location?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: controller.garbageDisposed.value,
            onChanged: (v) => controller.garbageDisposed.value = v,
          ),
          Text(
            controller.garbageDisposed.value ? 'Yes' : 'No',
            style: TextStyle(
              color: controller.garbageDisposed.value
                  ? Colors.green
                  : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisposalLocationField() {
    final disposalLocations = [
      'Pune Station',
      'Other Station',
    ];

    return Column(
      children: [
        LabeledField(
          label: 'Nominated Disposal Location *',
          child: Obx(
                () {
              final safeValue = disposalLocations.contains(controller.selectedDisposalLocation.value)
                  ? controller.selectedDisposalLocation.value
                  : disposalLocations.first;

              return DropdownButtonFormField<String>(
                value: safeValue,
                onChanged: (v) => controller.selectedDisposalLocation.value = v ?? disposalLocations.first,
                items: disposalLocations.map((location) {
                  return DropdownMenuItem(
                    value: location,
                    child: Text(location, style: const TextStyle(fontSize: 14)),
                  );
                }).toList(),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildOccupiedToiletsField() {
    return LabeledField(
      label: 'Occupied Toilets Count',
      child: Obx(
        () => TextFormField(
          initialValue: controller.occupiedToiletsCount.value.toString(),
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onChanged: (v) =>
              controller.occupiedToiletsCount.value = int.tryParse(v) ?? 0,
        ),
      ),
    );
  }

  Widget _buildNotesField() {
    return LabeledField(
      label: 'Notes / Exceptions',
      child: TextFormField(
        controller: controller.notesController,
        maxLines: 4,
        decoration: InputDecoration(
          hintText: 'e.g., occupied toilets, passenger constraints, etc.',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
