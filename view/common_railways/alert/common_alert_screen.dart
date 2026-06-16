import 'package:crm_train/services/api_services.dart';
import 'package:crm_train/utills/app_colors.dart';
import 'package:flutter/material.dart';

class CommonAlertScreen extends StatefulWidget {
  const CommonAlertScreen({super.key});

  @override
  State<CommonAlertScreen> createState() => _CommonAlertScreenState();
}

class _CommonAlertScreenState extends State<CommonAlertScreen> {
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { isLoading = true; });
    try {
      final result = await ApiService.getNotifications();
      if (mounted) setState(() { notifications = result; isLoading = false; });
    } catch (_) {
      if (mounted) setState(() { isLoading = false; });
    }
  }

  Future<void> _markAllRead() async {
    await ApiService.markAllNotificationsRead();
    for (var i = 0; i < notifications.length; i++) {
      notifications[i]['read'] = true;
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 20)),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: kRailwayBlue,
        elevation: 0.5,
        actions: [
          if (notifications.any((n) => n['read'] == false))
            TextButton(onPressed: _markAllRead, child: const Text('Mark All Read', style: TextStyle(color: Colors.white))),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.notifications_off, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('No notifications yet', style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
                ]))
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: notifications.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final n = notifications[index];
                    final read = n['read'] == true;
                    final title = n['title'] ?? 'Notification';
                    final body = n['body'] ?? '';
                    final type = n['type'] ?? 'general';
                    return ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: read ? Colors.grey.shade100 : kRailwayBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          type == 'bill_approved' ? Icons.check_circle : type == 'bill_rejected' ? Icons.cancel : type == 'invoice_generated' ? Icons.receipt : Icons.notifications,
                          color: read ? Colors.grey : kRailwayBlue,
                        ),
                      ),
                      title: Text(title, style: TextStyle(fontWeight: read ? FontWeight.normal : FontWeight.bold, fontSize: 14)),
                      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(body, style: TextStyle(color: Colors.grey.shade600, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ]),
                      trailing: read ? null : Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                      onTap: () async {
                        if (n['uid'] != null && !read) {
                          await ApiService.markNotificationRead(n['uid']);
                          if (mounted) setState(() { n['read'] = true; });
                        }
                      },
                    );
                  },
                ),
    );
  }
}