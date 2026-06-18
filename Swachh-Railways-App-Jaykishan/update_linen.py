import sys
import re

file_path = 'lib/view/obhs_screens/mcc/attendant_linen_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace linenItems array
pattern = r'  final List<Map<String, dynamic>> linenItems = \[.*?\];'
new_linen = '''  final List<Map<String, dynamic>> linenItems = [
    {'item': 'Bedsheet', 'distributed': 0, 'returned': 0, 'missing': 0, 'damaged': 0, 'target': 72},
    {'item': 'Pillow Cover', 'distributed': 0, 'returned': 0, 'missing': 0, 'damaged': 0, 'target': 72},
    {'item': 'Blanket', 'distributed': 0, 'returned': 0, 'missing': 0, 'damaged': 0, 'target': 72},
    {'item': 'Towel', 'distributed': 0, 'returned': 0, 'missing': 0, 'damaged': 0, 'target': 72},
  ];'''
content = re.sub(pattern, new_linen, content, flags=re.DOTALL)

# Replace _buildLinenItemCard completely to show the new counters
pattern2 = r'  Widget _buildLinenItemCard\(Map<String, dynamic> item\) \{.*?  Widget _buildCounterRow'
new_card = '''  Widget _buildLinenItemCard(Map<String, dynamic> item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_laundry_service, color: kRailwayBlue),
                const SizedBox(width: 8),
                Text(
                  item['item'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Target: ${item['target']}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Distribution', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const Divider(),
            _buildCounterRow('Distributed', item['distributed'], (newVal) {
              setState(() => item['distributed'] = newVal);
            }),
            const SizedBox(height: 16),
            const Text('Collection Status', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const Divider(),
            _buildCounterRow('Returned (Clean)', item['returned'], (newVal) {
              setState(() => item['returned'] = newVal);
            }),
            _buildCounterRow('Missing', item['missing'], (newVal) {
              setState(() => item['missing'] = newVal);
            }),
            _buildCounterRow('Damaged', item['damaged'], (newVal) {
              setState(() => item['damaged'] = newVal);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCounterRow'''
content = re.sub(pattern2, new_card, content, flags=re.DOTALL)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
