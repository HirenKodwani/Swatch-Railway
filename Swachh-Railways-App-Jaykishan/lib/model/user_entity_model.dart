import 'package:intl/intl.dart';

class EntityModel {
  final String uid;


  final String? contractorName;
  final String? registrationType;
  final String? panNumber;
  final String? gstinNumber;
  final String? registeredAddress;
  final String? contactNumber;
  final String? alternateContact;
  final String? email;
  final String? website;
  final String? yearOfEstablishment;
  final String? gemId;
  final String? status;


  final DateTime? createdAt;
  final String? createdBy;
  final String? createdByName;

  final DateTime? updatedAt;
  final String? updatedBy;
  final String? updatedByName;

  final DateTime? approvedAt;
  final String? approvedBy;
  final String? approvedByName;

  final DateTime? suspendedAt;
  final String? suspendedBy;
  final String? suspendedByName;


  final DateTime? rejectedAt;
  final String? rejectedBy;
  final String? rejectedByName;

  final List<AuditLog>? auditLogs;

  EntityModel({
    required this.uid,
    this.contractorName,
    this.registrationType,
    this.panNumber,
    this.gstinNumber,
    this.registeredAddress,
    this.contactNumber,
    this.alternateContact,
    this.email,
    this.website,
    this.yearOfEstablishment,
    this.gemId,
    this.status,
    this.createdAt,
    this.createdBy,
    this.createdByName,
    this.updatedAt,
    this.updatedBy,
    this.updatedByName,
    this.approvedAt,
    this.approvedBy,
    this.approvedByName,
    this.auditLogs,
    this.suspendedAt,
    this.suspendedBy,
    this.suspendedByName,
    this.rejectedAt,
    this.rejectedBy,
    this.rejectedByName
  });


  factory EntityModel.fromJson(Map<String, dynamic> json) {
    print('=== Entity Model fromJson Debug ===');
    print('createdAt raw: ${json['createdAt']}');
    print('createdBy: ${json['createdBy']}');
    print('createdByName: ${json['createdByName']}');

    final parsedCreatedAt = _parseDateTime(json['createdAt']);
    print('createdAt parsed: $parsedCreatedAt');

    return EntityModel(
      uid: json['uid'] ?? '',

      contractorName: json['companyName'],
      registrationType: json['registrationType'],
      panNumber: json['panNumber'],
      gstinNumber: json['gstinNumber'],
      registeredAddress: json['registeredAddress'],
      contactNumber: json['contactNumber'],
      alternateContact: json['alternateContact'],
      email: json['email'],
      website: json['website'],
      yearOfEstablishment: json['yearOfEstablishment'],
      gemId: json['gemId'],
      status: json['status'],

      createdAt: parsedCreatedAt,
      createdBy: json['createdBy'],
      createdByName: json['createdByName'],

      updatedAt: _parseDateTime(json['updatedAt']),
      updatedBy: json['updatedBy'],
      updatedByName: json['updatedByName'],

      approvedAt: _parseDateTime(json['approvedAt']),
      approvedBy: json['approvedBy'],
      approvedByName: json['approvedByName'],

      suspendedAt: _parseDateTime(json['suspendedAt']),
      suspendedBy: json['suspendedBy'],
      suspendedByName: json['suspendedByName'],


      rejectedAt: _parseDateTime(json['rejectedAt']),
      rejectedBy: json['rejectedBy'],
      rejectedByName: json['rejectedByName'],


      auditLogs: (json['auditLogs'] as List?)
          ?.map((e) => AuditLog.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
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
      'status': status,

      'createdAt': createdAt,
      'createdBy': createdBy,
      'createdByName': createdByName,

      'updatedAt': updatedAt,
      'updatedBy': updatedBy,
      'updatedByName': updatedByName,

      'approvedAt': approvedAt,
      'approvedBy': approvedBy,
      'approvedByName': approvedByName,


      'auditLogs': auditLogs?.map((e) => e.toJson()).toList(),
    };
  }


  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) {
      print('_parseDateTime: value is null');
      return null;
    }

    if (value is String) {
      try {
        final parsed = DateTime.parse(value);
        return parsed.toLocal();
      } catch (e) {
        print('_parseDateTime: ISO format failed, trying custom formats...');
      }

      try {
        final format = DateFormat('dd/MM/yy, h:mm a');
        final parsed = format.parse(value);
        print('_parseDateTime: Successfully parsed custom format (dd/MM/yy, h:mm a) to DateTime: $parsed');
        return parsed;
      } catch (e) {
        print('_parseDateTime: Custom format 1 failed: $e');
      }

      try {
        final format = DateFormat('dd/MM/yy, HH:mm');
        final parsed = format.parse(value);
        print('_parseDateTime: Successfully parsed custom format (dd/MM/yy, HH:mm) to DateTime: $parsed');
        return parsed;
      } catch (e) {
        print('_parseDateTime: Custom format 2 failed: $e');
      }

      print('_parseDateTime: All string parsing attempts failed');
      return null;
    }

    if (value is Map && value['_seconds'] != null) {
      final seconds = value['_seconds'];
      final parsed = DateTime.fromMillisecondsSinceEpoch(
        seconds * 1000,
        isUtc: true,
      ).toLocal();
      print('_parseDateTime: Parsed from Map seconds: $parsed');
      return parsed;
    }

    print('_parseDateTime: No matching format, returning null');
    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EntityModel &&
          runtimeType == other.runtimeType &&
          uid == other.uid;

  @override
  int get hashCode => uid.hashCode;
}




class AuditLog {
  final String? action;
  final String? actor;
  final String? timestamp;
  final String? note;

  AuditLog({this.action, this.actor, this.timestamp, this.note});

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      action: json['action'],
      actor: json['actor'],
      timestamp: json['timestamp'],
      note: json['note'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'action': action,
      'actor': actor,
      'timestamp': timestamp,
      'note': note,
    };
  }
}
