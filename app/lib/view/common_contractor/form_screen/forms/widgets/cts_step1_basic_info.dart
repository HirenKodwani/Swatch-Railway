import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../../controller/cts_form_controller.dart';
import '../../../../../model/train_model.dart';
import 'labeled_field.dart';

class CTSStep1BasicInfo extends GetView<CTSFormController> {
  const CTSStep1BasicInfo({super.key});

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Select';
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');
    return '${dateFormat.format(dateTime)} ${timeFormat.format(dateTime)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Basic Info',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Obx(
            () => ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (controller.currentStep.value + 1) / 4,
                backgroundColor: Colors.grey.shade300,
                color: Colors.blue,
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(height: 16),

          _buildJobDateTimeField(context),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(flex: 1, child: _buildPlatformField()),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: _buildTrainSelectionField()),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(child: _buildActualArrivalField(context)),
              const SizedBox(width: 12),
              Expanded(child: _buildActualDepartureField(context)),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(child: _buildWorkStartTimeField(context)),
              const SizedBox(width: 12),
              Expanded(child: _buildWorkEndTimeField(context)),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(child: _buildAllowedWindowField()),
              const SizedBox(width: 12),
              Expanded(child: _buildLateField()),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(child: _buildCoachesInRakeField()),
              const SizedBox(width: 12),
              Expanded(child: _buildCoachesAttendedField()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformField() {
    return LabeledField(
      label: 'Platform',
      child: Obx(
        () => DropdownButtonFormField<int>(
          value: controller.platformNumber.value,
          onChanged: (v) => controller.platformNumber.value = v ?? 1,
          items: List.generate(6, (i) => i + 1)
              .map((n) => DropdownMenuItem(value: n, child: Text('$n')))
              .toList(),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ),
    );
  }

  Widget _buildJobDateTimeField(BuildContext context) {
    return Obx(
      () => LabeledField(
        label: 'Form Date & Time *',
        child: InkWell(
          onTap: () => controller.selectJobDateTime(context),
          child: InputDecorator(
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              suffixIcon: const Icon(Icons.calendar_today),
            ),
            child: Text(
              _formatDateTime(controller.jobDateTime.value),
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrainSelectionField() {
    return LabeledField(
      label: 'Train No *',
      child: Obx(
        () => controller.isLoadingTrains.value
            ? Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Flexible(child: Text('Loading...', style: TextStyle(fontSize: 13))),
                  ],
                ),
              )
            : DropdownButtonFormField(
                value: controller.selectedTrain.value,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  filled: controller.isResubmit,
                  fillColor: controller.isResubmit ? Colors.grey.shade200 : null,
                ),
                hint: const Text('Select train', style: TextStyle(fontSize: 14)),
                isExpanded: true,
                items: controller.activeTrains.map((train) {
                  return DropdownMenuItem(
                    value: train,
                    child: Text(
                      '${train.trainNo ?? 'N/A'} - ${train.trainName ?? 'Unknown'}',
                      style: const TextStyle(fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  );
                }).toList(),
                onChanged: controller.isResubmit ? null : (newValue) {
                  controller.selectedTrain.value = newValue as TrainModel?;
                },
              ),
      ),
    );
  }

  Widget _buildActualArrivalField(BuildContext context) {
    return LabeledField(
      label: 'Act Arrival *',
      child: Obx(
        () => InkWell(
          onTap: () => controller.selectDateTime(context, controller.actualArrivalDateTime),
          child: InputDecorator(
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              suffixIcon: const Icon(Icons.event, size: 20),
            ),
            child: Text(
              _formatDateTime(controller.actualArrivalDateTime.value),
              style: TextStyle(
                fontSize: 13,
                color: controller.actualArrivalDateTime.value == null
                    ? Colors.grey
                    : Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActualDepartureField(BuildContext context) {
    return LabeledField(
      label: 'Act Departure *',
      child: Obx(
        () => InkWell(
          onTap: () => controller.selectDateTime(context, controller.actualDepartureDateTime),
          child: InputDecorator(
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              suffixIcon: const Icon(Icons.event, size: 20),
            ),
            child: Text(
              _formatDateTime(controller.actualDepartureDateTime.value),
              style: TextStyle(
                fontSize: 13,
                color: controller.actualDepartureDateTime.value == null
                    ? Colors.grey
                    : Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWorkStartTimeField(BuildContext context) {
    return LabeledField(
      label: 'Work Start *',
      child: Obx(
        () => InkWell(
          onTap: () => controller.selectDateTime(context, controller.workStartDateTime),
          child: InputDecorator(
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              suffixIcon: const Icon(Icons.event, size: 20),
            ),
            child: Text(
              _formatDateTime(controller.workStartDateTime.value),
              style: TextStyle(
                fontSize: 13,
                color: controller.workStartDateTime.value == null
                    ? Colors.grey
                    : Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWorkEndTimeField(BuildContext context) {
    return LabeledField(
      label: 'Work End *',
      child: Obx(
        () => InkWell(
          onTap: () => controller.selectDateTime(context, controller.workEndDateTime),
          child: InputDecorator(
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              suffixIcon: const Icon(Icons.event, size: 20),
            ),
            child: Text(
              _formatDateTime(controller.workEndDateTime.value),
              style: TextStyle(
                fontSize: 13,
                color: controller.workEndDateTime.value == null
                    ? Colors.grey
                    : Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAllowedWindowField() {
    return LabeledField(
      label: 'Allowed Window (min)',
      child: Obx(
        () => SizedBox(
          height: 48,
          child: InputDecorator(
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              controller.allowedWindow.value.toString(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoachesInRakeField() {
    return LabeledField(
      label: 'Coaches in Rake',
      child: Obx(
        () => DropdownButtonFormField<int>(
          value: controller.selectedCoachesInRake.value,
          onChanged: (v) {
            if (v != null) controller.selectedCoachesInRake.value = v;
          },
          items: List.generate(30, (i) => i + 1)
              .map((n) => DropdownMenuItem(value: n, child: Text('$n')))
              .toList(),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ),
    );
  }

  Widget _buildCoachesAttendedField() {
    return LabeledField(
      label: 'Coaches Attended',
      child: Obx(
        () => DropdownButtonFormField<int>(
          value: controller.selectedCoachesAttended.value,
          onChanged: (v) {
            if (v != null) controller.selectedCoachesAttended.value = v;
          },
          items: List.generate(
            controller.selectedCoachesInRake.value,
            (i) => i + 1,
          ).map((n) => DropdownMenuItem(value: n, child: Text('$n'))).toList(),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            helperStyle: const TextStyle(fontSize: 10),
          ),
        ),
      ),
    );
  }

  Widget _buildLateField() {
    return LabeledField(
      label: 'Late (Y/N)',
      child: Obx(
        () => DropdownButtonFormField<String>(
          value: controller.isLate.value,
          onChanged: (v) => controller.isLate.value = v ?? 'No',
          items: ['Yes', 'No']
              .map((option) => DropdownMenuItem(
                    value: option,
                    child: Text(option),
                  ))
              .toList(),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ),
    );
  }
}
