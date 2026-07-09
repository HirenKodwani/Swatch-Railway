import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../services/api_services.dart';
import '../../../utills/app_colors.dart';

class CommonAlertScreen extends StatefulWidget {
  const CommonAlertScreen({super.key});

  @override
  State<CommonAlertScreen> createState() => _CommonAlertScreenState();
}

class _CommonAlertScreenState extends State<CommonAlertScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final list = await ApiService.getNotifications();
      setState(() {
        _notifications = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _markAllRead() async {
    try {
      await ApiService.markAllNotificationsRead();
      for (final n in _notifications) {
        n['read'] = true;
      }
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All notifications marked as read')),
        );
      }
    } catch (_) {}
  }

  Future<void> _markRead(String uid) async {
    try {
      await ApiService.markNotificationRead(uid);
    } catch (_) {}
  }

  String _formatTime(dynamic ts) {
    if (ts == null) return '';
    DateTime? dt;
    if (ts is String) dt = DateTime.tryParse(ts);
    if (ts is int) {
      dt = DateTime.fromMillisecondsSinceEpoch(
        ts < 10000000000 ? ts * 1000 : ts,
      );
    }
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('dd MMM').format(dt);
  }

  IconData _typeIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'billing':
        return Icons.receipt_long;
      case 'task':
        return Icons.task_alt;
      case 'complaint':
        return Icons.report_problem;
      case 'alert':
        return Icons.warning_amber;
      default:
        return Icons.notifications;
    }
  }

  Color _typeColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'billing':
        return Colors.purple;
      case 'task':
        return kRailwayBlue;
      case 'complaint':
        return Colors.red;
      case 'alert':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: kRailwayBlue,
        elevation: 0.5,
        actions: [
          if (_notifications.any((n) => n['read'] != true))
            TextButton(
              onPressed: _markAllRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 56, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Could not load notifications',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _fetchNotifications,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_off, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No notifications',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'You\'re all caught up!',
              style: TextStyle(fontSize: 13, color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchNotifications,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _notifications.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
        itemBuilder: (context, index) {
          final n = _notifications[index];
          final isRead = n['read'] == true;
          final uid = n['uid']?.toString() ?? '';
          final title = n['title']?.toString() ?? '';
          final body = n['body']?.toString() ?? '';
          final type = n['type']?.toString();

          return ListTile(
            onTap: () {
              if (!isRead) {
                setState(() => n['read'] = true);
                _markRead(uid);
              }
            },
            leading: CircleAvatar(
              backgroundColor: _typeColor(type).withValues(alpha: 0.12),
              child: Icon(
                _typeIcon(type),
                color: _typeColor(type),
                size: 20,
              ),
            ),
            title: Text(
              title.isEmpty ? 'Notification' : title,
              style: TextStyle(
                fontWeight: isRead ? FontWeight.w400 : FontWeight.w700,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            subtitle: Text(
              body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
            trailing: Text(
              _formatTime(n['createdAt']),
              style: TextStyle(fontSize: 11, color: Colors.grey[400]),
            ),
            tileColor: isRead ? null : Colors.blue.withValues(alpha: 0.04),
          );
        },
      ),
    );
  }
}
