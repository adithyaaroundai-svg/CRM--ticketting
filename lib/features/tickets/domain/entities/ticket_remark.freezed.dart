// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ticket_remark.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TicketRemark {

 String get id;@JsonKey(name: 'ticket_id') String get ticketId;@JsonKey(name: 'agent_id') String? get agentId;@JsonKey(name: 'customer_id') String? get customerId; String? get remark;@JsonKey(name: 'remark_type') String get remarkType;@JsonKey(name: 'voice_url') String? get voiceUrl;@JsonKey(name: 'duration_seconds') int? get durationSeconds; String? get stage;@JsonKey(name: 'created_at')@UtcDateTimeConverter() DateTime? get createdAt;@JsonKey(name: 'updated_at')@UtcDateTimeConverter() DateTime? get updatedAt;
/// Create a copy of TicketRemark
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TicketRemarkCopyWith<TicketRemark> get copyWith => _$TicketRemarkCopyWithImpl<TicketRemark>(this as TicketRemark, _$identity);

  /// Serializes this TicketRemark to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TicketRemark&&(identical(other.id, id) || other.id == id)&&(identical(other.ticketId, ticketId) || other.ticketId == ticketId)&&(identical(other.agentId, agentId) || other.agentId == agentId)&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.remark, remark) || other.remark == remark)&&(identical(other.remarkType, remarkType) || other.remarkType == remarkType)&&(identical(other.voiceUrl, voiceUrl) || other.voiceUrl == voiceUrl)&&(identical(other.durationSeconds, durationSeconds) || other.durationSeconds == durationSeconds)&&(identical(other.stage, stage) || other.stage == stage)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,ticketId,agentId,customerId,remark,remarkType,voiceUrl,durationSeconds,stage,createdAt,updatedAt);

@override
String toString() {
  return 'TicketRemark(id: $id, ticketId: $ticketId, agentId: $agentId, customerId: $customerId, remark: $remark, remarkType: $remarkType, voiceUrl: $voiceUrl, durationSeconds: $durationSeconds, stage: $stage, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $TicketRemarkCopyWith<$Res>  {
  factory $TicketRemarkCopyWith(TicketRemark value, $Res Function(TicketRemark) _then) = _$TicketRemarkCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'ticket_id') String ticketId,@JsonKey(name: 'agent_id') String? agentId,@JsonKey(name: 'customer_id') String? customerId, String? remark,@JsonKey(name: 'remark_type') String remarkType,@JsonKey(name: 'voice_url') String? voiceUrl,@JsonKey(name: 'duration_seconds') int? durationSeconds, String? stage,@JsonKey(name: 'created_at')@UtcDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@UtcDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class _$TicketRemarkCopyWithImpl<$Res>
    implements $TicketRemarkCopyWith<$Res> {
  _$TicketRemarkCopyWithImpl(this._self, this._then);

  final TicketRemark _self;
  final $Res Function(TicketRemark) _then;

/// Create a copy of TicketRemark
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? ticketId = null,Object? agentId = freezed,Object? customerId = freezed,Object? remark = freezed,Object? remarkType = null,Object? voiceUrl = freezed,Object? durationSeconds = freezed,Object? stage = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,ticketId: null == ticketId ? _self.ticketId : ticketId // ignore: cast_nullable_to_non_nullable
as String,agentId: freezed == agentId ? _self.agentId : agentId // ignore: cast_nullable_to_non_nullable
as String?,customerId: freezed == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as String?,remark: freezed == remark ? _self.remark : remark // ignore: cast_nullable_to_non_nullable
as String?,remarkType: null == remarkType ? _self.remarkType : remarkType // ignore: cast_nullable_to_non_nullable
as String,voiceUrl: freezed == voiceUrl ? _self.voiceUrl : voiceUrl // ignore: cast_nullable_to_non_nullable
as String?,durationSeconds: freezed == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int?,stage: freezed == stage ? _self.stage : stage // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [TicketRemark].
extension TicketRemarkPatterns on TicketRemark {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TicketRemark value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TicketRemark() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TicketRemark value)  $default,){
final _that = this;
switch (_that) {
case _TicketRemark():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TicketRemark value)?  $default,){
final _that = this;
switch (_that) {
case _TicketRemark() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'ticket_id')  String ticketId, @JsonKey(name: 'agent_id')  String? agentId, @JsonKey(name: 'customer_id')  String? customerId,  String? remark, @JsonKey(name: 'remark_type')  String remarkType, @JsonKey(name: 'voice_url')  String? voiceUrl, @JsonKey(name: 'duration_seconds')  int? durationSeconds,  String? stage, @JsonKey(name: 'created_at')@UtcDateTimeConverter()  DateTime? createdAt, @JsonKey(name: 'updated_at')@UtcDateTimeConverter()  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TicketRemark() when $default != null:
return $default(_that.id,_that.ticketId,_that.agentId,_that.customerId,_that.remark,_that.remarkType,_that.voiceUrl,_that.durationSeconds,_that.stage,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'ticket_id')  String ticketId, @JsonKey(name: 'agent_id')  String? agentId, @JsonKey(name: 'customer_id')  String? customerId,  String? remark, @JsonKey(name: 'remark_type')  String remarkType, @JsonKey(name: 'voice_url')  String? voiceUrl, @JsonKey(name: 'duration_seconds')  int? durationSeconds,  String? stage, @JsonKey(name: 'created_at')@UtcDateTimeConverter()  DateTime? createdAt, @JsonKey(name: 'updated_at')@UtcDateTimeConverter()  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _TicketRemark():
return $default(_that.id,_that.ticketId,_that.agentId,_that.customerId,_that.remark,_that.remarkType,_that.voiceUrl,_that.durationSeconds,_that.stage,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'ticket_id')  String ticketId, @JsonKey(name: 'agent_id')  String? agentId, @JsonKey(name: 'customer_id')  String? customerId,  String? remark, @JsonKey(name: 'remark_type')  String remarkType, @JsonKey(name: 'voice_url')  String? voiceUrl, @JsonKey(name: 'duration_seconds')  int? durationSeconds,  String? stage, @JsonKey(name: 'created_at')@UtcDateTimeConverter()  DateTime? createdAt, @JsonKey(name: 'updated_at')@UtcDateTimeConverter()  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _TicketRemark() when $default != null:
return $default(_that.id,_that.ticketId,_that.agentId,_that.customerId,_that.remark,_that.remarkType,_that.voiceUrl,_that.durationSeconds,_that.stage,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TicketRemark implements TicketRemark {
  const _TicketRemark({required this.id, @JsonKey(name: 'ticket_id') required this.ticketId, @JsonKey(name: 'agent_id') this.agentId, @JsonKey(name: 'customer_id') this.customerId, this.remark, @JsonKey(name: 'remark_type') this.remarkType = 'text', @JsonKey(name: 'voice_url') this.voiceUrl, @JsonKey(name: 'duration_seconds') this.durationSeconds, this.stage, @JsonKey(name: 'created_at')@UtcDateTimeConverter() this.createdAt, @JsonKey(name: 'updated_at')@UtcDateTimeConverter() this.updatedAt});
  factory _TicketRemark.fromJson(Map<String, dynamic> json) => _$TicketRemarkFromJson(json);

@override final  String id;
@override@JsonKey(name: 'ticket_id') final  String ticketId;
@override@JsonKey(name: 'agent_id') final  String? agentId;
@override@JsonKey(name: 'customer_id') final  String? customerId;
@override final  String? remark;
@override@JsonKey(name: 'remark_type') final  String remarkType;
@override@JsonKey(name: 'voice_url') final  String? voiceUrl;
@override@JsonKey(name: 'duration_seconds') final  int? durationSeconds;
@override final  String? stage;
@override@JsonKey(name: 'created_at')@UtcDateTimeConverter() final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at')@UtcDateTimeConverter() final  DateTime? updatedAt;

/// Create a copy of TicketRemark
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TicketRemarkCopyWith<_TicketRemark> get copyWith => __$TicketRemarkCopyWithImpl<_TicketRemark>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TicketRemarkToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TicketRemark&&(identical(other.id, id) || other.id == id)&&(identical(other.ticketId, ticketId) || other.ticketId == ticketId)&&(identical(other.agentId, agentId) || other.agentId == agentId)&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.remark, remark) || other.remark == remark)&&(identical(other.remarkType, remarkType) || other.remarkType == remarkType)&&(identical(other.voiceUrl, voiceUrl) || other.voiceUrl == voiceUrl)&&(identical(other.durationSeconds, durationSeconds) || other.durationSeconds == durationSeconds)&&(identical(other.stage, stage) || other.stage == stage)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,ticketId,agentId,customerId,remark,remarkType,voiceUrl,durationSeconds,stage,createdAt,updatedAt);

