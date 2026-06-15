import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:crm_train/utills/app_colors.dart';

class PremisesCleaningExcelDownloader extends StatelessWidget {
  const PremisesCleaningExcelDownloader({super.key});

  Future<void> downloadPremisesCleaningExcel() async {
    final workbook = xlsio.Workbook();
    final sheet = workbook.worksheets[0];

    final headerStyle = workbook.styles.add('headerStyle')
      ..backColor = '#1F4E78'
      ..fontColor = '#FFFFFF'
      ..bold = true
      ..hAlign = xlsio.HAlignType.center
      ..vAlign = xlsio.VAlignType.center
      ..wrapText = true
      ..borders.all.lineStyle = xlsio.LineStyle.thin;

    final cellStyle = workbook.styles.add('cellStyle')
      ..hAlign = xlsio.HAlignType.center
      ..vAlign = xlsio.VAlignType.center
      ..borders.all.lineStyle = xlsio.LineStyle.thin;

    sheet.getRangeByName('A1').setText('Date');
    sheet.getRangeByName('B1').setText('Premise Name');
    sheet.getRangeByName('C1').setText('Total Area in Sq Mtrs');
    sheet.getRangeByName('D1').setText('Area attended for Cleaning');
    sheet.getRangeByName('E1').setText('Area Not Attended / Not Cleaned');
    sheet.getRangeByName('F1').setText('Rating of Cleaning on the Day in %');

    sheet.getRangeByName('G1').setText('Housekeeping Score');
    sheet.getRangeByName('H1').setText('Pit-Line Score');
    sheet.getRangeByName('I1').setText('Garbage Score');
    sheet.getRangeByName('J1').setText('Overall Score');
    sheet.getRangeByName('K1').setText('90%+');

    sheet.getRangeByName('L1:N1').merge();
    sheet.getRangeByName('L1').setText('Penalty for Cleaning having rating');

    sheet.getRangeByName('L2').setText('81% to 90%');
    sheet.getRangeByName('M2').setText('71% to 80%');
    sheet.getRangeByName('N2').setText('70% and below');

    sheet.getRangeByName('A1:K1').cellStyle = headerStyle; // main headers
    sheet.getRangeByName('L1').cellStyle = headerStyle; // merged penalty header
    sheet.getRangeByName('L2:N2').cellStyle = headerStyle; // subheaders under penalty

    sheet.getRangeByName('A1:N2').rowHeight = 30;

    sheet.getRangeByName('A1').columnWidth = 15;
    sheet.getRangeByName('B1').columnWidth = 20;
    sheet.getRangeByName('C1').columnWidth = 20;
    sheet.getRangeByName('D1').columnWidth = 22;
    sheet.getRangeByName('E1').columnWidth = 25;
    sheet.getRangeByName('F1').columnWidth = 25;
    sheet.getRangeByName('G1').columnWidth = 20;
    sheet.getRangeByName('H1').columnWidth = 20;
    sheet.getRangeByName('I1').columnWidth = 20;
    sheet.getRangeByName('J1').columnWidth = 20;
    sheet.getRangeByName('K1').columnWidth = 10;
    for (int i = 12; i <= 14; i++) {
      sheet.getRangeByIndex(1, i).columnWidth = 15;
    }

    sheet.getRangeByIndex(3, 1).setText('31-10-2025');
    sheet.getRangeByIndex(3, 2).setText('Station A');
    sheet.getRangeByIndex(3, 3).setText('1200');
    sheet.getRangeByIndex(3, 4).setText('1100');
    sheet.getRangeByIndex(3, 5).setText('100');
    sheet.getRangeByIndex(3, 6).setText('92%');
    sheet.getRangeByIndex(3, 7).setText('94%');
    sheet.getRangeByIndex(3, 8).setText('93%');
    sheet.getRangeByIndex(3, 9).setText('96%');
    sheet.getRangeByIndex(3, 10).setText('95%');
    sheet.getRangeByIndex(3, 11).setText('Yes');
    sheet.getRangeByIndex(3, 12).setText('NA');
    sheet.getRangeByIndex(3, 13).setText('NA');
    sheet.getRangeByIndex(3, 14).setText('NA');

    sheet.getRangeByName('A3:N3').cellStyle = cellStyle;

    final bytes = workbook.saveAsStream();
    workbook.dispose();

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/Premises_Cleaning_Report.xlsx');
    await file.writeAsBytes(bytes, flush: true);
    await OpenFilex.open(file.path);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: downloadPremisesCleaningExcel,
      child: Icon(Icons.download, color: kRailwayBlue),
    );
  }
}
