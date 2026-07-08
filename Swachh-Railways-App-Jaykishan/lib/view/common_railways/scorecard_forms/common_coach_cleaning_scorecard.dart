import 'dart:convert';
import 'package:crm_train/model/coach_form_model.dart';
import 'package:crm_train/services/api_services.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CommonCoachCleaningScorecard extends StatefulWidget {
 final CoachForm form;
  const CommonCoachCleaningScorecard({super.key, required this.form});

  @override
  State<CommonCoachCleaningScorecard> createState() => _CommonCoachCleaningScorecardState();
}

class _CommonCoachCleaningScorecardState extends State<CommonCoachCleaningScorecard> {
  String selectedLocation = "Ghorpadi";
  int? selectedPitNumber;
  int? selectedCoachNumber;

  final List<String> locations = [
    "GICC",
    "OWS",
    "NWS",
    "Platform",
    "Pune Yard",
    "Hadapsar",
    "Khadki"
  ];

  String selectedWorkType = "Primary Cleaning";

  final List<String> workType = [
    "Primary Cleaning",
    "Secondary Cleaning",
    "Intensive Cleaning",
    "RBPC(Without Machine)",
    "RBPC(With Machine)",
  ];

  String selectedACWPStatus = "With ACWP";
  String? _signedBy;
  bool _isSubmitting = false;
  bool _isSavingDraft = false;


  final List<String> acwpStatus = [
    "With ACWP",
    "Without ACWP",
    "NA",
  ];

  List<CoachData> coachesData = [];

  @override
  void initState() {
    super.initState();
    _loadDraftData();
  }

  Future<void> _loadDraftData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftKey = 'coach_scorecard_draft_${widget.form.uid}';
      final draftJson = prefs.getString(draftKey);

