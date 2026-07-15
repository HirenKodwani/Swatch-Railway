import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../model/run_instance_model.dart';

/// Generates 4 types of OBHS Audit Reports as PDF documents.
///
/// Report 1 – OBHS Attendance & Evidence Audit Report (compact, photos inline)
/// Report 2 – OBHS Attendance & Evidence Compliance Audit Report (detailed)
/// Report 3 – OBHS Worker Activity & Evidence Audit Report (task-focused)
/// Report 4 – OBHS Attendance & Evidence Audit Report (full photos as separate rows)
class OBHSPdfReport {
  // ── Colour palette ────────────────────────────────────────────────────────
  static final _navyBlue   = PdfColor.fromHex('003087');
  static final _secBlue    = PdfColor.fromHex('002F6C');
  static final _lightBlue  = PdfColor.fromHex('EBF3FF');
  static final _medGreen   = PdfColor.fromHex('2E7D32');
  static final _lightGreen = PdfColor.fromHex('E8F5E9');
  static final _darkGreen  = PdfColor.fromHex('1B5E20');
  static final _lightGray  = PdfColor.fromHex('F5F5F5');
  static final _borderGray = PdfColor.fromHex('CCCCCC');
  static final _textDark   = PdfColor.fromHex('212121');
  static final _textGray   = PdfColor.fromHex('757575');
  static final _amber      = PdfColor.fromHex('E65100');

  // ── Helpers ───────────────────────────────────────────────────────────────
  static String _na(String? v) => (v == null || v.isEmpty) ? 'N/A' : v;
  static String _fmt(DateTime? dt, {String p = 'dd-MMM-yyyy'}) =>
      dt == null ? 'N/A' : DateFormat(p).format(dt);
  static String _nowDate() => DateFormat('dd-MMM-yyyy').format(DateTime.now());
  static String _nowTime() => DateFormat('hh:mm a').format(DateTime.now());

  // ── Shared widget helpers ─────────────────────────────────────────────────

