import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../repositories/worker_repo.dart';
import '../../../utills/app_colors.dart';
import '../../common_workers/worker_complaints_screen.dart' show ComplaintModel;

class AdminComplaintsScreen extends StatefulWidget {
  const AdminComplaintsScreen({super.key});

  @override
  State<AdminComplaintsScreen> createState() => _AdminComplaintsScreenState();
}

class _AdminComplaintsScreenState extends State<AdminComplaintsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ComplaintModel> complaints = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchComplaints();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchComplaints() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final response = await WorkerRepository.getObhsComplaints();
      
      final raw = response['complaints'] ??
          response['data'] ??
          response['items'] ??
          [];

      final fetchedComplaints = (raw as List)
          .map((json) => ComplaintModel.fromJson(json as Map<String, dynamic>))
          .toList();

      // Sort by latest first
      fetchedComplaints.sort((a, b) => b.raisedDate.compareTo(a.raisedDate));

      setState(() {
        complaints = fetchedComplaints;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching complaints for Admin: $e');
      setState(() {
        errorMessage = e.toString().replaceAll('Exception: ', '');
        isLoading = false;
      });
    }
  }

  List<ComplaintModel> get activeComplaints => complaints
      .where((c) => ['Raised', 'Acknowledged', 'In Progress'].contains(c.status))
      .toList();

  List<ComplaintModel> get resolvedComplaints =>
      complaints.where((c) => c.status == 'Resolved' || c.status == 'Closed').toList();

  List<ComplaintModel> get allComplaints => complaints;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Complaints',
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
        backgroundColor: kRailwayBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchComplaints,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'Active (${activeComplaints.length})'),
            Tab(text: 'Resolved (${resolvedComplaints.length})'),
            Tab(text: 'All (${allComplaints.length})'),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(errorMessage!,
                          style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchComplaints,
                        child: const Text('Retry'),
                      )
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildComplaintsList(activeComplaints),
                    _buildComplaintsList(resolvedComplaints),
                    _buildComplaintsList(allComplaints),
                  ],
                ),
    );
  }

  Widget _buildComplaintsList(List<ComplaintModel> list) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline,
                size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No complaints found',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchComplaints,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final complaint = list[index];
          return _AdminComplaintCard(
            complaint: complaint,
            onResolveTapped: () => _showResolveDialog(complaint),
          );
        },
      ),
    );
  }

  void _showResolveDialog(ComplaintModel complaint) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return _ResolveComplaintSheet(
          complaint: complaint,
          onSuccess: () {
            Navigator.pop(ctx);
            _fetchComplaints();
          },
        );
      },
    );
  }
}

class _AdminComplaintCard extends StatelessWidget {
  final ComplaintModel complaint;
  final VoidCallback onResolveTapped;

  const _AdminComplaintCard({
    required this.complaint,
    required this.onResolveTapped,
  });

  @override
  Widget build(BuildContext context) {
    final bool isActive =
        ['Raised', 'Acknowledged', 'In Progress'].contains(complaint.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                _buildCategoryIcon(complaint.category),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        complaint.category,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Coach ${complaint.coachId}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(complaint.status).withOpacity(0.1),
                    border: Border.all(color: _getStatusColor(complaint.status)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    complaint.status,
                    style: TextStyle(
                      color: _getStatusColor(complaint.status),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Description
            Text(
              complaint.description,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            const Divider(),
            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('dd MMM yyyy, hh:mm a')
                          .format(complaint.raisedDate),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                if (isActive)
                  ElevatedButton.icon(
                    onPressed: onResolveTapped,
                    icon: const Icon(Icons.check, size: 16, color: Colors.white),
                    label: const Text('Resolve',
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kRailwayBlue,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryIcon(String category) {
    IconData iconData;
    Color iconColor;
    Color bgColor;

    switch (category.toLowerCase()) {
      case 'electrical':
        iconData = Icons.electrical_services;
        iconColor = Colors.orange;
        bgColor = Colors.orange.shade50;
        break;
      case 'mechanical':
        iconData = Icons.build;
        iconColor = Colors.blue;
        bgColor = Colors.blue.shade50;
        break;
      case 'security':
        iconData = Icons.security;
        iconColor = Colors.red;
        bgColor = Colors.red.shade50;
        break;
      case 'cleanliness':
        iconData = Icons.cleaning_services;
        iconColor = Colors.green;
        bgColor = Colors.green.shade50;
        break;
      default:
        iconData = Icons.report_problem;
        iconColor = Colors.grey;
        bgColor = Colors.grey.shade100;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(iconData, color: iconColor),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Raised':
      case 'OPEN':
        return Colors.orange;
      case 'Acknowledged':
        return Colors.blue;
      case 'In Progress':
        return Colors.purple;
      case 'Resolved':
      case 'Closed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

class _ResolveComplaintSheet extends StatefulWidget {
  final ComplaintModel complaint;
  final VoidCallback onSuccess;

  const _ResolveComplaintSheet({
    required this.complaint,
    required this.onSuccess,
  });

  @override
  State<_ResolveComplaintSheet> createState() => _ResolveComplaintSheetState();
}

class _ResolveComplaintSheetState extends State<_ResolveComplaintSheet> {
  final _remarksController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _photoFile;
  bool _isSubmitting = false;
  String _selectedStatus = 'SOLVED';

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );
    if (photo != null) {
      setState(() => _photoFile = photo);
    }
  }

  Future<void> _submitResolution() async {
    if (_remarksController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter remarks.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      String? photoUrl;
      if (_photoFile != null) {
        photoUrl = await WorkerRepository.uploadMedia(_photoFile!.path);
      }

      await WorkerRepository.resolveComplaint(
        complaintId: widget.complaint.complaintId,
        adminRemarks: _remarksController.text.trim(),
        resolutionPhotoUrl: photoUrl,
        status: _selectedStatus,
      );

      widget.onSuccess();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complaint updated successfully!')),
      );
    } catch (e) {
      debugPrint('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update complaint. Try again.')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Resolve Complaint',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Status',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedStatus,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                          value: 'SOLVED', child: Text('Solved (Resolved)')),
                      DropdownMenuItem(
                          value: 'UNSOLVED', child: Text('Unsolved (Pending)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedStatus = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Admin Remarks',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: _remarksController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Enter your remarks here...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Resolution Photo',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              if (_photoFile != null)
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(_photoFile!.path),
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.white),
                      onPressed: () => setState(() => _photoFile = null),
                    ),
                  ],
                )
              else
                OutlinedButton.icon(
                  onPressed: _takePhoto,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Capture Photo'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitResolution,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kRailwayBlue,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Submit',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
