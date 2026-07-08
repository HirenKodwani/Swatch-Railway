import 'package:crm_train/utills/app_colors.dart';
import 'package:crm_train/model/train_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/api_services.dart';
import '../../../services/draft_storage_service.dart';
import '../widgets/CommonMultiSelectDropdown.dart';
import '../widgets/rolevise_dropdowns.dart';

class TrainFormScreen extends StatefulWidget {
  final TrainModel? train;
  final Map<String, dynamic>? draftData;
  final String? draftId;

  const TrainFormScreen({super.key, this.train, this.draftData, this.draftId});

  @override
  State<TrainFormScreen> createState() => _TrainFormScreenState();
}

class _TrainFormScreenState extends State<TrainFormScreen> {
  final _formKey = GlobalKey<FormState>();

  TextEditingController trainNoController = TextEditingController();
  TextEditingController trainNameController = TextEditingController();
  TextEditingController originStationController = TextEditingController();
  TextEditingController destinationStationController = TextEditingController();
  TextEditingController outboundTrainNoController = TextEditingController();
  TextEditingController inboundTrainNoController = TextEditingController();
  TextEditingController expectedReturnOffsetController =
      TextEditingController();
  TextEditingController outboundTravelTimeController = TextEditingController();
  TextEditingController inboundTravelTimeController = TextEditingController();
  TextEditingController layoverDestinationController = TextEditingController();
  TextEditingController layoverOriginController = TextEditingController();
  TextEditingController journeyStartTimeController = TextEditingController();

  bool isActive = true;
  String? zone;
  String? division;
  String? depot;
  List<String> selectedDays = [];
  bool _isSaving = false;
  bool _isDraft = false;
  String? _currentDraftId;
  List<String> selectedTrainApplicability = [];

  int calculatedInstances = 1;
  List<Map<String, dynamic>> instancesPreview = [];

  final Map<String, String> dayMapping = {
    "Monday": "Mon",
    "Tuesday": "Tue",
    "Wednesday": "Wed",
    "Thursday": "Thu",
    "Friday": "Fri",
    "Saturday": "Sat",
    "Sunday": "Sun",
    "All Days": "All Days",
  };

