import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/api_services.dart';
import '../model/cts_form_model.dart';

class CTSScorecardController extends GetxController {
  final currentStep = 0.obs;
  final isSubmitting = false.obs;
  bool isInitialized = false;

  String? formId;
  CTSForm? ctsForm;

  final signedBy = Rx<String?>(null);
  final totalCoaches = 22.obs;
  final attendedCoaches = 22.obs;
  final selectedTrainNumber = Rx<int?>(null);
  final trainName = Rx<String?>(null);
  final workStartTime = Rx<DateTime?>(DateTime.now());
  final workEndTime = Rx<DateTime?>(null);
  final inspectorType = 'Supervisor'.obs;
  final samplingPercentage = 20.0.obs;

  void setFormId(String id) {
    formId = id;
    resetFormData();
    isInitialized = true;
  }

  void setFormData(CTSForm form) {
    ctsForm = form;
    formId = form.uid;
    resetFormData();
    isInitialized = true;
  }

  void resetFormData() {
    currentStep.value = 0;
    isSubmitting.value = false;
    signedBy.value = null;
    totalCoaches.value = 22;
    attendedCoaches.value = 22;
    selectedTrainNumber.value = null;
    trainName.value = null;
    workStartTime.value = DateTime.now();
    workEndTime.value = null;
    inspectorType.value = 'Supervisor';
    samplingPercentage.value = 20.0;

    machines.forEach((key, value) {
      machines[key] = false;
    });
    machines.refresh();

    chemicals.value = [
      ChemicalData(type: "Toilet Bowl Cleaner (Bio-safe)", brand: "", quantity: ""),
      ChemicalData(type: "Disinfectant Cleaner", brand: "", quantity: ""),
      ChemicalData(type: "Floor Cleaner (Heavy-duty)", brand: "", quantity: ""),
      ChemicalData(type: "Degreasing Agent", brand: "", quantity: ""),
      ChemicalData(type: "Glass / Washbasin Cleaner", brand: "", quantity: ""),
      ChemicalData(type: "Deodorizer / Odour Neutralizer", brand: "", quantity: ""),
      ChemicalData(type: "Bio-digester safe enzyme solution", brand: "", quantity: ""),
      ChemicalData(type: "Anti-scaling agent (bio-safe)", brand: "", quantity: ""),
      ChemicalData(type: "Neutral pH cleaners", brand: "", quantity: ""),
    ];

    generateCoachesData();
  }

  final coachesData = <CTSCoachData>[].obs;

  final machines = <String, bool>{
    "High Pressure Jet Cleaning Machine": false,
    "Wet & Dry Industrial Vacuum Cleaner": false,
    "Portable Jet Washer (Electric/Diesel)": false,
    "Water Spray / Jet Gun with Hose Pipe": false,
    "Floor scrubbers / long-handle brushes": false,
    "Toilet pan brushes": false,
    "Mops (wet & dry)": false,
    "Buckets & mugs": false,
    "Garbage collection bins (handheld)": false,
    "Trolleys for waste transfer": false,
  }.obs;

  final chemicals = <ChemicalData>[
    ChemicalData(type: "Toilet Bowl Cleaner (Bio-safe)", brand: "", quantity: ""),
    ChemicalData(type: "Disinfectant Cleaner", brand: "", quantity: ""),
    ChemicalData(type: "Floor Cleaner (Heavy-duty)", brand: "", quantity: ""),
    ChemicalData(type: "Degreasing Agent", brand: "", quantity: ""),
    ChemicalData(type: "Glass / Washbasin Cleaner", brand: "", quantity: ""),
    ChemicalData(type: "Deodorizer / Odour Neutralizer", brand: "", quantity: ""),
    ChemicalData(type: "Bio-digester safe enzyme solution", brand: "", quantity: ""),
    ChemicalData(type: "Anti-scaling agent (bio-safe)", brand: "", quantity: ""),
    ChemicalData(type: "Neutral pH cleaners", brand: "", quantity: ""),
  ].obs;

