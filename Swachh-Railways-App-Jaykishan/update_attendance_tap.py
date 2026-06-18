import sys
import re

def update_file(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Add import
    if "import 'obhs_attendance_screen.dart';" not in content:
        content = content.replace("import 'package:provider/provider.dart';", "import 'package:provider/provider.dart';\nimport 'obhs_attendance_screen.dart';")

    # Replace the block
    pattern = r'(              // Attendance Status Chip\n              )Container\([\s\S]*?            \],'
    
    match = re.search(pattern, content)
    if match:
        old_block = match.group(0)
        
        # We know the block ends with "            ]," which is the closing of the Row children.
        # Wait, the Container ends with "              )," 
        # Let's just hardcode the exact string we want to replace.
        
        old_str = '''              // Attendance Status Chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.greenAccent.withOpacity(0.5)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.fingerprint, color: Colors.greenAccent, size: 14),
                    SizedBox(width: 4),
                    Text('PRESENT', style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),'''

        new_str = '''              // Attendance Status Chip
              InkWell(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ObhsAttendanceScreen(user: widget.user)));
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.greenAccent.withOpacity(0.5)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.fingerprint, color: Colors.greenAccent, size: 14),
                      SizedBox(width: 4),
                      Text('PRESENT', style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),'''

        content = content.replace(old_str, new_str)

        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)

update_file('lib/view/obhs_screens/mcc/janitor_home_screen.dart')
update_file('lib/view/obhs_screens/mcc/attendant_home_screen.dart')
