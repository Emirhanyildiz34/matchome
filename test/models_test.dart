import 'package:flutter_test/flutter_test.dart';
import 'package:match_home/features/second_hand/data/models/second_hand_item_model.dart';
import 'package:match_home/features/chat/data/models/message_model.dart';
import 'package:match_home/features/chat/data/models/conversation_model.dart';
import 'package:match_home/features/listings/data/models/favorite_model.dart';

void main() {
  group('SecondHandItemModel', () {
    test('fromJson with minimal fields', () {
      final json = {
        'id': 'item1',
        'seller_id': 'user1',
        'title': 'Eski Laptop',
        'price': 3000,
        'category': 'teknoloji',
        'condition': 'az_kullanilmis',
      };

      final item = SecondHandItemModel.fromJson(json);
      expect(item.id, 'item1');
      expect(item.title, 'Eski Laptop');
      expect(item.price, 3000);
      expect(item.category, 'teknoloji');
      expect(item.condition, 'az_kullanilmis');
      expect(item.isActive, true);
      expect(item.imageUrls, isEmpty);
      expect(item.currency, 'TL');
    });

    test('fromJson filters non-http image URLs', () {
      final json = {
        'seller_id': 'user1',
        'title': 'Test',
        'price': 100,
        'category': 'diger',
        'condition': 'iyi',
        'image_urls': [
          'https://example.com/a.jpg',
          'blob:something',
          'http://example.com/b.jpg',
          'data:image/png;base64,xxx',
        ],
      };

      final item = SecondHandItemModel.fromJson(json);
      expect(item.imageUrls.length, 2);
      expect(item.imageUrls[0], 'https://example.com/a.jpg');
      expect(item.imageUrls[1], 'http://example.com/b.jpg');
    });

    test('toJson round-trip preserves data', () {
      final item = SecondHandItemModel(
        sellerId: 'user1',
        title: 'Masa',
        price: 500,
        category: 'mobilya',
        subcategory: 'Çalışma Masası',
        condition: 'iyi',
        city: 'İstanbul',
        district: 'Kadıköy',
      );

      final json = item.toJson();
      final restored = SecondHandItemModel.fromJson(json);
      expect(restored.title, item.title);
      expect(restored.price, item.price);
      expect(restored.city, item.city);
      expect(restored.district, item.district);
    });

    test('fromJson handles null price as 0', () {
      final json = {
        'seller_id': 'user1',
        'title': 'Bedava',
        'category': 'diger',
        'condition': 'iyi',
      };

      final item = SecondHandItemModel.fromJson(json);
      expect(item.price, 0);
    });

    test('categories map has all expected keys', () {
      final keys = SecondHandItemModel.categories.keys.toList();
      expect(
          keys,
          containsAll([
            'kiyafet',
            'aksesuar',
            'teknoloji',
            'mutfak',
            'ders_kitabi',
            'mobilya',
            'spor',
            'diger'
          ]));
    });

    test('conditions map has all expected keys', () {
      expect(SecondHandItemModel.conditions.keys,
          containsAll(['sifir_gibi', 'az_kullanilmis', 'iyi', 'makul']));
    });

    test('getSubcategories returns correct items', () {
      final subs = SecondHandItemModel.getSubcategories('teknoloji');
      expect(subs, isNotEmpty);
      expect(subs, contains('Telefon'));
      expect(subs, contains('Laptop'));
    });

    test('getSubcategories returns empty for unknown category', () {
      final subs = SecondHandItemModel.getSubcategories('non_existent');
      expect(subs, isEmpty);
    });

    test('locationLabel combines city and district', () {
      final item = SecondHandItemModel(
        sellerId: 'u1',
        title: 'T',
        price: 1,
        category: 'diger',
        condition: 'iyi',
        city: 'İstanbul',
        district: 'Kadıköy',
      );
      expect(item.locationLabel, 'İstanbul, Kadıköy');
    });

    test('locationLabel with only city', () {
      final item = SecondHandItemModel(
        sellerId: 'u1',
        title: 'T',
        price: 1,
        category: 'diger',
        condition: 'iyi',
        city: 'Ankara',
      );
      expect(item.locationLabel, 'Ankara');
    });

    test('copyWith preserves unchanged fields', () {
      final original = SecondHandItemModel(
        id: 'id1',
        sellerId: 'seller1',
        title: 'Original',
        price: 100,
        category: 'diger',
        condition: 'iyi',
      );

      final updated = original.copyWith(price: 200);
      expect(updated.price, 200);
      expect(updated.id, 'id1');
      expect(updated.title, 'Original');
    });
  });

  group('MessageModel', () {
    test('fromJson creates valid model', () {
      final json = {
        'id': 'msg1',
        'conversation_id': 'conv1',
        'sender_id': 'user1',
        'content': 'Hello!',
        'is_read': true,
        'is_deleted': false,
        'created_at': '2026-03-23T12:00:00Z',
      };

      final msg = MessageModel.fromJson(json);
      expect(msg.id, 'msg1');
      expect(msg.content, 'Hello!');
      expect(msg.isRead, true);
      expect(msg.isDeleted, false);
    });

    test('fromJson handles missing boolean fields', () {
      final json = {
        'id': 'msg2',
        'conversation_id': 'conv1',
        'sender_id': 'user1',
        'content': 'Test',
        'created_at': '2026-03-23T12:00:00Z',
      };

      final msg = MessageModel.fromJson(json);
      expect(msg.isRead, false);
      expect(msg.isDeleted, false);
    });

    test('copyWith isDeleted', () {
      final msg = MessageModel(
        id: 'msg1',
        conversationId: 'conv1',
        senderId: 'user1',
        content: 'Hello',
        createdAt: DateTime(2026, 3, 23),
      );

      final deleted = msg.copyWith(isDeleted: true);
      expect(deleted.isDeleted, true);
      expect(deleted.content, 'Hello');
    });

    test('toJson doesn\'t include id or created_at', () {
      final msg = MessageModel(
        id: 'msg1',
        conversationId: 'conv1',
        senderId: 'user1',
        content: 'Test',
        createdAt: DateTime.now(),
      );

      final json = msg.toJson();
      expect(json.containsKey('id'), false);
      expect(json.containsKey('created_at'), false);
      expect(json['conversation_id'], 'conv1');
      expect(json['content'], 'Test');
    });
  });

  group('ConversationModel', () {
    test('fromJson with participant names', () {
      final json = {
        'id': 'conv1',
        'participant1_id': 'user_a',
        'participant2_id': 'user_b',
        'last_message': 'Merhaba',
        'last_message_at': '2026-03-23T15:00:00Z',
        'p1': {'full_name': 'Ali'},
        'p2': {'full_name': 'Veli'},
        'listing_type': 'listing',
        'listing_title': 'Güzel Oda',
      };

      final conv = ConversationModel.fromJson(json);
      expect(conv.id, 'conv1');
      expect(conv.participant1Name, 'Ali');
      expect(conv.participant2Name, 'Veli');
      expect(conv.lastMessage, 'Merhaba');
      expect(conv.listingTitle, 'Güzel Oda');
    });

    test('otherUserName returns correct name', () {
      final conv = ConversationModel(
        id: 'c1',
        participant1Id: 'user_a',
        participant2Id: 'user_b',
        lastMessageAt: DateTime.now(),
        participant1Name: 'Ali',
        participant2Name: 'Veli',
      );

      expect(conv.otherUserName('user_a'), 'Veli');
      expect(conv.otherUserName('user_b'), 'Ali');
    });

    test('otherUserName returns fallback when name is null', () {
      final conv = ConversationModel(
        id: 'c1',
        participant1Id: 'user_a',
        participant2Id: 'user_b',
        lastMessageAt: DateTime.now(),
      );

      expect(conv.otherUserName('user_a'), 'Kullanıcı');
      expect(conv.otherUserName('user_b'), 'Kullanıcı');
    });

    test('fromJson handles null last_message_at with DateTime.now()', () {
      final json = {
        'id': 'conv2',
        'participant1_id': 'a',
        'participant2_id': 'b',
      };

      final conv = ConversationModel.fromJson(json);
      // Should not throw, and lastMessageAt should be close to now
      expect(conv.lastMessageAt.difference(DateTime.now()).inSeconds.abs(),
          lessThan(5));
    });

    test('fromJson defaults listing_type to listing', () {
      final json = {
        'id': 'conv3',
        'participant1_id': 'a',
        'participant2_id': 'b',
      };

      final conv = ConversationModel.fromJson(json);
      expect(conv.listingType, 'listing');
    });
  });

  group('FavoriteModel', () {
    test('fromJson creates valid model', () {
      final json = {
        'id': 'fav1',
        'user_id': 'user1',
        'listing_id': 'listing1',
        'category': 'fiyat',
        'price_at_favorite': 5000,
        'notes': 'Güzel fiyat',
        'created_at': '2026-03-23T12:00:00Z',
        'updated_at': '2026-03-23T14:00:00Z',
      };

      final fav = FavoriteModel.fromJson(json);
      expect(fav.id, 'fav1');
      expect(fav.category, 'fiyat');
      expect(fav.priceAtFavorite, 5000);
      expect(fav.notes, 'Güzel fiyat');
      expect(fav.updatedAt, isNotNull);
    });

    test('fromJson defaults category to diğer', () {
      final json = {
        'id': 'fav2',
        'user_id': 'u1',
        'listing_id': 'l1',
        'price_at_favorite': 3000,
        'created_at': '2026-03-23T12:00:00Z',
      };

      final fav = FavoriteModel.fromJson(json);
      expect(fav.category, 'diğer');
    });

    test('toJson round-trip', () {
      final fav = FavoriteModel(
        id: 'fav1',
        userId: 'u1',
        listingId: 'l1',
        priceAtFavorite: 7000,
        createdAt: DateTime(2026, 3, 23),
      );

      final json = fav.toJson();
      expect(json['id'], 'fav1');
      expect(json['price_at_favorite'], 7000);
      expect(json['category'], 'diğer');
    });

    test('copyWith works correctly', () {
      final fav = FavoriteModel(
        id: 'fav1',
        userId: 'u1',
        listingId: 'l1',
        priceAtFavorite: 5000,
        createdAt: DateTime(2026, 3, 23),
      );

      final updated = fav.copyWith(category: 'konum', notes: 'yakın');
      expect(updated.category, 'konum');
      expect(updated.notes, 'yakın');
      expect(updated.id, 'fav1');
      expect(updated.priceAtFavorite, 5000);
    });
  });
}
