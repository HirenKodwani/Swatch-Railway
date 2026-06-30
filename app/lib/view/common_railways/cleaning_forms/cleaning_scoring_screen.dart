import 'package:crm_train/model/cleaning_form_models.dart';
import 'package:crm_train/services/api_services.dart';
import 'package:crm_train/utills/app_colors.dart';
import 'package:flutter/material.dart';

class CleaningScoringScreen extends StatefulWidget {
  final String formUid;
  const CleaningScoringScreen({super.key, required this.formUid});

  @override
  State<CleaningScoringScreen> createState() => _CleaningScoringScreenState();
}

class _CleaningScoringScreenState extends State<CleaningScoringScreen> {
  CleaningForm? form;
  bool isLoading = true;
  bool isSubmitting = false;
  String? error;

  late List<_CriterionState> criteria;
  final TextEditingController _overallRemarksController = TextEditingController();

  static const Map<String, double> _coachCriteria = {
    'Internal Cleaning': 25,
    'Toilet Cleaning': 25,
    'External Cleaning': 20,
    'Amenities': 15,
    'Overall Presentation': 15,
  };

  static const Map<String, double> _premiseCriteria = {
    'Housekeeping': 30,
    'Pit Line Cleaning': 25,
    'Garbage Disposal': 25,
    'Safety Compliance': 20,
  };

  @override
  void initState() {
    super.initState();
    _loadForm();
  }

  @override
  void dispose() {
    _overallRemarksController.dispose();
    super.dispose();
  }

  Future<void> _loadForm() async {
    setState(() { isLoading = true; error = null; });
    try {
      final data = await ApiService.getCleaningFormDetail(widget.formUid);
      if (mounted) {
        final f = CleaningForm.fromJson(data['form']);
        final criteriaDefs = f.formType == FormType.coach ? _coachCriteria : _premiseCriteria;
        final existingCriteria = f.scoringData?['criteria'] as List? ?? [];
        criteria = criteriaDefs.entries.map((e) {
          final existing = existingCriteria.cast<Map<String, dynamic>>().firstWhere(
            (c) => c['name'] == e.key,
            orElse: () => <String, dynamic>{},
          );
          return _CriterionState(
            name: e.key,
            maxScore: e.value,
            score: (existing['score'] as num?)?.toDouble() ?? 0,
            remarksController: TextEditingController(text: existing['remarks'] as String? ?? ''),
          );
        }).toList();
        if (f.scoringData?['remarks'] != null) {
          _overallRemarksController.text = f.scoringData!['remarks'] as String;
        }
        setState(() { form = f; isLoading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { isLoading = false; error = e.toString(); });
    }
  }

  double get _totalScore => criteria.fold(0, (sum, c) => sum + c.score);

  String get _grade {
    final pct = (_totalScore / 100) * 100;
    if (pct >= 90) return 'A';
    if (pct >= 80) return 'B';
    if (pct >= 70) return 'C';
    if (pct >= 60) return 'D';
    return 'F';
  }

  Color get _gradeColor {
    switch (_grade) {
      case 'A': return kSuccessGreen;
      case 'B': return kRailwayBlue;
      case 'C': return kWarningOrange;
      case 'D': return kAccentYellow;
      case 'F': return kErrorRed;
      default: return kTextSecondary;
    }
  }

  Future<void> _submitScore() async {
    setState(() { isSubmitting = true; });
    try {
      final criteriaList = criteria.map((c) => {
        'name': c.name,
        'maxScore': c.maxScore,
        'score': c.score,
        'remarks': c.remarksController.text,
      }).toList();

      await ApiService.scoreCleaningForm(
        widget.formUid,
        totalScore: _totalScore,
        maxTotalScore: 100,
        criteria: criteriaList,
        grade: _grade,
        remarks: _overallRemarksController.text,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Score submitted successfully'),
            backgroundColor: kSuccessGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: kErrorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() { isSubmitting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          form != null
              ? 'Score ${form!.formType == FormType.coach ? 'Coach' : 'Premise'} Cleaning'
              : 'Scoring',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: kRailwayBlue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text('Error: $error'))
              : form == null
                  ? const Center(child: Text('Form not found'))
                  : _buildBody(),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFormInfo(),
                const SizedBox(height: 20),
                ...criteria.asMap().entries.map((e) => Padding(
                  padding: EdgeInsets.only(bottom: e.key < criteria.length - 1 ? 16 : 0),
                  child: _buildCriterionCard(e.value),
                )),
              ],
            ),
          ),
        ),
        _buildBottomBar(),
      ],
    );
  }

  Widget _buildFormInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: kRailwayBannerGradient,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                form!.formType == FormType.coach ? Icons.train : Icons.business,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      form!.formId,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${form!.entityName} • ${form!.cleaningDate}',
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCriterionCard(_CriterionState criterion) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    criterion.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: kRailwayBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Max: ${criterion.maxScore.toInt()}',
                    style: const TextStyle(fontSize: 12, color: kRailwayBlue, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                '${criterion.score.toInt()}',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: criterion.score > 0 ? kRailwayBlue : Colors.grey.shade400,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                '/ ${criterion.maxScore.toInt()}',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              ),
            ),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: kRailwayBlue,
                inactiveTrackColor: kRailwayBlue.withOpacity(0.2),
                thumbColor: kRailwayBlue,
                overlayColor: kRailwayBlue.withOpacity(0.1),
                valueIndicatorColor: kRailwayBlue,
                valueIndicatorTextStyle: const TextStyle(color: Colors.white),
              ),
              child: Slider(
                value: criterion.score,
                min: 0,
                max: criterion.maxScore,
                divisions: criterion.maxScore.toInt(),
                label: '${criterion.score.toInt()}',
                onChanged: (v) => setState(() { criterion.score = v; }),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: criterion.remarksController,
              decoration: InputDecoration(
                hintText: 'Remarks for ${criterion.name}',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                isDense: true,
              ),
              maxLines: 2,
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final total = _totalScore;
    final grade = _grade;
    final gradeColor = _gradeColor;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Score: ${total.toStringAsFixed(0)}/100',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: gradeColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: gradeColor),
                    ),
                    child: Text(
                      'Grade $grade',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: gradeColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _overallRemarksController,
                decoration: InputDecoration(
                  hintText: 'Overall remarks',
                  hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  isDense: true,
                ),
                maxLines: 2,
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : _submitScore,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kRailwayBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: isSubmitting
                      ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Submit Score', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CriterionState {
  final String name;
  final double maxScore;
  double score;
  final TextEditingController remarksController;

  _CriterionState({
    required this.name,
    required this.maxScore,
    this.score = 0,
    required this.remarksController,
  });
}