  @override
  void onInit() {
    super.onInit();
    generateCoachesData();
  }

  void generateCoachesData() {
    int sampleSize = (totalCoaches.value * samplingPercentage.value / 100).ceil();
    if (sampleSize > totalCoaches.value) sampleSize = totalCoaches.value;

    coachesData.value = List.generate(sampleSize, (index) {
      return CTSCoachData(
        position: null,
        coachNumber: '',
        jetCleaningScore: null,
        basinCleaningScore: null,
        garbageCollectionScore: null,
        remarks: '',
      );
    });
  }

  void updateWorkStartTime(DateTime value) {
    workStartTime.value = value;
  }

  void updateWorkEndTime(DateTime value) {
    workEndTime.value = value;
  }

  Future<void> selectDateTime(
      BuildContext context,
      String dateTimeType,
      {DateTime? initialDateTime}
      ) async {
    final dateTimeObservable = dateTimeType == 'start' ? workStartTime : workEndTime;
    final initial = initialDateTime ?? dateTimeObservable.value ?? DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (pickedDate != null && context.mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initial),
      );

      if (pickedTime != null) {
        final newDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        dateTimeObservable.value = newDateTime;
        debugPrint('DateTime updated ($dateTimeType): $newDateTime');
      }
    }
  }

  Future<void> openSignDialog(BuildContext context) async {
    final controller = TextEditingController();
    final res = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Digital Signature'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Your full name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Sign'),
          ),
        ],
      ),
    );

    if (res != null && res.isNotEmpty) {
      signedBy.value = res;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Signed by $res'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  String getGrade(double avgScore) {
    if (avgScore >= 8) return 'A';
    if (avgScore >= 6) return 'B';
    if (avgScore >= 4) return 'C';
    return 'D';
  }

  Color getGradeColor(String grade) {
    switch (grade) {
      case 'A':
        return Colors.green;
      case 'B':
        return Colors.blue;
      case 'C':
        return Colors.orange;
      case 'D':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  double calculateAverageScore() {
    if (coachesData.isEmpty) return 0;

    int totalScore = 0;
    int validCoaches = 0;

    for (var coach in coachesData) {
      if (coach.jetCleaningScore != null &&
          coach.basinCleaningScore != null &&
          coach.garbageCollectionScore != null) {
        totalScore += coach.jetCleaningScore! +
            coach.basinCleaningScore! +
            coach.garbageCollectionScore!;
        validCoaches++;
      }
    }

    if (validCoaches == 0) return 0;
    return totalScore / validCoaches;
  }

  void nextStep(BuildContext context) {
    if (currentStep.value == 0) {
      if (workStartTime.value == null || workEndTime.value == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select work start and end times'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    if (currentStep.value == 1) {
      for (var coach in coachesData) {
        if (coach.position == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter coach position for all coaches'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        if (coach.coachNumber.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter coach number for all coaches'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        if (coach.jetCleaningScore == null ||
            coach.basinCleaningScore == null ||
            coach.garbageCollectionScore == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please complete all scores for all coaches'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }
    }

    if (currentStep.value < 3) {
      currentStep.value++;
    }
  }

  void previousStep() {
    if (currentStep.value > 0) {
      currentStep.value--;
    }
  }

  Future<void> validateAndSubmit(BuildContext context) async {
    if (isSubmitting.value) return;

    if (formId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Form ID is missing'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (signedBy.value == null) {
      await openSignDialog(context);
      if (signedBy.value == null) return;
    }

    isSubmitting.value = true;

    try {
      final inspectionHeader = {
        "workStart": workStartTime.value!.toIso8601String(),
        "workEnd": workEndTime.value!.toIso8601String(),
        "inspectorType": inspectorType.value,
        "totalCoaches": totalCoaches.value,
        "coachesAttended": attendedCoaches.value,
        "samplingPercentage": samplingPercentage.value.toInt(),
      };

      final coachEvaluationTable = coachesData.map((c) {
        return {
          "coachPosition": "L${c.position}",
          "coachNo": c.coachNumber,
          "jetCleaningScore": c.jetCleaningScore ?? 0,
          "basinCleaningScore": c.basinCleaningScore ?? 0,
          "disposalScore": c.garbageCollectionScore ?? 0,
          "remarks": c.remarks.isEmpty ? "N/A" : c.remarks,
        };
      }).toList();

      final machinesUsed = machines.entries
          .where((entry) => entry.value == true)
          .map((entry) => entry.key)
          .toList();

      final chemicalsData = chemicals
          .where((c) => c.brand.isNotEmpty && c.quantity.isNotEmpty)
          .map((c) {
        return {
          "name": c.type,
          "brand": c.brand,
          "quantity": c.quantity,
        };
      }).toList();

      final result = await ApiService.submitCTSScorecard(
        formId: formId!,
        inspectionHeader: inspectionHeader,
        coachEvaluationTable: coachEvaluationTable,
        machinesUsed: machinesUsed,
        chemicals: chemicalsData,
        railwaySignatureName: signedBy.value!,
        railwaySignatureDate: DateTime.now().toIso8601String(),
      );

      if (result['success'] == true) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('CTS Scorecard submitted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }

        await Future.delayed(const Duration(milliseconds: 500));

        if (context.mounted) {
          Navigator.pop(context, true);
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Submission failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Submission failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      isSubmitting.value = false;
    }
  }

  void updateTotalCoaches(int value) {
    totalCoaches.value = value;
    if (attendedCoaches.value > totalCoaches.value) {
      attendedCoaches.value = totalCoaches.value;
    }
    generateCoachesData();
  }

  void updateAttendedCoaches(int value) {
    attendedCoaches.value = value;
  }

  void updateSamplingPercentage(double value) {
    samplingPercentage.value = value;
    generateCoachesData();
  }

  void updateInspectorType(String value) {
    inspectorType.value = value;
  }

  void updateMachine(String key, bool value) {
    machines[key] = value;
    machines.refresh();
  }

  void updateCoachPosition(int index, int? value) {
    if (index < coachesData.length) {
      coachesData[index].position = value;
      coachesData.refresh();
    }
  }

  void updateCoachNumber(int index, String value) {
    if (index < coachesData.length) {
      coachesData[index].coachNumber = value;
      coachesData.refresh();
    }
  }

  void updateJetCleaningScore(int index, int? value) {
    if (index < coachesData.length) {
      coachesData[index].jetCleaningScore = value;
      coachesData.refresh();
    }
  }

  void updateBasinCleaningScore(int index, int? value) {
    if (index < coachesData.length) {
      coachesData[index].basinCleaningScore = value;
      coachesData.refresh();
    }
  }

  void updateGarbageCollectionScore(int index, int? value) {
    if (index < coachesData.length) {
      coachesData[index].garbageCollectionScore = value;
      coachesData.refresh();
    }
  }

  void updateCoachRemarks(int index, String value) {
    if (index < coachesData.length) {
      coachesData[index].remarks = value;
      coachesData.refresh();
    }
  }

  void updateChemicalBrand(int index, String value) {
    if (index < chemicals.length) {
      chemicals[index].brand = value;
      chemicals.refresh();
    }
  }

  void updateChemicalQuantity(int index, String value) {
    if (index < chemicals.length) {
      chemicals[index].quantity = value;
      chemicals.refresh();
    }
  }
}

class CTSCoachData {
  int? position;
  String coachNumber;
  int? jetCleaningScore;
  int? basinCleaningScore;
  int? garbageCollectionScore;
  String remarks;

  CTSCoachData({
    required this.position,
    required this.coachNumber,
    this.jetCleaningScore,
    this.basinCleaningScore,
    this.garbageCollectionScore,
    required this.remarks,
  });
}

class ChemicalData {
  final String type;
  String brand;
  String quantity;

  ChemicalData({
    required this.type,
    required this.brand,
    required this.quantity,
  });
}
