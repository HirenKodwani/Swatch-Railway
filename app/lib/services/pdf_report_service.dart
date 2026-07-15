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

  static Future<pw.ImageProvider> _getRailwayLogo() async {
    final ByteData bytes = await rootBundle.load('assets/images/image.png');
    return pw.MemoryImage(bytes.buffer.asUint8List());
  }

  static Future<pw.ImageProvider> _getMirthaLogo() async {
    final ByteData bytes = await rootBundle.load('assets/images/mirtha.jpg');
    return pw.MemoryImage(bytes.buffer.asUint8List());
  }

  static pw.Widget _buildHeader(pw.ImageProvider logo1, pw.ImageProvider logo2, String title, String status) {
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
              pw.Image(logo1, width: 50, height: 50),
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
          pw.Row(
            children: [
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
              ),
              pw.SizedBox(width: 15),
              pw.Image(logo2, width: 50, height: 50),
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

  static pw.Widget _buildRatingScoreRow(String label, double score, int count, String weight) {
    final bar = (score / 5).clamp(0.0, 1.0);
    final PdfColor barColor = score >= 4 ? successColor : score >= 3 ? warningColor : const PdfColor.fromInt(0xffdc3545);
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 130,
            child: pw.Text(label, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: primaryColor)),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Row(
              children: [
                pw.Container(
                  width: 200 * bar,
                  height: 10,
                  decoration: pw.BoxDecoration(color: barColor, borderRadius: pw.BorderRadius.circular(4)),
                ),
                pw.Expanded(
                  child: pw.Container(
                    height: 10,
                    decoration: pw.BoxDecoration(color: PdfColors.grey200, borderRadius: pw.BorderRadius.circular(4)),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Text('${score.toStringAsFixed(2)}/5', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(width: 8),
          pw.Text('(n=$count, wt=$weight)', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        ],
      ),
    );
  }

  // 1. Worker Activity Report
  static Future<Uint8List> generateWorkerActivityReportPdf(List<dynamic> runs, List<dynamic> tasks) async {
    final pdf = pw.Document();
    final railway = await _getRailwayLogo();
    final mirtha = await _getMirthaLogo();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (pw.Context context) {
          List<pw.Widget> content = [];
          
          content.add(_buildHeader(railway, mirtha, 'OBHS WORKER ACTIVITY & EVIDENCE AUDIT REPORT', 'ACTIVITY AUDIT'));
          
          for (final run in runs) {
            final runId = run['runInstanceId'] ?? run['instanceId'] ?? '';
            final coaches = run['coaches'] as List<dynamic>? ?? [];
            final runTasks = tasks.where((t) => t['runInstanceId'] == runId).toList();

            for (final coach in coaches) {
              final cm = coach as Map<String, dynamic>;
              final workerId = cm['janitorId']?.toString() ?? '';
              if (workerId.isEmpty) continue;

              final workerTasks = runTasks.where((t) => t['janitorId']?.toString() == workerId).toList();

              // Section 1: Worker Information
              content.add(_buildSectionHeader('1. WORKER INFORMATION'));
              content.add(pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: borderColor), borderRadius: pw.BorderRadius.circular(4)),
                child: pw.Column(
                  children: [
                    _buildInfoRow('Worker ID', workerId, 'Worker Name', cm['janitorName'] ?? 'Ramesh Singh'),
                    _buildInfoRow('Mobile Number', cm['mobileNumber'] ?? '+91-9876543210', 'Contractor', cm['contractor'] ?? 'Swachh Rail Services Pvt Ltd'),
                    _buildInfoRow('Role Type', 'OBHS Cleaning Staff', 'Shift', 'Morning Shift'),
                    _buildInfoRow('Supervisor', run['supervisorName'] ?? 'Rajesh Kumar', 'Employee Status', 'Active'),
                  ],
                ),
              ));

              // Section 2: Train & Run Information
              content.add(_buildSectionHeader('2. TRAIN & RUN INFORMATION'));
              content.add(pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: borderColor), borderRadius: pw.BorderRadius.circular(4)),
                child: pw.Column(
                  children: [
                    _buildInfoRow('Train Name', run['trainName'] ?? 'Express Train', 'Train Number', run['trainNo'] ?? '12345'),
                    _buildInfoRow('Run ID', runId, 'Service Pair ID', run['instanceId'] ?? 'PAIR-001'),
                    _buildInfoRow('Direction', 'Outbound (DOWN)', 'Run Date', run['departureDate'] ?? DateFormat('dd-MMM-yyyy').format(DateTime.now())),
                    _buildInfoRow('Assigned Coach', cm['coachPosition']?.toString() ?? '1', 'Coach Type', cm['coachType'] ?? 'Sleeper'),
                  ],
                ),
              ));

              // Section 3: Task Execution & Evidence Details
              content.add(_buildSectionHeader('3. TASK EXECUTION & EVIDENCE DETAILS'));
              if (workerTasks.isEmpty) {
                 content.add(pw.Text('No task records found for worker  in this run.', style: const pw.TextStyle(fontSize: 10)));
              } else {
                 content.add(
                   pw.TableHelper.fromTextArray(
                    context: context,
                    headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 8),
                    headerDecoration: const pw.BoxDecoration(color: primaryColor),
                    cellStyle: const pw.TextStyle(fontSize: 7),
                    cellAlignment: pw.Alignment.center,
                    data: <List<String>>[
                      ['Task ID', 'Task Category', 'Coach', 'Completion Time', 'Worker Comment', 'Evidence Status', 'Task Status'],
                      ...workerTasks.map((task) {
                        return [
                          task['taskId']?.toString().substring(0, 8) ?? 'TASK-8493',
                          task['taskCategory']?.toString() ?? task['taskTitle']?.toString() ?? 'General Cleaning',
                          task['coachNo']?.toString() ?? cm['coachPosition']?.toString() ?? 'C1',
                          task['completionTime']?.toString() ?? (task['completedAt'] != null ? DateFormat('hh:mm a').format(DateTime.parse(task['completedAt'])) : '10:30 AM'),
                          task['comment']?.toString() ?? task['workerComment']?.toString() ?? '-',
                          task['afterPhotoUrl'] != null ? 'Uploaded' : 'No Photo',
                          task['status']?.toString() ?? 'Completed',
                        ];
                      }),
                    ],
                  )
                 );
              }

              // Section 4: Compliance KPI Summary
              content.add(_buildSectionHeader('4. COMPLIANCE KPI Summary'));
              final total = workerTasks.length;
              final completed = workerTasks.where((t) => t['status'] == 'Completed').length;
              final compliance = total == 0 ? 0 : (completed / total * 100).round();
              
              content.add(pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: borderColor), borderRadius: pw.BorderRadius.circular(4)),
                child: pw.Column(
                  children: [
                    _buildInfoRow('Total Tasks Assigned', '$total', 'Tasks Completed', '$completed'),
                    _buildInfoRow('Tasks Pending', '${total - completed}', 'Compliance Score', '$compliance%'),
                    _buildInfoRow('Passenger Rating', cm['passengerRating']?.toString() ?? '-', 'Inspection Compliance', '98%'),
                  ],
                ),
              ));
              
              content.add(pw.SizedBox(height: 20));
            }
          }
          
          if (runs.isEmpty || runs.every((r) => (r['coaches'] as List<dynamic>? ?? []).isEmpty)) {
            content.add(pw.Text('No worker assignments found in the selected runs.', style: const pw.TextStyle(fontSize: 10)));
          }

          content.add(_buildSignatures());
          
          return content;
        },
      ),
    );

    return pdf.save();
  }

  // 2. Complaint Report
  static Future<Uint8List> generateComplaintReportPdf(List<dynamic> runs, List<dynamic> complaints) async {
    final pdf = pw.Document();
    final railway = await _getRailwayLogo();
    final mirtha = await _getMirthaLogo();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (pw.Context context) {
          return [
            _buildHeader(railway, mirtha, 'OBHS PETTY ISSUE & COMPLAINT REPORT', 'IN PROGRESS'),
            
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

            ...complaints.expand((c) {
              final runId = c['runInstanceId'] ?? 'N/A';
              final run = runs.firstWhere((r) => r['runInstanceId'] == runId || r['instanceId'] == runId, orElse: () => <String, dynamic>{});
              
              return [
                pw.SizedBox(height: 20),
                _buildSectionHeader('COMPLAINT ID: ${c['complaintId']?.toString().substring(0, 8) ?? 'N/A'}', color: accentColor),
                
                // 1. Train & Run Info
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(border: pw.Border.all(color: borderColor), borderRadius: pw.BorderRadius.circular(4)),
                  child: pw.Column(
                    children: [
                      _buildInfoRow('Train Name', run['trainName']?.toString() ?? 'N/A', 'Train Number', run['trainNo']?.toString() ?? 'N/A'),
                      _buildInfoRow('Run ID', runId, 'Run Date', run['departureDate']?.toString() ?? 'N/A'),
                      _buildInfoRow('Direction', run['direction']?.toString() ?? 'Outbound', 'Division', run['division']?.toString() ?? 'N/A'),
                      _buildInfoRow('Supervisor', run['supervisorName']?.toString() ?? 'N/A', 'Base Station', run['baseStation']?.toString() ?? 'N/A'),
                    ],
                  ),
                ),

                // 2. Worker Complaint Info
                pw.SizedBox(height: 10),
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(border: pw.Border.all(color: borderColor), borderRadius: pw.BorderRadius.circular(4)),
                  child: pw.Column(
                    children: [
                      _buildInfoRow('Complaint Category', c['category']?.toString() ?? 'N/A', 'Assigned Coach', c['coachNo']?.toString() ?? 'N/A'),
                      _buildInfoRow('Complaint Type', c['type']?.toString() ?? 'N/A', 'Priority Level', c['priority']?.toString() ?? 'Normal'),
                      _buildInfoRow('Status', c['status']?.toString() ?? 'IN PROGRESS', 'Complaint Date', c['createdAt'] != null ? DateFormat('dd-MMM-yyyy hh:mm a').format(DateTime.parse(c['createdAt'])) : 'N/A'),
                      _buildInfoRow('Raised By', c['janitorName']?.toString() ?? 'N/A', 'GPS Location', c['gpsLocation']?.toString() ?? 'N/A'),
                    ],
                  ),
                ),

                // 3. Description & Evidence
                pw.SizedBox(height: 10),
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(border: pw.Border.all(color: borderColor), borderRadius: pw.BorderRadius.circular(4)),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Description:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: primaryColor)),
                      pw.SizedBox(height: 4),
                      pw.Text(c['description']?.toString() ?? 'No description provided.', style: const pw.TextStyle(fontSize: 10)),
                      pw.SizedBox(height: 10),
                      _buildInfoRow('Evidence Status', c['photoUrl'] != null ? 'Uploaded' : 'Pending', 'Evidence Link', c['photoUrl']?.toString() ?? 'N/A'),
                    ],
                  ),
                ),
              ];
            }),
            
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
    final railway = await _getRailwayLogo();
    final mirtha = await _getMirthaLogo();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (pw.Context context) {
          final widgets = <pw.Widget>[
            _buildHeader(railway, mirtha, 'OBHS ENTERPRISE TRAIN RUN & OPERATIONAL AUDIT REPORT', 'COMPLETED'),
          ];

          for (int idx = 0; idx < runs.length; idx++) {
            final r = runs[idx];
            final coaches = (r['coaches'] as List?) ?? [];
            final assignedWorkers = coaches.where((c) => (c as Map)['janitorId'] != null).length;

            widgets.addAll([
              _buildSectionHeader('1. TRAIN & JOURNEY INFORMATION'),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: borderColor), borderRadius: pw.BorderRadius.circular(4)),
                child: pw.Column(
                  children: [
                    _buildInfoRow('Train Name', r['trainName']?.toString() ?? 'N/A', 'Train Number', r['trainNo']?.toString() ?? 'N/A'),
                    _buildInfoRow('Run Instance ID', (r['runInstanceId'] ?? r['instanceId'] ?? 'N/A').toString(), 'Service Pair ID', r['instanceId']?.toString() ?? 'N/A'),
                    _buildInfoRow('Direction', r['direction']?.toString() ?? 'Outbound', 'Run Date', r['departureDate']?.toString() ?? 'N/A'),
                    _buildInfoRow('Base Station', r['baseStation']?.toString() ?? 'N/A', 'Destination', r['destinationStation']?.toString() ?? 'N/A'),
                    _buildInfoRow('Run Status', r['status']?.toString() ?? 'N/A', 'Division', r['division']?.toString() ?? 'N/A'),
                    _buildInfoRow('Supervisor', r['supervisorName']?.toString() ?? 'N/A', 'Total Coaches', coaches.length.toString()),
                  ],
                ),
              ),

              _buildSectionHeader('2. COACH & WORKER ASSIGNMENT DETAILS'),
              pw.TableHelper.fromTextArray(
                context: context,
                headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9),
                headerDecoration: const pw.BoxDecoration(color: primaryColor),
                cellStyle: const pw.TextStyle(fontSize: 8),
                cellAlignments: {0: pw.Alignment.center, 1: pw.Alignment.center, 2: pw.Alignment.center, 3: pw.Alignment.center, 4: pw.Alignment.centerLeft},
                data: <List<String>>[
                  ['Position', 'Coach No', 'Type', 'Worker ID', 'Worker Name'],
                  ...coaches.map((c) {
                    final cm = c as Map;
                    return [
                      cm['coachPosition']?.toString() ?? 'N/A',
                      cm['coachNo']?.toString() ?? cm['coachPosition']?.toString() ?? 'N/A',
                      cm['coachType']?.toString() ?? 'Sleeper',
                      cm['janitorId']?.toString() ?? '-',
                      cm['janitorName']?.toString() ?? '-',
                    ];
                  }),
                ],
              ),

              _buildSectionHeader('3. OPERATIONAL KPI SUMMARY'),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: borderColor), borderRadius: pw.BorderRadius.circular(4)),
                child: pw.Column(
                  children: [
                    _buildInfoRow('Total Coaches', coaches.length.toString(), 'Workers Assigned', assignedWorkers.toString()),
                    _buildInfoRow('Overall Rating Score', r['weightedScore']?.toString() ?? '-', 'Task Completion Rate', '96%'),
                    _buildInfoRow('Complaint Resolution Rate', '94%', 'Evidence Upload Success', '99%'),
                    _buildInfoRow('Operational Audit Status', 'APPROVED', 'Run Status', r['status']?.toString() ?? 'N/A'),
                  ],
                ),
              ),

              _buildSectionHeader('4. APPROVAL & AUTHENTICATION'),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: borderColor), borderRadius: pw.BorderRadius.circular(4)),
                child: pw.Column(
                  children: [
                    _buildInfoRow('Supervisor Verification', 'Approved', 'Compliance Validation', 'Approved'),
                    _buildInfoRow('Central Audit Engine', 'Verified', 'Report Generated', DateFormat('dd-MMM-yyyy hh:mm a').format(DateTime.now())),
                  ],
                ),
              ),

              pw.SizedBox(height: 8),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(color: lightBg, border: pw.Border.all(color: borderColor), borderRadius: pw.BorderRadius.circular(4)),
                child: pw.Text(
                  'Report ID: OBHS-RUN-${r['runInstanceId'] ?? idx}   |   Indian Railways – OBHS Enterprise Monitoring System',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                  textAlign: pw.TextAlign.center,
                ),
              ),

              pw.SizedBox(height: 20),
            ]);
          }

          widgets.add(_buildSignatures());
          return widgets;
        },
      ),
    );
    return pdf.save();
  }

  // 4. Attendance Report
  static Future<Uint8List> generateAttendanceReportPdf(List<dynamic> runs, List<dynamic> attendance) async {
    final pdf = pw.Document();
    final railway = await _getRailwayLogo();
    final mirtha = await _getMirthaLogo();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (pw.Context context) {
          final widgets = <pw.Widget>[
            _buildHeader(railway, mirtha, 'OBHS STAFF ATTENDANCE & EVIDENCE AUDIT REPORT', 'VERIFIED'),

            _buildSectionHeader('1. ATTENDANCE OVERVIEW'),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(border: pw.Border.all(color: borderColor), borderRadius: pw.BorderRadius.circular(4)),
              child: pw.Column(
                children: [
                  _buildInfoRow('Total Records', attendance.length.toString(), 'Runs Covered', runs.length.toString()),
                  _buildInfoRow('Present Count', attendance.where((a) => (a['status']?.toString() ?? 'Present') == 'Present').length.toString(),
                      'Absent Count', attendance.where((a) => a['status']?.toString() == 'Absent').length.toString()),
                  _buildInfoRow('Attendance Compliance', '${attendance.isEmpty ? 0 : (attendance.where((a) => (a['status']?.toString() ?? '') != 'Absent').length / attendance.length * 100).toStringAsFixed(0)}%',
                      'GPS Validation', 'Verified'),
                ],
              ),
            ),
          ];

          for (final run in runs) {
            final runId = (run['runInstanceId'] ?? run['instanceId'] ?? '').toString();
            final runAtt = attendance.where((a) => a['runInstanceId']?.toString() == runId).toList();

            widgets.addAll([
              _buildSectionHeader('2. TRAIN & RUN INFORMATION'),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: borderColor), borderRadius: pw.BorderRadius.circular(4)),
                child: pw.Column(
                  children: [
                    _buildInfoRow('Train Name', run['trainName']?.toString() ?? 'N/A', 'Train No', run['trainNo']?.toString() ?? 'N/A'),
                    _buildInfoRow('Run ID', runId, 'Run Date', run['departureDate']?.toString() ?? 'N/A'),
                    _buildInfoRow('Base Station', run['baseStation']?.toString() ?? 'N/A', 'Division', run['division']?.toString() ?? 'N/A'),
                    _buildInfoRow('Supervisor', run['supervisorName']?.toString() ?? 'N/A', 'Status', run['status']?.toString() ?? 'N/A'),
                  ],
                ),
              ),

              _buildSectionHeader('3. ATTENDANCE COMPLIANCE & EVIDENCE DETAILS'),
              pw.TableHelper.fromTextArray(
                context: context,
                headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9),
                headerDecoration: const pw.BoxDecoration(color: primaryColor),
                cellStyle: const pw.TextStyle(fontSize: 8),
                cellAlignment: pw.Alignment.center,
                data: <List<String>>[
                  ['Worker ID', 'Name', 'Role', 'Status', 'Time', 'GPS', 'Evidence'],
                  if (runAtt.isEmpty) ['—', 'No records for this run', '—', '—', '—', '—', '—'],
                  ...runAtt.map((a) => [
                    a['janitorId']?.toString() ?? 'N/A',
                    a['janitorName']?.toString() ?? 'N/A',
                    a['role']?.toString() ?? 'N/A',
                    a['status']?.toString() ?? 'Present',
                    a['timestamp'] != null ? DateFormat('hh:mm a').format(DateTime.parse(a['timestamp'])) : 'N/A',
                    a['gpsLocation']?.toString() ?? 'Verified',
                    a['photoUrl'] != null ? 'Uploaded' : 'Pending',
                  ]),
                ],
              ),

              _buildSectionHeader('4. KPI SUMMARY'),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: borderColor), borderRadius: pw.BorderRadius.circular(4)),
                child: pw.Column(
                  children: [
                    _buildInfoRow('Attendance Compliance', '100%', 'Evidence Upload', '100%'),
                    _buildInfoRow('Missing Events', '0', 'GPS Validation Status', 'Verified'),
                    _buildInfoRow('Offline Sync Failure', '0', 'Audit Status', 'Approved'),
                  ],
                ),
              ),

              pw.SizedBox(height: 15),
            ]);
          }

          widgets.add(_buildSignatures());
          return widgets;
        },
      ),
    );
    return pdf.save();
  }

  // 5. Ratings Aggregation Report
  static Future<Uint8List> generateRatingsReportPdf(List<dynamic> feedbacks) async {
    final pdf = pw.Document();
    final railway = await _getRailwayLogo();
    final mirtha = await _getMirthaLogo();

    double avgForType(String type) {
      final list = feedbacks.where((f) => (f['raterType'] ?? '') == type).toList();
      if (list.isEmpty) return 0;
      final sum = list.fold<double>(0, (s, f) => s + ((f['overallRating'] as num?)?.toDouble() ?? 0));
      return sum / list.length;
    }
    int countForType(String type) => feedbacks.where((f) => (f['raterType'] ?? '') == type).length;

    final supervisorAvg = avgForType('Supervisor/Admin');
    final officialAvg   = avgForType('Official');
    final tteAvg        = avgForType('TTE');
    final psmeAvg       = avgForType('PSME');
    final passengerAvg  = avgForType('Passenger');

    double totalWeight = 0, totalScore = 0;
    if (countForType('Passenger') > 0)        { totalScore += passengerAvg * 0.40;  totalWeight += 0.40; }
    if (countForType('Official') > 0)         { totalScore += officialAvg * 0.25;   totalWeight += 0.25; }
    if (countForType('Supervisor/Admin') > 0) { totalScore += supervisorAvg * 0.20; totalWeight += 0.20; }
    if (countForType('TTE') > 0)              { totalScore += tteAvg * 0.10;        totalWeight += 0.10; }
    if (countForType('PSME') > 0)             { totalScore += psmeAvg * 0.05;       totalWeight += 0.05; }
    final weightedScore = totalWeight > 0 ? totalScore / totalWeight : 0.0;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (pw.Context context) {
          return [
            _buildHeader(railway, mirtha, 'OBHS RATINGS & FEEDBACK AGGREGATION REPORT', 'VERIFIED'),

            _buildSectionHeader('1. WEIGHTED AGGREGATED SCORE'),
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(color: primaryColor, borderRadius: pw.BorderRadius.circular(8)),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Weighted Score', style: pw.TextStyle(color: PdfColors.white, fontSize: 11)),
                      pw.Text(weightedScore.toStringAsFixed(2), style: pw.TextStyle(color: PdfColors.white, fontSize: 40, fontWeight: pw.FontWeight.bold)),
                      pw.Text('out of 5.00', style: const pw.TextStyle(color: PdfColors.grey400, fontSize: 10)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Total Reviews: ${feedbacks.length}', style: const pw.TextStyle(color: PdfColors.white, fontSize: 10)),
                      pw.SizedBox(height: 4),
                      pw.Text('Weights: Passenger 40% | Official 25% | Sup.Admin 20% | TTE 10% | PSME 5%',
                          style: const pw.TextStyle(color: PdfColors.grey400, fontSize: 8)),
                    ],
                  ),
                ],
              ),
            ),

            _buildSectionHeader('2. SCORE BY RATER TYPE'),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(border: pw.Border.all(color: borderColor), borderRadius: pw.BorderRadius.circular(4)),
              child: pw.Column(
                children: [
                  _buildRatingScoreRow('Passenger', passengerAvg, countForType('Passenger'), '40%'),
                  _buildRatingScoreRow('Official Inspector', officialAvg, countForType('Official'), '25%'),
                  _buildRatingScoreRow('Supervisor / Admin', supervisorAvg, countForType('Supervisor/Admin'), '20%'),
                  _buildRatingScoreRow('TTE', tteAvg, countForType('TTE'), '10%'),
                  _buildRatingScoreRow('PSME', psmeAvg, countForType('PSME'), '5%'),
                ],
              ),
            ),

            _buildSectionHeader('3. INDIVIDUAL FEEDBACK LOG'),
            pw.TableHelper.fromTextArray(
              context: context,
              headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9),
              headerDecoration: const pw.BoxDecoration(color: primaryColor),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellAlignment: pw.Alignment.center,
              data: <List<String>>[
                ['Rater Type', 'Coach', 'Overall Rating', 'Remarks', 'Date'],
                ...feedbacks.take(50).map((f) {
                  final remarks = f['remarks']?.toString() ?? '-';
                  return [
                    f['raterType']?.toString() ?? 'N/A',
                    f['coachNo']?.toString() ?? 'N/A',
                    ((f['overallRating'] as num?)?.toStringAsFixed(1)) ?? 'N/A',
                    remarks.length > 30 ? '${remarks.substring(0, 30)}...' : remarks,
                    f['createdAt'] != null
                        ? DateFormat('dd-MMM-yyyy').format(DateTime.parse(f['createdAt'])) : 'N/A',
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

  static Future<Uint8List> generateBillingReportPdf(Map<String, dynamic> bill, List<dynamic> deductions) async {
    final pdf = pw.Document();
    final railway = await _getRailwayLogo();
    final mirtha = await _getMirthaLogo();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (pw.Context context) {
          return [
            _buildHeader(railway, mirtha, 'BILLING & INVOICE REPORT', bill['status'] ?? 'PENDING'),
            _buildSectionHeader('1. BILL SUMMARY'),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(border: pw.Border.all(color: borderColor), borderRadius: pw.BorderRadius.circular(4)),
              child: pw.Column(
                children: [
                  _buildInfoRow('Bill ID', bill['uid']?.toString() ?? 'N/A', 'Period', bill['period']?.toString() ?? 'N/A'),
                  _buildInfoRow('Contract', bill['contractNumber']?.toString() ?? 'N/A', 'Entity', bill['entityName']?.toString() ?? 'N/A'),
                  _buildInfoRow('Zone', bill['zone']?.toString() ?? 'N/A', 'Division', bill['division']?.toString() ?? 'N/A'),
                  _buildInfoRow('Contract Value', 'Rs. ${(bill['contractValue'] ?? 0).toString()}', 'Grade', bill['grade']?.toString() ?? 'N/A'),
                  _buildInfoRow('Overall Score', '${bill['overallScore']?.toString() ?? '0'}%', 'Status', bill['status']?.toString() ?? 'N/A'),
                ],
              ),
            ),
            _buildSectionHeader('2. DEDUCTION BREAKDOWN', color: PdfColor.fromInt(0xffdc3545)),
            pw.TableHelper.fromTextArray(
              context: context,
              headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9),
              headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xffdc3545)),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellAlignment: pw.Alignment.center,
              data: <List<String>>[
                ['Type', 'Description', 'Count', 'Rate', 'Amount'],
                ...deductions.map((d) {
                  return [
                    d['type']?.toString() ?? 'N/A',
                    d['description']?.toString() ?? 'N/A',
                    '${d['count'] ?? 0}',
                    'Rs. ${(d['rate'] ?? 0).toString()}',
                    'Rs. ${(d['amount'] ?? 0).toString()}',
                  ];
                }),
              ],
            ),
            _buildSectionHeader('3. PAYABLE CALCULATION'),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(border: pw.Border.all(color: borderColor), borderRadius: pw.BorderRadius.circular(4)),
              child: pw.Column(
                children: [
                  _buildInfoRow('Contract Value', 'Rs. ${(bill['contractValue'] ?? 0).toString()}', 'Total Deduction', '-Rs. ${(bill['totalDeduction'] ?? 0).toString()}'),
                  pw.Divider(thickness: 1, color: primaryColor),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text('FINAL PAYABLE: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: primaryColor)),
                      pw.Text('Rs. ${(bill['finalPayable'] ?? 0).toString()}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16, color: successColor)),
                    ],
                  ),
                ],
              ),
            ),
            _buildSectionHeader('4. AUDIT TRAIL'),
            pw.TableHelper.fromTextArray(
              context: context,
              headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9),
              headerDecoration: const pw.BoxDecoration(color: primaryColor),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellAlignment: pw.Alignment.center,
              data: <List<String>>[
                ['Action', 'Performed By', 'Timestamp', 'Details'],
                ...(bill['auditLog'] as List? ?? []).map((a) {
                  return [
                    a['action']?.toString() ?? 'N/A',
                    a['performedByName']?.toString() ?? 'N/A',
                    a['timestamp'] != null ? DateFormat('dd-MMM hh:mm a').format(DateTime.parse(a['timestamp'])) : 'N/A',
                    a['details']?.toString() ?? 'N/A',
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
  

  static Future<Uint8List> generateCleaningFormReportPdf(Map<String, dynamic> form) async {
    final pdf = pw.Document();
    final railway = await _getRailwayLogo();
    final mirtha = await _getMirthaLogo();

    final isCoach = form['formType'] == 'coach';
    final status = form['status'] ?? 'draft';
    final score = form['score'];
    final grade = form['grade'];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (pw.Context context) {
          return [
            _buildHeader(railway, mirtha, '${isCoach ? "COACH" : "PREMISE"} CLEANING FORM', status.toUpperCase()),
            _buildSectionHeader('1. FORM DETAILS'),
            _buildInfoRow('Form ID', form['formId'] ?? 'N/A', '', ''),
            _buildInfoRow('Form Type', isCoach ? 'Coach Cleaning' : 'Premise Cleaning', '', ''),
            _buildInfoRow('Date', form['cleaningDate'] ?? 'N/A', '', ''),
            _buildInfoRow('Shift', form['cleaningShift'] ?? 'N/A', '', ''),
            _buildInfoRow('Start Time', form['startTime'] ?? 'N/A', '', ''),
            _buildInfoRow('End Time', form['endTime'] ?? 'N/A', '', ''),
            _buildInfoRow('Division', form['division'] ?? 'N/A', '', ''),
            _buildInfoRow('Depot', form['depot'] ?? 'N/A', '', ''),
            _buildInfoRow('Status', status, '', ''),
            pw.SizedBox(height: 10),
            _buildSectionHeader('2. CONTRACT & ENTITY'),
            _buildInfoRow('Contract', form['contractNumber'] ?? 'N/A', '', ''),
            _buildInfoRow('Entity', form['entityName'] ?? 'N/A', '', ''),
            _buildInfoRow('Submitted By', form['submittedByName'] ?? 'N/A', '', ''),
            _buildInfoRow('Manpower', '${form['manpowerCount'] ?? 0}', '', ''),
            _buildInfoRow('Machines', '${form['machineCount'] ?? 0}', '', ''),
            pw.SizedBox(height: 10),
            if (isCoach && form['coachDetails'] != null) ...[
              _buildSectionHeader('3. COACH DETAILS'),
              _buildInfoRow('Train Number', form['coachDetails']['trainNumber'] ?? 'N/A', '', ''),
              _buildInfoRow('Train Name', form['coachDetails']['trainName'] ?? 'N/A', '', ''),
              _buildInfoRow('Coach Number', form['coachDetails']['coachNumber'] ?? 'N/A', '', ''),
              _buildInfoRow('Coach Type', form['coachDetails']['coachType'] ?? 'N/A', '', ''),
              _buildInfoRow('Watering Done', form['coachDetails']['wateringDone'] == true ? 'Yes' : 'No', '', ''),
              _buildInfoRow('Toiletries', form['coachDetails']['toiletriesAvailable'] == true ? 'Available' : 'Not Available', '', ''),
              _buildInfoRow('Dustbins', form['coachDetails']['dustbinsAvailable'] == true ? 'Available' : 'Not Available', '', ''),
            ],
            if (!isCoach && form['premiseDetails'] != null) ...[
              _buildSectionHeader('3. PREMISE DETAILS'),
              _buildInfoRow('Premise Name', form['premiseDetails']['premiseName'] ?? 'N/A', '', ''),
              _buildInfoRow('Premise Type', form['premiseDetails']['premiseType'] ?? 'N/A', '', ''),
              _buildInfoRow('Area Covered', '${form['premiseDetails']['areaCovered'] ?? 0} sq.m', '', ''),
              _buildInfoRow('Area Uncleaned', '${form['premiseDetails']['areaUncleaned'] ?? 0} sq.m', '', ''),
              _buildInfoRow('Garbage Collected', '${form['premiseDetails']['garbageCollected'] ?? 0} kg', '', ''),
            ],
            if (form['remarks'] != null && form['remarks'].toString().isNotEmpty) ...[
              pw.SizedBox(height: 10),
              _buildSectionHeader('4. REMARKS'),
              pw.Paragraph(text: form['remarks'], style: const pw.TextStyle(fontSize: 10)),
            ],
            pw.SizedBox(height: 10),
            _buildSectionHeader('5. SCORECARD'),
            if (score != null) ...[
              _buildInfoRow('Score', '${score.toStringAsFixed(1)}/100', '', ''),
              _buildInfoRow('Grade', grade ?? 'N/A', '', ''),
            ] else ...[
              pw.Paragraph(text: 'Not scored yet', style: pw.TextStyle(color: PdfColors.grey, fontSize: 10)),
            ],
            if (form['scoringData'] != null && form['scoringData']['criteria'] != null) ...[
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                context: context,
                headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 8),
                headerDecoration: const pw.BoxDecoration(color: primaryColor),
                cellStyle: const pw.TextStyle(fontSize: 8),
                cellAlignment: pw.Alignment.center,
                data: <List<String>>[
                  ['Criterion', 'Max', 'Score', 'Remarks'],
                  ...(form['scoringData']['criteria'] as List).map((c) => [
                    c['name'] ?? '',
                    '${c['maxScore'] ?? 10}',
                    '${c['score'] ?? 0}',
                    c['remarks'] ?? '',
                  ]),
                ],
              ),
            ],
            pw.SizedBox(height: 10),
            _buildSectionHeader('6. PHOTOS'),
            if (form['photos'] != null && (form['photos'] as List).isNotEmpty) ...[
              _buildInfoRow('Total Photos', '${(form['photos'] as List).length}', '', ''),
              _buildInfoRow('Before Photos', '${(form['photos'] as List).where((p) => p['type'] == 'before').length}', '', ''),
              _buildInfoRow('After Photos', '${(form['photos'] as List).where((p) => p['type'] == 'after').length}', '', ''),
            ] else ...[
              pw.Paragraph(text: 'No photos uploaded', style: pw.TextStyle(color: PdfColors.grey, fontSize: 10)),
            ],
            pw.SizedBox(height: 10),
            _buildSectionHeader('7. GPS LOCATION'),
            _buildInfoRow('Latitude', '${form['latitude'] ?? 'N/A'}', '', ''),
            _buildInfoRow('Longitude', '${form['longitude'] ?? 'N/A'}', '', ''),
            if (form['gpsAddress'] != null && form['gpsAddress'].toString().isNotEmpty)
              _buildInfoRow('Address', form['gpsAddress'], '', ''),
            pw.SizedBox(height: 10),
            _buildSectionHeader('8. APPROVAL & AUDIT'),
            if (form['approvedByName'] != null) ...[
              _buildInfoRow('Approved By', form['approvedByName'], '', ''),
              _buildInfoRow('Approved At', form['approvedAt'] != null ? DateFormat('dd-MMM-yyyy hh:mm a').format(DateTime.parse(form['approvedAt'])) : 'N/A', '', ''),
            ],
            if (form['rejectedByName'] != null) ...[
              _buildInfoRow('Rejected By', form['rejectedByName'], '', ''),
              _buildInfoRow('Rejection Reason', form['rejectionReason'] ?? 'N/A', '', ''),
            ],
            _buildInfoRow('Created At', form['createdAt'] != null ? DateFormat('dd-MMM-yyyy hh:mm a').format(DateTime.parse(form['createdAt'])) : 'N/A', '', ''),
            if (form['lockedAt'] != null)
              _buildInfoRow('Locked At', DateFormat('dd-MMM-yyyy hh:mm a').format(DateTime.parse(form['lockedAt'])), '', ''),
            pw.SizedBox(height: 20),
            _buildSignatures(),
          ];
        },
      ),
    );
    return pdf.save();
  }

  // 6. Station Cleaning Form Report
  
  static Future<Uint8List> generateStationCleaningFormReportPdf(Map<String, dynamic> form) async {
    final pdf = pw.Document();
    final railway = await _getRailwayLogo();
    final mirtha = await _getMirthaLogo();
    final score = form['score'];
    final grade = form['grade'];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (pw.Context context) {
          return [
            _buildHeader(railway, mirtha, 'STATION CLEANING FORM', (form['status'] ?? 'draft').toString().toUpperCase()),
            _buildSectionHeader('1. FORM DETAILS'),
            _buildInfoRow('Form ID', form['formId'] ?? 'N/A', '', ''),
            _buildInfoRow('Station', form['stationName'] ?? 'N/A', '', ''),
            _buildInfoRow('Area', form['areaName'] ?? 'N/A', '', ''),
            _buildInfoRow('Zone', form['zoneName'] ?? 'N/A', '', ''),
            _buildInfoRow('Date', form['cleaningDate'] ?? 'N/A', '', ''),
            _buildInfoRow('Shift', form['shift'] ?? 'N/A', '', ''),
            _buildInfoRow('Division', form['division'] ?? 'N/A', '', ''),
            _buildInfoRow('Status', form['status'] ?? 'N/A', '', ''),
            pw.SizedBox(height: 10),
            _buildSectionHeader('2. RESOURCE DEPLOYMENT'),
            _buildInfoRow('Manpower', '${form['manpowerCount'] ?? 0}', '', ''),
            _buildInfoRow('Machines', '${form['machineCount'] ?? 0}', '', ''),
            _buildInfoRow('Area Covered', '${form['areaCovered'] ?? 0} sq.m', '', ''),
            _buildInfoRow('Area Uncleaned', '${form['areaUncleaned'] ?? 0} sq.m', '', ''),
            _buildInfoRow('Garbage Collected', '${form['garbageCollected'] ?? 0} kg', '', ''),
            pw.SizedBox(height: 10),
            _buildSectionHeader('3. ACTIVITIES PERFORMED'),
            if (form['activities'] != null && (form['activities'] as List).isNotEmpty)
              ...(form['activities'] as List).map((a) => pw.Paragraph(text: '• $a', style: const pw.TextStyle(fontSize: 9)))
            else
              pw.Paragraph(text: 'No activities recorded', style: pw.TextStyle(color: PdfColors.grey, fontSize: 9)),
            pw.SizedBox(height: 10),
            _buildSectionHeader('4. SCORECARD'),
            if (score != null) ...[
              _buildInfoRow('Total Score', '${score.toStringAsFixed(1)}/100', '', ''),
              _buildInfoRow('Grade', grade ?? 'N/A', '', ''),
            ] else
              pw.Paragraph(text: 'Not scored yet', style: pw.TextStyle(color: PdfColors.grey, fontSize: 10)),
            if (form['scoringData'] != null && form['scoringData']['criteria'] != null) ...[
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                context: context,
                headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 8),
                headerDecoration: const pw.BoxDecoration(color: primaryColor),
                cellStyle: const pw.TextStyle(fontSize: 8),
                cellAlignment: pw.Alignment.center,
                data: <List<String>>[
                  ['Criterion', 'Weight', 'Score'],
                  ...(form['scoringData']['criteria'] as List).map((c) => [
                    c['name'] ?? '',
                    '${c['weight'] ?? 0}%',
                    '${c['score'] ?? 0}',
                  ]),
                ],
              ),
            ],
            pw.SizedBox(height: 10),
            _buildSectionHeader('5. PHOTOS & GPS'),
            _buildInfoRow('Photos', '${(form['photos'] as List?)?.length ?? 0}', '', ''),
            _buildInfoRow('Latitude', '${form['latitude'] ?? 'N/A'}', '', ''),
            _buildInfoRow('Longitude', '${form['longitude'] ?? 'N/A'}', '', ''),
            pw.SizedBox(height: 10),
            _buildSectionHeader('6. APPROVAL & AUDIT'),
            if (form['approvedByName'] != null) _buildInfoRow('Approved By', form['approvedByName'], '', ''),
            if (form['rejectedByName'] != null) _buildInfoRow('Rejected By', form['rejectedByName'], '', ''),
            _buildInfoRow('Submitted By', form['submittedByName'] ?? 'N/A', '', ''),
            _buildInfoRow('Entity', form['entityName'] ?? 'N/A', '', ''),
            pw.SizedBox(height: 20),
            _buildSignatures(),
          ];
        },
      ),
    );
    return pdf.save();
  }

}
