import sys

file_path = r'lib\view\obhs_screens\obhs_runs_list_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("if (coach.tasks != null && coach.tasks!.isNotEmpty)", "if ((coach.janitorTasks != null && coach.janitorTasks!.isNotEmpty) || (coach.attendantTasks != null && coach.attendantTasks!.isNotEmpty))")
content = content.replace("child: Text('Tasks: ${coach.tasks!.join(', ')}',", "child: Text('Tasks: ${[...(coach.janitorTasks ?? []), ...(coach.attendantTasks ?? [])].join(', ')}',")

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
