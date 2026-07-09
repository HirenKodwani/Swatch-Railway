import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:crm_train/utills/app_colors.dart';

class StationCleaningDashboard extends StatefulWidget {
  final String stationId;
  final String stationName;
  final String? role;
  const StationCleaningDashboard({super.key, required this.stationId, required this.stationName, this.role});

  @override
  State<StatefulWidget> createState() => _StationCleaningDashboardState();
}

class _StationCleaningDashboardState extends State<StationCleaningDashboard> {
  String _selectedStation = 'Bhopal Junction';
  String _selectedDate = DateFormat('dd-MM-yyyy').format(DateTime.now());
  String _selectedShift = 'All';
  String _selectedArea = 'All';
  String _selectedContractor = 'All';

  final _stations = ['Bhopal Junction', 'Habibganj', 'Vidisha'];
  final _shifts = ['All', 'Morning', 'Afternoon', 'Night'];
  final _areas = ['All', 'PF-1', 'PF-2', 'PF-3', 'Waiting Hall', 'Station Toilet'];
  final _contractors = ['All', 'ABC Facility Services', 'XYZ Cleaning Co'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('STATION CLEANING DASHBOARD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: kRailwayBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.notifications), onPressed: () {}),
          const CircleAvatar(child: Icon(Icons.person), radius: 16),
          const SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilterRow(),
            const SizedBox(height: 12),
            _buildOverviewCards(),
            const SizedBox(height: 12),
            _buildAlertsSection(),
            const SizedBox(height: 12),
            _buildPerformanceTrend(),
            const SizedBox(height: 12),
            _buildPlannedVsCompleted(),
            const SizedBox(height: 12),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildDropdown('Station', _selectedStation, _stations, (v) => setState(() => _selectedStation = v ?? _selectedStation))),
                const SizedBox(width: 8),
                Expanded(child: _buildDatePicker()),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildDropdown('Shift', _selectedShift, _shifts, (v) => setState(() => _selectedShift = v ?? _selectedShift))),
                const SizedBox(width: 8),
                Expanded(child: _buildDropdown('Area', _selectedArea, _areas, (v) => setState(() => _selectedArea = v ?? _selectedArea))),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildDropdown('Contractor', _selectedContractor, _contractors, (v) => setState(() => _selectedContractor = v ?? _selectedContractor))),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: () {}, child: const Text('Apply')),
                const SizedBox(width: 4),
                OutlinedButton(onPressed: () {}, child: const Text('Reset')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label, contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(6))),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2024), lastDate: DateTime.now());
        if (picked != null) setState(() => _selectedDate = DateFormat('dd-MM-yyyy').format(picked));
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: 'Date', contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)), suffixIcon: const Icon(Icons.calendar_today, size: 18)),
        child: Text(_selectedDate, style: const TextStyle(fontSize: 13)),
      ),
    );
  }

  Widget _buildOverviewCards() {
    final cards = [
      ('Stations', '45', Icons.business, kRailwayBlue),
      ('Contracts', '23', Icons.assignment, Colors.teal),
      ('Attendance', '89%', Icons.people, Colors.orange),
      ('Planned', '156', Icons.plumbing, Colors.lightBlue),
      ('Completed', '32', Icons.check_circle, Colors.green),
    ];
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => Container(
          width: 110,
          decoration: BoxDecoration(color: cards[i].$4.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(cards[i].$3, color: cards[i].$4, size: 22),
              const SizedBox(height: 4),
              Text(cards[i].$2, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: cards[i].$4)),
              Text(cards[i].$1, style: TextStyle(fontSize: 11, color: cards[i].$4)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlertsSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(children: [
              _alertTile(Icons.pending_actions, 'Pending\nTasks', '8', kWarningOrange),
              _alertTile(Icons.timer_off, 'Missed\nFrequency', '3', kErrorRed),
              _alertTile(Icons.report, 'Open\nComplaints', '2', kWarningOrange),
            ]),
            const Divider(height: 16),
            Row(children: [
              _alertTile(Icons.assessment, 'Inspection\nScore', '85%', kRailwayBlue),
              _alertTile(Icons.star, 'Feedback\nScore', '4.2/5.0', Colors.amber.shade700),
              _alertTile(Icons.trending_up, 'Monthly\nPerf.', '82%', Colors.green),
            ]),
            const Divider(height: 16),
            Row(children: [
              _alertTile(Icons.currency_rupee, 'Billing\nReadiness', '✅ 85%', Colors.teal),
              _alertTile(Icons.email, 'Reports\nSent', '12/15', kRailwayBlue),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _alertTile(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 6),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
              Text(label, style: const TextStyle(fontSize: 9)),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceTrend() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('PERFORMANCE TREND (Last 7 Days)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildBar('Mon', 0.95, Colors.green),
                  _buildBar('Tue', 0.88, Colors.green),
                  _buildBar('Wed', 0.85, kRailwayBlue),
                  _buildBar('Thu', 0.82, kWarningOrange),
                  _buildBar('Fri', 0.86, Colors.green),
                  _buildBar('Sat', 0.90, Colors.green),
                  _buildBar('Sun', 0.87, Colors.green),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBar(String day, double pct, Color color) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('${(pct * 100).toInt()}%', style: const TextStyle(fontSize: 9)),
          Container(height: 80 * pct, width: 20, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
          Text(day, style: const TextStyle(fontSize: 9)),
        ],
      ),
    );
  }

  Widget _buildPlannedVsCompleted() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('PLANNED VS COMPLETED (Today)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            _statusRow('Cleaning', '48', '32', 0.67, kWarningOrange),
            _statusRow('Sweeping', '24', '20', 0.83, Colors.green),
            _statusRow('Mopping', '12', '8', 0.67, kErrorRed),
          ],
        ),
      ),
    );
  }

  Widget _statusRow(String activity, String planned, String completed, double pct, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(activity, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
          Text(planned, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 12),
          Text(completed, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: pct, backgroundColor: Colors.grey.shade200, color: color, minHeight: 12),
            ),
          ),
          const SizedBox(width: 8),
          Text('${(pct * 100).toInt()}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(child: ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.assessment), label: const Text('Full Report'))),
        const SizedBox(width: 8),
        Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.refresh), label: const Text('Refresh'))),
        const SizedBox(width: 8),
        Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.download), label: const Text('Export'))),
      ],
    );
  }
}