@override
String toString() {
  return 'TicketRemark(id: $id, ticketId: $ticketId, agentId: $agentId, customerId: $customerId, remark: $remark, remarkType: $remarkType, voiceUrl: $voiceUrl, durationSeconds: $durationSeconds, stage: $stage, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$TicketRemarkCopyWith<$Res> implements $TicketRemarkCopyWith<$Res> {
  factory _$TicketRemarkCopyWith(_TicketRemark value, $Res Function(_TicketRemark) _then) = __$TicketRemarkCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'ticket_id') String ticketId,@JsonKey(name: 'agent_id') String? agentId,@JsonKey(name: 'customer_id') String? customerId, String? remark,@JsonKey(name: 'remark_type') String remarkType,@JsonKey(name: 'voice_url') String? voiceUrl,@JsonKey(name: 'duration_seconds') int? durationSeconds, String? stage,@JsonKey(name: 'created_at')@UtcDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@UtcDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class __$TicketRemarkCopyWithImpl<$Res>
    implements _$TicketRemarkCopyWith<$Res> {
  __$TicketRemarkCopyWithImpl(this._self, this._then);

  final _TicketRemark _self;
  final $Res Function(_TicketRemark) _then;

/// Create a copy of TicketRemark
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? ticketId = null,Object? agentId = freezed,Object? customerId = freezed,Object? remark = freezed,Object? remarkType = null,Object? voiceUrl = freezed,Object? durationSeconds = freezed,Object? stage = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_TicketRemark(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,ticketId: null == ticketId ? _self.ticketId : ticketId // ignore: cast_nullable_to_non_nullable
as String,agentId: freezed == agentId ? _self.agentId : agentId // ignore: cast_nullable_to_non_nullable
as String?,customerId: freezed == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as String?,remark: freezed == remark ? _self.remark : remark // ignore: cast_nullable_to_non_nullable
as String?,remarkType: null == remarkType ? _self.remarkType : remarkType // ignore: cast_nullable_to_non_nullable
as String,voiceUrl: freezed == voiceUrl ? _self.voiceUrl : voiceUrl // ignore: cast_nullable_to_non_nullable
as String?,durationSeconds: freezed == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int?,stage: freezed == stage ? _self.stage : stage // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
