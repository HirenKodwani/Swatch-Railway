import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../repositories/obhs_repository.dart';
import '../../utills/app_colors.dart';

class OBHSReviewQueueScreen extends StatefulWidget {
  final String runInstanceId;

  const OBHSReviewQueueScreen({super.key, required this.runInstanceId});

  @override
  State<OBHSReviewQueueScreen> createState() => _OBHSReviewQueueScreenState();
}

class _OBHSReviewQueueScreenState extends State<OBHSReviewQueueScreen> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _tasks = [];

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tasks = await OBHSRepository.getPendingReviewTasks(widget.runInstanceId);
      if (mounted) {
        setState(() {
          _tasks = tasks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateTask(String taskId, String status, int score) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      await OBHSRepository.updateTaskStatus(taskId, status, supervisorScore: score);

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Task ${status.toLowerCase()} successfully'),
            backgroundColor: status == 'APPROVED' ? Colors.green : Colors.red,
          ),
        );
        _fetchTasks(); // Refresh list
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update task: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showScoreDialog(String taskId, String action) {
    int score = 10;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('$action Task'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Provide a supervisor score for this task (1-10) before you ${action.toLowerCase()} it:'),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Score:'),
                      Text('$score/10', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                  Slider(
                    value: score.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: score.toString(),
                    onChanged: (val) {
                      setDialogState(() {
                        score = val.toInt();
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: action == 'Approve' ? Colors.green : Colors.red,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _updateTask(taskId, action == 'Approve' ? 'APPROVED' : 'REJECTED', score);
                  },
                  child: Text(action, style: const TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Queue', style: TextStyle(color: Colors.white)),
        backgroundColor: kRailwayBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchTasks,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchTasks,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _tasks.isEmpty
                  ? const Center(child: Text('No tasks pending review.'))
                  : ListView.builder(
                      itemCount: _tasks.length,
                      padding: const EdgeInsets.all(12),
                      itemBuilder: (context, index) {
                        final task = _tasks[index];
                        final String taskId = task['id'] ?? task['taskId'] ?? '';
                        final String taskName = task['taskName'] ?? task['taskType'] ?? 'Unknown Task';
                        final String workerName = task['workerName'] ?? 'Unknown Worker';
                        final String coachId = task['coachId'] ?? 'Unknown Coach';
                        final String submittedAt = task['submittedAt'] ?? '';
                        
                        String formattedTime = 'Recently';
                        if (submittedAt.isNotEmpty) {
                          try {
                            final dt = DateTime.parse(submittedAt).toLocal();
                            formattedTime = DateFormat('dd MMM, hh:mm a').format(dt);
                          } catch (_) {}
                        }

                        final String beforePhoto = task['beforePhotoUrl'] ?? '';
                        final String afterPhoto = task['afterPhotoUrl'] ?? '';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                                        taskName,
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'SUBMITTED',
                                        style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('Worker: $workerName', style: TextStyle(color: Colors.grey[700])),
                                Text('Coach: $coachId', style: TextStyle(color: Colors.grey[700])),
                                Text('Submitted: $formattedTime', style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                                const SizedBox(height: 12),
                                if (beforePhoto.isNotEmpty || afterPhoto.isNotEmpty)
                                  Row(
                                    children: [
                                      if (beforePhoto.isNotEmpty)
                                        Expanded(
                                          child: Column(
                                            children: [
                                              const Text('Before', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                              const SizedBox(height: 4),
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: Image.network(beforePhoto, height: 100, width: double.infinity, fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) => Container(height: 100, color: Colors.grey[200], child: const Icon(Icons.broken_image, color: Colors.grey)),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      if (beforePhoto.isNotEmpty && afterPhoto.isNotEmpty)
                                        const SizedBox(width: 8),
                                      if (afterPhoto.isNotEmpty)
                                        Expanded(
                                          child: Column(
                                            children: [
                                              const Text('After', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                              const SizedBox(height: 4),
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: Image.network(afterPhoto, height: 100, width: double.infinity, fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) => Container(height: 100, color: Colors.grey[200], child: const Icon(Icons.broken_image, color: Colors.grey)),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => _showScoreDialog(taskId, 'Reject'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.red, side: const BorderSide(color: Colors.red),
                                        ),
                                        child: const Text('Reject'),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () => _showScoreDialog(taskId, 'Approve'),
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                        child: const Text('Approve', style: TextStyle(color: Colors.white)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
