import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:crm_train/utills/app_colors.dart';

class CreateExecutionPlanScreen extends StatefulWidget {
  final String stationId;
  final String stationName;
  const CreateExecutionPlanScreen({super.key, required this.stationId, required this.stationName});

  @override
  State<StatefulWidget> createState() => _CreateExecutionPlanScreenState();
}

class _CreateExecutionPlanScreenState extends State<CreateExecutionPlanScreen> {
  String _selectedDate = DateFormat('dd-MM-yyyy').format(DateTime.now());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EXECUTION PLAN', style: TextStyle(color: Colors.white)),
        backgroundColor: kRailwayBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: const [Icon(Icons.save), SizedBox(width: 8), Icon(Icons.send), SizedBox(width: 8), Icon(Icons.cancel)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPlanDetails(),
            const SizedBox(height: 12),
            _buildManpowerPlan(),
            const SizedBox(height: 12),
            _buildMachineDeployment(),
            const SizedBox(height: 12),
            _buildMaterialPlan(),
            const SizedBox(height: 12),
            _buildGarbagePlan(),
            const SizedBox(height: 12),
            _buildStatusAndActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanDetails() {
    return Card(
      elevation: 2, child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('PLAN DETAILS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        DropdownButtonFormField(value: 'Bhopal Junction', decoration: const InputDecoration(labelText: 'Station', isDense: true), items: ['Bhopal Junction'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (_) {}),
        const SizedBox(height: 8),
        InkWell(onTap: () async {
          final picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2024), lastDate: DateTime.now());
          if (picked != null) setState(() => _selectedDate = DateFormat('dd-MM-yyyy').format(picked));
        }, child: InputDecorator(decoration: const InputDecoration(labelText: 'Date', isDense: true, suffixIcon: Icon(Icons.calendar_today, size: 18)), child: Text(_selectedDate))),
        const SizedBox(height: 8),
        DropdownButtonFormField(value: 'CON-2024-001 - ABC Facility Services', decoration: const InputDecoration(labelText: 'Contract', isDense: true), items: ['CON-2024-001 - ABC Facility Services'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 12)))).toList(), onChanged: (_) {}),
      ])),
    );
  }

  Widget _buildManpowerPlan() {
    return Card(
      elevation: 2, child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('MANPOWER PLAN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        Table(columnWidths: const {0: FlexColumnWidth(1.5), 1: FlexColumnWidth(1), 2: FlexColumnWidth(1), 3: FlexColumnWidth(1), 4: FlexColumnWidth(0.8)}, children: [
          const TableRow(children: [Text('Shift', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), Text('Planned', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), Text('Actual', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), Text('Variance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), Text('', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))]),
          _manRow('Morning', '15', '12', '-3', kWarningOrange),
          _manRow('Afternoon', '10', '10', '0', Colors.green),
          _manRow('Night', '5', '5', '0', Colors.green),
        ]),
        const SizedBox(height: 8),
        OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.edit, size: 16), label: const Text('Edit Manpower Plan', style: TextStyle(fontSize: 12))),
      ])),
    );
  }

  TableRow _manRow(String shift, String planned, String actual, String variance, Color c) {
    return TableRow(children: [Text(shift, style: const TextStyle(fontSize: 11)), Text(planned, style: const TextStyle(fontSize: 11)), Text(actual, style: const TextStyle(fontSize: 11)), Text(variance, style: TextStyle(fontSize: 11, color: c, fontWeight: FontWeight.w600)), Icon(variance == '0' ? Icons.check_circle : Icons.warning, size: 16, color: c)]);
  }

  Widget _buildMachineDeployment() {
    return Card(
      elevation: 2, child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('MACHINE DEPLOYMENT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        Table(columnWidths: const {0: FlexColumnWidth(1), 1: FlexColumnWidth(2), 2: FlexColumnWidth(1), 3: FlexColumnWidth(1.2)}, children: [
          const TableRow(children: [Text('Platform', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), Text('Machine Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), Text('Quantity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))]),
          TableRow(children: [const Text('PF-1', style: TextStyle(fontSize: 11)), const Text('Scrubbing Machine', style: TextStyle(fontSize: 11)), const Text('1', style: TextStyle(fontSize: 11)), Row(children: [Icon(Icons.check_circle, size: 14, color: Colors.green), const Text(' Deployed', style: TextStyle(fontSize: 11))])]),
          TableRow(children: [const Text('PF-1', style: TextStyle(fontSize: 11)), const Text('Platform Sweeper', style: TextStyle(fontSize: 11)), const Text('1', style: TextStyle(fontSize: 11)), Row(children: [Icon(Icons.build, size: 14, color: kWarningOrange), const Text(' Maint.', style: TextStyle(fontSize: 11))])]),
          TableRow(children: [const Text('PF-2', style: TextStyle(fontSize: 11)), const Text('Scrubbing Machine', style: TextStyle(fontSize: 11)), const Text('1', style: TextStyle(fontSize: 11)), Row(children: [Icon(Icons.check_circle, size: 14, color: Colors.green), const Text(' Deployed', style: TextStyle(fontSize: 11))])]),
        ]),
        const SizedBox(height: 8),
        OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.edit, size: 16), label: const Text('Edit Machine Plan', style: TextStyle(fontSize: 12))),
      ])),
    );
  }

  Widget _buildMaterialPlan() {
    return Card(
      elevation: 2, child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('MATERIAL PLAN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        Table(columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(1), 2: FlexColumnWidth(1), 3: FlexColumnWidth(1), 4: FlexColumnWidth(0.8)}, children: [
          const TableRow(children: [Text('Material Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), Text('Required', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), Text('Available', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), Text('Shortage', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), Text('', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))]),
          _matRow('Floor Cleaner', '100 L', '82 L', '18 L', kWarningOrange),
          _matRow('Toilet Cleaner', '50 L', '30 L', '20 L', kErrorRed),
          _matRow('Disinfectant', '30 L', '20 L', '10 L', kWarningOrange),
        ]),
        const SizedBox(height: 8),
        OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.edit, size: 16), label: const Text('Edit Material Plan', style: TextStyle(fontSize: 12))),
      ])),
    );
  }

  TableRow _matRow(String name, String req, String avail, String shortage, Color c) {
    return TableRow(children: [Text(name, style: const TextStyle(fontSize: 11)), Text(req, style: const TextStyle(fontSize: 11)), Text(avail, style: const TextStyle(fontSize: 11)), Text(shortage, style: TextStyle(fontSize: 11, color: c, fontWeight: FontWeight.w600)), Icon(shortage == '0' ? Icons.check_circle : Icons.warning, size: 16, color: c)]);
  }

  Widget _buildGarbagePlan() {
    return Card(
      elevation: 2, child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('GARBAGE DISPOSAL PLAN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        Table(columnWidths: const {0: FlexColumnWidth(1.5), 1: FlexColumnWidth(1), 2: FlexColumnWidth(1), 3: FlexColumnWidth(1.2)}, children: [
          const TableRow(children: [Text('Disposal Point', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), Text('Capacity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), Text('Schedule', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))]),
          TableRow(children: [const Text('PF-1 Point', style: TextStyle(fontSize: 11)), const Text('200 kg', style: TextStyle(fontSize: 11)), const Text('Daily', style: TextStyle(fontSize: 11)), Row(children: [Icon(Icons.check_circle, size: 14, color: Colors.green), const Text(' Active', style: TextStyle(fontSize: 11))])]),
          TableRow(children: [const Text('PF-2 Point', style: TextStyle(fontSize: 11)), const Text('200 kg', style: TextStyle(fontSize: 11)), const Text('Daily', style: TextStyle(fontSize: 11)), Row(children: [Icon(Icons.check_circle, size: 14, color: Colors.green), const Text(' Active', style: TextStyle(fontSize: 11))])]),
        ]),
        const SizedBox(height: 8),
        OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.edit, size: 16), label: const Text('Edit Garbage Plan', style: TextStyle(fontSize: 12))),
      ])),
    );
  }

  Widget _buildStatusAndActions() {
    return Card(
      elevation: 2, child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)), child: const Text('PLAN STATUS: DRAFT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.save, size: 18), label: const Text('Save Draft', style: TextStyle(fontSize: 12)))),
          const SizedBox(width: 8),
          Expanded(child: ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.send, size: 18), label: const Text('Submit for Review', style: TextStyle(fontSize: 12)))),
        ]),
      ])),
    );
  }
}

