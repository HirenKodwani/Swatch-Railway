import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utills/app_colors.dart';
import '../../services/passenger_service.dart';

class PassengerTaskScreen extends StatefulWidget {
  const PassengerTaskScreen({super.key});

  @override
  State<PassengerTaskScreen> createState() => _PassengerTaskScreenState();
}

class _PassengerTaskScreenState extends State<PassengerTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _trainNoController = TextEditingController();
  final _coachNoController = TextEditingController();
  final _seatNoController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String? _selectedTaskType;
  final List<String> _taskTypes = [
    'Coach Cleaning',
    'Toilet Cleaning',
    'Garbage Collection',
    'Water Supply Issue',
    'Linen Issue',
    'Other'
  ];

  bool _isSubmitting = false;

  Future<void> _submitTask() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = await PassengerService.createCleaningTask(
        trainNo: _trainNoController.text.trim(),
        coachNo: _coachNoController.text.trim(),
        seatNo: _seatNoController.text.trim(),
        taskType: _selectedTaskType!,
        description: _descriptionController.text.trim(),
      );

      if (mounted) {
        Get.snackbar(
          'Success',
          response['message'] ?? 'Your request has been submitted to the housekeeping team.',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Error',
          e.toString().replaceAll('Exception: ', ''),
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Passenger Service Request', style: TextStyle(color: Colors.white)),
        backgroundColor: kRailwayBlue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Request Housekeeping Services',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: kRailwayBlue,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Please provide your travel details and the service you require.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 30),
              
              TextFormField(
                controller: _trainNoController,
                decoration: InputDecoration(
                  labelText: 'Train Number',
                  prefixIcon: const Icon(Icons.train),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Please enter train number' : null,
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _coachNoController,
                      decoration: InputDecoration(
                        labelText: 'Coach No.',
                        prefixIcon: const Icon(Icons.meeting_room),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _seatNoController,
                      decoration: InputDecoration(
                        labelText: 'Seat/Berth No.',
                        prefixIcon: const Icon(Icons.event_seat),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                value: _selectedTaskType,
                decoration: InputDecoration(
                  labelText: 'Service Type',
                  prefixIcon: const Icon(Icons.cleaning_services),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _taskTypes.map((String task) {
                  return DropdownMenuItem<String>(
                    value: task,
                    child: Text(task),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedTaskType = value;
                  });
                },
                validator: (value) => value == null ? 'Please select a service' : null,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'e.g., Water spilled near seat 24',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 30),
              
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitTask,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kRailwayBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Submit Request',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
