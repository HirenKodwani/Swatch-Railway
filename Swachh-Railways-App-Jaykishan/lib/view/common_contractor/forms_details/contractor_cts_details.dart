import 'package:crm_train/utills/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../model/cts_form_model.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ContractorCTSFormDetails extends StatefulWidget {
  final CTSForm form;

  const ContractorCTSFormDetails({
    super.key,
    required this.form,
  });

  @override
  State<ContractorCTSFormDetails> createState() => _ContractorCTSFormDetailsState();
}

class _ContractorCTSFormDetailsState extends State<ContractorCTSFormDetails>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isAccepting = false;

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
          'CTS Form Details',
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
          if (widget.form.status?.toLowerCase() == 'locked' ||
              widget.form.status?.toLowerCase() == 'auto-approved')
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
                labelColor: kRailwayBlue,
                unselectedLabelColor: Colors.black54,
                indicatorColor: kRailwayBlue,
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

  Future<void> _downloadPDF() async {
    final form = widget.form;

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
                'CTS FORM',
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
                'Zone: ${form.submittedByZone ?? 'N/A'}, Division: ${form.submittedByDivision ?? 'N/A'}${(form.submittedByDepot != null && form.submittedByDepot!.isNotEmpty) ? ', Depot: ${form.submittedByDepot}' : ''}',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.red900,
                ),
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
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
                _buildPDFTableRow('Train', '${form.trainNumber} - ${form.trainName}',
                    'Submitted Date:', _formatDateTime(form.formDateTime)),
                _buildPDFTableRow('Station', form.station,
                    'Platform:', form.platform),
                _buildPDFTableRow('Job Date', _formatDate(form.jobDate),
                    'Company:', form.contractorName ?? 'N/A'),
                _buildPDFTableRow('Coaches In Rake', form.coachesInRake.toString(),
                    'Coaches Attended:', form.coachesAttended.toString()),
                _buildPDFTableRow('Act Arrival', _formatDateTime(form.actArrival),
                    'Act Departure:', _formatDateTime(form.actDeparture)),
                _buildPDFTableRow('Work Start', _formatDateTime(form.workStart),
                    'Work End:', _formatDateTime(form.workEnd)),
                _buildPDFTableRow('Allowed Window', form.allowedWindow.toString(),
                    'Late (Y/N):', form.lateYN.toString()),
                _buildPDFTableRow('Occupied Toilets', form.occupiedToilets.toString(),
                    'Status:', form.status ?? 'PENDING'),
                _buildPDFTableRow('Garbage Disposed', form.garbageDisposed ? 'Yes' : 'No',
                    'Nominated Location:', form.nominatedLocation),
                _buildPDFTableRow('Submitted By', form.submittedByName ?? 'N/A',
                    'Submitted To:', form.submittedTo.railwayEmployeeName ?? 'N/A'),
              ],
            ),
            pw.SizedBox(height: 10),

            // pw.Container(
            //   padding: const pw.EdgeInsets.all(8),
            //   decoration: pw.BoxDecoration(
            //     color: PdfColors.blue50,
            //     border: pw.Border.all(color: PdfColors.blue700),
            //     borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            //   ),
            //   child: pw.Column(
            //     crossAxisAlignment: pw.CrossAxisAlignment.start,
            //     children: [
            //       pw.Text(
            //         'Timing Details',
            //         style: pw.TextStyle(
            //           fontSize: 10,
            //           fontWeight: pw.FontWeight.bold,
            //           color: PdfColors.blue900,
            //         ),
            //       ),
            //       pw.SizedBox(height: 6),
            //       _buildCompactPDFRow('Act Arrival', _formatDateTime(form.actArrival)),
            //       _buildCompactPDFRow('Act Departure', _formatDateTime(form.actDeparture)),
            //       _buildCompactPDFRow('Work Start', _formatDateTime(form.workStart)),
            //       _buildCompactPDFRow('Work End', _formatDateTime(form.workEnd)),
            //       _buildCompactPDFRow('Allowed Window', form.allowedWindow),
            //       _buildCompactPDFRow('Late (Y/N)', form.lateYN),
            //     ],
            //   ),
            // ),
            // pw.SizedBox(height: 10),

            pw.Text(
              'Attendance Staff Details',
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
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(2),
                4: const pw.FlexColumnWidth(2.5),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blue50),
                  children: [
                    _buildPDFTableCell('S.No', isHeader: true, fontSize: 9),
                    _buildPDFTableCell('Name', isHeader: true, fontSize: 9),
                    _buildPDFTableCell('Staff ID', isHeader: true, fontSize: 9),
                    _buildPDFTableCell('Role', isHeader: true, fontSize: 9),
                    _buildPDFTableCell('Remark', isHeader: true, fontSize: 9),
                  ],
                ),
                ...form.attendanceStaff.asMap().entries.map((entry) {
                  final i = entry.key + 1;
                  final staff = entry.value;
                  return pw.TableRow(
                    children: [
                      _buildPDFTableCell('$i', fontSize: 8),
                      _buildPDFTableCell(staff.name, fontSize: 8),
                      _buildPDFTableCell(staff.staffId, fontSize: 8),
                      _buildPDFTableCell(staff.role, fontSize: 8),
                      _buildPDFTableCell(staff.remarks, fontSize: 8),
                    ],
                  );
                }).toList(),
              ],
            ),
            pw.SizedBox(height: 10),

            // pw.Container(
            //   padding: const pw.EdgeInsets.all(8),
            //   decoration: pw.BoxDecoration(
            //     color: PdfColors.green50,
            //     border: pw.Border.all(color: PdfColors.green700),
            //     borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            //   ),
            //   child: pw.Column(
            //     crossAxisAlignment: pw.CrossAxisAlignment.start,
            //     children: [
            //       pw.Text(
            //         'Garbage Details',
            //         style: pw.TextStyle(
            //           fontSize: 10,
            //           fontWeight: pw.FontWeight.bold,
            //           color: PdfColors.blue900,
            //         ),
            //       ),
            //       pw.SizedBox(height: 6),
            //       _buildCompactPDFRow('Garbage Disposed', form.garbageDisposed ? 'Yes' : 'No'),
            //       _buildCompactPDFRow('Nominated Location', form.nominatedLocation),
            //       if (form.notes.isNotEmpty)
            //         _buildCompactPDFRow('Notes', form.notes),
            //     ],
            //   ),
            // ),
            // pw.SizedBox(height: 8),

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
                        'Date: ${_formatDateForDisplay(form.signature.date)}',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Approved By: ${form.submittedTo.railwayEmployeeName ?? 'N/A'}',
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
                          'Rejected By: ${form.submittedTo.railwayEmployeeName ?? 'N/A'}',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                        pw.Text(
                          'Date: ${form.rejectAt != null ? DateFormat('dd/MM/yyyy HH:mm').format(form.rejectAt!) : 'N/A'}',
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
                'Generated on ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())} | Indian Railways - CTS Service',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
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
                      'Scored By: ${form.submittedTo.railwayEmployeeName ?? 'N/A'}',
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
                  'Generated on ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())} | Indian Railways - CTS Service',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                ),
              ),
            ],
          ),
        );
      }

      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/CTS_Form_${form.uid}.pdf');
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
    final inspectionHeader = ratingDetails.inspectionHeader;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [

        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey800, width: 1),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(3),
            2: const pw.FlexColumnWidth(2),
            3: const pw.FlexColumnWidth(3),
          },
          children: [
            _buildPDFTableRow('Inspector Type', inspectionHeader.inspectorType,
                'Total Coaches:', _formatDateTime(inspectionHeader.totalCoaches.toString())),
            _buildPDFTableRow('Coaches Attended', inspectionHeader.coachesAttended.toString(),
                'Sampling %:', inspectionHeader.samplingPercentage.toString()),
          ],
        ),


        // pw.Container(
        //   padding: const pw.EdgeInsets.all(6),
        //   decoration: pw.BoxDecoration(
        //     color: PdfColors.blue50,
        //     border: pw.Border.all(color: PdfColors.blue700),
        //     borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        //   ),
        //   child: pw.Column(
        //     crossAxisAlignment: pw.CrossAxisAlignment.start,
        //     children: [
        //       _buildCompactPDFRow('Inspector Type', inspectionHeader.inspectorType),
        //       _buildCompactPDFRow('Total Coaches', '${inspectionHeader.totalCoaches}'),
        //       _buildCompactPDFRow('Coaches Attended', '${inspectionHeader.coachesAttended}'),
        //       _buildCompactPDFRow('Sampling %', '${inspectionHeader.samplingPercentage}%'),
        //     ],
        //   ),
        // ),
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
                _buildPDFTableCell('Position', isHeader: true),
                _buildPDFTableCell('Coach No', isHeader: true),
                _buildPDFTableCell('Jet Clean', isHeader: true),
                _buildPDFTableCell('Basin Clean', isHeader: true),
                _buildPDFTableCell('Disposal', isHeader: true),
                _buildPDFTableCell('Total', isHeader: true),
                _buildPDFTableCell('Grade', isHeader: true),
              ],
            ),
            ...ratingDetails.coachEvaluationTable.map((coach) {
              return pw.TableRow(
                children: [
                  _buildPDFTableCell(coach.coachPosition),
                  _buildPDFTableCell(coach.coachNo),
                  _buildPDFTableCell('${coach.jetCleaningScore}'),
                  _buildPDFTableCell('${coach.basinCleaningScore}'),
                  _buildPDFTableCell('${coach.disposalScore}'),
                  _buildPDFTableCell('${coach.totalScore}'),
                  _buildPDFTableCell(coach.grade),
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
              _buildCompactPDFRow('Average Score', '${summary.averageScore.toStringAsFixed(1)}'),
              _buildCompactPDFRow('Overall Grade', summary.overallGrade),
            ],
          ),
        ),

        if (ratingDetails.machinesUsed.isNotEmpty) ...[
          pw.SizedBox(height: 8),
          pw.Text(
            'Machines Used:',
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),

          ..._buildMachineRows(ratingDetails.machinesUsed),
        ],





        if (ratingDetails.chemicals.isNotEmpty) ...[
          pw.SizedBox(height: 8),
          pw.Text(
            'Chemicals Used:',
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.blue50),
                children: [
                  _buildPDFTableCell('Chemical Type', isHeader: true),
                  _buildPDFTableCell('Brand', isHeader: true),
                  _buildPDFTableCell('Quantity (Liter)', isHeader: true),
                ],
              ),
              ...ratingDetails.chemicals.map((chemical) {
                return pw.TableRow(
                  children: [
                    _buildPDFTableCell(chemical.name),
                    _buildPDFTableCell(chemical.brand),
                    _buildPDFTableCell(chemical.quantity),
                  ],
                );
              }),
            ],
          ),
        ],
      ],
    );
  }


  List<pw.Widget> _buildMachineRows(List<String> machines) {
    const int columns = 3;

    List<pw.Widget> rows = [];

    for (int i = 0; i < machines.length; i += columns) {
      final rowItems = machines.skip(i).take(columns).toList();

      rows.add(
        pw.Row(
          children: List.generate(columns, (index) {
            if (index < rowItems.length) {
              return pw.Expanded(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.only(right: 4, bottom: 4),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        width: 3,
                        height: 3,
                        margin: const pw.EdgeInsets.only(top: 3, right: 4),
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.black,
                          shape: pw.BoxShape.circle,
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          rowItems[index],
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            } else {
              return pw.Expanded(child: pw.SizedBox());
            }
          }),
        ),
      );
    }

    return rows;
  }


  pw.TableRow _buildPDFTableRow(String label1, String value1, String label2, String value2) {
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

  pw.Widget _buildPDFTableCell(String text, {bool isHeader = false, double fontSize = 7}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 8 : fontSize,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.blue900 : PdfColors.black,
        ),
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
          _buildStaffCard(),
          const SizedBox(height: 16),
          _buildGarbageCard(),
          const SizedBox(height: 16),
          _buildSignatureCard(),
          const SizedBox(height: 16),
          if ((widget.form.contractorRemarks ?? '')
              .trim()
              .isNotEmpty) ...[
            _buildContractorRemarksCard(),
            const SizedBox(height: 16),
          ],
          if ((widget.form.rejectionComments ?? '')
              .trim()
              .isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
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
                  _infoRowWhite(
                    'Rejected By:',
                    widget.form.submittedTo.railwayEmployeeName ?? 'N/A',
                  ),
                  _infoRowWhite(
                    'Rejected Date:',
                    widget.form.rejectAt != null
                        ? DateFormat('dd-MM-yyyy HH:mm').format(
                        widget.form.rejectAt!)
                        : 'N/A',
                  ),
                  _infoRowWhite(
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
                'CTS Form\nDetails',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xffe9edff),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.form.status ?? 'PENDING',
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
          _infoRow('Train:',
              '${widget.form.trainNumber} - ${widget.form.trainName}'),
          const SizedBox(height: 8),
          _infoRow('Station:', widget.form.station),
          const SizedBox(height: 8),
          _infoRow('Platform:', widget.form.platform),
          const SizedBox(height: 8),
          _infoRow('Job Date:', _formatDate(widget.form.jobDate)),
          const SizedBox(height: 8),
          _infoRow('Coaches In Rake:', widget.form.coachesInRake.toString()),
          const SizedBox(height: 8),
          _infoRow('Coaches Attended:', widget.form.coachesAttended.toString()),
          const SizedBox(height: 8),
          _infoRow('Occupied Toilets:', widget.form.occupiedToilets.toString()),
          const SizedBox(height: 8),
          _infoRow('Zone:', widget.form.submittedByZone ?? 'N/A'),
          const SizedBox(height: 8),
          _infoRow('Division:', widget.form.submittedByDivision ?? 'N/A'),
          if (widget.form.submittedByDepot != null &&
              widget.form.submittedByDepot!.isNotEmpty)
            const SizedBox(height: 8),
          if (widget.form.submittedByDepot != null &&
              widget.form.submittedByDepot!.isNotEmpty)
            _infoRow('Depot:', widget.form.submittedByDepot!),
          const SizedBox(height: 8),
          _infoRow('Form ID:', widget.form.uid),
          const SizedBox(height: 8),
          _infoRow(
              'Contractor Supervisor:', widget.form.submittedByName ?? 'N/A'),
          const SizedBox(height: 8),
          _infoRow('Contractor Company:', widget.form.contractorName ?? 'N/A'),
          const SizedBox(height: 8),
          _infoRow(
              'Submitted Date:', _formatDateTime(widget.form.formDateTime)),
          const SizedBox(height: 8),
          _infoRow('Act Arrival:', _formatDateTime(widget.form.actArrival)),
          const SizedBox(height: 8),
          _infoRow('Act Departure:', _formatDateTime(widget.form.actDeparture)),
          const SizedBox(height: 8),
          _infoRow('Work Start:', _formatDateTime(widget.form.workStart)),
          const SizedBox(height: 8),
          _infoRow('Work End:', _formatDateTime(widget.form.workEnd)),
          const SizedBox(height: 8),
          _infoRow('Allowed Window:', widget.form.allowedWindow),
          const SizedBox(height: 8),
          _infoRow('Late (Y/N):', widget.form.lateYN),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd-MM-yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString).toLocal();
      return DateFormat('dd-MM-yyyy HH:mm').format(dateTime);
    } catch (e) {
      return dateTimeString;
    }
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
            widget.form.submittedTo.railwayEmployeeName ?? 'N/A',
          ),
          const SizedBox(height: 8),
          _infoRow('Division:', widget.form.submittedTo.division ?? 'N/A'),
          const SizedBox(height: 8),
          if (widget.form.submittedTo.depot != null)
            _infoRow('Depot:', widget.form.submittedTo.depot ?? ''),
        ],
      ),
    );
  }

  Widget _buildStaffCard() {
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
              const Icon(Icons.group, color: kRailwayBlue, size: 20),
              const SizedBox(width: 8),
              Text(
                'Attendance Staff (${widget.form.attendanceStaff.length})',
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
                    'Staff ID',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Role',
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
          ...widget.form.attendanceStaff
              .asMap()
              .entries
              .map((entry) {
            final i = entry.key + 1;
            final staff = entry.value;
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.black12)),
              ),
              child: Row(
                children: [
                  Expanded(flex: 2, child: Text('$i')),
                  Expanded(flex: 3, child: Text(staff.name)),
                  Expanded(flex: 3, child: Text(staff.staffId)),
                  Expanded(
                    flex: 2,
                    child: Text(
                      staff.role,
                      style: const TextStyle(color: Colors.deepOrange),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      staff.remarks,
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

  Widget _buildGarbageCard() {
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
              const Icon(Icons.delete_outline, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Garbage Details',
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
              'Garbage Disposed:', widget.form.garbageDisposed ? 'Yes' : 'No'),
          const SizedBox(height: 8),
          _infoRow('Nominated Location:', widget.form.nominatedLocation),
          const SizedBox(height: 8),
          if (widget.form.notes.isNotEmpty)
            _infoRow('Notes:', widget.form.notes),
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
              _infoRow('Signature By:', widget.form.signature.name),
              const SizedBox(height: 8),
              _infoRow(
                  'Date:', _formatDateForDisplay(widget.form.signature.date)),
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
                _infoRow('Resubmitted By:', widget.form.resubmitSign!.name),
                const SizedBox(height: 8),
                _infoRow('Date:',
                    _formatDateForDisplay(widget.form.resubmitSign!.date)),
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
              const Icon(Icons.comment, color: kRailwayBlue, size: 20),
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
                    'Scored on ${widget.form.ratedAt?.toFormattedString() ??
                        'N/A'}',
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
    final inspectionHeader = ratingDetails.inspectionHeader;

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xff4059ed), Color(0xff5a70ff)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: kRailwayBlue.withOpacity(0.3),
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
                        'by ${widget.form.submittedTo.railwayEmployeeName ??
                            'N/A'}',
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
              _infoRowWhite('Inspector Type:', inspectionHeader.inspectorType),
              const SizedBox(height: 6),
              _infoRowWhite(
                  'Total Coaches:', '${inspectionHeader.totalCoaches}'),
              const SizedBox(height: 6),
              _infoRowWhite(
                  'Coaches Attended:', '${inspectionHeader.coachesAttended}'),
              const SizedBox(height: 6),
              _infoRowWhite(
                  'Sampling %:', '${inspectionHeader.samplingPercentage}%'),
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
                  const Color(0xffe9edff)),
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
                    'Position',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Coach No',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Jet Clean',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Basin Clean',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Disposal',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Total',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Grade',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Remarks',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
                  ),
                ),
              ],
              rows: List.generate(
                  ratingDetails.coachEvaluationTable.length, (index) {
                final coach = ratingDetails.coachEvaluationTable[index];
                return DataRow(
                  color: MaterialStateProperty.all(
                    index % 2 == 0 ? Colors.grey.shade50 : Colors.white,
                  ),
                  cells: [
                    DataCell(
                      Text(
                        coach.coachPosition,
                        style: const TextStyle(fontWeight: FontWeight.w600,
                            fontSize: 12),
                      ),
                    ),
                    DataCell(
                      Text(
                        coach.coachNo,
                        style: const TextStyle(fontWeight: FontWeight.w600,
                            fontSize: 12),
                      ),
                    ),
                    DataCell(_buildScoreCell(coach.jetCleaningScore)),
                    DataCell(_buildScoreCell(coach.basinCleaningScore)),
                    DataCell(_buildScoreCell(coach.disposalScore)),
                    DataCell(_buildScoreCell(coach.totalScore)),
                    DataCell(_buildGradeCell(coach.grade)),
                    DataCell(
                      Text(
                        coach.remarks.isEmpty ? 'N/A' : coach.remarks,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
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
                  _statBox('Average Score',
                      '${summary.averageScore.toStringAsFixed(1)}',
                      kRailwayBlue),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Overall Grade',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            summary.overallGrade,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        if (ratingDetails.machinesUsed.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 16),
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
                  'Machines Used',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                ...ratingDetails.machinesUsed
                    .asMap()
                    .entries
                    .map((entry) {
                  final i = entry.key + 1;
                  final machine = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$i. ',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            machine,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

        if (ratingDetails.chemicals.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 16),
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
                  'Chemicals Used',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(
                        const Color(0xffe9edff)),
                    border: TableBorder.all(color: Colors.grey.shade300),
                    columnSpacing: 16,
                    columns: const [
                      DataColumn(
                        label: Text(
                          'Chemical Type',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 11),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Brand',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 11),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Quantity (Liter)',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 11),
                        ),
                      ),
                    ],
                    rows: ratingDetails.chemicals.map((chemical) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              chemical.name,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          DataCell(
                            Text(
                              chemical.brand,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          DataCell(
                            Center(
                              child: Text(
                                chemical.quantity,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildScoreCell(int score) {
    Color color = score >= 8 ? Colors.green : (score >= 5
        ? Colors.orange
        : Colors.red);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color),
      ),
      child: Text(
        score.toString(),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: color,
        ),
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

  Widget _infoRowWhite(String label, String value) {
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

  Color _getGradeColor(String grade) {
    switch (grade.toUpperCase()) {
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

  String _formatDateForDisplay(String dateStr) {
    try {
      DateTime date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

}