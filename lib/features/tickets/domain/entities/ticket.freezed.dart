// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ticket.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Ticket implements DiagnosticableTreeMixin {

@JsonKey(name: 'id') String get ticketId;@JsonKey(name: 'customer_id') String get customerId;@JsonKey(name: 'client_ticket_uuid') String? get clientTicketUuid;@JsonKey(name: 'title') String get title;@JsonKey(name: 'description') String? get description;@JsonKey(name: 'contact_phone') String? get contactPhone;@JsonKey(name: 'screenshot_url') String? get screenshotUrl;@JsonKey(name: 'category') String? get category;@JsonKey(name: 'status') String get status;@JsonKey(name: 'priority') String? get priority;@JsonKey(name: 'created_by') String get createdBy;@JsonKey(name: 'assigned_to') String? get assignedTo;@JsonKey(name: 'created_at')@UtcDateTimeConverter() DateTime? get createdAt;@JsonKey(name: 'updated_at')@UtcDateTimeConverter() DateTime? get updatedAt;@JsonKey(name: 'sla_due')@UtcDateTimeConverter() DateTime? get slaDue;@JsonKey(name: 'bill_amount') double? get billAmount;@JsonKey(name: 'billing_procedure') String? get billingProcedure;@JsonKey(name: 'payment_collected') bool? get paymentCollected;@JsonKey(name: 'has_amc') bool? get hasAmc;@JsonKey(name: 'completed_at')@UtcDateTimeConverter() DateTime? get completedDate;
/// Create a copy of Ticket
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TicketCopyWith<Ticket> get copyWith => _$TicketCopyWithImpl<Ticket>(this as Ticket, _$identity);

  /// Serializes this Ticket to a JSON map.
  Map<String, dynamic> toJson();

@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'Ticket'))
    ..add(DiagnosticsProperty('ticketId', ticketId))..add(DiagnosticsProperty('customerId', customerId))..add(DiagnosticsProperty('clientTicketUuid', clientTicketUuid))..add(DiagnosticsProperty('title', title))..add(DiagnosticsProperty('description', description))..add(DiagnosticsProperty('contactPhone', contactPhone))..add(DiagnosticsProperty('screenshotUrl', screenshotUrl))..add(DiagnosticsProperty('category', category))..add(DiagnosticsProperty('status', status))..add(DiagnosticsProperty('priority', priority))..add(DiagnosticsProperty('createdBy', createdBy))..add(DiagnosticsProperty('assignedTo', assignedTo))..add(DiagnosticsProperty('createdAt', createdAt))..add(DiagnosticsProperty('updatedAt', updatedAt))..add(DiagnosticsProperty('slaDue', slaDue))..add(DiagnosticsProperty('billAmount', billAmount))..add(DiagnosticsProperty('billingProcedure', billingProcedure))..add(DiagnosticsProperty('paymentCollected', paymentCollected))..add(DiagnosticsProperty('hasAmc', hasAmc))..add(DiagnosticsProperty('completedDate', completedDate));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Ticket&&(identical(other.ticketId, ticketId) || other.ticketId == ticketId)&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.clientTicketUuid, clientTicketUuid) || other.clientTicketUuid == clientTicketUuid)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.contactPhone, contactPhone) || other.contactPhone == contactPhone)&&(identical(other.screenshotUrl, screenshotUrl) || other.screenshotUrl == screenshotUrl)&&(identical(other.category, category) || other.category == category)&&(identical(other.status, status) || other.status == status)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.assignedTo, assignedTo) || other.assignedTo == assignedTo)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.slaDue, slaDue) || other.slaDue == slaDue)&&(identical(other.billAmount, billAmount) || other.billAmount == billAmount)&&(identical(other.billingProcedure, billingProcedure) || other.billingProcedure == billingProcedure)&&(identical(other.paymentCollected, paymentCollected) || other.paymentCollected == paymentCollected)&&(identical(other.hasAmc, hasAmc) || other.hasAmc == hasAmc)&&(identical(other.completedDate, completedDate) || other.completedDate == completedDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,ticketId,customerId,clientTicketUuid,title,description,contactPhone,screenshotUrl,category,status,priority,createdBy,assignedTo,createdAt,updatedAt,slaDue,billAmount,billingProcedure,paymentCollected,hasAmc,completedDate]);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'Ticket(ticketId: $ticketId, customerId: $customerId, clientTicketUuid: $clientTicketUuid, title: $title, description: $description, contactPhone: $contactPhone, screenshotUrl: $screenshotUrl, category: $category, status: $status, priority: $priority, createdBy: $createdBy, assignedTo: $assignedTo, createdAt: $createdAt, updatedAt: $updatedAt, slaDue: $slaDue, billAmount: $billAmount, billingProcedure: $billingProcedure, paymentCollected: $paymentCollected, hasAmc: $hasAmc, completedDate: $completedDate)';
}


}

