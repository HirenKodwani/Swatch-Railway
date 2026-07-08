import 'package:crm_train/model/cts_form_model.dart';
import 'package:crm_train/utills/app_colors.dart';
import 'package:crm_train/controller/cts_scorecard_controller.dart';
import 'package:crm_train/view/common_contractor/form_screen/forms/widgets/cts_bottom_bar.dart';
import 'package:crm_train/view/common_contractor/form_screen/forms/widgets/cts_step_header.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class CTSScorecardForm extends StatefulWidget {
  final String? formId;
  final CTSForm? ctsForm;

  const CTSScorecardForm({super.key, this.formId, this.ctsForm});

  @override
  State<CTSScorecardForm> createState() => _CTSScorecardFormState();
}

class _CTSScorecardFormState extends State<CTSScorecardForm> {
  late final String _controllerTag;
  late final CTSScorecardController controller;

  @override
  void initState() {
    super.initState();
    _controllerTag = widget.formId ?? widget.ctsForm?.uid ?? 'cts_scorecard';

    controller = Get.put(
      CTSScorecardController(),
      tag: _controllerTag,
    );

    if (!controller.isInitialized) {
      if (widget.ctsForm != null) {
        controller.setFormData(widget.ctsForm!);
      } else if (widget.formId != null) {
        controller.setFormId(widget.formId!);
      }
    }
  }

