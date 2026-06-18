import sys

file_path = 'lib/services/pdf_report_service.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("await rootBundle.load('assets/images/mirtha.jpg')", "await rootBundle.load('assets/images/image.png')")
content = content.replace("static Future<pw.ImageProvider> _getMirthaLogo()", "static Future<pw.ImageProvider> _getRailwayLogo()")

content = content.replace("await rootBundle.load('assets/images/swachh_bharat.png')", "await rootBundle.load('assets/images/mirtha.jpg')")
content = content.replace("static Future<pw.ImageProvider> _getSwachhBharatLogo()", "static Future<pw.ImageProvider> _getMirthaLogo()")

content = content.replace("final mirtha = await _getMirthaLogo();", "final railway = await _getRailwayLogo();")
content = content.replace("final swachh = await _getSwachhBharatLogo();", "final mirtha = await _getMirthaLogo();")

content = content.replace("_buildHeader(mirtha, swachh,", "_buildHeader(railway, mirtha,")

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
