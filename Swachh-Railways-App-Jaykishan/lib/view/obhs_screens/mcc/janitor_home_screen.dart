import 'package:flutter/material.dart';
import 'package:crm_train/model/user_model.dart';
import 'package:crm_train/utills/app_colors.dart';
import 'package:crm_train/repositories/worker_repo.dart';
import '../../../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'obhs_coach_checklist_screen.dart';
import 'package:get/get.dart';
import '../controllers/worker_controller.dart';

class JanitorHomeScreen extends StatefulWidget {
  final UserModel user;
  const JanitorHomeScreen({super.key, required this.user});
  @override
  State<JanitorHomeScreen> createState() => _JanitorHomeScreenState();
}

class _JanitorHomeScreenState extends State<JanitorHomeScreen> {
  Map<String, dynamic>? _runData;
  List<Map<String, dynamic>> _coaches = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAssignment();
  }

  Future<void> _fetchAssignment() async {
    setState(() => _loading = true);
    try {
      final resp = await WorkerRepository.getActiveRun();
      if (resp['success'] == true && resp['hasAssignment'] == true) {
        _runData = resp['run'];
        _coaches = List<Map<String, dynamic>>.from(resp['coaches'] ?? []);
      }
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('My Duty (Janitor)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: kRailwayBlue, elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.logout, color: Colors.white), onPressed: () => Provider.of<AuthProvider>(context, listen: false).logout()),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchAssignment,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : _runData == null
                    ? _buildEmptyState()
                    : _buildContent(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: kRailwayBlue,
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
        label: const Text('Report Issue', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildError() {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 60),
        const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
        const SizedBox(height: 16),
        const Text('Connection Error', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text('$_error', style: TextStyle(color: Colors.grey[600]), textAlign: TextAlign.center),
        const SizedBox(height: 24),
        ElevatedButton(onPressed: _fetchAssignment, child: const Text('Retry')),
      ],
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 60),
        Icon(Icons.check_circle_outline, size: 80, color: Colors.grey[300]),
        const SizedBox(height: 16),
        const Text('No coaches assigned yet.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black54)),
        const SizedBox(height: 8),
        Text('Wait for your supervisor to assign duties.', style: TextStyle(color: Colors.grey[500])),
        const SizedBox(height: 24),
        OutlinedButton(onPressed: _fetchAssignment, child: const Text('Refresh')),
      ],
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWelcomeBanner(),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text('My Assigned Coaches', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
        ),
        if (_coaches.isEmpty)
          Expanded(child: Center(child: Text('No coaches assigned', style: TextStyle(color: Colors.grey[500]))))
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _coaches.length,
              itemBuilder: (_, i) => _buildCoachTile(_coaches[i]),
            ),
          ),
      ],
    );
  }

  Widget _buildWelcomeBanner() {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: kRailwayBlue,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hello, ${widget.user.fullName}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Text('Train: ${_runData?['trainNo'] ?? 'N/A'} ${_runData?['trainName'] ?? ''}',
              style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8))),
        ],
      ),
    );
  }

  Widget _buildCoachTile(Map<String, dynamic> coach) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => ObhsCoachChecklistScreen(
            user: widget.user, coachLabel: coach['coachNo'] ?? 'N/A',
            runInstanceId: _runData?['runInstanceId'],
          ))),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: kRailwayBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.train, color: kRailwayBlue, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Coach ${coach['coachNo']}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(coach['coachType'] ?? 'General', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
