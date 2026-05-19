import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/listing_model.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/utils/distance_utils.dart';
import '../../../../core/constants/university_data.dart';
import '../providers/listing_provider.dart';
import '../../../chat/data/chat_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ListingDetailScreen extends ConsumerStatefulWidget {
  final ListingModel listing;

  const ListingDetailScreen({super.key, required this.listing});

  @override
  ConsumerState<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends ConsumerState<ListingDetailScreen> {
  late final PageController _pageController;
  int _currentPage = 0;

  ListingModel get listing => widget.listing;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openFullscreen(int initialIndex) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) => _FullscreenGallery(
          imageUrls: listing.imageUrls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Arka plan
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0F0C29),
                  Color(0xFF302B63),
                  Color(0xFF24243E)
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // AppBar
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios,
                            color: Colors.white),
                        onPressed: () => context.pop(),
                      ),
                      const Expanded(
                        child: Text(
                          'İlan Detayı',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      // Favori butonu
                      GestureDetector(
                        onTap: () async {
                          final user = Supabase.instance.client.auth.currentUser;
                          if (user == null) return;

                          final favModel = await ref
                              .read(favoritesRepositoryProvider)
                              .isFavorited(user.id, listing.id ?? '');
                          final isFav = favModel != null;

                          if (isFav) {
                            await ref.read(favoritesRepositoryProvider)
                                .removeFromFavorites(favModel.id);
                          } else {
                            await ref.read(favoritesRepositoryProvider)
                                .addToFavorites(
                              userId: user.id,
                              listingId: listing.id ?? '',
                              priceAtFavorite: listing.price,
                            );
                          }
                          ref.invalidate(isFavoritedProvider);
                        },
                        child: ref
                            .watch(isFavoritedProvider(listing.id ?? ''))
                            .when(
                          data: (isFav) => Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            color: isFav ? Colors.redAccent : Colors.white38,
                            size: 26,
                          ),
                          loading: () => Icon(Icons.favorite_border,
                              color: Colors.white38, size: 26),
                          error: (_, __) => Icon(Icons.favorite_border,
                              color: Colors.white38, size: 26),
                        ),
                      ),
                    ],
                  ),
                ),

                // İçerik
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Görsel Galerisi (Kaydırılabilir)
                        if (listing.imageUrls.isNotEmpty)
                          SizedBox(
                            height: 280,
                            child: Stack(
                              children: [
                                PageView.builder(
                                  controller: _pageController,
                                  itemCount: listing.imageUrls.length,
                                  onPageChanged: (i) => setState(() => _currentPage = i),
                                  itemBuilder: (context, index) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      child: GestureDetector(
                                        onTap: () => _openFullscreen(index),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(20),
                                          child: Image.network(
                                            listing.imageUrls[index],
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Container(
                                              decoration: BoxDecoration(
                                                color: Colors.white10,
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: const Center(
                                                child: Icon(Icons.image,
                                                    color: Colors.white24, size: 64),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                // Fotoğraf sayacı
                                Positioned(
                                  bottom: 12,
                                  right: 20,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.zoom_out_map,
                                            color: Colors.white70, size: 13),
                                        const SizedBox(width: 5),
                                        Text(
                                          '${_currentPage + 1}/${listing.imageUrls.length}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Nokta göstergesi
                                if (listing.imageUrls.length > 1)
                                  Positioned(
                                    bottom: 12,
                                    left: 0,
                                    right: 0,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: List.generate(
                                        listing.imageUrls.length,
                                        (i) => AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          margin: const EdgeInsets.symmetric(horizontal: 3),
                                          width: i == _currentPage ? 16 : 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: i == _currentPage
                                                ? Colors.orangeAccent
                                                : Colors.white38,
                                            borderRadius: BorderRadius.circular(3),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          )
                        else
                          Container(
                            height: 220,
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Center(
                              child: Icon(Icons.image,
                                  color: Colors.white24, size: 64),
                            ),
                          ),
                        const SizedBox(height: 20),

                        // Tip etiketi
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: listing.listingType == 'room_offer'
                                    ? Colors.green.withValues(alpha: 0.2)
                                    : Colors.blue.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                listing.listingType == 'room_offer'
                                    ? '🏠 Oda Veren'
                                    : '🔍 Oda Arayan',
                                style: TextStyle(
                                  color: listing.listingType == 'room_offer'
                                      ? Colors.greenAccent
                                      : Colors.lightBlueAccent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (!listing.isActive) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text('Pasif',
                                    style: TextStyle(
                                        color: Colors.redAccent,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Başlık
                        Text(
                          listing.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Fiyat kartı
                        GlassContainer(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              const Icon(Icons.payments,
                                  color: Colors.orangeAccent, size: 28),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${formatPrice(listing.price)} ${currencySymbol(listing.currency)}/ay',
                                    style: const TextStyle(
                                        color: Colors.orangeAccent,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    listing.utilitiesIncluded
                                        ? 'Faturalar dahil'
                                        : 'Faturalar hariç',
                                    style: const TextStyle(
                                        color: Colors.white54, fontSize: 13),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Detay bilgiler
                        GlassContainer(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              if (listing.roomCount != null)
                                _buildInfoRow(
                                    Icons.meeting_room, 'Oda', listing.roomCount!),
                              if (listing.addressText != null &&
                                  listing.addressText!.isNotEmpty)
                                _buildInfoRow(Icons.location_on, 'Konum',
                                    listing.addressText!),
                              if (listing.nearbyUniversity != null)
                                _buildInfoRow(Icons.school, 'Yakın Üniversite',
                                    listing.nearbyUniversity!),
                              _buildCampusDistanceRow(profileAsync),
                              if (listing.preferredGender != null)
                                _buildInfoRow(
                                  listing.preferredGender == 'male'
                                      ? Icons.male
                                      : Icons.female,
                                  'Kiracı Tercihi',
                                  listing.preferredGender == 'male'
                                      ? 'Sadece Erkek'
                                      : 'Sadece Kadın',
                                ),
                              if (listing.createdAt != null)
                                _buildInfoRow(
                                    Icons.calendar_today,
                                    'Yayın Tarihi',
                                    _formatDate(listing.createdAt!)),
                            ],
                          ),
                        ),

                        // Özellikler
                        if (listing.houseFeatures.isNotEmpty || listing.extraFeatures.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Özellikler',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ...listing.houseFeatures.map((f) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.orangeAccent
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: Colors.orangeAccent
                                            .withValues(alpha: 0.3)),
                                  ),
                                  child: Text(f,
                                      style: const TextStyle(
                                          color: Colors.orangeAccent,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500)),
                                );
                              }),
                              ...listing.extraFeatures.map((f) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.orangeAccent
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: Colors.orangeAccent
                                            .withValues(alpha: 0.3)),
                                  ),
                                  child: Text(f,
                                      style: const TextStyle(
                                          color: Colors.orangeAccent,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500)),
                                );
                              }),
                            ],
                          ),
                        ],

                        // Açıklama
                        if (listing.description != null &&
                            listing.description!.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          const Text(
                            'Açıklama',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          GlassContainer(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              listing.description!,
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 15,
                                  height: 1.5),
                            ),
                          ),
                        ],

                        const SizedBox(height: 28),

                        // İletişim Seçenekleri
                        const Text(
                          'İletişime Geç',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),

                        // Uygulama içi mesaj
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final currentUser =
                                  Supabase.instance.client.auth.currentUser;
                              if (currentUser == null) return;

                              if (listing.hostId == currentUser.id) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Kendi ilanınıza mesaj gönderemezsiniz'),
                                    backgroundColor: Colors.orangeAccent,
                                  ),
                                );
                                return;
                              }

                              // Cinsiyet kısıtı kontrolü
                              if (listing.preferredGender != null) {
                                final profile = await Supabase.instance.client
                                    .from('profiles')
                                    .select('gender')
                                    .eq('id', currentUser.id)
                                    .maybeSingle();
                                final userGender = profile?['gender'] as String?;
                                if (userGender != null &&
                                    userGender != listing.preferredGender) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Bu ilan yalnızca ${listing.preferredGender == 'male' ? 'erkek' : 'kadın'} kiracılara açıktır'),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }
                                  return;
                                }
                              }

                              if (listing.id == null) return;

                              try {
                                final chatRepo = ChatRepository(
                                    Supabase.instance.client);
                                final conversationId =
                                    await chatRepo.findOrCreateConversation(
                                  hostId: listing.hostId,
                                  listingType: 'listing',
                                  listingId: listing.id,
                                  listingImageUrl: listing.imageUrls.isNotEmpty
                                      ? listing.imageUrls[0]
                                      : null,
                                  listingTitle: listing.title,
                                );
                                if (context.mounted) {
                                  context.push(
                                    '/chat/$conversationId',
                                    extra: {
                                      'otherUserName': 'Ev Sahibi',
                                      'listingTitle': listing.title,
                                    },
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Sohbet başlatılamadı: $e'),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.chat_bubble_outline,
                                color: Colors.white),
                            label: const Text(
                                'Uygulama Üzerinden Mesaj Gönder',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orangeAccent,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),

                        // WhatsApp ve Arama — sadece show_phone true ise
                        if (listing.showPhone && listing.hostPhone != null && listing.hostPhone!.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    final phone = listing.hostPhone!
                                        .replaceAll(RegExp(r'[^0-9+]'), '');
                                    final uri = Uri.parse(
                                        'https://wa.me/$phone');
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(uri,
                                          mode: LaunchMode.externalApplication);
                                    }
                                  },
                                  icon: const Icon(Icons.message,
                                      color: Colors.white, size: 18),
                                  label: const Text('WhatsApp',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF25D366),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    final phone = listing.hostPhone!
                                        .replaceAll(RegExp(r'[^0-9+]'), '');
                                    final uri = Uri.parse('tel:$phone');
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(uri);
                                    }
                                  },
                                  icon: const Icon(Icons.call,
                                      color: Colors.white, size: 18),
                                  label: const Text('Ara',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Colors.blueAccent.shade700,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.orangeAccent, size: 20),
          const SizedBox(width: 12),
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 14)),
          const Spacer(),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.end,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildCampusDistanceRow(
      AsyncValue<Map<String, dynamic>?> profileAsync) {
    if (listing.latitude == null || listing.longitude == null) {
      return const SizedBox.shrink();
    }

    return profileAsync.when(
      data: (profile) {
        final university = profile?['university'] as String?;
        final campus = profile?['campus'] as String?;
        if (university == null || university.isEmpty) {
          return const SizedBox.shrink();
        }

        final campusData = UniversityData.getCampusData(university, campus);
        if (campusData == null) {
          return const SizedBox.shrink();
        }

        final km = DistanceUtils.haversineKm(
          campusData.latitude,
          campusData.longitude,
          listing.latitude!,
          listing.longitude!,
        );

        return _buildInfoRow(
          Icons.route,
          'Kampüse Mesafe',
          DistanceUtils.formatDistance(km),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
      'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

// ──────────────────────────────────────────────────────────
// Tam Ekran Galeri
// ──────────────────────────────────────────────────────────
class _FullscreenGallery extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const _FullscreenGallery({
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  State<_FullscreenGallery> createState() => _FullscreenGalleryState();
}

class _FullscreenGalleryState extends State<_FullscreenGallery> {
  late final PageController _ctrl;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _ctrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Fotoğraflar
          PageView.builder(
            controller: _ctrl,
            itemCount: widget.imageUrls.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: Center(
                  child: Image.network(
                    widget.imageUrls[index],
                    fit: BoxFit.contain,
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Colors.orangeAccent,
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.broken_image,
                          color: Colors.white38, size: 64),
                    ),
                  ),
                ),
              );
            },
          ),

          // Kapatma butonu
          Positioned(
            top: 12,
            right: 12,
            child: SafeArea(
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ),
            ),
          ),

          // Sayaç
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_current + 1} / ${widget.imageUrls.length}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),

          // Sol ok
          if (_current > 0)
            Positioned(
              left: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () => _ctrl.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.chevron_left,
                        color: Colors.white, size: 28),
                  ),
                ),
              ),
            ),

          // Sağ ok
          if (_current < widget.imageUrls.length - 1)
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () => _ctrl.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.chevron_right,
                        color: Colors.white, size: 28),
                  ),
                ),
              ),
            ),

          // Nokta göstergesi
          if (widget.imageUrls.length > 1)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.imageUrls.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _current ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _current
                          ? Colors.orangeAccent
                          : Colors.white38,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
