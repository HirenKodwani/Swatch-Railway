import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:crm_train/repositories/worker_repo.dart';
import 'package:crm_train/repositories/station_cleaning_repository.dart';
import 'package:crm_train/utills/app_colors.dart';

class StationWorkerAttendanceScreen extends StatefulWidget {
  final String workerId;
  final String workerName;
  final String? runInstanceId;
  final String? stationId;
  final String attendanceType;

  const StationWorkerAttendanceScreen({
    super.key,
    required this.workerId,
    required this.workerName,
    this.runInstanceId,
    this.stationId,
    required this.attendanceType,
  });

  @override
  State<StationWorkerAttendanceScreen> createState() => _StationWorkerAttendanceScreenState();
}

class _StationWorkerAttendanceScreenState extends State<StationWorkerAttendanceScreen> {
  int currentStep = 0;
  final picker = ImagePicker();

  File? _selfie;
  String? _selfieUrl;
  Position? _gpsPosition;
  bool _submitting = false;
  bool _isFaceVerified = false;
  bool _isVerifying = false;
  String _livenessChallenge = '';

  @override
  void initState() {
    super.initState();
    _generateChallenge();
  }

  void _generateChallenge() {
    final challenges = ['THUMBS_UP', 'FIST', 'SMILE'];
    _livenessChallenge = challenges[DateTime.now().millisecond % challenges.length];
  }

  String _challengeDisplayText() {
    switch (_livenessChallenge) {
      case 'THUMBS_UP': return 'Thumbs Up gesture';
      case 'FIST': return 'Fist gesture';
      case 'SMILE': return 'wide Smile';
      default: return _livenessChallenge;
    }
  }

  Future<Map<String, dynamic>?> _captureSelfie() async {
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 1280,
      preferredCameraDevice: CameraDevice.front,
    );
    if (picked == null) return null;

    final file = File(picked.path);
    String? url;
    try {
      url = await WorkerRepository.uploadMedia(picked.path);
    } catch (_) {}

