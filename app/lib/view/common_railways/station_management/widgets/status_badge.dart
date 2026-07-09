import 'package:flutter/material.dart';
import '../../../../utills/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;
  final EdgeInsets padding;

  const StatusBadge(
    this.status, {
    super.key,
    this.fontSize = 10,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  });

  @override
  Widget build(BuildContext context) {
    final info = _statusInfo(status);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: info['color']!.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: info['color']!.withOpacity(0.3)),
      ),
      child: Text(
        _label(status),
        style: TextStyle(
          color: info['color'],
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _label(String s) {
    switch (s.toLowerCase()) {
      case 'pending': return 'Pending';
      case 'in-progress': case 'in_progress': return 'In Progress';
      case 'completed': return 'Completed';
      case 'approved': return 'Approved';
      case 'rejected': return 'Rejected';
      case 'active': return 'Active';
      case 'inactive': return 'Inactive';
      case 'resubmitted': return 'Resubmitted';
      default: return s;
    }
  }

  Map<String, Color?> _statusInfo(String s) {
    switch (s.toLowerCase()) {
      case 'pending': case 'resubmitted':
        return {'color': kWarningOrange};
      case 'in-progress': case 'in_progress':
        return {'color': kRailwayBlue};
      case 'completed':
        return {'color': kSuccessGreen};
      case 'approved':
        return {'color': kInfo};
      case 'rejected':
        return {'color': kErrorRed};
      case 'active':
        return {'color': kSuccessGreen};
      case 'inactive':
        return {'color': kDisabled};
      default:
        return {'color': kNeutralGrey};
    }
  }
}
