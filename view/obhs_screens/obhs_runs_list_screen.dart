import 'package:crm_train/utills/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../model/run_instance_model.dart';
import '../../repositories/obhs_repository.dart';
import '../../model/railway_worker_model.dart';
import 'obhs_create_run_screen.dart';
import 'obhs_review_queue_screen.dart';

class OBHSRunsListScreen extends StatefulWidget {
  const OBHSRunsListScreen({super.key});

  @override
  State<OBHSRunsListScreen> createState() => _OBHSRunsListScreenState();
}

class _OBHSRunsListScreenState extends State<OBHSRunsListScreen> {
  // Data from API
  List<RunInstanceModel> allInstances = [];
  List<RunInstanceModel> filteredInstances = [];

  // Loading & Error states
  bool _isLoading = false;
  String? _error;

  // Filters
  String _searchQuery = '';
  String? selectedTrain;
  String? selectedStatus = 'All';
  bool _isFilterExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadRunInstances();
  }

  Future<void> _loadRunInstances() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final instances = await OBHSRepository.getAllRunInstances();
      if (mounted) {
        setState(() {
          allInstances = instances;
          _isLoading = false;
          _applyFilters();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });

        if (_error!.contains('AUTH_ERROR')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session expired. Please login again.'),
              backgroundColor: kErrorRed,
            ),
          );
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    }
  }

  void _applyFilters() {
    setState(() {
      filteredInstances = allInstances.where((instance) {
        bool matchesSearch = _searchQuery.isEmpty ||
            (instance.trainName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
            (instance.trainNo?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
            instance.instanceId.toLowerCase().contains(_searchQuery.toLowerCase());

        bool matchesTrain = selectedTrain == null ||
            selectedTrain == 'All' ||
            instance.trainNo == selectedTrain;

        bool matchesStatus = selectedStatus == 'All' ||
            selectedStatus == null ||
            instance.status.toLowerCase() == selectedStatus!.toLowerCase();

        return matchesSearch && matchesTrain && matchesStatus;
      }).toList();
    });
  }

  void _clearFilters() {
    setState(() {
      selectedTrain = null;
      selectedStatus = 'All';
      _searchQuery = '';
      _isFilterExpanded = false;
      _applyFilters();
    });
  }

  void _navigateToCreateInstance() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const OBHSCreateInstanceScreen(),
      ),
    ).then((result) {
      if (result == true) {
        // Refresh list if instance was created
        _loadRunInstances();
      }
    });
  }

  // Edit Instance
  void _editInstance(RunInstanceModel instance) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OBHSCreateInstanceScreen(editInstance: instance),
      ),
    ).then((result) {
      if (result == true) {
        // Refresh list if instance was updated
        _loadRunInstances();
      }
    });
  }

  // Delete Instance
  Future<void> _deleteInstance(RunInstanceModel instance) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Instance'),
        content: Text(
          'Are you sure you want to delete run instance ${instance.instanceId}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: kErrorRed,
            ),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );

      await OBHSRepository.deleteRunInstance(instance.runInstanceId ?? instance.id!);

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Instance deleted successfully'),
            backgroundColor: kSuccessGreen,
          ),
        );
        _loadRunInstances(); // Refresh list
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        final errorMessage = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete instance: $errorMessage'),
            backgroundColor: kErrorRed,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return kSuccessGreen;
      case 'pending':
        return kWarningOrange;
      case 'closed':
      case 'completed':
        return Colors.grey[600]!;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Icons.play_circle_filled;
      case 'pending':
        return Icons.schedule;
      case 'closed':
      case 'completed':
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    final uniqueTrains = allInstances
        .where((i) => i.trainNo != null)
        .map((i) => i.trainNo!)
        .toSet()
        .toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'OBHS Runs',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: kRailwayBlue,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadRunInstances,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: kRailwayBlue),
            )
          : _error != null
              ? _buildErrorView()
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 14, horizontal: 16),
                            border: InputBorder.none,
                            prefixIcon:
                                Icon(Icons.search, color: Colors.grey, size: 22),
                            hintText: 'Search train or instance...',
                            hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                          onChanged: (value) {
                            _searchQuery = value;
                            _applyFilters();
                          },
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _isFilterExpanded = !_isFilterExpanded;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.filter_list,
                                      color: kRailwayBlue,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Filters',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const Spacer(),
                                    AnimatedRotation(
                                      turns: _isFilterExpanded ? 0.5 : 0,
                                      duration:
                                          const Duration(milliseconds: 300),
                                      child: const Icon(
                                        Icons.keyboard_arrow_down,
                                        color: kRailwayBlue,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            AnimatedSize(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              child: _isFilterExpanded
                                  ? Padding(
                                      padding: const EdgeInsets.only(
                                        left: 16,
                                        right: 16,
                                        bottom: 16,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Divider(
                                            height: 1,
                                            color: Colors.grey[300],
                                          ),
                                          const SizedBox(height: 16),
                                          if (uniqueTrains.isNotEmpty)
                                            _buildFilterDropdown(
                                              label: 'Train',
                                              value: selectedTrain,
                                              options: ['All', ...uniqueTrains],
                                              onChanged: (value) {
                                                setState(() {
                                                  selectedTrain =
                                                      value == 'All'
                                                          ? null
                                                          : value;
                                                  _applyFilters();
                                                });
                                              },
                                            ),
                                          const SizedBox(height: 12),
                                          _buildFilterDropdown(
                                            label: 'Status',
                                            value: selectedStatus,
                                            options: [
                                              'All',
                                              'Active',
                                              'Pending',
                                              'Closed'
                                            ],
                                            onChanged: (value) {
                                              setState(() {
                                                selectedStatus = value;
                                                _applyFilters();
                                              });
                                            },
                                          ),
                                          const SizedBox(height: 16),
                                          Center(
                                            child: TextButton(
                                              onPressed: _clearFilters,
                                              child: const Text(
                                                'Clear All Filters',
                                                style: TextStyle(
                                                  color: kRailwayBlue,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Expanded(
                      child: filteredInstances.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.train,
                                    size: 64,
                                    color: Colors.grey[300],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No run instances found',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  if (_searchQuery.isNotEmpty ||
                                      selectedTrain != null ||
                                      (selectedStatus != null &&
                                          selectedStatus != 'All')) ...[
                                    const SizedBox(height: 8),
                                    TextButton(
                                      onPressed: _clearFilters,
                                      child: const Text('Clear filters'),
                                    ),
                                  ],
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.only(
                                  left: 20, right: 20, bottom: 100),
                              itemCount: filteredInstances.length,
                              itemBuilder: (context, index) {
                                final instance = filteredInstances[index];
                                return _buildInstanceCard(instance);
                              },
                            ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreateInstance,
        backgroundColor: kRailwayBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Create Run',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: kErrorRed),
            const SizedBox(height: 16),
            Text(
              'Error loading run instances',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadRunInstances,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text(
                'Retry',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: kRailwayBlue,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String? value,
    required List<String> options,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value ?? options.first,
              items: options
                  .map(
                    (option) => DropdownMenuItem(
                      value: option,
                      child: Text(
                        option,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                if (val != null) onChanged(val);
              },
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down,
                size: 20,
                color: kRailwayBlue,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInstanceCard(RunInstanceModel instance) {
    final assignedCount =
        instance.coaches.where((c) => c.workerId != null).length;
    final totalCount = instance.coaches.length;

    return InkWell(
      onTap: () => _showInstanceDetails(instance),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getStatusColor(instance.status).withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: kRailwayBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.tag,
                            size: 14,
                            color: kRailwayBlue,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              instance.instanceId,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: kRailwayBlue,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(instance.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      instance.status,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(instance.status),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildActionMenu(instance),
                ],
              ),

              const SizedBox(height: 12),

              if (instance.trainName != null) ...[
                Text(
                  instance.trainName!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
              ],
              if (instance.trainNo != null)
                Text(
                  'Train #${instance.trainNo}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),

              const SizedBox(height: 12),

              // Train Numbers Row
              Row(
                children: [
                  if (instance.outboundTrainNo != null)
                    Expanded(
                      child: _buildCompactInfo(
                        icon: Icons.arrow_downward,
                        label: 'Down',
                        value: instance.outboundTrainNo!,
                        color: Colors.blue,
                      ),
                    ),
                  if (instance.outboundTrainNo != null &&
                      instance.inboundTrainNo != null)
                    const SizedBox(width: 10),
                  if (instance.inboundTrainNo != null)
                    Expanded(
                      child: _buildCompactInfo(
                        icon: Icons.arrow_upward,
                        label: 'Up',
                        value: instance.inboundTrainNo!,
                        color: Colors.green,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Stats Row
              Row(
                children: [
                  Expanded(
                    child: _buildSimpleStat(
                      icon: Icons.train,
                      value: '$assignedCount/$totalCount',
                      label: 'Coaches',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildSimpleStat(
                      icon: Icons.people_outline,
                      value: '$assignedCount',
                      label: 'Workers',
                    ),
                  ),
                  if (instance.createdAt != null) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildSimpleStat(
                        icon: Icons.calendar_today_outlined,
                        value: DateFormat('dd MMM').format(instance.createdAt!),
                        label: 'Created',
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionMenu(RunInstanceModel instance) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: Colors.grey[700],
        size: 20,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      offset: const Offset(0, 40),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'details',
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: kRailwayBlue),
              const SizedBox(width: 10),
              const Text('View Details'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 18, color: Colors.orange),
              const SizedBox(width: 10),
              const Text('Edit Instance'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 18, color: kErrorRed),
              const SizedBox(width: 10),
              const Text('Delete Instance'),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'details':
            _showInstanceDetails(instance);
            break;
          case 'edit':
            _editInstance(instance);
            break;
          case 'delete':
            _deleteInstance(instance);
            break;
        }
      },
    );
  }

  Widget _buildCompactInfo({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleStat({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[700]),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showInstanceDetails(RunInstanceModel instance) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          instance.instanceId,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        if (instance.trainName != null)
                          Text(
                            instance.trainName!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context); // close bottom sheet
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OBHSReviewQueueScreen(
                          runInstanceId: instance.runInstanceId ?? instance.id!,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.fact_check, color: Colors.white),
                  label: const Text('Review Pending Tasks', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Coaches Assignment',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: instance.coaches.length,
                  itemBuilder: (context, index) {
                    final coach = instance.coaches[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.blue[100],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Center(
                                child: Text(
                                  '${coach.coachPosition}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Coach ${coach.coachPosition}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  if (coach.workerId != null)
                                    Row(
                                      children: [
                                        Text('Worker: ${coach.workerName}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        InkWell(
                                          onTap: () => _assignWorkerFlow(instance, index),
                                          child: const Icon(Icons.edit, size: 14, color: kRailwayBlue),
                                        )
                                      ],
                                    )
                                  else
                                    InkWell(
                                      onTap: () => _assignWorkerFlow(instance, index),
                                      child: Row(
                                        children: [
                                          Text(
                                            'No worker assigned',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.orange[700],
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(Icons.add_circle, size: 14, color: Colors.orange),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.green[300]!),
                              ),
                              child: Text(
                                coach.coachType,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Future<void> _assignWorkerFlow(RunInstanceModel instance, int coachIndex) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final workers = await OBHSRepository.getWorkers();
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      final selectedWorker = await showModalBottomSheet<RailwayWorkerModel>(
        context: context,
        builder: (context) => Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Select Worker to Assign', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: workers.length,
                itemBuilder: (context, index) {
                  final worker = workers[index];
                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(worker.fullName),
                    subtitle: Text(worker.designation ?? ''),
                    onTap: () => Navigator.pop(context, worker),
                  );
                },
              ),
            ),
          ],
        ),
      );

      if (selectedWorker != null) {
        // Show saving...
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );

        // Modify the instance coaches locally
        final updatedCoaches = List<CoachAssignment>.from(instance.coaches);
        updatedCoaches[coachIndex] = updatedCoaches[coachIndex].copyWith(
          workerId: selectedWorker.uid,
          workerName: selectedWorker.fullName,
        );

        // Update in backend
        await OBHSRepository.updateRunInstance(
          runInstanceId: instance.runInstanceId ?? instance.id ?? '',
          coaches: updatedCoaches,
        );

        if (!mounted) return;
        Navigator.pop(context); // close saving dialog
        Navigator.pop(context); // close bottom sheet
        _loadRunInstances(); // reload list
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Worker assigned successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
