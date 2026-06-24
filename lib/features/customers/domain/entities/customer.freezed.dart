// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'customer.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Customer {

 String get id;@JsonKey(name: 'company_name') String get companyName;@JsonKey(name: 'tally_license') String? get tallyLicense;@JsonKey(name: 'tally_serial_no') String? get tallySerialNo;@JsonKey(name: 'api_key') String get apiKey;@JsonKey(name: 'amc_expiry_date')@UtcDateTimeConverter() DateTime? get amcExpiryDate;@JsonKey(name: 'tss_expiry_date')@UtcDateTimeConverter() DateTime? get tssExpiryDate;@JsonKey(name: 'contact_person') String? get contactPerson;@JsonKey(name: 'contact_phone') String? get contactPhone;@JsonKey(name: 'contact_phone_numbers', fromJson: _phoneNumbersFromJson, toJson: _phoneNumbersToJson) List<String>? get contactPhoneNumbers;@JsonKey(name: 'contact_email') String? get contactEmail;@JsonKey(name: 'created_at')@UtcDateTimeConverter() DateTime? get createdAt;// Can be null in old records
@JsonKey(name: 'pinned_note') String? get pinnedNote;@JsonKey(name: 'tally_customizations') List<Map<String, dynamic>>? get tallyCustomizations;@JsonKey(name: 'secret_email') String? get secretEmail;@JsonKey(name: 'accountant_name') String? get accountantName;@JsonKey(name: 'accountant_phone') String? get accountantPhone;@JsonKey(name: 'accountant_email') String? get accountantEmail;@JsonKey(name: 'tally_software_history') List<Map<String, dynamic>>? get tallySoftwareHistory;
/// Create a copy of Customer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CustomerCopyWith<Customer> get copyWith => _$CustomerCopyWithImpl<Customer>(this as Customer, _$identity);

  /// Serializes this Customer to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Customer&&(identical(other.id, id) || other.id == id)&&(identical(other.companyName, companyName) || other.companyName == companyName)&&(identical(other.tallyLicense, tallyLicense) || other.tallyLicense == tallyLicense)&&(identical(other.tallySerialNo, tallySerialNo) || other.tallySerialNo == tallySerialNo)&&(identical(other.apiKey, apiKey) || other.apiKey == apiKey)&&(identical(other.amcExpiryDate, amcExpiryDate) || other.amcExpiryDate == amcExpiryDate)&&(identical(other.tssExpiryDate, tssExpiryDate) || other.tssExpiryDate == tssExpiryDate)&&(identical(other.contactPerson, contactPerson) || other.contactPerson == contactPerson)&&(identical(other.contactPhone, contactPhone) || other.contactPhone == contactPhone)&&const DeepCollectionEquality().equals(other.contactPhoneNumbers, contactPhoneNumbers)&&(identical(other.contactEmail, contactEmail) || other.contactEmail == contactEmail)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.pinnedNote, pinnedNote) || other.pinnedNote == pinnedNote)&&const DeepCollectionEquality().equals(other.tallyCustomizations, tallyCustomizations)&&(identical(other.secretEmail, secretEmail) || other.secretEmail == secretEmail)&&(identical(other.accountantName, accountantName) || other.accountantName == accountantName)&&(identical(other.accountantPhone, accountantPhone) || other.accountantPhone == accountantPhone)&&(identical(other.accountantEmail, accountantEmail) || other.accountantEmail == accountantEmail)&&const DeepCollectionEquality().equals(other.tallySoftwareHistory, tallySoftwareHistory));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,companyName,tallyLicense,tallySerialNo,apiKey,amcExpiryDate,tssExpiryDate,contactPerson,contactPhone,const DeepCollectionEquality().hash(contactPhoneNumbers),contactEmail,createdAt,pinnedNote,const DeepCollectionEquality().hash(tallyCustomizations),secretEmail,accountantName,accountantPhone,accountantEmail,const DeepCollectionEquality().hash(tallySoftwareHistory)]);

