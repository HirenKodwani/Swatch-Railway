import 'package:crm_train/model/premises_form_model.dart';
import 'package:crm_train/providers/auth_provider.dart';
import 'package:crm_train/services/api_services.dart';
import 'package:crm_train/services/draft_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'common_coach_cleaning_scorecard.dart';

class CommonPremisesCleaningScorecard extends StatefulWidget {
  final FormData model;
  const CommonPremisesCleaningScorecard({super.key, required this.model});

  @override
  State<CommonPremisesCleaningScorecard> createState() => _CommonPremisesCleaningScorecardState();
}

class _CommonPremisesCleaningScorecardState extends State<CommonPremisesCleaningScorecard> {
  String? _signedBy;
  DateTime? _signedAt;
  bool _isSubmitting = false;

  String? _currentDraftId;
  bool _isSavingDraft = false;

  bool _includePoint2 = false;
  bool _includePoint7 = false;


  Future<void> _saveDraft() async {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user?.uid == null) {
      _showSnack('Unable to save draft: User not found', isError: true);
      return;
    }

    setState(() => _isSavingDraft = true);

    try {
      final draftData = {
        'formId': widget.model.uid ?? '',
        'location': widget.model.location,
        'depot': widget.model.submittedByDepot ?? '',
        'submittedByName': widget.model.submittedByName,
        'manpowerCount': widget.model.manpower.length,
        'submittedToName': widget.model.submittedTo.railwayEmployeeName,

        'includePoint2': _includePoint2,
        'includePoint7': _includePoint7,

        'housekeepingItems': housekeepingItems.map((item) => {
          'title': item.title,
          'score1': item.score1,
          'score2': item.score2,
          'isOptional': item.isOptional,
        }).toList(),

        'pitlineItems': pitlineItems.map((item) => {
          'title': item.title,
          'score1': item.score1,
          'score2': item.score2,
        }).toList(),

        'disposalItems': disposalItems.map((item) => {
          'title': item.title,
          'score1': item.score1,
          'score2': item.score2,
        }).toList(),

        'formType': 'premises_scorecard',
        'savedAt': DateTime.now().toIso8601String(),
      };

      await DraftStorageService.savePremisesDraft(
        draftData,
        existingDraftId: _currentDraftId,
      );

      if (_currentDraftId == null) {
        _currentDraftId = draftData['draftId'] as String?;
      }

      if (mounted) {
        _showSnack('Draft saved successfully!', isError: false);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Failed to save draft: ${e.toString()}', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingDraft = false);
      }
    }
  }

  Future<void> _loadDraftIfExists() async {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user?.uid == null) return;

    try {
      final drafts = await DraftStorageService.getPremisesDraftsList();
      final formDraft = drafts.where((d) => d['formId'] == widget.model.uid).toList();

      if (formDraft.isEmpty) return;

      final draft = formDraft.first;
      _currentDraftId = draft['draftId'] as String?;

      setState(() {
        _includePoint2 = draft['includePoint2'] ?? false;
        _includePoint7 = draft['includePoint7'] ?? false;

        housekeepingItems.clear();

        housekeepingItems.add(ScoreItem('Cleaning of offices, toilets, supervisor / staff rooms, etc'));

        if (_includePoint2) {
          housekeepingItems.add(ScoreItem('Cleaning of Store / tool / equipment rooms etc', isOptional: true));
        }

        housekeepingItems.addAll([
          ScoreItem('Cleaning of IOH shed/Sick line'),
          ScoreItem('Cleaning of catwalk, pathways / roads at corridors in front of the service buildings, etc.'),
          ScoreItem('Cleaning of stabling lines'),
          ScoreItem('Desilting and cleaning of Drains / detritus chambers / sump'),
        ]);

        if (_includePoint7) {
          housekeepingItems.add(ScoreItem('Degreasing / Disinfection of pit Lines apron, drains, IOH shed', isOptional: true));
        }

        housekeepingItems.add(ScoreItem('Disposal of scrap or rejected material to nominated places'));

        final savedHousekeepingItems = List<Map<String, dynamic>>.from(draft['housekeepingItems'] ?? []);
        for (int i = 0; i < housekeepingItems.length && i < savedHousekeepingItems.length; i++) {
          if (housekeepingItems[i].title == savedHousekeepingItems[i]['title']) {
            housekeepingItems[i].score1 = savedHousekeepingItems[i]['score1'];
            housekeepingItems[i].score2 = savedHousekeepingItems[i]['score2'];
          }
        }

        final savedPitlineItems = List<Map<String, dynamic>>.from(draft['pitlineItems'] ?? []);
        for (int i = 0; i < pitlineItems.length && i < savedPitlineItems.length; i++) {
          pitlineItems[i].score1 = savedPitlineItems[i]['score1'];
          pitlineItems[i].score2 = savedPitlineItems[i]['score2'];
        }

        final savedDisposalItems = List<Map<String, dynamic>>.from(draft['disposalItems'] ?? []);
        for (int i = 0; i < disposalItems.length && i < savedDisposalItems.length; i++) {
          disposalItems[i].score1 = savedDisposalItems[i]['score1'];
          disposalItems[i].score2 = savedDisposalItems[i]['score2'];
        }
      });

    } catch (e) {
      print('Error loading draft: $e');
    }
  }


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDraftIfExists();
    });
  }

  List<ScoreItem> housekeepingItems = [
    ScoreItem('Cleaning of offices, toilets, supervisor / staff rooms, etc'),
    ScoreItem('Cleaning of IOH shed/Sick line'),
    ScoreItem('Cleaning of catwalk, pathways / roads at corridors in front of the service buildings, etc.'),
    ScoreItem('Cleaning of stabling lines'),
    ScoreItem('Desilting and cleaning of Drains / detritus chambers / sump'),
    ScoreItem('Disposal of scrap or rejected material to nominated places'),
  ];

  final List<ScoreItem> pitlineItems = [
    ScoreItem('Deep cleaning of pit-line'),
    ScoreItem('Removing garbage, debris, mud from pit-line'),
    ScoreItem('Condition of water logging in pit'),
  ];

  final List<ScoreItem> disposalItems = [
    ScoreItem('Disposal of garbage at nominated places as per PMC norms.'),
  ];

  double _toPercent(double avg) => avg.isNaN ? 0 : avg * 10;
  double _sectionAverage(List<ScoreItem> items) {
    final valid = items.map((e) => e.average).where((v) => !v.isNaN).toList();
    if (valid.isEmpty) return 0;
    return valid.reduce((a, b) => a + b) / valid.length;
  }

  double _overallAvgPercent() {
    final all = [...housekeepingItems, ...pitlineItems, ...disposalItems];
    final valid = all.map((e) => e.average).where((v) => !v.isNaN).toList();
    if (valid.isEmpty) return 0;
    return valid.reduce((a, b) => a + b) / valid.length * 10;
  }

  List<Map<String, dynamic>> _convertToApiFormat(List<ScoreItem> items) {
    return items.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      return {
        "sr": index + 1,
        "itemDescription": item.title,
        "score1": item.score1 ?? 0,
        "score2": item.score2 ?? 0,
      };
    }).toList();
  }


  bool _validateScores() {
    final allItems = [...housekeepingItems, ...pitlineItems, ...disposalItems];
    for (var item in allItems) {
      if (item.isOptional && item.isNA) {
        continue;
      }
      if (item.score1 == null || item.score2 == null) {
        return false;
      }
    }
    return true;
  }

  Future<void> _openSignAndSubmitDialog() async {
    if (!_validateScores()) {
      _showSnack('Please fill all scores before submitting', isError: true);
      return;
    }

    final controller = TextEditingController();
    final res = await showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Digital Signature Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'By signing, you confirm that all information is accurate and complete.',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Enter your full name',
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Please enter your name')),
                );
                return;
              }
              Navigator.of(ctx).pop(controller.text.trim());
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Sign & Submit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (res != null && res.isNotEmpty) {
      final signedAt = DateTime.now();
      setState(() {
        _signedBy = res;
        _signedAt = signedAt;
      });
      await _submitScorecard(res, signedAt);
    }
  }

  Future<void> _submitScorecard(String signatureName, DateTime signatureDate) async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final housekeepingData = _convertToApiFormat(housekeepingItems);
      final pitLineData = _convertToApiFormat(pitlineItems);
      final disposalData = _convertToApiFormat(disposalItems);


      final formattedDate = signatureDate.toIso8601String();

      final response = await ApiService.submitPremisesScorecard(
        formId: widget.model.uid,
        railwaySignatureName: signatureName,
        railwaySignatureDate: formattedDate,
        housekeepingItems: housekeepingData,
        pitLineItems: pitLineData,
        disposalItems: disposalData,
      );


      if (mounted) {
        _showSnack('Form successfully scored and sent to contractor.', isError: false);
        await _deleteDraftAfterSubmission();
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Failed to submit score: ${e.toString()}', isError: true);
        setState(() {
          _signedBy = null;
          _signedAt = null;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _deleteDraftAfterSubmission() async {
    if (_currentDraftId != null) {
      try {
        await DraftStorageService.deletePremisesDraft(_currentDraftId!);
      } catch (e) {
        print('Error deleting draft: $e');
      }
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  void _togglePoint2(bool? value) {
    setState(() {
      _includePoint2 = value ?? false;
      if (_includePoint2) {
        housekeepingItems.insert(1, ScoreItem('Cleaning of Store / tool / equipment rooms etc', isOptional: true));
      } else {
        housekeepingItems.removeWhere((item) => item.title == 'Cleaning of Store / tool / equipment rooms etc');
      }
    });
  }

  void _togglePoint7(bool? value) {
    setState(() {
      _includePoint7 = value ?? false;
      if (_includePoint7) {
        int insertIndex = _includePoint2 ? 6 : 5;
        housekeepingItems.insert(insertIndex, ScoreItem('Degreasing / Disinfection of pit Lines apron, drains, IOH shed', isOptional: true));
      } else {
        housekeepingItems.removeWhere((item) => item.title == 'Degreasing / Disinfection of pit Lines apron, drains, IOH shed');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final overall = _overallAvgPercent();
    return Scaffold(
      appBar: AppBar(
        title: const Text("Depot Premises Scorecard",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0.3,
      ),
      backgroundColor: const Color(0xFFF7F8FC),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(14),
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
                            "Premises Details",
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
                            child:  Text(
                              widget.model.formDateTime.toLocal().toString().substring(0, 16),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      InfoRow(label: "Location:", value: widget.model.location),
                      if(widget.model.submittedByDepot != null)
                      InfoRow(label: "Depot:", value: widget.model.submittedByDepot ?? ''),
                      InfoRow(label: "Contractor Employee:", value: widget.model.submittedByName),
                      InfoRow(label: "No of Staff:", value: widget.model.manpower.length.toString()),
                      InfoRow(label: "Submit To:", value: widget.model.submittedTo.railwayEmployeeName),
                      InfoRow(label: "Time of work started:", value: "NA"),
                      InfoRow(label: "Time of work Completed:", value: "NA"),
                    ],
                  ),
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
                        "Optional Items",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Select if applicable to this premises:",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 12),
                      CheckboxListTile(
                        value: _includePoint2,
                        onChanged: _togglePoint2,
                        title: const Text(
                          'Cleaning of Store / tool / equipment rooms etc',
                          style: TextStyle(fontSize: 14),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                      CheckboxListTile(
                        value: _includePoint7,
                        onChanged: _togglePoint7,
                        title: const Text(
                          'Degreasing / Disinfection of pit Lines apron, drains, IOH shed',
                          style: TextStyle(fontSize: 14),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _sectionCard("HOUSEKEEPING OF DEPOT PREMISES", housekeepingItems),
                const SizedBox(height: 12),
                _sectionCard("PIT-LINE CLEANING WORK", pitlineItems),
                const SizedBox(height: 12),
                _sectionCard("DISPOSAL OF GARBAGE AS PER MUNICIPAL NORM", disposalItems),
                const SizedBox(height: 20),
                _summaryCard(overall),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Digital Signature',
                          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      if (_signedBy == null) ...[
                        const Text('Click "Sign & Submit" button to provide your digital signature'),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.all(30),
                          child: const Column(
                            children: [
                              Icon(Icons.draw, size: 40, color: Colors.grey),
                              SizedBox(height: 10),
                              Text('No Signature Yet',
                                  style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
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
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              const Icon(Icons.check_circle, size: 40, color: Colors.green),
                              const SizedBox(height: 10),
                              Text('Signed by: $_signedBy',
                                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                              Text(
                                'Date: ${_signedAt!.toIso8601String().split('T')[0]}',
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
          if (_isSubmitting)
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
                  onPressed: (_isSubmitting || _isSavingDraft)
                      ? null
                      : () async {
                    await _saveDraft();
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: _isSavingDraft ? Colors.grey : Colors.blue),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: _isSavingDraft
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    'Save Draft',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _openSignAndSubmitDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    'Sign & Submit',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // dropdown field 0–10
  Widget _dropdownField({
    required int? value,
    required ValueChanged<int?> onChanged,
  }) {
    return DropdownButtonFormField<int>(
      value: value,
      items: List.generate(11, (i) {
        return DropdownMenuItem(value: i, child: Text('$i',style: TextStyle(fontSize: 12),));
      }),
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      ),
      onChanged: onChanged,
    );
  }

  Widget _sectionCard(String title, List<ScoreItem> items) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black12.withOpacity(0.05), blurRadius: 6)
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            children: [
              Container(
                color: const Color(0xFFF2F3F7),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                child: const Row(
                  children: [
                    SizedBox(width: 40, child: Text('Sr', style: TextStyle(fontWeight: FontWeight.w600))),
                    SizedBox(width: 150, child: Text('Item Description', style: TextStyle(fontWeight: FontWeight.w600))),
                    SizedBox(width: 70, child: Center(child: Text('Score 1', style: TextStyle(fontWeight: FontWeight.w600)))),
                    SizedBox(width: 70, child: Center(child: Text('Score 2', style: TextStyle(fontWeight: FontWeight.w600)))),
                    SizedBox(width: 100, child: Center(child: Text('Avg', style: TextStyle(fontWeight: FontWeight.w600)))),
                    SizedBox(width: 100, child: Center(child: Text('Avg %', style: TextStyle(fontWeight: FontWeight.w600)))),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Column(
                children: List.generate(items.length, (i) {
                  final item = items[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        SizedBox(width: 40, child: Text('${i + 1}')),
                        SizedBox(width: 150, child: Text(item.title)),
                        SizedBox(
                          width: 70,
                          child: _dropdownField(
                            value: item.score1,
                            onChanged: (v) {
                              setState(() {
                                item.score1 = v;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 70,
                          child: _dropdownField(
                            value: item.score2,
                            onChanged: (v) {
                              setState(() {
                                item.score2 = v;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                            width: 100,
                            child: Center(
                                child: Text(item.average.isNaN
                                    ? '-'
                                    : item.average.toStringAsFixed(1)))),
                        SizedBox(
                            width: 100,
                            child: Center(
                                child: Text(item.average.isNaN
                                    ? '-'
                                    : '${_toPercent(item.average).toStringAsFixed(1)}%'))),
                      ],
                    ),
                  );
                }),
              )
            ],
          ),
        )
      ]),
    );
  }

  // summary section
  Widget _summaryCard(double overall) {
    final housekeepingAvg = _toPercent(_sectionAverage(housekeepingItems));
    final pitlineAvg = _toPercent(_sectionAverage(pitlineItems));
    final disposalAvg = _toPercent(_sectionAverage(disposalItems));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12.withOpacity(0.04), blurRadius: 6)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Summary",
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Housekeeping Average %",
                  style: TextStyle(fontWeight: FontWeight.w600)),
              Text('${housekeepingAvg.toStringAsFixed(1)}%',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: Colors.blue)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Pit-Line Average %",
                  style: TextStyle(fontWeight: FontWeight.w600)),
              Text('${pitlineAvg.toStringAsFixed(1)}%',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: Colors.orange)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Garbage Disposal Average %",
                  style: TextStyle(fontWeight: FontWeight.w600)),
              Text('${disposalAvg.toStringAsFixed(1)}%',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: Colors.purple)),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Overall Average %",
                  style: TextStyle(fontWeight: FontWeight.w600)),
              Text('${overall.toStringAsFixed(1)}%',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: Colors.green)),
            ],
          ),
        ],
      ),
    );
  }
}

class ScoreItem {
  final String title;
  final bool isOptional;
  int? score1;
  int? score2;

  ScoreItem(this.title, {this.isOptional = false});

  bool get isNA => score1 == null && score2 == null;

  double get average {
    if (score1 == null && score2 == null) return double.nan;
    if (score1 == null) return score2!.toDouble();
    if (score2 == null) return score1!.toDouble();
    return (score1! + score2!) / 2;
  }
}