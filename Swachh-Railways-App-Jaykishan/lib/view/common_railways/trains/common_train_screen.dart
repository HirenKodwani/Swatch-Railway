import 'package:crm_train/utills/app_colors.dart';
import 'package:crm_train/model/train_model.dart';
import 'package:crm_train/view/common_railways/trains/train_from_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../services/api_services.dart';
import '../../../services/draft_storage_service.dart';
import '../widgets/rolevise_dropdowns.dart';


class CommonTrainScreen extends StatefulWidget {
  const CommonTrainScreen({super.key});

  @override
  State<CommonTrainScreen> createState() => _CommonTrainScreenState();
}

class _CommonTrainScreenState extends State<CommonTrainScreen> with SingleTickerProviderStateMixin {
  List<TrainModel> activeTrains = [];
  List<TrainModel> inactiveTrains = [];
  List<Map<String, dynamic>> trainDrafts = [];
  String search = "";
  late TabController _tabController;
  bool _isFilterExpanded = false;
  bool _isLoading = true;
  int activeCount = 0;
  int inactiveCount = 0;

  String? _selectedFilterZone;
  String? _selectedFilterDivision;
  String? _selectedFilterDepot;


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser = Provider.of<AuthProvider>(context, listen: false).currentUser;
      if (currentUser?.role == 'Railway Master' ||
          currentUser?.role == 'Railway Admin' ||
          currentUser?.role == 'Railway Supervisor' ||
          currentUser?.role == 'Contractor Master' ||
          currentUser?.role == 'Contractor Admin' ||
          currentUser?.role == 'Contractor Supervisor') {
        setState(() {
          _selectedFilterZone = currentUser?.zone;
          if (currentUser?.role == 'Railway Admin' ||
              currentUser?.role == 'Railway Supervisor' ||
              currentUser?.role == 'Contractor Admin' ||
              currentUser?.role == 'Contractor Supervisor') {
            _selectedFilterDivision = currentUser?.division;
          }
          if (currentUser?.role == 'Railway Supervisor' ||
              currentUser?.role == 'Contractor Supervisor') {
            _selectedFilterDepot = currentUser?.depot;
          }
        });
      }
    });

    _loadTrains();
    _loadDrafts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDrafts() async {
    final currentUser = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (currentUser?.uid == null) return;

    try {
      final drafts = await DraftStorageService.getTrainDrafts(currentUser!.uid!);
      setState(() {
        trainDrafts = drafts;
      });
    } catch (e) {
      print('Error loading drafts: $e');
    }
  }

  Future<void> _deleteDraft(String draftId) async {
    final currentUser = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (currentUser?.uid == null) return;

    final success = await DraftStorageService.deleteTrainDraft(
      currentUserId: currentUser!.uid!,
      draftId: draftId,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Draft deleted successfully'), backgroundColor: Colors.green),
      );
      await _loadDrafts();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete draft'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _openDraft(Map<String, dynamic> draft) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrainFormScreen(
          draftData: draft,
          draftId: draft['draftId'],
        ),
      ),
    );

    if (result == true) {
      await _loadDrafts();
      await _loadTrains();
    }
  }

  Future<void> _loadTrains() async {
    setState(() => _isLoading = true);

    try {
      final activeList = await ApiService.getActiveTrains();
      final inactiveList = await ApiService.getInactiveTrains();

      setState(() {
        activeTrains = activeList;
        inactiveTrains = inactiveList;
        _isLoading = false;
      });

    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading trains: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<TrainModel> _applyRoleBasedFiltering(List<TrainModel> trains) {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;

    return trains.where((t) {
      if (user?.role == 'Railway Master' || user?.role == 'Contractor Master') {
        if (user?.zone != null && t.zone != user?.zone) {
          return false;
        }
      } else if (user?.role == 'Railway Admin' || user?.role == 'Contractor Admin') {
        if (user?.zone != null && t.zone != user?.zone) {
          return false;
        }
        if (user?.division != null && t.division != user?.division) {
          return false;
        }
      } else if (user?.role == 'Railway Supervisor' || user?.role == 'Contractor Supervisor') {
        if (user?.zone != null && t.zone != user?.zone) {
          return false;
        }
        if (user?.division != null && t.division != user?.division) {
          return false;
        }
        if (user?.depot != null && t.depot != null && t.depot != user?.depot) {
          return false;
        }
      }
      return true;
    }).toList();
  }


  List<TrainModel> _applyFilters(List<TrainModel> trains) {
    return trains.where((t) {
      // First apply role-based filtering
      final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
      if (user?.role == 'Railway Master' || user?.role == 'Contractor Master') {
        if (user?.zone != null && t.zone != user?.zone) return false;
      } else if (user?.role == 'Railway Admin' || user?.role == 'Contractor Admin') {
        if (user?.zone != null && t.zone != user?.zone) return false;
        if (user?.division != null && t.division != user?.division) return false;
      } else if (user?.role == 'Railway Supervisor' || user?.role == 'Contractor Supervisor') {
        if (user?.zone != null && t.zone != user?.zone) return false;
        if (user?.division != null && t.division != user?.division) return false;
        if (user?.depot != null && t.depot != null && t.depot != user?.depot) return false;
      }
      // Then apply manual filter selections
      if (_selectedFilterZone != null && t.zone != _selectedFilterZone) return false;
      if (_selectedFilterDivision != null && t.division != _selectedFilterDivision) return false;
      if (_selectedFilterDepot != null && t.depot != null && t.depot != _selectedFilterDepot) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;

    final filteredActiveTrains = _applyFilters(activeTrains);
    final filteredInactiveTrains = _applyFilters(inactiveTrains);
    activeCount = filteredActiveTrains.length;
    inactiveCount = filteredInactiveTrains.length;


    final currentUser = Provider.of<AuthProvider>(context, listen: false).currentUser;
    final bool canAddTrains = currentUser != null &&
        (currentUser.role == 'Company Master' ||
         currentUser.role == 'Railway Master' ||
         currentUser.role == 'Railway Admin' ||
         currentUser.role == 'Contractor Master' ||
         currentUser.role == 'Contractor Admin');

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: const Text(
            "Train Management",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          backgroundColor: kRailwayBlue,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              tooltip: 'Refresh Trains',
              onPressed: _loadTrains,
            ),
          ],
        ),

        body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  hintText: "Search by Train No. / Name",
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                onChanged: (v) => setState(() => search = v),
              ),
            ),
          ),

          if (user?.role != 'Railway Supervisor')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() {
                          _isFilterExpanded = !_isFilterExpanded;
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.filter_list, color: kRailwayBlue, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Filter',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            const Spacer(),
                            AnimatedRotation(
                              turns: _isFilterExpanded ? 0.5 : 0,
                              duration: const Duration(milliseconds: 300),
                              child: Icon(
                                Icons.keyboard_arrow_down,
                                color: kRailwayBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: _isFilterExpanded
                          ? Padding(
                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Divider(height: 1, color: Colors.grey.shade200),
                            const SizedBox(height: 16),
                            ZoneDivisionDepotDropdowns(
                              key: ValueKey('${_selectedFilterZone}_${_selectedFilterDivision}_${_selectedFilterDepot}'),
                              user: user!,
                              initialZone: _selectedFilterZone,
                              initialDivision: _selectedFilterDivision,
                              initialDepot: _selectedFilterDepot,
                              onChangedWithZone: (zone, division, depot) {
                                setState(() {
                                  _selectedFilterZone = zone;
                                  _selectedFilterDivision = division;
                                  _selectedFilterDepot = depot;
                                });
                              },
                            ),
                            const SizedBox(height: 14),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedFilterZone = null;
                                  _selectedFilterDivision = null;
                                  _selectedFilterDepot = null;
                                });
                              },
                              child: Text(
                                'Clear All Filters',
                                style: TextStyle(
                                  color: kRailwayBlue,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 10),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: kRailwayBlue,
                    unselectedLabelColor: Colors.black54,
                    indicatorColor: kRailwayBlue,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    dividerColor: Colors.transparent,
                    tabs: [
                      Tab(text: "Active ($activeCount)"),
                      Tab(text: "Inactive ($inactiveCount)"),
                      Tab(text: "Drafts (${trainDrafts.length})"),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _trainListView(filteredActiveTrains),
                      _trainListView(filteredInactiveTrains),
                      _buildDraftsTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: canAddTrains ?
      FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TrainFormScreen()),
          );
          _loadTrains();
          _loadDrafts();
        },
        backgroundColor: kRailwayBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Add Train",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ) : null
    );
  }

  Widget _trainListView(List<TrainModel> list) {
    List<TrainModel> filteredTrains = list.where((t) {
      bool matchesSearch = search.isEmpty ||
          (t.trainNo?.toLowerCase().contains(search.toLowerCase()) ?? false) ||
          (t.trainName?.toLowerCase().contains(search.toLowerCase()) ?? false);

      bool matchesZone = _selectedFilterZone == null ||
          t.zone == _selectedFilterZone;

      bool matchesDivision = _selectedFilterDivision == null ||
          t.division == _selectedFilterDivision;

      bool matchesDepot = _selectedFilterDepot == null ||
          t.depot == _selectedFilterDepot;

      return matchesSearch && matchesZone && matchesDivision && matchesDepot;
    }).toList();

    if (filteredTrains.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.train, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              "No trains found",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: filteredTrains.length,
      itemBuilder: (_, index) {
        TrainModel t = filteredTrains[index];
        bool isActive = t.status.toLowerCase() == 'active';

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ],
          ),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isActive ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.train,
                color: isActive ? Colors.green : Colors.red,
                size: 28,
              ),
            ),
            title: Text(
              "${t.trainNo ?? 'Draft'} · ${t.trainName ?? 'Unnamed'}",
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        "${t.origin ?? '-'} → ${t.destination ?? '-'}",
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _statusPill(t),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _showTrainDetails(t),
                  icon: Icon(Icons.remove_red_eye),
                  tooltip: "View Details",
                ),
                IconButton(
                  onPressed: () => _editTrain(t),
                  icon: Icon(Icons.edit),
                  tooltip: "Edit Train",
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  Widget _statusPill(TrainModel t) {
    String label;
    Color color;
    if (t.trainNo == null || t.trainNo!.isEmpty) {
      label = "Draft";
      color = Colors.grey.shade400;
    } else if (t.status.toLowerCase() == 'active') {
      label = "Active";
      color = Colors.green;
    } else {
      label = "Inactive";
      color = Colors.red;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showTrainDetails(TrainModel t) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => TrainDetailsBottomSheet(
        train: t,
        onEdit: () {
          Navigator.pop(context);
          _editTrain(t);
        },
      ),
    );
  }

  void _editTrain(TrainModel t) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TrainFormScreen(train: t)),
    ).then((_) => _loadTrains());
  }

  Widget _buildDraftsTab() {
    if (trainDrafts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.drafts_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No saved drafts',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Save a draft when creating a new train to see it here',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: trainDrafts.length,
      itemBuilder: (context, idx) {
        final draft = trainDrafts[idx];

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ],
          ),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.train,
                color: Colors.grey.shade600,
                size: 28,
              ),
            ),
            title: Text(
              "${draft['trainNo']?.toString().isNotEmpty == true ? draft['trainNo'] : 'Draft'} · ${draft['trainName']?.toString().isNotEmpty == true ? draft['trainName'] : 'Unnamed'}",
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        "${draft['origin']?.toString().isNotEmpty == true ? draft['origin'] : '-'} → ${draft['destination']?.toString().isNotEmpty == true ? draft['destination'] : '-'}",
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade400, width: 1),
                  ),
                  child: Text(
                    'Draft',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _openDraft(draft),
                  icon: Icon(Icons.edit,),
                  tooltip: "Edit Draft",
                ),

                IconButton(
                  onPressed: () => _deleteDraft(draft['draftId']),
                  icon: Icon(Icons.delete,),
                  tooltip: "Delete Draft",
                ),
              ],
            ),

          ),
        );
      },
    );
  }

  void _editDraft(Map<String, dynamic> draft) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Draft'),
        content: const Text('Do you want to edit or delete this draft?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteDraft(draft['draftId']);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _openDraft(draft);
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }
}