@override
String toString() {
  return 'Customer(id: $id, companyName: $companyName, tallyLicense: $tallyLicense, tallySerialNo: $tallySerialNo, apiKey: $apiKey, amcExpiryDate: $amcExpiryDate, tssExpiryDate: $tssExpiryDate, contactPerson: $contactPerson, contactPhone: $contactPhone, contactPhoneNumbers: $contactPhoneNumbers, contactEmail: $contactEmail, createdAt: $createdAt, pinnedNote: $pinnedNote, tallyCustomizations: $tallyCustomizations, secretEmail: $secretEmail, accountantName: $accountantName, accountantPhone: $accountantPhone, accountantEmail: $accountantEmail, tallySoftwareHistory: $tallySoftwareHistory)';
}


}

/// @nodoc
abstract mixin class $CustomerCopyWith<$Res>  {
  factory $CustomerCopyWith(Customer value, $Res Function(Customer) _then) = _$CustomerCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'company_name') String companyName,@JsonKey(name: 'tally_license') String? tallyLicense,@JsonKey(name: 'tally_serial_no') String? tallySerialNo,@JsonKey(name: 'api_key') String apiKey,@JsonKey(name: 'amc_expiry_date')@UtcDateTimeConverter() DateTime? amcExpiryDate,@JsonKey(name: 'tss_expiry_date')@UtcDateTimeConverter() DateTime? tssExpiryDate,@JsonKey(name: 'contact_person') String? contactPerson,@JsonKey(name: 'contact_phone') String? contactPhone,@JsonKey(name: 'contact_phone_numbers', fromJson: _phoneNumbersFromJson, toJson: _phoneNumbersToJson) List<String>? contactPhoneNumbers,@JsonKey(name: 'contact_email') String? contactEmail,@JsonKey(name: 'created_at')@UtcDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'pinned_note') String? pinnedNote,@JsonKey(name: 'tally_customizations') List<Map<String, dynamic>>? tallyCustomizations,@JsonKey(name: 'secret_email') String? secretEmail,@JsonKey(name: 'accountant_name') String? accountantName,@JsonKey(name: 'accountant_phone') String? accountantPhone,@JsonKey(name: 'accountant_email') String? accountantEmail,@JsonKey(name: 'tally_software_history') List<Map<String, dynamic>>? tallySoftwareHistory
});




}
/// @nodoc
class _$CustomerCopyWithImpl<$Res>
    implements $CustomerCopyWith<$Res> {
  _$CustomerCopyWithImpl(this._self, this._then);

  final Customer _self;
  final $Res Function(Customer) _then;

/// Create a copy of Customer
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? companyName = null,Object? tallyLicense = freezed,Object? tallySerialNo = freezed,Object? apiKey = null,Object? amcExpiryDate = freezed,Object? tssExpiryDate = freezed,Object? contactPerson = freezed,Object? contactPhone = freezed,Object? contactPhoneNumbers = freezed,Object? contactEmail = freezed,Object? createdAt = freezed,Object? pinnedNote = freezed,Object? tallyCustomizations = freezed,Object? secretEmail = freezed,Object? accountantName = freezed,Object? accountantPhone = freezed,Object? accountantEmail = freezed,Object? tallySoftwareHistory = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyName: null == companyName ? _self.companyName : companyName // ignore: cast_nullable_to_non_nullable
as String,tallyLicense: freezed == tallyLicense ? _self.tallyLicense : tallyLicense // ignore: cast_nullable_to_non_nullable
as String?,tallySerialNo: freezed == tallySerialNo ? _self.tallySerialNo : tallySerialNo // ignore: cast_nullable_to_non_nullable
as String?,apiKey: null == apiKey ? _self.apiKey : apiKey // ignore: cast_nullable_to_non_nullable
as String,amcExpiryDate: freezed == amcExpiryDate ? _self.amcExpiryDate : amcExpiryDate // ignore: cast_nullable_to_non_nullable
as DateTime?,tssExpiryDate: freezed == tssExpiryDate ? _self.tssExpiryDate : tssExpiryDate // ignore: cast_nullable_to_non_nullable
as DateTime?,contactPerson: freezed == contactPerson ? _self.contactPerson : contactPerson // ignore: cast_nullable_to_non_nullable
as String?,contactPhone: freezed == contactPhone ? _self.contactPhone : contactPhone // ignore: cast_nullable_to_non_nullable
as String?,contactPhoneNumbers: freezed == contactPhoneNumbers ? _self.contactPhoneNumbers : contactPhoneNumbers // ignore: cast_nullable_to_non_nullable
as List<String>?,contactEmail: freezed == contactEmail ? _self.contactEmail : contactEmail // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,pinnedNote: freezed == pinnedNote ? _self.pinnedNote : pinnedNote // ignore: cast_nullable_to_non_nullable
as String?,tallyCustomizations: freezed == tallyCustomizations ? _self.tallyCustomizations : tallyCustomizations // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>?,secretEmail: freezed == secretEmail ? _self.secretEmail : secretEmail // ignore: cast_nullable_to_non_nullable
as String?,accountantName: freezed == accountantName ? _self.accountantName : accountantName // ignore: cast_nullable_to_non_nullable
as String?,accountantPhone: freezed == accountantPhone ? _self.accountantPhone : accountantPhone // ignore: cast_nullable_to_non_nullable
as String?,accountantEmail: freezed == accountantEmail ? _self.accountantEmail : accountantEmail // ignore: cast_nullable_to_non_nullable
as String?,tallySoftwareHistory: freezed == tallySoftwareHistory ? _self.tallySoftwareHistory : tallySoftwareHistory // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>?,
  ));
}

}


