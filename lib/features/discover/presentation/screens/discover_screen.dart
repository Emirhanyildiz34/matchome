import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../listings/presentation/providers/listing_provider.dart';
import '../../../listings/data/models/listing_model.dart';
import '../../../second_hand/presentation/screens/second_hand_list_screen.dart';
import '../../../campus/presentation/screens/campus_screen.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/constants/turkish_cities.dart';
import '../../../../core/constants/university_data.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/utils/distance_utils.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen>
    with TickerProviderStateMixin {
  final PageController _sliderController = PageController();
  Timer? _sliderTimer;
  int _currentSliderPage = 0;
  int _lastFeaturedCount = 0;

  late TabController _tabController;

  // Kampüs / öğrenci durumu
  bool _isStudent = false;
  String? _userUniversity;
  String? _userCampus;
  CampusData? _userCampusData;

  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  bool _speechAvailable = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initSpeech();
  }

  @override
  void dispose() {
    _sliderTimer?.cancel();
    _sliderController.dispose();
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    final available = await _speech.initialize();
    if (mounted) setState(() => _speechAvailable = available);
  }

  /// Profile verisine göre öğrenci durumunu ve TabController'u günceller.
  void _updateStudentState(Map<String, dynamic>? profile) {
    final university = profile?['university'] as String?;
    final campus = profile?['campus'] as String?;

    final isStudent = university != null && university.isNotEmpty;

    // Değişiklik yoksa gereksiz rebuild yapmaktan kaçın
    if (isStudent == _isStudent &&
        university == _userUniversity &&
        campus == _userCampus) {
      return;
    }

    CampusData? campusData;
    if (isStudent) {
      campusData = UniversityData.getCampusData(university, campus);
    }

    final newTabCount = isStudent ? 3 : 2;
    final needsRebuild = _tabController.length != newTabCount;

    if (needsRebuild) {
      final oldController = _tabController;
      _tabController = TabController(length: newTabCount, vsync: this);
      oldController.dispose();
    }

    if (mounted) {
      setState(() {
        _isStudent = isStudent;
        _userUniversity = isStudent ? university : null;
        _userCampus = isStudent ? campus : null;
        _userCampusData = campusData;
      });
    }
  }

  void _startAutoAdvance(int count) {
    _sliderTimer?.cancel();
    if (count < 2) return;
    _sliderTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_sliderController.hasClients) return;
      _currentSliderPage = (_currentSliderPage + 1) % count;
      _sliderController.animateToPage(
        _currentSliderPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> _toggleVoice() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }

    // Cihaz speech desteği yoksa yeniden dene, sonra hata göster
    if (!_speechAvailable) {
      final available = await _speech.initialize();
      if (mounted) setState(() => _speechAvailable = available);
      if (!available) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bu cihazda sesli arama kullanılamıyor.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }
    }

    setState(() => _isListening = true);
    await _speech.listen(
      onResult: (result) {
        _searchController.text = result.recognizedWords;
        ref.read(searchQueryProvider.notifier).state = result.recognizedWords;
      },
      localeId: 'tr_TR',
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final listingsAsync = ref.watch(activeListingsProvider);
    final filter = ref.watch(listingFilterProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    // Profil güncellenince (örn. üniversite eklendi/değiştirildi) sekmeleri güncelle
    ref.listen<AsyncValue<Map<String, dynamic>?>>(profileProvider,
        (prev, next) {
      next.whenData((profile) => _updateStudentState(profile));
    });

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: profileAsync.when(
              data: (profile) {
                final name = profile?['full_name'] ?? 'Kullanıcı';
                final avatarUrl = profile?['avatar_url'] as String?;
                return Column(
                  children: [
                    _buildHeader(name, avatarUrl: avatarUrl),
                    _buildTabBar(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Tab 1: İlanlar
                          Column(
                            children: [
                              _buildSearchBar(),
                              _buildFilterChips(filter),
                              Expanded(
                                child: listingsAsync.when(
                                  data: (listings) {
                                    final filtered = searchQuery.isEmpty
                                        ? listings
                                        : listings.where((l) {
                                            final q = searchQuery.toLowerCase();
                                            return l.title.toLowerCase().contains(q) ||
                                                (l.description?.toLowerCase().contains(q) ?? false) ||
                                                (l.addressText?.toLowerCase().contains(q) ?? false);
                                          }).toList();
                                    return _buildFeed(filtered);
                                  },
                                  loading: () => const Center(
                                      child: CircularProgressIndicator(color: Colors.orangeAccent)),
                                  error: (e, _) => Center(
                                      child: Text('Hata: $e',
                                          style: const TextStyle(color: Colors.white))),
                                ),
                              ),
                            ],
                          ),
                          // Tab 2: 2. El Eşyalar
                          const SecondHandListScreen(),
                          // Tab 3: Kampüs (yalnızca öğrenciler için)
                          if (_isStudent)
                            CampusScreen(
                              university: _userUniversity!,
                              campus: _userCampus,
                              campusData: _userCampusData,
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(
                  child: CircularProgressIndicator(color: Colors.orangeAccent)),
              error: (e, _) => Center(
                  child: Text('Hata: $e', style: const TextStyle(color: Colors.white))),
            ),
          ),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, _) {
          final index = _tabController.index;
          // Kampüs sekmesinde FAB gösterme
          if (_isStudent && index == 2) {
            return const SizedBox.shrink();
          }
          final isSecondHand = index == 1;
          return FloatingActionButton.extended(
            onPressed: isSecondHand
                ? () => context.push('/add-second-hand')
                : () => context.push('/add-listing'),
            backgroundColor: Colors.orangeAccent,
            icon: const Icon(Icons.add, color: Colors.white),
            label: Text(
              isSecondHand ? 'Eşya Sat' : 'İlan Ver',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.orangeAccent,
          borderRadius: BorderRadius.circular(30),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white54,
        labelStyle: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.bold),
        unselectedLabelStyle:
            const TextStyle(fontSize: 13, fontWeight: FontWeight.normal),
        tabs: [
          const Tab(text: '🏠  İlanlar'),
          const Tab(text: '🛍️  Elden Ele'),
          if (_isStudent) const Tab(text: '🎓  Kampüs'),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          children: [
            const Icon(Icons.search, color: Colors.white38, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'İlan ara...',
                  hintStyle: TextStyle(color: Colors.white38),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
                onChanged: (v) => ref.read(searchQueryProvider.notifier).state = v,
              ),
            ),
            if (_searchController.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                  ref.read(searchQueryProvider.notifier).state = '';
                },
                child: const Icon(Icons.close, color: Colors.white38, size: 18),
              ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: _toggleVoice,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _isListening
                      ? Colors.orangeAccent.withValues(alpha: 0.3)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _isListening ? Icons.mic : Icons.mic_none,
                  color: _isListening ? Colors.orangeAccent : Colors.white54,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String name, {String? avatarUrl}) {
    Widget avatar = avatarUrl != null
        ? CircleAvatar(
            backgroundColor: Colors.orangeAccent,
            backgroundImage: NetworkImage(avatarUrl),
          )
        : CircleAvatar(
            backgroundColor: Colors.orangeAccent,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
          );

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Merhaba, $name 👋',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                ),
                const Text(
                  'İlanları keşfet, filtrele ve başvur.',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => context.push('/conversations'),
            tooltip: 'Mesajlarım',
            icon: const Icon(Icons.chat_bubble_outline,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'logout') {
                await ref.read(authRepositoryProvider).signOut();
                if (context.mounted) {
                  context.go('/login');
                }
              } else if (value == 'profile') {
                context.push('/profile');
              } else if (value == 'my_listings') {
                context.push('/my-listings');
              } else if (value == 'favorites') {
                context.push('/favorites');
              }
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: const Color(0xFF302B63),
            offset: const Offset(0, 50),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    const Icon(Icons.person_outline,
                        color: Colors.white70, size: 20),
                    const SizedBox(width: 12),
                    Text(name, style: const TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'my_listings',
                child: Row(
                  children: [
                    Icon(Icons.list_alt, color: Colors.white70, size: 20),
                    SizedBox(width: 12),
                    Text('İlanlarım', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'favorites',
                child: Row(
                  children: [
                    Icon(Icons.favorite, color: Colors.redAccent, size: 20),
                    SizedBox(width: 12),
                    Text('Favorilerim', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.redAccent, size: 20),
                    SizedBox(width: 12),
                    Text('Çıkış Yap',
                        style: TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
            child: avatar,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(ListingFilter filter) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          // Kaydırılabilir chip'ler
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTypeChip(
                    label: 'Tümü',
                    isSelected: filter.listingType == null,
                    onTap: () {
                      ref.read(listingFilterProvider.notifier).state =
                          filter.copyWith(listingType: () => null);
                    },
                  ),
                  const SizedBox(width: 6),
                  _buildTypeChip(
                    label: '🏠 Oda Veren',
                    isSelected: filter.listingType == 'room_offer',
                    onTap: () {
                      ref.read(listingFilterProvider.notifier).state =
                          filter.copyWith(listingType: () => 'room_offer');
                    },
                  ),
                  const SizedBox(width: 6),
                  _buildTypeChip(
                    label: '🔍 Oda Arayan',
                    isSelected: filter.listingType == 'room_search',
                    onTap: () {
                      ref.read(listingFilterProvider.notifier).state =
                          filter.copyWith(listingType: () => 'room_search');
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Filtre butonu
          InkWell(
            onTap: () => _showFilterSheet(filter),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: filter.hasActiveFilters
                    ? Colors.orangeAccent.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: filter.hasActiveFilters
                      ? Colors.orangeAccent
                      : Colors.white24,
                ),
              ),
              child: Icon(Icons.tune,
                  size: 20,
                  color: filter.hasActiveFilters
                      ? Colors.orangeAccent
                      : Colors.white70),
            ),
          ),
          const SizedBox(width: 6),
          // Sıralama butonu
          InkWell(
            onTap: () => _showSortSheet(filter),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: filter.sortOrder != null
                    ? Colors.purpleAccent.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: filter.sortOrder != null
                      ? Colors.purpleAccent
                      : Colors.white24,
                ),
              ),
              child: Icon(Icons.sort,
                  size: 20,
                  color: filter.sortOrder != null
                      ? Colors.purpleAccent
                      : Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.orangeAccent
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isSelected ? Colors.orangeAccent : Colors.white.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildFeed(List<ListingModel> listings) {
    final topFeatured = ([...listings]
          ..sort((a, b) => b.viewCount.compareTo(a.viewCount)))
        .take(10)
        .toList();

    if (topFeatured.length != _lastFeaturedCount) {
      _lastFeaturedCount = topFeatured.length;
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => _startAutoAdvance(topFeatured.length));
    }

    if (listings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: GlassContainer(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.search_off, size: 64, color: Colors.orangeAccent),
                const SizedBox(height: 16),
                const Text('Henüz ilan bulunamadı',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text(
                  'Filtreleri değiştirmeyi dene veya ilk ilanı sen oluştur!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () {
                    ref.read(listingFilterProvider.notifier).state =
                        const ListingFilter();
                  },
                  child: const Text('Filtreleri Temizle',
                      style: TextStyle(color: Colors.orangeAccent)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final showSlider = topFeatured.length >= 2;
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(activeListingsProvider),
      color: Colors.orangeAccent,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: listings.length + (showSlider ? 1 : 0),
        itemBuilder: (context, index) {
          if (showSlider && index == 0) {
            return _buildFeaturedSlider(topFeatured);
          }
          final l = listings[showSlider ? index - 1 : index];
          return _buildListingCard(l);
        },
      ),
    );
  }

  Widget _buildFeaturedSlider(List<ListingModel> featured) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              const Icon(Icons.star, color: Colors.orangeAccent, size: 18),
              const SizedBox(width: 6),
              const Text(
                'Öne Çıkan İlanlar',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                '${_currentSliderPage + 1}/${featured.length}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 190,
          child: PageView.builder(
            controller: _sliderController,
            itemCount: featured.length,
            onPageChanged: (i) => setState(() => _currentSliderPage = i),
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _buildFeaturedCard(featured[i]),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(featured.length, (i) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _currentSliderPage == i ? 16 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _currentSliderPage == i
                    ? Colors.orangeAccent
                    : Colors.white24,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFeaturedCard(ListingModel l) {
    return InkWell(
      onTap: () => context.push('/listing-detail', extra: l),
      borderRadius: BorderRadius.circular(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            l.imageUrls.isNotEmpty
                ? Image.network(l.imageUrls.first,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFF302B63),
                        child:
                            const Icon(Icons.image, color: Colors.white24, size: 40)))
                : Container(
                    color: const Color(0xFF302B63),
                    child: const Icon(Icons.home, color: Colors.white24, size: 40)),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.75)
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              left: 14,
              right: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${formatPrice(l.price)} ${currencySymbol(l.currency)}',
                        style: const TextStyle(
                            color: Colors.orangeAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                      ),
                      const Spacer(),
                      if (l.addressText != null && l.addressText!.isNotEmpty) ...[
                        const Icon(Icons.location_on,
                            color: Colors.white54, size: 12),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(l.addressText!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 11)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text('Öne Çıkan',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListingCard(ListingModel l) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => context.push('/listing-detail', extra: l),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.horizontal(left: Radius.circular(16)),
                child: l.imageUrls.isNotEmpty
                    ? Image.network(l.imageUrls.first,
                        height: 100,
                        width: 110,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                            height: 100,
                            width: 110,
                            color: Colors.white10,
                            child: const Icon(Icons.image,
                                color: Colors.white24, size: 28)))
                    : Container(
                        height: 100,
                        width: 110,
                        color: Colors.white10,
                        child: const Icon(Icons.home,
                            color: Colors.white24, size: 28)),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${formatPrice(l.price)} ${currencySymbol(l.currency)}',
                            style: const TextStyle(
                                color: Colors.orangeAccent,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () async {
                              try {
                                final user = Supabase
                                    .instance.client.auth.currentUser;
                                if (user == null) return;
                                final favModel = await ref
                                    .read(favoritesRepositoryProvider)
                                    .isFavorited(user.id, l.id ?? '');
                                final isFav = favModel != null;
                                if (isFav) {
                                  await ref
                                      .read(favoritesRepositoryProvider)
                                      .removeFromFavorites(favModel.id);
                                } else {
                                  await ref
                                      .read(favoritesRepositoryProvider)
                                      .addToFavorites(
                                        userId: user.id,
                                        listingId: l.id ?? '',
                                        priceAtFavorite: l.price,
                                      );
                                }
                                ref.invalidate(isFavoritedProvider);
                              } catch (e) {
                                debugPrint('Favori hatası: $e');
                              }
                            },
                            child: ref
                                .watch(isFavoritedProvider(l.id ?? ''))
                                .when(
                                  data: (isFav) => Icon(
                                      isFav
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: isFav
                                          ? Colors.redAccent
                                          : Colors.white38,
                                      size: 22),
                                  loading: () => const Icon(
                                      Icons.favorite_border,
                                      color: Colors.white38,
                                      size: 22),
                                  error: (_, __) => const Icon(
                                      Icons.favorite_border,
                                      color: Colors.white38,
                                      size: 22),
                                ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: l.listingType == 'room_offer'
                                  ? Colors.green.withValues(alpha: 0.15)
                                  : Colors.blue.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              l.listingType == 'room_offer'
                                  ? 'Oda Veren'
                                  : 'Oda Arayan',
                              style: TextStyle(
                                color: l.listingType == 'room_offer'
                                    ? Colors.greenAccent
                                    : Colors.lightBlueAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(l.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 3),
                      if (l.addressText != null && l.addressText!.isNotEmpty)
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                color: Colors.white38, size: 12),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(l.addressText!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.white54, fontSize: 12)),
                            ),
                          ],
                        ),
                      // Kampüse mesafe rozeti (yalnızca öğrenciler için)
                      if (_isStudent &&
                          _userCampusData != null &&
                          l.latitude != null &&
                          l.longitude != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.school,
                                  color: Colors.orangeAccent, size: 12),
                              const SizedBox(width: 3),
                              Text(
                                'Kampüse ${DistanceUtils.formatDistance(DistanceUtils.haversineKm(_userCampusData!.latitude, _userCampusData!.longitude, l.latitude!, l.longitude!))}',
                                style: const TextStyle(
                                    color: Colors.orangeAccent, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            if (l.roomCount != null) ...[
                              const Icon(Icons.meeting_room,
                                  color: Colors.white38, size: 12),
                              const SizedBox(width: 3),
                              Text(l.roomCount!,
                                  style: const TextStyle(
                                      color: Colors.white54, fontSize: 12)),
                              const SizedBox(width: 10),
                            ],
                            if (l.houseFeatures.isNotEmpty ||
                                l.extraFeatures.isNotEmpty) ...[
                              const Icon(Icons.check_circle_outline,
                                  color: Colors.white38, size: 12),
                              const SizedBox(width: 3),
                              Text(
                                  '${l.houseFeatures.length + l.extraFeatures.length} özellik',
                                  style: const TextStyle(
                                      color: Colors.white54, fontSize: 12)),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 10),
                child: Icon(Icons.chevron_right, color: Colors.white24, size: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _showCitySearchDialog() async {
    final controller = TextEditingController();
    String query = '';
    return showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final filtered = query.isEmpty
              ? TurkishCities.cities
              : TurkishCities.cities
                  .where((c) => c.toLowerCase().contains(query.toLowerCase()))
                  .toList();
          return AlertDialog(
            backgroundColor: const Color(0xFF1A1640),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Şehir Seç',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: double.maxFinite,
              height: 360,
              child: Column(
                children: [
                  TextField(
                    controller: controller,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Şehir ara...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      prefixIcon:
                          const Icon(Icons.search, color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.08),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    onChanged: (v) => setS(() => query = v),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (_, i) => ListTile(
                        dense: true,
                        title: Text(filtered[i],
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14)),
                        onTap: () => Navigator.of(ctx).pop(filtered[i]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('İptal',
                    style: TextStyle(color: Colors.white70)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showSortSheet(ListingFilter filter) {
    final sortOptions = [
      _SortOption('newest', '⏰ En Yeni İlanlar'),
      _SortOption('price_asc', '📈 Fiyata Göre Artan'),
      _SortOption('price_desc', '📉 Fiyata Göre Azalan'),
      _SortOption('most_visited', '🔥 En Sık Ziyaret Edilenler'),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1640),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bsCtx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Sırala',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  if (filter.sortOrder != null)
                    TextButton(
                      onPressed: () {
                        ref.read(listingFilterProvider.notifier).state =
                            filter.copyWith(sortOrder: () => null);
                        Navigator.pop(bsCtx);
                      },
                      child: const Text('Temizle',
                          style: TextStyle(color: Colors.purpleAccent)),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              ...sortOptions.map((option) {
                final isSelected = filter.sortOrder == option.value;
                return InkWell(
                  onTap: () {
                    ref.read(listingFilterProvider.notifier).state =
                        filter.copyWith(sortOrder: () => option.value);
                    Navigator.pop(bsCtx);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.purpleAccent.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? Colors.purpleAccent
                            : Colors.white24,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            option.label,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.purpleAccent
                                  : Colors.white,
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle,
                              color: Colors.purpleAccent, size: 20),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showFilterSheet(ListingFilter filter) {
    final minPriceCtrl =
        TextEditingController(text: filter.minPrice?.toString() ?? '');
    final maxPriceCtrl =
        TextEditingController(text: filter.maxPrice?.toString() ?? '');
    String? selectedCity = filter.city;
    String? selectedDistrict = filter.district;
    String? selectedRoom = filter.roomCount;
    List<String> selectedFeatures = List<String>.from(filter.features);

    const allFeatures = [
      'Eşyalı', 'WiFi', 'Asansör', 'Merkezi Isıtma', 'Klima',
      'Balkon', 'Çamaşır Makinesi', 'Pet Arkadaşı',
      'Ütü', 'Tost Makinesi', 'Saç Kurutma Makinesi', 'Çay Makinesi',
      'Kahve Makinesi', 'Bulaşık Makinesi', 'Çamaşır Kurutma Makinesi',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1640),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (bsCtx) {
        return StatefulBuilder(
          builder: (bsCtx, setSheetState) {
            final districts = TurkishCities.districts[selectedCity] ?? [];
            return Padding(
              padding: EdgeInsets.fromLTRB(
                  24, 24, 24, MediaQuery.of(bsCtx).viewInsets.bottom + 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Filtrele',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                        TextButton(
                          onPressed: () {
                            ref.read(listingFilterProvider.notifier).state =
                                const ListingFilter();
                            Navigator.pop(bsCtx);
                          },
                          child: const Text('Temizle',
                              style: TextStyle(color: Colors.orangeAccent)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text('Fiyat Aralığı (₺)',
                        style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildFilterTextField(
                              minPriceCtrl, 'Min', TextInputType.number),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('-',
                              style: TextStyle(
                                  color: Colors.white54, fontSize: 20)),
                        ),
                        Expanded(
                          child: _buildFilterTextField(
                              maxPriceCtrl, 'Max', TextInputType.number),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text('Oda Sayısı',
                        style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children:
                          ['1+0', '1+1', '2+1', '3+1', '4+1'].map((room) {
                        final isSelected = selectedRoom == room;
                        return InkWell(
                          onTap: () {
                            setSheetState(() {
                              selectedRoom = isSelected ? null : room;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.orangeAccent
                                  : Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.orangeAccent
                                    : Colors.white24,
                              ),
                            ),
                            child: Text(room,
                                style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.white70)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    const Text('Konum',
                        style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final result = await _showCitySearchDialog();
                        if (result != null) {
                          setSheetState(() {
                            selectedCity = result;
                            selectedDistrict = null;
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_city,
                                color: Colors.orangeAccent, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                selectedCity ?? 'Şehir Seçin',
                                style: TextStyle(
                                  color: selectedCity != null
                                      ? Colors.white
                                      : Colors.white54,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            if (selectedCity != null)
                              GestureDetector(
                                onTap: () => setSheetState(() {
                                  selectedCity = null;
                                  selectedDistrict = null;
                                }),
                                child: const Icon(Icons.close,
                                    color: Colors.white38, size: 18),
                              ),
                            const SizedBox(width: 4),
                            const Icon(Icons.search,
                                color: Colors.white38, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (selectedCity != null && districts.isNotEmpty) ...[
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedDistrict,
                            hint: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text('İlçe Seçin',
                                  style: TextStyle(
                                      color: Colors.white54, fontSize: 14)),
                            ),
                            dropdownColor: const Color(0xFF302B63),
                            icon: const Icon(Icons.keyboard_arrow_down,
                                color: Colors.white70),
                            isExpanded: true,
                            menuMaxHeight: 300,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14),
                            items: districts
                                .map((v) => DropdownMenuItem(
                                    value: v,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16),
                                      child: Text(v),
                                    )))
                                .toList(),
                            onChanged: (v) =>
                                setSheetState(() => selectedDistrict = v),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 16),
                    const Text('Ev Özellikleri',
                        style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: allFeatures.map((feature) {
                        final isSelected = selectedFeatures.contains(feature);
                        return InkWell(
                          onTap: () {
                            setSheetState(() {
                              if (isSelected) {
                                selectedFeatures.remove(feature);
                              } else {
                                selectedFeatures.add(feature);
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.orangeAccent
                                  : Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.orangeAccent
                                    : Colors.white24,
                              ),
                            ),
                            child: Text(feature,
                                style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.white70,
                                    fontSize: 12)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          ref.read(listingFilterProvider.notifier).state =
                              ListingFilter(
                            listingType:
                                ref.read(listingFilterProvider).listingType,
                            minPrice: int.tryParse(minPriceCtrl.text),
                            maxPrice: int.tryParse(maxPriceCtrl.text),
                            roomCount: selectedRoom,
                            city: selectedCity,
                            district: selectedDistrict,
                            features: selectedFeatures,
                          );
                          Navigator.pop(bsCtx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orangeAccent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Filtreleri Uygula',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterTextField(
      TextEditingController controller, String hint, TextInputType type) {
    return TextField(
      controller: controller,
      keyboardType: type,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.orangeAccent),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}

class _SortOption {
  final String value;
  final String label;
  const _SortOption(this.value, this.label);
}

