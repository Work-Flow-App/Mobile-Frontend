import 'package:flutter/material.dart';

// --- Step Enums & Extensions ---
enum StepStatus {
  INITIATED,
  NOT_STARTED,
  PENDING,
  ONGOING,
  STARTED,
  COMPLETED,
  SKIPPED,
}

extension StepStatusExtension on StepStatus {
  String get label => name.replaceAll('_', ' ');

  Color get color {
    switch (this) {
      case StepStatus.COMPLETED:
        return Colors.green.shade700;
      case StepStatus.STARTED:
      case StepStatus.ONGOING:
        return Colors.blue.shade700;
      case StepStatus.PENDING:
        return Colors.red.shade700;
      case StepStatus.SKIPPED:
        return Colors.amber.shade800;
      case StepStatus.INITIATED:
        return Colors.purple.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case StepStatus.COMPLETED:
        return Colors.green.withOpacity(0.15);
      case StepStatus.STARTED:
      case StepStatus.ONGOING:
        return Colors.blue.withOpacity(0.15);
      case StepStatus.PENDING:
        return Colors.red.withOpacity(0.15);
      case StepStatus.SKIPPED:
        return Colors.amber.withOpacity(0.15);
      case StepStatus.INITIATED:
        return Colors.purple.withOpacity(0.15);
      default:
        return Colors.grey.withOpacity(0.15);
    }
  }
}

// --- Original JobStep Model ---
class JobStep {
  final int id;
  final String name;
  final String description;
  final int orderIndex;
  final StepStatus status;
  final List<int> assignedWorkerIds;
  final DateTime? startedAt;
  final DateTime? completedAt;

  JobStep({
    required this.id,
    required this.name,
    required this.description,
    required this.orderIndex,
    required this.status,
    required this.assignedWorkerIds,
    this.startedAt,
    this.completedAt,
  });

  factory JobStep.fromJson(Map<String, dynamic> json) {
    StepStatus mappedStatus = StepStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => StepStatus.NOT_STARTED,
    );

    return JobStep(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? "",
      orderIndex: json['orderIndex'] ?? 0,
      status: mappedStatus,
      assignedWorkerIds: List<int>.from(json['assignedWorkerIds'] ?? []),
      startedAt: json['startedAt'] != null
          ? DateTime.tryParse(json['startedAt'])
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'])
          : null,
    );
  }

  bool isAssignedTo(int workerId) => assignedWorkerIds.contains(workerId);
}

// Job Address Model
class JobAddress {
  final int id;
  final String street;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final String? additionalInfo;
  final double? latitude;
  final double? longitude;

  JobAddress({
    required this.id,
    required this.street,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
    this.additionalInfo,
    this.latitude,
    this.longitude,
  });

  factory JobAddress.fromJson(Map<String, dynamic> json) {
    return JobAddress(
      id: json['id'] ?? 0,
      street: json['street'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      postalCode: json['postalCode'] ?? '',
      country: json['country'] ?? '',
      additionalInfo: json['additionalInfo'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  String get fullAddress => [
    street,
    city,
    state,
    postalCode,
    country,
  ].where((e) => e.isNotEmpty).join(', ');
}

class CustomerAddress {
  final String houseNumber;
  final String street;
  final String city;
  final String county;
  final String postalCode;
  final String country;

  CustomerAddress({
    required this.houseNumber,
    required this.street,
    required this.city,
    required this.county,
    required this.postalCode,
    required this.country,
  });

  factory CustomerAddress.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return CustomerAddress(
        houseNumber: '',
        street: '',
        city: '',
        county: '',
        postalCode: '',
        country: '',
      );
    }
    return CustomerAddress(
      houseNumber: json['houseNumber'] ?? '',
      street: json['street'] ?? '',
      city: json['city'] ?? '',
      county: json['county'] ?? '',
      postalCode: json['postalCode'] ?? '',
      country: json['country'] ?? '',
    );
  }

  String get fullAddress => [
    houseNumber,
    street,
    city,
    postalCode,
    country,
  ].where((e) => e.isNotEmpty).join(', ');
}

class Customer {
  final int id;
  final String name;
  final String email;
  final String telephone;
  final String mobile;
  final CustomerAddress address;

  Customer({
    required this.id,
    required this.name,
    required this.email,
    required this.telephone,
    required this.mobile,
    required this.address,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      telephone: json['telephone'] ?? '',
      mobile: json['mobile'] ?? '',
      address: CustomerAddress.fromJson(json['address']),
    );
  }
}

class AssignedAsset {
  final int assignmentId;
  final int assetId;
  final String? assetName;
  final String? description;
  final String? serialNumber;
  final String? assetTag;
  final String? notes;
  final String status;

  AssignedAsset({
    required this.assignmentId,
    required this.assetId,
    this.assetName,
    this.description,
    this.serialNumber,
    this.assetTag,
    this.notes,
    required this.status,
  });

  factory AssignedAsset.fromJson(Map<String, dynamic> json) {
    return AssignedAsset(
      assignmentId: json['assignmentId'] ?? 0,
      assetId: json['assetId'] ?? 0,
      assetName: json['assetName'],
      description: json['description'],
      serialNumber: json['serialNumber'],
      assetTag: json['assetTag'],
      notes: json['notes'],
      status: json['status'] ?? 'UNKNOWN',
    );
  }
}

// The new root wrapper for the assigned step response
class JobData {
  final JobStep step;
  final int jobId;
  final int? jobRef;
  final Customer? customer;
  final List<AssignedAsset> assignedAssets;
  final JobAddress? jobAddress; // NEW: Added jobAddress field

  JobData({
    required this.step,
    required this.jobId,
    this.jobRef,
    this.customer,
    required this.assignedAssets,
    this.jobAddress, // NEW
  });

  factory JobData.fromJson(Map<String, dynamic> json) {
    return JobData(
      step: JobStep.fromJson(json['step'] ?? {}),
      jobId: json['jobId'] ?? 0,
      jobRef: json['jobRef'] ?? 0,
      customer: json['customer'] != null
          ? Customer.fromJson(json['customer'])
          : null,
      assignedAssets:
          (json['assignedAssets'] as List<dynamic>?)
              ?.map((e) => AssignedAsset.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      jobAddress: json['jobAddress'] != null
          ? JobAddress.fromJson(json['jobAddress'])
          : null, // NEW: Parse jobAddress
    );
  }
}
