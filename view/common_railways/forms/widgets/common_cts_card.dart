import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../model/cts_form_model.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../services/api_services.dart';
import '../../../../utills/app_colors.dart';
import '../../../common_contractor/form_screen/forms/cts_form_screen_v2.dart';

class CTSFormStatusCard extends StatefulWidget {
  final CTSForm form;
  final VoidCallback? onView;
  final VoidCallback? onPdf;
  final VoidCallback? onScore;

  const CTSFormStatusCard({
    super.key,
    required this.form,
    this.onView,
    this.onPdf,
    this.onScore,
  });

  @override
  State<CTSFormStatusCard> createState() => _CTSFormStatusCardState();
}

class _CTSFormStatusCardState extends State<CTSFormStatusCard> {
  bool _isAccepting = false;

  @override
  Widget build(BuildContext context) {
    final statusInfo = widget.form.getStatusInfo();
    final user = Provider.of<AuthProvider>(context).currentUser;
    final bool canPerformActions = user?.role != 'Contractor Master' && user?.role != 'Contractor Admin';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                flex: 1,
                child: Text(
                  'CTS\nForm',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusInfo['color'],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getStatusText(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: statusInfo['textColor'],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(
                  text: 'Train: ',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                TextSpan(
                  text: widget.form.trainName.isNotEmpty ? widget.form.trainName : 'N/A',
                ),
              ],
            ),
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(
                  text: 'Submitted by: ',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                TextSpan(text: '${widget.form.submittedByName}   •   '),
                const TextSpan(
                  text: 'Submitted to: ',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                TextSpan(text: widget.form.submittedTo.railwayEmployeeName ?? 'N/A'),
              ],
            ),
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(
                  text: 'Timestamp: ',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                TextSpan(text: '${widget.form.getFormattedDateTime()}   •   '),
                const TextSpan(
                  text: 'Division: ',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                TextSpan(text: widget.form.submittedByDivision ?? 'N/A'),
                if (widget.form.submittedByDepot?.toString().isNotEmpty ?? false) ...[
                  const TextSpan(text: ' • '),
                  const TextSpan(
                    text: 'Depot: ',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  TextSpan(text: widget.form.submittedByDepot!),
                ]
              ],
            ),
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _actionButton('View', Colors.grey.shade200, Colors.black, widget.onView, false),
              if (canPerformActions) _buildStatusActionButton(context),
            ],
          ),
        ],
      ),
    );
  }

  String _getStatusText() {
    switch (widget.form.status?.toUpperCase() ?? 'PENDING') {
      case 'SUBMITTED':
        return 'Waiting for railway approval';
      case 'APPROVED_BY_RAILWAY':
        return 'Approved by railway';
      case 'REJECTED_BY_RAILWAY':
        return 'Reject by railway';
      case 'SCORED':
        return 'Auto approved in 30 min';
      case 'AUTO-APPROVED':
        return 'Locked';
      case 'LOCKED':
        return 'Locked';
      default:
        return widget.form.status ?? 'Pending';
    }
  }

  Widget _actionButton(
      String text, Color bg, Color color, VoidCallback? onPressed, bool isLoading) {
    return Expanded(
      child: Container(
        height: 40,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: bg,
            foregroundColor: color,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  text,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                ),
        ),
      ),
    );
  }

  Widget _buildStatusActionButton(BuildContext context) {
    String btnText = '';
    Color btnColor = Colors.grey;
    VoidCallback? callback;
    bool isLoading = false;

    switch (widget.form.status) {
      case 'SUBMITTED':
        btnText = 'SUBMITTED';
        btnColor = Colors.grey;
        callback = null;
        break;

      case 'REJECTED_BY_RAILWAY':
        btnText = 'RE-SUBMIT';
        btnColor = Colors.blue;
        callback = () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewCTSFormScreen(
                existingForm: widget.form,
                isResubmit: true,
              ),
            ),
          );
          if (result == true && widget.onPdf != null) {
            widget.onPdf!();
          }
        };
        break;

      case 'APPROVED_BY_RAILWAY':
        btnText = 'IN REVIEW';
        btnColor = Colors.orange;
        callback = null;
        break;

      case 'AUTO-APPROVED':
        btnText = 'LOCKED';
        btnColor = Colors.red;
        callback = () {};
        break;

      case 'SCORED':
        btnText = 'ACCEPT';
        btnColor = Colors.green;
        isLoading = _isAccepting;
        callback = _isAccepting ? null : () => _acceptScoredForm(context);
        break;

      case 'LOCKED':
        btnText = 'LOCKED';
        btnColor = Colors.red;
        callback = () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("This form is locked. You cannot process it any more."),
            ),
          );
        };
        break;

      default:
        btnText = widget.form.status ?? 'PENDING';
        btnColor = kRailwayBlue;
        callback = widget.onPdf;
    }

    return _actionButton(btnText, btnColor, Colors.white, callback, isLoading);
  }

  Future<void> _acceptScoredForm(BuildContext context) async {
    setState(() => _isAccepting = true);

    try {
      final result = await ApiService.acceptCTSScoredForm(formId: widget.form.uid);

      if (result["success"] != false) {
        if (mounted) {
          String message = result["message"] ?? "Form accepted successfully";

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.green,
            ),
          );

          if (widget.onPdf != null) {
            widget.onPdf!();
          }

          await Future.delayed(const Duration(milliseconds: 300));
          if (mounted) {
            setState(() {});
          }
        }
      } else {
        if (mounted) {
          String errorMsg = result["message"] ?? "Failed to accept form";

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAccepting = false);
      }
    }
  }
}