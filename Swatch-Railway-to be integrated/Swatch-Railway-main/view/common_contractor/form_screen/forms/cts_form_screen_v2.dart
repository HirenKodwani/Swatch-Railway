import 'package:crm_train/utills/app_colors.dart';
import 'package:crm_train/view/common_contractor/form_screen/forms/widgets/cts_bottom_bar.dart';
import 'package:crm_train/view/common_contractor/form_screen/forms/widgets/cts_step1_basic_info.dart';
import 'package:crm_train/view/common_contractor/form_screen/forms/widgets/cts_step2_attendance.dart';
import 'package:crm_train/view/common_contractor/form_screen/forms/widgets/cts_step3_disposal.dart';
import 'package:crm_train/view/common_contractor/form_screen/forms/widgets/cts_step4_submit.dart';
import 'package:crm_train/view/common_contractor/form_screen/forms/widgets/cts_step_header.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../controller/cts_form_controller.dart';
import '../../../../model/cts_form_model.dart';

class NewCTSFormScreen extends StatefulWidget {
  final CTSForm? existingForm;
  final bool isResubmit;

  const NewCTSFormScreen({
    super.key,
    this.existingForm,
    this.isResubmit = false,
  });

  @override
  State<NewCTSFormScreen> createState() => _NewCTSFormScreenState();
}

class _NewCTSFormScreenState extends State<NewCTSFormScreen> {
  late CTSFormController controller;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    controller = Get.put(CTSFormController());
    _loadFormData();
  }

  Future<void> _loadFormData() async {
    if (widget.isResubmit && widget.existingForm != null) {
      setState(() => _isLoading = true);
      await controller.loadExistingForm(widget.existingForm!);
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            'Loading Form...',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: kRailwayBlue,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.isResubmit ? 'Resubmit CTS Form' : 'New CTS Form',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: kRailwayBlue,
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Obx(
              () => CTSStepHeader(currentStep: controller.currentStep.value),
            ),
          ),
          const Divider(height: 20),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Obx(() {
                switch (controller.currentStep.value) {
                  case 0:
                    return const CTSStep1BasicInfo();
                  case 1:
                    return const CTSStep2Attendance();
                  case 2:
                    return const CTSStep3Disposal();
                  case 3:
                    return const CTSStep4Submit();
                  default:
                    return const CTSStep1BasicInfo();
                }
              }),
            ),
          ),
          Obx(
            () => CTSBottomBar(
              currentStep: controller.currentStep.value,
              isSubmitting: controller.isSubmitting.value,
              onBack: controller.previousStep,
              onCancel: () {
                controller.resetForm();
                Navigator.pop(context);
              },
              onNext: controller.nextStep,
              onSubmit: () {
                if (controller.signedBy.value == null) {
                  controller.openSignDialog().then((_) {
                    if (controller.signedBy.value != null) {
                      controller.submitForm(context);
                    }
                  });
                } else {
                  controller.submitForm(context);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
