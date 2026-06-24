// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ChatMessage {

 String get id;@JsonKey(name: 'sender_id') String get senderId;@JsonKey(name: 'receiver_id') String? get receiverId;@JsonKey(name: 'sender_name') String get senderName;@JsonKey(name: 'sender_role') String get senderRole;@JsonKey(name: 'sender_avatar_url') String? get senderAvatarUrl; String get content;@JsonKey(name: 'created_at')@UtcDateTimeConverter() DateTime get createdAt;@JsonKey(name: 'is_deleted') bool get isDeleted;@JsonKey(name: 'reactions') List<Map<String, dynamic>> get reactions;@JsonKey(name: 'reply_to_message_id') String? get replyToMessageId;@JsonKey(name: 'reply_to_sender_name') String? get replyToSenderName;@JsonKey(name: 'reply_to_content') String? get replyToContent;@JsonKey(name: 'file_url') String? get fileUrl;@JsonKey(name: 'file_name') String? get fileName;@JsonKey(name: 'file_type') String? get fileType;@JsonKey(name: 'channel') String get channel;@JsonKey(name: 'rich_text_delta') List<dynamic>? get richTextDelta;
/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatMessageCopyWith<ChatMessage> get copyWith => _$ChatMessageCopyWithImpl<ChatMessage>(this as ChatMessage, _$identity);

  /// Serializes this ChatMessage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.senderId, senderId) || other.senderId == senderId)&&(identical(other.receiverId, receiverId) || other.receiverId == receiverId)&&(identical(other.senderName, senderName) || other.senderName == senderName)&&(identical(other.senderRole, senderRole) || other.senderRole == senderRole)&&(identical(other.senderAvatarUrl, senderAvatarUrl) || other.senderAvatarUrl == senderAvatarUrl)&&(identical(other.content, content) || other.content == content)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted)&&const DeepCollectionEquality().equals(other.reactions, reactions)&&(identical(other.replyToMessageId, replyToMessageId) || other.replyToMessageId == replyToMessageId)&&(identical(other.replyToSenderName, replyToSenderName) || other.replyToSenderName == replyToSenderName)&&(identical(other.replyToContent, replyToContent) || other.replyToContent == replyToContent)&&(identical(other.fileUrl, fileUrl) || other.fileUrl == fileUrl)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.fileType, fileType) || other.fileType == fileType)&&(identical(other.channel, channel) || other.channel == channel)&&const DeepCollectionEquality().equals(other.richTextDelta, richTextDelta));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,senderId,receiverId,senderName,senderRole,senderAvatarUrl,content,createdAt,isDeleted,const DeepCollectionEquality().hash(reactions),replyToMessageId,replyToSenderName,replyToContent,fileUrl,fileName,fileType,channel,const DeepCollectionEquality().hash(richTextDelta));

@override
String toString() {
  return 'ChatMessage(id: $id, senderId: $senderId, receiverId: $receiverId, senderName: $senderName, senderRole: $senderRole, senderAvatarUrl: $senderAvatarUrl, content: $content, createdAt: $createdAt, isDeleted: $isDeleted, reactions: $reactions, replyToMessageId: $replyToMessageId, replyToSenderName: $replyToSenderName, replyToContent: $replyToContent, fileUrl: $fileUrl, fileName: $fileName, fileType: $fileType, channel: $channel, richTextDelta: $richTextDelta)';
}


}

