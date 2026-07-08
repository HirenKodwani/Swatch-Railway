import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:http/http.dart' as http;
import '../../../model/coach_form_model.dart';
import '../../../model/coach_scorecard_model.dart';

class ContractorFormDetailsWithScorecard extends StatefulWidget {
  final CoachForm form;
  final ScorecardResponse? scorecard;

  const ContractorFormDetailsWithScorecard({
    super.key,
    required this.form,
    this.scorecard,
  });

  @override
  State<ContractorFormDetailsWithScorecard> createState() =>
      _ContractorFormDetailsWithScorecardState();
}

class _ContractorFormDetailsWithScorecardState
    extends State<ContractorFormDetailsWithScorecard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.form.hasScoringDetails() ? 2 : 1,
      vsync: this,
    );
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
          'Form Details',
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
        actions: [
          if (widget.form.status.toLowerCase() == 'locked' || widget.form.status.toLowerCase() == 'auto-approved')
            IconButton(
              onPressed: _downloadPDF,
              icon: const Icon(Icons.download, color: Colors.black87),
              tooltip: 'Download PDF',
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                labelColor: const Color(0xff4059ed),
                unselectedLabelColor: Colors.black54,
                indicatorColor: const Color(0xff4059ed),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.description, size: 18),
                        SizedBox(width: 6),
                        Text('Form Details'),
                      ],
                    ),
                  ),
                  if (widget.form.hasScoringDetails())
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              Icons.check_circle,
                              size: 16,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text('Scorecard'),
                        ],
                      ),
                    ),
                ],
              ),
              if (widget.form.hasScoringDetails())
                Container(height: 2, color: Colors.green.withOpacity(0.3)),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFormDetailsTab(),
          if (widget.form.hasScoringDetails()) _buildScorecardTab(),
        ],
      ),
    );
  }

  Widget _buildFormDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTrainDetailsCard(),
          const SizedBox(height: 16),

          _buildSubmittedToCard(),
          const SizedBox(height: 16),

          _buildMachinesCard(),
          const SizedBox(height: 16),

          _buildChemicalsCard(),
          const SizedBox(height: 16),

          _buildEmployeeCard(),
          const SizedBox(height: 16),

          _buildSignatureCard(),

          const SizedBox(height: 16),

          if ((widget.form.contractorRemarks ?? '').trim().isNotEmpty) ...[
            _buildContractorRemarksCard(),
            const SizedBox(height: 16),
          ],

          if ((widget.form.rejectionComments ?? '').trim().isNotEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.8),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.cancel_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Rejection Details',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  infoRow(
                    'Rejected By:',
                    widget.form.submittedTo.railwayEmployeeName,
                  ),
                  infoRow(
                    'Rejected Date:',
                    widget.form.rejectAt != null
                        ? DateFormat(
                            'dd/MM/yyyy HH:mm',
                          ).format(widget.form.rejectAt!)
                        : 'N/A',
                  ),
                  infoRow(
                    'Rejected Comment:',
                    widget.form.rejectionComments ?? '',
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),

          if (widget.form.hasScoringDetails()) ...[
            const SizedBox(height: 16),
            _buildScorecardStatusBanner(),
          ],

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildTrainDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Coach Cleaning\nForm Details',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xffe9edff),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.form.status,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xff4059ed),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _infoRow(
            'Train:',
            '${widget.form.trainNumber} - ${widget.form.trainName}',
          ),
          const SizedBox(height: 8),
          _infoRow('No of Coaches:', widget.form.coachCount.toString()),
          if (widget.form.submittedByDepot != null &&
              widget.form.submittedByDepot!.isNotEmpty)
            const SizedBox(height: 8),
          if (widget.form.submittedByDepot != null &&
              widget.form.submittedByDepot!.isNotEmpty)
            _infoRow('Depot:', widget.form.submittedByDepot!),
          const SizedBox(height: 8),
          _infoRow('Zone:', widget.form.submittedByZone),
          const SizedBox(height: 8),
          _infoRow('Division:', widget.form.submittedByDivision),
          const SizedBox(height: 8),
          _infoRow('Form ID:', widget.form.uid),
          const SizedBox(height: 8),
          _infoRow('Contractor Supervisor:', widget.form.submittedByName),
          const SizedBox(height: 8),
          _infoRow('Contractor Company:', widget.form.submittedByEntityName),
          const SizedBox(height: 8),
          _infoRow(
            'Submitted Date:',
            DateFormat(
              'dd/MM/yyyy HH:mm',
            ).format(DateTime.parse(widget.form.formDateTime).toLocal()),
          ),
        ],
      ),
    );
  }

  Widget infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMachinesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
            'Machines Used',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.start,
            children: widget.form.machinesUsed.isEmpty
                ? [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'No machines used',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ),
                  ]
                : widget.form.machinesUsed
                      .map(
                        (m) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.green.shade300),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 14,
                                color: Colors.green.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                m,
                                style: TextStyle(
                                  color: Colors.green.shade800,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildChemicalsCard() {
    String formatNum(num value) {
      if (value % 1 == 0) {
        return value.toInt().toString();
      }
      return value.toString();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
            'Chemicals Used (in ml)',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          _chemicalRow('Spiral', formatNum(widget.form.chemicals.spiral)),
          _chemicalRow('R3', formatNum(widget.form.chemicals.r3)),
          _chemicalRow('R7 / R2', formatNum(widget.form.chemicals.r7R2)),
          _chemicalRow('R5', formatNum(widget.form.chemicals.r5)),
          _chemicalRow('R1 / R6', formatNum(widget.form.chemicals.r1R6)),
          _chemicalRow('TRIAD-III', formatNum(widget.form.chemicals.triadIii)),
          _chemicalRow('Suma Inox', formatNum(widget.form.chemicals.sumaInox)),
        ],
      ),
    );
  }

  Widget _buildEmployeeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            children: [
              const Icon(Icons.group, color: Colors.deepPurple, size: 20),
              const SizedBox(width: 8),
              Text(
                'Manpower (${widget.form.manpower.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            color: Colors.deepPurple.shade50,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            child: const Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'S.No',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Name',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Designation',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Remark',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.grey),
          ...widget.form.manpower.asMap().entries.map((entry) {
            final i = entry.key + 1;
            final e = entry.value;
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.black12)),
              ),
              child: Row(
                children: [
                  Expanded(flex: 2, child: Text('$i')),
                  Expanded(flex: 3, child: Text(e.name)),
                  Expanded(
                    flex: 3,
                    child: Text(
                      e.designation,
                      style: const TextStyle(color: Colors.deepOrange),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      e.remark,
                      style: const TextStyle(color: Colors.deepOrange),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildScorecardStatusBanner() {
    return GestureDetector(
      onTap: () {
        if (widget.form.hasScoringDetails()) {
          _tabController.animateTo(1);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade400, Colors.green.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Scoring Completed',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Scored on ${widget.form.ratedAt?.toFormattedString() ?? 'N/A'}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildScorecardTab() {
    if (!widget.form.hasScoringDetails()) {
      return const Center(child: Text('No scorecard available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(children: [_buildScorecardContent()]),
    );
  }

  Widget _buildScorecardContent() {
    final ratingDetails = widget.form.ratingDetails!;
    final summary = ratingDetails.summary;

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 16),
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
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 24,
                    ),
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
                        'by ${widget.form.submittedTo.railwayEmployeeName}',
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
                  _headerInfo('Work Type', ratingDetails.workType),
                  _headerInfo('ACWP Status', ratingDetails.acwpStatus),
                ],
              ),
            ],
          ),
        ),

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
                const Color(0xffe9edff),
              ),
              border: TableBorder(
                horizontalInside: BorderSide(color: Colors.grey.shade300),
                verticalInside: BorderSide(color: Colors.grey.shade300),
                bottom: BorderSide(color: Colors.grey.shade300),
                top: BorderSide(color: Colors.grey.shade300),
              ),
              columnSpacing: 12,
              headingRowHeight: 45,
              dataRowHeight: 55,
              columns: const [
                DataColumn(
                  label: Text(
                    'Coach',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Internal',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'External',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Intensive',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Penalty',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
                  ),
                ),
              ],
              rows: List.generate(ratingDetails.coachEvaluationTable.length, (
                index,
              ) {
                final coach = ratingDetails.coachEvaluationTable[index];
                return DataRow(
                  color: MaterialStateProperty.all(
                    index % 2 == 0 ? Colors.grey.shade50 : Colors.white,
                  ),
                  cells: [
                    DataCell(
                      Text(
                        coach.coachNumber,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    DataCell(_buildGradeCell(coach.internalCleaning)),
                    DataCell(_buildGradeCell(coach.externalCleaning)),
                    DataCell(_buildGradeCell(coach.intensiveCleaning)),
                    DataCell(_buildPenaltyCell(coach.penalty)),
                  ],
                );
              }),
            ),
          ),
        ),

        Container(
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
                'Summary',
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
                  _statBox(
                    'Total Coaches',
                    '${summary.totalCoaches}',
                    Colors.indigo,
                  ),
                  _statBox(
                    'Total Penalty',
                    '₹${ratingDetails.totalPenalty}',
                    Colors.red,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSummarySection('Internal Cleaning', summary.internal),
              const SizedBox(height: 12),
              _buildSummarySection('External Cleaning', summary.external),
              const SizedBox(height: 12),
              _buildSummarySection('Intensive Cleaning', summary.intensive),
            ],
          ),
        ),

        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildSummarySection(String title, Map<String, int> grades) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['A', 'B', 'C', 'D'].map((grade) {
              int count = grades[grade] ?? 0;
              return _gradeBox(grade, count);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _gradeBox(String grade, int count) {
    Color color = _getGradeColor(grade);
    return Container(
      width: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            grade,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            count.toString(),
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
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

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.black54,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _chemicalRow(String label, String qty) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            '$qty ml',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
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

  Widget _buildSubmittedToCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            children: [
              const Icon(Icons.person_outline, color: Colors.teal, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Submitted To',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _infoRow(
            'Employee Name:',
            widget.form.submittedTo.railwayEmployeeName,
          ),
          const SizedBox(height: 8),
          _infoRow('Division:', widget.form.submittedTo.division),
          const SizedBox(height: 8),
          if(widget.form.submittedTo.depot != null)
          _infoRow('Depot:', widget.form.submittedTo.depot ?? ''),
        ],
      ),
    );
  }

  Widget _buildSignatureCard() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
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
              Row(
                children: [
                  const Icon(
                    Icons.edit_document,
                    color: Colors.deepOrange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Signature Details',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _infoRow(
                'Signature By:',
                widget.form.signature.name,
              ),
              const SizedBox(height: 8),
              _infoRow('Date:', _formatDateForPDF(widget.form.signature.date)),
            ],
          ),
        ),
        if (widget.form.resubmitSign != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.redAccent, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.edit_document,
                      color: Colors.deepOrange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Resubmit Signature Details',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _infoRow(
                  'Resubmitted By:',
                  widget.form.resubmitSign!.name,
                ),
                const SizedBox(height: 8),
                _infoRow('Date:', _formatDateForPDF(widget.form.resubmitSign!.date)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildContractorRemarksCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            children: [
              const Icon(Icons.comment, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Contractor Remarks (Resubmission)',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.form.contractorRemarks ?? '',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ],
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



  String _formatDateForPDF(String dateStr) {
    try {
      DateTime date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  Future<void> _downloadPDF() async {
    final form = widget.form;

    try {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Generating PDF...')));

      final pdf = pw.Document();

      pw.MemoryImage? indianRailwayLogo;
      pw.MemoryImage? swachhBharatLogo;
      pw.MemoryImage? pisolveLogo;

      try {
        final irBytes = await rootBundle.load(
          'assets/images/indian_railway.png',
        );
        indianRailwayLogo = pw.MemoryImage(irBytes.buffer.asUint8List());

        final sbBytes = await rootBundle.load(
          'assets/images/swachh_bharat.png',
        );
        swachhBharatLogo = pw.MemoryImage(sbBytes.buffer.asUint8List());

        final pisolveBytes = await rootBundle.load('assets/images/mirtha.jpg');
        pisolveLogo = pw.MemoryImage(pisolveBytes.buffer.asUint8List());
      } catch (e) {
        debugPrint('Error loading logos: $e');
      }

      pw.Widget buildHeader(pw.Context context) {
        return pw.Column(
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                if (indianRailwayLogo != null)
                  pw.Container(
                    width: 45,
                    height: 45,
                    child: pw.Image(indianRailwayLogo, fit: pw.BoxFit.contain),
                  )
                else
                  pw.SizedBox(width: 45),

                if (swachhBharatLogo != null)
                  pw.Container(
                    width: 45,
                    height: 45,
                    child: pw.Image(swachhBharatLogo, fit: pw.BoxFit.contain),
                  )
                else
                  pw.SizedBox(width: 45),

                if (pisolveLogo != null)
                  pw.Container(
                    width: 45,
                    height: 45,
                    child: pw.Image(pisolveLogo, fit: pw.BoxFit.contain),
                  )
                else
                  pw.SizedBox(width: 45),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Center(
              child: pw.Text(
                'COACH CLEANING FORM',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Center(
              child: pw.Text(
                'Zone: ${form.submittedByZone}, Division: ${form.submittedByDivision}${(form.submittedByDepot != null && form.submittedByDepot!.isNotEmpty) ? ', Depot: ${form.submittedByDepot}' : ''}',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.red900,
                ),
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                vertical: 4,
                horizontal: 8,
              ),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.blue700, width: 1.5),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Text(
                'Form ID - ${form.uid}',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
            ),
            pw.SizedBox(height: 10),
          ],
        );
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          header: buildHeader,
          build: (context) => [
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey800, width: 1),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(3),
              },
              children: [
                _buildCoachPDFTableRow(
                  'Train',
                  form.trainName,
                  'Submitted Date:',
                  DateFormat(
                    'dd/MM/yyyy HH:mm',
                  ).format(DateTime.parse(form.formDateTime).toLocal()),
                ),
                _buildCoachPDFTableRow(
                  'No of Coaches',
                  form.coachCount.toString(),
                  'Company:',
                  form.submittedByEntityName,
                ),
                _buildCoachPDFTableRow(
                  'Status',
                  form.status,
                  'Submitted By',
                  form.submittedByName,
                ),
                _buildCoachPDFTableRow(
                  'Submitted to',
                  form.submittedTo.railwayEmployeeName,
                  '',
                  '',
                ),
              ],
            ),
            pw.SizedBox(height: 10),

            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  flex: 2,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(6),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey400),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Machines Used',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          form.machinesUsed.isEmpty
                              ? 'None'
                              : form.machinesUsed.join(', '),
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  flex: 3,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(6),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey400),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Chemicals Used (ml)',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Wrap(
                          spacing: 8,
                          runSpacing: 2,
                          children: [
                            pw.Text(
                              'Spiral:${form.chemicals.spiral}',
                              style: const pw.TextStyle(fontSize: 8),
                            ),
                            pw.Text(
                              'R3:${form.chemicals.r3}',
                              style: const pw.TextStyle(fontSize: 8),
                            ),
                            pw.Text(
                              'R7/R2:${form.chemicals.r7R2}',
                              style: const pw.TextStyle(fontSize: 8),
                            ),
                            pw.Text(
                              'R5:${form.chemicals.r5}',
                              style: const pw.TextStyle(fontSize: 8),
                            ),
                            pw.Text(
                              'R1/R6:${form.chemicals.r1R6}',
                              style: const pw.TextStyle(fontSize: 8),
                            ),
                            pw.Text(
                              'TRIAD:${form.chemicals.triadIii}',
                              style: const pw.TextStyle(fontSize: 8),
                            ),
                            pw.Text(
                              'Inox:${form.chemicals.sumaInox}',
                              style: const pw.TextStyle(fontSize: 8),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 10),

            pw.Text(
              'Manpower Details',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              columnWidths: {
                0: const pw.FlexColumnWidth(1),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FlexColumnWidth(2.5),
                3: const pw.FlexColumnWidth(2.5),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blue50),
                  children: [
                    _buildCoachPDFTableCellNew(
                      'S.No',
                      isHeader: true,
                      fontSize: 9,
                    ),
                    _buildCoachPDFTableCellNew(
                      'Name',
                      isHeader: true,
                      fontSize: 9,
                    ),
                    _buildCoachPDFTableCellNew(
                      'Designation',
                      isHeader: true,
                      fontSize: 9,
                    ),
                    _buildCoachPDFTableCellNew(
                      'Remark',
                      isHeader: true,
                      fontSize: 9,
                    ),
                  ],
                ),
                ...form.manpower.asMap().entries.map((entry) {
                  final i = entry.key + 1;
                  final m = entry.value;
                  return pw.TableRow(
                    children: [
                      _buildCoachPDFTableCellNew('$i', fontSize: 8),
                      _buildCoachPDFTableCellNew(m.name, fontSize: 8),
                      _buildCoachPDFTableCellNew(m.designation, fontSize: 8),
                      _buildCoachPDFTableCellNew(m.remark, fontSize: 8),
                    ],
                  );
                }).toList(),
              ],
            ),
            pw.SizedBox(height: 8),



            // Signature Section
            pw.Container(
              padding: const pw.EdgeInsets.all(6),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
              ),
              child: pw.Column(
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Signed By: ${form.signature.name}',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                      pw.Text(
                        'Date: ${_formatDateForPDF(form.signature.date)}',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Approved By: ${form.submittedTo.railwayEmployeeName}',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                      pw.Text(
                        'Date: ${form.formDateTime != null ? DateFormat('dd/MM/yyyy').format(DateTime.parse(form.formDateTime)) : 'N/A'}',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if ((form.rejectionComments ?? '').trim().isNotEmpty) ...[
              pw.SizedBox(height: 8),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.red50,
                  border: pw.Border.all(color: PdfColors.red700, width: 1.5),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Rejection Details',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.red900,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Rejected By: ${form.submittedTo.railwayEmployeeName}',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                        pw.Text(
                          'Date: ${form.rejectAt != null ? DateFormat('dd/MM/yyyy HH:mm').format(form.rejectAt!) : '2025-12-19'}',
                          style: const pw.TextStyle(fontSize: 9),
                        ),

                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Rejection Comment: ${form.rejectionComments ?? ''}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
              ),
            ],

            if (form.resubmitSign != null) ...[
              pw.SizedBox(height: 8),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.orange50,
                  border: pw.Border.all(color: PdfColors.orange700, width: 1.5),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Resubmission Details',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.orange900,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Resubmitted By: ${form.resubmitSign!.name}',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                        pw.Text(
                          'Date: ${form.resubmittedAt != null ? DateFormat('dd/MM/yyyy HH:mm').format(form.resubmittedAt!) : 'NA'}',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ],
                    ),
                    if ((form.contractorRemarks ?? '').trim().isNotEmpty) ...[
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Contractor Remarks: ${form.contractorRemarks ?? ''}',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            pw.SizedBox(height: 15),
            pw.Divider(thickness: 1, color: PdfColors.orange),
            pw.SizedBox(height: 4),
            pw.Center(
              child: pw.Text(
                'Generated on ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())} | Indian Railways - Swachh Bharat Mission',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey600,
                ),
              ),
            ),
          ],
        ),
      );

      if (form.hasScoringDetails()) {
        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(24),
            header: buildHeader,
            build: (context) => [
              _buildPDFScorecardSection(),
              pw.SizedBox(height: 15),

              pw.Container(
                padding: const pw.EdgeInsets.all(6),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Scored By: ${form.submittedTo.railwayEmployeeName}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text(
                      'Date: ${form.ratedAt?.toFormattedString() ?? 'N/A'}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 15),
              pw.Divider(thickness: 1, color: PdfColors.orange),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text(
                  'Generated on ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())} | Indian Railways - Swachh Bharat Mission',
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey600,
                  ),
                ),
              ),
            ],
          ),
        );
      }



      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/Coach_Form_${form.uid}.pdf');
      await file.writeAsBytes(await pdf.save());
      await OpenFilex.open(file.path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF saved: ${file.path}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  pw.Widget _buildPDFScorecardSection() {
    final ratingDetails = widget.form.ratingDetails!;
    final summary = ratingDetails.summary;

    Map<String, int> wateringSummary = {'Yes': 0, 'No': 0, 'NA': 0};
    Map<String, int> doorLockingSummary = {'Yes': 0, 'No': 0, 'NA': 0};
    Map<String, int> toiletriesSummary = {'Yes': 0, 'No': 0, 'NA': 0};

    for (var coach in ratingDetails.coachEvaluationTable) {
      wateringSummary[coach.watering] = (wateringSummary[coach.watering] ?? 0) + 1;
      doorLockingSummary[coach.doorsLocking] = (doorLockingSummary[coach.doorsLocking] ?? 0) + 1;
      toiletriesSummary[coach.toiletries] = (toiletriesSummary[coach.toiletries] ?? 0) + 1;
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(6),
          decoration: pw.BoxDecoration(
            color: PdfColors.blue50,
            border: pw.Border.all(color: PdfColors.blue700),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildCompactPDFRow('Work Type', ratingDetails.workType),
              _buildCompactPDFRow('ACWP Status', ratingDetails.acwpStatus),
            ],
          ),
        ),
        pw.SizedBox(height: 6),

        pw.Text(
          'Coach Evaluation',
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue900,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.blue50),
              children: [
                _buildPDFTableCell('Coach', isHeader: true),
                _buildPDFTableCell('Internal', isHeader: true),
                _buildPDFTableCell('External', isHeader: true),
                _buildPDFTableCell('Intensive', isHeader: true),
                _buildPDFTableCell('Watering', isHeader: true),
                _buildPDFTableCell('Door Lock', isHeader: true),
                _buildPDFTableCell('Toiletries', isHeader: true),
              ],
            ),
            ...ratingDetails.coachEvaluationTable.map((coach) {
              return pw.TableRow(
                children: [
                  _buildPDFTableCell(coach.coachNumber),
                  _buildPDFTableCell(coach.internalCleaning),
                  _buildPDFTableCell(coach.externalCleaning),
                  _buildPDFTableCell(coach.intensiveCleaning),
                  _buildPDFTableCell(coach.watering),
                  _buildPDFTableCell(coach.doorsLocking),
                  _buildPDFTableCell(coach.toiletries),
                ],
              );
            }).toList(),
          ],
        ),
        pw.SizedBox(height: 8),

        pw.Container(
          padding: const pw.EdgeInsets.all(6),
          decoration: pw.BoxDecoration(
            color: PdfColors.green50,
            border: pw.Border.all(color: PdfColors.green700),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Summary',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
              pw.SizedBox(height: 4),
              _buildCompactPDFRow('Total Coaches', '${summary.totalCoaches}'),
              pw.Divider(thickness: 0.5, color: PdfColors.green700),
              pw.SizedBox(height: 3),
              pw.Text(
                'Internal Cleaning Grades:',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey700,
                ),
              ),
              _buildPDFGradeRow(summary.internal),
              pw.SizedBox(height: 3),
              pw.Text(
                'External Cleaning Grades:',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey700,
                ),
              ),
              _buildPDFGradeRow(summary.external),
              pw.SizedBox(height: 3),
              pw.Text(
                'Intensive Cleaning Grades:',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey700,
                ),
              ),
              _buildPDFGradeRow(summary.intensive),
              pw.SizedBox(height: 3),
              pw.Text(
                'Watering:',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey700,
                ),
              ),
              _buildPDFYesNoNARow(wateringSummary),
              pw.SizedBox(height: 3),
              pw.Text(
                'Door Locking:',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey700,
                ),
              ),
              _buildPDFYesNoNARow(doorLockingSummary),
              pw.SizedBox(height: 3),
              pw.Text(
                'Toiletries:',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey700,
                ),
              ),
              _buildPDFYesNoNARow(toiletriesSummary),
            ],
          ),
        ),

        // if (widget.form.railwayRemarks != null) ...[
        //   pw.SizedBox(height: 15),
        //   pw.Container(
        //     padding: const pw.EdgeInsets.all(10),
        //     decoration: pw.BoxDecoration(
        //       color: PdfColors.amber50,
        //       border: pw.Border.all(color: PdfColors.amber700),
        //       borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        //     ),
        //     child: pw.Column(
        //       crossAxisAlignment: pw.CrossAxisAlignment.start,
        //       children: [
        //         pw.Text(
        //           'Railway Remarks',
        //           style: pw.TextStyle(
        //             fontSize: 12,
        //             fontWeight: pw.FontWeight.bold,
        //             color: PdfColors.blue900,
        //           ),
        //         ),
        //         pw.SizedBox(height: 6),
        //         pw.Text(
        //           widget.form.railwayRemarks!,
        //           style: const pw.TextStyle(fontSize: 10, color: PdfColors.black),
        //         ),
        //       ],
        //     ),
        //   ),
        // ],
      ],
    );
  }

  pw.Widget _buildPDFYesNoNARow(Map<String, int> counts) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(left: 10, top: 4),
      child: pw.Row(
        children: [
          pw.Text(
            'Yes: ${counts['Yes'] ?? 0}  ',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.Text(
            'No: ${counts['No'] ?? 0}  ',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.Text(
            'NA: ${counts['NA'] ?? 0}',
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  pw.TableRow _buildCoachPDFTableRow(
    String label1,
    String value1,
    String label2,
    String value2,
  ) {
    return pw.TableRow(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(
            label1,
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(value1, style: const pw.TextStyle(fontSize: 9)),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(
            label2,
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(value2, style: const pw.TextStyle(fontSize: 9)),
        ),
      ],
    );
  }

  pw.Widget _buildCoachPDFTableCellNew(
    String text, {
    bool isHeader = false,
    double fontSize = 9,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.blue900 : PdfColors.black,
        ),
      ),
    );
  }

  pw.Widget _buildPDFRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              textAlign: pw.TextAlign.right,
              style: const pw.TextStyle(fontSize: 11, color: PdfColors.black),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCompactPDFRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              textAlign: pw.TextAlign.right,
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.black),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPDFTableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 8 : 7,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.blue900 : PdfColors.black,
        ),
      ),
    );
  }

  pw.Widget _buildPDFGradeRow(Map<String, int> grades) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(left: 10, top: 4),
      child: pw.Row(
        children: [
          pw.Text(
            'A: ${grades['A'] ?? 0}  ',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.Text(
            'B: ${grades['B'] ?? 0}  ',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.Text(
            'C: ${grades['C'] ?? 0}  ',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.Text(
            'D: ${grades['D'] ?? 0}',
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }
}
