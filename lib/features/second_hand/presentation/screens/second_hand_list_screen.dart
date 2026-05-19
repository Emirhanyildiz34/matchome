import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/second_hand_item_model.dart';
import '../providers/second_hand_provider.dart';
import '../../../../core/constants/turkish_cities.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/utils/format_utils.dart';

class SecondHandListScreen extends ConsumerStatefulWidget {
  const SecondHandListScreen({super.key});

  @override
  ConsumerState<SecondHandListScreen> createState() =>
      _SecondHandListScreenState();
}

class _SecondHandListScreenState extends ConsumerState<SecondHandListScreen> {
  final TextEditingController _searchController = TextEditingController();
  late final PageController _sliderController;
  int _currentSliderPage = 0;

  @override
  void initState() {
    super.initState();
    _sliderController = PageController(viewportFraction: 0.88);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _sliderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(secondHandItemsProvider);
    final filter = ref.watch(secondHandFilterProvider);
    final searchQuery = ref.watch(secondHandSearchProvider);

    return Column(
      children: [
        _buildSearchBar(),
        _buildCategoryChips(filter),
        if (filter.hasActiveFilters) _buildActiveFilters(filter),
        Expanded(
          child: itemsAsync.when(
            data: (items) {
              final filtered = searchQuery.isEmpty
                  ? items
                  : items.where((item) {
                      final q = searchQuery.toLowerCase();
                      return item.title.toLowerCase().contains(q) ||
                          (item.subcategory?.toLowerCase().contains(q) ??
                              false) ||
                          (item.description?.toLowerCase().contains(q) ??
                              false);
                    }).toList();
              return _buildItemList(filtered);
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.orangeAccent),
            ),
            error: (e, _) => Center(
              child: Text('Hata: $e',
                  style: const TextStyle(color: Colors.white70)),
            ),
          ),
        ),
      ],
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
                  hintText: 'Eşya ara...',
                  hintStyle: TextStyle(color: Colors.white38),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
                onChanged: (v) =>
                    ref.read(secondHandSearchProvider.notifier).state = v,
              ),
            ),
            GestureDetector(
              onTap: () => _showFilterSheet(context),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: ref.watch(secondHandFilterProvider).hasActiveFilters
                      ? Colors.orangeAccent.withValues(alpha: 0.18)
                      : Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.tune,
                  color: ref.watch(secondHandFilterProvider).hasActiveFilters
                      ? Colors.orangeAccent
                      : Colors.white54,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (_searchController.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                  ref.read(secondHandSearchProvider.notifier).state = '';
                },
                child: const Icon(Icons.close, color: Colors.white38, size: 18),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChips(SecondHandFilter filter) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildCategoryChip(
              label: '🏷️ Tümü',
              isSelected: filter.category == null,
              onTap: () => ref.read(secondHandFilterProvider.notifier).state =
                  filter.copyWith(
                category: () => null,
                subcategory: () => null,
              ),
            ),
            const SizedBox(width: 6),
            ...SecondHandItemModel.categories.entries.map((e) {
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: _buildCategoryChip(
                  label: '${e.value.emoji} ${e.value.label}',
                  isSelected: filter.category == e.key,
                  onTap: () {
                    final nextSubcategory =
                        filter.category == e.key ? filter.subcategory : null;
                    ref.read(secondHandFilterProvider.notifier).state =
                        filter.copyWith(
                      category: () => e.key,
                      subcategory: () => nextSubcategory,
                    );
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFilters(SecondHandFilter filter) {
    final chips = <String>[
      if (filter.city != null) 'Şehir: ${filter.city}',
      if (filter.district != null) 'İlçe: ${filter.district}',
      if (filter.subcategory != null) 'Alt kategori: ${filter.subcategory}',
      if (filter.minPrice != null || filter.maxPrice != null)
        'Fiyat: ${filter.minPrice ?? 0}-${filter.maxPrice ?? '∞'} TL',
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: chips
                .map(
                  (chip) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Text(
                      chip,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                ref.read(secondHandFilterProvider.notifier).state =
                    const SecondHandFilter();
              },
              child: const Text(
                'Filtreleri Temizle',
                style: TextStyle(color: Colors.orangeAccent),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip({
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
            color: isSelected
                ? Colors.orangeAccent
                : Colors.white.withValues(alpha: 0.2),
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

  Widget _buildItemList(List<SecondHandItemModel> items) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: GlassContainer(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.storefront_outlined,
                    size: 64, color: Colors.orangeAccent),
                const SizedBox(height: 16),
                const Text(
                  'Henüz eşya bulunamadı',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Filtreleri değiştir veya ilk ilanı sen ver!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () {
                    ref.read(secondHandFilterProvider.notifier).state =
                        const SecondHandFilter();
                    ref.read(secondHandSearchProvider.notifier).state = '';
                    _searchController.clear();
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

    final topFeatured = ([...items]
          ..sort((a, b) => b.price.compareTo(a.price)))
        .take(10)
        .toList();
    final showSlider = topFeatured.length >= 2;

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(secondHandItemsProvider),
      color: Colors.orangeAccent,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: items.length + (showSlider ? 1 : 0),
        itemBuilder: (context, index) {
          if (showSlider && index == 0) {
            return _buildFeaturedSlider(topFeatured);
          }
          return _buildItemCard(items[showSlider ? index - 1 : index]);
        },
      ),
    );
  }

  Widget _buildFeaturedSlider(List<SecondHandItemModel> featured) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              const Icon(Icons.local_offer, color: Colors.tealAccent, size: 18),
              const SizedBox(width: 6),
              const Text(
                'Öne Çıkan Eşyalar',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                '${_currentSliderPage + 1}/${featured.length}',
                style:
                    const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _sliderController,
            itemCount: featured.length,
            onPageChanged: (i) => setState(() => _currentSliderPage = i),
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.only(right: 10),
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
                    ? Colors.tealAccent
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

  Widget _buildFeaturedCard(SecondHandItemModel item) {
    final catInfo = SecondHandItemModel.categories[item.category];
    return InkWell(
      onTap: () => context.push('/second-hand-detail', extra: item),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: Colors.tealAccent.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(16)),
              child: item.imageUrls.isNotEmpty
                  ? Image.network(
                      item.imageUrls.first,
                      height: 180,
                      width: 130,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 180,
                        width: 130,
                        color: Colors.white10,
                        child: const Icon(Icons.image_not_supported,
                            color: Colors.white38, size: 36),
                      ),
                    )
                  : Container(
                      height: 180,
                      width: 130,
                      color: Colors.white10,
                      child: const Icon(Icons.storefront,
                          color: Colors.white38, size: 36),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.tealAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${catInfo?.emoji ?? '📦'} ${catInfo?.label ?? 'Diğer'}',
                        style: const TextStyle(
                            color: Colors.tealAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${formatPrice(item.price)} ${currencySymbol(item.currency)}',
                      style: const TextStyle(
                          color: Colors.orangeAccent,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(SecondHandItemModel item) {
    final catInfo = SecondHandItemModel.categories[item.category];
    final condLabel =
        SecondHandItemModel.conditions[item.condition] ?? item.condition;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => context.push('/second-hand-detail', extra: item),
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
                child: item.imageUrls.isNotEmpty
                    ? Image.network(
                        item.imageUrls.first,
                        height: 100,
                        width: 110,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imagePlaceholder(),
                      )
                    : _imagePlaceholder(),
              ),
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${formatPrice(item.price)} ${currencySymbol(item.currency)}',
                            style: const TextStyle(
                                color: Colors.orangeAccent,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.tealAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${catInfo?.emoji ?? '📦'} ${catInfo?.label ?? 'Diğer'}',
                              style: const TextStyle(
                                  color: Colors.tealAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 3),
                      if (item.subcategory != null &&
                          item.subcategory!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            item.subcategory!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              condLabel,
                              style: const TextStyle(
                                  color: Colors.white60, fontSize: 10),
                            ),
                          ),
                          if (item.locationLabel.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.location_on,
                                color: Colors.white38, size: 12),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                item.locationLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.white54, fontSize: 12),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 10),
                child:
                    Icon(Icons.chevron_right, color: Colors.white24, size: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 100,
      width: 110,
      color: Colors.white10,
      child: const Icon(Icons.storefront_outlined,
          color: Colors.white24, size: 28),
    );
  }

  Future<void> _showFilterSheet(BuildContext context) async {
    final filter = ref.read(secondHandFilterProvider);
    String? selectedCategory = filter.category;
    String? selectedSubcategory = filter.subcategory;
    String? selectedCity = filter.city;
    String? selectedDistrict = filter.district;
    final minController = TextEditingController(
      text: filter.minPrice?.toString() ?? '',
    );
    final maxController = TextEditingController(
      text: filter.maxPrice?.toString() ?? '',
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1640),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final categoryEntries =
                SecondHandItemModel.categories.entries.toList();
            final districtOptions =
                TurkishCities.districts[selectedCity] ?? const [];
            final subcategories = selectedCategory == null
                ? const <String>[]
                : SecondHandItemModel.getSubcategories(selectedCategory!);

            Future<void> pickCity() async {
              final city = await _showCitySearchDialog(
                sheetContext,
                currentValue: selectedCity,
              );
              if (city == null) return;
              setSheetState(() {
                selectedCity = city;
                selectedDistrict = null;
              });
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'İlan Filtreleri',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFilterLabel('Kategori'),
                    _buildFilterDropdown(
                      value: selectedCategory,
                      hint: 'Kategori seçin',
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Tümü'),
                        ),
                        ...categoryEntries.map(
                          (entry) => DropdownMenuItem<String>(
                            value: entry.key,
                            child: Text(
                                '${entry.value.emoji} ${entry.value.label}'),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setSheetState(() {
                          selectedCategory = value;
                          final availableSubcategories = value == null
                              ? const <String>[]
                              : SecondHandItemModel.getSubcategories(value);
                          if (!availableSubcategories
                              .contains(selectedSubcategory)) {
                            selectedSubcategory = null;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildFilterLabel('Alt kategori'),
                    _buildFilterDropdown(
                      value: selectedSubcategory,
                      hint: selectedCategory == null
                          ? 'Önce kategori seçin'
                          : 'Alt kategori seçin',
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Tümü'),
                        ),
                        ...subcategories.map(
                          (subcategory) => DropdownMenuItem<String>(
                            value: subcategory,
                            child: Text(subcategory),
                          ),
                        ),
                      ],
                      onChanged: selectedCategory == null
                          ? null
                          : (value) {
                              setSheetState(() {
                                selectedSubcategory = value;
                              });
                            },
                    ),
                    const SizedBox(height: 12),
                    _buildFilterLabel('Şehir'),
                    InkWell(
                      onTap: pickCity,
                      borderRadius: BorderRadius.circular(14),
                      child: GlassContainer(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            const Icon(Icons.location_city,
                                color: Colors.orangeAccent, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                selectedCity ?? 'Şehir seçin',
                                style: TextStyle(
                                  color: selectedCity == null
                                      ? Colors.white54
                                      : Colors.white,
                                ),
                              ),
                            ),
                            if (selectedCity != null)
                              GestureDetector(
                                onTap: () {
                                  setSheetState(() {
                                    selectedCity = null;
                                    selectedDistrict = null;
                                  });
                                },
                                child: const Icon(Icons.close,
                                    color: Colors.white38, size: 18),
                              )
                            else
                              const Icon(Icons.search,
                                  color: Colors.white38, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildFilterLabel('İlçe'),
                    _buildFilterDropdown(
                      value: selectedDistrict,
                      hint: selectedCity == null
                          ? 'Önce şehir seçin'
                          : 'İlçe seçin',
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Tümü'),
                        ),
                        ...districtOptions.map(
                          (district) => DropdownMenuItem<String>(
                            value: district,
                            child: Text(district),
                          ),
                        ),
                      ],
                      onChanged: selectedCity == null
                          ? null
                          : (value) {
                              setSheetState(() {
                                selectedDistrict = value;
                              });
                            },
                    ),
                    const SizedBox(height: 12),
                    _buildFilterLabel('Fiyat aralığı'),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: minController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: _filterInputDecoration('Min fiyat'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: maxController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: _filterInputDecoration('Max fiyat'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              ref
                                  .read(secondHandFilterProvider.notifier)
                                  .state = const SecondHandFilter();
                              Navigator.of(sheetContext).pop();
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white24),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text(
                              'Temizle',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              ref
                                  .read(secondHandFilterProvider.notifier)
                                  .state = SecondHandFilter(
                                category: selectedCategory,
                                subcategory: selectedSubcategory,
                                city: selectedCity,
                                district: selectedDistrict,
                                minPrice:
                                    int.tryParse(minController.text.trim()),
                                maxPrice:
                                    int.tryParse(maxController.text.trim()),
                              );
                              Navigator.of(sheetContext).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orangeAccent,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text(
                              'Uygula',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildFilterLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  InputDecoration _filterInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.08),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.orangeAccent),
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String? value,
    required String hint,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?>? onChanged,
  }) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            hint,
            style: const TextStyle(color: Colors.white38),
          ),
          dropdownColor: const Color(0xFF302B63),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
          isExpanded: true,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Future<String?> _showCitySearchDialog(BuildContext ctx,
      {String? currentValue}) async {
    String query = '';
    return showDialog<String>(
      context: ctx,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final filtered = TurkishCities.cities
              .where((city) => city.toLowerCase().contains(query.toLowerCase()))
              .toList();

          return Dialog(
            backgroundColor: const Color(0xFF1A1640),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Şehir Ara',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Şehir adı yazın...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      prefixIcon:
                          const Icon(Icons.search, color: Colors.orangeAccent),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.08),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) => setDialogState(() => query = value),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 280,
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (_, index) {
                        final city = filtered[index];
                        final isSelected = city == currentValue;
                        return ListTile(
                          dense: true,
                          title: Text(
                            city,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.orangeAccent
                                  : Colors.white,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.orangeAccent,
                                  size: 18,
                                )
                              : null,
                          onTap: () => Navigator.of(dialogCtx).pop(city),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
