import 'package:crm_train/data/zone_database.dart';
import 'package:crm_train/model/user_registeration_model.dart';
import 'package:crm_train/providers/auth_provider.dart';
import 'package:crm_train/services/api_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../utills/app_colors.dart';
import '../widgets/approve_entity_dropdown.dart';


class UserEditScreen extends StatefulWidget {
  final UserRegistrationModel user;

  const UserEditScreen({super.key, required this.user});

  @override
  State<UserEditScreen> createState() => _UserEditScreenState();
}

class _UserEditScreenState extends State<UserEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullName;
  late TextEditingController _designation;
  late TextEditingController _email;
  late TextEditingController _mobile;

  late String _selectedUserType;
  String? _selectedRole;
  String? _selectedCompany;
  String? _zone;
  String? _division;
  String? _depot;

  List<String> zones = [];
  List<String> divisions = [];
  List<String> depots = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fullName = TextEditingController(text: widget.user.fullName);
    _designation = TextEditingController(text: widget.user.designation);
    _email = TextEditingController(text: widget.user.email);
    _mobile = TextEditingController(text: widget.user.mobile);

    _selectedUserType = widget.user.userType?.toLowerCase() ?? 'railway';
    _selectedRole = widget.user.role;
    _zone = widget.user.zone;
    _division = widget.user.division;
    _depot = widget.user.depot;
    _selectedCompany = widget.user.entityId;

    zones = DepotDatabase.zoneData.keys.toList();
    if (_zone != null) {
      divisions = DepotDatabase.zoneData[_zone]?.keys.toList() ?? [];
      if (_division != null) {
        depots = DepotDatabase.zoneData[_zone]?[_division] ?? [];
      }
    }
  }

  void _loadDivisions(String zone) {
    setState(() {
      divisions = DepotDatabase.zoneData[zone]?.keys.toList() ?? [];
      _division = null;
      depots = [];
      _depot = null;
    });
  }

  void _loadDepots(String zone, String division) {
    setState(() {
      depots = DepotDatabase.zoneData[zone]?[division] ?? [];
      _depot = null;
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  bool _shouldShowZone() {
    if (_selectedRole == null) return false;
    return true;
  }

  bool _shouldShowDivision() {
    if (_selectedRole == null || _zone == null) return false;
    return _selectedRole!.contains('Admin') || _selectedRole!.contains('Supervisor') || _selectedRole!.contains('Worker');
  }

  bool _shouldShowDepot() {
    if (_selectedRole == null || _division == null) return false;
    return _selectedRole!.contains('Supervisor') || _selectedRole!.contains('Worker');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: kRailwayBlue,
        title: const Text('Edit User', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'User Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kRailwayBlue,
                ),
              ),
              const SizedBox(height: 16),


              DropdownButtonFormField<String>(
                value: _selectedUserType,
                decoration: const InputDecoration(
                  labelText: 'User Type *',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'railway', child: Text('Railway')),
                  DropdownMenuItem(value: 'contractor', child: Text('Contractor')),
                ],
                onChanged: null,
              ),
              const SizedBox(height: 12),


              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Role *',
                  border: OutlineInputBorder(),
                ),
                items: _getRolesForUserType(_selectedUserType)
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                validator: (v) => v == null ? 'Select role' : null,
                onChanged: (v) => setState(() {
                  _selectedRole = v;
                  _zone = null;
                  _division = null;
                  _depot = null;
                  divisions = [];
                  depots = [];
                }),
              ),
              const SizedBox(height: 12),


              if (_selectedUserType == 'contractor')
                ApprovedEntityDropdown(
                  initialValue: _selectedCompany,
                  onSelected: (name) {
                    setState(() {
                      _selectedCompany = name;
                    });
                  },
                ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _fullName,
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),


              TextFormField(
                controller: _designation,
                decoration: const InputDecoration(
                  labelText: 'Designation *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),


              TextFormField(
                controller: _email,
                decoration: const InputDecoration(
                  labelText: 'Official Email *',
                  border: OutlineInputBorder(),
                ),
                enabled: false,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _mobile,
                decoration: const InputDecoration(
                  labelText: 'Mobile Number *',
                  border: OutlineInputBorder(),
                  hintText: '10 digit number',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (v.length != 10) return '10 digits required';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              const Text(
                'Location Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kRailwayBlue,
                ),
              ),
              const SizedBox(height: 16),


              if (_shouldShowZone())
                Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _zone,
                      decoration: InputDecoration(
                        labelText: 'Zone *',
                        border: const OutlineInputBorder(),
                        helperText: _selectedRole?.contains('Master') == true
                            ? 'Master has access to entire zone'
                            : null,
                      ),
                      items: zones
                          .map((z) => DropdownMenuItem(value: z, child: Text(z)))
                          .toList(),
                      validator: (v) => v == null ? 'Required' : null,
                      onChanged: (v) {
                        setState(() {
                          _zone = v;
                          if (_selectedRole?.contains('Master') == true) {
                            _division = null;
                            _depot = null;
                            divisions = [];
                            depots = [];
                          } else if (v != null) {
                            _loadDivisions(v);
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                ),


              if (_shouldShowDivision())
                Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _division,
                      decoration: InputDecoration(
                        labelText: 'Division *',
                        border: const OutlineInputBorder(),
                        helperText: _selectedRole!.contains('Admin')
                            ? 'Admin has access to entire division'
                            : null,
                      ),
                      items: divisions
                          .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                          .toList(),
                      validator: (v) => v == null ? 'Required' : null,
                      onChanged: (v) {
                        setState(() {
                          _division = v;
                          if (v != null && _zone != null) {
                            _loadDepots(_zone!, v);
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                ),


              if (_shouldShowDepot())
                Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _depot,
                      decoration: const InputDecoration(
                        labelText: 'Depot',
                        border: OutlineInputBorder(),
                        helperText: 'Supervisor manages this depot',
                      ),
                      items: depots
                          .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                          .toList(),
                      onChanged: (v) => setState(() => _depot = v),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),

              const SizedBox(height: 24),


              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kRailwayBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: const Text(
                    'Update User',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  onPressed: _submitForm,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _getRolesForUserType(String userType) {
    if (userType == 'railway') {
      return ['Railway Master', 'Railway Admin', 'Railway Supervisor', 'Railway Worker'];
    } else {
      return ['Contractor Master', 'Contractor Admin', 'Contractor Supervisor', 'Contractor Worker'];
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = Provider.of<AuthProvider>(context, listen: false).currentUser;


    if (currentUser?.uid == widget.user.uid) {
      _showError('You cannot edit your own account');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await ApiService.updateUser(
        uid: widget.user.uid,
        userType: _selectedUserType,
        role: _selectedRole!,
        fullName: _fullName.text.trim(),
        designation: _designation.text.trim(),
        email: _email.text.trim(),
        mobile: _mobile.text.trim(),
        zone: _zone?.trim().isEmpty ?? true ? null : _zone?.trim(),
        division: _division?.trim().isEmpty ?? true ? null : _division?.trim(),
        depot: _depot?.trim().isEmpty ?? true ? null : _depot?.trim(),
        entityId: _selectedCompany?.trim().isEmpty ?? true ? null : _selectedCompany?.trim(),
        editedById: currentUser?.uid ?? '',
        status: 'PENDING',
      );

      setState(() => _isLoading = false);

      final message = result['message'] ?? 'User updated successfully';
      _showSuccess(message);

      await Future.delayed(const Duration(seconds: 1));
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to update user: ${e.toString()}');
    }
  }

  @override
  void dispose() {
    _fullName.dispose();
    _designation.dispose();
    _email.dispose();
    _mobile.dispose();
    super.dispose();
  }
}
