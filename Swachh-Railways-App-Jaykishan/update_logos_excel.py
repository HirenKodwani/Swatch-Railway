import sys

file_path = 'lib/view/common_railways/report_excel_format/obhs_report_excel.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("await rootBundle.load('assets/images/mirtha.jpg')", "await rootBundle.load('assets/images/image.png')")
content = content.replace("await rootBundle.load('assets/images/swachh_bharat.png')", "await rootBundle.load('assets/images/mirtha.jpg')")

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
