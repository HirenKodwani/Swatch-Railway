import 'package:crm_train/services/api_services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../model/premises_form_model.dart';
import '../../../../providers/auth_provider.dart';
import '../../../common_contractor/form_screen/forms/new_premises_form.dart';

class PremisesStatusCard extends StatefulWidget {
  final FormData form;
  final VoidCallback? onView;
  final VoidCallback? onRefresh;
  final VoidCallback? onScore;
  final Function(String remark)? onReject;
  final VoidCallback? onApprove;

  const PremisesStatusCard({
    super.key,
    required this.form,
    this.onView,
    this.onRefresh,
    this.onScore,
    this.onReject,
    this.onApprove,
  });

  @override
  State<PremisesStatusCard> createState() => _PremisesStatusCardState();
}

class _PremisesStatusCardState extends State<PremisesStatusCard> {
  bool _isApproving = false;
  bool _isRejecting = false;
  bool _isAccepting = false;

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
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: const Offset(0, 2),
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
                child: Text(
                  'Premises\nCleaning',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusInfo['color'],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: user!.userType != 'railway'
                    ? Text(
                  _getContractorStatusText(widget.form.status),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: statusInfo['textColor'],
                    fontWeight: FontWeight.w500,
                  ),
                )
                    : Text(
                  _getRailwayStatusText(widget.form.status),
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
                  text: 'Premises Location: ',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                TextSpan(text: widget.form.location),
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
                TextSpan(text: widget.form.submittedByName),
                const TextSpan(text: '   •   '),
                const TextSpan(
                  text: 'Submitted to: ',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                TextSpan(text: widget.form.submittedTo.railwayEmployeeName),
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
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                TextSpan(
                    text:
                    '${widget.form.formDateTime.toLocal().toString().substring(0, 16)}   •   '),
                const TextSpan(
                  text: 'Division: ',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                TextSpan(text: widget.form.submittedByDivision),
                if(widget.form.submittedByDepot != null && widget.form.submittedByDepot!.trim().isNotEmpty) ...[
                  const TextSpan(text: '   •   '),
                  const TextSpan(
                    text: 'Depot: ',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  TextSpan(text: widget.form.submittedByDepot!.trim()),
                ],
              ],
            ),
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              user!.userType == 'contractor'
                  ? _buildContractorButtons(context)
                  : _buildRailwayButtons(context)
            ],
          ),
        ],
      ),
    );
  }

  String _getContractorStatusText(String status) {
    switch (status) {
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
        return 'Locked';
      default:
        return status;
    }
  }

  String _getRailwayStatusText(String status) {
    switch (status) {
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

  Widget _buildContractorButtons(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;
    final bool canPerformActions = user?.role != 'Contractor Supervisor';

    return Expanded(
      child: Row(
        children: [
          Expanded(
            child: _actionButton(
                'View', Colors.grey.shade200, Colors.black, widget.onView, false),
          ),
          if (canPerformActions) ...[
            const SizedBox(width: 8),
            Expanded(
              child: _buildContractorActionButton(context),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContractorActionButton(BuildContext context) {
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

      case 'APPROVED_BY_RAILWAY':
        btnText = 'IN REVIEW';
        btnColor = Colors.orange;
        callback = null;
        break;

      case 'AUTO-APPROVED':
        btnText = 'LOCKED';
        btnColor = Colors.red;
        callback = null;
        break;

      case 'REJECTED_BY_RAILWAY':
        btnText = 'RE-SUBMIT';
        btnColor = Colors.blue;
        callback = () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PremisesCleaningForm(
                existingForm: widget.form,
                isResubmit: true,
              ),
            ),
          );
          if (result == true && widget.onRefresh != null) {
            widget.onRefresh!();
          }
        };
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
        callback = null;
        break;

      default:
        btnText = widget.form.status;
        btnColor = Colors.blue;
        callback = widget.onRefresh;
    }

    return _actionButton(btnText, btnColor, Colors.white, callback, isLoading);
  }

  Future<void> _acceptScoredForm(BuildContext context) async {
    setState(() => _isAccepting = true);

    try {
      final result = await ApiService.acceptPremisesScoredForm(
        formId: widget.form.uid,
      );

      if (result["success"] != false) {
        if (mounted) {
          String message = result["message"] ?? "Form accepted successfully";

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );


          if (widget.onRefresh != null) {
            widget.onRefresh!();
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

  Widget _buildRailwayButtons(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;
    final bool canPerformActions = user?.role == 'Railway Supervisor';

    // If user is not Railway Supervisor, show only View button for all statuses
    if (!canPerformActions) {
      return Expanded(
        child: Row(
          children: [
            Expanded(
              child: _actionButton(
                  'View', Colors.grey.shade200, Colors.black, widget.onView, false),
            ),
          ],
        ),
      );
    }

    // Railway Supervisor specific logic below
    if (widget.form.status == 'SUBMITTED' || widget.form.status == 'RE-SUBMITTED') {
      return Expanded(
        child: Row(
          children: [
            Expanded(
              child: _actionButton(
                  'View', Colors.grey.shade200, Colors.black, widget.onView, false),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _actionButton(
                'Reject',
                Colors.red,
                Colors.white,
                _isRejecting ? null : () => _showRejectDialog(context),
                _isRejecting,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _actionButton(
                'Approve',
                Colors.green,
                Colors.white,
                _isApproving ? null : () => _approvePremisesForm(context),
                _isApproving,
              ),
            ),
          ],
        ),
      );
    }

    if (widget.form.status == 'APPROVED_BY_RAILWAY') {
      return Expanded(
        child: Row(
          children: [
            Expanded(
                child: _actionButton(
                    'View', Colors.grey.shade200, Colors.black, widget.onView, false)),
            const SizedBox(width: 8),
            Expanded(
              child: _actionButton(
                'Reject',
                Colors.red,
                Colors.white,
                _isRejecting ? null : () => _showRejectDialog(context),
                _isRejecting,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
                child: _actionButton(
                    'Score', Colors.blue, Colors.white, widget.onScore, false)),
          ],
        ),
      );
    }

    if (widget.form.status == 'REJECTED_BY_RAILWAY') {
      return Expanded(
        child: Row(
          children: [
            Expanded(
                child: _actionButton(
                    'View', Colors.grey.shade200, Colors.black, widget.onView, false)),
            const SizedBox(width: 8),
            Expanded(
                child: _actionButton(
                    'REJECTED', Colors.red, Colors.white, null, false)),
          ],
        ),
      );
    }

    if (widget.form.status == 'SCORED') {
      return Expanded(
        child: Row(
          children: [
            Expanded(
                child: _actionButton(
                    'View', Colors.grey.shade200, Colors.black, widget.onView, false)),
            const SizedBox(width: 8),
            Expanded(child: _actionButton('SCORED', Colors.grey, Colors.white, () {}, false)),
          ],
        ),
      );
    }

    if (widget.form.status == 'LOCKED' || widget.form.status == 'AUTO-APPROVED') {
      return Expanded(
        child: Row(
          children: [
            Expanded(
                child: _actionButton(
                    'View', Colors.grey.shade200, Colors.black, widget.onView, false)),
            const SizedBox(width: 8),
            Expanded(
                child: _actionButton('LOCKED', Colors.red, Colors.white, null, false)),
          ],
        ),
      );
    }

    return Expanded(
      child: Row(
        children: [
          Expanded(
              child: _actionButton(
                  'View', Colors.grey.shade200, Colors.black, widget.onView, false)),
          const SizedBox(width: 8),
          Expanded(
              child: _actionButton(
                  widget.form.status, Colors.blue, Colors.white, widget.onRefresh, false)),
        ],
      ),
    );
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
                          content: Text('Please enter rejection comments'),
                        ),
                      );
                      return;
                    }

                    setDialogState(() => isLoading = true);
                    setState(() => _isRejecting = true);

                    try {
                      final result = await ApiService.rejectPremisesForm(
                        formId: widget.form.uid,
                        rejectRemark: remarks,
                      );

                      if (context.mounted) {
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Premises form for ${widget.form.location} rejected successfully!'),
                          ),
                        );

                        if (widget.onRefresh != null) {
                          widget.onRefresh!();
                        }

                        if (widget.onReject != null) {
                          widget.onReject!(remarks);
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

  void _approvePremisesForm(BuildContext context) async {
    setState(() => _isApproving = true);

    try {
      final result = await ApiService.approvePremisesForm(
        formId: widget.form.uid,
      );

      if (mounted) {
        setState(() => _isApproving = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Premises form for ${widget.form.location} approved successfully!'),
            backgroundColor: Colors.green,
          ),
        );


        if (widget.onRefresh != null) {
          widget.onRefresh!();
        }

        if (widget.onApprove != null) {
          widget.onApprove!();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isApproving = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to approve form: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _actionButton(
      String label, Color bgColor, Color textColor, VoidCallback? onTap, bool isLoading) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isLoading ? bgColor.withOpacity(0.6) : bgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(textColor),
            ),
          )
              : Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}