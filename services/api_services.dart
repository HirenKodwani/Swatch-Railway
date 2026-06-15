import 'dart:convert';
import 'package:crm_train/model/contracts_model.dart';
import 'package:crm_train/model/user_registeration_model.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../helper/api_error_handler.dart';
import '../model/coach_form_model.dart';
import '../model/cts_form_model.dart';
import '../model/premises_form_model.dart';
import '../model/train_model.dart';
import '../model/user_entity_model.dart';

class ApiService {
  static Future<http.Response> _handleRequest(
    Future<http.Response> Function() request,
  ) async {
    try {
      final response = await request().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  static const String baseUrl = 'http://localhost:5000';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  static Future<Map<String, dynamic>> createUser({
    required String userType,
    required String role,
    required String fullName,
    required String designation,
    required String email,
    required String password,
    required String mobile,
    String? zone,
    String? division,
    String? depot,
    String? entityId,
    String? createdById,
  }) async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/api/admin/createUser'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'userType': userType,
          'role': role,
          'fullName': fullName,
          'designation': designation,
          'email': email,
          'mobile': mobile,
          'password': password,
          'zone': zone,
          'division': division,
          'depot': depot,
          'entityId': entityId,
          'createdById': createdById,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to create user');
      }
    } catch (e) {
      throw Exception('Error creating user: $e');
    }
  }

  static Future<Map<String, dynamic>> updateUser({
    required String uid,
    required String userType,
    required String role,
    required String fullName,
    required String designation,
    required String email,
    required String mobile,
    String? zone,
    String? division,
    String? depot,
    String? entityId,
    required String editedById,
  }) async {
    try {
      final token = await getToken();
      final response = await http.put(
        Uri.parse('$baseUrl/api/admin/updateUser/$uid'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'userType': userType,
          'role': role,
          'fullName': fullName,
          'designation': designation,
          'email': email,
          'mobile': mobile,
          'zone': zone,
          'division': division,
          'depot': depot,
          'entityId': entityId,
          'editedById': editedById,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to update user');
      }
    } catch (e) {
      throw Exception('Error updating user: $e');
    }
  }

  static Future<List<UserRegistrationModel>> getPendingUsers() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/master/pending-users'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final List users = data['users'] ?? [];

        final parsedUsers = users
            .map<UserRegistrationModel?>((u) {
              try {
                final userMap = Map<String, dynamic>.from(u);
                print('Parsing user: ${userMap['fullName']}');
                print(
                  'createdAt: ${userMap['createdAt']} (type: ${userMap['createdAt']?.runtimeType})',
                );
                print(
                  'approved_at: ${userMap['approved_at']} (type: ${userMap['approved_at']?.runtimeType})',
                );
                final user = UserRegistrationModel.fromJson(userMap);
                return user;
              } catch (err, stack) {
                print(stack);
                return null;
              }
            })
            .whereType<UserRegistrationModel>()
            .toList();

        print('Successfully parsed ${parsedUsers.length} users');
        return parsedUsers;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to fetch pending users');
      }
    } catch (e, stack) {
      print('Error fetching pending users: $e');
      print(stack);
      throw Exception('Error fetching pending users: $e');
    }
  }

  static Future<List<UserRegistrationModel>> getApprovedUsers() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/users?status=APPROVED'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final List users = data['users'] ?? [];

        return users
            .map<UserRegistrationModel>(
              (u) =>
                  UserRegistrationModel.fromJson(Map<String, dynamic>.from(u)),
            )
            .toList();
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to fetch pending users');
      }
    } catch (e) {
      throw Exception('Error fetching pending users: $e');
    }
  }

  static Future<List<UserRegistrationModel>> getRejectedUsers() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/users?status=REJECTED'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final List users = data['users'] ?? [];

        return users
            .map<UserRegistrationModel>(
              (u) =>
                  UserRegistrationModel.fromJson(Map<String, dynamic>.from(u)),
            )
            .toList();
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to fetch pending users');
      }
    } catch (e) {
      throw Exception('Error fetching pending users: $e');
    }
  }

  static Future<Map<String, dynamic>> approveUser(
    String uid, {
    String? approvedById,
  }) async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/api/master/approveUser/$uid'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'approvedById': approvedById}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to approve user');
      }
    } catch (e) {
      throw Exception('Error approving user: $e');
    }
  }

  static Future<Map<String, dynamic>> rejectUser(String uid) async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/api/master/rejectUser/$uid'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to reject user');
      }
    } catch (e) {
      throw Exception('Error rejecting user: $e');
    }
  }

  //<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<Create Entity>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

  static Future<Map<String, dynamic>> createEntity({
    required String contractorName,
    required String registrationType,
    required String panNumber,
    required String gstinNumber,
    required String registeredAddress,
    String? alternateContact,
    required String contactNumber,
    required String email,
    String? website,
    String? yearOfEstablishment,
    required String gemId,
  }) async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/api/contractors'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'companyName': contractorName,
          'registrationType': registrationType,
          'panNumber': panNumber,
          'gstinNumber': gstinNumber,
          'registeredAddress': registeredAddress,
          'contactNumber': contactNumber,
          'alternateContact': alternateContact,
          'email': email,
          'website': website,
          'yearOfEstablishment': yearOfEstablishment,
          'gemId': gemId,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to create user');
      }
    } catch (e) {
      throw Exception('Error creating user: $e');
    }
  }

  static Future<List<EntityModel>> getPendingEntity() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/contractors?status=PENDING'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        print('=== getPendingEntity API Response ===');
        print(
          'Response body (first 500 chars): ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}',
        );

        final List entity = data['contractors'] ?? [];

        if (entity.isNotEmpty) {
          print('First entity raw data: ${entity[0]}');
          print('createdAt from API: ${entity[0]['createdAt']}');
          print('createdByName from API: ${entity[0]['createdByName']}');
        }

        return entity
            .map<EntityModel>(
              (u) => EntityModel.fromJson(Map<String, dynamic>.from(u)),
            )
            .toList();
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to fetch pending users');
      }
    } catch (e) {
      throw Exception('Error fetching pending users: $e');
    }
  }

  static Future<List<EntityModel>> getApprovedEntity() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/contractors?status=APPROVED'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        print('=== getApprovedEntity API Response ===');
        print(
          'Response body (first 500 chars): ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}',
        );

        final List entity = data['contractors'] ?? [];

        if (entity.isNotEmpty) {
          print('First approved entity raw data: ${entity[0]}');
          print('createdAt from API: ${entity[0]['createdAt']}');
          print('createdByName from API: ${entity[0]['createdByName']}');
        }

        return entity
            .map<EntityModel>(
              (u) => EntityModel.fromJson(Map<String, dynamic>.from(u)),
            )
            .toList();
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to fetch pending users');
      }
    } catch (e) {
      throw Exception('Error fetching pending users: $e');
    }
  }

  static Future<List<EntityModel>> getRejectedEntity() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/contractors?status=REJECTED'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final List entity = data['contractors'] ?? [];

        return entity
            .map<EntityModel>(
              (u) => EntityModel.fromJson(Map<String, dynamic>.from(u)),
            )
            .toList();
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to fetch pending users');
      }
    } catch (e) {
      throw Exception('Error fetching pending users: $e');
    }
  }

  static Future<List<EntityModel>> getSuspendedEntity() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/contractors?status=SUSPENDED'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final List entity = data['contractors'] ?? [];

        return entity
            .map<EntityModel>(
              (u) => EntityModel.fromJson(Map<String, dynamic>.from(u)),
            )
            .toList();
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to fetch pending users');
      }
    } catch (e) {
      throw Exception('Error fetching pending users: $e');
    }
  }

  static Future<Map<String, dynamic>> approveEntity(String id) async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/api/master/approveContractor/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to approve user');
      }
    } catch (e) {
      print("Error in approveEntity: $e");
      throw Exception('Error approving user: $e');
    }
  }

  static Future<Map<String, dynamic>> rejectEntity(String id) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/master/rejectContractor/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to reject user');
      }
    } catch (e) {
      throw Exception('Error rejecting user: $e');
    }
  }

  static Future<Map<String, dynamic>> updateEntity({
    required String uid,
    required Map<String, dynamic> entityData,
  }) async {
    try {
      final token = await getToken();
      final response = await http.put(
        Uri.parse('$baseUrl/api/contractors/$uid'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(entityData),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to update entity');
      }
    } catch (e) {
      print("Error in updateEntity: $e");
      throw Exception('Error updating entity: $e');
    }
  }

  //<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<Create Contracts>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

  static Future<Map<String, dynamic>> createContract({
    required String contractNumber,
    required String contractName,
    required String entityId,
    required String zone,
    String? division,
    String? depot,
    required String startDate,
    required String endDate,
    required String? workCategories,
    String? remarks,
    required String status,
    required String repName,
    required String repDesignation,
    required String repMobile,
    required String repEmail,
    required String repIdProofType,
    required String repIdProofNumber,
  }) async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/api/contracts'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'contractNumber': contractNumber,
          'contractName': contractName,
          'zone': zone,
          'entityId': entityId,
          'division': division,
          'depot': depot,
          'startDate': startDate,
          'endDate': endDate,
          'remarks': remarks,
          'workCategories': workCategories,
          'status': status,
          'repName': repName,
          'repDesignation': repDesignation,
          'repMobile': repMobile,
          'repEmail': repEmail,
          'repIdProofType': repIdProofType,
          'repIdProofNumber': repIdProofNumber,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to create user');
      }
    } catch (e) {
      throw Exception('Error creating user: $e');
    }
  }

  static Future<Map<String, dynamic>> updateContract({
    required String contractId,
    required String status,
    required String repName,
    required String repDesignation,
    required String repMobile,
    required String repEmail,
    required String repIdProofType,
    required String repIdProofNumber,
  }) async {
    try {
      final token = await getToken();
      final response = await http.put(
        Uri.parse('$baseUrl/api/contracts/$contractId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'status': status,
          'repName': repName,
          'repDesignation': repDesignation,
          'repMobile': repMobile,
          'repEmail': repEmail,
          'repIdProofType': repIdProofType,
          'repIdProofNumber': repIdProofNumber,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to update contract');
      }
    } catch (e) {
      throw Exception('Error updating contract: $e');
    }
  }

  static Future<List<ContractModel>> getActiveContracts() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/contracts?status=Active'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List contracts = data['contracts'] ?? [];
      return contracts.map((e) => ContractModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load active contracts');
    }
  }

  static Future<List<ContractModel>> getInActiveContracts() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/contracts?status=Inactive'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List contracts = data['contracts'] ?? [];
      return contracts.map((e) => ContractModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load inactive contracts');
    }
  }

  static Future<List<ContractModel>> getContractsDetails(
    String contractId,
  ) async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/contracts/number/$contractId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final List contract = data['contracts'] ?? [];

        return contract
            .map<ContractModel>(
              (u) => ContractModel.fromJson(Map<String, dynamic>.from(u)),
            )
            .toList();
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to fetch pending users');
      }
    } catch (e) {
      throw Exception('Error fetching pending users: $e');
    }
  }

  static Future<List<ContractModel>> getContractsContractor(
    String entityId,
  ) async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/contracts/by-entity/$entityId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List contracts = data['contracts'] ?? [];
      return contracts.map((e) => ContractModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load inactive contracts');
    }
  }

  static Future<List<ContractModel>> getContractsByStatus(
    String entityId,
    String zone,
    String division,
  ) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/api/contracts/by-entity/$entityId?zone=$zone&division=$division',
      ),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List contracts = data['contracts'] ?? [];
      return contracts.map((e) => ContractModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load inactive contracts');
    }
  }

  static Future<List<ContractModel>> getContractsActive(
    String entityId,
    String zone,
    String division,
  ) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/api/contracts/by-entity/$entityId?zone=$zone&division=$division&status=Active',
      ),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List contracts = data['contracts'] ?? [];
      return contracts.map((e) => ContractModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load inactive contracts');
    }
  }

  //<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<Train APis>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

  static Future<Map<String, dynamic>> sendPassengerOtp({
    required String phone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/passenger/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone}),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 || response.statusCode == 201) {
        return data;
      }
      throw Exception(
        data['message'] ?? data['error'] ?? 'Failed to send passenger OTP',
      );
    } catch (e) {
      throw Exception('Error sending passenger OTP: $e');
    }
  }

  static Future<Map<String, dynamic>> verifyPassengerOtp({
    required String phone,
    required String otp,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/passenger/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone, 'otp': otp}),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 || response.statusCode == 201) {
        return data;
      }
      throw Exception(
        data['message'] ?? data['error'] ?? 'Failed to verify passenger OTP',
      );
    } catch (e) {
      throw Exception('Error verifying passenger OTP: $e');
    }
  }

  static Future<Map<String, dynamic>> createTrain({
    required String? trainNo,
    required String? trainName,
    required String? origin,
    required String? destination,
    required List<String> days,
    required String zone,
    required List<String> trainApplicableFor,
    required String division,
    String? depot,
    required String status,
    String? outboundTrainNo,
    String? inboundTrainNo,
    String? outboundTravelTime,
    String? inboundTravelTime,
    String? layoverDestination,
    String? layoverOrigin,
    String? journeyStartTime,
  }) async {
    try {
      final token = await getToken();

      final body = <String, dynamic>{
        'days': days,
        'zone': zone,
        'division': division,
        'status': status,
        'TrainApplicableFor': trainApplicableFor,
      };

      if (trainNo != null && trainNo.isNotEmpty) {
        body['trainNo'] = trainNo;
      }
      if (trainName != null && trainName.isNotEmpty) {
        body['trainName'] = trainName;
      }
      if (origin != null && origin.isNotEmpty) {
        body['origin'] = origin;
      }
      if (destination != null && destination.isNotEmpty) {
        body['destination'] = destination;
      }
      if (depot != null && depot.isNotEmpty) {
        body['depot'] = depot;
      }

      if (outboundTrainNo != null && outboundTrainNo.isNotEmpty) {
        body['outboundTrainNo'] = outboundTrainNo;
      }

      if (inboundTrainNo != null && inboundTrainNo.isNotEmpty) {
        body['inboundTrainNo'] = inboundTrainNo;
      }

      int totalHours = 0;
      int outboundAndLayoverHours = 0;

      int parseHours(String? timeStr) {
        if (timeStr == null || timeStr.isEmpty) return 0;
        final parts = timeStr.split(':');
        if (parts.length == 3) {
          int days = int.tryParse(parts[0]) ?? 0;
          int hours = int.tryParse(parts[1]) ?? 0;
          return (days * 24) + hours;
        }
        return 0;
      }

      final outH = parseHours(outboundTravelTime);
      final inH = parseHours(inboundTravelTime);
      final layDestH = parseHours(layoverDestination);
      final layOriH = parseHours(layoverOrigin);

      outboundAndLayoverHours = outH + layDestH;
      totalHours = outH + inH + layDestH + layOriH;

      if (totalHours > 0) {
        body['cycleLength'] = (totalHours / 24).ceil();
        if (body['cycleLength'] == 0) body['cycleLength'] = 1;
      }
      if (outboundAndLayoverHours > 0) {
        body['returnOffset'] = (outboundAndLayoverHours / 24).floor();
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/trains'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to create train');
      }
    } catch (e) {
      throw Exception('Error creating train: $e');
    }
  }

  static Future<List<TrainModel>> getActiveTrains() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/trains?status=active'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List trains = data['trains'] ?? [];

        return trains
            .map<TrainModel>(
              (t) => TrainModel.fromJson(Map<String, dynamic>.from(t)),
            )
            .toList();
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to fetch active trains');
      }
    } catch (e) {
      throw Exception('Error fetching active trains: $e');
    }
  }

  static Future<List<TrainModel>> getInactiveTrains() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/trains?status=inactive'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List trains = data['trains'] ?? [];

        return trains
            .map<TrainModel>(
              (t) => TrainModel.fromJson(Map<String, dynamic>.from(t)),
            )
            .toList();
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to fetch inactive trains');
      }
    } catch (e) {
      throw Exception('Error fetching inactive trains: $e');
    }
  }

  static Future<List<TrainModel>> getAllTrains() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/trains'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List trains = data['trains'] ?? [];

        return trains
            .map<TrainModel>(
              (t) => TrainModel.fromJson(Map<String, dynamic>.from(t)),
            )
            .toList();
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to fetch trains');
      }
    } catch (e) {
      throw Exception('Error fetching trains: $e');
    }
  }

  static Future<Map<String, dynamic>> updateTrain({
    required String uid,
    required String? trainNo,
    required String? trainName,
    required String? origin,
    required String? destination,
    required List<String> days,
    required String zone,
    required List<String> trainApplicableFor,
    required String division,
    String? depot,
    required String status,
    String? outboundTrainNo,
    String? inboundTrainNo,
    String? outboundTravelTime,
    String? inboundTravelTime,
    String? layoverDestination,
    String? layoverOrigin,
    String? journeyStartTime,
  }) async {
    try {
      final token = await getToken();

      final body = <String, dynamic>{
        'days': days,
        'zone': zone,
        'division': division,
        'status': status,
        'TrainApplicableFor': trainApplicableFor,
      };

      if (trainNo != null && trainNo.isNotEmpty) {
        body['trainNo'] = trainNo;
      }
      if (trainName != null && trainName.isNotEmpty) {
        body['trainName'] = trainName;
      }
      if (origin != null && origin.isNotEmpty) {
        body['origin'] = origin;
      }
      if (destination != null && destination.isNotEmpty) {
        body['destination'] = destination;
      }
      if (depot != null && depot.isNotEmpty) {
        body['depot'] = depot;
      }

      if (outboundTrainNo != null && outboundTrainNo.isNotEmpty) {
        body['outboundTrainNo'] = outboundTrainNo;
      }

      if (inboundTrainNo != null && inboundTrainNo.isNotEmpty) {
        body['inboundTrainNo'] = inboundTrainNo;
      }

      int totalHours = 0;
      int outboundAndLayoverHours = 0;

      int parseHours(String? timeStr) {
        if (timeStr == null || timeStr.isEmpty) return 0;
        final parts = timeStr.split(':');
        if (parts.length == 3) {
          int days = int.tryParse(parts[0]) ?? 0;
          int hours = int.tryParse(parts[1]) ?? 0;
          return (days * 24) + hours;
        }
        return 0;
      }

      final outH = parseHours(outboundTravelTime);
      final inH = parseHours(inboundTravelTime);
      final layDestH = parseHours(layoverDestination);
      final layOriH = parseHours(layoverOrigin);

      outboundAndLayoverHours = outH + layDestH;
      totalHours = outH + inH + layDestH + layOriH;

      if (totalHours > 0) {
        body['cycleLength'] = (totalHours / 24).ceil();
        if (body['cycleLength'] == 0) body['cycleLength'] = 1;
      }
      if (outboundAndLayoverHours > 0) {
        body['returnOffset'] = (outboundAndLayoverHours / 24).floor();
      }

      // DO NOT send outboundDurationStr, inboundDurationStr, layoverDestStr, layoverOriginStr, journeyStartTime
      // as they are not in the backend schema and cause "Invalid field name." on PUT.

      final response = await http.put(
        Uri.parse('$baseUrl/api/trains/$uid'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to update train');
      }
    } catch (e) {
      throw Exception('Error updating train: $e');
    }
  }

  ////<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<Coach form>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

  static Future<Map<String, dynamic>> submitCoachForm({
    required String trainId,
    required String formDateTime,
    required String contractId,
    required int coachCount,
    required List<String> machinesUsed,
    required Map<String, double> chemicals,
    required List<Map<String, String>> manpower,
    required Map<String, String> submittedTo,
    required Map<String, String> signature,
  }) async {
    try {
      final token = await getToken();

      final response = await http.post(
        Uri.parse('$baseUrl/api/coach-forms'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'trainId': trainId,
          'formDateTime': formDateTime,
          'coachCount': coachCount,
          'machinesUsed': machinesUsed,
          'chemicals': chemicals,
          'manpower': manpower,
          'submittedTo': submittedTo,
          'signature': signature,
          'contractId': contractId,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to submit coach form');
      }
    } catch (e) {
      throw Exception('Error submitting coach form: $e');
    }
  }

  static Future<List<TrainModel>> getSupervisors() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/railway-supervisors'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List trains = data['trains'] ?? [];

        return trains
            .map<TrainModel>(
              (t) => TrainModel.fromJson(Map<String, dynamic>.from(t)),
            )
            .toList();
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to fetch trains');
      }
    } catch (e) {
      throw Exception('Error fetching trains: $e');
    }
  }

  Future<CoachFormsResponse?> getSubmittedCoachForms() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/coach-forms/submitted'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return CoachFormsResponse.fromJson(jsonData);
      } else {
        print('Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception: $e');
      return null;
    }
  }

  //<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<Premises Form<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

  static Future<Map<String, dynamic>> submitPremisesForm({
    required String supervisor,
    required String location,
    required String contractId,
    required String formDateTime,
    required List<Map<String, String>> manpower,
    required Map<String, String> submittedTo,
    required Map<String, dynamic> signature,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('No authentication token found. Please log in again.');
      }

      final url = Uri.parse('$baseUrl/api/premises-forms');

      final payload = {
        'supervisor': supervisor,
        'location': location,
        'formDateTime': formDateTime,
        'manpower': manpower,
        'contractId': contractId,
        'submittedTo': submittedTo,
        'signature': signature,
      };

      print('=== API REQUEST ===');
      print('URL: $url');
      print('Payload: ${jsonEncode(payload)}');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print('=== SUCCESS ===');
        print('Response: $data');
        return data;
      } else {
        final errorData = jsonDecode(response.body);
        final errorMsg = errorData['message'] ?? 'Unknown error occurred';
        throw Exception(
          'Failed to submit form: $errorMsg (${response.statusCode})',
        );
      }
    } catch (e) {
      print('=== ERROR ===');
      print('Exception: $e');
      rethrow;
    }
  }

  Future<FormResponse?> getPendingPremiseForm() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/premises-forms'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return FormResponse.fromJson(jsonData);
      } else {
        print('Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception: $e');
      return null;
    }
  }

  Future<FormResponse?> getSubmittedPremiseForm() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/premises-forms/submitted'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return FormResponse.fromJson(jsonData);
      } else {
        print('Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception: $e');
      return null;
    }
  }

  //<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

  //Railway SIDE;

  Future<CoachFormsResponse?> getIncomingCoachForms() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/coach-forms'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return CoachFormsResponse.fromJson(jsonData);
      } else {
        print('Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception: $e');
      return null;
    }
  }

  Future<CoachFormsResponse?> getScoredCoachForm() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/coach-forms?type=history'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return CoachFormsResponse.fromJson(jsonData);
      } else {
        print('Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>> approveManpower({
    required String formId,
  }) async {
    try {
      final token = await getToken();
      final String endpoint = "/api/coach-forms/$formId/approve-manpower";

      final Uri url = Uri.parse("$baseUrl$endpoint");

      print("Approve Manpower URL: $url");

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      print("Response Status: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        return {
          "success": false,
          "message": "Failed to approve manpower",
          "status": response.statusCode,
          "body": response.body,
        };
      }
    } catch (e) {
      return {
        "success": false,
        "message": "Error occurred",
        "error": e.toString(),
      };
    }
  }

  ////

  Future<CoachFormsResponse?> getIncomingApprovedCoachForms() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/coach-forms/pending-scoring'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return CoachFormsResponse.fromJson(jsonData);
      } else {
        print('Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception: $e');
      return null;
    }
  }

  //

  static Future<Map<String, dynamic>> submitCoachScorecard({
    required String formId,
    required String workType,
    required String acwpStatus,
    required String railwaySignatureName,
    required List<Map<String, dynamic>> coachEvaluationTable,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) throw Exception('No authentication token found.');

      final url = Uri.parse('$baseUrl/api/coach-forms/$formId/submit-scoring');

      final body = {
        "workType": workType,
        "acwpStatus": acwpStatus,
        "coachEvaluationTable": coachEvaluationTable,
        "railwaySignatureName": railwaySignatureName,
        "railwaySignatureDate": 'NA',
        "railwayRemarks": 'NA',
      };

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to submit scorecard');
      }
    } catch (e) {
      print('Submit Error: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> saveScoringDraft({
    required String formId,
    required String workType,
    required String acwpStatus,
    required List<Map<String, dynamic>> coachEvaluationTable,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) throw Exception('No authentication token found.');

      final url = Uri.parse(
        '$baseUrl/api/coach-forms/$formId/save-scoring-draft',
      );

      final body = {
        "workType": workType,
        "acwpStatus": acwpStatus,
        "coachEvaluationTable": coachEvaluationTable,
      };

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to save draft');
      }
    } catch (e) {
      print('Draft Error: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getScoringDraft({
    required String formId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) throw Exception('No authentication token found.');

      final url = Uri.parse('$baseUrl/api/coach-forms/$formId');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        return null;
      }
    } catch (e) {
      print('Get Draft Error: $e');
      return null;
    }
  }

  Future<CoachFormsResponse?> getScoredCoachForms({
    String status = 'SCORED',
  }) async {
    try {
      final token = await getToken();

      if (token == null) {
        print('Error: No authentication token found');
        return null;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/coach-forms/submitted?status=$status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return CoachFormsResponse.fromJson(jsonData);
      } else if (response.statusCode == 401) {
        print('Error: Unauthorized - Token may have expired');
        return null;
      } else if (response.statusCode == 403) {
        print('Error: Forbidden - You do not have permission');
        return null;
      } else {
        print('Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception in getScoredCoachForms: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>> acceptScoredForm({
    required String formId,
  }) async {
    try {
      final token = await getToken();
      final String endpoint = "/api/coach-forms/$formId/accept-rating";

      final Uri url = Uri.parse("$baseUrl$endpoint");

      print("Accept Scored URL: $url");

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      print("Response Status: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        return {
          "success": false,
          "message": "Failed to accept scored form",
          "status": response.statusCode,
          "body": response.body,
        };
      }
    } catch (e) {
      return {
        "success": false,
        "message": "Error occurred",
        "error": e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> rejectCoachForm({
    required String formId,
    required String rejectRemark,
  }) async {
    try {
      final token = await getToken();
      final String endpoint = "/api/coach-forms/$formId/reject";

      final Uri url = Uri.parse("$baseUrl$endpoint");

      print("Reject Form URL: $url");

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"rejectionComments": rejectRemark}),
      );

      print("Response Status: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        return {
          "success": false,
          "message": "Failed to reject coach form",
          "status": response.statusCode,
          "body": response.body,
        };
      }
    } catch (e) {
      return {
        "success": false,
        "message": "Error occurred",
        "error": e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> rejectPremisesForm({
    required String formId,
    required String rejectRemark,
  }) async {
    try {
      final token = await getToken();
      final String endpoint = "/api/premises-forms/$formId/reject";

      final Uri url = Uri.parse("$baseUrl$endpoint");

      print("Reject Form URL: $url");

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"rejectionComments": rejectRemark}),
      );

      print("Response Status: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        return {
          "success": false,
          "message": "Failed to reject coach form",
          "status": response.statusCode,
          "body": response.body,
        };
      }
    } catch (e) {
      return {
        "success": false,
        "message": "Error occurred",
        "error": e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> resubmitPremisesForm({
    required String formId,
    required String contractorRemarks,
    required List<Map<String, String>> manpower,
    required Map<String, dynamic> resubmitSign,
  }) async {
    try {
      final token = await getToken();
      final String endpoint = "/api/premises-forms/$formId/resubmit";

      final Uri url = Uri.parse("$baseUrl$endpoint");

      print("Resubmit Form URL: $url");

      final response = await http.put(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "contractorRemarks": contractorRemarks,
          "manpower": manpower,
          "resubmitSign": resubmitSign,
        }),
      );

      print("Response Status: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to resubmit form: ${response.body}");
      }
    } catch (e) {
      throw Exception("Error resubmitting form: $e");
    }
  }

  static Future<Map<String, dynamic>> resubmitCoachForm({
    required String formId,
    required String contractorRemarks,
    required int coachCount,
    required List<String> machinesUsed,
    required Map<String, double> chemicals,
    required List<Map<String, String>> manpower,
    required Map<String, String> resubmitSign,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw Exception('No token found');
    }

    final url = Uri.parse('$baseUrl/api/coach-forms/$formId/resubmit');

    final body = jsonEncode({
      'contractorRemarks': contractorRemarks,
      'coachCount': coachCount,
      'machinesUsed': machinesUsed,
      'chemicals': chemicals,
      'manpower': manpower,
      'resubmitSign': resubmitSign,
    });

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to resubmit form');
    }
  }

  static Future<Map<String, dynamic>> approvePremisesForm({
    required String formId,
  }) async {
    try {
      final token = await getToken();
      final String endpoint = "/api/premises-forms/$formId/approve-manpower";

      final Uri url = Uri.parse("$baseUrl$endpoint");

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        return {
          "success": false,
          "message": "Failed to approve manpower",
          "status": response.statusCode,
          "body": response.body,
        };
      }
    } catch (e) {
      return {
        "success": false,
        "message": "Error occurred",
        "error": e.toString(),
      };
    }
  }

  Future<FormResponse?> getIncomingApprovedPremisesForms() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/premises-forms/pending-scoring'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData is List) {
          return FormResponse(
            count: jsonData.length,
            forms: (jsonData as List).map((e) => FormData.fromJson(e)).toList(),
          );
        } else if (jsonData.containsKey('forms')) {
          return FormResponse.fromJson(jsonData);
        } else {
          return FormResponse(count: 1, forms: [FormData.fromJson(jsonData)]);
        }
      } else {
        print('Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>> submitPremisesScorecard({
    required String formId,
    required String railwaySignatureName,
    required String railwaySignatureDate,
    required List<Map<String, dynamic>> housekeepingItems,
    required List<Map<String, dynamic>> pitLineItems,
    required List<Map<String, dynamic>> disposalItems,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) throw Exception('No authentication token found.');

      final url = Uri.parse(
        '$baseUrl/api/premises-forms/$formId/submit-scoring',
      );

      final body = {
        "railwaySignatureName": railwaySignatureName,
        "railwaySignatureDate": railwaySignatureDate,
        "housekeepingItems": housekeepingItems,
        "pitLineItems": pitLineItems,
        "disposalItems": disposalItems,
      };

      print('=== SUBMIT PREMISES SCORECARD REQUEST ===');
      print('URL: $url');
      print('Payload: ${jsonEncode(body)}');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to submit scorecard');
      }
    } catch (e) {
      print('Submit Error: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> acceptPremisesScoredForm({
    required String formId,
  }) async {
    try {
      final token = await getToken();
      final String endpoint = "/api/premises-forms/$formId/accept-rating";

      final Uri url = Uri.parse("$baseUrl$endpoint");

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        return {
          "success": false,
          "message": "Failed to accept scored form",
          "status": response.statusCode,
          "body": response.body,
        };
      }
    } catch (e) {
      return {
        "success": false,
        "message": "Error occurred",
        "error": e.toString(),
      };
    }
  }

  Future<FormResponse?> getScoredPremisesForm() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/premises-forms?type=history'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return FormResponse.fromJson(jsonData);
      } else {
        print('Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception: $e');
      return null;
    }
  }

  ///<<<<<<<<<<<<<<<<<<<<<<<<<REPORT>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

  static Future<dynamic> getPremisesReportData({
    required String startDate,
    required String endDate,
    required String areaType,
    String? depot,
    String? contractId,
    String? contractorId,
    String? division,
    required String zone,
  }) async {
    final token = await getToken();
    final uri = Uri.parse(
      "$baseUrl/api/reports/premises-data?"
      "areaType=$areaType&"
      "startDate=$startDate&"
      "endDate=$endDate&"
      "zone=$zone&"
      "division=$division&"
      "depot=$depot&"
      "contractorId=$contractorId&"
      "contractId=$contractId",
    );

    try {
      final response = await http.get(
        uri,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      throw Exception("Error: $e");
    }
  }

  // <<<<<<<<<<<<<<<<<<<<<<<<<<< Premises Report>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> -

  static Future<dynamic> getCoachReportData({
    String? startDate,
    String? endDate,
    String? depot,
    String? division,
    String? trainNo,
    String? contractId,
    String? coachNo,
    String? contractorId,
    String? zone,
  }) async {
    final token = await getToken();
    final uri = Uri.parse(
      "$baseUrl/api/reports/coach-data?"
      "startDate=$startDate&"
      "endDate=$endDate&"
      "zone=$zone&"
      "division=$division&"
      "depot=$depot&"
      "trainNo=$trainNo&"
      "contractorId=$contractorId&"
      "coachNo=$coachNo&"
      "contractId=$contractId",
    );

    try {
      final response = await http.get(
        uri,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      throw Exception("Error: $e");
    }
  }

  static Future<Map<String, dynamic>> getPremisesStatistics({
    required String userRole,
    required String uid,
    String? zone,
    String? division,
    String? depot,
  }) async {
    final token = await getToken();
    final uri = Uri.parse(
      "$baseUrl/api/reports/premises-statistics?"
      "userRole=$userRole&"
      "uid=$uid&"
      "zone=${zone ?? ''}&"
      "division=${division ?? ''}&"
      "depot=${depot ?? ''}",
    );

    try {
      final response = await http.get(
        uri,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      throw Exception("Error: $e");
    }
  }

  static Future<Map<String, dynamic>> getCoachStatistics({
    required String userRole,
    required String uid,
    String? zone,
    String? division,
    String? depot,
  }) async {
    final token = await getToken();
    final uri = Uri.parse(
      "$baseUrl/api/reports/coach-statistics?"
      "userRole=$userRole&"
      "uid=$uid&"
      "zone=${zone ?? ''}&"
      "division=${division ?? ''}&"
      "depot=${depot ?? ''}",
    );

    try {
      final response = await http.get(
        uri,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      throw Exception("Error: $e");
    }
  }

  static Future<Map<String, dynamic>> getDashboardStats({
    String? zone,
    String? division,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('AUTH_ERROR');
      }

      final queryParams = <String, String>{};
      if (zone != null && zone.isNotEmpty) queryParams['zone'] = zone;
      if (division != null && division.isNotEmpty)
        queryParams['division'] = division;
      if (startDate != null && startDate.isNotEmpty)
        queryParams['startDate'] = startDate;
      if (endDate != null && endDate.isNotEmpty)
        queryParams['endDate'] = endDate;

      final uri = Uri.parse(
        "$baseUrl/api/dashboard/stats${queryParams.isNotEmpty ? '?' : ''}${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}",
      );

      final response = await _handleRequest(
        () => http.get(
          uri,
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        ),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        await clearToken();
        throw Exception('AUTH_ERROR');
      } else {
        throw Exception(
          ApiErrorHandler.getErrorMessage(response.body, response.statusCode),
        );
      }
    } catch (e) {
      if (e.toString().contains('AUTH_ERROR')) {
        rethrow;
      }
      print('Error in getDashboardStats: $e');
      throw Exception(ApiErrorHandler.getErrorMessage(e, null));
    }
  }

  static Future<Map<String, dynamic>> getUserStats({
    String? zone,
    String? division,
    String? depot,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('AUTH_ERROR');
      }

      final queryParams = <String, String>{};
      if (zone != null && zone.isNotEmpty) queryParams['selectedZone'] = zone;
      if (division != null && division.isNotEmpty)
        queryParams['selectedDivision'] = division;
      if (depot != null && depot.isNotEmpty)
        queryParams['selectedDepot'] = depot;

      final uri = Uri.parse(
        "$baseUrl/api/dashboard/user-stats${queryParams.isNotEmpty ? '?' : ''}${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}",
      );

      final response = await _handleRequest(
        () => http.get(
          uri,
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        ),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        await clearToken();
        throw Exception('AUTH_ERROR');
      } else {
        throw Exception(
          ApiErrorHandler.getErrorMessage(response.body, response.statusCode),
        );
      }
    } catch (e) {
      if (e.toString().contains('AUTH_ERROR')) {
        rethrow;
      }
      print('Error in getUserStats: $e');
      throw Exception(ApiErrorHandler.getErrorMessage(e, null));
    }
  }

  static Future<Map<String, dynamic>> getTrainStats({
    String? zone,
    String? division,
    String? depot,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('AUTH_ERROR');
      }

      final queryParams = <String, String>{};
      if (zone != null && zone.isNotEmpty) queryParams['selectedZone'] = zone;
      if (division != null && division.isNotEmpty)
        queryParams['selectedDivision'] = division;
      if (depot != null && depot.isNotEmpty)
        queryParams['selectedDepot'] = depot;

      final uri = Uri.parse(
        "$baseUrl/api/dashboard/train-stats${queryParams.isNotEmpty ? '?' : ''}${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}",
      );

      final response = await _handleRequest(
        () => http.get(
          uri,
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        ),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        await clearToken();
        throw Exception('AUTH_ERROR');
      } else {
        throw Exception(
          ApiErrorHandler.getErrorMessage(response.body, response.statusCode),
        );
      }
    } catch (e) {
      if (e.toString().contains('AUTH_ERROR')) {
        rethrow;
      }
      print('Error in getTrainStats: $e');
      throw Exception(ApiErrorHandler.getErrorMessage(e, null));
    }
  }

  static Future<Map<String, dynamic>> getFormsStats({
    required String formType,
    String? zone,
    String? division,
    int? days,
    String? entityId,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('AUTH_ERROR');
      }

      final queryParams = <String, String>{'formType': formType};
      if (zone != null && zone.isNotEmpty) queryParams['zone'] = zone;
      if (division != null && division.isNotEmpty)
        queryParams['division'] = division;
      if (days != null) queryParams['days'] = days.toString();
      if (entityId != null && entityId.isNotEmpty)
        queryParams['entityId'] = entityId;

      final uri = Uri.parse(
        "$baseUrl/api/all-forms/stats?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}",
      );

      final response = await _handleRequest(
        () => http.get(
          uri,
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        ),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        await clearToken();
        throw Exception('AUTH_ERROR');
      } else {
        throw Exception(
          ApiErrorHandler.getErrorMessage(response.body, response.statusCode),
        );
      }
    } catch (e) {
      if (e.toString().contains('AUTH_ERROR')) {
        rethrow;
      }
      print('Error in getFormsStats: $e');
      throw Exception(ApiErrorHandler.getErrorMessage(e, null));
    }
  }

  static Future<Map<String, dynamic>> getCoachStats() async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('AUTH_ERROR');
      }

      final response = await _handleRequest(
        () => http.get(
          Uri.parse('$baseUrl/api/reports/coach-stats'),
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        ),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        await clearToken();
        throw Exception('AUTH_ERROR');
      } else {
        throw Exception(
          ApiErrorHandler.getErrorMessage(response.body, response.statusCode),
        );
      }
    } catch (e) {
      if (e.toString().contains('AUTH_ERROR')) {
        rethrow;
      }
      print('Error in getCoachStats: $e');
      throw Exception(ApiErrorHandler.getErrorMessage(e, null));
    }
  }

  static Future<Map<String, dynamic>> getPremisesStats() async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('AUTH_ERROR');
      }

      final response = await _handleRequest(
        () => http.get(
          Uri.parse('$baseUrl/api/reports/premises-stats'),
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        ),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        await clearToken();
        throw Exception('AUTH_ERROR');
      } else {
        throw Exception(
          ApiErrorHandler.getErrorMessage(response.body, response.statusCode),
        );
      }
    } catch (e) {
      if (e.toString().contains('AUTH_ERROR')) {
        rethrow;
      }
      print('Error in getPremisesStats: $e');
      throw Exception(ApiErrorHandler.getErrorMessage(e, null));
    }
  }

  // cts - apis

  static Future<List<TrainModel>> getCTSTrains() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/trains?applicableFor=CTS&status=active'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List trains = data['trains'] ?? [];

        return trains
            .map<TrainModel>(
              (t) => TrainModel.fromJson(Map<String, dynamic>.from(t)),
            )
            .toList();
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to fetch active trains');
      }
    } catch (e) {
      throw Exception('Error fetching active trains: $e');
    }
  }

  static Future<Map<String, dynamic>> submitCTSForm({
    required String trainId,
    required String contractId,
    required String formDateTime,
    required String platform,
    required String actArrival,
    required String actDeparture,
    required String workStart,
    required String workEnd,
    required String allowedWindow,
    required String lateYN,
    required int coachesInRake,
    required int coachesAttended,
    required List<Map<String, String>> attendanceStaff,
    required bool garbageDisposed,
    required String nominatedLocation,
    required int occupiedToilets,
    required String notes,
    required Map<String, String> submittedTo,
    required Map<String, String> signature,
  }) async {
    try {
      final token = await getToken();

      final response = await http.post(
        Uri.parse('$baseUrl/api/cts-forms'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'trainId': trainId,
          'contractId': contractId,
          'formDateTime': formDateTime,
          'platform': platform,
          'actArrival': actArrival,
          'actDeparture': actDeparture,
          'workStart': workStart,
          'workEnd': workEnd,
          'allowedWindow': allowedWindow,
          'lateYN': lateYN,
          'coachesInRake': coachesInRake,
          'coachesAttended': coachesAttended,
          'attendanceStaff': attendanceStaff,
          'garbageDisposed': garbageDisposed,
          'nominatedLocation': nominatedLocation,
          'occupiedToilets': occupiedToilets,
          'notes': notes,
          'submittedTo': submittedTo,
          'signature': signature,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to submit CTS form');
      }
    } catch (e) {
      throw Exception('Error submitting CTS form: $e');
    }
  }

  Future<CTSFormsResponse?> getSubmittedCTSForms() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/cts-forms'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return CTSFormsResponse.fromJson(jsonData);
      } else {
        print('Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception: $e');
      return null;
    }
  }

  Future<CTSFormsResponse?> getPendingCTSForms() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/cts-forms?type=history'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return CTSFormsResponse.fromJson(jsonData);
      } else {
        print('Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>> approveCTSForm({
    required String formId,
  }) async {
    try {
      final token = await getToken();
      final String endpoint = "/api/cts-forms/$formId/approve-manpower";

      final Uri url = Uri.parse("$baseUrl$endpoint");

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'message': 'Failed to approve CTS form'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> rejectCTSForm({
    required String formId,
    required String rejectRemark,
  }) async {
    try {
      final token = await getToken();
      final String endpoint = "/api/cts-forms/$formId/reject";

      final Uri url = Uri.parse("$baseUrl$endpoint");

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"rejectionComments": rejectRemark}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'CTS form rejected successfully',
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to reject CTS form: ${response.body}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error rejecting CTS form: $e'};
    }
  }

  static Future<Map<String, dynamic>> submitCTSScorecard({
    required String formId,
    required Map<String, dynamic> inspectionHeader,
    required List<Map<String, dynamic>> coachEvaluationTable,
    required List<String> machinesUsed,
    required List<Map<String, dynamic>> chemicals,
    required String railwaySignatureName,
    required String railwaySignatureDate,
  }) async {
    try {
      final token = await getToken();
      final String endpoint = "/api/cts-forms/$formId/submit-scoring";

      final Uri url = Uri.parse("$baseUrl$endpoint");

      final requestBody = {
        "inspectionHeader": inspectionHeader,
        "coachEvaluationTable": coachEvaluationTable,
        "machinesUsed": machinesUsed,
        "chemicals": chemicals,
        "railwaySignatureName": railwaySignatureName,
        "railwaySignatureDate": railwaySignatureDate,
      };

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'CTS scorecard submitted successfully',
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to submit CTS scorecard: ${response.body}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error submitting CTS scorecard: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> acceptCTSScoredForm({
    required String formId,
  }) async {
    try {
      final token = await getToken();
      final String endpoint = "/api/cts-forms/$formId/accept-rating";

      final Uri url = Uri.parse("$baseUrl$endpoint");

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        return {
          "success": false,
          "message": "Failed to accept CTS scored form",
          "status": response.statusCode,
          "body": response.body,
        };
      }
    } catch (e) {
      return {
        "success": false,
        "message": "Error occurred",
        "error": e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> resubmitCTSForm({
    required String formId,
    required String contractorRemarks,
    required String trainId,
    required String trainNumber,
    required String trainName,
    required String jobDate,
    required String actArrival,
    required String actDeparture,
    required String workStart,
    required String workEnd,
    required String platform,
    required String allowedWindow,
    required String lateYN,
    required int coachesInRake,
    required int coachesAttended,
    required List<Map<String, String>> attendanceStaff,
    required bool garbageDisposed,
    required String nominatedLocation,
    required int occupiedToilets,
    required String notes,
    required Map<String, String> resubmitSign,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw Exception('No token found');
    }

    final url = Uri.parse('$baseUrl/api/cts-forms/$formId/resubmit');

    final body = jsonEncode({
      'contractorRemarks': contractorRemarks,
      'trainId': trainId,
      'trainNumber': trainNumber,
      'trainName': trainName,
      'jobDate': jobDate,
      'actArrival': actArrival,
      'actDeparture': actDeparture,
      'workStart': workStart,
      'workEnd': workEnd,
      'platform': platform,
      'allowedWindow': allowedWindow,
      'lateYN': lateYN,
      'coachesInRake': coachesInRake,
      'coachesAttended': coachesAttended,
      'attendanceStaff': attendanceStaff,
      'garbageDisposed': garbageDisposed,
      'nominatedLocation': nominatedLocation,
      'occupiedToilets': occupiedToilets,
      'notes': notes,
      'resubmitSign': resubmitSign,
    });

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to resubmit CTS form');
    }
  }

  static Future<Map<String, dynamic>> getCTSStatistics({
    required String userRole,
    required String uid,
    String? zone,
    String? division,
    String? depot,
  }) async {
    final token = await getToken();
    final uri = Uri.parse(
      "$baseUrl/api/reports/cts-stats?"
      "userRole=$userRole&"
      "uid=$uid&"
      "zone=${zone ?? ''}&"
      "division=${division ?? ''}&"
      "depot=${depot ?? ''}",
    );

    try {
      final response = await http.get(
        uri,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      throw Exception("Error: $e");
    }
  }

  static Future<dynamic> getCTSReportData({
    String? startDate,
    String? endDate,
    String? depot,
    String? division,
    String? trainNo,
    String? contractId,
    String? contractorId,
    String? zone,
  }) async {
    final token = await getToken();
    final uri = Uri.parse(
      "$baseUrl/api/reports/cts-data?"
      "startDate=$startDate&"
      "endDate=$endDate&"
      "zone=$zone&"
      "division=$division&"
      "depot=$depot&"
      "trainNo=$trainNo&"
      "contractorId=$contractorId&"
      "contractId=$contractId",
    );

    try {
      final response = await http.get(
        uri,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      throw Exception("Error: $e");
    }
  }

  static Future<Map<String, dynamic>> getCTSStats() async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('AUTH_ERROR');
      }

      final response = await _handleRequest(
        () => http.get(
          Uri.parse('$baseUrl/api/reports/cts-stats'),
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        ),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        await clearToken();
        throw Exception('AUTH_ERROR');
      } else {
        throw Exception(
          ApiErrorHandler.getErrorMessage(response.body, response.statusCode),
        );
      }
    } catch (e) {
      if (e.toString().contains('AUTH_ERROR')) {
        rethrow;
      }
      print('Error in getCTSStats: $e');
      throw Exception(ApiErrorHandler.getErrorMessage(e, null));
    }
  }
}