  @override
  void dispose() {
    Get.delete<CTSScorecardController>(tag: _controllerTag);
    super.dispose();
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Select';
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');
    return '${dateFormat.format(dateTime)} ${timeFormat.format(dateTime)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: kRailwayBlue,
        elevation: 0,
        title: const Text(
          'CTS Scorecard Form',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Obx(
              () => CTSStepHeader(
                currentStep: controller.currentStep.value,
                stepTitles: const ['Basic\nInfo', 'Coach\nDetails', 'Machines\n& Chemicals', 'Summary\nDetails'],
              ),
            ),
          ),
          const Divider(height: 20),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Obx(() {
                switch (controller.currentStep.value) {
                  case 0:
                    return _buildStep1BasicInfo(controller, context);
                  case 1:
                    return _buildStep2CoachDetails(controller);
                  case 2:
                    return _buildStep3Machines(controller);
                  case 3:
                    return _buildStep4Summary(controller);
                  default:
                    return _buildStep1BasicInfo(controller, context);
                }
              }),
            ),
          ),
          Obx(
            () => CTSBottomBar(
              currentStep: controller.currentStep.value,
              isSubmitting: controller.isSubmitting.value,
              onBack: controller.previousStep,
              onCancel: () => Navigator.of(context).pop(),
              onNext: () => controller.nextStep(context),
              onSubmit: () => controller.validateAndSubmit(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1BasicInfo(CTSScorecardController controller, BuildContext context) {
    return Column(
      children: [
        _buildFormDetailsCard(controller),
        const SizedBox(height: 16),
        _buildInspectionHeaderCard(controller, context),
      ],
    );
  }

  Widget _buildStep2CoachDetails(CTSScorecardController controller) {
    return Obx(() => _buildCoachesTable(controller));
  }

  Widget _buildStep3Machines(CTSScorecardController controller) {
    return Column(
      children: [
        Obx(() => _buildMachinesCard(controller)),
        const SizedBox(height: 16),
        Obx(() => _buildChemicalsCard(controller)),
      ],
    );
  }

  Widget _buildStep4Summary(CTSScorecardController controller) {
    return Obx(() => Column(
          children: [
            _buildSummaryCard(controller),
            const SizedBox(height: 16),
            _buildSignatureCard(controller),
          ],
        ));
  }

  Widget _buildFormDetailsCard(CTSScorecardController controller) {
    final form = controller.ctsForm;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Form Details",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xffe9edff),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "CTS Inspection",
                  style: TextStyle(
                    fontSize: 12,
                    color: kRailwayBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InfoRow(
            label: "Submitted At:",
            value: form != null ? form.getFormattedDateTime() : 'N/A',
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: InfoRow(
                  label: "Division:",
                  value: form?.submittedTo.division ?? 'N/A',
                ),
              ),
              Expanded(
                child: InfoRow(
                  label: "Depot:",
                  value: form?.submittedTo.depot ?? 'N/A',
                ),
              ),
              Expanded(
                child: InfoRow(
                  label: "Station:",
                  value: form?.station ?? 'N/A',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          InfoRow(
            label: "Train Name & No.:",
            value: form != null
                ? '${form.trainNumber} - ${form.trainName}'
                : 'N/A',
          ),
          const SizedBox(height: 8),
          InfoRow(
            label: "Submitted By:",
            value: form?.submittedByName ?? 'N/A',
          ),
          InfoRow(
            label: "Submitted To:",
            value: form?.submittedTo.railwayEmployeeName ?? 'N/A',
          ),
        ],
      ),
    );
  }

  Widget _buildInspectionHeaderCard(CTSScorecardController controller, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.assignment, color: kRailwayBlue, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Inspection Header",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Obx(() => InkWell(
                      onTap: () => controller.selectDateTime(context, 'start'),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Work Start *',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          suffixIcon: const Icon(Icons.event, size: 20),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        child: Text(
                          _formatDateTime(controller.workStartTime.value),
                          style: TextStyle(
                            fontSize: 13,
                            color: controller.workStartTime.value == null ? Colors.grey : Colors.black,
                          ),
                        ),
                      ),
                    )),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Obx(() => InkWell(
                      onTap: () => controller.selectDateTime(context, 'end'),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Work End *',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          suffixIcon: const Icon(Icons.event, size: 20),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        child: Text(
                          _formatDateTime(controller.workEndTime.value),
                          style: TextStyle(
                            fontSize: 13,
                            color: controller.workEndTime.value == null ? Colors.grey : Colors.black,
                          ),
                        ),
                      ),
                    )),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: controller.inspectorType.value,
                decoration: InputDecoration(
                  labelText: "Inspector Type",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: ['Supervisor', 'Railway Rep'].map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) {
                  if (value != null) controller.updateInspectorType(value);
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: controller.totalCoaches.value,
                      decoration: InputDecoration(
                        labelText: "Total Coaches (N)",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: List.generate(30, (i) => i + 1).map((num) {
                        return DropdownMenuItem(value: num, child: Text('$num'));
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) controller.updateTotalCoaches(value);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: controller.attendedCoaches.value,
                      decoration: InputDecoration(
                        labelText: "Coaches Attended",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: List.generate(controller.totalCoaches.value, (i) => i + 1).map((num) {
                        return DropdownMenuItem(value: num, child: Text('$num'));
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) controller.updateAttendedCoaches(value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Sampling %: ', style: TextStyle(fontWeight: FontWeight.w500)),
                  Expanded(
                    child: Slider(
                      value: controller.samplingPercentage.value,
                      min: 5,
                      max: 50,
                      divisions: 9,
                      label: '${controller.samplingPercentage.value.toInt()}%',
                      onChanged: (value) {
                        controller.updateSamplingPercentage(value);
                      },
                    ),
                  ),
                  Text('${controller.samplingPercentage.value.toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xffe9edff),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: kRailwayBlue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Sample Size: ${controller.coachesData.length} coaches (auto-calculated based on sampling %)',
                        style: const TextStyle(fontSize: 13, color:kRailwayBlue),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ));
  }

  Widget _buildCoachesTable(CTSScorecardController controller) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: const [
                Icon(Icons.table_chart, color: kRailwayBlue, size: 18),
                SizedBox(width: 6),
                Text(
                  "Coach-wise Inspection Scorecard",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(const Color(0xffe9edff)),
                border: TableBorder(
                  horizontalInside: BorderSide(color: Colors.grey.shade300),
                  verticalInside: BorderSide(color: Colors.grey.shade300),
                ),
                columnSpacing: 10,
                headingRowHeight: 50,
                dataRowHeight: 60,
                columns: const [
                  DataColumn(label: Text('Sr.\nNo.', style: _headerStyle, textAlign: TextAlign.center)),
                  DataColumn(label: Text('Coach\nPosition', style: _headerStyle, textAlign: TextAlign.center)),
                  DataColumn(label: Text('Coach\nNumber', style: _headerStyle, textAlign: TextAlign.center)),
                  DataColumn(label: Text('Jet\nCleaning\n(0-3)', style: _headerStyle, textAlign: TextAlign.center)),
                  DataColumn(label: Text('Basin\nCleaning\n(0-3)', style: _headerStyle, textAlign: TextAlign.center)),
                  DataColumn(label: Text('Garbage\nCollection\n(0-3)', style: _headerStyle, textAlign: TextAlign.center)),
                  DataColumn(label: Text('Remarks', style: _headerStyle, textAlign: TextAlign.center)),
                  DataColumn(label: Text('Total\n(0-9)', style: _headerStyle, textAlign: TextAlign.center)),
                  DataColumn(label: Text('Grade', style: _headerStyle, textAlign: TextAlign.center)),
                ],
                rows: List.generate(
                  controller.coachesData.length,
                  (index) => _buildCoachDataRow(controller, index),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  static const TextStyle _headerStyle = TextStyle(fontWeight: FontWeight.bold, fontSize: 11);

  DataRow _buildCoachDataRow(CTSScorecardController controller, int index) {
    final coach = controller.coachesData[index];
    int totalScore = (coach.jetCleaningScore ?? 0) +
        (coach.basinCleaningScore ?? 0) +
        (coach.garbageCollectionScore ?? 0);
    String grade = controller.getGrade(totalScore.toDouble());

    return DataRow(
      cells: [
        DataCell(Text('${index + 1}', style: const TextStyle(fontSize: 12),)),
        DataCell(
          SizedBox(
            width: 40,
            child: TextField(
              controller: TextEditingController(text: coach.position?.toString() ?? '')
                ..selection = TextSelection.fromPosition(
                  TextPosition(offset: (coach.position?.toString() ?? '').length),
                ),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,

              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                hintText: '0',
                contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                isDense: true,
              ),
              onChanged: (value) {
                controller.updateCoachPosition(index, int.tryParse(value));
              },
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 70,
            child: TextField(
              controller: TextEditingController(text: coach.coachNumber)
                ..selection = TextSelection.fromPosition(
                  TextPosition(offset: coach.coachNumber.length),
                ),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Enter',
                contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                isDense: true,
              ),
              onChanged: (value) {
                controller.updateCoachNumber(index, value);
              },
            ),
          ),
        ),
        DataCell(_buildScoreDropdown(
          controller: controller,
          value: coach.jetCleaningScore,
          onChanged: (value) {
            controller.updateJetCleaningScore(index, value);
          },
        )),
        DataCell(_buildScoreDropdown(
          controller: controller,
          value: coach.basinCleaningScore,
          onChanged: (value) {
            controller.updateBasinCleaningScore(index, value);
          },
        )),
        DataCell(_buildScoreDropdown(
          controller: controller,
          value: coach.garbageCollectionScore,
          onChanged: (value) {
            controller.updateGarbageCollectionScore(index, value);
          },
        )),
        DataCell(
          SizedBox(
            width: 120,
            child: TextField(
              controller: TextEditingController(text: coach.remarks)
                ..selection = TextSelection.fromPosition(
                  TextPosition(offset: coach.remarks.length),
                ),
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Optional',
                contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                isDense: true,
              ),
              onChanged: (value) {
                controller.updateCoachRemarks(index, value);
              },
            ),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: controller.getGradeColor(grade).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$totalScore',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: controller.getGradeColor(grade),
              ),
            ),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: controller.getGradeColor(grade).withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: controller.getGradeColor(grade)),
            ),
            child: Text(
              grade,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: controller.getGradeColor(grade),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScoreDropdown({
    required CTSScorecardController controller,
    required int? value,
    required Function(int?) onChanged,
  }) {
    return SizedBox(
      width: 60,
      height: 35,
      child: DropdownButtonFormField<int>(
        value: value,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          isDense: true,
        ),
        items: [0, 1, 2, 3].map((score) {
          return DropdownMenuItem(
            value: score,
            child: Center(
              child: Text(
                '$score',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: score >= 2 ? Colors.green : (score == 1 ? Colors.orange : Colors.red),
                ),
              ),
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildMachinesCard(CTSScorecardController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.build, color: kRailwayBlue, size: 20),
              SizedBox(width: 8),
              Text(
                "Machines Used",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...controller.machines.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CheckboxListTile(
                  title: Text(
                    entry.key,
                    style: const TextStyle(fontSize: 13),
                  ),
                  value: entry.value,
                  onChanged: (bool? value) {
                    controller.updateMachine(entry.key, value ?? false);
                  },
                  activeColor: kRailwayBlue,
                  dense: true,
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildChemicalsCard(CTSScorecardController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.science, color: kRailwayBlue, size: 20),
              SizedBox(width: 8),
              Text(
                "Chemicals used (ml)",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(const Color(0xffe9edff)),
              border: TableBorder.all(color: Colors.grey.shade300),
              columnSpacing: 12,
              headingRowHeight: 40,
              dataRowHeight: 50,
              columns: const [
                DataColumn(label: Text('Sr.', style: _headerStyle)),
                DataColumn(label: Text('Chemical Type', style: _headerStyle)),
                DataColumn(label: Text('Brand', style: _headerStyle)),
                DataColumn(label: Text('Quantity (ml)', style: _headerStyle)),
              ],
              rows: List.generate(
                controller.chemicals.length,
                (index) => DataRow(
                  cells: [
                    DataCell(Text('${index + 1}', style: const TextStyle(fontSize: 12))),
                    DataCell(
                      SizedBox(
                        width: 100,
                        child: Text(
                          controller.chemicals[index].type,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 90,
                        child: TextField(
                          controller: TextEditingController(text: controller.chemicals[index].brand)
                            ..selection = TextSelection.fromPosition(
                              TextPosition(offset: controller.chemicals[index].brand.length),
                            ),
                          style: const TextStyle(fontSize: 12),
                          decoration: InputDecoration(
                            hintText: 'Brand',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                            isDense: true,
                          ),
                          onChanged: (value) {
                            controller.updateChemicalBrand(index, value);
                          },
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 60,
                        child: TextField(
                          controller: TextEditingController(text: controller.chemicals[index].quantity)
                            ..selection = TextSelection.fromPosition(
                              TextPosition(offset: controller.chemicals[index].quantity.length),
                            ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(fontSize: 12,),
                          decoration: InputDecoration(
                            hintText: 'Qty',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                            isDense: true,
                          ),
                          onChanged: (value) {
                            controller.updateChemicalQuantity(index, value);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(CTSScorecardController controller) {
    double avgScore = controller.calculateAverageScore();
    String overallGrade = controller.getGrade(avgScore);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xfff9fafc),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.analytics_outlined, color: kRailwayBlue, size: 26),
              SizedBox(width: 8),
              Text(
                "Summary",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _summaryBadge(
                "Average Score",
                avgScore.toStringAsFixed(2),
                kRailwayBlue,
              ),
              _summaryBadge(
                "Overall Grade",
                overallGrade,
                controller.getGradeColor(overallGrade),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: controller.getGradeColor(overallGrade), width: 2),
            ),
            child: Column(
              children: [
                const Text(
                  'Grade Distribution',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
                const SizedBox(height: 12),
                _buildGradeDistribution(controller),
              ],
            ),
          )

        ],
      ),
    );
  }

  Widget _summaryBadge(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildGradeDistribution(CTSScorecardController controller) {
    Map<String, int> gradeCount = {"A": 0, "B": 0, "C": 0, "D": 0};

    for (var coach in controller.coachesData) {
      if (coach.jetCleaningScore != null &&
          coach.basinCleaningScore != null &&
          coach.garbageCollectionScore != null) {
        int total = coach.jetCleaningScore! + coach.basinCleaningScore! + coach.garbageCollectionScore!;
        String grade = controller.getGrade(total.toDouble());
        gradeCount[grade] = (gradeCount[grade] ?? 0) + 1;
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: ['A', 'B', 'C', 'D'].map((grade) {
        return Column(
          children: [
            Text(
              grade,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: controller.getGradeColor(grade),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: controller.getGradeColor(grade).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${gradeCount[grade]}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: controller.getGradeColor(grade),
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildSignatureCard(CTSScorecardController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Railway Sign-off',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          if (controller.signedBy.value == null) ...[
            const Text('Click "Submit" button to provide your digital signature'),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(30),
              child: Column(
                children: const [
                  Icon(Icons.draw, size: 40, color: Colors.grey),
                  SizedBox(height: 10),
                  Text('No Signature Yet', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  Text(
                    'Signature will be recorded upon submission',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green, width: 2),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(Icons.check_circle, size: 40, color: Colors.green),
                  const SizedBox(height: 10),
                  Text(
                    'Signed by: ${controller.signedBy.value}',
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Inspector Type: ${controller.inspectorType.value}',
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const InfoRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.black87),
          ),
        ),
      ],
    );
  }
}
