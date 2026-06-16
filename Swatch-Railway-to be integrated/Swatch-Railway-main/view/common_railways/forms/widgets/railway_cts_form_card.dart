import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../model/cts_form_model.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../services/api_services.dart';
import '../../scorecard_forms/common_cts_scorecard.dart' show CTSScorecardForm;

class RailwayCTSFormCard extends StatefulWidget {
  final CTSForm form;
  final VoidCallback? onView;
  final VoidCallback? onPdf;
  final VoidCallback? onScore;

  const RailwayCTSFormCard({
    super.key,
    required this.form,
    this.onView,
    this.onPdf,
    this.onScore,
  });

  @override
  State<RailwayCTSFormCard> createState() => _RailwayCTSFormCardState();
}

class _RailwayCTSFormCardState extends State<RailwayCTSFormCard> {
  bool _isApproving = false;
  bool _isRejecting = false;

  @override
  Widget build(BuildContext context) {
    final statusInfo = widget.form.getStatusInfo();
    final user = Provider.of<AuthProvider>(context).currentUser;

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
                child: user!.userType != 'railway'
                    ? Text(
                        _getContractorStatusText(widget.form.status ?? ''),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: statusInfo['textColor'],
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    : Text(
                        _getRailwayStatusText(widget.form.status ?? ''),
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
                    style: TextStyle(fontWeight: FontWeight.w500)),
                TextSpan(
                    text: widget.form.trainName.isNotEmpty
                        ? widget.form.trainName
                        : 'N/A'),
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
                    style: TextStyle(fontWeight: FontWeight.w500)),
                TextSpan(text: '${widget.form.submittedByName}'),
              ],
            ),
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(
                    text: 'Submitted Date: ',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                TextSpan(text: '${widget.form.getFormattedDateTime()}   •   '),
                const TextSpan(
                    text: 'Division: ',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                TextSpan(text: '${widget.form.submittedByDivision ?? 'N/A'}'),
                if (widget.form.submittedByDepot != null &&
                    widget.form.submittedByDepot!.isNotEmpty)
                  const TextSpan(
                      text: ' •  Depot: ',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                if (widget.form.submittedByDepot != null &&
                    widget.form.submittedByDepot!.isNotEmpty)
                  TextSpan(text: widget.form.submittedByDepot),
              ],
            ),
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 5),
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(
                    text: 'Assigned to: ',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                TextSpan(
                    text:
                        '${widget.form.submittedTo.railwayEmployeeName ?? 'N/A'}'),
              ],
            ),
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 14),
          _buildActionButtons(),
        ],
      ),
    );
  }

  String _getContractorStatusText(String status) {
    switch (status.toUpperCase()) {
      case 'SUBMITTED':
        return 'Waiting for railway approval';
      case 'APPROVED_BY_RAILWAY':
        return 'Approved by railway';
      case 'REJECTED_BY_RAILWAY':
        return 'Reject by railway';
      case 'SCORED':
        return 'Auto approved in 30 min';
      case 'AUTO-APPROVED':
        return 'LOCKED';
      case 'LOCKED':
        return 'LOCKED';
      default:
        return status;
    }
  }

  String _getRailwayStatusText(String status) {
    switch (status.toUpperCase()) {
      case 'SUBMITTED':
        return 'Pending for approval';
      case 'APPROVED_BY_RAILWAY':
        return 'Pending Scoring';
      case 'REJECTED_BY_RAILWAY':
        return 'Rejected';
      case 'SCORED':
        return 'Pending for contractor approval';
      case 'AUTO-APPROVED':
        return 'LOCKED';
      case 'LOCKED':
        return 'Locked';
      default:
        return status;
    }
  }

  bool _canShowActionButtons() {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    return user?.role == 'Railway Supervisor' ||
        user?.role == 'Contractor Supervisor';
  }

  Widget _buildActionButtons() {
    final canPerformActions = _canShowActionButtons();
    final status = widget.form.status ?? '';

    if (!canPerformActions) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _actionButton(
              'View', Colors.grey.shade200, Colors.black, widget.onView, false),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _actionButton(
            'View', Colors.grey.shade200, Colors.black, widget.onView, false),
        if (status != 'SCORED' &&
            status != 'LOCKED' &&
            status != 'AUTO-APPROVED' &&
            status != 'REJECTED_BY_RAILWAY')
          _actionButton(
            'Reject',
            Colors.red.shade400,
            Colors.white,
            _isRejecting ? null : () => _showRejectDialog(context),
            _isRejecting,
          ),
        _buildMainActionButton(),
      ],
    );
  }

  Widget _buildMainActionButton() {
    final canPerformActions = _canShowActionButtons();
    final status = widget.form.status ?? '';
    String btnText = _getButtonLabel(status);
    Color btnColor = _getButtonColor(status);
    bool isLoading = _isApproving;
    VoidCallback? onPressed;

    if (status == 'APPROVED_BY_RAILWAY' || status == 'SCORING_IN_PROGRESS') {
      if (canPerformActions) {
        onPressed = () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CTSScorecardForm(ctsForm: widget.form),
            ),
          );
          if (result == true && widget.onScore != null) {
            widget.onScore!();
          }
        };
      } else {
        onPressed = null;
      }
      isLoading = false;
    } else if (status == 'SUBMITTED' || status == 'RE-SUBMITTED') {
      if (canPerformActions) {
        onPressed =
            _isApproving ? null : () => _approveForm(widget.form, context);
      } else {
        onPressed = null;
      }
    } else if (status == 'AUTO-APPROVED' || status == 'LOCKED') {
      onPressed = null;
      isLoading = false;
    } else if (status == 'REJECTED_BY_RAILWAY') {
      onPressed = null;
      isLoading = false;
    } else {
      onPressed = null;
      isLoading = false;
    }

    return _actionButton(btnText, btnColor, Colors.white, onPressed, isLoading);
  }

  void _showRejectDialog(BuildContext context) {
    final TextEditingController remarksController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Reject Form'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Please provide rejection comments:',
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: remarksController,
                      maxLines: 4,
                      minLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Enter rejection reason...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      isLoading ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final remarks = remarksController.text.trim();

                          if (remarks.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Please enter rejection comments')),
                            );
                            return;
                          }

                          setDialogState(() => isLoading = true);
                          setState(() => _isRejecting = true);

                          try {
                            final result = await ApiService.rejectCTSForm(
                              formId: widget.form.uid,
                              rejectRemark: remarks,
                            );

                            if (result['message'] != null &&
                                result['message'].contains('successfully')) {
                              if (context.mounted) {
                                Navigator.pop(dialogContext);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Form rejected successfully!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                if (widget.onScore != null) widget.onScore!();
                              }
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Rejection failed: ${result['message'] ?? 'Unknown error'}'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() => _isRejecting = false);
                            }
                            setDialogState(() => isLoading = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade400,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Reject'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      if (mounted) {
        setState(() => _isRejecting = false);
      }
    });
  }

  void _approveForm(CTSForm form, BuildContext context) async {
    setState(() => _isApproving = true);

    try {
      await ApiService.approveCTSForm(formId: form.uid);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Form approved successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        if (widget.onScore != null) {
          widget.onScore!();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Approval failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isApproving = false);
      }
    }
  }

  String _getButtonLabel(String status) {
    if (status == 'REJECTED_BY_RAILWAY') return 'REJECTED';
    if (status == 'APPROVED_BY_RAILWAY') return 'SCORE';
    if (status == 'SUBMITTED') return 'APPROVE';
    if (status == 'RE-SUBMITTED') return 'APPROVE';
    if (status == 'SCORING_IN_PROGRESS') return 'SCORE';
    if (status == 'AUTO-APPROVED') return 'LOCKED';
    return status;
  }

  Color _getButtonColor(String status) {
    if (status == 'APPROVED_BY_RAILWAY') return Colors.blue;
    if (status == 'SUBMITTED') return Colors.green;
    if (status == 'RE-SUBMITTED') return Colors.green;
    if (status == 'SCORING_IN_PROGRESS') return Colors.blue;
    if (status == 'AUTO-APPROVED') return Colors.red;
    if (status == 'LOCKED') return Colors.red;
    if (status == 'REJECTED_BY_RAILWAY') return Colors.red;
    return Colors.grey;
  }

  Widget _actionButton(String text, Color bg, Color color,
      VoidCallback? onPressed, bool isLoading) {
    return Expanded(
      child: Container(
        height: 40,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: bg,
            disabledForegroundColor: color,
            foregroundColor: color,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
            disabledBackgroundColor: bg,
          ),
          child: isLoading
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                )
              : Text(
                  text,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 12),
                ),
        ),
      ),
    );
  }
}