class ReviewExecutionPlanScreen extends StatelessWidget {
  final String stationId;
  final String stationName;
  const ReviewExecutionPlanScreen({super.key, required this.stationId, required this.stationName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('REVIEW EXECUTION PLAN', style: TextStyle(color: Colors.white)), backgroundColor: kRailwayBlue, iconTheme: const IconThemeData(color: Colors.white)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(elevation: 2, child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('PLAN DETAILS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              const Text('Contractor: ABC Facility Services', style: TextStyle(fontSize: 12)),
              const Text('Station: Bhopal Junction', style: TextStyle(fontSize: 12)),
              const Text('Date: 15-01-2024', style: TextStyle(fontSize: 12)),
              const SizedBox(height: 4),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: kWarningOrange.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)), child: const Text('Status: PENDING REVIEW', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: kWarningOrange))),
            ]))),
            const SizedBox(height: 12),
            _buildReviewSection('MANPOWER PLAN', [
              _reviewRow('Morning', '15', '12', '-3', '⚠️ Shortage', kWarningOrange),
              _reviewRow('Afternoon', '10', '10', '0', '✅ Acceptable', Colors.green),
              _reviewRow('Night', '5', '5', '0', '✅ Acceptable', Colors.green),
            ]),
            const SizedBox(height: 12),
            _buildReviewSection('MACHINE DEPLOYMENT', [
              _reviewRow('PF-1', 'Scrubbing Machine', 'Deployed', '', '✅ Adequate', Colors.green),
              _reviewRow('PF-1', 'Platform Sweeper', 'Maint.', '', '⚠️ Needs Repair', kWarningOrange),
            ]),
            const SizedBox(height: 12),
            _buildReviewSection('MATERIAL PLAN', [
              _reviewRow('Floor Cleaner', '100 L', '82 L', '', '⚠️ Shortage', kWarningOrange),
              _reviewRow('Toilet Cleaner', '50 L', '30 L', '', '🔴 Critical', kErrorRed),
            ]),
            const SizedBox(height: 12),
            Card(elevation: 2, child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('REVIEW DECISION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              Row(children: [
                ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.check, size: 18), label: const Text('Approve', style: TextStyle(fontSize: 12)), style: ElevatedButton.styleFrom(backgroundColor: Colors.green)),
                const SizedBox(width: 8),
                OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.close, size: 18), label: const Text('Reject', style: TextStyle(fontSize: 12)), style: OutlinedButton.styleFrom(foregroundColor: kErrorRed)),
                const SizedBox(width: 8),
                OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.replay, size: 18), label: const Text('Return', style: TextStyle(fontSize: 12))),
              ]),
              const SizedBox(height: 8),
              TextField(decoration: InputDecoration(labelText: 'Remarks', hintText: 'Add review remarks...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), isDense: true), maxLines: 2),
              const SizedBox(height: 8),
              Row(children: [
                ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.send, size: 18), label: const Text('Submit Decision', style: TextStyle(fontSize: 12))),
                const SizedBox(width: 8),
                OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(fontSize: 12))),
              ]),
            ]))),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewSection(String title, List<TableRow> rows) {
    return Card(elevation: 2, child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      const SizedBox(height: 8),
      Table(columnWidths: const {0: FlexColumnWidth(1.2), 1: FlexColumnWidth(1.5), 2: FlexColumnWidth(1), 3: FlexColumnWidth(0.8), 4: FlexColumnWidth(1.5)}, children: [
        const TableRow(children: [Text('Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), Text('', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), Text('', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), Text('', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), Text('Assessment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))]),
        ...rows,
      ]),
    ])));
  }

  TableRow _reviewRow(String a, String b, String c, String d, String assessment, Color color) {
    return TableRow(children: [Text(a, style: const TextStyle(fontSize: 11)), Text(b, style: const TextStyle(fontSize: 11)), Text(c, style: const TextStyle(fontSize: 11)), Text(d, style: const TextStyle(fontSize: 11)), Row(children: [Text(assessment, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600))])]);
  }
}