      if (draftJson != null && draftJson.isNotEmpty) {
        final draft = jsonDecode(draftJson) as Map<String, dynamic>;

        setState(() {
          if (draft['workType'] != null) {
            selectedWorkType = draft['workType'];
          }
          if (draft['acwpStatus'] != null) {
            selectedACWPStatus = draft['acwpStatus'];
          }

          if (draft['coachEvaluationTable'] != null) {
            final tableData = draft['coachEvaluationTable'] as List;
            selectedCoachNumber = tableData.length;
            coachesData = tableData.asMap().entries.map((entry) {
              final data = entry.value as Map<String, dynamic>;
              return CoachData(
                position: entry.key + 1,
                coachNumber: data['coachNumber'] ?? '',
                internalGrade: data['internalCleaning'] != null && data['internalCleaning'] != 'NA' ? data['internalCleaning'] : null,
                externalGrade: data['externalCleaning'] != null && data['externalCleaning'] != 'NA' ? data['externalCleaning'] : null,
                intensiveGrade: data['intensiveCleaning'] != null && data['intensiveCleaning'] != 'NA' ? data['intensiveCleaning'] : null,
                toiletries: data['toiletries'] ?? 'NA',
                doorsLocked: data['doorsLocking'] ?? 'Yes',
                watering: data['watering'] ?? 'Yes',
                internalRemark: '',
                externalRemark: '',
                intensiveRemark: '',
              );
            }).toList();
          }
        });
        _showSnack('Draft loaded from local storage');
      } else {
      }
    } catch (e, stackTrace) {
      print('Error loading draft data: $e');
      print('Stack trace: $stackTrace');
    }
  }

  Future<void> _saveDraftLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftKey = 'coach_scorecard_draft_${widget.form.uid}';

      List<Map<String, dynamic>> table = coachesData.map((c) {
        return {
          "coachNumber": c.coachNumber,
          "internalCleaning": c.internalGrade ?? 'NA',
          "externalCleaning": c.externalGrade ?? 'NA',
          "intensiveCleaning": c.intensiveGrade ?? 'NA',
          "toiletries": c.toiletries ?? 'NA',
          "doorsLocking": c.doorsLocked ?? 'Yes',
          "watering": c.watering ?? 'Yes',
        };
      }).toList();

      final draftData = {
        "workType": selectedWorkType,
        "acwpStatus": selectedACWPStatus,
        "coachEvaluationTable": table,
      };

      final draftJson = jsonEncode(draftData);
      await prefs.setString(draftKey, draftJson);
    } catch (e) {
      print('Error saving draft locally: $e');
      rethrow;
    }
  }

  Future<void> _clearDraftLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftKey = 'coach_scorecard_draft_${widget.form.uid}';
      await prefs.remove(draftKey);
    } catch (e) {
      print('Error clearing draft: $e');
    }
  }

  Future<void> _openSignDialog() async {
    final controller = TextEditingController();
    final res = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Provide digital signature (type name)'),
        content:
        TextField(controller: controller, decoration: const InputDecoration(hintText: 'Your full name')),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(controller.text.trim()), child: const Text('Sign')),
        ],
      ),
    );

    if (res != null && res.isNotEmpty) {
      setState(() {
        _signedBy = res;
      });
      _showSnack('Signed by $_signedBy');
    }
  }

  void _showSnack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));



  bool _isDuplicateCoachNumber(String coachNumber, int currentIndex) {
    if (coachNumber.isEmpty) return false;

    return coachesData
        .asMap()
        .entries
        .any((entry) =>
            entry.key != currentIndex &&
            entry.value.coachNumber.toLowerCase() == coachNumber.toLowerCase());
  }

  bool _hasAnyDuplicateCoachNumbers() {
    if (coachesData.isEmpty) return false;

    final coachNumbers = coachesData
        .where((c) => c.coachNumber.isNotEmpty)
        .map((c) => c.coachNumber.toLowerCase())
        .toList();

    return coachNumbers.length != coachNumbers.toSet().length;
  }

  void _updateCoachCount(int? count) {
    if (count == null) return;

    setState(() {
      selectedCoachNumber = count;
      coachesData = List.generate(
        count,
            (index) => CoachData(
          position: index + 1,
          coachNumber: '',
          internalGrade: null,
          externalGrade: null,
          intensiveGrade: null,
          toiletries: null,
          doorsLocked: null,
          watering: null,
          internalRemark: '',
          externalRemark: '',
          intensiveRemark: '',
        ),
      );
    });
  }

  Widget _buildCoachesTable() {
    if (coachesData.isEmpty) return const SizedBox.shrink();
    for (var coach in coachesData) {
      coach.toiletries ??= 'NA';
      coach.doorsLocked ??= 'Yes';
      coach.watering ??= 'Yes';
    }


    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8), // ↓ Reduced margin
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
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: const [
                Icon(Icons.table_chart, color: Color(0xff4059ed), size: 18),
                SizedBox(width: 6),
                Text(
                  "Coach Evaluation Table",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            padding: EdgeInsets.zero,
            scrollDirection: Axis.horizontal,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DataTable(
                headingRowColor:
                MaterialStateProperty.all(const Color(0xffe9edff)),
                border: TableBorder(
                  horizontalInside: BorderSide(color: Colors.grey.shade300),
                  verticalInside: BorderSide(color: Colors.grey.shade300),
                ),
                columnSpacing: 10,
                headingRowHeight: 40,
                dataRowHeight: 50,
                columns: const [
                  DataColumn(label: Text('Sr.\nNo.', style: _headerStyle)),
                  DataColumn(label: Text('Coach\nNumber', style: _headerStyle)),
                  DataColumn(label: Text('Internal\nCleaning', style: _headerStyle)),
                  DataColumn(label: Text('External\nCleaning', style: _headerStyle)),
                  DataColumn(label: Text('Intensive\nCleaning', style: _headerStyle)),
                  DataColumn(label: Text('Toiletries', style: _headerStyle)),
                  DataColumn(label: Text('Doors\nLocking', style: _headerStyle)),
                  DataColumn(label: Text('Watering', style: _headerStyle)),
                  DataColumn(label: Text('Penalty\n(₹)', style: _headerStyle)),
                ],
                rows: List.generate(
                  coachesData.length,
                      (index) => _buildDataRow(index),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  static const TextStyle _headerStyle =
  TextStyle(fontWeight: FontWeight.bold, fontSize: 11);

  DataRow _buildDataRow(int index) {
    final coach = coachesData[index];

    return DataRow(
      cells: [
        DataCell(
            Text('${coach.position}', style: const TextStyle(fontSize: 12))),
        DataCell(
          SizedBox(
            width: 80,
            height: 30,
            child: TextField(
              controller: TextEditingController(text: coach.coachNumber)
                ..selection = TextSelection.fromPosition(
                  TextPosition(offset: coach.coachNumber.length),
                ),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Enter',
                hintStyle: const TextStyle(fontSize: 11),
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(
                    color: _isDuplicateCoachNumber(coach.coachNumber, index)
                        ? Colors.red
                        : Colors.grey,
                    width: _isDuplicateCoachNumber(coach.coachNumber, index) ? 2 : 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(
                    color: _isDuplicateCoachNumber(coach.coachNumber, index)
                        ? Colors.red
                        : Colors.grey.shade300,
                    width: _isDuplicateCoachNumber(coach.coachNumber, index) ? 2 : 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(
                    color: _isDuplicateCoachNumber(coach.coachNumber, index)
                        ? Colors.red
                        : Colors.blue,
                    width: 2,
                  ),
                ),
                isDense: true,
              ),
              onChanged: (value) {
                if (value.isNotEmpty) {
                  final duplicateExists = coachesData
                      .asMap()
                      .entries
                      .any((entry) =>
                          entry.key != index &&
                          entry.value.coachNumber.toLowerCase() == value.toLowerCase());

                  if (duplicateExists) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Coach number "$value" already exists! Please enter a different number.'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    return;
                  }
                }

                setState(() {
                  coachesData[index].coachNumber = value;
                });
              },
            ),
          ),
        ),
        DataCell(_buildGradeDropdown(
          value: coach.internalGrade,
          onChanged: (value) {
            setState(() {
              coachesData[index].internalGrade = value;
            });
          },
        )),
        DataCell(_buildGradeDropdown(
          value: coach.externalGrade,
          onChanged: (value) {
            setState(() {
              coachesData[index].externalGrade = value;
            });
          },
        )),
        DataCell(_buildGradeDropdown(
          value: coach.intensiveGrade,
          onChanged: (value) {
            setState(() {
              coachesData[index].intensiveGrade = value;
            });
          },
        )),
        DataCell(_buildYesNoDropdown(
          value: coach.toiletries,
          onChanged: (value) {
            setState(() {
              coachesData[index].toiletries = value;
            });
          },
        )),
        DataCell(_buildYesNoDropdown(
          value: coach.doorsLocked,
          onChanged: (value) {
            setState(() {
              coachesData[index].doorsLocked = value;
            });
          },
        )),
        DataCell(_buildYesNoDropdown(
          value: coach.watering,
          onChanged: (value) {
            setState(() {
              coachesData[index].watering = value;
            });
          },
        )),
        DataCell(Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4), // ↓ Compact
            decoration: BoxDecoration(
              color: _getPenaltyColor(coach).withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _getPenaltyColor(coach)),
            ),
            child: Text(
              '₹${_calculatePenalty(coach)}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: _getPenaltyColor(coach),
              ),
            ),
          ),
        )),
      ],
    );
  }


  Widget _buildGradeDropdown({
    required String? value,
    required Function(String?) onChanged,
  }) {
    return SizedBox(
      width: 75,
      height: 30,
      child: DropdownButtonFormField<String>(
        iconSize: 20,
        value: value,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          isDense: true,
        ),
        items: ['A', 'B', 'C', 'D', 'NA'].map((grade) {
          return DropdownMenuItem(
            value: grade,
            child: Center(
              child: Text(
                grade,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _getGradeColor(grade),
                ),
              ),
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildYesNoDropdown({
    required String? value,
    required Function(String?) onChanged,
  }) {
    return SizedBox(
      width: 80,
      height: 30,
      child: DropdownButtonFormField<String>(
        value: value,
        iconSize: 20,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          isDense: true,
        ),
        items: ['Yes', 'No', 'NA'].map((option) {
          return DropdownMenuItem(
            value: option,
            child: Center(
              child: Text(
                option,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Color _getGradeColor(String? grade) {
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

  int _calculatePenalty(CoachData coach) {
    int penalty = 0;

    if (coach.internalGrade == 'B') penalty = 50;
    if (coach.internalGrade == 'C') penalty = 100;
    if (coach.internalGrade == 'D') penalty = 200;

    if (coach.externalGrade == 'B' && penalty < 50) penalty = 50;
    if (coach.externalGrade == 'C' && penalty < 100) penalty = 100;
    if (coach.externalGrade == 'D') penalty = 200;

    return penalty;
  }

  Color _getPenaltyColor(CoachData coach) {
    int penalty = _calculatePenalty(coach);
    if (penalty == 0) return Colors.green;
    if (penalty == 50) return Colors.blue;
    if (penalty == 100) return Colors.orange;
    return Colors.red;
  }

  Widget _buildOverallGradeSummary() {
    if (coachesData.isEmpty) return const SizedBox.shrink();

    int total = selectedCoachNumber ?? 0;
    int incomplete = 0;

    Map<String, int> internal = {"A": 0, "B": 0, "C": 0, "D": 0};
    Map<String, int> external = {"A": 0, "B": 0, "C": 0, "D": 0};
    Map<String, int> intensive = {"A": 0, "B": 0, "C": 0, "D": 0};

    Map<String, int> toiletries = {"Yes": 0, "No": 0, "NA": 0};
    Map<String, int> watering = {"Yes": 0, "No": 0, "NA": 0};
    Map<String, int> doors = {"Yes": 0, "No": 0, "NA": 0};

    for (var coach in coachesData) {
      if (coach.internalGrade == null || coach.externalGrade == null) {
        incomplete++;
      }

      if (coach.internalGrade != null && coach.internalGrade != 'NA') {
        internal[coach.internalGrade!] = (internal[coach.internalGrade!] ?? 0) + 1;
      }
      if (coach.externalGrade != null && coach.externalGrade != 'NA') {
        external[coach.externalGrade!] = (external[coach.externalGrade!] ?? 0) + 1;
      }
      if (coach.intensiveGrade != null && coach.intensiveGrade != 'NA') {
        intensive[coach.intensiveGrade!] = (intensive[coach.intensiveGrade!] ?? 0) + 1;
      }

      if (coach.toiletries != null) {
        toiletries[coach.toiletries!] = (toiletries[coach.toiletries!] ?? 0) + 1;
      }
      if (coach.watering != null) {
        watering[coach.watering!] = (watering[coach.watering!] ?? 0) + 1;
      }
      if (coach.doorsLocked != null) {
        doors[coach.doorsLocked!] = (doors[coach.doorsLocked!] ?? 0) + 1;
      }
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              Icon(Icons.analytics_outlined, color: Colors.indigo, size: 26),
              SizedBox(width: 8),
              Text(
                "Overall Grade Summary",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _infoBadge("Total Coaches", "$total", Colors.indigo),
              _infoBadge("Incomplete", "$incomplete", Colors.redAccent),
            ],
          ),
          const SizedBox(height: 16),
          _divider(),

          _summarySection("Internal Cleaning", internal, grade: true),
          _summarySection("External Cleaning", external, grade: true),
          _summarySection("Intensive Cleaning", intensive, grade: true),

          _divider(),

          _summarySection("Toiletries", toiletries),
          _summarySection("Watering", watering),
          _summarySection("Doors Locked", doors),
        ],
      ),
    );
  }

  Widget _infoBadge(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _summarySection(String title, Map<String, int> data, {bool grade = false}) {
    final labels = grade ? ['A', 'B', 'C', 'D'] : ['Yes', 'No', 'NA'];
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: labels.map((l) {
              int count = data[l] ?? 0;
              return _summaryBox(label: l, value: count.toString(), grade: grade);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _summaryBox({required String label, required String value, required bool grade}) {
    Color color;
    if (grade) {
      switch (label) {
        case 'A':
          color = Colors.green;
          break;
        case 'B':
          color = Colors.lightGreen;
          break;
        case 'C':
          color = Colors.orangeAccent;
          break;
        default:
          color = Colors.redAccent;
      }
    } else {
      switch (label) {
        case 'Yes':
          color = Colors.green;
          break;
        case 'No':
          color = Colors.redAccent;
          break;
        default:
          color = Colors.orange;
      }
    }

    return Container(
      width: 65,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(label,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _divider() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Container(height: 1, color: Colors.grey.withOpacity(0.3)),
  );


  void _validateAll() async {
    if (_isSubmitting) return;

    if (selectedWorkType.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Work Type')),
      );
      return;
    }

    if (selectedACWPStatus.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select ACWP Status')),
      );
      return;
    }

    if (_signedBy == null) {
      await _openSignDialog();
      if (_signedBy == null) {
        return;
      }
    }

    if (selectedCoachNumber == null || selectedCoachNumber == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select number of coaches')),
      );
      return;
    }

    for (int i = 0; i < coachesData.length; i++) {
      final coach = coachesData[i];
      if (coach.coachNumber.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter Coach Number for Coach ${i + 1}')),
        );
        return;
      }
    }

    final coachNumbers = coachesData.map((c) => c.coachNumber.toLowerCase()).toList();
    final uniqueCoachNumbers = coachNumbers.toSet();
    if (coachNumbers.length != uniqueCoachNumbers.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Duplicate coach numbers found! Each coach must have a unique number.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    List<Map<String, dynamic>> table = coachesData.map((c) {
      return {
        "coachNumber": c.coachNumber,
        "internalCleaning": c.internalGrade ?? 'NA',
        "externalCleaning": c.externalGrade ?? 'NA',
        "intensiveCleaning": c.intensiveGrade ?? 'NA',
        "toiletries": c.toiletries ?? 'NA',
        "doorsLocking": c.doorsLocked ?? 'Yes',
        "watering": c.watering ?? 'Yes',
      };
    }).toList();

    try {
      final response = await ApiService.submitCoachScorecard(
        formId: widget.form.uid,
        workType: selectedWorkType,
        acwpStatus: selectedACWPStatus,
        coachEvaluationTable: table,
        railwaySignatureName: _signedBy!,
      );

      if (mounted) {
        await _clearDraftLocally();

        String successMessage = 'Form scored successfully!';

        if (response.containsKey('message')) {
          successMessage = response['message'].toString();
        } else if (response.containsKey('msg')) {
          successMessage = response['msg'].toString();
        } else if (response.containsKey('data') && response['data'] is Map) {
          final data = response['data'] as Map<String, dynamic>;
          if (data.containsKey('message')) {
            successMessage = data['message'].toString();
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Submission failed';

        final errorString = e.toString();
        if (errorString.contains('Exception:')) {
          errorMessage = errorString.replaceAll('Exception:', '').trim();
        } else if (errorString.contains(':')) {
          errorMessage = errorString.split(':').last.trim();
        } else {
          errorMessage = errorString;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }



  String formatDate(String isoDate) {
    final date = DateTime.parse(isoDate);
    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Coach Cleaning Scorecard',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Container(
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
                          "Train Details",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xffe9edff),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            "Scoring under progress",
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xff4059ed),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                        InfoRow(
                          label: "Train:",
                          value: "${widget.form.trainName} - ${widget.form.trainName}",
                        ),

                    const SizedBox(height: 8),
                    InfoRow(
                      label: "Submitted Date:",
                      value:  DateFormat(
                        'dd/MM/yyyy HH:mm',
                      ).format(DateTime.parse(widget.form.formDateTime).toLocal()),
                    ),
                    const SizedBox(height: 8),
                    InfoRow(label: "Division:", value: widget.form.submittedByDivision),
                    if(widget.form.submittedByDepot != null)
                    const SizedBox(height: 8),
                    if(widget.form.submittedByDepot != null)
                        InfoRow(label: "Depot:", value: widget.form.submittedByDepot ?? ''),
                    const SizedBox(height: 8),
                    InfoRow(label: "Contractor Employee:", value: widget.form.submittedByName),
                    const SizedBox(height: 8),
                     Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InfoRow(label: "No of Staff:", value: widget.form.manpower.length.toString()),
                        InfoRow(label: "Submit To :", value: widget.form.submittedTo.railwayEmployeeName),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),


              Container(
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
                    Text(
                      "Select the location and ACWP status of maintenance from options given",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedWorkType,
                      decoration: InputDecoration(
                        labelText: "Select Work Type",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: workType.map((loc) {
                        return DropdownMenuItem(
                          value: loc,
                          child: Text(
                            loc,
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedWorkType = value!;
                        });
                      },
                    ),

                    const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: selectedACWPStatus,
                    decoration: InputDecoration(
                      labelText: "External Cleaning",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: acwpStatus.map((loc) {
                      return DropdownMenuItem(
                        value: loc,
                        child: Text(
                          loc,
                          style: const TextStyle(fontSize: 14),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedACWPStatus = value!;
                      });
                    },
                  ),
                ]
              )
                    ),

              const SizedBox(height: 16),

              Container(
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
                    const Text(
                      "Grading Instructions",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _gradeBox(
                      color: const Color(0xffe8f8ec),
                      borderColor: const Color(0xff34a853),
                      text: "Grade A: Clean, no dirt or no stains - No penalty",
                      textColor: const Color(0xff1e7c3b),
                    ),
                    const SizedBox(height: 10),
                    _gradeBox(
                      color: const Color(0xffe9f1ff),
                      borderColor: const Color(0xff4a74ff),
                      text: "Grade B: Very light/minor dirt or stains visible - ₹50 penalty per coach",
                      textColor: const Color(0xff4059ed),
                    ),
                    const SizedBox(height: 10),
                    _gradeBox(
                      color: const Color(0xfffff3da),
                      borderColor: const Color(0xffffcc00),
                      text: "Grade C: Fair dirt and stains visible - ₹100 penalty per coach",
                      textColor: const Color(0xffa37200),
                    ),
                    const SizedBox(height: 10),
                    _gradeBox(
                      color: const Color(0xffffebeb),
                      borderColor: const Color(0xffe53935),
                      text: "Grade D: Severe dirt/extremely stained - ₹200 penalty / NO PAYMENT",
                      textColor: const Color(0xffc62828),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Container(
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
                        Icon(Icons.train, color: Color(0xff4059ed)),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            "Train Coaches",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Select Number of Coaches",
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 5),
                    DropdownButtonFormField<int>(
                      value: selectedCoachNumber,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: List.generate(
                        50,
                            (index) => DropdownMenuItem(
                          value: index + 1,
                          child: Text('${index + 1}'),
                        ),
                      ),
                      onChanged: _updateCoachCount,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              _buildCoachesTable(),

              const SizedBox(height: 20),

              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10)
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Digital Signature', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),

                    if (_signedBy == null) ...[
                      const Text('Click "Sign & Submit" button to provide your digital signature'),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10)
                        ),
                        padding: EdgeInsets.all(30),
                        child: Column(
                          children: [
                            Icon(Icons.draw, size: 40, color: Colors.grey),
                            const SizedBox(height: 10),
                            Text('No Signature Yet', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                            Text(
                              textAlign: TextAlign.center,
                              'Signature will be recorded upon\nsubmission',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            )
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
                        padding: EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Icon(Icons.check_circle, size: 40, color: Colors.green),
                            const SizedBox(height: 10),
                            Text('Signed by: $_signedBy', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              if (_hasAnyDuplicateCoachNumbers()) ...[
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red, width: 2),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.error_outline, color: Colors.red, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Duplicate coach numbers detected! Each coach must have a unique number. Please correct before submitting.',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (selectedCoachNumber != null && selectedCoachNumber! > 0) ...[
                _buildOverallGradeSummary(),
                const SizedBox(height: 10),
              ],

              const SizedBox(height: 80),
            ],
          ),
        ),
          ),

          if (_isSubmitting || _isSavingDraft)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
      bottomSheet: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: (_isSubmitting || _isSavingDraft) ? null : () async {
                    if (coachesData.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please add at least one coach')),
                      );
                      return;
                    }

                    setState(() {
                      _isSavingDraft = true;
                    });

                    List<Map<String, dynamic>> table = coachesData.map((c) {
                      return {
                        "coachNumber": c.coachNumber,
                        "internalCleaning": c.internalGrade ?? 'NA',
                        "externalCleaning": c.externalGrade ?? 'NA',
                        "intensiveCleaning": c.intensiveGrade ?? 'NA',
                        "toiletries": c.toiletries ?? 'NA',
                        "doorsLocking": c.doorsLocked ?? 'Yes',
                        "watering": c.watering ?? 'Yes',
                      };
                    }).toList();

                    try {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Saving draft...')),
                      );


                      await _saveDraftLocally();


                      try {
                        await ApiService.saveScoringDraft(
                          formId: widget.form.uid,
                          workType: selectedWorkType,
                          acwpStatus: selectedACWPStatus,
                          coachEvaluationTable: table,
                        );
                      } catch (apiError) {
                        print('API save failed (non-critical): $apiError');
                      }

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Draft saved locally!')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to save draft: $e')),
                        );
                      }
                    } finally {
                      if (mounted) {
                        setState(() {
                          _isSavingDraft = false;
                        });
                      }
                    }
                  },

                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text('Save Draft', style: TextStyle(color: Colors.red)),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: ElevatedButton(
                  onPressed: (_isSubmitting || _isSavingDraft || _hasAnyDuplicateCoachNumbers())
                      ? null
                      : _validateAll,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _hasAnyDuplicateCoachNumbers() ? Colors.grey : Colors.green,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    _hasAnyDuplicateCoachNumbers()
                        ? 'Duplicate Coach Numbers!'
                        : 'Sign & Submit',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _gradeBox({
    required Color color,
    required Color borderColor,
    required String text,
    required Color textColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        border: Border(
          left: BorderSide(color: borderColor, width: 4),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }



}

class InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style:
          const TextStyle(color: Colors.black54, fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(color: Colors.black87),
        ),
      ],
    );
  }
}



class CoachData {
  final int position;
  String coachNumber;
  String? internalGrade;
  String? externalGrade;
  String? intensiveGrade;
  String? toiletries;
  String? doorsLocked;
  String? watering;
  String internalRemark;
  String externalRemark;
  String intensiveRemark;

  CoachData({
    required this.position,
    required this.coachNumber,
    this.internalGrade,
    this.externalGrade,
    this.intensiveGrade,
    this.toiletries,
    this.doorsLocked,
    this.watering,
    required this.internalRemark,
    required this.externalRemark,
    required this.intensiveRemark,
  });
}




