import 'package:flutter/material.dart';
import 'package:crm_train/utills/app_colors.dart';

class ObhsTaskExecutionSheet extends StatefulWidget {
  final Map<String, dynamic> task;

  const ObhsTaskExecutionSheet({super.key, required this.task});

  @override
  State<ObhsTaskExecutionSheet> createState() => _ObhsTaskExecutionSheetState();
}

class _ObhsTaskExecutionSheetState extends State<ObhsTaskExecutionSheet> {
  int currentStep = 0; // 0: Before Photo, 1: GPS, 2: Comment, 3: After Photo, 4: Submit

  bool hasBeforePhoto = false;
  bool hasGps = false;
  bool hasAfterPhoto = false;
  final TextEditingController commentController = TextEditingController();

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildStepper(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _buildCurrentStepContent(),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kRailwayBlue.withOpacity(0.05),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.task['name'],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kRailwayBlue,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Status: ${widget.task['status'].toString().toUpperCase()}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(5, (index) {
          final isActive = index == currentStep;
          final isCompleted = index < currentStep;

          return Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? kRailwayBlue
                      : isCompleted
                          ? kSuccessGreen
                          : Colors.grey[300],
                ),
                alignment: Alignment.center,
                child: isCompleted
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: isActive ? Colors.white : Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              if (index < 4)
                Container(
                  width: 32,
                  height: 2,
                  color: isCompleted ? kSuccessGreen : Colors.grey[300],
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (currentStep) {
      case 0:
        return _buildPhotoUploadStep('Before Cleaning Photo', hasBeforePhoto, (val) {
          setState(() => hasBeforePhoto = val);
        });
      case 1:
        return _buildGpsStep();
      case 2:
        return _buildCommentStep();
      case 3:
        return _buildPhotoUploadStep('After Cleaning Photo', hasAfterPhoto, (val) {
          setState(() => hasAfterPhoto = val);
        });
      case 4:
        return _buildSubmitStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPhotoUploadStep(String title, bool hasPhoto, ValueChanged<bool> onToggle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(Icons.camera_alt_outlined, size: 64, color: Colors.grey[400]),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Please capture a clear photo as evidence.',
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 32),
        if (hasPhoto)
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kSuccessGreen, width: 2),
            ),
            alignment: Alignment.center,
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: kSuccessGreen, size: 48),
                SizedBox(height: 8),
                Text('Photo Attached successfully', style: TextStyle(color: kSuccessGreen, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildUploadButton(Icons.camera_alt, 'Camera', () => onToggle(true)),
              _buildUploadButton(Icons.photo_library, 'Gallery', () => onToggle(true)),
            ],
          ),
        if (hasPhoto) ...[
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () => onToggle(false),
            icon: const Icon(Icons.delete_outline, color: kErrorRed),
            label: const Text('Remove Photo', style: TextStyle(color: kErrorRed)),
          )
        ]
      ],
    );
  }

  Widget _buildUploadButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: kRailwayBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kRailwayBlue.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: kRailwayBlue, size: 32),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: kRailwayBlue, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildGpsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(Icons.location_on_outlined, size: 64, color: Colors.grey[400]),
        const SizedBox(height: 16),
        const Text(
          'Location Capture',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'We need to attach your GPS coordinates to this task.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 32),
        if (hasGps)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kSuccessGreen),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: kSuccessGreen),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Location Captured', style: TextStyle(fontWeight: FontWeight.bold, color: kSuccessGreen)),
                      Text('Lat: 28.6139, Lng: 77.2090', style: TextStyle(fontSize: 12, color: Colors.green[800])),
                      Text('New Delhi Railway Station', style: TextStyle(fontSize: 12, color: Colors.green[800])),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          ElevatedButton.icon(
            onPressed: () {
              // Simulate GPS capture delay
              Future.delayed(const Duration(seconds: 1), () {
                setState(() => hasGps = true);
              });
            },
            icon: const Icon(Icons.my_location),
            label: const Text('Capture Location Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: kRailwayBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildCommentStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Task Comments (Optional)',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: commentController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Enter any remarks, issues, or details about the task...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildQuickCommentChip('Choke cleared'),
            _buildQuickCommentChip('Deep cleaning done'),
            _buildQuickCommentChip('Water refill needed'),
            _buildQuickCommentChip('Hardware broken'),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickCommentChip(String text) {
    return ActionChip(
      label: Text(text, style: const TextStyle(fontSize: 12)),
      onPressed: () {
        final currentText = commentController.text;
        commentController.text = currentText.isEmpty ? text : '$currentText, $text';
      },
      backgroundColor: Colors.grey[200],
    );
  }

  Widget _buildSubmitStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(Icons.fact_check_outlined, size: 64, color: kRailwayBlue),
        const SizedBox(height: 16),
        const Text(
          'Review & Submit',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            children: [
              _buildReviewRow('Before Photo', hasBeforePhoto),
              const Divider(),
              _buildReviewRow('GPS Attached', hasGps),
              const Divider(),
              _buildReviewRow('After Photo', hasAfterPhoto),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Comments', style: TextStyle(fontWeight: FontWeight.w500)),
                  Text(commentController.text.isNotEmpty ? 'Added' : 'None', 
                       style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewRow(String label, bool isDone) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Icon(
            isDone ? Icons.check_circle : Icons.cancel,
            color: isDone ? kSuccessGreen : kErrorRed,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final bool canProceed = _canProceedFromCurrentStep();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          if (currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() => currentStep--);
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
                child: const Text('Back', style: TextStyle(color: Colors.black87)),
              ),
            ),
          if (currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: canProceed
                  ? () {
                      if (currentStep < 4) {
                        setState(() => currentStep++);
                      } else {
                        // Submit Task
                        Navigator.pop(context, true);
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: kRailwayBlue,
                disabledBackgroundColor: Colors.grey[300],
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                currentStep == 4 ? 'Submit for Approval' : 'Continue',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _canProceedFromCurrentStep() {
    switch (currentStep) {
      case 0:
        return hasBeforePhoto; // require before photo
      case 1:
        return hasGps; // require GPS
      case 2:
        return true; // comments optional
      case 3:
        return hasAfterPhoto; // require after photo
      case 4:
        return hasBeforePhoto && hasGps && hasAfterPhoto;
      default:
        return false;
    }
  }
}