class TrainDetailsBottomSheet extends StatelessWidget {
  final TrainModel train;
  final VoidCallback onEdit;

  const TrainDetailsBottomSheet({
    super.key,
    required this.train,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    bool isActive = train.status.toLowerCase() == 'active';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.train,
                    color: isActive ? Colors.green : Colors.red,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        train.trainName ?? "Unnamed Train",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Train No: ${train.trainNo ?? 'Draft'}",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            _detailRow(Icons.location_on_outlined, "Origin Station", train.origin ?? "-"),
            _detailRow(Icons.flag_outlined, "Destination Station", train.destination ?? "-"),
            _detailRow(Icons.map_outlined, "Zone", train.zone),
            _detailRow(Icons.account_tree_outlined, "Division", train.division),
            _detailRow(Icons.warehouse_outlined, "Depot", train.depot ?? "-"),
            _detailRow(
              Icons.calendar_today_outlined,
              "Running Days",
              train.days.isEmpty ? "-" : train.days.join(", "),
            ),
            _detailRow(
              Icons.toggle_on_outlined,
              "Status",
              isActive ? "Active" : "Inactive",
              statusColor: isActive ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 24),

            //  AUDIT LOGS SECTION
            const SizedBox(height: 20),
            const Text(
              'Audit Logs',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kRailwayBlue),
            ),
            const SizedBox(height: 12),


            if (train.createdBy != null || train.createdAt != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade200, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: kRailwayBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.add_circle_outline, size: 20, color: kRailwayBlue),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Created',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: kRailwayBlue),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (train.createdByName != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            const SizedBox(width: 8),
                            const Text('Created By: ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            Expanded(
                              child: Text(
                                train.createdByName!,
                                style: const TextStyle(fontSize: 13, color: Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (train.createdAt != null)
                      Row(
                        children: [
                          const SizedBox(width: 8),
                          const Text('Created At: ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          Expanded(
                            child: Text(
                              DateFormat('dd/MM/yyyy · hh:mm a').format(train.createdAt!.toLocal()),
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],


            if (train.updatedBy != null || train.updatedAt != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade300, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.edit_outlined, size: 20, color: Colors.orange.shade700),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Last Updated',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.orange.shade700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (train.updatedByName != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            const SizedBox(width: 8),
                            const Text('Updated By: ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            Expanded(
                              child: Text(
                                train.updatedByName!,
                                style: const TextStyle(fontSize: 13, color: Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (train.updatedAt != null)
                      Row(
                        children: [
                          const SizedBox(width: 8),
                          const Text('Updated At: ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          Expanded(
                            child: Text(
                              DateFormat('dd/MM/yyyy · hh:mm a').format(train.updatedAt!.toLocal()),
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],


            if (train.createdBy == null &&
                train.createdAt == null &&
                train.updatedBy == null &&
                train.updatedAt == null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey.shade600),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No audit logs available for this train',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ),
                  ],
                ),
              ),


            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    label: const Text("Close"),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, color: Colors.white),
                    label: const Text("Edit"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kRailwayBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, {Color? statusColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: statusColor ?? Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