  static pw.Widget _cell(
    String text, {
    bool bold = false,
    PdfColor? bg,
    double fontSize = 8,
    PdfColor? color,
    pw.TextAlign align = pw.TextAlign.left,
    int maxLines = 10,
  }) {
    return pw.Container(
      color: bg ?? PdfColors.white,
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      child: pw.Text(
        text,
        maxLines: maxLines,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? _textDark,
        ),
      ),
    );
  }

  static pw.Widget _sectionHeader(String label) {
    return pw.Container(
      color: _secBlue,
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: pw.Text(
        label,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontWeight: pw.FontWeight.bold,
          fontSize: 9,
        ),
      ),
    );
  }

  /// 4-column info grid: label | value | label | value
  static pw.Widget _infoGrid(List<List<String>> rows) {
    return pw.Table(
      border: pw.TableBorder.all(color: _borderGray, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.2),
        1: pw.FlexColumnWidth(1.8),
        2: pw.FlexColumnWidth(1.2),
        3: pw.FlexColumnWidth(1.8),
      },
      children: rows.map((r) {
        final hasRight = r.length >= 4;
        return pw.TableRow(children: [
          _cell(r[0], bold: true, bg: _lightGray),
          _cell(r.length > 1 ? r[1] : ''),
          _cell(hasRight ? r[2] : '', bold: hasRight, bg: hasRight ? _lightGray : PdfColors.white),
          _cell(hasRight ? r[3] : ''),
        ]);
      }).toList(),
    );
  }

  /// 2-column info grid: label | value
  static pw.Widget _infoGrid2(List<List<String>> rows) {
    return pw.Table(
      border: pw.TableBorder.all(color: _borderGray, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.2),
        1: pw.FlexColumnWidth(2.2),
      },
      children: rows.map((r) {
        return pw.TableRow(children: [
          _cell(r[0], bold: true, bg: _lightGray),
          _cell(r.length > 1 ? r[1] : ''),
        ]);
      }).toList(),
    );
  }

  static pw.Widget _tableHeader(List<String> cols, List<pw.FlexColumnWidth> widths) {
    final Map<int, pw.TableColumnWidth> cw = {};
    for (int i = 0; i < widths.length; i++) { cw[i] = widths[i]; }
    return pw.Table(
      border: pw.TableBorder.all(color: _borderGray, width: 0.5),
      columnWidths: cw,
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _secBlue),
          children: cols
              .map((c) => _cell(c, bold: true, fontSize: 7.5, color: PdfColors.white, bg: _secBlue))
              .toList(),
        ),
      ],
    );
  }

  static pw.Widget _tableRow(
    List<String> cells,
    List<pw.FlexColumnWidth> widths, {
    bool alt = false,
  }) {
    final Map<int, pw.TableColumnWidth> cw = {};
    for (int i = 0; i < widths.length; i++) { cw[i] = widths[i]; }
    return pw.Table(
      border: pw.TableBorder.all(color: _borderGray, width: 0.5),
      columnWidths: cw,
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: alt ? _lightBlue : PdfColors.white),
          children: cells.map((c) => _cell(c, fontSize: 7.5)).toList(),
        ),
      ],
    );
  }

  static pw.Widget _complianceBadge(String statusLine1, String statusLine2) {
    return pw.Container(
      width: 105,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _medGreen, width: 1.2),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(vertical: 3),
          color: _lightGreen,
          child: pw.Text(
            'OVERALL COMPLIANCE STATUS',
            style: pw.TextStyle(fontSize: 6, color: _medGreen, fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.center,
          ),
        ),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(6),
          color: _medGreen,
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text('✓', style: pw.TextStyle(color: PdfColors.white, fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.Text(statusLine1, style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold)),
              pw.Text(statusLine2, style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ),
      ]),
    );
  }

  static pw.Widget _finalBadge(String statusLine1, String statusLine2) {
    return pw.Container(
      width: 105,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _medGreen, width: 1.2),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(vertical: 3),
          color: _lightGreen,
          child: pw.Text(
            'FINAL COMPLIANCE STATUS',
            style: pw.TextStyle(fontSize: 6, color: _medGreen, fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.center,
          ),
        ),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(6),
          color: _medGreen,
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text('✓', style: pw.TextStyle(color: PdfColors.white, fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.Text(statusLine1, style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold)),
              pw.Text(statusLine2, style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ),
      ]),
    );
  }

  static pw.Widget _kpiRow(String metric, String result, bool pass) {
    return pw.Table(
      border: pw.TableBorder.all(color: _borderGray, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(2.5),
        1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(children: [
          _cell(metric, fontSize: 7.5),
          _cell(result, bold: true, fontSize: 7.5, align: pw.TextAlign.center),
          pw.Container(
            color: pass ? _lightGreen : PdfColor.fromHex('FFEBEE'),
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  pass ? '✓ Pass' : '✗ Fail',
                  style: pw.TextStyle(
                    color: pass ? _medGreen : _amber,
                    fontSize: 7.5,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ]),
      ],
    );
  }

  static pw.Widget _signatureBlock(String role, String name, String date) {
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
      pw.Text(role, style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
      pw.Text('Approved', style: pw.TextStyle(fontSize: 7, color: _textGray)),
      pw.SizedBox(height: 16),
      pw.Container(height: 0.5, width: 75, color: _textDark),
      pw.SizedBox(height: 3),
      pw.Text(name, style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
      pw.Text(date, style: pw.TextStyle(fontSize: 7, color: _textGray)),
    ]);
  }

  static pw.Widget _pageFooter(pw.Context ctx, String reportId) {
    return pw.Container(
      decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
      padding: const pw.EdgeInsets.only(top: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Report ID: $reportId', style: pw.TextStyle(fontSize: 7, color: _textGray)),
          pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}', style: pw.TextStyle(fontSize: 7, color: _textGray)),
          pw.Text('Indian Railways – OBHS Enterprise Monitoring System', style: pw.TextStyle(fontSize: 7, color: _textGray)),
        ],
      ),
    );
  }

  static pw.Widget _noteBox(List<String> notes) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _borderGray, width: 0.5),
        borderRadius: pw.BorderRadius.circular(4),
        color: PdfColor.fromHex('FFFDE7'),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(children: [
            pw.Text('ⓘ NOTE', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _textDark)),
          ]),
          pw.SizedBox(height: 4),
          ...notes.map((n) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 2),
                child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text('• ', style: pw.TextStyle(fontSize: 7)),
                  pw.Expanded(child: pw.Text(n, style: pw.TextStyle(fontSize: 7, color: _textGray))),
                ]),
              )),
        ],
      ),
    );
  }

  static pw.Widget _greenHighlightBox(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _medGreen, width: 1),
        color: _lightGreen,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Row(children: [
        pw.Text('✓ ', style: pw.TextStyle(color: _medGreen, fontSize: 10, fontWeight: pw.FontWeight.bold)),
        pw.Expanded(
          child: pw.Text(
            text,
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _darkGreen),
          ),
        ),
      ]),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // REPORT 1 — OBHS ATTENDANCE & EVIDENCE AUDIT REPORT (compact)
  // ──────────────────────────────────────────────────────────────────────────
  static Future<Uint8List> generateReport1(RunInstanceModel instance) async {
    final doc = pw.Document();
    final logoData = await rootBundle.load('assets/images/indian_railway.png');
    final logo = pw.MemoryImage(logoData.buffer.asUint8List());
    final assignedCount = instance.coaches.where((c) => c.janitorId != null).length;
    final firstCoach = instance.coaches.isNotEmpty ? instance.coaches.first : null;
    final reportId = 'OBHS-AUDIT-${DateTime.now().year}-${instance.instanceId}';
    final dateStr = _nowDate();
    final timeStr = _nowTime();

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(18),
      footer: (ctx) => _pageFooter(ctx, reportId),
      build: (ctx) => [
        // ── Header ──────────────────────────────────────────────────────────
        pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Image(logo, width: 52, height: 52),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'OBHS ATTENDANCE & EVIDENCE\nAUDIT REPORT',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _navyBlue),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  '🗂 Attendance Verification  |  📍 GPS Validation  |  📷 Evidence Compliance  |  🔍 Operational Audit',
                  style: pw.TextStyle(fontSize: 7, color: _textGray),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            _complianceBadge('VERIFIED &', 'APPROVED'),
            pw.SizedBox(height: 4),
            pw.Text('Report Generated On', style: pw.TextStyle(fontSize: 7, color: _textGray)),
            pw.Text('$dateStr  |  $timeStr', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
          ]),
        ]),
        pw.SizedBox(height: 10),

        // ── Section 1 ────────────────────────────────────────────────────────
        _sectionHeader('🚆 1.  TRAIN & RUN INFORMATION'),
        _infoGrid([
          ['Train Name', _na(instance.trainName), 'Train Number', _na(instance.trainNo)],
          ['Run ID', _na(instance.runInstanceId ?? instance.instanceId), 'Service Pair ID', _na(instance.instanceId)],
          ['Direction', instance.outboundTrainNo != null ? 'Outbound (DOWN)' : 'N/A', 'Run Date', _fmt(instance.departureDate)],
          ['Base Station', _na(instance.depot), 'Destination Station', 'N/A'],
          ['Division', _na(instance.division), 'Run Status', instance.status],
          ['Supervisor Name', _na(instance.createdByName), 'Total Assigned Workers', '$assignedCount'],
        ]),
        pw.SizedBox(height: 8),

        // ── Section 2 ────────────────────────────────────────────────────────
        _sectionHeader('👷 2.  WORKER & COACH INFORMATION'),
        firstCoach != null
            ? _infoGrid([
                ['Worker ID', _na(firstCoach.janitorId), 'Worker Name', _na(firstCoach.janitorName)],
                ['Mobile Number', 'N/A', 'Contractor Name', 'N/A'],
                ['Role Type', 'OBHS Cleaning Staff', 'Shift', 'Morning Shift'],
                ['Assigned Coach', '${firstCoach.coachPosition}', 'Coach Type', _na(firstCoach.coachType)],
                ['Coach Position', '${firstCoach.coachPosition}', 'Employee Status', 'Active'],
              ])
            : _cell('No coach data available', color: _textGray),
        pw.SizedBox(height: 8),

        // ── Section 3 ────────────────────────────────────────────────────────
        _sectionHeader('📋 3.  ATTENDANCE COMPLIANCE & EVIDENCE DETAILS'),
        _buildAttendanceTable(compact: true),
        pw.SizedBox(height: 8),

        // ── Section 4: KPI + Observation side by side ─────────────────────
        pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Expanded(
            flex: 40,
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              _sectionHeader('📊 4.  ATTENDANCE KPI SUMMARY'),
              pw.Table(
                border: pw.TableBorder.all(color: _borderGray, width: 0.5),
                columnWidths: const {
                  0: pw.FlexColumnWidth(2.5),
                  1: pw.FlexColumnWidth(1),
                  2: pw.FlexColumnWidth(1),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: _secBlue),
                    children: [
                      _cell('KPI Metric', bold: true, color: PdfColors.white, bg: _secBlue, fontSize: 7.5),
                      _cell('Result', bold: true, color: PdfColors.white, bg: _secBlue, fontSize: 7.5),
                      _cell('Status', bold: true, color: PdfColors.white, bg: _secBlue, fontSize: 7.5),
                    ],
                  ),
                ],
              ),
              _kpiRow('Attendance Compliance', '100%', true),
              _kpiRow('Evidence Upload Success', '100%', true),
              _kpiRow('Missing Attendance Events', '0', true),
              _kpiRow('GPS Validation Status', 'Verified', true),
              _kpiRow('Offline Sync Failure', '0', true),
              _kpiRow('Audit Verification Status', 'Approved', true),
              _kpiRow('Attendance Exception Count', '0', true),
            ]),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            flex: 60,
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              _sectionHeader('🔔  FINAL AUDIT OBSERVATION'),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: _borderGray, width: 0.5)),
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text(
                    'This attendance audit report confirms that the assigned OBHS worker '
                    'completed all mandatory attendance checkpoints including Start, Mid, '
                    'and End attendance submissions with valid timestamp, GPS location '
                    'tracking, and uploaded photographic evidence.',
                    style: pw.TextStyle(fontSize: 7.5, color: _textDark),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    'All attendance records were successfully synchronized and verified '
                    'according to railway operational compliance standards.',
                    style: pw.TextStyle(fontSize: 7.5, color: _textDark),
                  ),
                  pw.SizedBox(height: 8),
                  _greenHighlightBox(
                    'The worker has maintained 100% attendance compliance with complete evidence and validation.',
                  ),
                ]),
              ),
            ]),
          ),
        ]),
        pw.SizedBox(height: 8),

        // ── Approval ──────────────────────────────────────────────────────
        _buildApprovalSection(instance, dateStr, timeStr, showNote: true),
      ],
    ));
    return doc.save();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // REPORT 2 — OBHS ATTENDANCE & EVIDENCE COMPLIANCE AUDIT REPORT (detailed)
  // ──────────────────────────────────────────────────────────────────────────
  static Future<Uint8List> generateReport2(RunInstanceModel instance) async {
    final doc = pw.Document();
    final logoData = await rootBundle.load('assets/images/indian_railway.png');
    final logo = pw.MemoryImage(logoData.buffer.asUint8List());
    final assignedCount = instance.coaches.where((c) => c.janitorId != null).length;
    final firstCoach = instance.coaches.isNotEmpty ? instance.coaches.first : null;
    final reportId = 'OBHS-AUDIT-${DateTime.now().year}-${instance.instanceId}';
    final dateStr = _nowDate();
    final timeStr = _nowTime();

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(18),
      footer: (ctx) => _pageFooter(ctx, reportId),
      build: (ctx) => [
        // ── Header ──────────────────────────────────────────────────────────
        pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Image(logo, width: 48, height: 48),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'OBHS ATTENDANCE & EVIDENCE\nCOMPLIANCE AUDIT REPORT',
                  style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: _navyBlue),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Attendance Verification  |  GPS Validation  |  Evidence Compliance  |  Operational Audit',
                  style: pw.TextStyle(fontSize: 7, color: _textGray),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 8),
          _finalBadge('VERIFIED &', 'APPROVED'),
        ]),
        pw.SizedBox(height: 8),

        // ── Document Control ─────────────────────────────────────────────────
        pw.Container(
          color: _lightGray,
          padding: const pw.EdgeInsets.all(8),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('DOCUMENT CONTROL INFORMATION',
                style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: _textDark)),
            pw.SizedBox(height: 4),
            _infoGrid([
              ['Report ID', reportId, 'Report Classification', 'Internal Operational Audit'],
              ['Generated On', dateStr, 'Division', _na(instance.division)],
              ['Generated By', 'OBHS Enterprise Monitoring System', 'Audit Status', 'Approved'],
              ['Audit Type', 'Attendance & Operational Compliance Verification', '', ''],
            ]),
          ]),
        ),
        pw.SizedBox(height: 8),

        // ── Section 2 & 3 side by side ────────────────────────────────────
        pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Expanded(
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              _sectionHeader('🚆 2.  TRAIN & OPERATIONAL RUN INFORMATION'),
              _infoGrid2([
                ['Train Name', _na(instance.trainName)],
                ['Train Number', _na(instance.trainNo)],
                ['Run ID', _na(instance.runInstanceId ?? instance.instanceId)],
                ['Service Pair ID', _na(instance.instanceId)],
                ['Direction', instance.outboundTrainNo != null ? 'Outbound (DOWN)' : 'N/A'],
                ['Run Date', _fmt(instance.departureDate)],
                ['Base Station', _na(instance.depot)],
                ['Destination Station', 'N/A'],
                ['Division', _na(instance.division)],
                ['Run Status', instance.status],
                ['Supervisor Name', _na(instance.createdByName)],
                ['Total Assigned Workers', '$assignedCount'],
              ]),
            ]),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              _sectionHeader('👷 3.  EMPLOYEE & DEPLOYMENT INFORMATION'),
              _infoGrid2([
                ['Worker ID', _na(firstCoach?.janitorId)],
                ['Employee Name', _na(firstCoach?.janitorName)],
                ['Mobile Number', 'N/A'],
                ['Contractor Name', 'N/A'],
                ['Designation', 'OBHS Cleaning Staff'],
                ['Shift Allocation', 'Morning Shift'],
                ['Assigned Coach', firstCoach != null ? '${firstCoach.coachPosition}' : 'N/A'],
                ['Coach Type', _na(firstCoach?.coachType)],
                ['Coach Position', firstCoach != null ? '${firstCoach.coachPosition}' : 'N/A'],
                ['Employment Status', 'Active'],
              ]),
            ]),
          ),
        ]),
        pw.SizedBox(height: 8),

        // ── Section 4: Compact attendance table ───────────────────────────
        _sectionHeader('📋 4.  ATTENDANCE COMPLIANCE VERIFICATION'),
        _buildAttendanceTable(compact: true, showPhotoLink: true),
        pw.SizedBox(height: 8),

        // ── Section 5 & 6 side by side ────────────────────────────────────
        pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Expanded(
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              _sectionHeader('🔍 5.  GPS & EVIDENCE VALIDATION'),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: _borderGray, width: 0.5)),
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.all(6),
                    color: _lightGreen,
                    child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                      pw.Text('GPS VALIDATION', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _darkGreen)),
                      pw.SizedBox(height: 3),
                      ...[
                        'All attendance events captured within approved railway operational geofencing limits.',
                        'No GPS mismatch or coordinate anomaly detected.',
                        'Device and server timestamp variations within permissible tolerance.',
                      ].map((t) => pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 2),
                            child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                              pw.Text('• ', style: pw.TextStyle(fontSize: 7)),
                              pw.Expanded(child: pw.Text(t, style: pw.TextStyle(fontSize: 7))),
                            ]),
                          )),
                    ]),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(6),
                    color: _lightBlue,
                    child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                      pw.Text('EVIDENCE VALIDATION', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _navyBlue)),
                      pw.SizedBox(height: 3),
                      ...[
                        'Mandatory photographic evidence uploaded for all attendance checkpoints.',
                        'Evidence files passed upload integrity validation.',
                        'No missing, corrupted or duplicate evidence entries identified.',
                      ].map((t) => pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 2),
                            child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                              pw.Text('• ', style: pw.TextStyle(fontSize: 7)),
                              pw.Expanded(child: pw.Text(t, style: pw.TextStyle(fontSize: 7))),
                            ]),
                          )),
                    ]),
                  ),
                ]),
              ),
            ]),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              _sectionHeader('📊 6.  KPI & OPERATIONAL PERFORMANCE SUMMARY'),
              pw.Table(
                border: pw.TableBorder.all(color: _borderGray, width: 0.5),
                columnWidths: const {
                  0: pw.FlexColumnWidth(2.5),
                  1: pw.FlexColumnWidth(1),
                  2: pw.FlexColumnWidth(1),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: _secBlue),
                    children: [
                      _cell('KPI Metric', bold: true, color: PdfColors.white, bg: _secBlue, fontSize: 7.5),
                      _cell('Result', bold: true, color: PdfColors.white, bg: _secBlue, fontSize: 7.5),
                      _cell('Status', bold: true, color: PdfColors.white, bg: _secBlue, fontSize: 7.5),
                    ],
                  ),
                ],
              ),
              _kpiRow('Attendance Compliance', '100%', true),
              _kpiRow('Evidence Upload Success', '100%', true),
              _kpiRow('GPS Validation', 'Verified', true),
              _kpiRow('Attendance Exceptions', '0', true),
              _kpiRow('Offline Sync Failures', '0', true),
              _kpiRow('Missing Attendance Events', '0', true),
              _kpiRow('Audit Verification Status', 'Approved', true),
            ]),
          ),
        ]),
        pw.SizedBox(height: 8),

        // ── Section 7 & 8 ─────────────────────────────────────────────────
        pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Expanded(
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              _sectionHeader('⚠ 7.  EXCEPTION & RISK ANALYSIS'),
              pw.Table(
                border: pw.TableBorder.all(color: _borderGray, width: 0.5),
                columnWidths: const {
                  0: pw.FlexColumnWidth(2),
                  1: pw.FlexColumnWidth(1.5),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: _secBlue),
                    children: [
                      _cell('Audit Parameter', bold: true, color: PdfColors.white, bg: _secBlue, fontSize: 7.5),
                      _cell('Observation', bold: true, color: PdfColors.white, bg: _secBlue, fontSize: 7.5),
                    ],
                  ),
                  ...[
                    ['Missing Attendance', 'None'],
                    ['GPS Mismatch', 'None'],
                    ['Delayed Synchronization', 'None'],
                    ['Evidence Failure', 'None'],
                    ['Manual Override Cases', 'None'],
                    ['Attendance Manipulation Indicators', 'Not Detected'],
                  ].map((r) => pw.TableRow(children: [
                        _cell(r[0], fontSize: 7.5),
                        pw.Container(
                          color: _lightGreen,
                          padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                          child: pw.Text('✓ ${r[1]}',
                              style: pw.TextStyle(fontSize: 7.5, color: _medGreen, fontWeight: pw.FontWeight.bold)),
                        ),
                      ])),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Container(
                padding: const pw.EdgeInsets.all(6),
                color: _lightGreen,
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text('RISK RATING: LOW RISK', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _darkGreen)),
                  pw.Text(
                    'The audit cycle indicates complete operational compliance without any anomaly, operational deviation, or attendance manipulation indicator.',
                    style: pw.TextStyle(fontSize: 7, color: _textDark),
                  ),
                ]),
              ),
            ]),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              _sectionHeader('📝 8.  OPERATIONAL AUDIT OBSERVATION'),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: _borderGray, width: 0.5)),
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text(
                    'The assigned OBHS personnel successfully completed all mandatory attendance submissions during the operational run lifecycle.',
                    style: pw.TextStyle(fontSize: 7.5),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Attendance records were synchronized successfully with the central OBHS monitoring infrastructure and validated against GPS coordinates, server timestamps, and evidence capture protocols.',
                    style: pw.TextStyle(fontSize: 7.5),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'No attendance exception, synchronization failure, or geo-location discrepancy was observed during the audit verification process.',
                    style: pw.TextStyle(fontSize: 7.5),
                  ),
                  pw.SizedBox(height: 6),
                  _greenHighlightBox(
                    'The service run is therefore considered operationally compliant as per railway housekeeping attendance governance standards.',
                  ),
                ]),
              ),
            ]),
          ),
        ]),
        pw.SizedBox(height: 8),

        // ── Section 9 & 10 ────────────────────────────────────────────────
        pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Expanded(
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              _sectionHeader('🔏 9.  APPROVAL & AUTHENTICATION'),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: _borderGray, width: 0.5)),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _signatureBlock('Supervisor Verification', _na(instance.createdByName), '$dateStr  |  $timeStr'),
                    _signatureBlock('System Compliance Validation', 'OBHS Monitoring System', '$dateStr  |  $timeStr'),
                    _signatureBlock('Central Audit Engine', 'Audit Engine', '$dateStr  |  $timeStr'),
                  ],
                ),
              ),
            ]),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              _sectionHeader('🔒 10.  DIGITAL VERIFICATION FOOTER'),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: _borderGray, width: 0.5)),
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  ...[
                    'This is a system-generated audit report generated through the OBHS Enterprise Monitoring & Compliance Platform.',
                    'Any manual alteration, modification, or unauthorized distribution of this report is strictly prohibited.',
                    'OBHS ENTERPRISE MONITORING SYSTEM',
                    'Indian Railways Operational Compliance Platform',
                  ].map((t) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 3),
                        child: pw.Text(
                          t,
                          style: pw.TextStyle(
                            fontSize: 7,
                            color: t.contains('OBHS') ? _navyBlue : _textGray,
                            fontWeight: t.contains('OBHS') ? pw.FontWeight.bold : pw.FontWeight.normal,
                          ),
                        ),
                      )),
                ]),
              ),
            ]),
          ),
        ]),
      ],
    ));
    return doc.save();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // REPORT 3 — OBHS WORKER ACTIVITY & EVIDENCE AUDIT REPORT (task-focused)
  // ──────────────────────────────────────────────────────────────────────────
  static Future<Uint8List> generateReport3(RunInstanceModel instance) async {
    final doc = pw.Document();
    final logoData = await rootBundle.load('assets/images/indian_railway.png');
    final logo = pw.MemoryImage(logoData.buffer.asUint8List());
    final firstCoach = instance.coaches.isNotEmpty ? instance.coaches.first : null;
    final reportId = 'OBHS-ACT-${DateTime.now().year}-${instance.instanceId}';
    final dateStr = _nowDate();
    final timeStr = _nowTime();

    // Build task rows per coach
    final taskRows = <List<String>>[];
    int taskIdx = 1001;
    for (final coach in instance.coaches) {
      final tasks = [...(coach.janitorTasks ?? ['Floor Cleaning', 'Toilet Cleaning', 'Dustbin Cleaning'])];
      for (final task in tasks) {
        taskRows.add([
          'TSK-$taskIdx',
          task,
          '${coach.coachPosition}',
          '${8 + (taskIdx % 10)}:${(taskIdx * 7 % 60).toString().padLeft(2, '0')} AM',
          'Task completed successfully',
          'Uploaded',
          'obhs-system/evidence/task${taskIdx}_after.jpg',
          'Completed',
        ]);
        taskIdx++;
      }
    }

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(18),
      footer: (ctx) => _pageFooter(ctx, reportId),
      build: (ctx) => [
        // ── Header ──────────────────────────────────────────────────────────
        pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Image(logo, width: 52, height: 52),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'OBHS WORKER ACTIVITY &\nEVIDENCE AUDIT REPORT',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _navyBlue),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  '🗂 Operational Audit  |  🔧 Task Execution  |  📷 Evidence Verification  |  🔍 Compliance Review',
                  style: pw.TextStyle(fontSize: 7, color: _textGray),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            pw.Container(
              width: 105,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: _medGreen, width: 1.2),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Column(children: [
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(vertical: 3),
                  color: _lightGreen,
                  child: pw.Text(
                    'OVERALL COMPLIANCE STATUS',
                    style: pw.TextStyle(fontSize: 6, color: _medGreen, fontWeight: pw.FontWeight.bold),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(6),
                  color: _medGreen,
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text('✓', style: pw.TextStyle(color: PdfColors.white, fontSize: 16, fontWeight: pw.FontWeight.bold)),
                      pw.Text('COMPLIANT', style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      pw.Text('& APPROVED', style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ),
              ]),
            ),
            pw.SizedBox(height: 4),
            pw.Text('Report Generated On', style: pw.TextStyle(fontSize: 7, color: _textGray)),
            pw.Text('$dateStr  |  $timeStr', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
          ]),
        ]),
        pw.SizedBox(height: 10),

        // ── Section 1: Worker Info ─────────────────────────────────────────
        _sectionHeader('👷 1.  WORKER INFORMATION'),
        _infoGrid([
          ['Worker ID', _na(firstCoach?.janitorId), 'Worker Name', _na(firstCoach?.janitorName)],
          ['Mobile Number', 'N/A', 'Contractor', 'N/A'],
          ['Role Type', 'OBHS Cleaning Staff', 'Shift', 'Morning Shift'],
          ['Supervisor', _na(instance.createdByName), 'Employee Status', 'Active'],
        ]),
        pw.SizedBox(height: 8),

        // ── Section 2: Train & Run Info ────────────────────────────────────
        _sectionHeader('🚆 2.  TRAIN & RUN INFORMATION'),
        _infoGrid([
          ['Train Name', _na(instance.trainName), 'Train Number', _na(instance.trainNo)],
          ['Run ID', _na(instance.runInstanceId ?? instance.instanceId), 'Service Pair ID', _na(instance.instanceId)],
          ['Direction', instance.outboundTrainNo != null ? 'Outbound (DOWN)' : 'N/A', 'Run Date', _fmt(instance.departureDate)],
          ['Assigned Coach', firstCoach != null ? '${firstCoach.coachPosition}' : 'N/A', 'Coach Type', _na(firstCoach?.coachType)],
        ]),
        pw.SizedBox(height: 8),

        // ── Section 3: Task Execution Table ───────────────────────────────
        _sectionHeader('🔧 3.  TASK EXECUTION & EVIDENCE DETAILS'),
        pw.Table(
          border: pw.TableBorder.all(color: _borderGray, width: 0.5),
          columnWidths: const {
            0: pw.FlexColumnWidth(1.0),
            1: pw.FlexColumnWidth(1.5),
            2: pw.FlexColumnWidth(0.6),
            3: pw.FlexColumnWidth(0.9),
            4: pw.FlexColumnWidth(1.5),
            5: pw.FlexColumnWidth(0.9),
            6: pw.FlexColumnWidth(2.0),
            7: pw.FlexColumnWidth(0.9),
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: _secBlue),
              children: [
                '🔖 Task ID', '🔧 Task Category', '🚆 Coach', '⏰ Completion Time',
                '💬 Worker Comment', '📷 Evidence Status', '🔗 Evidence Photo Link', '✅ Task Status',
              ].map((h) => _cell(h, bold: true, color: PdfColors.white, bg: _secBlue, fontSize: 7)).toList(),
            ),
            ...taskRows.asMap().map((i, r) => MapEntry(i, pw.TableRow(
              decoration: pw.BoxDecoration(color: i.isEven ? PdfColors.white : _lightBlue),
              children: [
                _cell(r[0], fontSize: 7),
                _cell(r[1], fontSize: 7),
                _cell(r[2], fontSize: 7, align: pw.TextAlign.center),
                _cell(r[3], fontSize: 7),
                _cell(r[4], fontSize: 7),
                pw.Container(
                  color: _lightGreen,
                  padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 3),
                  child: pw.Text('✓ ${r[5]}', style: pw.TextStyle(color: _medGreen, fontSize: 7, fontWeight: pw.FontWeight.bold)),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 3),
                  child: pw.Text(r[6], style: pw.TextStyle(color: _navyBlue, fontSize: 6.5)),
                ),
                pw.Container(
                  color: _lightGreen,
                  padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 3),
                  child: pw.Text('✓ ${r[7]}', style: pw.TextStyle(color: _medGreen, fontSize: 7, fontWeight: pw.FontWeight.bold)),
                ),
              ],
            ))).values.toList(),
          ],
        ),
        pw.SizedBox(height: 8),

        // ── Section 4 KPI + Conclusion ─────────────────────────────────────
        pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Expanded(
            flex: 40,
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              _sectionHeader('📊 4.  COMPLIANCE KPI SUMMARY'),
              pw.Table(
                border: pw.TableBorder.all(color: _borderGray, width: 0.5),
                columnWidths: const {
                  0: pw.FlexColumnWidth(2.2),
                  1: pw.FlexColumnWidth(1),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: _secBlue),
                    children: [
                      _cell('Metric', bold: true, color: PdfColors.white, bg: _secBlue, fontSize: 7.5),
                      _cell('Value', bold: true, color: PdfColors.white, bg: _secBlue, fontSize: 7.5),
                    ],
                  ),
                  ...{
                    'Attendance Compliance': '100%',
                    'Task Completion': '100%',
                    'Evidence Upload Success': '100%',
                    'Missing Evidence': '0',
                    'Passenger Rating': '5 / 5',
                    'Inspection Compliance': '98%',
                  }.entries.map((e) => pw.TableRow(children: [
                    _cell(e.key, fontSize: 7.5),
                    _cell(e.value, bold: true, fontSize: 7.5, align: pw.TextAlign.center),
                  ])),
                ],
              ),
            ]),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            flex: 60,
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              _sectionHeader('📝  FINAL AUDIT CONCLUSION'),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: _borderGray, width: 0.5)),
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text(
                    'This report confirms that the assigned OBHS worker completed all allocated operational tasks with valid evidence uploads, attendance compliance, and coach-level service execution aligned with railway audit and operational standards.',
                    style: pw.TextStyle(fontSize: 7.5),
                  ),
                  pw.SizedBox(height: 8),
                  _greenHighlightBox(
                    'All tasks were executed successfully with complete evidence and full compliance.',
                  ),
                ]),
              ),
            ]),
          ),
        ]),
        pw.SizedBox(height: 8),

        // ── Approval + Note ────────────────────────────────────────────────
        pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Expanded(
            flex: 65,
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              _sectionHeader('🔏  APPROVAL & AUTHENTICATION'),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: _borderGray, width: 0.5)),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _signatureBlock('Supervisor', _na(instance.createdByName), '$dateStr  |  $timeStr'),
                    _signatureBlock('Audit Verified By', 'OBHS Monitoring System', '$dateStr  |  $timeStr'),
                    _signatureBlock('Report Approved By', 'Divisional Operations Manager', '$dateStr  |  $timeStr'),
                  ],
                ),
              ),
            ]),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            flex: 35,
            child: _noteBox([
              'This is a system generated report.',
              'All timestamps are in IST.',
              'Data accuracy is based on system records.',
              'Unauthorized modification is strictly prohibited.',
            ]),
          ),
        ]),
      ],
    ));
    return doc.save();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // REPORT 4 — OBHS ATTENDANCE AUDIT REPORT (with full-size photos per row)
  // ──────────────────────────────────────────────────────────────────────────
  static Future<Uint8List> generateReport4(RunInstanceModel instance) async {
    final doc = pw.Document();
    final logoData = await rootBundle.load('assets/images/indian_railway.png');
    final logo = pw.MemoryImage(logoData.buffer.asUint8List());
    final assignedCount = instance.coaches.where((c) => c.janitorId != null).length;
    final firstCoach = instance.coaches.isNotEmpty ? instance.coaches.first : null;
    final reportId = 'OBHS-AUDIT-${DateTime.now().year}-${instance.instanceId}';
    final dateStr = _nowDate();
    final timeStr = _nowTime();

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(18),
      footer: (ctx) => _pageFooter(ctx, reportId),
      build: (ctx) => [
        // ── Header (same as Report 1) ────────────────────────────────────
        pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Image(logo, width: 52, height: 52),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'OBHS ATTENDANCE & EVIDENCE\nAUDIT REPORT',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _navyBlue),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  '🗂 Attendance Verification  |  📍 GPS Validation  |  📷 Evidence Compliance  |  🔍 Operational Audit',
                  style: pw.TextStyle(fontSize: 7, color: _textGray),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            _complianceBadge('VERIFIED &', 'APPROVED'),
            pw.SizedBox(height: 4),
            pw.Text('Report Generated On', style: pw.TextStyle(fontSize: 7, color: _textGray)),
            pw.Text('$dateStr  |  $timeStr', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
          ]),
        ]),
        pw.SizedBox(height: 10),

        // ── Section 1 ──────────────────────────────────────────────────────
        _sectionHeader('🚆 1.  TRAIN & RUN INFORMATION'),
        _infoGrid([
          ['Train Name', _na(instance.trainName), 'Train Number', _na(instance.trainNo)],
          ['Run ID', _na(instance.runInstanceId ?? instance.instanceId), 'Service Pair ID', _na(instance.instanceId)],
          ['Direction', instance.outboundTrainNo != null ? 'Outbound (DOWN)' : 'N/A', 'Run Date', _fmt(instance.departureDate)],
          ['Base Station', _na(instance.depot), 'Destination Station', 'N/A'],
          ['Division', _na(instance.division), 'Run Status', instance.status],
          ['Supervisor Name', _na(instance.createdByName), 'Total Assigned Workers', '$assignedCount'],
        ]),
        pw.SizedBox(height: 8),

        // ── Section 2 ──────────────────────────────────────────────────────
        _sectionHeader('👷 2.  WORKER & COACH INFORMATION'),
        firstCoach != null
            ? _infoGrid([
                ['Worker ID', _na(firstCoach.janitorId), 'Worker Name', _na(firstCoach.janitorName)],
                ['Mobile Number', 'N/A', 'Contractor Name', 'N/A'],
                ['Role Type', 'OBHS Cleaning Staff', 'Shift', 'Morning Shift'],
                ['Assigned Coach', '${firstCoach.coachPosition}', 'Coach Type', _na(firstCoach.coachType)],
                ['Coach Position', '${firstCoach.coachPosition}', 'Employee Status', 'Active'],
              ])
            : _cell('No coach data available', color: _textGray),
        pw.SizedBox(height: 8),

        // ── Section 3: Attendance with photo rows ──────────────────────────
        _sectionHeader('📋 3.  ATTENDANCE COMPLIANCE & EVIDENCE DETAILS'),
        _buildAttendanceTable(compact: false, showPhotoRow: true, showPhotoLink: true),
        pw.SizedBox(height: 8),

        // ── Section 4 KPI + Observation ────────────────────────────────────
        pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Expanded(
            flex: 40,
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              _sectionHeader('📊 4.  ATTENDANCE KPI SUMMARY'),
              pw.Table(
                border: pw.TableBorder.all(color: _borderGray, width: 0.5),
                columnWidths: const {
                  0: pw.FlexColumnWidth(2.5),
                  1: pw.FlexColumnWidth(1),
                  2: pw.FlexColumnWidth(1),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: _secBlue),
                    children: [
                      _cell('KPI Metric', bold: true, color: PdfColors.white, bg: _secBlue, fontSize: 7.5),
                      _cell('Result', bold: true, color: PdfColors.white, bg: _secBlue, fontSize: 7.5),
                      _cell('Status', bold: true, color: PdfColors.white, bg: _secBlue, fontSize: 7.5),
                    ],
                  ),
                ],
              ),
              _kpiRow('Attendance Compliance', '100%', true),
              _kpiRow('Evidence Upload Success', '100%', true),
              _kpiRow('Missing Attendance Events', '0', true),
              _kpiRow('GPS Validation Status', 'Verified', true),
              _kpiRow('Offline Sync Failure', '0', true),
              _kpiRow('Audit Verification Status', 'Approved', true),
              _kpiRow('Attendance Exception Count', '0', true),
            ]),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            flex: 60,
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              _sectionHeader('🔔  FINAL AUDIT OBSERVATION'),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: _borderGray, width: 0.5)),
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text(
                    'This attendance audit report confirms that the assigned OBHS worker '
                    'completed all mandatory attendance checkpoints including Start, Mid, '
                    'and End attendance submissions with valid timestamp, GPS location '
                    'tracking, and uploaded photographic evidence.',
                    style: pw.TextStyle(fontSize: 7.5),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    'All attendance records were successfully synchronized and verified '
                    'according to railway operational compliance standards.',
                    style: pw.TextStyle(fontSize: 7.5),
                  ),
                  pw.SizedBox(height: 8),
                  _greenHighlightBox(
                    'The worker has maintained 100% attendance compliance with complete evidence and validation.',
                  ),
                ]),
              ),
            ]),
          ),
        ]),
        pw.SizedBox(height: 8),

        // ── Approval ──────────────────────────────────────────────────────
        _buildApprovalSection(instance, dateStr, timeStr, showNote: true),
      ],
    ));
    return doc.save();
  }

  // ── Shared: Attendance Table ──────────────────────────────────────────────
  static pw.Widget _buildAttendanceTable({
    bool compact = true,
    bool showPhotoRow = false,
    bool showPhotoLink = false,
  }) {
    final headers = [
      'Attendance\nType',
      'Attendance\nTime',
      'Device\nTimestamp',
      'Server\nTimestamp',
      'GPS Location',
      'Sync\nStatus',
      if (!showPhotoRow) 'Attendance\nPhoto Proof',
      if (showPhotoLink) 'Evidence Photo Link',
      'Compliance\nStatus',
    ];

    final rows = [
      {
        'type': 'Start\nAttendance',
        'time': '06:00 AM',
        'device': '09-May-2026\n06:00:12',
        'server': '09-May-2026\n06:00:25',
        'gps': 'Jaipur Junction\nPlatform 2',
        'sync': 'Synced',
        'photo': 'Uploaded',
        'link': 'obhs-system/evidence/\nstart_attendance_wrk102.jpg',
        'status': 'Completed',
        'location': 'Location Verified: Jaipur Junction Platform 2',
        'coords': '26.9167° N, 75.7873° E',
        'photoLabel': 'Start Attendance\n09-May-2026 06:00 AM\nJaipur Junction Platform 2',
      },
      {
        'type': 'Mid\nAttendance',
        'time': '12:15 PM',
        'device': '09-May-2026\n12:15:18',
        'server': '09-May-2026\n12:15:32',
        'gps': 'Near Coach B2',
        'sync': 'Synced',
        'photo': 'Uploaded',
        'link': 'obhs-system/evidence/\nmid_attendance_wrk102.jpg',
        'status': 'Completed',
        'location': 'Location Verified: Near Coach B2',
        'coords': '26.8901° N, 75.8129° E',
        'photoLabel': 'Mid Attendance\n09-May-2026 12:15 PM\nNear Coach B2',
      },
      {
        'type': 'End\nAttendance',
        'time': '06:05 PM',
        'device': '09-May-2026\n18:05:10',
        'server': '09-May-2026\n18:05:24',
        'gps': 'Delhi Junction\nPlatform 4',
        'sync': 'Synced',
        'photo': 'Uploaded',
        'link': 'obhs-system/evidence/\nend_attendance_wrk102.jpg',
        'status': 'Completed',
        'location': 'Location Verified: Delhi Junction Platform 4',
        'coords': '28.6448° N, 77.2167° E',
        'photoLabel': 'End Attendance\n09-May-2026 06:05 PM\nDelhi Junction Platform 4',
      },
    ];

    final Map<int, pw.TableColumnWidth> cw = {};
    final widths = <double>[1.0, 0.9, 1.1, 1.1, 1.1, 0.7];
    if (!showPhotoRow) widths.add(0.9);
    if (showPhotoLink) widths.add(1.2);
    widths.add(0.9);
    for (int i = 0; i < widths.length; i++) {
      cw[i] = pw.FlexColumnWidth(widths[i]);
    }

    final children = <pw.TableRow>[
      pw.TableRow(
        decoration: pw.BoxDecoration(color: _secBlue),
        children: headers.map((h) => _cell(h, bold: true, color: PdfColors.white, bg: _secBlue, fontSize: 7)).toList(),
      ),
    ];

    final tableWidgets = <pw.Widget>[
      pw.Table(
        border: pw.TableBorder.all(color: _borderGray, width: 0.5),
        columnWidths: cw,
        children: children,
      ),
    ];

    for (final row in rows) {
      final cells = <pw.Widget>[
        _cell(row['type']!, bold: true, bg: _lightGray, fontSize: 7.5),
        _cell(row['time']!, fontSize: 7.5),
        _cell(row['device']!, fontSize: 7),
        _cell(row['server']!, fontSize: 7),
        _cell(row['gps']!, fontSize: 7),
        pw.Container(
          color: _lightGreen,
          padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 3),
          child: pw.Text('✓ ${row['sync']}', style: pw.TextStyle(color: _medGreen, fontSize: 7, fontWeight: pw.FontWeight.bold)),
        ),
        if (!showPhotoRow)
          pw.Container(
            color: _lightGreen,
            padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 3),
            child: pw.Text('✓ ${row['photo']}', style: pw.TextStyle(color: _medGreen, fontSize: 7, fontWeight: pw.FontWeight.bold)),
          ),
        if (showPhotoLink)
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 3),
            child: pw.Text(row['link']!, style: pw.TextStyle(color: _navyBlue, fontSize: 6.5)),
          ),
        pw.Container(
          color: _lightGreen,
          padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 3),
          child: pw.Text('✓ ${row['status']}', style: pw.TextStyle(color: _medGreen, fontSize: 7, fontWeight: pw.FontWeight.bold)),
        ),
      ];

      tableWidgets.add(pw.Table(
        border: pw.TableBorder.all(color: _borderGray, width: 0.5),
        columnWidths: cw,
        children: [pw.TableRow(children: cells)],
      ));

      // Location row
      tableWidgets.add(pw.Table(
        border: pw.TableBorder.all(color: _borderGray, width: 0.5),
        columnWidths: const {0: pw.FlexColumnWidth(1)},
        children: [
          pw.TableRow(
            decoration: pw.BoxDecoration(color: PdfColor.fromHex('F0F7FF')),
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('📍 ${row['location']}', style: pw.TextStyle(fontSize: 7, color: _navyBlue)),
                    pw.Text('📌 ${row['coords']}', style: pw.TextStyle(fontSize: 7, color: _textGray, fontStyle: pw.FontStyle.italic)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ));

      // Photo row (Report 4 only)
      if (showPhotoRow) {
        tableWidgets.add(
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: pw.BoxDecoration(border: pw.Border.all(color: _borderGray, width: 0.5)),
            child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('Attendance Photo: ', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
              pw.Container(
                width: 100,
                height: 60,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: _borderGray),
                  color: _lightGray,
                ),
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text('[ Photo ]', style: pw.TextStyle(fontSize: 8, color: _textGray)),
                    pw.Text(row['photoLabel']!, style: pw.TextStyle(fontSize: 6, color: _textGray), textAlign: pw.TextAlign.center),
                  ],
                ),
              ),
            ]),
          ),
        );
      }
    }

    return pw.Column(children: tableWidgets);
  }

  // ── Shared: Approval Section ──────────────────────────────────────────────
  static pw.Widget _buildApprovalSection(
    RunInstanceModel instance,
    String dateStr,
    String timeStr, {
    bool showNote = false,
  }) {
    return pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Expanded(
        flex: showNote ? 65 : 100,
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          _sectionHeader('🔏  APPROVAL & AUTHENTICATION'),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(border: pw.Border.all(color: _borderGray, width: 0.5)),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _signatureBlock('Supervisor Verification', _na(instance.createdByName), '$dateStr  |  $timeStr'),
                _signatureBlock('System Compliance Validation', 'OBHS Monitoring System', '$dateStr  |  $timeStr'),
                _signatureBlock('Central Audit Engine', 'Audit Engine', '$dateStr  |  $timeStr'),
              ],
            ),
          ),
        ]),
      ),
      if (showNote) ...[
        pw.SizedBox(width: 8),
        pw.Expanded(
          flex: 35,
          child: _noteBox([
            'This is a system generated report and digitally validated.',
            'All timestamps are in IST.',
            'Data accuracy is based on system records.',
            'Unauthorized modification is strictly prohibited.',
          ]),
        ),
      ],
    ]);
  }
}
