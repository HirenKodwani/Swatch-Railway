import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../model/contracts_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/api_services.dart';

class ContractorMasterMyContractsScreen extends StatefulWidget {
  const ContractorMasterMyContractsScreen({super.key});

  @override
  State<ContractorMasterMyContractsScreen> createState() =>
      _ContractorMasterMyContractsScreenState();
}

class _ContractorMasterMyContractsScreenState
    extends State<ContractorMasterMyContractsScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  bool _showCompanyDetails = true;
  late TabController _tabController;

  List<ContractModel> allContracts = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadContracts();
  }

  Future<void> _loadContracts() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final entityId = authProvider.entityDetails?['uid'] ?? '';
      final zone = authProvider.userData?['zone'] ?? '';
      final division = authProvider.userData?['division'] ?? '';

      if (entityId.isEmpty) {
        throw Exception('Entity ID not found');
      }
      final contracts = await ApiService.getContractsByStatus(
        entityId,
        zone,
        division,
      );

      setState(() {
        allContracts = contracts;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  List<ContractModel> get activeContracts =>
      allContracts.where((c) => c.status?.toLowerCase() == 'active').toList();

  List<ContractModel> get inactiveContracts =>
      allContracts.where((c) => c.status?.toLowerCase() != 'active').toList();

  List<ContractModel> getFilteredContracts(bool isActive) {
    List<ContractModel> contracts =
    isActive ? activeContracts : inactiveContracts;

    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      contracts = contracts.where((c) {
        return (c.contractNumber?.toLowerCase().contains(query) ?? false) ||
            (c.contractName?.toLowerCase().contains(query) ?? false) ||
            (c.zone?.toLowerCase().contains(query) ?? false) ||
            (c.division?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    return contracts;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'My Company & Contracts',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFF1565C0),
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadContracts,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? _buildErrorWidget()
          : NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildCompanyProfileCard(),
                  _buildStatisticsRow(),
                ],
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyTabBarDelegate(
                TabBar(
                  controller: _tabController,
                  indicatorColor: const Color(0xFF1565C0),
                  indicatorWeight: 3,
                  labelColor: const Color(0xFF1565C0),
                  unselectedLabelColor: Colors.grey,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  tabs: [
                    Tab(
                      text: 'Active (${activeContracts.length})',
                    ),
                    Tab(
                      text: 'Inactive (${inactiveContracts.length})',
                    ),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SearchBarDelegate(
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search contracts...',
                    prefixIcon: const Icon(Icons.search,
                        color: Color(0xFF1565C0)),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                        });
                      },
                    )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF5F7FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildContractsList(true),
            _buildContractsList(false),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading contracts',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? 'Unknown error',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadContracts,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyProfileCard() {
    final authProvider = Provider.of<AuthProvider>(context);
    final entityDetails = authProvider.entityDetails;

    final companyName = entityDetails?['companyName'] ?? 'N/A';
    final registrationType = entityDetails?['registrationType'] ?? 'N/A';
    final pan = entityDetails?['panNumber'] ?? 'N/A';
    final gst = entityDetails?['gstinNumber'] ?? 'N/A';
    final address = entityDetails?['registeredAddress'] ?? 'N/A';
    final contact = entityDetails?['contactNumber'] ?? 'N/A';
    final alternateContact = entityDetails?['alternateContact'] ?? 'N/A';
    final email = entityDetails?['email'] ?? 'N/A';
    final website = entityDetails?['website'] ?? '';
    final yearEstablished = entityDetails?['yearOfEstablishment'] ?? 'N/A';
    final gemId = entityDetails?['gemId'] ?? 'N/A';
    final status = entityDetails?['status'] ?? 'N/A';
    final isActive = status == 'APPROVED';

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.business,
                    color: Colors.white,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        companyName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              registrationType,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isActive ? Colors.green : Colors.red,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              status,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _showCompanyDetails
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: () {
                    setState(() {
                      _showCompanyDetails = !_showCompanyDetails;
                    });
                  },
                ),
              ],
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: _showCompanyDetails
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Container(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: [
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: 16),
                  _buildCompanyDetailRow(Icons.badge, 'PAN', pan),
                  _buildCompanyDetailRow(Icons.receipt_long, 'GSTIN', gst),
                  _buildCompanyDetailRow(
                      Icons.card_membership, 'GEM ID', gemId),
                  _buildCompanyDetailRow(
                      Icons.calendar_today, 'Established', yearEstablished),
                  _buildCompanyDetailRow(Icons.location_on, 'Address', address,
                      maxLines: 2),
                  _buildCompanyDetailRow(Icons.phone, 'Contact', contact),
                  _buildCompanyDetailRow(
                      Icons.phone_android, 'Alt. Contact', alternateContact),
                  _buildCompanyDetailRow(Icons.email, 'Email', email),
                  if (website.isNotEmpty)
                    _buildCompanyDetailRow(Icons.language, 'Website', website),
                ],
              ),
            ),
            secondChild: const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyDetailRow(IconData icon, String label, String value,
      {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Contracts',
              allContracts.length.toString(),
              Icons.description,
              const Color(0xFF1565C0),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Active Contracts',
              activeContracts.length.toString(),
              Icons.check_circle,
              const Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Inactive Contracts',
              inactiveContracts.length.toString(),
              Icons.cancel,
              const Color(0xFFD32F2F),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContractsList(bool isActive) {
    final contracts = getFilteredContracts(isActive);

    if (contracts.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _searchController.text.isNotEmpty
                    ? Icons.search_off
                    : Icons.folder_open,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                _searchController.text.isNotEmpty
                    ? 'No contracts found'
                    : 'No ${isActive ? 'active' : 'inactive'} contracts',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: contracts.length,
      itemBuilder: (context, index) {
        return _buildContractCard(contracts[index]);
      },
    );
  }

  Widget _buildContractCard(ContractModel contract) {
    final endDate = contract.endDate != null
        ? DateTime.parse(contract.endDate!)
        : DateTime.now();
    final daysRemaining = endDate.difference(DateTime.now()).inDays;
    final isExpiringSoon = daysRemaining > 0 && daysRemaining <= 30;
    final isActive = contract.status?.toLowerCase() == 'active';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? const Color(0xFF1565C0).withOpacity(0.2)
              : Colors.grey.shade300,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFF1565C0).withOpacity(0.05)
                  : Colors.grey.shade100,
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        contract.contractNumber ?? 'N/A',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFF2E7D32)
                            : Colors.grey.shade600,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        (contract.status ?? 'N/A').toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  contract.contractName ?? 'N/A',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildContractDetailRow(
                  Icons.location_city,
                  'Zone',
                  contract.zone ?? 'N/A',
                ),
                _buildContractDetailRow(
                  Icons.place,
                  'Division',
                  contract.depot != null
                      ? '${contract.division ?? 'N/A'} (${contract.depot})'
                      : contract.division ?? 'N/A',
                ),
                _buildContractDetailRow(
                  Icons.work,
                  'Categories',
                  (contract.workCategories != null && contract.workCategories!.isNotEmpty)
                      ? (contract.workCategories is List
                      ? (contract.workCategories as List).join(', ')
                      : contract.workCategories.toString())
                      : 'N/A',
                ),

                _buildContractDetailRow(
                  Icons.calendar_today,
                  'Duration',
                  '${_formatDate(contract.startDate)} - ${_formatDate(contract.endDate)}',
                ),
                if (isActive && daysRemaining > 0)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isExpiringSoon
                          ? Colors.orange.shade50
                          : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isExpiringSoon
                            ? Colors.orange.shade200
                            : Colors.blue.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isExpiringSoon
                              ? Icons.warning_amber
                              : Icons.info_outline,
                          color: isExpiringSoon
                              ? Colors.orange.shade700
                              : Colors.blue.shade700,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isExpiringSoon
                                ? 'Expires in $daysRemaining days'
                                : '$daysRemaining days remaining',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isExpiringSoon
                                  ? Colors.orange.shade700
                                  : Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContractDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 18),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _StickyTabBarDelegate(this.tabBar);

  @override
  double get minExtent => 48;
  @override
  double get maxExtent => 48;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) {
    return false;
  }
}

class _SearchBarDelegate extends SliverPersistentHeaderDelegate {
  final TextField searchField;

  _SearchBarDelegate(this.searchField);

  @override
  double get minExtent => 68;
  @override
  double get maxExtent => 68;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: searchField,
    );
  }

  @override
  bool shouldRebuild(_SearchBarDelegate oldDelegate) {
    return false;
  }
}