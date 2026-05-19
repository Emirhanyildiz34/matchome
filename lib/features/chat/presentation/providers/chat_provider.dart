import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/chat_repository.dart';
import '../../data/models/conversation_model.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(Supabase.instance.client);
});

/// Kullanıcının tüm sohbetleri
final conversationsProvider =
    FutureProvider.autoDispose<List<ConversationModel>>((ref) async {
  return ref.read(chatRepositoryProvider).getConversations();
});
