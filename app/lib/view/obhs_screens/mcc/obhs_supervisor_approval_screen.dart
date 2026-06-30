import 'package:flutter/material.dart';
import 'package:crm_train/utills/app_colors.dart';

class ObhsSupervisorApprovalScreen extends StatefulWidget {
  const ObhsSupervisorApprovalScreen({super.key});

  @override
  State<ObhsSupervisorApprovalScreen> createState() => _ObhsSupervisorApprovalScreenState();
}

class _ObhsSupervisorApprovalScreenState extends State<ObhsSupervisorApprovalScreen> {
  final List<Map<String, dynamic>> pendingApprovals = [
    {
      'id': 'a1',
      'worker': 'Amit Singh',
      'coach': 'B1',
      'task': 'Toilet 1 Cleaning',
      'time': '10:45 AM',
      'beforePhoto': true,
      'afterPhoto': true,
      'comments': 'Choke cleared successfully.',
    },
    {
      'id': 'a2',
      'worker': 'Amit Singh',
      'coach': 'B1',
      'task': 'Toilet 2 Cleaning',
      'time': '11:10 AM',
      'beforePhoto': true,
      'afterPhoto': true,
      'comments': '',
    },
    {
      'id': 'a3',
      'worker': 'Suresh D',
      'coach': 'B3',
      'task': 'Aisle Mopping',
      'time': '11:30 AM',
      'beforePhoto': false,
      'afterPhoto': true,
      'comments': 'Passengers walking, delayed.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Pending Approvals',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: kRailwayBlue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: pendingApprovals.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: pendingApprovals.length,
              itemBuilder: (context, index) {
                return _buildApprovalCard(pendingApprovals[index]);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.done_all, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'All caught up!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No pending approvals at the moment.',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalCard(Map<String, dynamic> item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Column(
        children: [
          _buildCardHeader(item),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailsRow('Worker', item['worker']),
                const SizedBox(height: 8),
                _buildDetailsRow('Time', item['time']),
                if (item['comments'].isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Janitor Comments:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(item['comments'], style: TextStyle(fontSize: 13, color: Colors.grey[800])),
                      ],
                    ),
                  )
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildPhotoThumbnail('Before', item['beforePhoto']),
                    _buildPhotoThumbnail('After', item['afterPhoto']),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _handleReject(item),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kErrorRed,
                          side: const BorderSide(color: kErrorRed),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () => _handleApprove(item),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kSuccessGreen,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Approve', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardHeader(Map<String, dynamic> item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: kRailwayBlue.withOpacity(0.05),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: kRailwayBlue,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item['coach'],
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                item['task'],
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const Icon(Icons.pending_actions, color: kWarningOrange),
        ],
      ),
    );
  }

  Widget _buildDetailsRow(String label, String value) {
    return Row(
      children: [
        SizedBox(width: 80, child: Text(label, style: TextStyle(color: Colors.grey[600]))),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildPhotoThumbnail(String label, bool hasPhoto) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: hasPhoto
              ? const Icon(Icons.image, size: 40, color: Colors.grey)
              : const Center(child: Text('No Photo', style: TextStyle(color: Colors.grey, fontSize: 12))),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  void _handleApprove(Map<String, dynamic> item) {
    setState(() {
      pendingApprovals.remove(item);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Task Approved'), backgroundColor: kSuccessGreen),
    );
  }

  void _handleReject(Map<String, dynamic> item) {
    // Show rejection reason dialog
    showDialog(
      context: context,
      builder: (ctx) {
        final reasonController = TextEditingController();
        return AlertDialog(
          title: const Text('Reject Task'),
          content: TextField(
            controller: reasonController,
            decoration: const InputDecoration(
              hintText: 'Enter reason for rejection...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: kErrorRed),
              onPressed: () {
                Navigator.pop(ctx);
                setState(() {
                  pendingApprovals.remove(item);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Task Rejected'), backgroundColor: kErrorRed),
                );
              },
              child: const Text('Confirm Reject', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
