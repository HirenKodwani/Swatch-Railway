import 'package:crm_train/model/station_cleaning_models.dart';
import 'package:crm_train/repositories/scorecard_repository.dart';
import 'package:crm_train/utills/app_colors.dart';
import 'package:flutter/material.dart';

class ScorecardListScreen extends StatefulWidget {
  final String stationId;
  final String stationName;
  const ScorecardListScreen({super.key, required this.stationId, required this.stationName});

  @override
  State<ScorecardListScreen> createState() => _ScorecardListScreenState();
}

class _ScorecardListScreenState extends State<ScorecardListScreen> {
  bool _isLoading = false;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  List<Scorecard> _scorecards = [];

  @override
  void initState() {
    super.initState();
    _loadScorecards();
  }

  Future<void> _loadScorecards() async {
    setState(() => _isLoading = true);
    try {
      final startFormatted =
          "${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}";
      final endFormatted =
          "${_endDate.year}-${_endDate.month.toString().padLeft(2, '0')}-${_endDate.day.toString().padLeft(2, '0')}";
      final query = {
        'stationId': widget.stationId,
        'startDate': startFormatted,
        'endDate': endFormatted,
        'month': _selectedMonth.toString(),
        'year': _selectedYear.toString(),
      };
      final list = await ScorecardRepository.list(query);
      setState(() => _scorecards = list);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load scorecards: $e'), backgroundColor: kErrorRed),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _autoGenerate() async {
    setState(() => _isLoading = true);
    try {
      final today =
          "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";
      await ScorecardRepository.autoGenerate(widget.stationId, today);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Scorecard auto-generated'), backgroundColor: kSuccessGreen),
        );
        _loadScorecards();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: kErrorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitScorecard(Scorecard sc) async {
    setState(() => _isLoading = true);
    try {
      await ScorecardRepository.submit(sc.uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Scorecard submitted'), backgroundColor: kSuccessGreen),
        );
        _loadScorecards();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: kErrorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _approveScorecard(Scorecard sc) async {
    setState(() => _isLoading = true);
    try {
      await ScorecardRepository.approve(sc.uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Scorecard approved'), backgroundColor: kSuccessGreen),
        );
        _loadScorecards();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: kErrorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _rejectScorecard(Scorecard sc) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Scorecard'),
        content: TextField(
          controller: reasonCtrl,
          decoration: const InputDecoration(labelText: 'Reason', border: OutlineInputBorder()),
          maxLines: 2,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (reasonCtrl.text.trim().isEmpty) return;
              try {
                await ScorecardRepository.reject(sc.uid, reasonCtrl.text.trim());
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Scorecard rejected'), backgroundColor: kErrorRed),
                  );
                  _loadScorecards();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: kErrorRed),
                  );
                }
              }
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _showMonthlySummary() async {
    setState(() => _isLoading = true);
    try {
      final summary = await ScorecardRepository.monthlySummary(widget.stationId, _selectedMonth, _selectedYear);
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Monthly Summary - $_selectedMonth/$_selectedYear'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: summary.entries.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text('${e.key}: ${e.value}', style: const TextStyle(fontSize: 14)),
                )).toList(),
              ),
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load summary: $e'), backgroundColor: kErrorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _statusColor(String status) {
    switch (ScorecardStatus.values.firstWhere((e) => e.name == status, orElse: () => ScorecardStatus.draft)) {
      case ScorecardStatus.draft:
        return Colors.grey;
      case ScorecardStatus.submitted:
        return Colors.blue;
      case ScorecardStatus.approved:
        return kSuccessGreen;
      case ScorecardStatus.rejected:
        return kErrorRed;
    }
  }

  Color _gradeColor(String? grade) {
    switch (grade) {
      case 'A+':
        return const Color(0xFF1B5E20);
      case 'A':
        return kSuccessGreen;
      case 'B+':
        return Colors.teal;
      case 'B':
        return kWarningOrange;
      case 'C':
        return kErrorRed;
      case 'D':
        return const Color(0xFFB71C1C);
      default:
        return Colors.grey;
    }
  }

  Widget _detailCard(Scorecard sc) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ExpansionTile(
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Date: ${sc.date}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Score: ${sc.overallStationScore}', style: TextStyle(color: kRailwayBlue, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            if (sc.grade != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _gradeColor(sc.grade).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _gradeColor(sc.grade!)),
                ),
                child: Text(sc.grade!, style: TextStyle(color: _gradeColor(sc.grade), fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _statusColor(sc.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _statusColor(sc.status)),
              ),
              child: Text(
                sc.status.toUpperCase(),
                style: TextStyle(color: _statusColor(sc.status), fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: sc.parameters.entries.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.key, style: const TextStyle(fontWeight: FontWeight.w500)),
                    Text('${e.value}', style: const TextStyle(color: kRailwayBlue)),
                  ],
                ),
              )).toList(),
            ),
          ),
          if (sc.status == 'draft')
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _submitScorecard(sc),
                  style: ElevatedButton.styleFrom(backgroundColor: kWarningOrange, foregroundColor: Colors.white),
                  child: const Text('Submit'),
                ),
              ),
            ),
          if (sc.status == 'submitted')
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _approveScorecard(sc),
                      style: ElevatedButton.styleFrom(backgroundColor: kSuccessGreen, foregroundColor: Colors.white),
                      child: const Text('Approve'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _rejectScorecard(sc),
                      style: ElevatedButton.styleFrom(backgroundColor: kErrorRed, foregroundColor: Colors.white),
                      child: const Text('Reject'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scorecards - ${widget.stationName}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: kRailwayBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.summarize), onPressed: _showMonthlySummary, tooltip: 'Monthly Summary'),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadScorecards),
        ],
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _startDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() => _startDate = picked);
                          _loadScorecards();
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'From', border: OutlineInputBorder(), isDense: true),
                        child: Text(
                          "${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}",
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _endDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() => _endDate = picked);
                          _loadScorecards();
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'To', border: OutlineInputBorder(), isDense: true),
                        child: Text(
                          "${_endDate.year}-${_endDate.month.toString().padLeft(2, '0')}-${_endDate.day.toString().padLeft(2, '0')}",
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 80,
                    child: TextFormField(
                      initialValue: _selectedMonth.toString(),
                      decoration: const InputDecoration(labelText: 'Month', border: OutlineInputBorder(), isDense: true),
                      keyboardType: TextInputType.number,
                      onFieldSubmitted: (v) {
                        final m = int.tryParse(v);
                        if (m != null && m >= 1 && m <= 12) {
                          setState(() => _selectedMonth = m);
                          _loadScorecards();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 80,
                    child: TextFormField(
                      initialValue: _selectedYear.toString(),
                      decoration: const InputDecoration(labelText: 'Year', border: OutlineInputBorder(), isDense: true),
                      keyboardType: TextInputType.number,
                      onFieldSubmitted: (v) {
                        final y = int.tryParse(v);
                        if (y != null && y >= 2020) {
                          setState(() => _selectedYear = y);
                          _loadScorecards();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ElevatedButton.icon(
                onPressed: _autoGenerate,
                icon: const Icon(Icons.auto_fix_high),
                label: const Text('Auto-Generate Scorecard'),
                style: ElevatedButton.styleFrom(backgroundColor: kRailwayBlue, foregroundColor: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _scorecards.isEmpty
                    ? const Center(child: Text('No scorecards found'))
                    : RefreshIndicator(
                        onRefresh: _loadScorecards,
                        child: ListView.builder(
                          itemCount: _scorecards.length,
                          itemBuilder: (context, idx) => _detailCard(_scorecards[idx]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
