import 'package:flutter/material.dart';

class AssetAddress {
  final int? id;
  final String street;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final String? additionalInfo;
  final double? latitude;
  final double? longitude;

  AssetAddress({
    this.id,
    required this.street,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
    this.additionalInfo,
    this.latitude,
    this.longitude,
  });

  factory AssetAddress.fromJson(Map<String, dynamic> json) {
    return AssetAddress(
      id: json['id'],
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

  Map<String, dynamic> toJson() {
    return {
      'street': street,
      'city': city,
      'state': state,
      'postalCode': postalCode,
      'country': country,
      if (additionalInfo != null) 'additionalInfo': additionalInfo,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  String get fullAddress => [
    street,
    city,
    state,
    postalCode,
    country,
  ].where((e) => e.isNotEmpty).join(', ');
}

class AssetAssignment {
  final int assignmentId;
  final int assetId;
  final int jobId;
  final int assignedWorkerId;
  final String assetName;
  final String description;
  final String serialNumber;
  final String assetTag;
  final String notes;
  final DateTime? assignedAt;
  final DateTime? returnedAt;
  final int? durationDays;
  final String status;
  final String locationType;
  final AssetAddress? address;
  final int? expectedDurationDays;
  final bool slaBreached;

  AssetAssignment({
    required this.assignmentId,
    required this.assetId,
    required this.jobId,
    required this.assignedWorkerId,
    required this.assetName,
    required this.description,
    required this.serialNumber,
    required this.assetTag,
    required this.notes,
    this.assignedAt,
    this.returnedAt,
    this.durationDays,
    required this.status,
    required this.locationType,
    this.address,
    this.expectedDurationDays,
    required this.slaBreached,
  });

  factory AssetAssignment.fromJson(Map<String, dynamic> json) {
    return AssetAssignment(
      assignmentId: json['assignmentId'] ?? 0,
      assetId: json['assetId'] ?? 0,
      jobId: json['jobId'] ?? 0,
      assignedWorkerId: json['assignedWorkerId'] ?? 0,
      assetName: json['assetName'] ?? 'Unknown Asset',
      description: json['description'] ?? '',
      serialNumber: json['serialNumber'] ?? '',
      assetTag: json['assetTag'] ?? '',
      notes: json['notes'] ?? '',
      assignedAt: json['assignedAt'] != null
          ? DateTime.tryParse(json['assignedAt'])?.toLocal()
          : null,
      returnedAt: json['returnedAt'] != null
          ? DateTime.tryParse(json['returnedAt'])?.toLocal()
          : null,
      durationDays: json['durationDays'],
      status: json['status'] ?? 'UNKNOWN',
      locationType: json['locationType'] ?? 'UNKNOWN',
      address: json['address'] != null
          ? AssetAddress.fromJson(json['address'])
          : null,
      expectedDurationDays: json['expectedDurationDays'],
      slaBreached: json['slaBreached'] ?? false,
    );
  }

  Color get statusColor {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return Colors.green.shade600;
      case 'INACTIVE':
        return Colors.red.shade500;
      case 'MAINTENANCE':
        return Colors.orange.shade500;
      default:
        return Colors.grey.shade600;
    }
  }
}
