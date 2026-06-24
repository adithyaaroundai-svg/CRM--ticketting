import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../core/utils/json_converters.dart';

// Freezed uses JsonKey on constructor parameters; ignore analyzer complaining
// about invalid annotation targets.
// ignore_for_file: invalid_annotation_target

part 'customer.freezed.dart';
part 'customer.g.dart';

@freezed
abstract class Customer with _$Customer {
  const factory Customer({
    required String id,
    @JsonKey(name: 'company_name') @Default('') String companyName,
    @JsonKey(name: 'tally_license') String? tallyLicense,
    @JsonKey(name: 'tally_serial_no') String? tallySerialNo,
    @JsonKey(name: 'api_key') @Default('') String apiKey,
    @JsonKey(name: 'amc_expiry_date') @UtcDateTimeConverter() DateTime? amcExpiryDate,
    @JsonKey(name: 'tss_expiry_date') @UtcDateTimeConverter() DateTime? tssExpiryDate,
    @JsonKey(name: 'contact_person') String? contactPerson,
    @JsonKey(name: 'contact_phone') String? contactPhone,
    @JsonKey(name: 'contact_phone_numbers', fromJson: _phoneNumbersFromJson, toJson: _phoneNumbersToJson) List<String>? contactPhoneNumbers,
    @JsonKey(name: 'contact_email') String? contactEmail,
    @JsonKey(name: 'created_at') @UtcDateTimeConverter()
    DateTime? createdAt, // Can be null in old records
    @JsonKey(name: 'pinned_note') String? pinnedNote,
    @JsonKey(name: 'tally_customizations')
    List<Map<String, dynamic>>? tallyCustomizations,
    @JsonKey(name: 'secret_email') String? secretEmail,
    @JsonKey(name: 'accountant_name') String? accountantName,
    @JsonKey(name: 'accountant_phone') String? accountantPhone,
    @JsonKey(name: 'accountant_email') String? accountantEmail,
    @JsonKey(name: 'tally_software_history')
    List<Map<String, dynamic>>? tallySoftwareHistory,
  }) = _Customer;

  factory Customer.fromJson(Map<String, dynamic> json) =>
      _$CustomerFromJson(json);

  // Helper to check if AMC is active
  const Customer._();

  bool get isAmcActive {
    if (amcExpiryDate == null) return false;
    return amcExpiryDate!.isAfter(DateTime.now());
  }

  bool get isTssActive {
    if (tssExpiryDate == null) return false;
    return tssExpiryDate!.isAfter(DateTime.now());
  }

  int get amcDaysRemaining {
    if (amcExpiryDate == null) return 0;
    return amcExpiryDate!.difference(DateTime.now()).inDays;
  }

  int get tssDaysRemaining {
    if (tssExpiryDate == null) return 0;
    return tssExpiryDate!.difference(DateTime.now()).inDays;
  }

  List<String> get phoneNumbers {
    final numbers = contactPhoneNumbers
        ?.map((number) => number.trim())
        .where((number) => number.isNotEmpty)
        .toList();

    if (numbers != null && numbers.isNotEmpty) {
      return List.unmodifiable(numbers);
    }

    final fallback = contactPhone?.trim();
    if (fallback != null && fallback.isNotEmpty) {
      return List.unmodifiable([fallback]);
    }

    return const [];
  }

  String? get primaryPhone => phoneNumbers.isNotEmpty ? phoneNumbers.first : null;
}

List<String>? _phoneNumbersFromJson(dynamic value) {
  if (value == null) return null;
  if (value is List) {
    return value.map((e) => e.toString()).toList();
  }
  if (value is String) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
    } catch (_) {}
    return [value];
  }
  return null;
}

List<String>? _phoneNumbersToJson(List<String>? value) => value;
