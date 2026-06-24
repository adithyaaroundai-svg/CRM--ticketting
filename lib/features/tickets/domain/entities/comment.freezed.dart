// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'comment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TicketComment {

 String get id;@JsonKey(name: 'ticket_id') String get ticketId; String get author; String get body;@JsonKey(name: 'internal') bool get isInternal;@JsonKey(name: 'created_at')@UtcDateTimeConverter() DateTime? get createdAt;
/// Create a copy of TicketComment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TicketCommentCopyWith<TicketComment> get copyWith => _$TicketCommentCopyWithImpl<TicketComment>(this as TicketComment, _$identity);

  /// Serializes this TicketComment to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TicketComment&&(identical(other.id, id) || other.id == id)&&(identical(other.ticketId, ticketId) || other.ticketId == ticketId)&&(identical(other.author, author) || other.author == author)&&(identical(other.body, body) || other.body == body)&&(identical(other.isInternal, isInternal) || other.isInternal == isInternal)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,ticketId,author,body,isInternal,createdAt);

@override
String toString() {
  return 'TicketComment(id: $id, ticketId: $ticketId, author: $author, body: $body, isInternal: $isInternal, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $TicketCommentCopyWith<$Res>  {
  factory $TicketCommentCopyWith(TicketComment value, $Res Function(TicketComment) _then) = _$TicketCommentCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'ticket_id') String ticketId, String author, String body,@JsonKey(name: 'internal') bool isInternal,@JsonKey(name: 'created_at')@UtcDateTimeConverter() DateTime? createdAt
});




}
/// @nodoc
class _$TicketCommentCopyWithImpl<$Res>
    implements $TicketCommentCopyWith<$Res> {
  _$TicketCommentCopyWithImpl(this._self, this._then);

  final TicketComment _self;
  final $Res Function(TicketComment) _then;

/// Create a copy of TicketComment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? ticketId = null,Object? author = null,Object? body = null,Object? isInternal = null,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,ticketId: null == ticketId ? _self.ticketId : ticketId // ignore: cast_nullable_to_non_nullable
as String,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,isInternal: null == isInternal ? _self.isInternal : isInternal // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [TicketComment].
extension TicketCommentPatterns on TicketComment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TicketComment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TicketComment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TicketComment value)  $default,){
final _that = this;
switch (_that) {
case _TicketComment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TicketComment value)?  $default,){
final _that = this;
switch (_that) {
case _TicketComment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'ticket_id')  String ticketId,  String author,  String body, @JsonKey(name: 'internal')  bool isInternal, @JsonKey(name: 'created_at')@UtcDateTimeConverter()  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TicketComment() when $default != null:
return $default(_that.id,_that.ticketId,_that.author,_that.body,_that.isInternal,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'ticket_id')  String ticketId,  String author,  String body, @JsonKey(name: 'internal')  bool isInternal, @JsonKey(name: 'created_at')@UtcDateTimeConverter()  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _TicketComment():
return $default(_that.id,_that.ticketId,_that.author,_that.body,_that.isInternal,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'ticket_id')  String ticketId,  String author,  String body, @JsonKey(name: 'internal')  bool isInternal, @JsonKey(name: 'created_at')@UtcDateTimeConverter()  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _TicketComment() when $default != null:
return $default(_that.id,_that.ticketId,_that.author,_that.body,_that.isInternal,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TicketComment implements TicketComment {
  const _TicketComment({required this.id, @JsonKey(name: 'ticket_id') required this.ticketId, this.author = 'Unknown', this.body = '', @JsonKey(name: 'internal') this.isInternal = false, @JsonKey(name: 'created_at')@UtcDateTimeConverter() this.createdAt});
  factory _TicketComment.fromJson(Map<String, dynamic> json) => _$TicketCommentFromJson(json);

@override final  String id;
@override@JsonKey(name: 'ticket_id') final  String ticketId;
@override@JsonKey() final  String author;
@override@JsonKey() final  String body;
@override@JsonKey(name: 'internal') final  bool isInternal;
@override@JsonKey(name: 'created_at')@UtcDateTimeConverter() final  DateTime? createdAt;

/// Create a copy of TicketComment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TicketCommentCopyWith<_TicketComment> get copyWith => __$TicketCommentCopyWithImpl<_TicketComment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TicketCommentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TicketComment&&(identical(other.id, id) || other.id == id)&&(identical(other.ticketId, ticketId) || other.ticketId == ticketId)&&(identical(other.author, author) || other.author == author)&&(identical(other.body, body) || other.body == body)&&(identical(other.isInternal, isInternal) || other.isInternal == isInternal)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,ticketId,author,body,isInternal,createdAt);

@override
String toString() {
  return 'TicketComment(id: $id, ticketId: $ticketId, author: $author, body: $body, isInternal: $isInternal, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$TicketCommentCopyWith<$Res> implements $TicketCommentCopyWith<$Res> {
  factory _$TicketCommentCopyWith(_TicketComment value, $Res Function(_TicketComment) _then) = __$TicketCommentCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'ticket_id') String ticketId, String author, String body,@JsonKey(name: 'internal') bool isInternal,@JsonKey(name: 'created_at')@UtcDateTimeConverter() DateTime? createdAt
});




}
/// @nodoc
class __$TicketCommentCopyWithImpl<$Res>
    implements _$TicketCommentCopyWith<$Res> {
  __$TicketCommentCopyWithImpl(this._self, this._then);

  final _TicketComment _self;
  final $Res Function(_TicketComment) _then;

/// Create a copy of TicketComment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? ticketId = null,Object? author = null,Object? body = null,Object? isInternal = null,Object? createdAt = freezed,}) {
  return _then(_TicketComment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,ticketId: null == ticketId ? _self.ticketId : ticketId // ignore: cast_nullable_to_non_nullable
as String,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,isInternal: null == isInternal ? _self.isInternal : isInternal // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