/// Adds pattern-matching-related methods to [Customer].
extension CustomerPatterns on Customer {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Customer value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Customer() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Customer value)  $default,){
final _that = this;
switch (_that) {
case _Customer():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Customer value)?  $default,){
final _that = this;
switch (_that) {
case _Customer() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'company_name')  String companyName, @JsonKey(name: 'tally_license')  String? tallyLicense, @JsonKey(name: 'tally_serial_no')  String? tallySerialNo, @JsonKey(name: 'api_key')  String apiKey, @JsonKey(name: 'amc_expiry_date')@UtcDateTimeConverter()  DateTime? amcExpiryDate, @JsonKey(name: 'tss_expiry_date')@UtcDateTimeConverter()  DateTime? tssExpiryDate, @JsonKey(name: 'contact_person')  String? contactPerson, @JsonKey(name: 'contact_phone')  String? contactPhone, @JsonKey(name: 'contact_phone_numbers', fromJson: _phoneNumbersFromJson, toJson: _phoneNumbersToJson)  List<String>? contactPhoneNumbers, @JsonKey(name: 'contact_email')  String? contactEmail, @JsonKey(name: 'created_at')@UtcDateTimeConverter()  DateTime? createdAt, @JsonKey(name: 'pinned_note')  String? pinnedNote, @JsonKey(name: 'tally_customizations')  List<Map<String, dynamic>>? tallyCustomizations, @JsonKey(name: 'secret_email')  String? secretEmail, @JsonKey(name: 'accountant_name')  String? accountantName, @JsonKey(name: 'accountant_phone')  String? accountantPhone, @JsonKey(name: 'accountant_email')  String? accountantEmail, @JsonKey(name: 'tally_software_history')  List<Map<String, dynamic>>? tallySoftwareHistory)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Customer() when $default != null:
return $default(_that.id,_that.companyName,_that.tallyLicense,_that.tallySerialNo,_that.apiKey,_that.amcExpiryDate,_that.tssExpiryDate,_that.contactPerson,_that.contactPhone,_that.contactPhoneNumbers,_that.contactEmail,_that.createdAt,_that.pinnedNote,_that.tallyCustomizations,_that.secretEmail,_that.accountantName,_that.accountantPhone,_that.accountantEmail,_that.tallySoftwareHistory);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'company_name')  String companyName, @JsonKey(name: 'tally_license')  String? tallyLicense, @JsonKey(name: 'tally_serial_no')  String? tallySerialNo, @JsonKey(name: 'api_key')  String apiKey, @JsonKey(name: 'amc_expiry_date')@UtcDateTimeConverter()  DateTime? amcExpiryDate, @JsonKey(name: 'tss_expiry_date')@UtcDateTimeConverter()  DateTime? tssExpiryDate, @JsonKey(name: 'contact_person')  String? contactPerson, @JsonKey(name: 'contact_phone')  String? contactPhone, @JsonKey(name: 'contact_phone_numbers', fromJson: _phoneNumbersFromJson, toJson: _phoneNumbersToJson)  List<String>? contactPhoneNumbers, @JsonKey(name: 'contact_email')  String? contactEmail, @JsonKey(name: 'created_at')@UtcDateTimeConverter()  DateTime? createdAt, @JsonKey(name: 'pinned_note')  String? pinnedNote, @JsonKey(name: 'tally_customizations')  List<Map<String, dynamic>>? tallyCustomizations, @JsonKey(name: 'secret_email')  String? secretEmail, @JsonKey(name: 'accountant_name')  String? accountantName, @JsonKey(name: 'accountant_phone')  String? accountantPhone, @JsonKey(name: 'accountant_email')  String? accountantEmail, @JsonKey(name: 'tally_software_history')  List<Map<String, dynamic>>? tallySoftwareHistory)  $default,) {final _that = this;
switch (_that) {
case _Customer():
return $default(_that.id,_that.companyName,_that.tallyLicense,_that.tallySerialNo,_that.apiKey,_that.amcExpiryDate,_that.tssExpiryDate,_that.contactPerson,_that.contactPhone,_that.contactPhoneNumbers,_that.contactEmail,_that.createdAt,_that.pinnedNote,_that.tallyCustomizations,_that.secretEmail,_that.accountantName,_that.accountantPhone,_that.accountantEmail,_that.tallySoftwareHistory);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'company_name')  String companyName, @JsonKey(name: 'tally_license')  String? tallyLicense, @JsonKey(name: 'tally_serial_no')  String? tallySerialNo, @JsonKey(name: 'api_key')  String apiKey, @JsonKey(name: 'amc_expiry_date')@UtcDateTimeConverter()  DateTime? amcExpiryDate, @JsonKey(name: 'tss_expiry_date')@UtcDateTimeConverter()  DateTime? tssExpiryDate, @JsonKey(name: 'contact_person')  String? contactPerson, @JsonKey(name: 'contact_phone')  String? contactPhone, @JsonKey(name: 'contact_phone_numbers', fromJson: _phoneNumbersFromJson, toJson: _phoneNumbersToJson)  List<String>? contactPhoneNumbers, @JsonKey(name: 'contact_email')  String? contactEmail, @JsonKey(name: 'created_at')@UtcDateTimeConverter()  DateTime? createdAt, @JsonKey(name: 'pinned_note')  String? pinnedNote, @JsonKey(name: 'tally_customizations')  List<Map<String, dynamic>>? tallyCustomizations, @JsonKey(name: 'secret_email')  String? secretEmail, @JsonKey(name: 'accountant_name')  String? accountantName, @JsonKey(name: 'accountant_phone')  String? accountantPhone, @JsonKey(name: 'accountant_email')  String? accountantEmail, @JsonKey(name: 'tally_software_history')  List<Map<String, dynamic>>? tallySoftwareHistory)?  $default,) {final _that = this;
switch (_that) {
case _Customer() when $default != null:
return $default(_that.id,_that.companyName,_that.tallyLicense,_that.tallySerialNo,_that.apiKey,_that.amcExpiryDate,_that.tssExpiryDate,_that.contactPerson,_that.contactPhone,_that.contactPhoneNumbers,_that.contactEmail,_that.createdAt,_that.pinnedNote,_that.tallyCustomizations,_that.secretEmail,_that.accountantName,_that.accountantPhone,_that.accountantEmail,_that.tallySoftwareHistory);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Customer extends Customer {
  const _Customer({required this.id, @JsonKey(name: 'company_name') this.companyName = '', @JsonKey(name: 'tally_license') this.tallyLicense, @JsonKey(name: 'tally_serial_no') this.tallySerialNo, @JsonKey(name: 'api_key') this.apiKey = '', @JsonKey(name: 'amc_expiry_date')@UtcDateTimeConverter() this.amcExpiryDate, @JsonKey(name: 'tss_expiry_date')@UtcDateTimeConverter() this.tssExpiryDate, @JsonKey(name: 'contact_person') this.contactPerson, @JsonKey(name: 'contact_phone') this.contactPhone, @JsonKey(name: 'contact_phone_numbers', fromJson: _phoneNumbersFromJson, toJson: _phoneNumbersToJson) final  List<String>? contactPhoneNumbers, @JsonKey(name: 'contact_email') this.contactEmail, @JsonKey(name: 'created_at')@UtcDateTimeConverter() this.createdAt, @JsonKey(name: 'pinned_note') this.pinnedNote, @JsonKey(name: 'tally_customizations') final  List<Map<String, dynamic>>? tallyCustomizations, @JsonKey(name: 'secret_email') this.secretEmail, @JsonKey(name: 'accountant_name') this.accountantName, @JsonKey(name: 'accountant_phone') this.accountantPhone, @JsonKey(name: 'accountant_email') this.accountantEmail, @JsonKey(name: 'tally_software_history') final  List<Map<String, dynamic>>? tallySoftwareHistory}): _contactPhoneNumbers = contactPhoneNumbers,_tallyCustomizations = tallyCustomizations,_tallySoftwareHistory = tallySoftwareHistory,super._();
  factory _Customer.fromJson(Map<String, dynamic> json) => _$CustomerFromJson(json);

@override final  String id;
@override@JsonKey(name: 'company_name') final  String companyName;
@override@JsonKey(name: 'tally_license') final  String? tallyLicense;
@override@JsonKey(name: 'tally_serial_no') final  String? tallySerialNo;
@override@JsonKey(name: 'api_key') final  String apiKey;
@override@JsonKey(name: 'amc_expiry_date')@UtcDateTimeConverter() final  DateTime? amcExpiryDate;
@override@JsonKey(name: 'tss_expiry_date')@UtcDateTimeConverter() final  DateTime? tssExpiryDate;
@override@JsonKey(name: 'contact_person') final  String? contactPerson;
@override@JsonKey(name: 'contact_phone') final  String? contactPhone;
 final  List<String>? _contactPhoneNumbers;
@override@JsonKey(name: 'contact_phone_numbers', fromJson: _phoneNumbersFromJson, toJson: _phoneNumbersToJson) List<String>? get contactPhoneNumbers {
  final value = _contactPhoneNumbers;
  if (value == null) return null;
  if (_contactPhoneNumbers is EqualUnmodifiableListView) return _contactPhoneNumbers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override@JsonKey(name: 'contact_email') final  String? contactEmail;
@override@JsonKey(name: 'created_at')@UtcDateTimeConverter() final  DateTime? createdAt;
// Can be null in old records
@override@JsonKey(name: 'pinned_note') final  String? pinnedNote;
 final  List<Map<String, dynamic>>? _tallyCustomizations;
@override@JsonKey(name: 'tally_customizations') List<Map<String, dynamic>>? get tallyCustomizations {
  final value = _tallyCustomizations;
  if (value == null) return null;
  if (_tallyCustomizations is EqualUnmodifiableListView) return _tallyCustomizations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override@JsonKey(name: 'secret_email') final  String? secretEmail;
@override@JsonKey(name: 'accountant_name') final  String? accountantName;
@override@JsonKey(name: 'accountant_phone') final  String? accountantPhone;
@override@JsonKey(name: 'accountant_email') final  String? accountantEmail;
 final  List<Map<String, dynamic>>? _tallySoftwareHistory;
@override@JsonKey(name: 'tally_software_history') List<Map<String, dynamic>>? get tallySoftwareHistory {
  final value = _tallySoftwareHistory;
  if (value == null) return null;
  if (_tallySoftwareHistory is EqualUnmodifiableListView) return _tallySoftwareHistory;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of Customer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CustomerCopyWith<_Customer> get copyWith => __$CustomerCopyWithImpl<_Customer>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CustomerToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Customer&&(identical(other.id, id) || other.id == id)&&(identical(other.companyName, companyName) || other.companyName == companyName)&&(identical(other.tallyLicense, tallyLicense) || other.tallyLicense == tallyLicense)&&(identical(other.tallySerialNo, tallySerialNo) || other.tallySerialNo == tallySerialNo)&&(identical(other.apiKey, apiKey) || other.apiKey == apiKey)&&(identical(other.amcExpiryDate, amcExpiryDate) || other.amcExpiryDate == amcExpiryDate)&&(identical(other.tssExpiryDate, tssExpiryDate) || other.tssExpiryDate == tssExpiryDate)&&(identical(other.contactPerson, contactPerson) || other.contactPerson == contactPerson)&&(identical(other.contactPhone, contactPhone) || other.contactPhone == contactPhone)&&const DeepCollectionEquality().equals(other._contactPhoneNumbers, _contactPhoneNumbers)&&(identical(other.contactEmail, contactEmail) || other.contactEmail == contactEmail)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.pinnedNote, pinnedNote) || other.pinnedNote == pinnedNote)&&const DeepCollectionEquality().equals(other._tallyCustomizations, _tallyCustomizations)&&(identical(other.secretEmail, secretEmail) || other.secretEmail == secretEmail)&&(identical(other.accountantName, accountantName) || other.accountantName == accountantName)&&(identical(other.accountantPhone, accountantPhone) || other.accountantPhone == accountantPhone)&&(identical(other.accountantEmail, accountantEmail) || other.accountantEmail == accountantEmail)&&const DeepCollectionEquality().equals(other._tallySoftwareHistory, _tallySoftwareHistory));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,companyName,tallyLicense,tallySerialNo,apiKey,amcExpiryDate,tssExpiryDate,contactPerson,contactPhone,const DeepCollectionEquality().hash(_contactPhoneNumbers),contactEmail,createdAt,pinnedNote,const DeepCollectionEquality().hash(_tallyCustomizations),secretEmail,accountantName,accountantPhone,accountantEmail,const DeepCollectionEquality().hash(_tallySoftwareHistory)]);

@override
String toString() {
  return 'Customer(id: $id, companyName: $companyName, tallyLicense: $tallyLicense, tallySerialNo: $tallySerialNo, apiKey: $apiKey, amcExpiryDate: $amcExpiryDate, tssExpiryDate: $tssExpiryDate, contactPerson: $contactPerson, contactPhone: $contactPhone, contactPhoneNumbers: $contactPhoneNumbers, contactEmail: $contactEmail, createdAt: $createdAt, pinnedNote: $pinnedNote, tallyCustomizations: $tallyCustomizations, secretEmail: $secretEmail, accountantName: $accountantName, accountantPhone: $accountantPhone, accountantEmail: $accountantEmail, tallySoftwareHistory: $tallySoftwareHistory)';
}


}