  final List<String> weekDays = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday",
    "All Days",
  ];

  @override
  void initState() {
    super.initState();
    _currentDraftId = widget.draftId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<AuthProvider>(
        context,
        listen: false,
      ).currentUser;

      setState(() {
        if (widget.train != null) {
          _loadTrainData(widget.train!);
        } else if (widget.draftData != null) {
          _loadDraftData(widget.draftData!, user);
        } else {
          _loadUserDefaults(user);
        }
      });
    });
  }

  void _loadTrainData(TrainModel train) {
    zone = train.zone;
    division = train.division;
    depot = train.depot;

    trainNoController.text = train.trainNo ?? '';
    trainNameController.text = train.trainName ?? '';
    originStationController.text = train.origin ?? '';
    destinationStationController.text = train.destination ?? '';
    isActive = train.status.toLowerCase() == 'active';
    selectedTrainApplicability = train.trainApplicableFor;

    outboundTrainNoController.text = train.outboundTrainNo ?? '';
    inboundTrainNoController.text = train.inboundTrainNo ?? '';
    outboundTravelTimeController.text = train.outboundDurationStr ?? '';
    inboundTravelTimeController.text = train.inboundDurationStr ?? '';
    layoverDestinationController.text = train.layoverDestStr ?? '';
    layoverOriginController.text = train.layoverOriginStr ?? '';
    journeyStartTimeController.text = train.journeyStartTime ?? '';

    selectedDays = train.days.map((apiDay) {
      return dayMapping.entries
          .firstWhere(
            (entry) => entry.value == apiDay,
            orElse: () => MapEntry(apiDay, apiDay),
          )
          .key;
    }).toList();
  }

  void _loadDraftData(Map<String, dynamic> draft, user) {
    zone = draft['zone'] ?? user?.zone;
    division = draft['division'] ?? user?.division;
    depot = draft['depot'] ?? user?.depot;

    trainNoController.text = draft['trainNo']?.toString() ?? '';
    trainNameController.text = draft['trainName']?.toString() ?? '';
    originStationController.text = draft['origin']?.toString() ?? '';
    destinationStationController.text = draft['destination']?.toString() ?? '';
    isActive = draft['status']?.toString().toLowerCase() == 'active';

    outboundTrainNoController.text = draft['outboundTrainNo']?.toString() ?? '';
    inboundTrainNoController.text = draft['inboundTrainNo']?.toString() ?? '';

    outboundTravelTimeController.text =
        draft['outboundTravelTime']?.toString() ?? '';
    inboundTravelTimeController.text =
        draft['inboundTravelTime']?.toString() ?? '';
    layoverDestinationController.text =
        draft['layoverDestination']?.toString() ?? '';
    layoverOriginController.text = draft['layoverOrigin']?.toString() ?? '';
    journeyStartTimeController.text =
        draft['journeyStartTime']?.toString() ?? '';

    if (draft['TrainApplicableFor'] != null) {
      if (draft['TrainApplicableFor'] is List) {
        selectedTrainApplicability = List<String>.from(
          draft['TrainApplicableFor'],
        );
      }
    }

    if (draft['days'] != null) {
      List<String> draftDays = [];
      if (draft['days'] is List) {
        draftDays = List<String>.from(draft['days']);
      } else if (draft['days'] is String) {
        draftDays = [draft['days']];
      }

      selectedDays = draftDays.map((apiDay) {
        return dayMapping.entries
            .firstWhere(
              (entry) => entry.value == apiDay,
              orElse: () => MapEntry(apiDay, apiDay),
            )
            .key;
      }).toList();
    }

    _isDraft = true;
  }

  void _loadUserDefaults(user) {
    zone = user?.zone;
    division = user?.division;
    depot = user?.depot;
  }

  void _generateInstancesPreview() {
    instancesPreview.clear();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;
    bool isEdit = widget.train != null;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          widget.train != null
              ? "Edit Train"
              : _isDraft
              ? "Edit Draft"
              : "Add Train",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: kRailwayBlue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isDraft)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.orange.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'You are editing a draft. Save it to publish the train.',
                            style: TextStyle(
                              color: Colors.orange.shade900,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                _sectionHeader("Basic Train Information"),
                const SizedBox(height: 12),
                _buildCard([
                  _buildTextField(
                    "Train Number",
                    "Enter train number (max 10 digits)",
                    trainNoController,
                    icon: Icons.confirmation_number_outlined,
                    numeric: true,
                    required: true,
                    readOnly: isEdit,
                    onChanged: (_) => _generateInstancesPreview(),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    "Train Name",
                    "Enter train name (2-80 characters)",
                    trainNameController,
                    icon: Icons.train_outlined,
                    required: true,
                  ),
                ]),

                const SizedBox(height: 20),
                _sectionHeader("Station Details"),
                const SizedBox(height: 12),
                _buildCard([
                  _buildTextField(
                    "Origin Station",
                    "Enter origin station",
                    originStationController,
                    icon: Icons.location_on_outlined,
                    required: true,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    "Destination Station",
                    "Enter destination station",
                    destinationStationController,
                    icon: Icons.flag_outlined,
                    required: true,
                  ),
                ]),

                const SizedBox(height: 20),
                _sectionHeader("Train Type"),
                const SizedBox(height: 12),
                _buildCard([
                  CommonMultiSelectDropdown(
                    label: "Train Applicability",
                    hint: "Select Train Applicability",
                    items: ["Coach Cleaning", "CTS", "OBHS"],
                    selectedItems: selectedTrainApplicability,
                    onSelect: (values) {
                      setState(() {
                        selectedTrainApplicability = values;
                      });
                    },
                  ),
                ]),

                // NEW
                if (selectedTrainApplicability.contains('OBHS'))
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      _sectionHeader("OBHS Configuration"),
                      const SizedBox(height: 12),
                      _buildCard([
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                "Outbound Train No",
                                "Enter outbound",
                                outboundTrainNoController,
                                numeric: true,
                                required: true,
                                onChanged: (_) => _generateInstancesPreview(),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildTextField(
                                "Inbound Train No",
                                "Enter inbound",
                                inboundTrainNoController,
                                numeric: true,
                                required: true,
                                onChanged: (_) => _generateInstancesPreview(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _DurationPicker(
                          label: "Outbound Travel Time",
                          controller: outboundTravelTimeController,
                          isRequired: true,
                        ),
                        _DurationPicker(
                          label: "Inbound Travel Time",
                          controller: inboundTravelTimeController,
                          isRequired: true,
                        ),
                        _DurationPicker(
                          label: "Layover at Destination",
                          controller: layoverDestinationController,
                          isRequired: true,
                        ),
                        _DurationPicker(
                          label: "Layover at Origin",
                          controller: layoverOriginController,
                          isRequired: true,
                        ),
                        _buildJourneyStartTimeField(),
                      ]),
                    ],
                  ),

                if (user?.role != 'Railway Supervisor') ...[
                  const SizedBox(height: 20),
                  _sectionHeader("Location"),
                  const SizedBox(height: 12),
                  _buildCard([
                    ZoneDivisionDepotDropdowns(
                      key: ValueKey([zone, division, depot].join('_')),
                      user: user!,
                      initialZone: zone,
                      initialDivision: division,
                      initialDepot: depot,
                      onChangedWithZone:
                          (selectedZone, selectedDivision, selectedDepot) {
                            setState(() {
                              zone = selectedZone;
                              division = selectedDivision;
                              depot = selectedDepot;
                            });
                          },
                    ),
                  ]),
                ],

                const SizedBox(height: 20),
                _sectionHeader("Running Days"),
                const SizedBox(height: 12),
                _buildCard([
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: weekDays.map((day) {
                      bool isSelected = selectedDays.contains(day);
                      return FilterChip(
                        label: Text(day),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (day == "All Days") {
                              if (selected) {
                                selectedDays.clear();
                                selectedDays.add("All Days");
                              } else {
                                selectedDays.remove("All Days");
                              }
                            } else {
                              selectedDays.remove("All Days");
                              if (selected) {
                                selectedDays.add(day);
                              } else {
                                selectedDays.remove(day);
                              }
                            }
                          });
                        },
                        selectedColor: kRailwayBlue.withValues(alpha: 0.2),
                        checkmarkColor: kRailwayBlue,
                        backgroundColor: Colors.grey.shade100,
                        labelStyle: TextStyle(
                          color: isSelected ? kRailwayBlue : Colors.black87,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  ),
                ]),

                const SizedBox(height: 20),
                _sectionHeader("Status"),
                const SizedBox(height: 12),
                _buildCard([
                  SwitchListTile(
                    value: isActive,
                    onChanged: (v) => setState(() => isActive = v),
                    title: const Text(
                      "Active Train",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      isActive
                          ? "Train is currently active"
                          : "Train is inactive",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    activeThumbColor: kRailwayBlue,
                    contentPadding: EdgeInsets.zero,
                  ),
                ]),

                const SizedBox(height: 32),

                if (widget.train != null)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(
                              color: Colors.grey.shade400,
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: Icon(Icons.close, color: Colors.grey.shade700),
                          label: Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 12,
                            ),
                          ),
                          onPressed: _isSaving
                              ? null
                              : () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kRailwayBlue,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: _isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.update, color: Colors.white),
                          label: const Text(
                            "Update Train",
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          onPressed: _isSaving ? null : _saveTrain,
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: kRailwayBlue, width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: Icon(Icons.save_outlined, color: kRailwayBlue),
                          label: Text(
                            'Save as Draft',
                            style: TextStyle(color: kRailwayBlue, fontSize: 12),
                          ),
                          onPressed: _isSaving ? null : _saveAsDraft,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kRailwayBlue,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: _isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.send, color: Colors.white),
                          label: const Text(
                            "Submit Train",
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          onPressed: _isSaving ? null : _saveTrain,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildTextField(
    String label,
    String hint,
    TextEditingController controller, {
    IconData? icon,
    bool numeric = false,
    bool required = false,
    bool readOnly = false,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            if (required)
              Text(
                ' *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          enabled: !readOnly,
          keyboardType: numeric ? TextInputType.number : TextInputType.text,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: icon != null
                ? Icon(icon, color: Colors.grey.shade600)
                : null,
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: kRailwayBlue, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          validator: (v) {
            if (required && (v == null || v.trim().isEmpty)) {
              return "$label is required";
            }

            if (label == "Train Number" && v != null && v.isNotEmpty) {
              if (!RegExp(r'^\d{1,10}$').hasMatch(v)) {
                return "Must be numeric and max 10 digits";
              }
            }
            if (label == "Train Name" && v != null && v.isNotEmpty) {
              if (v.length < 2 || v.length > 80) {
                return "Must be between 2 and 80 characters";
              }
            }
            if ((label.contains("Outbound") || label.contains("Inbound")) &&
                v != null &&
                v.isNotEmpty) {
              if (!RegExp(r'^\d{1,10}$').hasMatch(v)) {
                return "Must be numeric and max 10 digits";
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildJourneyStartTimeField() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                "Journey Start Time",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Text(
                ' *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: journeyStartTimeController,
            readOnly: true,
            onTap: _pickJourneyStartTime,
            decoration: InputDecoration(
              hintText: "Select journey start time",
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              prefixIcon: Icon(Icons.access_time, color: Colors.grey.shade600),
              suffixIcon: Icon(Icons.schedule, color: kRailwayBlue),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: kRailwayBlue, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.red),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            validator: (value) {
              if (selectedTrainApplicability.contains('OBHS') &&
                  (value == null || value.trim().isEmpty)) {
                return "Journey Start Time is required";
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Future<void> _pickJourneyStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _parseJourneyStartTime(journeyStartTimeController.text),
    );
    if (picked == null) return;

    setState(() {
      journeyStartTimeController.text =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}:00';
    });
  }

  TimeOfDay _parseJourneyStartTime(String value) {
    final parts = value.split(':');
    if (parts.length >= 2) {
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour != null &&
          minute != null &&
          hour >= 0 &&
          hour <= 23 &&
          minute >= 0 &&
          minute <= 59) {
        return TimeOfDay(hour: hour, minute: minute);
      }
    }
    return TimeOfDay.now();
  }

  Future<void> _saveAsDraft() async {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    final userId = user?.uid;
    if (userId == null) return;

    List<String> apiDays = selectedDays
        .map((uiDay) => dayMapping[uiDay] ?? uiDay)
        .toList();

    final draftData = {
      'trainNo': trainNoController.text,
      'trainName': trainNameController.text,
      'origin': originStationController.text,
      'destination': destinationStationController.text,
      'zone': zone,
      'division': division,
      'depot': depot,
      'days': apiDays,
      'TrainApplicableFor': selectedTrainApplicability,
      'status': isActive ? 'active' : 'inactive',
      'outboundTrainNo': outboundTrainNoController.text,
      'inboundTrainNo': inboundTrainNoController.text,
      'outboundTravelTime': outboundTravelTimeController.text,
      'inboundTravelTime': inboundTravelTimeController.text,
      'layoverDestination': layoverDestinationController.text,
      'layoverOrigin': layoverOriginController.text,
      'journeyStartTime': journeyStartTimeController.text,
    };

    try {
      final success = await DraftStorageService.saveTrainDraft(
        currentUserId: userId,
        draftData: draftData,
        draftId: _currentDraftId,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _currentDraftId != null ? 'Draft updated' : 'Draft saved',
            ),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context);

        if (_currentDraftId == null) {
          setState(() {
            _currentDraftId = DateTime.now().millisecondsSinceEpoch.toString();
            _isDraft = true;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving draft: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveTrain() async {
    if (_formKey.currentState!.validate()) {
      if (trainNoController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Train Number is required"),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (selectedDays.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please select at least one running day"),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (selectedTrainApplicability.contains('OBHS')) {
        if (outboundTrainNoController.text.trim().isEmpty ||
            inboundTrainNoController.text.trim().isEmpty ||
            journeyStartTimeController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Outbound, Inbound, and Journey Start Time required for OBHS",
              ),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
      }

      setState(() => _isSaving = true);

      try {
        List<String> apiDays = selectedDays
            .map((uiDay) => dayMapping[uiDay] ?? uiDay)
            .toList();

        if (widget.train != null) {
          await ApiService.updateTrain(
            uid: widget.train!.uid!,
            trainNo: trainNoController.text.isEmpty
                ? null
                : trainNoController.text,
            trainName: trainNameController.text.isEmpty
                ? null
                : trainNameController.text,
            origin: originStationController.text.isEmpty
                ? null
                : originStationController.text,
            destination: destinationStationController.text.isEmpty
                ? null
                : destinationStationController.text,
            days: apiDays,
            trainApplicableFor: selectedTrainApplicability,
            zone: zone!,
            division: division!,
            depot: depot,
            status: isActive ? 'active' : 'inactive',
            outboundTrainNo: outboundTrainNoController.text.isEmpty
                ? null
                : outboundTrainNoController.text,
            inboundTrainNo: inboundTrainNoController.text.isEmpty
                ? null
                : inboundTrainNoController.text,
            outboundTravelTime: outboundTravelTimeController.text.isEmpty
                ? null
                : outboundTravelTimeController.text,
            inboundTravelTime: inboundTravelTimeController.text.isEmpty
                ? null
                : inboundTravelTimeController.text,
            layoverDestination: layoverDestinationController.text.isEmpty
                ? null
                : layoverDestinationController.text,
            layoverOrigin: layoverOriginController.text.isEmpty
                ? null
                : layoverOriginController.text,
            journeyStartTime: journeyStartTimeController.text.isEmpty
                ? null
                : journeyStartTimeController.text,
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Train updated successfully"),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, true);
          }
        } else {
          final draftOwner = Provider.of<AuthProvider>(
            context,
            listen: false,
          ).currentUser;

          await ApiService.createTrain(
            trainNo: trainNoController.text.isEmpty
                ? null
                : trainNoController.text,
            trainName: trainNameController.text.isEmpty
                ? null
                : trainNameController.text,
            origin: originStationController.text.isEmpty
                ? null
                : originStationController.text,
            destination: destinationStationController.text.isEmpty
                ? null
                : destinationStationController.text,
            days: apiDays,
            zone: zone!,
            trainApplicableFor: selectedTrainApplicability,
            division: division!,
            depot: depot,
            status: isActive ? 'active' : 'inactive',
            outboundTrainNo: outboundTrainNoController.text.isEmpty
                ? null
                : outboundTrainNoController.text,
            inboundTrainNo: inboundTrainNoController.text.isEmpty
                ? null
                : inboundTrainNoController.text,
            outboundTravelTime: outboundTravelTimeController.text.isEmpty
                ? null
                : outboundTravelTimeController.text,
            inboundTravelTime: inboundTravelTimeController.text.isEmpty
                ? null
                : inboundTravelTimeController.text,
            layoverDestination: layoverDestinationController.text.isEmpty
                ? null
                : layoverDestinationController.text,
            layoverOrigin: layoverOriginController.text.isEmpty
                ? null
                : layoverOriginController.text,
            journeyStartTime: journeyStartTimeController.text.isEmpty
                ? null
                : journeyStartTimeController.text,
          );

          if (_currentDraftId != null) {
            final draftOwnerId = draftOwner?.uid;
            if (draftOwnerId != null) {
              await DraftStorageService.deleteTrainDraft(
                currentUserId: draftOwnerId,
                draftId: _currentDraftId!,
              );
            }
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Train added successfully"),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, true);
          }
        }
      } catch (e) {
        setState(() => _isSaving = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    trainNoController.dispose();
    trainNameController.dispose();
    originStationController.dispose();
    destinationStationController.dispose();
    outboundTrainNoController.dispose();
    inboundTrainNoController.dispose();
    outboundTravelTimeController.dispose();
    inboundTravelTimeController.dispose();
    layoverDestinationController.dispose();
    layoverOriginController.dispose();
    journeyStartTimeController.dispose();
    super.dispose();
  }
}

class _DurationPicker extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final bool isRequired;

  const _DurationPicker({
    required this.label,
    required this.controller,
    this.isRequired = false,
  });

  @override
  State<_DurationPicker> createState() => _DurationPickerState();
}

class _DurationPickerState extends State<_DurationPicker> {
  late int days, hours, minutes;

  @override
  void initState() {
    super.initState();
    days = 0;
    hours = 0;
    minutes = 0;
    _parseFromController();
  }

  void _parseFromController() {
    final text = widget.controller.text;
    if (text.isNotEmpty) {
      final parts = text.split(':');
      if (parts.length == 3) {
        days = int.tryParse(parts[0]) ?? 0;
        hours = int.tryParse(parts[1]) ?? 0;
        minutes = int.tryParse(parts[2]) ?? 0;
      }
    }
  }

  void _updateController() {
    widget.controller.text =
        '${days.toString().padLeft(2, '0')}:${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  Widget _counter({
    required String label,
    required int value,
    required int min,
    required int max,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: value > min ? onDecrement : null,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: kRailwayBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(Icons.remove, size: 16, color: kRailwayBlue),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                value.toString().padLeft(2, '0'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: value < max ? onIncrement : null,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: kRailwayBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(Icons.add, size: 16, color: kRailwayBlue),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              widget.label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            if (widget.isRequired)
              Text(
                ' *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              _counter(
                label: 'Days',
                value: days,
                min: 0,
                max: 30,
                onDecrement: () => setState(() {
                  days--;
                  _updateController();
                }),
                onIncrement: () => setState(() {
                  days++;
                  _updateController();
                }),
              ),
              Text(
                ':',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.bold,
                ),
              ),
              _counter(
                label: 'Hours',
                value: hours,
                min: 0,
                max: 23,
                onDecrement: () => setState(() {
                  hours--;
                  _updateController();
                }),
                onIncrement: () => setState(() {
                  hours++;
                  _updateController();
                }),
              ),
              Text(
                ':',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.bold,
                ),
              ),
              _counter(
                label: 'Mins',
                value: minutes,
                min: 0,
                max: 59,
                onDecrement: () => setState(() {
                  minutes--;
                  _updateController();
                }),
                onIncrement: () => setState(() {
                  minutes++;
                  _updateController();
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