/// @nodoc
abstract mixin class $TicketCopyWith<$Res>  {
  factory $TicketCopyWith(Ticket value, $Res Function(Ticket) _then) = _$TicketCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'id') String ticketId,@JsonKey(name: 'customer_id') String customerId,@JsonKey(name: 'client_ticket_uuid') String? clientTicketUuid,@JsonKey(name: 'title') String title,@JsonKey(name: 'description') String? description,@JsonKey(name: 'contact_phone') String? contactPhone,@JsonKey(name: 'screenshot_url') String? screenshotUrl,@JsonKey(name: 'category') String? category,@JsonKey(name: 'status') String status,@JsonKey(name: 'priority') String? priority,@JsonKey(name: 'created_by') String createdBy,@JsonKey(name: 'assigned_to') String? assignedTo,@JsonKey(name: 'created_at')@UtcDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@UtcDateTimeConverter() DateTime? updatedAt,@JsonKey(name: 'sla_due')@UtcDateTimeConverter() DateTime? slaDue,@JsonKey(name: 'bill_amount') double? billAmount,@JsonKey(name: 'billing_procedure') String? billingProcedure,@JsonKey(name: 'payment_collected') bool? paymentCollected,@JsonKey(name: 'has_amc') bool? hasAmc,@JsonKey(name: 'completed_at')@UtcDateTimeConverter() DateTime? completedDate
});




}
/// @nodoc
class _$TicketCopyWithImpl<$Res>
    implements $TicketCopyWith<$Res> {
  _$TicketCopyWithImpl(this._self, this._then);

  final Ticket _self;
  final $Res Function(Ticket) _then;

/// Create a copy of Ticket
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? ticketId = null,Object? customerId = null,Object? clientTicketUuid = freezed,Object? title = null,Object? description = freezed,Object? contactPhone = freezed,Object? screenshotUrl = freezed,Object? category = freezed,Object? status = null,Object? priority = freezed,Object? createdBy = null,Object? assignedTo = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? slaDue = freezed,Object? billAmount = freezed,Object? billingProcedure = freezed,Object? paymentCollected = freezed,Object? hasAmc = freezed,Object? completedDate = freezed,}) {
  return _then(_self.copyWith(
ticketId: null == ticketId ? _self.ticketId : ticketId // ignore: cast_nullable_to_non_nullable
as String,customerId: null == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as String,clientTicketUuid: freezed == clientTicketUuid ? _self.clientTicketUuid : clientTicketUuid // ignore: cast_nullable_to_non_nullable
as String?,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,contactPhone: freezed == contactPhone ? _self.contactPhone : contactPhone // ignore: cast_nullable_to_non_nullable
as String?,screenshotUrl: freezed == screenshotUrl ? _self.screenshotUrl : screenshotUrl // ignore: cast_nullable_to_non_nullable
as String?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,priority: freezed == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as String?,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,assignedTo: freezed == assignedTo ? _self.assignedTo : assignedTo // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,slaDue: freezed == slaDue ? _self.slaDue : slaDue // ignore: cast_nullable_to_non_nullable
as DateTime?,billAmount: freezed == billAmount ? _self.billAmount : billAmount // ignore: cast_nullable_to_non_nullable
as double?,billingProcedure: freezed == billingProcedure ? _self.billingProcedure : billingProcedure // ignore: cast_nullable_to_non_nullable
as String?,paymentCollected: freezed == paymentCollected ? _self.paymentCollected : paymentCollected // ignore: cast_nullable_to_non_nullable
as bool?,hasAmc: freezed == hasAmc ? _self.hasAmc : hasAmc // ignore: cast_nullable_to_non_nullable
as bool?,completedDate: freezed == completedDate ? _self.completedDate : completedDate // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Ticket].
extension TicketPatterns on Ticket {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Ticket value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Ticket() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Ticket value)  $default,){
final _that = this;
switch (_that) {
case _Ticket():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Ticket value)?  $default,){
final _that = this;
switch (_that) {
case _Ticket() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  String ticketId, @JsonKey(name: 'customer_id')  String customerId, @JsonKey(name: 'client_ticket_uuid')  String? clientTicketUuid, @JsonKey(name: 'title')  String title, @JsonKey(name: 'description')  String? description, @JsonKey(name: 'contact_phone')  String? contactPhone, @JsonKey(name: 'screenshot_url')  String? screenshotUrl, @JsonKey(name: 'category')  String? category, @JsonKey(name: 'status')  String status, @JsonKey(name: 'priority')  String? priority, @JsonKey(name: 'created_by')  String createdBy, @JsonKey(name: 'assigned_to')  String? assignedTo, @JsonKey(name: 'created_at')@UtcDateTimeConverter()  DateTime? createdAt, @JsonKey(name: 'updated_at')@UtcDateTimeConverter()  DateTime? updatedAt, @JsonKey(name: 'sla_due')@UtcDateTimeConverter()  DateTime? slaDue, @JsonKey(name: 'bill_amount')  double? billAmount, @JsonKey(name: 'billing_procedure')  String? billingProcedure, @JsonKey(name: 'payment_collected')  bool? paymentCollected, @JsonKey(name: 'has_amc')  bool? hasAmc, @JsonKey(name: 'completed_at')@UtcDateTimeConverter()  DateTime? completedDate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Ticket() when $default != null:
return $default(_that.ticketId,_that.customerId,_that.clientTicketUuid,_that.title,_that.description,_that.contactPhone,_that.screenshotUrl,_that.category,_that.status,_that.priority,_that.createdBy,_that.assignedTo,_that.createdAt,_that.updatedAt,_that.slaDue,_that.billAmount,_that.billingProcedure,_that.paymentCollected,_that.hasAmc,_that.completedDate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  String ticketId, @JsonKey(name: 'customer_id')  String customerId, @JsonKey(name: 'client_ticket_uuid')  String? clientTicketUuid, @JsonKey(name: 'title')  String title, @JsonKey(name: 'description')  String? description, @JsonKey(name: 'contact_phone')  String? contactPhone, @JsonKey(name: 'screenshot_url')  String? screenshotUrl, @JsonKey(name: 'category')  String? category, @JsonKey(name: 'status')  String status, @JsonKey(name: 'priority')  String? priority, @JsonKey(name: 'created_by')  String createdBy, @JsonKey(name: 'assigned_to')  String? assignedTo, @JsonKey(name: 'created_at')@UtcDateTimeConverter()  DateTime? createdAt, @JsonKey(name: 'updated_at')@UtcDateTimeConverter()  DateTime? updatedAt, @JsonKey(name: 'sla_due')@UtcDateTimeConverter()  DateTime? slaDue, @JsonKey(name: 'bill_amount')  double? billAmount, @JsonKey(name: 'billing_procedure')  String? billingProcedure, @JsonKey(name: 'payment_collected')  bool? paymentCollected, @JsonKey(name: 'has_amc')  bool? hasAmc, @JsonKey(name: 'completed_at')@UtcDateTimeConverter()  DateTime? completedDate)  $default,) {final _that = this;
switch (_that) {
case _Ticket():
return $default(_that.ticketId,_that.customerId,_that.clientTicketUuid,_that.title,_that.description,_that.contactPhone,_that.screenshotUrl,_that.category,_that.status,_that.priority,_that.createdBy,_that.assignedTo,_that.createdAt,_that.updatedAt,_that.slaDue,_that.billAmount,_that.billingProcedure,_that.paymentCollected,_that.hasAmc,_that.completedDate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'id')  String ticketId, @JsonKey(name: 'customer_id')  String customerId, @JsonKey(name: 'client_ticket_uuid')  String? clientTicketUuid, @JsonKey(name: 'title')  String title, @JsonKey(name: 'description')  String? description, @JsonKey(name: 'contact_phone')  String? contactPhone, @JsonKey(name: 'screenshot_url')  String? screenshotUrl, @JsonKey(name: 'category')  String? category, @JsonKey(name: 'status')  String status, @JsonKey(name: 'priority')  String? priority, @JsonKey(name: 'created_by')  String createdBy, @JsonKey(name: 'assigned_to')  String? assignedTo, @JsonKey(name: 'created_at')@UtcDateTimeConverter()  DateTime? createdAt, @JsonKey(name: 'updated_at')@UtcDateTimeConverter()  DateTime? updatedAt, @JsonKey(name: 'sla_due')@UtcDateTimeConverter()  DateTime? slaDue, @JsonKey(name: 'bill_amount')  double? billAmount, @JsonKey(name: 'billing_procedure')  String? billingProcedure, @JsonKey(name: 'payment_collected')  bool? paymentCollected, @JsonKey(name: 'has_amc')  bool? hasAmc, @JsonKey(name: 'completed_at')@UtcDateTimeConverter()  DateTime? completedDate)?  $default,) {final _that = this;
switch (_that) {
case _Ticket() when $default != null:
return $default(_that.ticketId,_that.customerId,_that.clientTicketUuid,_that.title,_that.description,_that.contactPhone,_that.screenshotUrl,_that.category,_that.status,_that.priority,_that.createdBy,_that.assignedTo,_that.createdAt,_that.updatedAt,_that.slaDue,_that.billAmount,_that.billingProcedure,_that.paymentCollected,_that.hasAmc,_that.completedDate);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Ticket with DiagnosticableTreeMixin implements Ticket {
  const _Ticket({@JsonKey(name: 'id') required this.ticketId, @JsonKey(name: 'customer_id') required this.customerId, @JsonKey(name: 'client_ticket_uuid') this.clientTicketUuid, @JsonKey(name: 'title') this.title = '', @JsonKey(name: 'description') this.description, @JsonKey(name: 'contact_phone') this.contactPhone, @JsonKey(name: 'screenshot_url') this.screenshotUrl, @JsonKey(name: 'category') this.category, @JsonKey(name: 'status') this.status = 'New', @JsonKey(name: 'priority') this.priority, @JsonKey(name: 'created_by') this.createdBy = 'Unknown', @JsonKey(name: 'assigned_to') this.assignedTo, @JsonKey(name: 'created_at')@UtcDateTimeConverter() this.createdAt, @JsonKey(name: 'updated_at')@UtcDateTimeConverter() this.updatedAt, @JsonKey(name: 'sla_due')@UtcDateTimeConverter() this.slaDue, @JsonKey(name: 'bill_amount') this.billAmount, @JsonKey(name: 'billing_procedure') this.billingProcedure, @JsonKey(name: 'payment_collected') this.paymentCollected, @JsonKey(name: 'has_amc') this.hasAmc, @JsonKey(name: 'completed_at')@UtcDateTimeConverter() this.completedDate});
  factory _Ticket.fromJson(Map<String, dynamic> json) => _$TicketFromJson(json);

@override@JsonKey(name: 'id') final  String ticketId;
@override@JsonKey(name: 'customer_id') final  String customerId;
@override@JsonKey(name: 'client_ticket_uuid') final  String? clientTicketUuid;
@override@JsonKey(name: 'title') final  String title;
@override@JsonKey(name: 'description') final  String? description;
@override@JsonKey(name: 'contact_phone') final  String? contactPhone;
@override@JsonKey(name: 'screenshot_url') final  String? screenshotUrl;
@override@JsonKey(name: 'category') final  String? category;
@override@JsonKey(name: 'status') final  String status;
@override@JsonKey(name: 'priority') final  String? priority;
@override@JsonKey(name: 'created_by') final  String createdBy;
@override@JsonKey(name: 'assigned_to') final  String? assignedTo;
@override@JsonKey(name: 'created_at')@UtcDateTimeConverter() final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at')@UtcDateTimeConverter() final  DateTime? updatedAt;
@override@JsonKey(name: 'sla_due')@UtcDateTimeConverter() final  DateTime? slaDue;
@override@JsonKey(name: 'bill_amount') final  double? billAmount;
@override@JsonKey(name: 'billing_procedure') final  String? billingProcedure;
@override@JsonKey(name: 'payment_collected') final  bool? paymentCollected;
@override@JsonKey(name: 'has_amc') final  bool? hasAmc;
@override@JsonKey(name: 'completed_at')@UtcDateTimeConverter() final  DateTime? completedDate;

/// Create a copy of Ticket
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TicketCopyWith<_Ticket> get copyWith => __$TicketCopyWithImpl<_Ticket>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TicketToJson(this, );
}
@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'Ticket'))
    ..add(DiagnosticsProperty('ticketId', ticketId))..add(DiagnosticsProperty('customerId', customerId))..add(DiagnosticsProperty('clientTicketUuid', clientTicketUuid))..add(DiagnosticsProperty('title', title))..add(DiagnosticsProperty('description', description))..add(DiagnosticsProperty('contactPhone', contactPhone))..add(DiagnosticsProperty('screenshotUrl', screenshotUrl))..add(DiagnosticsProperty('category', category))..add(DiagnosticsProperty('status', status))..add(DiagnosticsProperty('priority', priority))..add(DiagnosticsProperty('createdBy', createdBy))..add(DiagnosticsProperty('assignedTo', assignedTo))..add(DiagnosticsProperty('createdAt', createdAt))..add(DiagnosticsProperty('updatedAt', updatedAt))..add(DiagnosticsProperty('slaDue', slaDue))..add(DiagnosticsProperty('billAmount', billAmount))..add(DiagnosticsProperty('billingProcedure', billingProcedure))..add(DiagnosticsProperty('paymentCollected', paymentCollected))..add(DiagnosticsProperty('hasAmc', hasAmc))..add(DiagnosticsProperty('completedDate', completedDate));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Ticket&&(identical(other.ticketId, ticketId) || other.ticketId == ticketId)&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.clientTicketUuid, clientTicketUuid) || other.clientTicketUuid == clientTicketUuid)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.contactPhone, contactPhone) || other.contactPhone == contactPhone)&&(identical(other.screenshotUrl, screenshotUrl) || other.screenshotUrl == screenshotUrl)&&(identical(other.category, category) || other.category == category)&&(identical(other.status, status) || other.status == status)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.assignedTo, assignedTo) || other.assignedTo == assignedTo)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.slaDue, slaDue) || other.slaDue == slaDue)&&(identical(other.billAmount, billAmount) || other.billAmount == billAmount)&&(identical(other.billingProcedure, billingProcedure) || other.billingProcedure == billingProcedure)&&(identical(other.paymentCollected, paymentCollected) || other.paymentCollected == paymentCollected)&&(identical(other.hasAmc, hasAmc) || other.hasAmc == hasAmc)&&(identical(other.completedDate, completedDate) || other.completedDate == completedDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,ticketId,customerId,clientTicketUuid,title,description,contactPhone,screenshotUrl,category,status,priority,createdBy,assignedTo,createdAt,updatedAt,slaDue,billAmount,billingProcedure,paymentCollected,hasAmc,completedDate]);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'Ticket(ticketId: $ticketId, customerId: $customerId, clientTicketUuid: $clientTicketUuid, title: $title, description: $description, contactPhone: $contactPhone, screenshotUrl: $screenshotUrl, category: $category, status: $status, priority: $priority, createdBy: $createdBy, assignedTo: $assignedTo, createdAt: $createdAt, updatedAt: $updatedAt, slaDue: $slaDue, billAmount: $billAmount, billingProcedure: $billingProcedure, paymentCollected: $paymentCollected, hasAmc: $hasAmc, completedDate: $completedDate)';
}


}

