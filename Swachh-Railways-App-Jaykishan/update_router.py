import sys

file_path = 'lib/view/obhs_screens/mcc/obhs_mcc_router.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("import 'attendant_linen_screen.dart';", "import 'attendant_linen_screen.dart';\nimport 'attendant_home_screen.dart';")
content = content.replace("return AttendantLinenScreen(user: user);", "return AttendantHomeScreen(user: user);")

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