/// @nodoc
abstract mixin class $ChatMessageCopyWith<$Res>  {
  factory $ChatMessageCopyWith(ChatMessage value, $Res Function(ChatMessage) _then) = _$ChatMessageCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'sender_id') String senderId,@JsonKey(name: 'receiver_id') String? receiverId,@JsonKey(name: 'sender_name') String senderName,@JsonKey(name: 'sender_role') String senderRole,@JsonKey(name: 'sender_avatar_url') String? senderAvatarUrl, String content,@JsonKey(name: 'created_at')@UtcDateTimeConverter() DateTime createdAt,@JsonKey(name: 'is_deleted') bool isDeleted,@JsonKey(name: 'reactions') List<Map<String, dynamic>> reactions,@JsonKey(name: 'reply_to_message_id') String? replyToMessageId,@JsonKey(name: 'reply_to_sender_name') String? replyToSenderName,@JsonKey(name: 'reply_to_content') String? replyToContent,@JsonKey(name: 'file_url') String? fileUrl,@JsonKey(name: 'file_name') String? fileName,@JsonKey(name: 'file_type') String? fileType,@JsonKey(name: 'channel') String channel,@JsonKey(name: 'rich_text_delta') List<dynamic>? richTextDelta
});




}
/// @nodoc
class _$ChatMessageCopyWithImpl<$Res>
    implements $ChatMessageCopyWith<$Res> {
  _$ChatMessageCopyWithImpl(this._self, this._then);

  final ChatMessage _self;
  final $Res Function(ChatMessage) _then;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? senderId = null,Object? receiverId = freezed,Object? senderName = null,Object? senderRole = null,Object? senderAvatarUrl = freezed,Object? content = null,Object? createdAt = null,Object? isDeleted = null,Object? reactions = null,Object? replyToMessageId = freezed,Object? replyToSenderName = freezed,Object? replyToContent = freezed,Object? fileUrl = freezed,Object? fileName = freezed,Object? fileType = freezed,Object? channel = null,Object? richTextDelta = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,senderId: null == senderId ? _self.senderId : senderId // ignore: cast_nullable_to_non_nullable
as String,receiverId: freezed == receiverId ? _self.receiverId : receiverId // ignore: cast_nullable_to_non_nullable
as String?,senderName: null == senderName ? _self.senderName : senderName // ignore: cast_nullable_to_non_nullable
as String,senderRole: null == senderRole ? _self.senderRole : senderRole // ignore: cast_nullable_to_non_nullable
as String,senderAvatarUrl: freezed == senderAvatarUrl ? _self.senderAvatarUrl : senderAvatarUrl // ignore: cast_nullable_to_non_nullable
as String?,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,reactions: null == reactions ? _self.reactions : reactions // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,replyToMessageId: freezed == replyToMessageId ? _self.replyToMessageId : replyToMessageId // ignore: cast_nullable_to_non_nullable
as String?,replyToSenderName: freezed == replyToSenderName ? _self.replyToSenderName : replyToSenderName // ignore: cast_nullable_to_non_nullable
as String?,replyToContent: freezed == replyToContent ? _self.replyToContent : replyToContent // ignore: cast_nullable_to_non_nullable
as String?,fileUrl: freezed == fileUrl ? _self.fileUrl : fileUrl // ignore: cast_nullable_to_non_nullable
as String?,fileName: freezed == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String?,fileType: freezed == fileType ? _self.fileType : fileType // ignore: cast_nullable_to_non_nullable
as String?,channel: null == channel ? _self.channel : channel // ignore: cast_nullable_to_non_nullable
as String,richTextDelta: freezed == richTextDelta ? _self.richTextDelta : richTextDelta // ignore: cast_nullable_to_non_nullable
as List<dynamic>?,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatMessage].
extension ChatMessagePatterns on ChatMessage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatMessage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatMessage value)  $default,){
final _that = this;
switch (_that) {
case _ChatMessage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatMessage value)?  $default,){
final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'sender_id')  String senderId, @JsonKey(name: 'receiver_id')  String? receiverId, @JsonKey(name: 'sender_name')  String senderName, @JsonKey(name: 'sender_role')  String senderRole, @JsonKey(name: 'sender_avatar_url')  String? senderAvatarUrl,  String content, @JsonKey(name: 'created_at')@UtcDateTimeConverter()  DateTime createdAt, @JsonKey(name: 'is_deleted')  bool isDeleted, @JsonKey(name: 'reactions')  List<Map<String, dynamic>> reactions, @JsonKey(name: 'reply_to_message_id')  String? replyToMessageId, @JsonKey(name: 'reply_to_sender_name')  String? replyToSenderName, @JsonKey(name: 'reply_to_content')  String? replyToContent, @JsonKey(name: 'file_url')  String? fileUrl, @JsonKey(name: 'file_name')  String? fileName, @JsonKey(name: 'file_type')  String? fileType, @JsonKey(name: 'channel')  String channel, @JsonKey(name: 'rich_text_delta')  List<dynamic>? richTextDelta)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
return $default(_that.id,_that.senderId,_that.receiverId,_that.senderName,_that.senderRole,_that.senderAvatarUrl,_that.content,_that.createdAt,_that.isDeleted,_that.reactions,_that.replyToMessageId,_that.replyToSenderName,_that.replyToContent,_that.fileUrl,_that.fileName,_that.fileType,_that.channel,_that.richTextDelta);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'sender_id')  String senderId, @JsonKey(name: 'receiver_id')  String? receiverId, @JsonKey(name: 'sender_name')  String senderName, @JsonKey(name: 'sender_role')  String senderRole, @JsonKey(name: 'sender_avatar_url')  String? senderAvatarUrl,  String content, @JsonKey(name: 'created_at')@UtcDateTimeConverter()  DateTime createdAt, @JsonKey(name: 'is_deleted')  bool isDeleted, @JsonKey(name: 'reactions')  List<Map<String, dynamic>> reactions, @JsonKey(name: 'reply_to_message_id')  String? replyToMessageId, @JsonKey(name: 'reply_to_sender_name')  String? replyToSenderName, @JsonKey(name: 'reply_to_content')  String? replyToContent, @JsonKey(name: 'file_url')  String? fileUrl, @JsonKey(name: 'file_name')  String? fileName, @JsonKey(name: 'file_type')  String? fileType, @JsonKey(name: 'channel')  String channel, @JsonKey(name: 'rich_text_delta')  List<dynamic>? richTextDelta)  $default,) {final _that = this;
switch (_that) {
case _ChatMessage():
return $default(_that.id,_that.senderId,_that.receiverId,_that.senderName,_that.senderRole,_that.senderAvatarUrl,_that.content,_that.createdAt,_that.isDeleted,_that.reactions,_that.replyToMessageId,_that.replyToSenderName,_that.replyToContent,_that.fileUrl,_that.fileName,_that.fileType,_that.channel,_that.richTextDelta);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'sender_id')  String senderId, @JsonKey(name: 'receiver_id')  String? receiverId, @JsonKey(name: 'sender_name')  String senderName, @JsonKey(name: 'sender_role')  String senderRole, @JsonKey(name: 'sender_avatar_url')  String? senderAvatarUrl,  String content, @JsonKey(name: 'created_at')@UtcDateTimeConverter()  DateTime createdAt, @JsonKey(name: 'is_deleted')  bool isDeleted, @JsonKey(name: 'reactions')  List<Map<String, dynamic>> reactions, @JsonKey(name: 'reply_to_message_id')  String? replyToMessageId, @JsonKey(name: 'reply_to_sender_name')  String? replyToSenderName, @JsonKey(name: 'reply_to_content')  String? replyToContent, @JsonKey(name: 'file_url')  String? fileUrl, @JsonKey(name: 'file_name')  String? fileName, @JsonKey(name: 'file_type')  String? fileType, @JsonKey(name: 'channel')  String channel, @JsonKey(name: 'rich_text_delta')  List<dynamic>? richTextDelta)?  $default,) {final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
return $default(_that.id,_that.senderId,_that.receiverId,_that.senderName,_that.senderRole,_that.senderAvatarUrl,_that.content,_that.createdAt,_that.isDeleted,_that.reactions,_that.replyToMessageId,_that.replyToSenderName,_that.replyToContent,_that.fileUrl,_that.fileName,_that.fileType,_that.channel,_that.richTextDelta);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChatMessage implements ChatMessage {
  const _ChatMessage({required this.id, @JsonKey(name: 'sender_id') required this.senderId, @JsonKey(name: 'receiver_id') this.receiverId, @JsonKey(name: 'sender_name') required this.senderName, @JsonKey(name: 'sender_role') required this.senderRole, @JsonKey(name: 'sender_avatar_url') this.senderAvatarUrl, required this.content, @JsonKey(name: 'created_at')@UtcDateTimeConverter() required this.createdAt, @JsonKey(name: 'is_deleted') this.isDeleted = false, @JsonKey(name: 'reactions') final  List<Map<String, dynamic>> reactions = const [], @JsonKey(name: 'reply_to_message_id') this.replyToMessageId, @JsonKey(name: 'reply_to_sender_name') this.replyToSenderName, @JsonKey(name: 'reply_to_content') this.replyToContent, @JsonKey(name: 'file_url') this.fileUrl, @JsonKey(name: 'file_name') this.fileName, @JsonKey(name: 'file_type') this.fileType, @JsonKey(name: 'channel') this.channel = 'support-chat', @JsonKey(name: 'rich_text_delta') final  List<dynamic>? richTextDelta}): _reactions = reactions,_richTextDelta = richTextDelta;
  factory _ChatMessage.fromJson(Map<String, dynamic> json) => _$ChatMessageFromJson(json);

@override final  String id;
@override@JsonKey(name: 'sender_id') final  String senderId;
@override@JsonKey(name: 'receiver_id') final  String? receiverId;
@override@JsonKey(name: 'sender_name') final  String senderName;
@override@JsonKey(name: 'sender_role') final  String senderRole;
@override@JsonKey(name: 'sender_avatar_url') final  String? senderAvatarUrl;
@override final  String content;
@override@JsonKey(name: 'created_at')@UtcDateTimeConverter() final  DateTime createdAt;
@override@JsonKey(name: 'is_deleted') final  bool isDeleted;
 final  List<Map<String, dynamic>> _reactions;
@override@JsonKey(name: 'reactions') List<Map<String, dynamic>> get reactions {
  if (_reactions is EqualUnmodifiableListView) return _reactions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_reactions);
}

@override@JsonKey(name: 'reply_to_message_id') final  String? replyToMessageId;
@override@JsonKey(name: 'reply_to_sender_name') final  String? replyToSenderName;
@override@JsonKey(name: 'reply_to_content') final  String? replyToContent;
@override@JsonKey(name: 'file_url') final  String? fileUrl;
@override@JsonKey(name: 'file_name') final  String? fileName;
@override@JsonKey(name: 'file_type') final  String? fileType;
@override@JsonKey(name: 'channel') final  String channel;
 final  List<dynamic>? _richTextDelta;
@override@JsonKey(name: 'rich_text_delta') List<dynamic>? get richTextDelta {
  final value = _richTextDelta;
  if (value == null) return null;
  if (_richTextDelta is EqualUnmodifiableListView) return _richTextDelta;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatMessageCopyWith<_ChatMessage> get copyWith => __$ChatMessageCopyWithImpl<_ChatMessage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatMessageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.senderId, senderId) || other.senderId == senderId)&&(identical(other.receiverId, receiverId) || other.receiverId == receiverId)&&(identical(other.senderName, senderName) || other.senderName == senderName)&&(identical(other.senderRole, senderRole) || other.senderRole == senderRole)&&(identical(other.senderAvatarUrl, senderAvatarUrl) || other.senderAvatarUrl == senderAvatarUrl)&&(identical(other.content, content) || other.content == content)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted)&&const DeepCollectionEquality().equals(other._reactions, _reactions)&&(identical(other.replyToMessageId, replyToMessageId) || other.replyToMessageId == replyToMessageId)&&(identical(other.replyToSenderName, replyToSenderName) || other.replyToSenderName == replyToSenderName)&&(identical(other.replyToContent, replyToContent) || other.replyToContent == replyToContent)&&(identical(other.fileUrl, fileUrl) || other.fileUrl == fileUrl)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.fileType, fileType) || other.fileType == fileType)&&(identical(other.channel, channel) || other.channel == channel)&&const DeepCollectionEquality().equals(other._richTextDelta, _richTextDelta));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,senderId,receiverId,senderName,senderRole,senderAvatarUrl,content,createdAt,isDeleted,const DeepCollectionEquality().hash(_reactions),replyToMessageId,replyToSenderName,replyToContent,fileUrl,fileName,fileType,channel,const DeepCollectionEquality().hash(_richTextDelta));

