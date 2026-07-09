import 'package:flutter/material.dart';
import 'package:crm_train/model/station_feedback_model.dart';
import 'package:crm_train/repositories/station_feedback_repository.dart';
import 'package:crm_train/utills/app_colors.dart';

class StationFeedbackListScreen extends StatefulWidget {
  final String? stationId;
  const StationFeedbackListScreen({super.key, this.stationId});

  @override
  State<StationFeedbackListScreen> createState() => _StationFeedbackListScreenState();
}

class _StationFeedbackListScreenState extends State<StationFeedbackListScreen> {
  List<StationFeedback> _feedbacks = [];
  FeedbackSummary? _summary;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        StationFeedbackRepository.list(stationId: widget.stationId),
        if (widget.stationId != null) StationFeedbackRepository.getSummary(widget.stationId!),
      ]);
      _feedbacks = results[0] as List<StationFeedback>;
      _summary = results.length > 1 ? results[1] as FeedbackSummary : null;
    } catch (e) {
      if (e.toString().contains('AUTH_ERROR')) {
        _error = 'AUTH_ERROR';
      } else {
        _error = e.toString();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _ratingColor(int r) {
    if (r >= 4) return kSuccessGreen;
    if (r >= 3) return kWarningOrange;
    return kErrorRed;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Station Feedback', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: kRailwayBlue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error == 'AUTH_ERROR'
              ? const Center(child: Text('Authentication error'))
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: kErrorRed),
                          const SizedBox(height: 12),
                          Text(_error!, textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          ElevatedButton(onPressed: _load, child: const Text('Retry')),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          if (_summary != null) ...[
                            Card(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        _summaryTile('Total', _summary!.totalFeedback.toString(), Icons.feedback, kRailwayBlue),
                                        _summaryTile('Avg', _summary!.averageRating.toStringAsFixed(1), Icons.star, kWarningOrange),
                                        _summaryTile('Positive', _summary!.positiveCount.toString(), Icons.thumb_up, kSuccessGreen),
                                        _summaryTile('Negative', _summary!.negativeCount.toString(), Icons.thumb_down, kErrorRed),
                                      ],
                                    ),
                                    if (_summary!.categoryBreakdown.isNotEmpty) ...[
                                      const Divider(height: 24),
                                      const Text('Category Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                      const SizedBox(height: 8),
                                      ..._summary!.categoryBreakdown.entries.map((e) => Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        child: Row(
                                          children: [
                                            Expanded(child: Text(feedbackCategoryLabel(e.key), style: const TextStyle(fontSize: 13))),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: e.value.averageRating >= 4
                                                    ? kSuccessGreen.withOpacity(0.1)
                                                    : e.value.averageRating >= 3
                                                        ? kWarningOrange.withOpacity(0.1)
                                                        : kErrorRed.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text('${e.value.averageRating.toStringAsFixed(1)} (${e.value.count})',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: e.value.averageRating >= 4 ? kSuccessGreen : e.value.averageRating >= 3 ? kWarningOrange : kErrorRed,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          const Text('Recent Feedback', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          if (_feedbacks.isEmpty)
                            const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No feedback yet')))
                          else
                            ..._feedbacks.map((fb) => Card(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              margin: const EdgeInsets.only(bottom: 10),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _ratingColor(fb.rating).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.star, color: _ratingColor(fb.rating), size: 16),
                                              const SizedBox(width: 4),
                                              Text('${fb.rating}', style: TextStyle(color: _ratingColor(fb.rating), fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(feedbackCategoryLabel(fb.category), style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
                                      ],
                                    ),
                                    if (fb.comments.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(fb.comments, style: const TextStyle(color: kTextSecondary, fontSize: 13)),
                                    ],
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Text(fb.stationName, style: const TextStyle(fontSize: 12, color: kTextSecondary)),
                                        const Spacer(),
                                        Text(fb.createdAt.length >= 10 ? fb.createdAt.substring(0, 10) : fb.createdAt,
                                          style: const TextStyle(fontSize: 11, color: kTextSecondary)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            )),
                        ],
                      ),
                    ),
    );
  }

  Widget _summaryTile(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: kTextSecondary)),
      ],
    );
  }
}