/// @nodoc
abstract mixin class _$CustomerCopyWith<$Res> implements $CustomerCopyWith<$Res> {
  factory _$CustomerCopyWith(_Customer value, $Res Function(_Customer) _then) = __$CustomerCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'company_name') String companyName,@JsonKey(name: 'tally_license') String? tallyLicense,@JsonKey(name: 'tally_serial_no') String? tallySerialNo,@JsonKey(name: 'api_key') String apiKey,@JsonKey(name: 'amc_expiry_date')@UtcDateTimeConverter() DateTime? amcExpiryDate,@JsonKey(name: 'tss_expiry_date')@UtcDateTimeConverter() DateTime? tssExpiryDate,@JsonKey(name: 'contact_person') String? contactPerson,@JsonKey(name: 'contact_phone') String? contactPhone,@JsonKey(name: 'contact_phone_numbers', fromJson: _phoneNumbersFromJson, toJson: _phoneNumbersToJson) List<String>? contactPhoneNumbers,@JsonKey(name: 'contact_email') String? contactEmail,@JsonKey(name: 'created_at')@UtcDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'pinned_note') String? pinnedNote,@JsonKey(name: 'tally_customizations') List<Map<String, dynamic>>? tallyCustomizations,@JsonKey(name: 'secret_email') String? secretEmail,@JsonKey(name: 'accountant_name') String? accountantName,@JsonKey(name: 'accountant_phone') String? accountantPhone,@JsonKey(name: 'accountant_email') String? accountantEmail,@JsonKey(name: 'tally_software_history') List<Map<String, dynamic>>? tallySoftwareHistory
});




}
/// @nodoc
class __$CustomerCopyWithImpl<$Res>
    implements _$CustomerCopyWith<$Res> {
  __$CustomerCopyWithImpl(this._self, this._then);

  final _Customer _self;
  final $Res Function(_Customer) _then;

/// Create a copy of Customer
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? companyName = null,Object? tallyLicense = freezed,Object? tallySerialNo = freezed,Object? apiKey = null,Object? amcExpiryDate = freezed,Object? tssExpiryDate = freezed,Object? contactPerson = freezed,Object? contactPhone = freezed,Object? contactPhoneNumbers = freezed,Object? contactEmail = freezed,Object? createdAt = freezed,Object? pinnedNote = freezed,Object? tallyCustomizations = freezed,Object? secretEmail = freezed,Object? accountantName = freezed,Object? accountantPhone = freezed,Object? accountantEmail = freezed,Object? tallySoftwareHistory = freezed,}) {
  return _then(_Customer(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyName: null == companyName ? _self.companyName : companyName // ignore: cast_nullable_to_non_nullable
as String,tallyLicense: freezed == tallyLicense ? _self.tallyLicense : tallyLicense // ignore: cast_nullable_to_non_nullable
as String?,tallySerialNo: freezed == tallySerialNo ? _self.tallySerialNo : tallySerialNo // ignore: cast_nullable_to_non_nullable
as String?,apiKey: null == apiKey ? _self.apiKey : apiKey // ignore: cast_nullable_to_non_nullable
as String,amcExpiryDate: freezed == amcExpiryDate ? _self.amcExpiryDate : amcExpiryDate // ignore: cast_nullable_to_non_nullable
as DateTime?,tssExpiryDate: freezed == tssExpiryDate ? _self.tssExpiryDate : tssExpiryDate // ignore: cast_nullable_to_non_nullable
as DateTime?,contactPerson: freezed == contactPerson ? _self.contactPerson : contactPerson // ignore: cast_nullable_to_non_nullable
as String?,contactPhone: freezed == contactPhone ? _self.contactPhone : contactPhone // ignore: cast_nullable_to_non_nullable
as String?,contactPhoneNumbers: freezed == contactPhoneNumbers ? _self._contactPhoneNumbers : contactPhoneNumbers // ignore: cast_nullable_to_non_nullable
as List<String>?,contactEmail: freezed == contactEmail ? _self.contactEmail : contactEmail // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,pinnedNote: freezed == pinnedNote ? _self.pinnedNote : pinnedNote // ignore: cast_nullable_to_non_nullable
as String?,tallyCustomizations: freezed == tallyCustomizations ? _self._tallyCustomizations : tallyCustomizations // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>?,secretEmail: freezed == secretEmail ? _self.secretEmail : secretEmail // ignore: cast_nullable_to_non_nullable
as String?,accountantName: freezed == accountantName ? _self.accountantName : accountantName // ignore: cast_nullable_to_non_nullable
as String?,accountantPhone: freezed == accountantPhone ? _self.accountantPhone : accountantPhone // ignore: cast_nullable_to_non_nullable
as String?,accountantEmail: freezed == accountantEmail ? _self.accountantEmail : accountantEmail // ignore: cast_nullable_to_non_nullable
as String?,tallySoftwareHistory: freezed == tallySoftwareHistory ? _self._tallySoftwareHistory : tallySoftwareHistory // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>?,
  ));
}


}

// dart format on
