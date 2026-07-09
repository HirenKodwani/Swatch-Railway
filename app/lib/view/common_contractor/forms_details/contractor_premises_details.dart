import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:http/http.dart' as http;
import '../../../model/premises_form_model.dart';

class ContractorPremisesFormDetails extends StatefulWidget {
  final FormData model;

  const ContractorPremisesFormDetails({
    super.key,
    required this.model,
  });

  @override
  State<ContractorPremisesFormDetails> createState() =>
      _ContractorPremisesFormDetailsState();
}

class _ContractorPremisesFormDetailsState
    extends State<ContractorPremisesFormDetails>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool hasScorecard = false;

  @override
  void initState() {
    super.initState();
    hasScorecard = widget.model.ratingDetails != null;
    _tabController = TabController(
      length: hasScorecard ? 2 : 1,
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
          'Premises Form Details',
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
          if (widget.model.status.toLowerCase() == 'locked')
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
                  if (hasScorecard)
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
                            child: const Icon(Icons.check_circle,
                                size: 16, color: Colors.green),
                          ),
                          const SizedBox(width: 6),
                          const Text('Scorecard'),
                        ],
                      ),
                    ),
                ],
              ),
              if (hasScorecard)
                Container(
                  height: 2,
                  color: Colors.green.withOpacity(0.3),
                ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFormDetailsTab(),
          if (hasScorecard) _buildScorecardTab(),
        ],
      ),
    );
  }

  Widget _buildFormDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _buildPremisesDetailsCard(),
          const SizedBox(height: 16),
          _buildSubmittedToCard(),
          const SizedBox(height: 16),
          _buildManpowerCard(),
          const SizedBox(height: 16),
          _buildWorkTimingCard(),
          const SizedBox(height: 16),
          _buildSignatureCard(),
          if ((widget.model.contractorRemarks ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildContractorRemarksCard(),
          ],

          const SizedBox(height: 16),


          if ((widget.model.rejectionComments ?? '').trim().isNotEmpty)
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
                      const Icon(Icons.cancel_outlined, color: Colors.white, size: 20),
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
                  infoRow('Rejected By:', widget.model.submittedTo.railwayEmployeeName),
                  infoRow('Rejected Date:', widget.model.rejectAt != null
                      ? DateFormat('dd/MM/yyyy HH:mm').format(widget.model.rejectAt!)
                      : 'N/A'),
                  infoRow('Rejected Comment:', widget.model.rejectionComments ?? ''),
                ],
              ),

            ),


          if (hasScorecard) ...[
            const SizedBox(height: 16),
            _buildScorecardStatusBanner(),
          ],
          const SizedBox(height: 16),




    //       if ((widget.model.rejectionComments ?? '').trim().isNotEmpty)
    //       ElevatedButton(
    //           style: ElevatedButton.styleFrom(
    //             minimumSize: Size(double.infinity, 45)
    // ),
    //           onPressed: (){}, child: Text('RE-SUBMIT'))
        ],
      ),
    );
  }

  Widget _buildPremisesDetailsCard() {
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
                'Premises Details',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xffe9edff),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.model.status,
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
          _infoRow('Location:', widget.model.location),
          const SizedBox(height: 8),
          _infoRow('Total Area Cleaned:', '${widget.model.area.toString()} sq. meter'),
          if(widget.model.submittedByDepot != null && widget.model.submittedByDepot!.trim().isNotEmpty)
          const SizedBox(height: 8),
          if(widget.model.submittedByDepot != null && widget.model.submittedByDepot!.trim().isNotEmpty)
          _infoRow('Depot:', widget.model.submittedByDepot!.trim()),
          const SizedBox(height: 8),
          _infoRow('Zone:', widget.model.submittedByZone),
          const SizedBox(height: 8),
          _infoRow('Division:', widget.model.submittedByDivision),
          const SizedBox(height: 8),
          _infoRow('Form ID:', widget.model.uid),
      const SizedBox(height: 8),
          _infoRow('Contractor Supervisor:', widget.model.submittedByName),
          const SizedBox(height: 8),
          _infoRow('Contractor Company:', widget.model.submittedByEntityName),
          const SizedBox(height: 8),
          _infoRow(
            'Submitted Date:',
            DateFormat('dd/MM/yyyy HH:mm').format(widget.model.formDateTime.toLocal()),
          ),
        ],
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
          _infoRow('Employee Name:', widget.model.submittedTo.railwayEmployeeName),
          const SizedBox(height: 8),
          _infoRow('Division:', widget.model.submittedTo.division),
          if(widget.model.submittedTo.depot != null && widget.model.submittedTo.depot!.trim().isNotEmpty)
          const SizedBox(height: 8),
          if(widget.model.submittedTo.depot != null && widget.model.submittedTo.depot!.trim().isNotEmpty)
          _infoRow('Depot:', widget.model.submittedTo.depot!.trim()),
        ],
      ),
    );
  }

  Widget _buildManpowerCard() {
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
                'Manpower (${widget.model.manpower.length})',
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
                    child: Text('S.No',
                        style: TextStyle(fontWeight: FontWeight.w600))),
                Expanded(
                    flex: 3,
                    child: Text('Name',
                        style: TextStyle(fontWeight: FontWeight.w600))),
                Expanded(
                    flex: 3,
                    child: Text('Designation',
                        style: TextStyle(fontWeight: FontWeight.w600))),
                Expanded(
                    flex: 3,
                    child: Text('Remark',
                        style: TextStyle(fontWeight: FontWeight.w600))),

              ],
            ),
          ),
          const Divider(height: 1, color: Colors.grey),
          ...widget.model.manpower.asMap().entries.map((entry) {
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
                      child: Text(e.designation,
                          style: const TextStyle(color: Colors.deepOrange))),
                  Expanded(
                      flex: 3,
                      child: Text(e.remark,
                          style: const TextStyle(color: Colors.deepOrange))),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildWorkTimingCard() {
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
              const Icon(Icons.schedule, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Work Timing',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _infoRow('Time Started:', widget.model.timeWorkStarted ?? 'N/A'),
          const SizedBox(height: 8),
          _infoRow('Time Completed:', widget.model.timeWorkCompleted ?? 'N/A'),
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
                  const Icon(Icons.edit_document, color: Colors.deepOrange, size: 20),
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
              _infoRow('Signature By:', widget.model.signature.name),
              const SizedBox(height: 8),
              _infoRow('Date:', _formatSignatureDate(widget.model.signature.date)),
              if (widget.model.railwaySignature != null) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                _infoRow('Approved By:', widget.model.railwaySignature!.name),
                const SizedBox(height: 8),
                _infoRow('Approval Date:', _formatSignatureDate(widget.model.railwaySignature!.date)),
              ],
            ],
          ),
        ),
        if (widget.model.resubmitSign != null) ...[
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
                    const Icon(Icons.edit_document, color: Colors.deepOrange, size: 20),
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
                  widget.model.resubmitSign!.name,
                ),
                const SizedBox(height: 8),
                _infoRow('Date:', _formatSignatureDate(widget.model.resubmitSign!.date)),
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
            widget.model.contractorRemarks ?? '',
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

  Widget _buildScorecardStatusBanner() {
    return GestureDetector(
      onTap: () {
        if (hasScorecard) {
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
              child: const Icon(Icons.check_circle,
                  color: Colors.white, size: 20),
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
                    'Tap to view scorecard details',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildScorecardTab() {
    final rating = widget.model.ratingDetails!;
    final summary = rating.summary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _buildScorecardHeader(summary),
          const SizedBox(height: 16),
          _buildScoreTable('HOUSEKEEPING OF DEPOT PREMISES',
              rating.housekeepingItems, Colors.blue),
          const SizedBox(height: 12),
          _buildScoreTable('PIT-LINE CLEANING WORK', rating.pitLineItems,
              Colors.orange),
          const SizedBox(height: 12),
          _buildScoreTable('DISPOSAL OF GARBAGE AS PER MUNICIPAL NORM',
              rating.disposalItems, Colors.purple),
          const SizedBox(height: 20),
          _buildSummarySection(summary),
          if (widget.model.railwayRemarks != null) ...[
            const SizedBox(height: 16),
            _buildRemarksCard(),
          ],
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildScorecardHeader(ScorecardSummary summary) {
    return Container(
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
                    'Premises Cleaning Scorecard',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Overall Score: ${summary.overallAverage.toStringAsFixed(2)}/100',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreTable(
      String title, List<ScoreItem> items, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black12.withOpacity(0.05), blurRadius: 6)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: color,
            ),
          ),
          const SizedBox(height: 12),
           Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: color.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(
                    color.withOpacity(0.1)),
                border: TableBorder(
                  horizontalInside:
                  BorderSide(color: Colors.grey.shade300, width: 0.5),
                  verticalInside:
                  BorderSide(color: Colors.grey.shade300, width: 0.5),
                ),
                columnSpacing: 6,
                dataRowHeight: 48,
                headingRowHeight: 42,
                columns: [
                  DataColumn(
                    label: SizedBox(
                      width: 20,
                      child: Center(
                        child: Text('Sr',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: color,
                            )),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: SizedBox(
                      width: 55,
                      child: Text('Item',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: color,
                          )),
                    ),
                  ),
                  DataColumn(
                    label: SizedBox(
                      width: 42,
                      child: Center(
                        child: Text('S1',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: color,
                            )),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: SizedBox(
                      width: 42,
                      child: Center(
                        child: Text('S2',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: color,
                            )),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: SizedBox(
                      width: 45,
                      child: Center(
                        child: Text('Avg',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: color,
                            )),
                      ),
                    ),
                  ),
                ],
                rows: List.generate(
                  items.length,
                      (index) {
                    final item = items[index];
                    return DataRow(
                      color: MaterialStateProperty.all(
                        index % 2 == 0
                            ? Colors.grey.shade50
                            : Colors.white,
                      ),
                      cells: [
                        DataCell(
                          Center(
                            child: Text(
                              '${item.sr}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            item.itemDescription,
                            style: const TextStyle(fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DataCell(
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 4),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${item.score1}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: color,
                                ),
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 4),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${item.score2}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: color,
                                ),
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 4),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item.avg.toStringAsFixed(1),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: color,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(ScorecardSummary summary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12.withOpacity(0.04), blurRadius: 6)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Summary',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const Divider(),
          _summaryRow(
            'Housekeeping Average',
            summary.housekeepingAvg ,
            Colors.blue,
          ),
          const SizedBox(height: 8),
          _summaryRow('Pit-Line Average', summary.pitLineAvg, Colors.orange),
          const SizedBox(height: 8),
          _summaryRow(
            'Garbage Disposal Average',
            summary.disposalAvg,
            Colors.purple,
          ),
          const Divider(height: 20),
          _summaryRow(
            'Overall Average',
            summary.overallAverage,
            Colors.green,
            isOverall: true,
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double value, Color color,
      {bool isOverall = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isOverall ? FontWeight.w700 : FontWeight.w600,
            fontSize: isOverall ? 15 : 14,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${value.toStringAsFixed(2)}%',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRemarksCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12.withOpacity(0.04), blurRadius: 6)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.comment, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Remarks',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.model.railwayRemarks ?? '',
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ],
      ),
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
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ],
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

  String _formatSignatureDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateStr;
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
    final model = widget.model;

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generating PDF...')),
      );

      final pdf = pw.Document();

      pw.MemoryImage? indianRailwayLogo;
      pw.MemoryImage? swachhBharatLogo;
      pw.MemoryImage? pisolveLogo;

      try {
        final irBytes = await rootBundle.load('assets/images/indian_railway.png');
        indianRailwayLogo = pw.MemoryImage(irBytes.buffer.asUint8List());

        final sbBytes = await rootBundle.load('assets/images/swachh_bharat.png');
        swachhBharatLogo = pw.MemoryImage(sbBytes.buffer.asUint8List());

        final pisolveBytes = await rootBundle.load('assets/images/mirtha.jpg');
        pisolveLogo = pw.MemoryImage(pisolveBytes.buffer.asUint8List());
      } catch (e) {
        print('Error loading logos: $e');
      }

      pw.Widget buildHeader(pw.Context context) {
        return pw.Column(
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                if (indianRailwayLogo != null)
                  pw.Container(width: 45, height: 45, child: pw.Image(indianRailwayLogo, fit: pw.BoxFit.contain))
                else
                  pw.SizedBox(width: 45),

                if (swachhBharatLogo != null)
                  pw.Container(width: 45, height: 45, child: pw.Image(swachhBharatLogo, fit: pw.BoxFit.contain))
                else
                  pw.SizedBox(width: 45),

                if (pisolveLogo != null)
                  pw.Container(width: 45, height: 45, child: pw.Image(pisolveLogo, fit: pw.BoxFit.contain))
                else
                  pw.SizedBox(width: 45),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Center(
              child: pw.Text('PREMISES CLEANING FORM',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
            ),
            pw.SizedBox(height: 4),
            pw.Center(
              child: pw.Text(
                'Zone: ${model.submittedByZone}, Division: ${model.submittedByDivision}${(model.submittedByDepot != null && model.submittedByDepot!.trim().isNotEmpty) ? ', Depot: ${model.submittedByDepot}' : ''}',
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.red900),
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.blue700, width: 1.5),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Text('Form ID - ${model.uid}',
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
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
                _buildPDFTableRow('Location', model.location, 'Submitted Date:', DateFormat('dd/MM/yyyy HH:mm').format(model.formDateTime)),
                _buildPDFTableRow('Total Area Cleaned', '${model.area} sq. meters', 'Company:', model.submittedByEntityName),
                _buildPDFTableRow('Area Not Cleaned', '0 sq. meters', 'Submitted By', model.submittedByName),
                _buildPDFTableRow('Status', model.status, 'Submitted to', model.submittedTo.railwayEmployeeName),
                _buildPDFTableRow('Time Started', model.timeWorkStarted  ?? 'N/A', 'Time Completed', model.timeWorkCompleted ?? 'N/A'),
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
                    _buildPDFTableCellNew('S.No', isHeader: true, fontSize: 9),
                    _buildPDFTableCellNew('Name', isHeader: true, fontSize: 9),
                    _buildPDFTableCellNew('Designation', isHeader: true, fontSize: 9),
                    _buildPDFTableCellNew('Remark', isHeader: true, fontSize: 9),
                  ],
                ),
                ...model.manpower.asMap().entries.map((entry) {
                  final i = entry.key + 1;
                  final m = entry.value;
                  return pw.TableRow(
                    children: [
                      _buildPDFTableCellNew('$i', fontSize: 8),
                      _buildPDFTableCellNew(m.name, fontSize: 8),
                      _buildPDFTableCellNew(m.designation, fontSize: 8),
                      _buildPDFTableCellNew(m.remark, fontSize: 8),
                    ],
                  );
                }).toList(),
              ],
            ),
            pw.SizedBox(height: 8),

            pw.Container(
              padding: const pw.EdgeInsets.all(6),
              decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
              child: pw.Column(
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Signed By: ${(model.resubmitSign ?? model.signature).name}', style: const pw.TextStyle(fontSize: 9)),
                      pw.Text('Date: ${_formatSignatureDate((model.resubmitSign ?? model.signature).date)}', style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Approved By: ${model.submittedTo.railwayEmployeeName}', style: const pw.TextStyle(fontSize: 9)),
                      pw.Text('Date: ${DateFormat('dd/MM/yyyy').format(model.formDateTime)}', style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                ],
              ),
            ),


            if ((model.rejectionComments ?? '').trim().isNotEmpty) ...[
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
                          'Rejected By: ${model.submittedTo.railwayEmployeeName}',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                        pw.Text(
                          'Date: ${model.rejectAt != null ? DateFormat('dd/MM/yyyy HH:mm').format(model.rejectAt!) : 'N/A'}',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Rejection Comment: ${model.rejectionComments ?? ''}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
              ),
            ],

            if (model.resubmitSign != null) ...[
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
                          'Resubmitted By: ${model.resubmitSign!.name}',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                        pw.Text(
                          'Date: ${model.resubmittedAt != null ? DateFormat('dd/MM/yyyy HH:mm').format(model.resubmittedAt!) : 'N/A'}',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ],
                    ),
                    if ((model.contractorRemarks ?? '').trim().isNotEmpty) ...[
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Contractor Remarks: ${model.contractorRemarks ?? ''}',
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
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
            ),
          ],
        ),
      );



      if (model.ratingDetails != null) {
        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(24),
            header: buildHeader,
            build: (context) => [
              _buildPDFScorecardSectionNew(model),
              pw.SizedBox(height: 15),

              pw.Container(
                padding: const pw.EdgeInsets.all(6),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Scored By: ${model.submittedTo.railwayEmployeeName}', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text('Date: ${DateFormat('dd/MM/yyyy HH:mm').format(model.formDateTime)}', style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
              ),

              pw.SizedBox(height: 15),
              pw.Divider(thickness: 1, color: PdfColors.orange),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text(
                  'Generated on ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())} | Indian Railways - Swachh Bharat Mission',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                ),
              ),
            ],
          ),
        );
      }

      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/Premises_Form_${model.uid}.pdf');
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

  pw.TableRow _buildPDFTableRow(String label1, String value1, String label2, String value2) {
    return pw.TableRow(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(label1, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(value1, style: const pw.TextStyle(fontSize: 9)),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(label2, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(value2, style: const pw.TextStyle(fontSize: 9)),
        ),
      ],
    );
  }

  pw.Widget _buildPDFTableCellNew(String text, {bool isHeader = false, double fontSize = 9}) {
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

  pw.Widget _buildPDFScorecardSectionNew(FormData model) {
    final rating = model.ratingDetails!;
    final summary = rating.summary;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'SCORECARD DETAILS',
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue900,
          ),
        ),
        pw.SizedBox(height: 6),

        _buildCompactScoreTable('HOUSEKEEPING', rating.housekeepingItems, PdfColors.white),
        pw.SizedBox(height: 6),
        _buildCompactScoreTable('PIT-LINE CLEANING', rating.pitLineItems, PdfColors.white),
        pw.SizedBox(height: 6),
        _buildCompactScoreTable('GARBAGE DISPOSAL', rating.disposalItems, PdfColors.white),
        pw.SizedBox(height: 8),

        pw.Container(
          padding: const pw.EdgeInsets.all(6),
          decoration: pw.BoxDecoration(
            color: PdfColors.green50,
            border: pw.Border.all(color: PdfColors.green700),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _summaryItem('Housekeeping', summary.housekeepingAvg),
              _summaryItem('Pit-Line', summary.pitLineAvg),
              _summaryItem('Disposal', summary.disposalAvg),
              _summaryItem('Overall', summary.overallAverage, isOverall: true),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildCompactScoreTable(String title, List<ScoreItem> items, PdfColor color) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: color)),
        pw.SizedBox(height: 2),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(0.8),
            1: const pw.FlexColumnWidth(4),
            2: const pw.FlexColumnWidth(1),
            3: const pw.FlexColumnWidth(1),
            4: const pw.FlexColumnWidth(1),
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: color),
              children: [
                _buildPDFTableCellNew('Sr', isHeader: true, fontSize: 7),
                _buildPDFTableCellNew('Item', isHeader: true, fontSize: 7),
                _buildPDFTableCellNew('S1', isHeader: true, fontSize: 7),
                _buildPDFTableCellNew('S2', isHeader: true, fontSize: 7),
                _buildPDFTableCellNew('Avg', isHeader: true, fontSize: 7),
              ],
            ),
            ...items.map((item) {
              return pw.TableRow(
                children: [
                  _buildPDFTableCellNew('${item.sr}', fontSize: 7),
                  _buildPDFTableCellNew(item.itemDescription, fontSize: 7),
                  _buildPDFTableCellNew('${item.score1}', fontSize: 7),
                  _buildPDFTableCellNew('${item.score2}', fontSize: 7),
                  _buildPDFTableCellNew(item.avg.toStringAsFixed(1), fontSize: 7),
                ],
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  pw.Widget _summaryItem(String label, double value, {bool isOverall = false}) {
    return pw.Column(
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 8, fontWeight: isOverall ? pw.FontWeight.bold : pw.FontWeight.normal)),
        pw.Text('${value.toStringAsFixed(1)}%', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: isOverall ? PdfColors.green900 : PdfColors.black)),
      ],
    );
  }
}