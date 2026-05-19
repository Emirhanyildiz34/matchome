import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/conversation_model.dart';
import 'models/message_model.dart';

class ChatRepository {
  final SupabaseClient _supabase;

  ChatRepository(this._supabase);

  String get _currentUserId {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Oturum süresi dolmuş. Lütfen tekrar giriş yapın.');
    }
    return user.id;
  }

  /// Mevcut bir sohbet varsa id'sini döndürür, yoksa oluşturur
  Future<String> findOrCreateConversation({
    required String hostId,
    String listingType = 'listing',
    String? listingId,
    String? listingImageUrl,
    String? listingTitle,
  }) async {
    final senderId = _currentUserId;

    // Katılımcı ID'lerini sırala — benzersizlik için (p1 < p2 alfabetik)
    final p1 = senderId.compareTo(hostId) < 0 ? senderId : hostId;
    final p2 = senderId.compareTo(hostId) < 0 ? hostId : senderId;

    // Mevcut sohbeti bul (aynı kullanıcılar + aynı ilan tipi)
    final existing = await _supabase
        .from('conversations')
        .select('id')
        .eq('participant1_id', p1)
        .eq('participant2_id', p2)
        .eq('listing_type', listingType)
        .maybeSingle();

    if (existing != null) return existing['id'] as String;

    // Yeni sohbet oluştur
    final result = await _supabase
        .from('conversations')
        .insert({
          'participant1_id': p1,
          'participant2_id': p2,
          'last_message_at': DateTime.now().toUtc().toIso8601String(),
          'listing_type': listingType,
          if (listingId != null) 'listing_id': listingId,
          if (listingImageUrl != null) 'listing_image_url': listingImageUrl,
          if (listingTitle != null) 'listing_title': listingTitle,
        })
        .select('id')
        .single();

    return result['id'] as String;
  }

  /// Kullanıcının tüm sohbetlerini getirir (katılımcı ismiyle birlikte)
  Future<List<ConversationModel>> getConversations() async {
    final userId = _currentUserId;
    final data = await _supabase
        .from('conversations')
        .select(
          'id, participant1_id, participant2_id, last_message, last_message_at, '
          'listing_id, listing_type, listing_image_url, listing_title, '
          'p1:participant1_id(full_name), '
          'p2:participant2_id(full_name)',
        )
        .or('participant1_id.eq.$userId,participant2_id.eq.$userId')
        .order('last_message_at', ascending: false);

    return (data as List)
        .map((json) => ConversationModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Bir sohbetin tüm mesajlarını getirir
  Future<List<MessageModel>> getMessages(String conversationId) async {
    final data = await _supabase
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);

    return (data as List)
        .map((json) => MessageModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Mesajı siler (soft delete)
  Future<void> deleteMessage(String messageId) async {
    await _supabase
        .from('messages')
        .update({'is_deleted': true}).eq('id', messageId);
  }

  /// Sohbeti tamamen siler (hard delete)
  Future<void> deleteConversation(String conversationId) async {
    await _supabase.from('conversations').delete().eq('id', conversationId);
  }

  /// Mesaj gönderir ve sohbette son mesajı günceller
  Future<void> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    final senderId = _currentUserId;

    await _supabase.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': senderId,
      'content': content,
    });

    await _supabase.from('conversations').update({
      'last_message': content,
      'last_message_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', conversationId);
  }

  /// Sohbetteki okunmamış mesajları okundu olarak işaretler
  Future<void> markAsRead(String conversationId) async {
    final userId = _currentUserId;
    await _supabase
        .from('messages')
        .update({'is_read': true})
        .eq('conversation_id', conversationId)
        .neq('sender_id', userId)
        .eq('is_read', false);
  }

  /// Yeni mesajları gerçek zamanlı dinler (Supabase Realtime)
  RealtimeChannel subscribeToMessages(
    String conversationId,
    void Function(MessageModel message) onMessage,
    void Function(MessageModel message) onMessageUpdated,
  ) {
    return _supabase
        .channel('messages:$conversationId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) {
            final message = MessageModel.fromJson(payload.newRecord);
            onMessage(message);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) {
            final message = MessageModel.fromJson(payload.newRecord);
            onMessageUpdated(message);
          },
        )
        .subscribe();
  }
}