/// @nodoc
abstract mixin class _$TicketCopyWith<$Res> implements $TicketCopyWith<$Res> {
  factory _$TicketCopyWith(_Ticket value, $Res Function(_Ticket) _then) = __$TicketCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'id') String ticketId,@JsonKey(name: 'customer_id') String customerId,@JsonKey(name: 'client_ticket_uuid') String? clientTicketUuid,@JsonKey(name: 'title') String title,@JsonKey(name: 'description') String? description,@JsonKey(name: 'contact_phone') String? contactPhone,@JsonKey(name: 'screenshot_url') String? screenshotUrl,@JsonKey(name: 'category') String? category,@JsonKey(name: 'status') String status,@JsonKey(name: 'priority') String? priority,@JsonKey(name: 'created_by') String createdBy,@JsonKey(name: 'assigned_to') String? assignedTo,@JsonKey(name: 'created_at')@UtcDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@UtcDateTimeConverter() DateTime? updatedAt,@JsonKey(name: 'sla_due')@UtcDateTimeConverter() DateTime? slaDue,@JsonKey(name: 'bill_amount') double? billAmount,@JsonKey(name: 'billing_procedure') String? billingProcedure,@JsonKey(name: 'payment_collected') bool? paymentCollected,@JsonKey(name: 'has_amc') bool? hasAmc,@JsonKey(name: 'completed_at')@UtcDateTimeConverter() DateTime? completedDate
});




}
/// @nodoc
class __$TicketCopyWithImpl<$Res>
    implements _$TicketCopyWith<$Res> {
  __$TicketCopyWithImpl(this._self, this._then);

  final _Ticket _self;
  final $Res Function(_Ticket) _then;

/// Create a copy of Ticket
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? ticketId = null,Object? customerId = null,Object? clientTicketUuid = freezed,Object? title = null,Object? description = freezed,Object? contactPhone = freezed,Object? screenshotUrl = freezed,Object? category = freezed,Object? status = null,Object? priority = freezed,Object? createdBy = null,Object? assignedTo = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? slaDue = freezed,Object? billAmount = freezed,Object? billingProcedure = freezed,Object? paymentCollected = freezed,Object? hasAmc = freezed,Object? completedDate = freezed,}) {
  return _then(_Ticket(
ticketId: null == ticketId ? _self.ticketId : ticketId // ignore: cast_nullable_to_non_nullable
as String,customerId: null == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as String,clientTicketUuid: freezed == clientTicketUuid ? _self.clientTicketUuid : clientTicketUuid // ignore: cast_nullable_to_non_nullable
as String?,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,contactPhone: freezed == contactPhone ? _self.contactPhone : contactPhone // ignore: cast_nullable_to_non_nullable
as String?,screenshotUrl: freezed == screenshotUrl ? _self.screenshotUrl : screenshotUrl // ignore: cast_nullable_to_non_nullable
as String?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,priority: freezed == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as String?,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,assignedTo: freezed == assignedTo ? _self.assignedTo : assignedTo // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,slaDue: freezed == slaDue ? _self.slaDue : slaDue // ignore: cast_nullable_to_non_nullable
as DateTime?,billAmount: freezed == billAmount ? _self.billAmount : billAmount // ignore: cast_nullable_to_non_nullable
as double?,billingProcedure: freezed == billingProcedure ? _self.billingProcedure : billingProcedure // ignore: cast_nullable_to_non_nullable
as String?,paymentCollected: freezed == paymentCollected ? _self.paymentCollected : paymentCollected // ignore: cast_nullable_to_non_nullable
as bool?,hasAmc: freezed == hasAmc ? _self.hasAmc : hasAmc // ignore: cast_nullable_to_non_nullable
as bool?,completedDate: freezed == completedDate ? _self.completedDate : completedDate // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
