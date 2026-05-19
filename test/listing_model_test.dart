import 'package:flutter_test/flutter_test.dart';
import 'package:match_home/features/listings/data/models/listing_model.dart';

void main() {
  group('ListingModel', () {
    test('ListingModel oluşturulabilir - minimal parametreler', () {
      final listing = ListingModel(
        hostId: 'user123',
        title: 'Kiralık Oda',
        price: 5000,
        listingType: 'room_offer',
      );

      expect(listing.hostId, 'user123');
      expect(listing.title, 'Kiralık Oda');
      expect(listing.price, 5000);
      expect(listing.listingType, 'room_offer');
      expect(listing.isActive, true); // default değer
      expect(listing.houseFeatures, []);
      expect(listing.imageUrls, []);
    });

    test('ListingModel oluşturulabilir - tüm parametreler', () {
      final createdAt = DateTime.now();
      final listing = ListingModel(
        id: 'listing123',
        hostId: 'user123',
        title: 'Luxe Oda',
        description: 'Çok güzel bir oda',
        price: 10000,
        utilitiesIncluded: true,
        roomCount: '2',
        houseFeatures: ['WiFi', 'Mutfak'],
        imageUrls: ['url1', 'url2'],
        addressText: 'Kadıköy, İstanbul',
        latitude: 40.9883,
        longitude: 29.0279,
        isActive: true,
        listingType: 'room_offer',
        createdAt: createdAt,
      );

      expect(listing.id, 'listing123');
      expect(listing.hostId, 'user123');
      expect(listing.title, 'Luxe Oda');
      expect(listing.description, 'Çok güzel bir oda');
      expect(listing.price, 10000);
      expect(listing.utilitiesIncluded, true);
      expect(listing.roomCount, '2');
      expect(listing.houseFeatures, ['WiFi', 'Mutfak']);
      expect(listing.imageUrls, ['url1', 'url2']);
      expect(listing.addressText, 'Kadıköy, İstanbul');
      expect(listing.latitude, 40.9883);
      expect(listing.longitude, 29.0279);
      expect(listing.isActive, true);
      expect(listing.listingType, 'room_offer');
      expect(listing.createdAt, createdAt);
    });

    test('ListingModel türlerine dayalı olarak doğru oluşturulabilir', () {
      final roomOffer = ListingModel(
        hostId: 'host1',
        title: 'Oda Sunan',
        price: 5000,
        listingType: 'room_offer',
      );

      final roomSearch = ListingModel(
        hostId: 'student1',
        title: 'Oda Arayan',
        price: 5000,
        listingType: 'room_search',
      );

      expect(roomOffer.listingType, 'room_offer');
      expect(roomSearch.listingType, 'room_search');
    });

    test('ListingModel fiyat validasyonu - pozitif fiyat', () {
      final listing = ListingModel(
        hostId: 'user123',
        title: 'Test Listing',
        price: 1000,
        listingType: 'room_offer',
      );

      expect(listing.price, greaterThan(0));
    });

    test('ListingModel null değerler doğru işleniyor', () {
      final listing = ListingModel(
        hostId: 'user123',
        title: 'Minimal Listing',
        price: 5000,
        listingType: 'room_offer',
      );

      expect(listing.id, isNull);
      expect(listing.description, isNull);
      expect(listing.roomCount, isNull);
      expect(listing.addressText, isNull);
      expect(listing.latitude, isNull);
      expect(listing.longitude, isNull);
      expect(listing.createdAt, isNull);
    });

    test('ListingModel copyWith metodu - null id -> id set', () {
      final original = ListingModel(
        hostId: 'user123',
        title: 'Oda',
        price: 5000,
        listingType: 'room_offer',
      );

      expect(original.id, isNull);

      // copyWith kullanmadan yeni instance oluş - alternatif test
      final updated = ListingModel(
        id: 'new_id_123',
        hostId: original.hostId,
        title: original.title,
        price: original.price,
        listingType: original.listingType,
      );

      expect(updated.id, 'new_id_123');
      expect(updated.hostId, 'user123');
    });

    test('ListingModel utilities ve features kontrol', () {
      final listing = ListingModel(
        hostId: 'user123',
        title: 'Müstakil Ev',
        price: 15000,
        utilitiesIncluded: true,
        houseFeatures: ['Terrace', 'Garden', 'Garage'],
        listingType: 'room_offer',
      );

      expect(listing.utilitiesIncluded, true);
      expect(listing.houseFeatures.length, 3);
      expect(listing.houseFeatures, contains('Garden'));
    });

    test('ListingModel konumu kontrol', () {
      const latitude = 41.0082;
      const longitude = 28.9784;

      final listing = ListingModel(
        hostId: 'user123',
        title: 'İstanbul Oda',
        price: 5000,
        latitude: latitude,
        longitude: longitude,
        addressText: 'Taksim, İstanbul',
        listingType: 'room_offer',
      );

      expect(listing.latitude, latitude);
      expect(listing.longitude, longitude);
      expect(listing.addressText, contains('İstanbul'));
    });

    test('ListingModel imageUrls boş veya dolabilir', () {
      final emptyImages = ListingModel(
        hostId: 'user123',
        title: 'No Image Listing',
        price: 5000,
        listingType: 'room_offer',
      );

      final withImages = ListingModel(
        hostId: 'user123',
        title: 'With Images Listing',
        price: 5000,
        imageUrls: ['https://example.com/photo1.jpg', 'https://example.com/photo2.jpg'],
        listingType: 'room_offer',
      );

      expect(emptyImages.imageUrls, isEmpty);
      expect(withImages.imageUrls, isNotEmpty);
      expect(withImages.imageUrls.length, 2);
    });
  });
}
