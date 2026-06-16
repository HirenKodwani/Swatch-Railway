import 'package:flutter/material.dart';
import 'package:crm_train/utills/app_colors.dart';

class ScorecardsScreen extends StatefulWidget {
  const ScorecardsScreen({super.key});
  @override
  State<ScorecardsScreen> createState() => _ScorecardsScreenState();
}

class _ScorecardsScreenState extends State<ScorecardsScreen> with SingleTickerProviderStateMixin {
  int _selectedTab = 0;

  final List<Map<String, dynamic>> _coachScores = [
    {"name": "Coach A1-23456", "loc": "Mahesana Junction", "score": 92, "rating": "Excellent"},
    {"name": "Coach B2-78901", "loc": "Viramgam Jn", "score": 78, "rating": "Good"},
    {"name": "Coach C3-45678", "loc": "Mahesana Junction", "score": 65, "rating": "Average"},
    {"name": "Coach D4-12345", "loc": "Ahmedabad", "score": 88, "rating": "Good"},
  ];

  final List<Map<String, dynamic>> _premisesScores = [
    {"name": "Platform No. 1", "loc": "Mahesana Jn", "score": 88, "rating": "Good"},
    {"name": "Waiting Room Gents", "loc": "Mahesana Jn", "score": 72, "rating": "Average"},
    {"name": "Circulating Area", "loc": "Mahesana Jn", "score": 95, "rating": "Excellent"},
    {"name": "Parking Area", "loc": "Mahesana Jn", "score": 60, "rating": "Needs Work"},
  ];

  final List<Map<String, dynamic>> _rankings = [
    {"name": "Rajesh Sharma", "score": 96, "rank": 1, "dept": "Cleaning", "tasks": 42},
    {"name": "Suresh Patel", "score": 88, "rank": 2, "dept": "Security", "tasks": 38},
    {"name": "Manoj Singh", "score": 82, "rank": 3, "dept": "Maintenance", "tasks": 35},
    {"name": "Kiran Devi", "score": 75, "rank": 4, "dept": "Cleaning", "tasks": 30},
    {"name": "Amit Kumar", "score": 70, "rank": 5, "dept": "Security", "tasks": 28},
  ];

  Color _scoreColor(int s) => s >= 85 ? Colors.green : s >= 70 ? Colors.orange : Colors.red;
  String _scoreLabel(int s) => s >= 85 ? "Excellent" : s >= 70 ? "Good" : s >= 60 ? "Average" : "Needs Work";

  void _toggleScore(int tabIdx, int itemIdx) {
    setState(() {
      final list = tabIdx == 0 ? _coachScores : _premisesScores;
      list[itemIdx]["score"] = (list[itemIdx]["score"] as int) + 1;
      if (list[itemIdx]["score"] > 100) list[itemIdx]["score"] = 60;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Scorecards', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: kRailwayBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Container(
            height: 44, padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(children: [
              _buildTab(0, "Coach"),
              _buildTab(1, "Premises"),
              _buildTab(2, "Rankings"),
            ]),
          ),
        ),
      ),
      body: _selectedTab == 2 ? _buildRankings() : _buildScoreList(_selectedTab == 0 ? _coachScores : _premisesScores, _selectedTab),
    );
  }

  Widget _buildTab(int index, String label) {
    final active = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          alignment: Alignment.center,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(label, style: TextStyle(color: active ? Colors.white : Colors.white60, fontSize: 14, fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
            const SizedBox(height: 4),
            Container(height: 4, width: 26, decoration: BoxDecoration(color: active ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(3))),
          ]),
        ),
      ),
    );
  }

  void _showDetail(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(item["name"], style: const TextStyle(color: kRailwayBlue)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _detailRow("Location", item["loc"]),
          _detailRow("Score", "${item["score"]}%"),
          _detailRow("Rating", item["rating"]),
          _detailRow("Status", (item["score"] as int) >= 70 ? "Pass" : "Needs Improvement"),
          const SizedBox(height: 10),
          Container(
            width: double.infinity, padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.blue.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
            child: const Text("Detailed breakdown available in reports module", style: TextStyle(fontSize: 12, color: Colors.grey)),
          ),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close"))],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        SizedBox(width: 80, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
        Expanded(child: Text(value)),
      ]),
    );
  }

  Widget _buildScoreList(List<Map<String, dynamic>> items, int tabIdx) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        final s = item["score"] as int;
        final c = _scoreColor(s);
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showDetail(item),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                SizedBox(
                  width: 64, height: 64,
                  child: Stack(alignment: Alignment.center, children: [
                    SizedBox(width: 64, height: 64, child: CircularProgressIndicator(
                      value: s / 100, strokeWidth: 5,
                      backgroundColor: Colors.grey.shade200, color: c,
                    )),
                    Text("$s", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: c)),
                  ]),
                ),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item["name"], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(item["loc"], style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: Text(_scoreLabel(s), style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ])),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ]),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRankings() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _rankings.length,
      itemBuilder: (_, i) {
        final item = _rankings[i];
        final medalColor = i == 0 ? Colors.amber : (i == 1 ? Colors.grey : (i == 2 ? Colors.brown : Colors.transparent));
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _showRankDetail(item),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: medalColor != Colors.transparent ? medalColor.withOpacity(0.2) : Colors.grey.shade100,
                child: Text("#${item["rank"]}", style: TextStyle(fontWeight: FontWeight.bold, color: medalColor != Colors.transparent ? medalColor : Colors.grey)),
              ),
              title: Text(item["name"], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(item["dept"], style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                child: Text("${item["score"]}%", style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showRankDetail(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Icon(Icons.emoji_events, color: item["rank"] == 1 ? Colors.amber : Colors.grey),
          const SizedBox(width: 8),
          Text(item["name"], style: const TextStyle(color: kRailwayBlue)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _detailRow("Rank", "#${item["rank"]}"),
          _detailRow("Department", item["dept"]),
          _detailRow("Score", "${item["score"]}%"),
          _detailRow("Tasks Completed", "${item["tasks"]}"),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close"))],
      ),
    );
  }
}
