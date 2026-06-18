import os
import re

lib_dir = 'lib'

for root, dirs, files in os.walk(lib_dir):
    for file in files:
        if file.endswith('.dart'):
            file_path = os.path.join(root, file)
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            if 'workerId' in content or 'workerName' in content or 'assignedWorkerId' in content:
                # Replace properties
                content = content.replace('.workerId', '.janitorId')
                content = content.replace('.workerName', '.janitorName')
                content = content.replace("['workerId']", "['janitorId']")
                content = content.replace("['workerName']", "['janitorName']")
                content = content.replace("workerId:", "janitorId:")
                content = content.replace("workerName:", "janitorName:")
                content = content.replace("assignedWorkerId", "assignedJanitorId")
                
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(content)
                    
            if 'tasks' in content and 'run_instance_model.dart' not in file_path:
                # Replace coach.tasks
                content = content.replace('.tasks', '.janitorTasks') # Default mapping, then I will manually check
                # Note: `tasks` is used broadly, so I will only manually update it in obhs_runs_list_screen.dart and ca_manage_assignments_screen.dart where coach.tasks is used.
                pass
