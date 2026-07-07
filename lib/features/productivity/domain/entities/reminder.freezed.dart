// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reminder.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Reminder {

 String get id; String get companyName; String get phoneNumber; DateTime get createdAt; DateTime get remindAt; String get notes; bool get isTriggered; bool get isCompleted;
/// Create a copy of Reminder
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReminderCopyWith<Reminder> get copyWith => _$ReminderCopyWithImpl<Reminder>(this as Reminder, _$identity);

  /// Serializes this Reminder to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Reminder&&(identical(other.id, id) || other.id == id)&&(identical(other.companyName, companyName) || other.companyName == companyName)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.remindAt, remindAt) || other.remindAt == remindAt)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.isTriggered, isTriggered) || other.isTriggered == isTriggered)&&(identical(other.isCompleted, isCompleted) || other.isCompleted == isCompleted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,companyName,phoneNumber,createdAt,remindAt,notes,isTriggered,isCompleted);

@override
String toString() {
  return 'Reminder(id: $id, companyName: $companyName, phoneNumber: $phoneNumber, createdAt: $createdAt, remindAt: $remindAt, notes: $notes, isTriggered: $isTriggered, isCompleted: $isCompleted)';
}


}

/// @nodoc
abstract mixin class $ReminderCopyWith<$Res>  {
  factory $ReminderCopyWith(Reminder value, $Res Function(Reminder) _then) = _$ReminderCopyWithImpl;
@useResult
$Res call({
 String id, String companyName, String phoneNumber, DateTime createdAt, DateTime remindAt, String notes, bool isTriggered, bool isCompleted
});




}
/// @nodoc
class _$ReminderCopyWithImpl<$Res>
    implements $ReminderCopyWith<$Res> {
  _$ReminderCopyWithImpl(this._self, this._then);

  final Reminder _self;
  final $Res Function(Reminder) _then;

/// Create a copy of Reminder
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? companyName = null,Object? phoneNumber = null,Object? createdAt = null,Object? remindAt = null,Object? notes = null,Object? isTriggered = null,Object? isCompleted = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyName: null == companyName ? _self.companyName : companyName // ignore: cast_nullable_to_non_nullable
as String,phoneNumber: null == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,remindAt: null == remindAt ? _self.remindAt : remindAt // ignore: cast_nullable_to_non_nullable
as DateTime,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String,isTriggered: null == isTriggered ? _self.isTriggered : isTriggered // ignore: cast_nullable_to_non_nullable
as bool,isCompleted: null == isCompleted ? _self.isCompleted : isCompleted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Reminder].
extension ReminderPatterns on Reminder {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Reminder value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Reminder() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Reminder value)  $default,){
final _that = this;
switch (_that) {
case _Reminder():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Reminder value)?  $default,){
final _that = this;
switch (_that) {
case _Reminder() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String companyName,  String phoneNumber,  DateTime createdAt,  DateTime remindAt,  String notes,  bool isTriggered,  bool isCompleted)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Reminder() when $default != null:
return $default(_that.id,_that.companyName,_that.phoneNumber,_that.createdAt,_that.remindAt,_that.notes,_that.isTriggered,_that.isCompleted);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String companyName,  String phoneNumber,  DateTime createdAt,  DateTime remindAt,  String notes,  bool isTriggered,  bool isCompleted)  $default,) {final _that = this;
switch (_that) {
case _Reminder():
return $default(_that.id,_that.companyName,_that.phoneNumber,_that.createdAt,_that.remindAt,_that.notes,_that.isTriggered,_that.isCompleted);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String companyName,  String phoneNumber,  DateTime createdAt,  DateTime remindAt,  String notes,  bool isTriggered,  bool isCompleted)?  $default,) {final _that = this;
switch (_that) {
case _Reminder() when $default != null:
return $default(_that.id,_that.companyName,_that.phoneNumber,_that.createdAt,_that.remindAt,_that.notes,_that.isTriggered,_that.isCompleted);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Reminder implements Reminder {
  const _Reminder({required this.id, required this.companyName, required this.phoneNumber, required this.createdAt, required this.remindAt, this.notes = '', this.isTriggered = false, this.isCompleted = false});
  factory _Reminder.fromJson(Map<String, dynamic> json) => _$ReminderFromJson(json);

@override final  String id;
@override final  String companyName;
@override final  String phoneNumber;
@override final  DateTime createdAt;
@override final  DateTime remindAt;
@override@JsonKey() final  String notes;
@override@JsonKey() final  bool isTriggered;
@override@JsonKey() final  bool isCompleted;

/// Create a copy of Reminder
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReminderCopyWith<_Reminder> get copyWith => __$ReminderCopyWithImpl<_Reminder>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReminderToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Reminder&&(identical(other.id, id) || other.id == id)&&(identical(other.companyName, companyName) || other.companyName == companyName)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.remindAt, remindAt) || other.remindAt == remindAt)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.isTriggered, isTriggered) || other.isTriggered == isTriggered)&&(identical(other.isCompleted, isCompleted) || other.isCompleted == isCompleted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,companyName,phoneNumber,createdAt,remindAt,notes,isTriggered,isCompleted);

@override
String toString() {
  return 'Reminder(id: $id, companyName: $companyName, phoneNumber: $phoneNumber, createdAt: $createdAt, remindAt: $remindAt, notes: $notes, isTriggered: $isTriggered, isCompleted: $isCompleted)';
}


}

/// @nodoc
abstract mixin class _$ReminderCopyWith<$Res> implements $ReminderCopyWith<$Res> {
  factory _$ReminderCopyWith(_Reminder value, $Res Function(_Reminder) _then) = __$ReminderCopyWithImpl;
@override @useResult
$Res call({
 String id, String companyName, String phoneNumber, DateTime createdAt, DateTime remindAt, String notes, bool isTriggered, bool isCompleted
});




}
/// @nodoc
class __$ReminderCopyWithImpl<$Res>
    implements _$ReminderCopyWith<$Res> {
  __$ReminderCopyWithImpl(this._self, this._then);

  final _Reminder _self;
  final $Res Function(_Reminder) _then;

/// Create a copy of Reminder
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? companyName = null,Object? phoneNumber = null,Object? createdAt = null,Object? remindAt = null,Object? notes = null,Object? isTriggered = null,Object? isCompleted = null,}) {
  return _then(_Reminder(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyName: null == companyName ? _self.companyName : companyName // ignore: cast_nullable_to_non_nullable
as String,phoneNumber: null == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,remindAt: null == remindAt ? _self.remindAt : remindAt // ignore: cast_nullable_to_non_nullable
as DateTime,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String,isTriggered: null == isTriggered ? _self.isTriggered : isTriggered // ignore: cast_nullable_to_non_nullable
as bool,isCompleted: null == isCompleted ? _self.isCompleted : isCompleted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