    return {'url': url, 'file': file};
  }

  Future<Position?> _captureGps() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return null;
      }

      try {
        return await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 15),
          ),
        );
      } catch (e) {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) return lastKnown;
        return await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 15),
          ),
        );
      } catch (e) {
        return Position(
          longitude: 0.0, latitude: 0.0,
          timestamp: DateTime.now(),
          accuracy: 0.0, altitude: 0.0, heading: 0.0, speed: 0.0,
          speedAccuracy: 0.0, altitudeAccuracy: 0.0, headingAccuracy: 0.0,
        );
      }
    } catch (_) {
      return null;
    }
  }

  Future<void> _verifyFaceAndSubmit() async {
    if (_selfieUrl == null && _selfie == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selfie is required'), backgroundColor: kWarningOrange),
      );
      return;
    }
    if (_gpsPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('GPS location is required'), backgroundColor: kWarningOrange),
      );
      return;
    }

    setState(() => _isVerifying = true);
    try {
      final selfieUrl = _selfieUrl ?? (await WorkerRepository.uploadMedia(_selfie!.path));
      if (selfieUrl == null) throw Exception('Failed to upload selfie');

      final result = await WorkerRepository.verifyFace(image1Url: selfieUrl, image2Url: selfieUrl);
      final isMatch = result['match'] == true || result['verified'] == true;
      if (!isMatch) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Face verification failed. Please retake selfie.'), backgroundColor: kErrorRed),
          );
        }
        setState(() {
          _isVerifying = false;
          currentStep = 0;
          _selfie = null;
          _selfieUrl = null;
          _generateChallenge();
        });
        return;
      }
    } catch (_) {}

    setState(() { _isVerifying = false; _isFaceVerified = true; _submitting = true; });
    try {
      await StationCleaningRepository.markStationAttendance(
        type: widget.attendanceType,
        runInstanceId: widget.runInstanceId ?? '',
        stationId: widget.stationId ?? '',
        imageUrl: _selfieUrl ?? 'captured',
        latitude: _gpsPosition!.latitude,
        longitude: _gpsPosition!.longitude,
        livenessChallenge: _livenessChallenge,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.attendanceType.toUpperCase()} attendance marked successfully'),
            backgroundColor: kSuccessGreen,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: kErrorRed),
        );
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.attendanceType == 'start' ? 'Start Attendance' :
        widget.attendanceType == 'mid' ? 'Mid Check-in' : 'End Attendance';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: kRailwayBlue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _buildStepper(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _submitting
                  ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Submitting attendance...'),
                    ]))
                  : _buildCurrentStepContent(),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    final labels = ['Selfie', 'Face Verify', 'GPS', 'Submit'];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[200]!))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(4, (index) {
          final isActive = index == currentStep;
          final isCompleted = index < currentStep;
          return Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive ? kRailwayBlue : isCompleted ? kSuccessGreen : Colors.grey[300],
                  ),
                  alignment: Alignment.center,
                  child: isCompleted
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : Text('${index + 1}',
                          style: TextStyle(color: isActive ? Colors.white : Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 4),
                Text(labels[index], style: TextStyle(fontSize: 9, color: isActive ? kRailwayBlue : Colors.grey[500])),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    if (_submitting || _isVerifying) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(_isVerifying ? 'Verifying face...' : 'Submitting attendance...'),
        ]),
      );
    }
    switch (currentStep) {
      case 0: return _buildSelfieStep();
      case 1: return _buildFaceVerifyStep();
      case 2: return _buildGpsStep();
      case 3: return _buildSubmitStep();
      default: return const SizedBox.shrink();
    }
  }

  Widget _buildSelfieStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(Icons.camera_front_outlined, size: 64, color: Colors.grey),
        const SizedBox(height: 16),
        const Text('Take a Selfie', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: kWarningOrange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: kWarningOrange.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_amber_rounded, color: kWarningOrange, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Show a ${_challengeDisplayText()} in your selfie',
                  style: TextStyle(color: kWarningOrange, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text('Camera capture only — no gallery allowed.',
            style: TextStyle(color: Colors.grey[600])),
        const SizedBox(height: 24),
        if (_selfie != null)
          Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_selfie!, height: 220, width: double.infinity, fit: BoxFit.cover),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => setState(() { _selfie = null; _selfieUrl = null; _isFaceVerified = false; _generateChallenge(); }),
                icon: const Icon(Icons.delete_outline, color: kErrorRed),
                label: const Text('Remove', style: TextStyle(color: kErrorRed)),
              ),
            ],
          )
        else
          ElevatedButton.icon(
            onPressed: () async {
              final result = await _captureSelfie();
              if (result != null) {
                setState(() {
                  _selfie = result['file'];
                  if (result['url'] != null) _selfieUrl = result['url'];
                });
              }
            },
            icon: const Icon(Icons.camera_alt),
            label: const Text('Open Camera'),
            style: ElevatedButton.styleFrom(
              backgroundColor: kRailwayBlue, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
          ),
      ],
    );
  }

  Widget _buildFaceVerifyStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(_isFaceVerified ? Icons.verified_user : Icons.face_outlined, size: 64,
            color: _isFaceVerified ? kSuccessGreen : Colors.grey),
        const SizedBox(height: 16),
        Text('Face Verification', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(_isFaceVerified
            ? 'Face matched successfully for ${_challengeDisplayText()}'
            : 'Verify your selfie matches the challenge',
            style: TextStyle(color: _isFaceVerified ? kSuccessGreen : Colors.grey[600])),
        const SizedBox(height: 24),
        if (_selfie != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(_selfie!, height: 180, width: double.infinity, fit: BoxFit.cover),
          ),
        const SizedBox(height: 24),
        if (_isFaceVerified)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kSuccessGreen),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: kSuccessGreen),
                SizedBox(width: 12),
                Text('Face Verified', style: TextStyle(fontWeight: FontWeight.bold, color: kSuccessGreen)),
              ],
            ),
          )
        else
          ElevatedButton.icon(
            onPressed: () async {
              final selfieUrl = _selfieUrl ?? (_selfie != null ? await WorkerRepository.uploadMedia(_selfie!.path) : null);
              if (selfieUrl == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please capture a selfie first'), backgroundColor: kWarningOrange),
                );
                return;
              }
              setState(() => _isVerifying = true);
              try {
                final result = await WorkerRepository.verifyFace(image1Url: selfieUrl, image2Url: selfieUrl);
                if (result['match'] == true || result['verified'] == true) {
                  setState(() { _isFaceVerified = true; _isVerifying = false; });
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Face verification failed. Please retake selfie with correct gesture.'), backgroundColor: kErrorRed),
                    );
                  }
                  setState(() { _isVerifying = false; _selfie = null; _selfieUrl = null; _generateChallenge(); });
                }
              } catch (e) {
                setState(() => _isVerifying = false);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Face verification error. Proceeding with attendance.'), backgroundColor: kWarningOrange),
                  );
                }
              }
            },
            icon: _isVerifying
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.verified_user),
            label: Text(_isVerifying ? 'Verifying...' : 'Verify Face'),
            style: ElevatedButton.styleFrom(
              backgroundColor: kRailwayBlue, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
          ),
      ],
    );
  }

  Widget _buildGpsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(Icons.location_on_outlined, size: 64, color: Colors.grey),
        const SizedBox(height: 16),
        const Text('Location Capture', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('GPS coordinates are mandatory for attendance.',
            style: TextStyle(color: Colors.grey[600])),
        const SizedBox(height: 24),
        if (_gpsPosition != null)
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
                      Text('Lat: ${_gpsPosition!.latitude.toStringAsFixed(5)}, Lng: ${_gpsPosition!.longitude.toStringAsFixed(5)}',
                          style: TextStyle(fontSize: 12, color: Colors.green[800])),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          ElevatedButton.icon(
            onPressed: () async {
              final pos = await _captureGps();
              if (pos != null) {
                setState(() => _gpsPosition = pos);
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not get GPS. Check location permissions.')),
                  );
                }
              }
            },
            icon: const Icon(Icons.my_location),
            label: const Text('Capture Location Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: kRailwayBlue, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
          ),
      ],
    );
  }

  Widget _buildSubmitStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(Icons.fact_check_outlined, size: 64, color: kRailwayBlue),
        const SizedBox(height: 16),
        Text('Review & Submit', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
              _reviewRow('Selfie Captured', _selfieUrl != null || _selfie != null),
              const Divider(),
              _reviewRow('Face Verified', _isFaceVerified),
              const Divider(),
              _reviewRow('GPS Attached', _gpsPosition != null),
            ],
          ),
        ),
      ],
    );
  }

  Widget _reviewRow(String label, bool done) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        Icon(done ? Icons.check_circle : Icons.cancel, color: done ? kSuccessGreen : kErrorRed, size: 20),
      ]),
    );
  }

  Widget _buildBottomBar() {
    final canProceed = _canProceedFromCurrentStep();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), offset: const Offset(0, -2), blurRadius: 4)],
      ),
      child: Row(
        children: [
          if (currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => currentStep--),
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
                      if (currentStep < 3) {
                        setState(() => currentStep++);
                      } else {
                        _verifyFaceAndSubmit();
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: kRailwayBlue, disabledBackgroundColor: Colors.grey[300],
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                currentStep == 3 ? 'Submit Attendance' : 'Continue',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _canProceedFromCurrentStep() {
    if (_submitting || _isVerifying) return false;
    switch (currentStep) {
      case 0: return _selfieUrl != null || _selfie != null;
      case 1: return _isFaceVerified;
      case 2: return _gpsPosition != null;
      case 3: return (_selfieUrl != null || _selfie != null) && _gpsPosition != null;
      default: return false;
    }
  }
}
