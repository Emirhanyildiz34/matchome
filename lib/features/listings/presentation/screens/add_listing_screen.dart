import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../../core/constants/turkish_cities.dart';
import '../../../../core/constants/turkish_neighborhoods.dart';
import '../../../../core/constants/university_data.dart';
import '../../../../core/utils/content_filter.dart';
import '../../../../core/widgets/glass_container.dart';
import '../providers/listing_provider.dart';
import '../../data/models/listing_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddListingScreen extends ConsumerStatefulWidget {
  final ListingModel? existingListing;

  const AddListingScreen({super.key, this.existingListing});

  @override
  ConsumerState<AddListingScreen> createState() => _AddListingScreenState();
}

class _AddListingScreenState extends ConsumerState<AddListingScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  bool get isEditMode => widget.existingListing != null;

  // Controllers
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _priceController;

  String? _selectedCity;
  String? _selectedDistrict;
  String? _selectedNeighborhood;

  late String _selectedRoomCount;
  late bool _utilitiesIncluded;
  late List<String> _selectedFeatures;
  late String _listingType;
  late String? _selectedHomeType;
  late int? _emptyRooms;

  final List<String> _roomOptions = ['1+0', '1+1', '2+1', '3+1', '4+1'];
  final List<String> _homeTypeOptions = ['Müstakil', 'Apartman', 'Site'];
  final List<String> _currencyOptions = ['TL', 'EUR', 'USD', 'GBP'];
  final List<int> _emptyRoomsOptions = [1, 2, 3, 4, 5];
  final List<Map<String, dynamic>> _allFeatures = [
    {'name': 'Eşyalı', 'icon': Icons.weekend},
    {'name': 'WiFi', 'icon': Icons.wifi},
    {'name': 'Asansör', 'icon': Icons.elevator},
    {'name': 'Merkezi Isıtma', 'icon': Icons.hot_tub},
    {'name': 'Klima', 'icon': Icons.ac_unit},
    {'name': 'Balkon', 'icon': Icons.balcony},
    {'name': 'Çamaşır Makinesi', 'icon': Icons.local_laundry_service},
    {'name': 'Pet Arkadaşı', 'icon': Icons.pets},
  ];
  final List<Map<String, dynamic>> _allExtraFeatures = [
    {'name': 'Ütü', 'icon': Icons.checkroom},
    {'name': 'Tost Makinesi', 'icon': Icons.kitchen},
    {'name': 'Saç Kurutma Makinesi', 'icon': Icons.dry},
    {'name': 'Çay Makinesi', 'icon': Icons.local_drink},
    {'name': 'Kahve Makinesi', 'icon': Icons.coffee},
    {'name': 'Bulaşık Makinesi', 'icon': Icons.countertops},
    {'name': 'Çamaşır Kurutma Makinesi', 'icon': Icons.local_laundry_service},
  ];
  late List<String> _selectedExtraFeatures;
  late String _selectedCurrency;
  late List<String> _selectedImageUrls;
  bool _showPhone = false;
  late TextEditingController _phoneController;
  final ImagePicker _imagePicker = ImagePicker();
  bool _isLocating = false;
  double? _latitude;
  double? _longitude;
  bool _hasDeposit = false;
  late TextEditingController _depositController;
  String? _preferredGender; // null = fark etmez, 'male' = erkek, 'female' = kadın
  String? _nearbyUniversity;
  bool _termsAccepted = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingListing;
    _titleController = TextEditingController(text: existing?.title ?? '');
    _descController = TextEditingController(text: existing?.description ?? '');
    _priceController = TextEditingController(
        text: existing != null ? existing.price.toString() : '');
    // Parse city/district/neighborhood from addressText (format: "City, District, Neighborhood" or "City, District" or "City")
    if (existing?.addressText != null && existing!.addressText!.isNotEmpty) {
      final parts = existing.addressText!.split(', ');
      _selectedCity = parts.isNotEmpty && TurkishCities.cities.contains(parts[0]) ? parts[0] : null;
      _selectedDistrict = parts.length > 1 ? parts[1] : null;
      _selectedNeighborhood = parts.length > 2 ? parts[2] : null;
    }
    _selectedRoomCount = existing?.roomCount ?? '1+1';
    _selectedCurrency = existing?.currency ?? 'TL';
    _utilitiesIncluded = existing?.utilitiesIncluded ?? false;
    _selectedFeatures = List<String>.from(existing?.houseFeatures ?? []);
    _selectedExtraFeatures = List<String>.from(existing?.extraFeatures ?? []);
    _listingType = existing?.listingType ?? 'room_offer';
    _selectedHomeType = existing?.homeType;
    _emptyRooms = existing?.emptyRooms;
    _selectedImageUrls = List<String>.from(existing?.imageUrls ?? []);
    _showPhone = existing?.showPhone ?? false;
    _phoneController = TextEditingController(text: existing?.hostPhone ?? '');
    _latitude = existing?.latitude;
    _longitude = existing?.longitude;
    _hasDeposit = existing?.hasDeposit ?? false;
    _depositController = TextEditingController(
        text: existing?.depositAmount != null ? existing!.depositAmount.toString() : '');
    _preferredGender = existing?.preferredGender;
    _nearbyUniversity = existing?.nearbyUniversity != null
      ? UniversityData.resolveUniversityName(existing!.nearbyUniversity!) ?? existing.nearbyUniversity
      : null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _phoneController.dispose();
    _depositController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Argo/küfür kontrolü
    final titleText = _titleController.text.trim();
    final descText = _descController.text.trim();
    if (ContentFilter.hasBlockedContent(titleText) ||
        ContentFilter.hasBlockedContent(descText)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('İlan içeriğinde argo bulunamaz'),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    // Sözleşme onay kontrolü
    if (!_termsAccepted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'İlanı yayınlamak için kullanım sözleşmesini kabul etmeniz gerekiyor.'),
            backgroundColor: Colors.orangeAccent,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Giriş yapmanız gerekiyor.');

      if (isEditMode) {
        // Güncelleme
        await ref.read(listingRepositoryProvider).updateListing(
          widget.existingListing!.id!,
          {
            'title': _titleController.text.trim(),
            'description': _descController.text.trim(),
            'price': int.parse(_priceController.text),
            'currency': _selectedCurrency,
            'utilities_included': _utilitiesIncluded,
            'room_count': _selectedRoomCount,
            'house_features': _selectedFeatures,
            'image_urls': _selectedImageUrls,
            'address_text': [_selectedCity, _selectedDistrict, _selectedNeighborhood].where((e) => e != null && e.isNotEmpty).join(', '),
            'listing_type': _listingType,
            'latitude': _latitude,
            'longitude': _longitude,
            'show_phone': _showPhone,
            'host_phone': _showPhone ? _phoneController.text.trim() : null,
            'has_deposit': _hasDeposit,
            'deposit_amount': _hasDeposit && _depositController.text.isNotEmpty
                ? int.tryParse(_depositController.text)
                : null,
            'preferred_gender': _preferredGender,
            'nearby_university': _nearbyUniversity,
            if (_listingType == 'room_offer') ...{
              'home_type': _selectedHomeType,
              'empty_rooms': _emptyRooms,
              'extra_features': _selectedExtraFeatures,
            },
          },
        );

        if (mounted) {
          ref.invalidate(myListingsProvider);
          ref.invalidate(myListingProvider);
          ref.invalidate(activeListingsProvider);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('İlan başarıyla güncellendi!'),
                backgroundColor: Colors.green),
          );
          context.pop();
        }
      } else {
        // Yeni oluşturma
        final listing = ListingModel(
          hostId: user.id,
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          price: int.parse(_priceController.text),
          currency: _selectedCurrency,
          utilitiesIncluded: _utilitiesIncluded,
          roomCount: _selectedRoomCount,
          houseFeatures: _selectedFeatures,
          addressText: [_selectedCity, _selectedDistrict, _selectedNeighborhood].where((e) => e != null && e.isNotEmpty).join(', '),
          imageUrls: _selectedImageUrls,
          latitude: _latitude,
          longitude: _longitude,
          listingType: _listingType,
          homeType: _listingType == 'room_offer' ? _selectedHomeType : null,
          emptyRooms: _listingType == 'room_offer' ? _emptyRooms : null,
          extraFeatures: _listingType == 'room_offer' ? _selectedExtraFeatures : [],
          showPhone: _showPhone,
          hostPhone: _showPhone ? _phoneController.text.trim() : null,
          hasDeposit: _hasDeposit,
          depositAmount: _hasDeposit && _depositController.text.isNotEmpty
              ? int.tryParse(_depositController.text)
              : null,
          preferredGender: _preferredGender,
          nearbyUniversity: _nearbyUniversity,
        );

        await ref.read(listingRepositoryProvider).createListing(listing);

        if (mounted) {
          ref.invalidate(myListingProvider);
          ref.invalidate(myListingsProvider);
          ref.invalidate(activeListingsProvider);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('İlanınız başarıyla yayına alındı!'),
                backgroundColor: Colors.green),
          );
          context.go('/discover');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Hata: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                _buildAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('İlan Tipi'),
                          _buildListingTypeSelector(),
                          const SizedBox(height: 24),
                          _buildSectionTitle('Temel Bilgiler'),
                          _buildGlassTextField(
                            controller: _titleController,
                            label: 'İlan Başlığı',
                            hint: 'Örn: Kadıköy Merkezde Ferah Oda',
                            icon: Icons.title,
                            validator: (v) => v!.isEmpty ? 'Gerekli' : null,
                          ),
                          _buildGlassTextField(
                            controller: _priceController,
                            label: 'Aylık Kira',
                            hint: 'Örn: 8500',
                            icon: Icons.payments,
                            keyboardType: TextInputType.numberWithOptions(
                                signed: false, decimal: false),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (v) => v!.isEmpty ? 'Gerekli' : null,
                          ),
                          const SizedBox(height: 12),
                          _buildCurrencyDropdown(),
                          _buildUtilitiesToggle(),
                          _buildDepositSection(),
                          const SizedBox(height: 24),
                          _buildSectionTitle('Ev Detayları'),
                          _buildRoomDropdown(),
                          const SizedBox(height: 16),
                          if (_listingType == 'room_offer') ...[
                            _buildHomeTypeDropdown(),
                            const SizedBox(height: 16),
                            _buildEmptyRoomsDropdown(),
                            const SizedBox(height: 16),
                          ],
                          _buildFeaturesGrid(),
                          if (_listingType == 'room_offer') ...[
                            const SizedBox(height: 20),
                            _buildExtraFeaturesGrid(),
                          ],
                          const SizedBox(height: 24),
                          _buildSectionTitle('Kiracı Tercihleri'),
                          _buildGenderPreferenceSection(),
                          const SizedBox(height: 16),
                          _buildUniversityPicker(),
                          const SizedBox(height: 24),
                          _buildSectionTitle('Konum ve Açıklama'),
                          _buildPhotoGalleryWidget(),
                          const SizedBox(height: 20),
                          _buildLocationSection(),
                          _buildCityDropdown(),
                          if (_selectedCity != null)
                            _buildDistrictDropdown(),
                          if (_selectedDistrict != null)
                            _buildNeighborhoodDropdown(),
                          _buildGlassTextField(
                            controller: _descController,
                            label: 'Açıklama',
                            hint:
                                'Eviniz ve kurallarınız hakkında bilgi verin...',
                            icon: Icons.description,
                            maxLines: 4,
                          ),
                          const SizedBox(height: 24),
                          _buildSectionTitle('İletişim'),
                          _buildContactSection(),
                          const SizedBox(height: 24),
                          _buildTermsSection(),
                          const SizedBox(height: 40),
                          _buildSubmitButton(),
                          const SizedBox(height: 40),
                        ],
                      ),
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

  Widget _buildAppBar() {
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
              'İlan',
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 4),
      child: Text(
        title,
        style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 18,
            fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          inputFormatters: inputFormatters,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            prefixIcon: Icon(icon, color: Colors.orangeAccent),
            border: InputBorder.none,
          ),
          validator: validator,
        ),
      ),
    );
  }

  Widget _buildUtilitiesToggle() {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.bolt, color: Colors.orangeAccent),
              SizedBox(width: 12),
              Text('Faturalar Kiraya Dahil',
                  style: TextStyle(color: Colors.white)),
            ],
          ),
          Switch(
            value: _utilitiesIncluded,
            onChanged: (v) => setState(() => _utilitiesIncluded = v),
            activeThumbColor: Colors.orangeAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildRoomDropdown() {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedRoomCount,
          dropdownColor: const Color(0xFF302B63),
          style: const TextStyle(color: Colors.white, fontSize: 16),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
          isExpanded: true,
          items: _roomOptions
              .map((v) => DropdownMenuItem(value: v, child: Text(v)))
              .toList(),
          onChanged: (v) => setState(() => _selectedRoomCount = v!),
        ),
      ),
    );
  }

  Widget _buildCurrencyDropdown() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedCurrency,
            dropdownColor: const Color(0xFF302B63),
            style: const TextStyle(color: Colors.white, fontSize: 16),
            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
            isExpanded: true,
            items: _currencyOptions
                .map((v) => DropdownMenuItem(
                      value: v,
                      child: Row(
                        children: [
                          const SizedBox(width: 8),
                          Text(v),
                        ],
                      ),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _selectedCurrency = v!),
          ),
        ),
      ),
    );
  }

  Widget _buildHomeTypeDropdown() {
    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedHomeType,
            hint: Row(
              children: [
                const Icon(Icons.domain_rounded, color: Colors.orangeAccent),
                const SizedBox(width: 12),
                Text('Ev Tipi Seçin',
                    style:
                        TextStyle(color: Colors.white.withValues(alpha: 0.6))),
              ],
            ),
            dropdownColor: const Color(0xFF302B63),
            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
            isExpanded: true,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            items: _homeTypeOptions
                .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                .toList(),
            onChanged: (v) => setState(() => _selectedHomeType = v),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyRoomsDropdown() {
    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: _emptyRooms,
            hint: Row(
              children: [
                const Icon(Icons.door_front_door_rounded, color: Colors.orangeAccent),
                const SizedBox(width: 12),
                Text('Boş Oda Sayısı',
                    style:
                        TextStyle(color: Colors.white.withValues(alpha: 0.6))),
              ],
            ),
            dropdownColor: const Color(0xFF302B63),
            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
            isExpanded: true,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            items: _emptyRoomsOptions
                .map((v) => DropdownMenuItem(value: v, child: Text('$v Oda')))
                .toList(),
            onChanged: (v) => setState(() => _emptyRooms = v),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturesGrid() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _allFeatures.map((f) {
        final isSelected = _selectedFeatures.contains(f['name']);
        return InkWell(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedFeatures.remove(f['name']);
              } else {
                _selectedFeatures.add(f['name']);
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.orangeAccent
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isSelected ? Colors.orangeAccent : Colors.white24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(f['icon'],
                    size: 18,
                    color: isSelected ? Colors.white : Colors.white70),
                const SizedBox(width: 8),
                Text(f['name'],
                    style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildExtraFeaturesGrid() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _allExtraFeatures.map((f) {
        final isSelected = _selectedExtraFeatures.contains(f['name']);
        return InkWell(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedExtraFeatures.remove(f['name']);
              } else {
                _selectedExtraFeatures.add(f['name']);
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.orangeAccent
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isSelected ? Colors.orangeAccent : Colors.white24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(f['icon'],
                    size: 18,
                    color: isSelected ? Colors.white : Colors.white70),
                const SizedBox(width: 8),
                Text(f['name'],
                    style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildContactSection() {
    return Column(
      children: [
        GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.phone, color: Colors.orangeAccent),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Telefon numaramı göster',
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
              ),
              Switch(
                value: _showPhone,
                onChanged: (v) => setState(() => _showPhone = v),
                activeThumbColor: Colors.orangeAccent,
              ),
            ],
          ),
        ),
        if (_showPhone) ...[
          const SizedBox(height: 12),
          _buildGlassTextField(
            controller: _phoneController,
            label: 'Telefon Numarası',
            hint: '05XX XXX XX XX',
            icon: Icons.phone_android,
            keyboardType: TextInputType.phone,
          ),
        ],
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            _showPhone
                ? 'Telefon numaranız WhatsApp ve arama seçeneği olarak gösterilecek.'
                : 'Telefon numaranızı gizleyebilirsiniz. Kullanıcılar yalnızca uygulama üzerinden iletişime geçebilir.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          backgroundColor: Colors.orangeAccent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : Text(isEditMode ? 'İlanı Güncelle' : 'İlanı Yayınla',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
      ),
    );
  }

  Widget _buildPhotoGalleryWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Fotoğraflar (${_selectedImageUrls.length}/10)',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            if (_selectedImageUrls.length < 10 &&
                _selectedImageUrls.where((url) => url.startsWith('https://picsum')).isNotEmpty)
              ElevatedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.add_a_photo),
                label: const Text('Fotoğraf Ekle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_selectedImageUrls.isEmpty)
          GlassContainer(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.image_not_supported,
                      color: Colors.white38, size: 48),
                  const SizedBox(height: 8),
                  Text('İlan için henüz fotoğraf eklenmedi',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 13,
                      )),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _pickImages,
                    icon: const Icon(Icons.add_photo_alternate),
                    label: const Text('İlk Fotoğrafı Ekle'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ..._selectedImageUrls.asMap().entries.map((entry) {
                  int idx = entry.key;
                  String url = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Stack(
                      children: [
                        GlassContainer(
                          padding: const EdgeInsets.all(1),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              url,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.white10,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.broken_image,
                                    color: Colors.white24),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _selectedImageUrls.removeAt(idx);
                            }),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.8),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close,
                                  color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                if (_selectedImageUrls.length < 10)
                  GestureDetector(
                    onTap: _pickImages,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.orangeAccent.withValues(alpha: 0.5),
                          width: 2,
                          style: BorderStyle.solid,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add,
                          color: Colors.orangeAccent, size: 32),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _pickImages() async {
    if (_selectedImageUrls.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('En fazla 10 fotoğraf ekleyebilirsiniz'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      final List<XFile> pickedFiles = await _imagePicker.pickMultiImage(
        maxHeight: 1000,
        maxWidth: 1000,
        imageQuality: 80,
      );

      if (pickedFiles.isEmpty) return;

      int canAdd = 10 - _selectedImageUrls.length;
      List<XFile> filesToAdd = pickedFiles.take(canAdd).toList();

      setState(() => _isLoading = true);

      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id ?? 'anonymous';
      int uploadedCount = 0;

      for (var file in filesToAdd) {
        final bytes = await file.readAsBytes();
        final ext = file.name.split('.').last.toLowerCase();
        final fileName = '${userId}/${DateTime.now().millisecondsSinceEpoch}_${uploadedCount}.$ext';

        await supabase.storage
            .from('listing-images')
            .uploadBinary(fileName, bytes, fileOptions: const FileOptions(upsert: true));

        final publicUrl = supabase.storage
            .from('listing-images')
            .getPublicUrl(fileName);

        setState(() {
          _selectedImageUrls.add(publicUrl);
        });
        uploadedCount++;
      }

      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$uploadedCount fotoğraf yüklendi (${_selectedImageUrls.length}/10)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fotoğraf yükleme hatası: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Widget _buildGenderPreferenceSection() {
    final options = [
      {'value': null, 'label': 'Fark Etmez', 'icon': Icons.people},
      {'value': 'male', 'label': 'Erkek', 'icon': Icons.male},
      {'value': 'female', 'label': 'Kadın', 'icon': Icons.female},
    ];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person_search, color: Colors.orangeAccent, size: 20),
                const SizedBox(width: 10),
                const Text('Kiracı Cinsiyet Tercihi',
                    style: TextStyle(color: Colors.white, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: options.map((opt) {
                final isSelected = _preferredGender == opt['value'];
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () => setState(() => _preferredGender = opt['value'] as String?),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.orangeAccent.withValues(alpha: 0.25)
                              : Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Colors.orangeAccent
                                : Colors.white.withValues(alpha: 0.15),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(opt['icon'] as IconData,
                                color: isSelected ? Colors.orangeAccent : Colors.white60,
                                size: 22),
                            const SizedBox(height: 4),
                            Text(opt['label'] as String,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isSelected ? Colors.orangeAccent : Colors.white70,
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                )),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUniversityPicker() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () async {
          final result = await _showUniversitySearchDialog(
              context, currentValue: _nearbyUniversity);
          if (result != null) {
            setState(() => _nearbyUniversity = result == '__clear__' ? null : result);
          }
        },
        borderRadius: BorderRadius.circular(24),
        child: GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              const Icon(Icons.school, color: Colors.orangeAccent),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _nearbyUniversity ?? 'Yakın Üniversite Seçin (İsteğe Bağlı)',
                  style: TextStyle(
                    color: _nearbyUniversity != null
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.6),
                    fontSize: 15,
                  ),
                ),
              ),
              if (_nearbyUniversity != null)
                GestureDetector(
                  onTap: () => setState(() => _nearbyUniversity = null),
                  child: const Icon(Icons.close, color: Colors.white38, size: 18),
                ),
              const SizedBox(width: 4),
              const Icon(Icons.search, color: Colors.white54, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _showUniversitySearchDialog(BuildContext ctx,
      {String? currentValue}) async {
    String query = '';
    return showDialog<String>(
      context: ctx,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setS) {
          final filtered = query.isEmpty
              ? UniversityData.universityNames
              : UniversityData.searchUniversities(query);
          return Dialog(
            backgroundColor: const Color(0xFF1A1640),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Üniversite Ara',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Üniversite veya şehir adı yazın...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: const Icon(Icons.search,
                          color: Colors.orangeAccent),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.08),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (v) => setS(() => query = v),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 300,
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final uni = filtered[i];
                        final isSel = uni == currentValue;
                        final campusCount = UniversityData.getCampusNames(uni).length;
                        return ListTile(
                          dense: true,
                          title: Text(uni,
                              style: TextStyle(
                                color: isSel
                                    ? Colors.orangeAccent
                                    : Colors.white,
                                fontWeight: isSel
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              )),
                          subtitle: Text('$campusCount kampüs',
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 12)),
                          trailing: isSel
                              ? const Icon(Icons.check,
                                  color: Colors.orangeAccent, size: 18)
                              : null,
                          onTap: () =>
                              Navigator.of(dialogCtx).pop(uni),
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

  Widget _buildCityDropdown() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () async {
          final result = await _showCitySearchDialog(context, currentValue: _selectedCity);
          if (result != null) {
            setState(() {
              _selectedCity = result;
              _selectedDistrict = null;
              _selectedNeighborhood = null;
            });
          }
        },
        borderRadius: BorderRadius.circular(24),
        child: GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              const Icon(Icons.location_city, color: Colors.orangeAccent),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _selectedCity ?? 'Şehir Seçin (Ara...)',
                  style: TextStyle(
                    color: _selectedCity != null
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.6),
                    fontSize: 16,
                  ),
                ),
              ),
              if (_selectedCity != null)
                GestureDetector(
                  onTap: () => setState(() {
                    _selectedCity = null;
                    _selectedDistrict = null;
                    _selectedNeighborhood = null;
                  }),
                  child: const Icon(Icons.close, color: Colors.white38, size: 18),
                ),
              const SizedBox(width: 4),
              const Icon(Icons.search, color: Colors.white54, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _showCitySearchDialog(BuildContext ctx, {String? currentValue}) async {
    String query = '';
    return showDialog<String>(
      context: ctx,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setS) {
          final filtered = TurkishCities.cities
              .where((c) => c.toLowerCase().contains(query.toLowerCase()))
              .toList();
          return Dialog(
            backgroundColor: const Color(0xFF1A1640),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Şehir Ara',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Şehir adı yazın...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: const Icon(Icons.search, color: Colors.orangeAccent),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.08),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (v) => setS(() => query = v),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 280,
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final city = filtered[i];
                        final isSel = city == currentValue;
                        return ListTile(
                          dense: true,
                          title: Text(city,
                              style: TextStyle(
                                color: isSel ? Colors.orangeAccent : Colors.white,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                              )),
                          trailing: isSel
                              ? const Icon(Icons.check, color: Colors.orangeAccent, size: 18)
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

  Widget _buildDistrictDropdown() {
    final districts = TurkishCities.districts[_selectedCity] ?? [];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedDistrict,
            hint: Row(
              children: [
                const Icon(Icons.map, color: Colors.orangeAccent),
                const SizedBox(width: 12),
                Text('İlçe Seçin',
                    style:
                        TextStyle(color: Colors.white.withValues(alpha: 0.6))),
              ],
            ),
            dropdownColor: const Color(0xFF302B63),
            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
            isExpanded: true,
            menuMaxHeight: 300,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            items: districts
                .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                .toList(),
            onChanged: (v) => setState(() => _selectedDistrict = v),
          ),
        ),
      ),
    );
  }

  Widget _buildNeighborhoodDropdown() {
    final neighborhoodKey = '$_selectedCity-$_selectedDistrict';
    final neighborhoods = TurkishNeighborhoods.neighborhoods[neighborhoodKey] ??
        const ['Merkez'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () async {
          final result = await _showNeighborhoodSearchDialog(
              context, neighborhoods,
              currentValue: _selectedNeighborhood);
          if (result != null) {
            setState(() => _selectedNeighborhood = result);
          }
        },
        borderRadius: BorderRadius.circular(24),
        child: GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              const Icon(Icons.location_on, color: Colors.pinkAccent),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _selectedNeighborhood ?? 'Mahalle Seçin (Ara...)',
                  style: TextStyle(
                    color: _selectedNeighborhood != null
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.6),
                    fontSize: 16,
                  ),
                ),
              ),
              if (_selectedNeighborhood != null)
                GestureDetector(
                  onTap: () =>
                      setState(() => _selectedNeighborhood = null),
                  child: const Icon(Icons.close,
                      color: Colors.white38, size: 18),
                ),
              const SizedBox(width: 4),
              const Icon(Icons.search, color: Colors.white54, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _showNeighborhoodSearchDialog(
      BuildContext ctx, List<String> neighborhoods,
      {String? currentValue}) async {
    String query = '';
    return showDialog<String>(
      context: ctx,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setS) {
          final filtered = neighborhoods
              .where((n) => n.toLowerCase().contains(query.toLowerCase()))
              .toList();
          return Dialog(
            backgroundColor: const Color(0xFF1A1640),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Mahalle Ara',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Mahalle adı yazın...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: const Icon(Icons.search,
                          color: Colors.pinkAccent),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.08),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (v) => setS(() => query = v),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 280,
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final n = filtered[i];
                        final isSel = n == currentValue;
                        return ListTile(
                          dense: true,
                          title: Text(n,
                              style: TextStyle(
                                color: isSel
                                    ? Colors.pinkAccent
                                    : Colors.white,
                                fontWeight: isSel
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              )),
                          trailing: isSel
                              ? const Icon(Icons.check,
                                  color: Colors.pinkAccent, size: 18)
                              : null,
                          onTap: () =>
                              Navigator.of(dialogCtx).pop(n),
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

  Widget _buildListingTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => setState(() => _listingType = 'room_offer'),
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: _listingType == 'room_offer'
                    ? Colors.orangeAccent
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _listingType == 'room_offer'
                      ? Colors.orangeAccent
                      : Colors.white24,
                ),
              ),
              child: Column(
                children: [
                  Icon(Icons.home_work_rounded,
                      size: 32,
                      color: _listingType == 'room_offer'
                          ? Colors.white
                          : Colors.white54),
                  const SizedBox(height: 8),
                  Text('Oda Veriyorum',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: _listingType == 'room_offer'
                              ? Colors.white
                              : Colors.white54,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  const SizedBox(height: 2),
                  Text('Ev arkadaşı arıyorum',
                      style: TextStyle(
                          color: _listingType == 'room_offer'
                              ? Colors.white70
                              : Colors.white30,
                          fontSize: 11)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InkWell(
            onTap: () => setState(() => _listingType = 'room_search'),
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: _listingType == 'room_search'
                    ? Colors.orangeAccent
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _listingType == 'room_search'
                      ? Colors.orangeAccent
                      : Colors.white24,
                ),
              ),
              child: Column(
                children: [
                  Icon(Icons.search_rounded,
                      size: 32,
                      color: _listingType == 'room_search'
                          ? Colors.white
                          : Colors.white54),
                  const SizedBox(height: 8),
                  Text('Oda Arıyorum',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: _listingType == 'room_search'
                              ? Colors.white
                              : Colors.white54,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  const SizedBox(height: 2),
                  Text('Kalacak yer istiyorum',
                      style: TextStyle(
                          color: _listingType == 'room_search'
                              ? Colors.white70
                              : Colors.white30,
                          fontSize: 11)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── KONUM BÖLÜMÜ ──────────────────────────────────────────────────────────

  Widget _buildLocationSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.my_location, color: Colors.orangeAccent, size: 18),
                SizedBox(width: 8),
                Text('Konum Bilgisi',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLocating ? null : _detectLocation,
                    icon: _isLocating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.gps_fixed, size: 18),
                    label: Text(
                        _isLocating ? 'Konum alınıyor...' : 'Konumu Otomatik Al'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                if (_latitude != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() {
                      _latitude = null;
                      _longitude = null;
                    }),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                      ),
                      child: const Icon(Icons.location_off,
                          color: Colors.redAccent, size: 18),
                    ),
                  ),
                ],
              ],
            ),
            if (_latitude != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.greenAccent, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Konum alındı: ${_latitude!.toStringAsFixed(4)}°, ${_longitude!.toStringAsFixed(4)}°',
                    style: const TextStyle(color: Colors.greenAccent, fontSize: 12),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'GPS ile konumunuzu otomatik alın ya da aşağıdan şehir/ilçe seçip manuel girin.',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  // ─── DEPOZİTO BÖLÜMÜ ───────────────────────────────────────────────────────

  Widget _buildDepositSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, top: 4),
      child: Column(
        children: [
          GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.shield_outlined, color: Colors.orangeAccent),
                    SizedBox(width: 12),
                    Text('Depozito İstiyorum',
                        style: TextStyle(color: Colors.white)),
                  ],
                ),
                Switch(
                  value: _hasDeposit,
                  onChanged: (v) => setState(() => _hasDeposit = v),
                  activeThumbColor: Colors.orangeAccent,
                ),
              ],
            ),
          ),
          if (_hasDeposit) ...[
            const SizedBox(height: 8),
            _buildGlassTextField(
              controller: _depositController,
              label: 'Depozito Tutarı (TL)',
              hint: 'Örn: 5000',
              icon: Icons.monetization_on_outlined,
              keyboardType: TextInputType.number,
            ),
          ],
        ],
      ),
    );
  }

  // ─── SÖZLEŞME ONAY BÖLÜMÜ ──────────────────────────────────────────────────

  Widget _buildTermsSection() {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.gavel, color: Colors.orangeAccent, size: 18),
              SizedBox(width: 8),
              Text(
                'Kullanım Koşulları',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Text(
              'Kişisel Veri İşleme Sözleşmesi\n\n'
              'İlan verirken paylaştığınız kişisel veriler (ad, telefon, konum vb.) '
              'yalnızca hizmet amacıyla işlenmekte ve üçüncü taraflarla paylaşılmamaktadır.\n\n'
              'Kira Sözleşmesi — Alt Kiralama Hakkı\n\n'
              'Bu platform üzerinden oluşturulan kiralama ilanları ve gerçekleşen '
              'kiralama işlemleri tamamen ilgili taraflar arasındadır. '
              'Platform, kiracı ile ev sahibi arasındaki kira sözleşmesine taraf değildir. '
              'Alt kiralama hakkını kullanan ya da kullanan kişilerin neden '
              'olduğu hukuki ve mali sonuçlardan platform hiçbir sorumluluk kabul etmemektedir. '
              'İlan sahibi, oluşabilecek tüm hukuki yükümlülüklerin kendisine ait olduğunu kabul eder.',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7), fontSize: 12, height: 1.5),
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => setState(() => _termsAccepted = !_termsAccepted),
            borderRadius: BorderRadius.circular(8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _termsAccepted
                        ? Colors.orangeAccent
                        : Colors.transparent,
                    border: Border.all(
                      color: _termsAccepted
                          ? Colors.orangeAccent
                          : Colors.white38,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: _termsAccepted
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Kişisel veri işleme sözleşmesini ve alt kiralama sorumluluğunu '
                    'okudum, anladım ve kabul ediyorum.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          if (!_termsAccepted) ...[
            const SizedBox(height: 8),
            Text(
              'İlanı yayınlamak için koşulları kabul etmeniz gerekiyor.',
              style: TextStyle(
                  color: Colors.orangeAccent.withValues(alpha: 0.8),
                  fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _detectLocation() async {    setState(() => _isLocating = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Konum izni verilmedi. Lütfen tarayıcı ayarlarından izin verin.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });

      // Nominatim ile ters jeokodlama
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?format=json'
        '&lat=${position.latitude}'
        '&lon=${position.longitude}'
        '&accept-language=tr',
      );
      final response = await http.get(uri, headers: {
        'User-Agent': 'MatchHome/1.0 (Flutter)',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final address = (data['address'] as Map<String, dynamic>?) ?? {};

        final rawCity = (address['city'] ??
                address['province'] ??
                address['state'] ??
                '') as String;
        final rawDistrict = (address['town'] ??
                address['district'] ??
                address['county'] ??
                '') as String;

        // Türk şehriyle eşleştir
        if (rawCity.isNotEmpty) {
          final matchedCity = TurkishCities.cities.firstWhere(
            (c) =>
                c.toLowerCase() == rawCity.toLowerCase() ||
                rawCity.toLowerCase().contains(c.toLowerCase()) ||
                c.toLowerCase().contains(rawCity.toLowerCase()),
            orElse: () => '',
          );
          if (matchedCity.isNotEmpty && mounted) {
            setState(() => _selectedCity = matchedCity);

            // İlçe eşleştir
            if (rawDistrict.isNotEmpty) {
              final districts =
                  TurkishCities.districts[matchedCity] ?? [];
              final matchedDistrict = districts.firstWhere(
                (d) =>
                    d.toLowerCase() == rawDistrict.toLowerCase() ||
                    rawDistrict.toLowerCase().contains(d.toLowerCase()) ||
                    d.toLowerCase().contains(rawDistrict.toLowerCase()),
                orElse: () => '',
              );
              if (matchedDistrict.isNotEmpty && mounted) {
                setState(() => _selectedDistrict = matchedDistrict);

                // Mahalle eşleştir
                final rawNeighborhood = (address['neighbourhood'] ??
                        address['suburb'] ??
                        address['quarter'] ??
                        '') as String;
                if (rawNeighborhood.isNotEmpty) {
                  final neighborhoodKey = '$matchedCity-$matchedDistrict';
                  final neighborhoods =
                      TurkishNeighborhoods.neighborhoods[neighborhoodKey] ??
                          const <String>[];
                  final normalizedRaw = rawNeighborhood
                      .toLowerCase()
                      .replaceAll(' mahallesi', '')
                      .replaceAll(' mah', '')
                      .trim();
                  final matchedNeighborhood = neighborhoods.firstWhere(
                    (n) {
                      final normalizedN = n
                          .toLowerCase()
                          .replaceAll(' mah', '')
                          .trim();
                      return normalizedN == normalizedRaw ||
                          normalizedRaw.contains(normalizedN) ||
                          normalizedN.contains(normalizedRaw);
                    },
                    orElse: () => '',
                  );
                  if (matchedNeighborhood.isNotEmpty && mounted) {
                    setState(() => _selectedNeighborhood = matchedNeighborhood);
                  }
                }
              }
            }
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _selectedCity != null
                    ? 'Konum alındı: $_selectedCity${_selectedDistrict != null ? ", $_selectedDistrict" : ""}${_selectedNeighborhood != null ? ", $_selectedNeighborhood" : ""}'
                    : 'Koordinatlar alındı, şehir listeden seçiniz.',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Konum alınamadı: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }
}

