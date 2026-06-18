import 'dart:io';
import 'dart:typed_data';
import 'package:crm_train/utills/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:intl/intl.dart';

class CoachCleaningReportExcelDownload extends StatelessWidget {
  const CoachCleaningReportExcelDownload({super.key});

  Future<void> downloadExcelTemplate() async {
    final workbook = xlsio.Workbook();
    final sheet = workbook.worksheets[0];
    sheet.name = 'Coach Cleaning Report';

    // ── Branded Header ─────────────────────────────────────────────────────
    // Row 1: Logo col + Railway title
    sheet.getRangeByIndex(1, 1).rowHeight = 50;
    try {
      final ByteData bytes = await rootBundle.load('assets/images/image.png');
      final Uint8List byteList = bytes.buffer.asUint8List();
      final xlsio.Picture picture = sheet.pictures.addStream(1, 1, byteList);
      picture.height = 44;
      picture.width = 44;
    } catch (_) {/* logo not found — skip */}

    final logoColStyle = workbook.styles.add('logoColStyle')
      ..backColor = '#0D2C6B'
      ..fontColor = '#FFFFFF'
      ..bold = true
      ..fontSize = 14
      ..hAlign = xlsio.HAlignType.center
      ..vAlign = xlsio.VAlignType.center;
    sheet.getRangeByIndex(1, 1).cellStyle = logoColStyle;

    sheet.getRangeByIndex(1, 2, 1, 41).merge();
    final railwayTitleStyle = workbook.styles.add('railwayTitleStyle')
      ..backColor = '#0D2C6B'
      ..fontColor = '#FFFFFF'
      ..bold = true
      ..fontSize = 14
      ..hAlign = xlsio.HAlignType.left
      ..vAlign = xlsio.VAlignType.center;
    sheet.getRangeByIndex(1, 2).cellStyle = railwayTitleStyle;
    sheet.getRangeByIndex(1, 2).setText('  Indian Railways – OBHS Enterprise Monitoring System');

    // Row 2: Report title (full width)
    sheet.getRangeByIndex(2, 1, 2, 41).merge();
    final reportTitleStyle = workbook.styles.add('reportTitleStyle')
      ..backColor = '#1A3E8C'
      ..fontColor = '#FFFFFF'
      ..bold = true
      ..fontSize = 12
      ..hAlign = xlsio.HAlignType.center
      ..vAlign = xlsio.VAlignType.center;
    sheet.getRangeByIndex(2, 1).cellStyle = reportTitleStyle;
    sheet.getRangeByIndex(2, 1).setText('COACH CLEANING INSPECTION REPORT');
    sheet.getRangeByIndex(2, 1).rowHeight = 26;

    // Row 3: Generated on + badge
    sheet.getRangeByIndex(3, 1, 3, 34).merge();
    final genStyle = workbook.styles.add('genStyle')
      ..fontSize = 8
      ..italic = true
      ..hAlign = xlsio.HAlignType.left
      ..vAlign = xlsio.VAlignType.center;
    sheet.getRangeByIndex(3, 1).cellStyle = genStyle;
    sheet.getRangeByIndex(3, 1).setText('  Generated On: ${DateFormat('dd-MMM-yyyy hh:mm a').format(DateTime.now())}');
    sheet.getRangeByIndex(3, 35, 3, 41).merge();
    final badgeStyle = workbook.styles.add('badgeStyle')
      ..backColor = '#C8A400'
      ..fontColor = '#0D2C6B'
      ..bold = true
      ..fontSize = 9
      ..hAlign = xlsio.HAlignType.center
      ..vAlign = xlsio.VAlignType.center;
    sheet.getRangeByIndex(3, 35).cellStyle = badgeStyle;
    sheet.getRangeByIndex(3, 35).setText('OFFICIAL REPORT');
    sheet.getRangeByIndex(3, 1).rowHeight = 18;
    // ── Blank separator row ───────────────────────────────────────────────
    sheet.getRangeByIndex(4, 1).rowHeight = 8;
    // Data headers start at row 5
    // ──────────────────────────────────────────────────────────────────────

    final centerStyle = workbook.styles.add('centerStyle')
      ..hAlign = xlsio.HAlignType.center
      ..vAlign = xlsio.VAlignType.center
      ..bold = true
      ..wrapText = true
      ..borders.all.lineStyle = xlsio.LineStyle.thin;

    final yellowHeader = workbook.styles.add('yellowHeader')
      ..backColor = '#FFF3CD'
      ..bold = true
      ..hAlign = xlsio.HAlignType.center
      ..vAlign = xlsio.VAlignType.center
      ..borders.all.lineStyle = xlsio.LineStyle.thin;

    final purpleHeader = workbook.styles.add('purpleHeader')
      ..backColor = '#9966CC'
      ..fontColor = '#FFFFFF'
      ..bold = true
      ..hAlign = xlsio.HAlignType.center
      ..vAlign = xlsio.VAlignType.center
      ..borders.all.lineStyle = xlsio.LineStyle.thin;

    final lightBlueHeader = workbook.styles.add('lightBlueHeader')
      ..backColor = '#CCE5FF'
      ..bold = true
      ..hAlign = xlsio.HAlignType.center
      ..vAlign = xlsio.VAlignType.center
      ..borders.all.lineStyle = xlsio.LineStyle.thin;

    final whiteHeader = workbook.styles.add('whiteHeader')
      ..backColor = '#F5F5F5'
      ..bold = true
      ..hAlign = xlsio.HAlignType.center
      ..vAlign = xlsio.VAlignType.center
      ..borders.all.lineStyle = xlsio.LineStyle.thin;


    // Data headers — offset by 4 rows for our branded header
    final int headerOffset = 4; // rows 1-4 are the branded header

    sheet.getRangeByIndex(headerOffset + 1, 1, headerOffset + 3, 1).merge();
    sheet.getRangeByIndex(headerOffset + 1, 1).setText('Date');
    sheet.getRangeByIndex(headerOffset + 1, 1).cellStyle = whiteHeader;

    sheet.getRangeByIndex(headerOffset + 1, 2, headerOffset + 3, 2).merge();
    sheet.getRangeByIndex(headerOffset + 1, 2).setText('Train No.');
    sheet.getRangeByIndex(headerOffset + 1, 2).cellStyle = whiteHeader;

    sheet.getRangeByIndex(headerOffset + 1, 3, headerOffset + 3, 3).merge();
    sheet.getRangeByIndex(headerOffset + 1, 3).setText('TYPE OF WORK\n(PRIMARY/\nSECONDARY/ RBPC WITH\nM/C / RBPC\nWITHOUT M/C');
    sheet.getRangeByIndex(headerOffset + 1, 3).cellStyle = whiteHeader;

    sheet.getRangeByIndex(headerOffset + 1, 4, headerOffset + 3, 4).merge();
    sheet.getRangeByIndex(headerOffset + 1, 4).setText('WITH OR\nWITHOUT\nACWP');
    sheet.getRangeByIndex(headerOffset + 1, 4).cellStyle = whiteHeader;

    sheet.getRangeByIndex(headerOffset + 1, 5, headerOffset + 1, 8).merge();
    sheet.getRangeByIndex(headerOffset + 1, 5).setText('Internal Cleaning');
    sheet.getRangeByIndex(headerOffset + 1, 5).cellStyle = yellowHeader;

    sheet.getRangeByIndex(headerOffset + 1, 9, headerOffset + 1, 12).merge();
    sheet.getRangeByIndex(headerOffset + 1, 9).setText('Internal Cleaning');
    sheet.getRangeByIndex(headerOffset + 1, 9).cellStyle = yellowHeader;

    sheet.getRangeByIndex(headerOffset + 1, 13, headerOffset + 1, 16).merge();
    sheet.getRangeByIndex(headerOffset + 1, 13).setText('Internal Cleaning');
    sheet.getRangeByIndex(headerOffset + 1, 13).cellStyle = yellowHeader;

    sheet.getRangeByIndex(headerOffset + 1, 17, headerOffset + 1, 20).merge();
    sheet.getRangeByIndex(headerOffset + 1, 17).setText('Intensive Cleaning');
    sheet.getRangeByIndex(headerOffset + 1, 17).cellStyle = yellowHeader;

    sheet.getRangeByIndex(headerOffset + 1, 21, headerOffset + 1, 24).merge();
    sheet.getRangeByIndex(headerOffset + 1, 21).setText('External Cleaning');
    sheet.getRangeByIndex(headerOffset + 1, 21).cellStyle = purpleHeader;

    sheet.getRangeByIndex(headerOffset + 1, 25, headerOffset + 1, 28).merge();
    sheet.getRangeByIndex(headerOffset + 1, 25).setText('External Cleaning');
    sheet.getRangeByIndex(headerOffset + 1, 25).cellStyle = purpleHeader;

    sheet.getRangeByIndex(headerOffset + 1, 29, headerOffset + 1, 31).merge();
    sheet.getRangeByIndex(headerOffset + 1, 29).setText('Toiletries');
    sheet.getRangeByIndex(headerOffset + 1, 29).cellStyle = lightBlueHeader;

    sheet.getRangeByIndex(headerOffset + 1, 32, headerOffset + 1, 34).merge();
    sheet.getRangeByIndex(headerOffset + 1, 32).setText('Watering');
    sheet.getRangeByIndex(headerOffset + 1, 32).cellStyle = lightBlueHeader;

    sheet.getRangeByIndex(headerOffset + 1, 35, headerOffset + 1, 37).merge();
    sheet.getRangeByIndex(headerOffset + 1, 35).setText('Door Locking');
    sheet.getRangeByIndex(headerOffset + 1, 35).cellStyle = lightBlueHeader;

    sheet.getRangeByIndex(headerOffset + 1, 38, headerOffset + 3, 38).merge();
    sheet.getRangeByIndex(headerOffset + 1, 38).setText('ACTUAL MANPOWER (with ACWP)');
    sheet.getRangeByIndex(headerOffset + 1, 38).cellStyle = whiteHeader;

    sheet.getRangeByIndex(headerOffset + 1, 39, headerOffset + 3, 39).merge();
    sheet.getRangeByIndex(headerOffset + 1, 39).setText('ACTUAL MANPOWER (without ACWP)');
    sheet.getRangeByIndex(headerOffset + 1, 39).cellStyle = whiteHeader;

    sheet.getRangeByIndex(headerOffset + 1, 40, headerOffset + 3, 40).merge();
    sheet.getRangeByIndex(headerOffset + 1, 40).setText('MANPOWER SHORTAGE');
    sheet.getRangeByIndex(headerOffset + 1, 40).cellStyle = whiteHeader;

    sheet.getRangeByIndex(headerOffset + 1, 41, headerOffset + 3, 41).merge();
    sheet.getRangeByIndex(headerOffset + 1, 41).setText('Machine SHORTAGE');
    sheet.getRangeByIndex(headerOffset + 1, 41).cellStyle = whiteHeader;

    sheet.getRangeByIndex(headerOffset + 2, 5, headerOffset + 2, 8).merge();
    sheet.getRangeByIndex(headerOffset + 2, 5).setText('Primary or Secondary');
    sheet.getRangeByIndex(headerOffset + 2, 5).cellStyle = yellowHeader;

    sheet.getRangeByIndex(headerOffset + 2, 9, headerOffset + 2, 12).merge();
    sheet.getRangeByIndex(headerOffset + 2, 9).setText('RBPC With Machine');
    sheet.getRangeByIndex(headerOffset + 2, 9).cellStyle = yellowHeader;

    sheet.getRangeByIndex(headerOffset + 2, 13, headerOffset + 2, 16).merge();
    sheet.getRangeByIndex(headerOffset + 2, 13).setText('RBPC Without Machine');
    sheet.getRangeByIndex(headerOffset + 2, 13).cellStyle = yellowHeader;

    sheet.getRangeByIndex(headerOffset + 2, 17, headerOffset + 2, 20).merge();
    sheet.getRangeByIndex(headerOffset + 2, 17).setText('Without ACWP');
    sheet.getRangeByIndex(headerOffset + 2, 17).cellStyle = yellowHeader;

    sheet.getRangeByIndex(headerOffset + 2, 21, headerOffset + 2, 24).merge();
    sheet.getRangeByIndex(headerOffset + 2, 21).setText('With ACWP');
    sheet.getRangeByIndex(headerOffset + 2, 21).cellStyle = purpleHeader;

    sheet.getRangeByIndex(headerOffset + 2, 25, headerOffset + 2, 28).merge();
    sheet.getRangeByIndex(headerOffset + 2, 25).setText('Without ACWP');
    sheet.getRangeByIndex(headerOffset + 2, 25).cellStyle = purpleHeader;

    sheet.getRangeByIndex(headerOffset + 2, 29, headerOffset + 2, 31).merge();
    sheet.getRangeByIndex(headerOffset + 2, 29).cellStyle = lightBlueHeader;

    sheet.getRangeByIndex(headerOffset + 2, 32, headerOffset + 2, 34).merge();
    sheet.getRangeByIndex(headerOffset + 2, 32).cellStyle = lightBlueHeader;

    sheet.getRangeByIndex(headerOffset + 2, 35, headerOffset + 2, 37).merge();
    sheet.getRangeByIndex(headerOffset + 2, 35).cellStyle = lightBlueHeader;


    final subHeaders = ['A', 'B', 'C', 'D', 'NA'];

    for (int i = 0; i < 4; i++) {
      sheet.getRangeByIndex(headerOffset + 3, 5 + i).setText(subHeaders[i]);
      sheet.getRangeByIndex(headerOffset + 3, 5 + i).cellStyle = yellowHeader;
    }

    for (int i = 0; i < 4; i++) {
      sheet.getRangeByIndex(headerOffset + 3, 9 + i).setText(subHeaders[i]);
      sheet.getRangeByIndex(headerOffset + 3, 9 + i).cellStyle = yellowHeader;
    }

    for (int i = 0; i < 4; i++) {
      sheet.getRangeByIndex(headerOffset + 3, 13 + i).setText(subHeaders[i]);
      sheet.getRangeByIndex(headerOffset + 3, 13 + i).cellStyle = yellowHeader;
    }

    for (int i = 0; i < 4; i++) {
      sheet.getRangeByIndex(headerOffset + 3, 17 + i).setText(subHeaders[i]);
      sheet.getRangeByIndex(headerOffset + 3, 17 + i).cellStyle = yellowHeader;
    }

    for (int i = 0; i < 5; i++) {
      sheet.getRangeByIndex(headerOffset + 3, 21 + i).setText(subHeaders[i]);
      sheet.getRangeByIndex(headerOffset + 3, 21 + i).cellStyle = purpleHeader;
    }

    for (int i = 0; i < 4; i++) {
      sheet.getRangeByIndex(headerOffset + 3, 25 + i).setText(subHeaders[i]);
      sheet.getRangeByIndex(headerOffset + 3, 25 + i).cellStyle = purpleHeader;
    }


    final yesNoNaHeaders = ['Yes', 'No', 'NA'];

    for (int i = 0; i < 3; i++) {
      sheet.getRangeByIndex(headerOffset + 3, 29 + i).setText(yesNoNaHeaders[i]);
      sheet.getRangeByIndex(headerOffset + 3, 29 + i).cellStyle = lightBlueHeader;
    }

    for (int i = 0; i < 3; i++) {
      sheet.getRangeByIndex(headerOffset + 3, 32 + i).setText(yesNoNaHeaders[i]);
      sheet.getRangeByIndex(headerOffset + 3, 32 + i).cellStyle = lightBlueHeader;
    }

    for (int i = 0; i < 3; i++) {
      sheet.getRangeByIndex(headerOffset + 3, 35 + i).setText(yesNoNaHeaders[i]);
      sheet.getRangeByIndex(headerOffset + 3, 35 + i).cellStyle = lightBlueHeader;
    }

    // Column widths
    sheet.getRangeByIndex(1, 1).columnWidth = 10;
    sheet.getRangeByIndex(1, 2).columnWidth = 12;
    sheet.getRangeByIndex(1, 3).columnWidth = 20;
    sheet.getRangeByIndex(1, 4).columnWidth = 15;

    for (int i = 5; i <= 37; i++) {
      sheet.getRangeByIndex(1, i).columnWidth = 5;
    }

    sheet.getRangeByIndex(1, 38).columnWidth = 18;
    sheet.getRangeByIndex(1, 39).columnWidth = 18;
    sheet.getRangeByIndex(1, 40).columnWidth = 15;
    sheet.getRangeByIndex(1, 41).columnWidth = 15;


    final dataStyle = workbook.styles.add('dataStyle')
      ..hAlign = xlsio.HAlignType.center
      ..vAlign = xlsio.VAlignType.center
      ..borders.all.lineStyle = xlsio.LineStyle.thin;

    final yellowDataStyle = workbook.styles.add('yellowDataStyle')
      ..backColor = '#FFFFFF'
      ..hAlign = xlsio.HAlignType.center
      ..vAlign = xlsio.VAlignType.center
      ..borders.all.lineStyle = xlsio.LineStyle.thin;


    for (int row = headerOffset + 4; row <= headerOffset + 5; row++) {
      for (int col = 1; col <= 4; col++) {
        sheet.getRangeByIndex(row, col).cellStyle = dataStyle;
      }

      for (int col = 5; col <= 28; col++) {
        sheet.getRangeByIndex(row, col).cellStyle = yellowDataStyle;
      }

      for (int col = 29; col <= 37; col++) {
        sheet.getRangeByIndex(row, col).cellStyle = dataStyle;
      }

      for (int col = 38; col <= 41; col++) {
        sheet.getRangeByIndex(row, col).cellStyle = dataStyle;
      }
    }

    // Sample data row (offset for header)
    sheet.getRangeByIndex(headerOffset + 4, 1).setText('18-Apr');
    sheet.getRangeByIndex(headerOffset + 4, 2).setText('11037');
    sheet.getRangeByIndex(headerOffset + 4, 3).setText('Value selected dropdown');
    sheet.getRangeByIndex(headerOffset + 4, 4).setText('Value selected dropdown');
    sheet.getRangeByIndex(headerOffset + 4, 38).setText('6');

    // Footer
    final int footerRow = headerOffset + 7;
    sheet.getRangeByIndex(footerRow, 1, footerRow, 41).merge();
    final footerStyle = workbook.styles.add('footerBarStyle')
      ..backColor = '#0D2C6B'
      ..fontColor = '#C8A400'
      ..fontSize = 8
      ..italic = true
      ..hAlign = xlsio.HAlignType.center
      ..vAlign = xlsio.VAlignType.center;
    sheet.getRangeByIndex(footerRow, 1).cellStyle = footerStyle;
    sheet.getRangeByIndex(footerRow, 1).setText(
        '  Indian Railways – OBHS Enterprise Monitoring System   |   Generated: ${DateFormat('dd-MMM-yyyy hh:mm a').format(DateTime.now())}');
    sheet.getRangeByIndex(footerRow, 1).rowHeight = 18;


    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/Coach_Cleaning_Report.xlsx';
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);

    await OpenFilex.open(file.path);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: downloadExcelTemplate,
      child: Icon(Icons.download, color: kRailwayBlue),
    );
  }
}