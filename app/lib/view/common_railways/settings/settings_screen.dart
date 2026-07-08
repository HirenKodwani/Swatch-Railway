import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../utills/app_colors.dart';
import '../profile/change_password_screen.dart';
import '../alert/common_alert_screen.dart';
import '../users/common_user_management_screen.dart';
import '../divisions/division_management_screen.dart';
import '../audit/audit_log_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;
    final isAdmin = user?.role == 'Admin' || user?.role == 'Supervisor' || user?.role == 'Company Master';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: kRailwayBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeader('Account'),
          _settingsTile(
            Icons.lock_outline,
            'Change Password',
            'Update your account password',
            Colors.orange,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen())),
          ),
          _settingsTile(
            Icons.notifications_outlined,
            'Notifications',
            'View your notifications and alerts',
            Colors.blue,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CommonAlertScreen())),
          ),
          if (isAdmin) ...[
            const SizedBox(height: 8),
            _sectionHeader('Administration'),
            _settingsTile(
              Icons.people_outline,
              'User Management',
              'Create, edit, and manage users',
              Colors.teal,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CommonUserManagementScreen())),
            ),
            _settingsTile(
              Icons.map_outlined,
              'Division Management',
              'Manage railway divisions',
              Colors.purple,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DivisionManagementScreen())),
            ),
            _settingsTile(
              Icons.history,
              'Audit Logs',
              'View system audit trail',
              Colors.brown,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AuditLogScreen())),
            ),
          ],
          const SizedBox(height: 8),
          _sectionHeader('About'),
          _settingsTile(
            Icons.info_outline,
            'App Version',
            '1.0.0',
            Colors.grey,
            null,
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black54, letterSpacing: 0.5),
      ),
    );
  }

  Widget _settingsTile(IconData icon, String title, String subtitle, Color color, VoidCallback? onTap) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color.withOpacity(0.12), child: Icon(icon, color: color, size: 22)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        trailing: onTap != null ? const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey) : null,
        onTap: onTap,
      ),
    );
  }
}