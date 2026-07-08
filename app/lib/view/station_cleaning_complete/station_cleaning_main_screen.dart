import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crm_train/providers/auth_provider.dart';
import 'package:crm_train/utills/app_colors.dart';
import 'package:crm_train/view/station_cleaning/station_cleaning_hub_screen.dart';

class StationCleaningMainScreen extends StatelessWidget {
  const StationCleaningMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;
    final role = (user?.role ?? '').toUpperCase().replaceAll(' ', '_');
    final isFullAccess = ['SUPER_ADMIN', 'ADMIN', 'RAILWAY_MASTER', 'COMPANY_MASTER', 'RAILWAY_ADMIN'].contains(role);

    return Scaffold(
      appBar: AppBar(
        title: const Text('STATION CLEANING MODULE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: kRailwayBlue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildRoleBanner(context, role),
          const SizedBox(height: 16),
          _buildSectionHeader('QUICK ACCESS'),
          const SizedBox(height: 8),
          _buildQuickAccessGrid(context, role, isFullAccess, user?.uid ?? ''),
          const SizedBox(height: 16),
          _buildSectionHeader('ALL MODULES'),
          const SizedBox(height: 8),
          _buildModuleList(context, role, isFullAccess, user?.uid ?? ''),
        ],
      ),
    );
  }

  Widget _buildRoleBanner(BuildContext context, String role) {
    final user = Provider.of<AuthProvider>(context).currentUser;
    final roleNames = {
      'SUPER_ADMIN': 'Super Admin',
      'ADMIN': 'Admin',
      'STATION_MASTER': 'Station Master',
      'RAILWAY_SUPERVISOR': 'Railway Supervisor',
      'CONTRACTOR_ADMIN': 'Contractor Admin',
      'CONTRACTOR_SUPERVISOR': 'Contractor Supervisor',
      'PLATFORM_MASTER': 'Platform Master',
      'WORKER': 'Worker',
    };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [kRailwayBlue, Color(0xFF0047B3)]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const CircleAvatar(radius: 28, backgroundColor: Colors.white, child: Icon(Icons.person, size: 32, color: kRailwayBlue)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user?.fullName ?? 'User', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                Text(roleNames[role] ?? role, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
            child: Text(role.replaceAll('_', ' '), style: const TextStyle(color: Colors.white, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: kRailwayBlue));
  }

  Widget _buildQuickAccessGrid(BuildContext context, String role, bool isFullAccess, String userId) {
    final items = <_QuickAction>[];
    if (isFullAccess || role == 'STATION_MASTER' || role == 'AREA_MASTER' || role == 'RAILWAY_SUPERVISOR') {
      items.add(_QuickAction('Dashboard', Icons.dashboard, Colors.blue, () => _goToHub(context)));
    }
    if (isFullAccess || role == 'CONTRACTOR_ADMIN' || role == 'CONTRACTOR_SUPERVISOR') {
      items.add(_QuickAction('Attendance', Icons.people, Colors.teal, () => _openModule(context, 'attendance', userId)));
    }
    if (isFullAccess || role == 'CONTRACTOR_ADMIN' || role == 'CONTRACTOR_SUPERVISOR') {
      items.add(_QuickAction('Activities', Icons.assignment, Colors.orange, () => _openModule(context, 'activities', userId)));
    }
    items.add(_QuickAction('Feedback', Icons.feedback, Colors.amber, () => _openModule(context, 'feedback', userId)));
    items.add(_QuickAction('Complaints', Icons.report, Colors.red, () => _openModule(context, 'complaint', userId)));
    items.add(_QuickAction('Billing', Icons.receipt, Colors.deepOrange, () => _openModule(context, 'billing', userId)));

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 1.0),
      itemCount: items.length,
      itemBuilder: (_, i) => Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: items[i].onTap,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            CircleAvatar(backgroundColor: items[i].color.withValues(alpha: 0.15), radius: 24, child: Icon(items[i].icon, color: items[i].color, size: 26)),
            const SizedBox(height: 8),
            Text(items[i].label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    );
  }

  Widget _buildModuleList(BuildContext context, String role, bool isFullAccess, String userId) {
    final modules = [
      _Module('01. Dashboard', 'Station Cleaning Dashboard with all KPIs', Icons.dashboard, Colors.blue, () => _goToHub(context)),
      _Module('02. Attendance', 'Biometric & manual attendance management', Icons.people, Colors.teal, () => _openModule(context, 'attendance', userId)),
      _Module('03. Execution Plan', 'Manpower, machine & material planning', Icons.calendar_month, Colors.indigo, () => _openModule(context, 'execution', userId)),
      _Module('04. Daily Activity', 'Record cleaning activities with photos', Icons.cleaning_services, Colors.lightBlue, () => _openModule(context, 'activity', userId)),
      _Module('05. Image Capture', 'Before/after photo evidence capture', Icons.camera_alt, Colors.brown, () => _openModule(context, 'image', userId)),
      _Module('06. Supervisor Log', 'Daily log with handover notes', Icons.description, Colors.cyan, () => _openModule(context, 'supervisor_log', userId)),
      _Module('07. Inspection', '5 inspection types with scoring', Icons.search, Colors.deepPurple, () => _openModule(context, 'inspection', userId)),
      _Module('08. Scorecard', 'Daily & monthly cleanliness scorecards', Icons.star, Colors.pink, () => _openModule(context, 'scorecard', userId)),
      _Module('09. Passenger Feedback', 'QR-based feedback with OTP validation', Icons.feedback, Colors.amber, () => _openModule(context, 'feedback', userId)),
      _Module('10. Complaint', 'Full complaint lifecycle management', Icons.report, Colors.red, () => _openModule(context, 'complaint', userId)),
      _Module('11. Pest Control', 'Pest, rodent & termite treatment log', Icons.bug_report, Colors.green, () => _openModule(context, 'pest', userId)),
      _Module('12. Machine Tracking', 'Equipment status & downtime tracking', Icons.precision_manufacturing, Colors.blueGrey, () => _openModule(context, 'machine', userId)),
      _Module('13. Material Tracking', 'Consumable stock & shortage alerts', Icons.inventory_2, Colors.blueGrey, () => _openModule(context, 'material', userId)),
      _Module('14. Garbage Disposal', 'Waste collection & segregation log', Icons.delete, Colors.brown, () => _openModule(context, 'garbage', userId)),
      _Module('15. Billing Support', 'Compliance checklist & billing reports', Icons.receipt, Colors.deepOrange, () => _openModule(context, 'billing', userId)),
    ];

    return Column(
      children: modules.map((m) => Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: CircleAvatar(backgroundColor: m.color.withValues(alpha: 0.15), child: Icon(m.icon, color: m.color, size: 22)),
          title: Text(m.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          subtitle: Text(m.subtitle, style: const TextStyle(fontSize: 11)),
          trailing: const Icon(Icons.chevron_right),
          onTap: m.onTap,
        ),
      )).toList(),
    );
  }

  void _goToHub(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => StationCleaningHubScreen(stationId: '', stationName: 'Station Cleaning'),
    ));
  }

  void _openModule(BuildContext context, String module, String userId) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => StationCleaningHubScreen(stationId: '', stationName: 'Station Cleaning'),
    ));
  }
}

class _QuickAction {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  _QuickAction(this.label, this.icon, this.color, this.onTap);
}

class _Module {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  _Module(this.title, this.subtitle, this.icon, this.color, this.onTap);
}
