import 'package:flutter/material.dart';
import 'package:crm_train/utills/app_colors.dart';
import 'package:crm_train/services/api_services.dart';

class ObhsReportSummaryScreen extends StatefulWidget {
  const ObhsReportSummaryScreen({super.key});

  @override
  State<ObhsReportSummaryScreen> createState() => _ObhsReportSummaryScreenState();
}

class _ObhsReportSummaryScreenState extends State<ObhsReportSummaryScreen> {
  bool _isSendingEmail = false;

  void _sendEmail() async {
    setState(() {
      _isSendingEmail = true;
    });
    try {
      // Hardcoded for testing; ideally passed via widget props
      final response = await ApiServices.sendAuditReportEmail(
          'OPERATIONAL_AUDIT', 'dummy_run_id', 'hirenkodwani@gmail.com');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Email Sent!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to send email: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingEmail = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Run Summary Report',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: kRailwayBlue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildScoreHeader(),
            _buildExportSection(),
            _buildDetailedTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: kRailwayBlue,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          const Text('Final Train Score', style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 8),
          const Text('92%', style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(color: kSuccessGreen, borderRadius: BorderRadius.circular(20)),
            child: const Text('GRADE A', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat('Total Tasks', '140'),
              _buildStat('Completed', '132'),
              _buildStat('Penalties', '0'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildExportSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Download PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.table_chart),
                  label: const Text('Download Excel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSendingEmail ? null : _sendEmail,
              icon: _isSendingEmail 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send),
              label: Text(_isSendingEmail ? 'Sending...' : 'Send to Higher Authority'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kRailwayBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedTable() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Coach-wise Breakdown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Coach')),
                DataColumn(label: Text('Worker')),
                DataColumn(label: Text('Score')),
                DataColumn(label: Text('Status')),
              ],
              rows: const [
                DataRow(cells: [
                  DataCell(Text('B1', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text('Amit Singh')),
                  DataCell(Text('100%')),
                  DataCell(Text('Approved', style: TextStyle(color: kSuccessGreen))),
                ]),
                DataRow(cells: [
                  DataCell(Text('B2', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text('Amit Singh')),
                  DataCell(Text('80%')),
                  DataCell(Text('Approved', style: TextStyle(color: kSuccessGreen))),
                ]),
                DataRow(cells: [
                  DataCell(Text('A1', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text('Rahul V')),
                  DataCell(Text('95%')),
                  DataCell(Text('Pending', style: TextStyle(color: kWarningOrange))),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
