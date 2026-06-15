import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../model/coach_scorecard_model.dart';


class ScorecardViewScreen extends StatefulWidget {
  final ScorecardResponse scorecard;
  final String trainName;
  final DateTime formDate;

  const ScorecardViewScreen({
    super.key,
    required this.scorecard,
    required this.trainName,
    required this.formDate,
  });

  @override
  State<ScorecardViewScreen> createState() => _ScorecardViewScreenState();
}

class _ScorecardViewScreenState extends State<ScorecardViewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Scorecard Review',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xff4059ed),
          unselectedLabelColor: Colors.black54,
          indicatorColor: const Color(0xff4059ed),
          tabs: const [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.table_chart, size: 18),
                  SizedBox(width: 6),
                  Text('Evaluations'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.analytics, size: 18),
                  SizedBox(width: 6),
                  Text('Summary'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildScorecardHeader(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildEvaluationsTab(),
                _buildSummaryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScorecardHeader() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xff4059ed), const Color(0xff5a70ff)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff4059ed).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.check_circle,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Scoring Completed',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'by ${widget.scorecard.submittedBy}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _headerInfo('Train', widget.trainName),
              _headerInfo('Work Type', widget.scorecard.workType),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _headerInfo('ACWP Status', widget.scorecard.acwpStatus),
              _headerInfo(
                'Scored On',
                DateFormat('dd/MM/yyyy').format(widget.scorecard.submittedDate),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildEvaluationsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Evaluations Table
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(
                    const Color(0xffe9edff)),
                border: TableBorder(
                  horizontalInside:
                  BorderSide(color: Colors.grey.shade300),
                  verticalInside: BorderSide(color: Colors.grey.shade300),
                  bottom: BorderSide(color: Colors.grey.shade300),
                  top: BorderSide(color: Colors.grey.shade300),
                  left: BorderSide(color: Colors.grey.shade300),
                  right: BorderSide(color: Colors.grey.shade300),
                ),
                columnSpacing: 12,
                headingRowHeight: 45,
                dataRowHeight: 55,
                columns: const [
                  DataColumn(
                    label: Text('Coach\nNo.',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 11)),
                  ),
                  DataColumn(
                    label: Text('Internal\nCleaning',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 11)),
                  ),
                  DataColumn(
                    label: Text('External\nCleaning',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 11)),
                  ),
                  DataColumn(
                    label: Text('Intensive\nCleaning',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 11)),
                  ),
                  DataColumn(
                    label: Text('Toiletries',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 11)),
                  ),
                  DataColumn(
                    label: Text('Doors\nLocking',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 11)),
                  ),
                  DataColumn(
                    label: Text('Watering',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 11)),
                  ),
                  DataColumn(
                    label: Text('Penalty\n(₹)',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 11)),
                  ),
                ],
                rows: List.generate(
                  widget.scorecard.evaluations.length,
                      (index) => _buildEvaluationRow(
                      widget.scorecard.evaluations[index], index),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  DataRow _buildEvaluationRow(CoachEvaluation coach, int index) {
    return DataRow(
      color: MaterialStateProperty.all(
        index % 2 == 0 ? Colors.grey.shade50 : Colors.white,
      ),
      cells: [
        DataCell(
          Text(
            coach.coachNumber,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ),
        DataCell(_buildGradeCell(coach.internalCleaning)),
        DataCell(_buildGradeCell(coach.externalCleaning)),
        DataCell(_buildGradeCell(coach.intensiveCleaning)),
        DataCell(_buildStatusCell(coach.toiletries)),
        DataCell(_buildStatusCell(coach.doorsLocking)),
        DataCell(_buildStatusCell(coach.watering)),
        DataCell(_buildPenaltyCell(coach.penalty)),
      ],
    );
  }

  Widget _buildGradeCell(String grade) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: _getGradeColor(grade).withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _getGradeColor(grade)),
      ),
      child: Text(
        grade,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: _getGradeColor(grade),
        ),
      ),
    );
  }

  Widget _buildStatusCell(String status) {
    Color color = status == 'Yes'
        ? Colors.green
        : status == 'No'
        ? Colors.red
        : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 11,
          color: color,
        ),
      ),
    );
  }

  Widget _buildPenaltyCell(int penalty) {
    Color color = penalty == 0
        ? Colors.green
        : penalty == 50
        ? Colors.blue
        : penalty == 100
        ? Colors.orange
        : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color),
      ),
      child: Text(
        '₹$penalty',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: color,
        ),
      ),
    );
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'A':
        return Colors.green;
      case 'B':
        return Colors.blue;
      case 'C':
        return Colors.orange;
      case 'D':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildSummaryTab() {
    int totalCoaches = widget.scorecard.evaluations.length;
    int totalPenalty = widget.scorecard.evaluations
        .fold(0, (sum, coach) => sum + coach.penalty);

    Map<String, int> internalGrades = {'A': 0, 'B': 0, 'C': 0, 'D': 0};
    Map<String, int> externalGrades = {'A': 0, 'B': 0, 'C': 0, 'D': 0};
    Map<String, int> intensiveGrades = {'A': 0, 'B': 0, 'C': 0, 'D': 0};
    Map<String, int> yesNoStats = {'Yes': 0, 'No': 0, 'NA': 0};

    for (var coach in widget.scorecard.evaluations) {
      if (coach.internalCleaning != 'NA') {
        internalGrades[coach.internalCleaning] =
            (internalGrades[coach.internalCleaning] ?? 0) + 1;
      }
      if (coach.externalCleaning != 'NA') {
        externalGrades[coach.externalCleaning] =
            (externalGrades[coach.externalCleaning] ?? 0) + 1;
      }
      if (coach.intensiveCleaning != 'NA') {
        intensiveGrades[coach.intensiveCleaning] =
            (intensiveGrades[coach.intensiveCleaning] ?? 0) + 1;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Overall Statistics',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _statBox('Total Coaches', '$totalCoaches', Colors.indigo),
                    _statBox('Total Penalty', '₹$totalPenalty', Colors.red),
                  ],
                ),
              ],
            ),
          ),
          _buildGradeSummary('Internal Cleaning', internalGrades),
          const SizedBox(height: 12),
          _buildGradeSummary('External Cleaning', externalGrades),
          const SizedBox(height: 12),
          _buildGradeSummary('Intensive Cleaning', intensiveGrades),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildGradeSummary(String title, Map<String, int> grades) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['A', 'B', 'C', 'D'].map((grade) {
              int count = grades[grade] ?? 0;
              return _gradeStatBox(grade, count);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _statBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gradeStatBox(String grade, int count) {
    Color color = _getGradeColor(grade);
    return Container(
      width: 70,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            'Grade $grade',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            count.toString(),
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}