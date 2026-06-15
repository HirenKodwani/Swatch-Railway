import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

class PDFReportService {
  static const PdfColor primaryColor = PdfColor.fromInt(0xff1f4e78);
  static const PdfColor successColor = PdfColor.fromInt(0xff28a745);
  static const PdfColor warningColor = PdfColor.fromInt(0xffffc107);
  static const PdfColor accentColor = PdfColor.fromInt(0xff9966cc);
  static const PdfColor lightBg = PdfColor.fromInt(0xfff8f9fa);
  static const PdfColor borderColor = PdfColor.fromInt(0xffdee2e6);

  static Future<pw.ImageProvider> _getLogo() async {
    final ByteData bytes = await rootBundle.load('assets/images/image.png');
    final Uint8List byteList = bytes.buffer.asUint8List();
    return pw.MemoryImage(byteList);
  }

  static pw.Widget _buildHeader(pw.ImageProvider logo, String title, String status) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: primaryColor, width: 2),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Row(
            children: [
              pw.Image(logo, width: 50, height: 50),
              pw.SizedBox(width: 15),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(title, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                  pw.Text('Indian Railways - OBHS Enterprise Monitoring System', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                ],
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: pw.BoxDecoration(
                  color: status == 'COMPLIANT' || status == 'RESOLVED' ? successColor : warningColor,
                  borderRadius: pw.BorderRadius.circular(20),
                ),
                child: pw.Text(status, style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10)),
              ),
              pw.SizedBox(height: 5),
              pw.Text('Generated: ${DateFormat('dd-MMM-yyyy | hh:mm a').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
            ],
          )
        ],
      ),
    );
  }

  static pw.Widget _buildSectionHeader(String title, {PdfColor color = primaryColor}) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      margin: const pw.EdgeInsets.only(top: 15, bottom: 8),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(title, style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 12)),
    );
  }

  static pw.Widget _buildInfoRow(String label1, String value1, String label2, String value2) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        children: [
          pw.Expanded(child: pw.Text(label1, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: primaryColor))),
          pw.Text(':', style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(width: 5),
          pw.Expanded(child: pw.Text(value1, style: const pw.TextStyle(fontSize: 10))),
          pw.SizedBox(width: 20),
          pw.Expanded(child: pw.Text(label2, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: primaryColor))),
          pw.Text(':', style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(width: 5),
          pw.Expanded(child: pw.Text(value2, style: const pw.TextStyle(fontSize: 10))),
        ],
      ),
    );
  }

  static pw.Widget _buildSignatures() {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 30),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: primaryColor),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(6),
            color: primaryColor,
            child: pw.Text('APPROVAL & AUTHENTICATION', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10)),
          ),
          pw.SizedBox(height: 40),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              pw.Column(children: [
                pw.Container(width: 100, height: 1, color: PdfColors.grey),
                pw.SizedBox(height: 5),
                pw.Text('Supervisor', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                pw.Text('System Validated', style: const pw.TextStyle(fontSize: 8)),
              ]),
              pw.Column(children: [
                pw.Container(width: 100, height: 1, color: PdfColors.grey),
                pw.SizedBox(height: 5),
                pw.Text('Audit Verified By', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                pw.Text('OBHS Monitoring System', style: const pw.TextStyle(fontSize: 8)),
              ]),
              pw.Column(children: [
                pw.Container(width: 100, height: 1, color: PdfColors.grey),
                pw.SizedBox(height: 5),
                pw.Text('Report Approved By', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                pw.Text('Divisional Operations Manager', style: const pw.TextStyle(fontSize: 8)),
              ]),
            ]
          )
        ]
      )
    );
  }

  // 1. Worker Activity Report
  static Future<Uint8List> generateWorkerActivityReportPdf(List<dynamic> runs, List<dynamic> tasks) async {
    final pdf = pw.Document();
    final logo = await _getLogo();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (pw.Context context) {
          return [
            _buildHeader(logo, 'OBHS WORKER ACTIVITY & EVIDENCE AUDIT REPORT', 'COMPLIANT'),
            
            _buildSectionHeader('1. REPORT OVERVIEW'),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(border: pw.Border.all(color: borderColor), borderRadius: pw.BorderRadius.circular(4)),
              child: pw.Column(
                children: [
                  _buildInfoRow('Total Runs Covered', '${runs.length}', 'Total Tasks Executed', '${tasks.length}'),
                  _buildInfoRow('Date Range', DateFormat('dd-MMM-yyyy').format(DateTime.now()), 'Report Type', 'Activity Audit'),
                ],
              ),
            ),

            _buildSectionHeader('2. TASK EXECUTION & EVIDENCE DETAILS'),
            pw.TableHelper.fromTextArray(
              context: context,
              headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9),
              headerDecoration: const pw.BoxDecoration(color: primaryColor),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellAlignment: pw.Alignment.center,
              data: <List<String>>[
                ['Task ID', 'Coach', 'Category', 'Status', 'Worker Comment', 'Completion Time'],
                ...tasks.map((task) {
                  return [
                    task['taskId']?.toString().substring(0, 8) ?? 'N/A',
                    task['coachId']?.toString() ?? 'N/A',
                    task['taskName']?.toString() ?? 'N/A',
                    task['status']?.toString() ?? 'N/A',
                    task['workerComment']?.toString() ?? '-',
                    task['completedAt'] != null ? DateFormat('hh:mm a').format(DateTime.parse(task['completedAt'])) : 'N/A',
                  ];
                }),
              ],
            ),
            
            _buildSignatures(),
          ];
        },
      ),
    );

    return pdf.save();
  }

  // 2. Complaint Report
  static Future<Uint8List> generateComplaintReportPdf(List<dynamic> runs, List<dynamic> complaints) async {
    final pdf = pw.Document();
    final logo = await _getLogo();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (pw.Context context) {
          return [
            _buildHeader(logo, 'OBHS PETTY ISSUE & COMPLAINT REPORT', 'IN PROGRESS'),
            
            _buildSectionHeader('1. KPI SUMMARY', color: accentColor),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(border: pw.Border.all(color: borderColor), borderRadius: pw.BorderRadius.circular(4)),
              child: pw.Column(
                children: [
                  _buildInfoRow('Total Complaints Raised', '${complaints.length}', 'Open Issues', '${complaints.where((c) => c['status'] != 'RESOLVED').length}'),
                  _buildInfoRow('Resolved Issues', '${complaints.where((c) => c['status'] == 'RESOLVED').length}', 'SLA Compliance Status', 'Within SLA'),
                ],
              ),
            ),

            _buildSectionHeader('2. RESOLUTION TRACKING'),
            pw.TableHelper.fromTextArray(
              context: context,
              headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9),
              headerDecoration: const pw.BoxDecoration(color: primaryColor),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellAlignment: pw.Alignment.center,
              data: <List<String>>[
                ['Complaint ID', 'Train', 'Coach', 'Category', 'Description', 'Status'],
                ...complaints.map((c) {
                  return [
                    c['complaintId']?.toString().substring(0, 8) ?? 'N/A',
                    c['trainNo']?.toString() ?? 'N/A',
                    c['coachNo']?.toString() ?? 'N/A',
                    c['category']?.toString() ?? 'N/A',
                    c['description']?.toString() ?? 'N/A',
                    c['status']?.toString() ?? 'N/A',
                  ];
                }),
              ],
            ),
            
            _buildSignatures(),
          ];
        },
      ),
    );

    return pdf.save();
  }

  // 3. Train Report
  static Future<Uint8List> generateTrainReportPdf(List<dynamic> runs) async {
    final pdf = pw.Document();
    final logo = await _getLogo();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (pw.Context context) {
          return [
            _buildHeader(logo, 'OBHS TRAIN RUN EXECUTION REPORT', 'COMPLETED'),
            _buildSectionHeader('1. RUN INSTANCES SUMMARY'),
            pw.TableHelper.fromTextArray(
              context: context,
              headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9),
              headerDecoration: const pw.BoxDecoration(color: primaryColor),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellAlignment: pw.Alignment.center,
              data: <List<String>>[
                ['Run ID', 'Train No', 'Date', 'Status', 'Total Coaches'],
                ...runs.map((r) {
                  return [
                    (r['runInstanceId'] ?? r['instanceId'] ?? 'N/A').toString().substring(0, 10),
                    r['trainNo']?.toString() ?? 'N/A',
                    r['departureDate']?.toString() ?? 'N/A',
                    r['status']?.toString() ?? 'N/A',
                    r['coaches'] != null ? (r['coaches'] as List).length.toString() : '0',
                  ];
                }),
              ],
            ),
            _buildSignatures(),
          ];
        },
      ),
    );
    return pdf.save();
  }

  // 4. Attendance Report
  static Future<Uint8List> generateAttendanceReportPdf(List<dynamic> runs, List<dynamic> attendance) async {
    final pdf = pw.Document();
    final logo = await _getLogo();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (pw.Context context) {
          return [
            _buildHeader(logo, 'OBHS STAFF ATTENDANCE REPORT', 'VERIFIED'),
            _buildSectionHeader('1. ATTENDANCE LOG'),
            pw.TableHelper.fromTextArray(
              context: context,
              headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9),
              headerDecoration: const pw.BoxDecoration(color: primaryColor),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellAlignment: pw.Alignment.center,
              data: <List<String>>[
                ['Worker ID', 'Name', 'Role', 'Status', 'Time'],
                ...attendance.map((a) {
                  return [
                    a['workerId']?.toString() ?? 'N/A',
                    a['workerName']?.toString() ?? 'N/A',
                    a['role']?.toString() ?? 'N/A',
                    a['status']?.toString() ?? 'N/A',
                    a['timestamp'] != null ? DateFormat('dd-MMM hh:mm a').format(DateTime.parse(a['timestamp'])) : 'N/A',
                  ];
                }),
              ],
            ),
            _buildSignatures(),
          ];
        },
      ),
    );
    return pdf.save();
  }
}