@override
String toString() {
  return 'ChatMessage(id: $id, senderId: $senderId, receiverId: $receiverId, senderName: $senderName, senderRole: $senderRole, senderAvatarUrl: $senderAvatarUrl, content: $content, createdAt: $createdAt, isDeleted: $isDeleted, reactions: $reactions, replyToMessageId: $replyToMessageId, replyToSenderName: $replyToSenderName, replyToContent: $replyToContent, fileUrl: $fileUrl, fileName: $fileName, fileType: $fileType, channel: $channel, richTextDelta: $richTextDelta)';
}


}

/// @nodoc
abstract mixin class _$ChatMessageCopyWith<$Res> implements $ChatMessageCopyWith<$Res> {
  factory _$ChatMessageCopyWith(_ChatMessage value, $Res Function(_ChatMessage) _then) = __$ChatMessageCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'sender_id') String senderId,@JsonKey(name: 'receiver_id') String? receiverId,@JsonKey(name: 'sender_name') String senderName,@JsonKey(name: 'sender_role') String senderRole,@JsonKey(name: 'sender_avatar_url') String? senderAvatarUrl, String content,@JsonKey(name: 'created_at')@UtcDateTimeConverter() DateTime createdAt,@JsonKey(name: 'is_deleted') bool isDeleted,@JsonKey(name: 'reactions') List<Map<String, dynamic>> reactions,@JsonKey(name: 'reply_to_message_id') String? replyToMessageId,@JsonKey(name: 'reply_to_sender_name') String? replyToSenderName,@JsonKey(name: 'reply_to_content') String? replyToContent,@JsonKey(name: 'file_url') String? fileUrl,@JsonKey(name: 'file_name') String? fileName,@JsonKey(name: 'file_type') String? fileType,@JsonKey(name: 'channel') String channel,@JsonKey(name: 'rich_text_delta') List<dynamic>? richTextDelta
});




}
/// @nodoc
class __$ChatMessageCopyWithImpl<$Res>
    implements _$ChatMessageCopyWith<$Res> {
  __$ChatMessageCopyWithImpl(this._self, this._then);

  final _ChatMessage _self;
  final $Res Function(_ChatMessage) _then;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? senderId = null,Object? receiverId = freezed,Object? senderName = null,Object? senderRole = null,Object? senderAvatarUrl = freezed,Object? content = null,Object? createdAt = null,Object? isDeleted = null,Object? reactions = null,Object? replyToMessageId = freezed,Object? replyToSenderName = freezed,Object? replyToContent = freezed,Object? fileUrl = freezed,Object? fileName = freezed,Object? fileType = freezed,Object? channel = null,Object? richTextDelta = freezed,}) {
  return _then(_ChatMessage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,senderId: null == senderId ? _self.senderId : senderId // ignore: cast_nullable_to_non_nullable
as String,receiverId: freezed == receiverId ? _self.receiverId : receiverId // ignore: cast_nullable_to_non_nullable
as String?,senderName: null == senderName ? _self.senderName : senderName // ignore: cast_nullable_to_non_nullable
as String,senderRole: null == senderRole ? _self.senderRole : senderRole // ignore: cast_nullable_to_non_nullable
as String,senderAvatarUrl: freezed == senderAvatarUrl ? _self.senderAvatarUrl : senderAvatarUrl // ignore: cast_nullable_to_non_nullable
as String?,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,reactions: null == reactions ? _self._reactions : reactions // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,replyToMessageId: freezed == replyToMessageId ? _self.replyToMessageId : replyToMessageId // ignore: cast_nullable_to_non_nullable
as String?,replyToSenderName: freezed == replyToSenderName ? _self.replyToSenderName : replyToSenderName // ignore: cast_nullable_to_non_nullable
as String?,replyToContent: freezed == replyToContent ? _self.replyToContent : replyToContent // ignore: cast_nullable_to_non_nullable
as String?,fileUrl: freezed == fileUrl ? _self.fileUrl : fileUrl // ignore: cast_nullable_to_non_nullable
as String?,fileName: freezed == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String?,fileType: freezed == fileType ? _self.fileType : fileType // ignore: cast_nullable_to_non_nullable
as String?,channel: null == channel ? _self.channel : channel // ignore: cast_nullable_to_non_nullable
as String,richTextDelta: freezed == richTextDelta ? _self._richTextDelta : richTextDelta // ignore: cast_nullable_to_non_nullable
as List<dynamic>?,
  ));
}


}

// dart format on
