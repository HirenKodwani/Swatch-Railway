import 'dart:io';
import 'package:crm_train/utills/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class CoachCleaningReportExcelDownload extends StatelessWidget {
  const CoachCleaningReportExcelDownload({super.key});

  Future<void> downloadExcelTemplate() async {
    final workbook = xlsio.Workbook();
    final sheet = workbook.worksheets[0];


    final centerStyle = workbook.styles.add('centerStyle')
      ..hAlign = xlsio.HAlignType.center
      ..vAlign = xlsio.VAlignType.center
      ..bold = true
      ..wrapText = true
      ..borders.all.lineStyle = xlsio.LineStyle.thin;

    final yellowHeader = workbook.styles.add('yellowHeader')
      ..backColor = '#FFFFFF'
      ..bold = true
      ..hAlign = xlsio.HAlignType.center
      ..vAlign = xlsio.VAlignType.center
      ..borders.all.lineStyle = xlsio.LineStyle.thin;

    final purpleHeader = workbook.styles.add('purpleHeader')
      ..backColor = '#9966CC'
      ..bold = true
      ..hAlign = xlsio.HAlignType.center
      ..vAlign = xlsio.VAlignType.center
      ..borders.all.lineStyle = xlsio.LineStyle.thin;

    final lightBlueHeader = workbook.styles.add('lightBlueHeader')
      ..backColor = '#ADD8E6'
      ..bold = true
      ..hAlign = xlsio.HAlignType.center
      ..vAlign = xlsio.VAlignType.center
      ..borders.all.lineStyle = xlsio.LineStyle.thin;

    final whiteHeader = workbook.styles.add('whiteHeader')
      ..backColor = '#FFFFFF'
      ..bold = true
      ..hAlign = xlsio.HAlignType.center
      ..vAlign = xlsio.VAlignType.center
      ..borders.all.lineStyle = xlsio.LineStyle.thin;


    sheet.getRangeByName('A1:A3').merge();
    sheet.getRangeByName('A1').setText('Date');
    sheet.getRangeByName('A1').cellStyle = whiteHeader;

    sheet.getRangeByName('B1:B3').merge();
    sheet.getRangeByName('B1').setText('Train No.');
    sheet.getRangeByName('B1').cellStyle = whiteHeader;

    sheet.getRangeByName('C1:C3').merge();
    sheet.getRangeByName('C1').setText('TYPE OF WORK\n(PRIMARY/\nSECONDARY/ RBPC WITH\nM/C / RBPC\nWITHOUT M/C');
    sheet.getRangeByName('C1').cellStyle = whiteHeader;

    sheet.getRangeByName('D1:D3').merge();
    sheet.getRangeByName('D1').setText('WITH OR\nWITHOUT\nACWP');
    sheet.getRangeByName('D1').cellStyle = whiteHeader;

    sheet.getRangeByName('E1:H1').merge();
    sheet.getRangeByName('E1').setText('Internal Cleaning');
    sheet.getRangeByName('E1').cellStyle = yellowHeader;

    sheet.getRangeByName('I1:L1').merge();
    sheet.getRangeByName('I1').setText('Internal Cleaning');
    sheet.getRangeByName('I1').cellStyle = yellowHeader;

    sheet.getRangeByName('M1:P1').merge();
    sheet.getRangeByName('M1').setText('Internal Cleaning');
    sheet.getRangeByName('M1').cellStyle = yellowHeader;

    sheet.getRangeByName('Q1:T1').merge();
    sheet.getRangeByName('Q1').setText('Intensive Cleaning');
    sheet.getRangeByName('Q1').cellStyle = yellowHeader;

    sheet.getRangeByName('U1:X1').merge();
    sheet.getRangeByName('U1').setText('External Cleaning');
    sheet.getRangeByName('U1').cellStyle = purpleHeader;

    sheet.getRangeByName('Y1:AB1').merge();
    sheet.getRangeByName('Y1').setText('External Cleaning');
    sheet.getRangeByName('Y1').cellStyle = purpleHeader;


    sheet.getRangeByName('AC1:AE1').merge();
    sheet.getRangeByName('AC1').setText('Toiletries');
    sheet.getRangeByName('AC1').cellStyle = lightBlueHeader;


    sheet.getRangeByName('AF1:AH1').merge();
    sheet.getRangeByName('AF1').setText('Watering');
    sheet.getRangeByName('AF1').cellStyle = lightBlueHeader;


    sheet.getRangeByName('AI1:AK1').merge();
    sheet.getRangeByName('AI1').setText('Door Locking');
    sheet.getRangeByName('AI1').cellStyle = lightBlueHeader;


    sheet.getRangeByName('AL1:AL3').merge();
    sheet.getRangeByName('AL1').setText('ACTUAL MANPOWER (with ACWP)');
    sheet.getRangeByName('AL1').cellStyle = whiteHeader;

    sheet.getRangeByName('AM1:AM3').merge();
    sheet.getRangeByName('AM1').setText('ACTUAL MANPOWER (without ACWP)');
    sheet.getRangeByName('AM1').cellStyle = whiteHeader;

    sheet.getRangeByName('AN1:AN3').merge();
    sheet.getRangeByName('AN1').setText('MANPOWER SHORTAGE');
    sheet.getRangeByName('AN1').cellStyle = whiteHeader;

    sheet.getRangeByName('AO1:AO3').merge();
    sheet.getRangeByName('AO1').setText('Machine SHORTAGE');
    sheet.getRangeByName('AO1').cellStyle = whiteHeader;


    sheet.getRangeByName('E2:H2').merge();
    sheet.getRangeByName('E2').setText('Primary or Secondary');
    sheet.getRangeByName('E2').cellStyle = yellowHeader;

    sheet.getRangeByName('I2:L2').merge();
    sheet.getRangeByName('I2').setText('RBPC With Machine');
    sheet.getRangeByName('I2').cellStyle = yellowHeader;

    sheet.getRangeByName('M2:P2').merge();
    sheet.getRangeByName('M2').setText('RBPC Without Machine');
    sheet.getRangeByName('M2').cellStyle = yellowHeader;

    sheet.getRangeByName('Q2:T2').merge();
    sheet.getRangeByName('Q2').setText('Without ACWP');
    sheet.getRangeByName('Q2').cellStyle = yellowHeader;

    sheet.getRangeByName('U2:X2').merge();
    sheet.getRangeByName('U2').setText('With ACWP');
    sheet.getRangeByName('U2').cellStyle = purpleHeader;

    sheet.getRangeByName('Y2:AB2').merge();
    sheet.getRangeByName('Y2').setText('Without ACWP');
    sheet.getRangeByName('Y2').cellStyle = purpleHeader;


    sheet.getRangeByName('AC2:AE2').merge();
    sheet.getRangeByName('AC2').cellStyle = lightBlueHeader;

    sheet.getRangeByName('AF2:AH2').merge();
    sheet.getRangeByName('AF2').cellStyle = lightBlueHeader;

    sheet.getRangeByName('AI2:AK2').merge();
    sheet.getRangeByName('AI2').cellStyle = lightBlueHeader;


    final subHeaders = ['A', 'B', 'C', 'D', 'NA'];


    for (int i = 0; i < 4; i++) {
      sheet.getRangeByIndex(3, 5 + i).setText(subHeaders[i]);
      sheet.getRangeByIndex(3, 5 + i).cellStyle = yellowHeader;
    }


    for (int i = 0; i < 4; i++) {
      sheet.getRangeByIndex(3, 9 + i).setText(subHeaders[i]);
      sheet.getRangeByIndex(3, 9 + i).cellStyle = yellowHeader;
    }


    for (int i = 0; i < 4; i++) {
      sheet.getRangeByIndex(3, 13 + i).setText(subHeaders[i]);
      sheet.getRangeByIndex(3, 13 + i).cellStyle = yellowHeader;
    }


    for (int i = 0; i < 4; i++) {
      sheet.getRangeByIndex(3, 17 + i).setText(subHeaders[i]);
      sheet.getRangeByIndex(3, 17 + i).cellStyle = yellowHeader;
    }


    for (int i = 0; i < 5; i++) {
      sheet.getRangeByIndex(3, 21 + i).setText(subHeaders[i]);
      sheet.getRangeByIndex(3, 21 + i).cellStyle = purpleHeader;
    }


    for (int i = 0; i < 4; i++) {
      sheet.getRangeByIndex(3, 25 + i).setText(subHeaders[i]);
      sheet.getRangeByIndex(3, 25 + i).cellStyle = purpleHeader;
    }


    final yesNoNaHeaders = ['Yes', 'No', 'NA'];


    for (int i = 0; i < 3; i++) {
      sheet.getRangeByIndex(3, 29 + i).setText(yesNoNaHeaders[i]);
      sheet.getRangeByIndex(3, 29 + i).cellStyle = lightBlueHeader;
    }


    for (int i = 0; i < 3; i++) {
      sheet.getRangeByIndex(3, 32 + i).setText(yesNoNaHeaders[i]);
      sheet.getRangeByIndex(3, 32 + i).cellStyle = lightBlueHeader;
    }


    for (int i = 0; i < 3; i++) {
      sheet.getRangeByIndex(3, 35 + i).setText(yesNoNaHeaders[i]);
      sheet.getRangeByIndex(3, 35 + i).cellStyle = lightBlueHeader;
    }


    sheet.getRangeByName('A1').columnWidth = 10;
    sheet.getRangeByName('B1').columnWidth = 12;
    sheet.getRangeByName('C1').columnWidth = 20;
    sheet.getRangeByName('D1').columnWidth = 15;


    for (int i = 5; i <= 37; i++) {
      sheet.getRangeByIndex(1, i).columnWidth = 5;
    }


    sheet.getRangeByName('AL1').columnWidth = 18;
    sheet.getRangeByName('AM1').columnWidth = 18;
    sheet.getRangeByName('AN1').columnWidth = 15;
    sheet.getRangeByName('AO1').columnWidth = 15;


    final dataStyle = workbook.styles.add('dataStyle')
      ..hAlign = xlsio.HAlignType.center
      ..vAlign = xlsio.VAlignType.center
      ..borders.all.lineStyle = xlsio.LineStyle.thin;

    final yellowDataStyle = workbook.styles.add('yellowDataStyle')
      ..backColor = '#FFFFFF'
      ..hAlign = xlsio.HAlignType.center
      ..vAlign = xlsio.VAlignType.center
      ..borders.all.lineStyle = xlsio.LineStyle.thin;


    for (int row = 4; row <= 5; row++) {
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


    sheet.getRangeByName('A4').setText('18-Apr');
    sheet.getRangeByName('B4').setText('11037');
    sheet.getRangeByName('C4').setText('Value selected dropdown');
    sheet.getRangeByName('D4').setText('Value selected dropdown');
    sheet.getRangeByName('AL4').setText('6');


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