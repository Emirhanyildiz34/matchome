import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/glass_container.dart';
import '../providers/listing_provider.dart';
import '../../data/models/listing_model.dart';
import '../../../second_hand/presentation/providers/second_hand_provider.dart';
import '../../../second_hand/data/models/second_hand_item_model.dart';

class MyListingsScreen extends ConsumerStatefulWidget {
  const MyListingsScreen({super.key});

  @override
  ConsumerState<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends ConsumerState<MyListingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final myListingsAsync = ref.watch(myListingsProvider);
    final mySecondHandAsync = ref.watch(mySecondHandItemsProvider);

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
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab 1: Ev İlanlarım
                      myListingsAsync.when(
                        data: (listings) =>
                            _buildListingsContent(context, ref, listings),
                        loading: () => const Center(
                            child: CircularProgressIndicator(
                                color: Colors.orangeAccent)),
                        error: (e, _) => Center(
                            child: Text('Hata: $e',
                                style:
                                    const TextStyle(color: Colors.white))),
                      ),
                      // Tab 2: Elden Ele İlanlarım
                      mySecondHandAsync.when(
                        data: (items) =>
                            _buildSecondHandContent(context, ref, items),
                        loading: () => const Center(
                            child: CircularProgressIndicator(
                                color: Colors.orangeAccent)),
                        error: (e, _) => Center(
                            child: Text('Hata: $e',
                                style:
                                    const TextStyle(color: Colors.white))),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/add-listing'),
              backgroundColor: Colors.orangeAccent,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('İlan Ver',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : FloatingActionButton.extended(
              onPressed: () => context.push('/add-second-hand'),
              backgroundColor: Colors.purpleAccent,
              icon: const Icon(Icons.sell, color: Colors.white),
              label: const Text('Eşya Sat',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          const Expanded(
            child: Text(
              'İlanlarım',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.orangeAccent.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.orangeAccent, width: 1.5),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white54,
        labelStyle:
            const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        tabs: const [
          Tab(text: '🏠  Ev İlanlarım'),
          Tab(text: '🛍️  Elden Ele'),
        ],
      ),
    );
  }

  Widget _buildListingsContent(
      BuildContext context, WidgetRef ref, List<ListingModel> listings) {
    if (listings.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: GlassContainer(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.list_alt,
                    size: 64, color: Colors.orangeAccent),
                SizedBox(height: 16),
                Text(
                  'Henüz ilanınız yok',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'İlk ilanınızı oluşturmak için aşağıdaki butona tıklayın.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(myListingsProvider);
      },
      color: Colors.orangeAccent,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
        itemCount: listings.length,
        itemBuilder: (context, index) {
          final listing = listings[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildListingCard(context, ref, listing),
          );
        },
      ),
    );
  }

  // ──────────────────────────────────────────────
  // ELDEN ELE TAB
  // ──────────────────────────────────────────────

  Widget _buildSecondHandContent(
      BuildContext context, WidgetRef ref, List<SecondHandItemModel> items) {
    if (items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: GlassContainer(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sell_outlined, size: 64, color: Colors.purpleAccent),
                SizedBox(height: 16),
                Text(
                  'Henüz elden ele eşyanız yok',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Satmak istediğiniz eşyaları "Eşya Sat" butonuyla ekleyebilirsiniz.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(mySecondHandItemsProvider);
      },
      color: Colors.purpleAccent,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildSecondHandCard(context, ref, item),
          );
        },
      ),
    );
  }

  Widget _buildSecondHandCard(
      BuildContext context, WidgetRef ref, SecondHandItemModel item) {
    const categoryLabels = <String, String>{
      'kiyafet': '👗 Kıyafet',
      'aksesuar': '👜 Aksesuar',
      'teknoloji': '📱 Teknoloji',
      'mutfak': '🍳 Mutfak',
      'ders_kitabi': '📚 Ders Kitabı',
      'mobilya': '🪑 Mobilya',
      'spor': '⚽ Spor',
      'diger': '📦 Diğer',
    };
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.imageUrls.isNotEmpty)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              child: Image.network(item.imageUrls.first,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                        height: 120,
                        color: Colors.white10,
                        child: const Center(
                            child: Icon(Icons.image,
                                color: Colors.white24, size: 40)),
                      )),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        categoryLabels[item.category] ?? '📦 Diğer',
                        style: const TextStyle(
                            color: Colors.purpleAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: item.isActive
                            ? Colors.green.withValues(alpha: 0.15)
                            : Colors.red.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.isActive ? '🟢 Aktif' : '🔴 Pasif',
                        style: TextStyle(
                          color: item.isActive
                              ? Colors.greenAccent
                              : Colors.redAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${item.price} ${item.currency}',
                      style: const TextStyle(
                          color: Colors.orangeAccent,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(item.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                if (item.city != null && item.city!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on,
                            color: Colors.white38, size: 14),
                        const SizedBox(width: 4),
                        Text(item.city!,
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 13)),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                Column(
                  children: [
                    Row(
                      children: [
                        if (item.isActive)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  _showSecondHandDeactivate(context, ref, item),
                              icon: const Icon(Icons.visibility_off, size: 18),
                              label: const Text('Yayından Çıkar'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.orange,
                                side: const BorderSide(color: Colors.orange),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        if (!item.isActive)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  _showSecondHandActivate(context, ref, item),
                              icon: const Icon(Icons.visibility, size: 18),
                              label: const Text('Yayına Al'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.green,
                                side: const BorderSide(color: Colors.green),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              context.push('/edit-second-hand', extra: item);
                            },
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('Düzenle'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.orangeAccent,
                              side:
                                  const BorderSide(color: Colors.orangeAccent),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _showSecondHandDelete(context, ref, item),
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: const Text('Sil'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: const BorderSide(color: Colors.redAccent),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSecondHandDeactivate(
      BuildContext context, WidgetRef ref, SecondHandItemModel item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1640),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Yayından Çıkar',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('Bu ilanı yayından çıkarmak istiyor musunuz?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal',
                  style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(secondHandRepositoryProvider)
                    .deactivateItem(item.id!);
                ref.invalidate(mySecondHandItemsProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('İlan yayından çıkarıldı.'),
                        backgroundColor: Colors.orange),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Hata: $e'),
                        backgroundColor: Colors.redAccent),
                  );
                }
              }
            },
            child: const Text('Çıkar',
                style:
                    TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showSecondHandActivate(
      BuildContext context, WidgetRef ref, SecondHandItemModel item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1640),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Yayına Al',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('Bu ilanı yeniden yayına almak istiyor musunuz?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal',
                  style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(secondHandRepositoryProvider)
                    .reactivateItem(item.id!);
                ref.invalidate(mySecondHandItemsProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('İlan yayına alındı.'),
                        backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Hata: $e'),
                        backgroundColor: Colors.redAccent),
                  );
                }
              }
            },
            child: const Text('Yayına Al',
                style: TextStyle(
                    color: Colors.green, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showSecondHandDelete(
      BuildContext context, WidgetRef ref, SecondHandItemModel item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1640),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('İlanı Sil',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
            'Bu ilanı kalıcı olarak silmek istediğinizden emin misiniz?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal',
                  style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(secondHandRepositoryProvider)
                    .deleteItem(item.id!);
                ref.invalidate(mySecondHandItemsProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('İlan silindi.'),
                        backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Hata: $e'),
                        backgroundColor: Colors.redAccent),
                  );
                }
              }
            },
            child: const Text('Sil',
                style: TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildListingCard(
      BuildContext context, WidgetRef ref, ListingModel listing) {
    // 1 ay (30 gün) cinsinden kalan gün hesapla
    int daysRemaining = 0;
    if (listing.publishedAt != null && listing.isActive) {
      final publishedDate = DateTime.parse(listing.publishedAt.toString());
      final expireDate = publishedDate.add(const Duration(days: 30));
      daysRemaining = expireDate.difference(DateTime.now()).inDays;
      if (daysRemaining < 0) daysRemaining = 0;
    }

    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resim
          if (listing.imageUrls.isNotEmpty)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              child: Image.network(listing.imageUrls.first,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                        height: 120,
                        color: Colors.white10,
                        child: const Center(
                            child: Icon(Icons.image,
                                color: Colors.white24, size: 40)),
                      )),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tip + Durum + Fiyat
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: listing.listingType == 'room_offer'
                            ? Colors.green.withValues(alpha: 0.2)
                            : Colors.blue.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        listing.listingType == 'room_offer'
                            ? '🏠 Oda Veren'
                            : '🔍 Oda Arayan',
                        style: TextStyle(
                          color: listing.listingType == 'room_offer'
                              ? Colors.greenAccent
                              : Colors.lightBlueAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: listing.isActive
                            ? Colors.green.withValues(alpha: 0.15)
                            : Colors.red.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        listing.isActive ? '🟢 Aktif' : '🔴 Pasif',
                        style: TextStyle(
                          color: listing.isActive
                              ? Colors.greenAccent
                              : Colors.redAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${listing.price} ₺/ay',
                      style: const TextStyle(
                          color: Colors.orangeAccent,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),

                // Kalan gün göstergesi
                if (listing.isActive && daysRemaining > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: daysRemaining <= 7
                            ? Colors.orange.withValues(alpha: 0.2)
                            : Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '⏰ ${daysRemaining} gün kaldı (30 günlük dönem)',
                        style: TextStyle(
                          color: daysRemaining <= 7
                              ? Colors.orange
                              : Colors.lightBlueAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 10),
                Text(listing.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                if (listing.addressText != null &&
                    listing.addressText!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on,
                            color: Colors.white38, size: 14),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(listing.addressText!,
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),

                // Ek Özellikler
                if (listing.listingType == 'room_offer' &&
                    listing.extraFeatures.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Wrap(
                      spacing: 6,
                      children: listing.extraFeatures
                          .map(
                            (feature) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '✨ $feature',
                                style: const TextStyle(
                                  color: Colors.lightBlueAccent,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),

                const SizedBox(height: 16),

                // Butonlar
                Column(
                  children: [
                    // Yayın Durumu Butonları (Yayından Çıkar / Yeniden Yayına Al)
                    Row(
                      children: [
                        if (listing.isActive)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  _showUnpublishConfirmation(
                                      context, ref, listing),
                              icon: const Icon(Icons.visibility_off, size: 18),
                              label: const Text('Yayından Çıkar'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.orange,
                                side: const BorderSide(color: Colors.orange),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        if (!listing.isActive)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  _showRepublishConfirmation(
                                      context, ref, listing),
                              icon: const Icon(Icons.visibility, size: 18),
                              label: const Text('Yeniden Yayına Al'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.green,
                                side: const BorderSide(color: Colors.green),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Düzenle ve Sil butonları
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              context.push('/edit-listing', extra: listing);
                            },
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('Düzenle'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.orangeAccent,
                              side: const BorderSide(color: Colors.orangeAccent),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _showDeleteConfirmation(context, ref, listing),
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: const Text('Sil'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: const BorderSide(color: Colors.redAccent),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showUnpublishConfirmation(
      BuildContext context, WidgetRef ref, ListingModel listing) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1640),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('İlanı Yayından Çıkar',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: const Text(
            'Bu ilanı yayından çıkarmak istediğinizden emin misiniz? İlanı daha sonra yeniden yayına alabilirsiniz.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child:
                  const Text('İptal', style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                try {
                  await ref
                      .read(listingRepositoryProvider)
                      .unpublishListing(listing.id!);
                  ref.invalidate(myListingsProvider);
                  ref.invalidate(myListingProvider);
                  ref.invalidate(activeListingsProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('İlan yayından çıkartıldı.'),
                          backgroundColor: Colors.orange),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Hata: $e'),
                          backgroundColor: Colors.redAccent),
                    );
                  }
                }
              },
              child: const Text('Çıkar',
                  style: TextStyle(
                      color: Colors.orange, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showRepublishConfirmation(
      BuildContext context, WidgetRef ref, ListingModel listing) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1640),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('İlanı Yeniden Yayına Al',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: const Text(
            'Bu ilanı yeniden yayına almak istediğinizden emin misiniz? Yeni 30 günlük dönem başlayacaktır.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child:
                  const Text('İptal', style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                try {
                  await ref
                      .read(listingRepositoryProvider)
                      .republishListing(listing.id!);
                  ref.invalidate(myListingsProvider);
                  ref.invalidate(myListingProvider);
                  ref.invalidate(activeListingsProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('İlan yeniden yayına alındı.'),
                          backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Hata: $e'),
                          backgroundColor: Colors.redAccent),
                    );
                  }
                }
              },
              child: const Text('Yayına Al',
                  style: TextStyle(
                      color: Colors.green, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(
      BuildContext context, WidgetRef ref, ListingModel listing) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1640),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('İlanı Sil',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: const Text(
            'Bu ilanı silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child:
                  const Text('İptal', style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                try {
                  await ref
                      .read(listingRepositoryProvider)
                      .deleteListing(listing.id!);
                  ref.invalidate(myListingsProvider);
                  ref.invalidate(myListingProvider);
                  ref.invalidate(activeListingsProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('İlan silindi.'),
                          backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Hata: $e'),
                          backgroundColor: Colors.redAccent),
                    );
                  }
                }
              },
              child: const Text('Sil',
                  style: TextStyle(
                      color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
