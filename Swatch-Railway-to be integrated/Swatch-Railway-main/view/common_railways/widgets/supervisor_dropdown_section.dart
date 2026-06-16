import 'dart:convert';
import 'package:crm_train/services/api_services.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RailwaySupervisor {
  final String uid;
  final String fullName;
  final String division;
  final String? depot;

  RailwaySupervisor({
    required this.uid,
    required this.fullName,
    required this.division,
    this.depot,
  });

  factory RailwaySupervisor.fromJson(Map<String, dynamic> json) {
    return RailwaySupervisor(
      uid: json['uid'],
      fullName: json['fullName'],
      division: json['division'],
      depot: json['depot'],
    );
  }
}

class SupervisorDropdownSection extends StatefulWidget {
  const SupervisorDropdownSection({super.key});

  @override
  State<SupervisorDropdownSection> createState() =>
      _SupervisorDropdownSectionState();
}

class _SupervisorDropdownSectionState extends State<SupervisorDropdownSection> {
  List<RailwaySupervisor> _supervisors = [];
  RailwaySupervisor? _selectedSupervisor;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchSupervisors();
  }

  Future<void> _fetchSupervisors() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('No token found — please log in again.');
      }

      final url = Uri.parse(
          '${ApiService.baseUrl}/api/users/railway-supervisors');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List supervisors = data['supervisors'];
        setState(() {
          _supervisors =
              supervisors.map((e) => RailwaySupervisor.fromJson(e)).toList();
        });
      } else {
        throw Exception('Failed to load supervisors: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }



  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Railway Supervisor *',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),



        DropdownButtonFormField<RailwaySupervisor>(
          decoration: InputDecoration(
            hintText: 'Select Supervisor',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          value: _selectedSupervisor,
          onChanged: (v) {
            setState(() => _selectedSupervisor = v);
          },
          items: _supervisors
              .map(
                (sup) => DropdownMenuItem(
              value: sup,
              child: Text(sup.fullName),
            ),
          )
              .toList(),
        ),

        const SizedBox(height: 20),


        const Text('Division *',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        TextFormField(
          readOnly: true,
          decoration: InputDecoration(
            hintText: 'Auto populated Division',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          controller: TextEditingController(
              text: _selectedSupervisor?.division ?? ''),
        ),
        const SizedBox(height: 5),
        const Text(
          'Auto-populated from your assignment',
          style: TextStyle(color: Colors.blue, fontSize: 13),
        ),

        const SizedBox(height: 20),

        const Text('Depot *',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        TextFormField(
          readOnly: true,
          decoration: InputDecoration(
            hintText: 'Auto populated Depot',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          controller: TextEditingController(
              text: _selectedSupervisor?.depot ?? ''),
        ),
        const SizedBox(height: 5),
        const Text(
          'Auto-populated from your assignment',
          style: TextStyle(color: Colors.blue, fontSize: 13),
        ),
      ],
    );
  }
}
