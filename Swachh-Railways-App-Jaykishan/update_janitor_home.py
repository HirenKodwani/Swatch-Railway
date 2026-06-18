import sys
import re

file_path = 'lib/view/obhs_screens/mcc/janitor_home_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace _buildWelcomeBanner() call in build method
content = content.replace('_buildWelcomeBanner(),', '_buildHeaderAndOverview(),')

# Replace _buildWelcomeBanner() definition
pattern = r'  Widget _buildWelcomeBanner\(\) \{.*?(?=  Widget _buildEmptyState\(\) \{)'
match = re.search(pattern, content, re.DOTALL)

if match:
    old_banner = match.group(0)
    new_banner = '''  Widget _buildHeaderAndOverview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 30),
      decoration: const BoxDecoration(
        color: kRailwayBlue,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, ${widget.user.fullName}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Train: 12456 - ExpressB',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              // Attendance Status Chip
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
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildOverviewCard('Pending', '5', Icons.pending_actions, Colors.orange),
              _buildOverviewCard('Completed', '1', Icons.check_circle, Colors.green),
              _buildOverviewCard('Complaints', '0', Icons.report_problem, Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(String title, String count, IconData icon, Color color) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            count,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }

'''
    content = content.replace(old_banner, new_banner)
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
else:
    print("Could not find _buildWelcomeBanner()")

