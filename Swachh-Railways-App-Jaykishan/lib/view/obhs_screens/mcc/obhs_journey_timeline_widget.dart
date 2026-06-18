import 'package:flutter/material.dart';
import 'package:crm_train/model/run_instance_model.dart';

class OBHSJourneyTimelineWidget extends StatelessWidget {
  final RunInstanceModel runInstance;
  final VoidCallback? onAdvance;
  final String? userRole;

  const OBHSJourneyTimelineWidget({
    super.key,
    required this.runInstance,
    this.onAdvance,
    this.userRole,
  });

  static const Map<String, Color> stateColors = {
    'PLANNED': Colors.grey,
    'ALLOCATED': Colors.blue,
    'READY': Colors.teal,
    'ACTIVE': Colors.green,
    'DELAYED': Colors.orange,
    'ARRIVED': Colors.purple,
    'CLOSED': Colors.blueGrey,
  };

  static const Map<String, IconData> stateIcons = {
    'PLANNED': Icons.schedule,
    'ALLOCATED': Icons.group_add,
    'READY': Icons.check_circle_outline,
    'ACTIVE': Icons.directions_train,
    'DELAYED': Icons.warning_amber,
    'ARRIVED': Icons.location_on,
    'CLOSED': Icons.lock_outline,
  };

  Color _stateColor(String state) {
    return stateColors[state] ?? Colors.grey;
  }

  IconData _stateIcon(String state) {
    return stateIcons[state] ?? Icons.help_outline;
  }

  String _stateLabel(String state) {
    return RunInstanceModel.stateLabels[state] ?? state;
  }

  @override
  Widget build(BuildContext context) {
    final timeline = runInstance.journeyTimeline;
    final currentState = runInstance.status;
    final canAdvance = runInstance.canTransitionTo(
      RunInstanceModel.validTransitions[currentState]?.first ?? ''
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_stateIcon(currentState), color: _stateColor(currentState), size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Journey Status',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        _stateLabel(currentState),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _stateColor(currentState),
                        ),
                      ),
                    ],
                  ),
                ),
                if (canAdvance && userRole != null && ['CM', 'CA', 'CTS', 'CS'].contains(userRole))
                  TextButton.icon(
                    onPressed: onAdvance,
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    label: Text(
                      'Advance to ${_stateLabel(RunInstanceModel.validTransitions[currentState]?.first ?? '')}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
            if (runInstance.delayMinutes > 0)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_off, size: 16, color: Colors.orange),
                    const SizedBox(width: 6),
                    Text(
                      'Delayed by ${runInstance.delayMinutes} minutes',
                      style: const TextStyle(color: Colors.orange, fontSize: 13),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            if (timeline.isEmpty)
              _buildEmptyTimeline()
            else
              _buildTimeline(context, timeline),
            _buildMetrics(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyTimeline() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Text(
          'No timeline events yet',
          style: TextStyle(color: Colors.grey[400], fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildTimeline(BuildContext context, List<JourneyTimelineEntry> entries) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final isLast = index == entries.length - 1;
        return _buildTimelineItem(entry, isLast);
      },
    );
  }

  Widget _buildTimelineItem(JourneyTimelineEntry entry, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _stateColor(entry.toState),
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: Colors.grey[300],
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _stateLabel(entry.toState),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: _stateColor(entry.toState),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        entry.formattedTime,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  if (entry.fromState != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'from ${_stateLabel(entry.fromState!)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ),
                  if (entry.actorName != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'by ${entry.actorName}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ),
                  if (entry.remarks != null && entry.remarks!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        entry.remarks!,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetrics() {
    final metrics = <Map<String, dynamic>>[];
    if (runInstance.actualDeparture != null) {
      metrics.add({
        'label': 'Departed',
        'value': _formatTime(runInstance.actualDeparture!),
        'icon': Icons.departure_board,
      });
    }
    if (runInstance.actualArrival != null) {
      metrics.add({
        'label': 'Arrived',
        'value': _formatTime(runInstance.actualArrival!),
        'icon': Icons.flight_land,
      });
    }
    if (runInstance.delayMinutes > 0) {
      metrics.add({
        'label': 'Delay',
        'value': '${runInstance.delayMinutes} min',
        'icon': Icons.timer_off,
      });
    }

    if (metrics.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: metrics.map((m) => Expanded(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(m['icon'] as IconData, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m['label'] as String,
                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                  ),
                  Text(
                    m['value'] as String,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } catch (_) {
      return iso;
    }
  }
}
