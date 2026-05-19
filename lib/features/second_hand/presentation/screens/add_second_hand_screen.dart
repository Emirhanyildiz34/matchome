import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/second_hand_item_model.dart';
import '../providers/second_hand_provider.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/utils/content_filter.dart';
import '../../../../core/constants/turkish_cities.dart';

class AddSecondHandScreen extends ConsumerStatefulWidget {
  final SecondHandItemModel? existingItem;

  const AddSecondHandScreen({super.key, this.existingItem});

  @override
  ConsumerState<AddSecondHandScreen> createState() =>
      _AddSecondHandScreenState();
}

class _AddSecondHandScreenState extends ConsumerState<AddSecondHandScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  bool get isEditMode => widget.existingItem != null;

  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _priceController;
  late final TextEditingController _phoneController;

  String? _selectedCity;
  String? _selectedDistrict;
  String? _selectedSubcategory;

  late String _selectedCategory;
  late String _selectedCondition;
  late String _selectedCurrency;
  late List<String> _imageUrls;
  late bool _showPhone;
  bool _termsAccepted = false;

  final ImagePicker _imagePicker = ImagePicker();

  final List<String> _currencyOptions = ['TL', 'EUR', 'USD', 'GBP'];

  @override
  void initState() {
    super.initState();
    final e = widget.existingItem;
    _titleController = TextEditingController(text: e?.title ?? '');
    _descController = TextEditingController(text: e?.description ?? '');
    _priceController =
        TextEditingController(text: e != null ? e.price.toString() : '');
    _phoneController = TextEditingController(text: e?.contactPhone ?? '');
    _selectedCity = e?.city;
    _selectedDistrict = e?.district;
    _selectedCategory = e?.category ?? 'diger';
    _selectedSubcategory = e?.subcategory;
    _selectedCondition = e?.condition ?? 'az_kullanilmis';
    _selectedCurrency = e?.currency ?? 'TL';
    _imageUrls = List<String>.from(e?.imageUrls ?? []);
    _showPhone = e?.showPhone ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final pickedFiles = await _imagePicker.pickMultiImage(
        maxHeight: 1000,
        maxWidth: 1000,
        imageQuality: 80,
      );
      if (pickedFiles.isEmpty) return;

      final canAdd = 8 - _imageUrls.length;
      final toAdd = pickedFiles.take(canAdd).toList();

      setState(() => _isLoading = true);
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id ?? 'anonymous';
      int uploaded = 0;

      for (final file in toAdd) {
        final bytes = await file.readAsBytes();
        final ext = file.name.split('.').last.toLowerCase();
        final fileName =
            'second_hand/$userId/${DateTime.now().millisecondsSinceEpoch}_$uploaded.$ext';

        await supabase.storage.from('listing-images').uploadBinary(
            fileName, bytes,
            fileOptions: const FileOptions(upsert: true));

        final url =
            supabase.storage.from('listing-images').getPublicUrl(fileName);

        setState(() => _imageUrls.add(url));
        uploaded++;
      }

      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('$uploaded fotoğraf yüklendi (${_imageUrls.length}/8)'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Fotoğraf yükleme hatası: $e'),
              backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Lütfen şehir seçiniz'),
            backgroundColor: Colors.redAccent),
      );
      return;
    }

    if (_selectedSubcategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Lütfen alt kategori seçiniz'),
            backgroundColor: Colors.redAccent),
      );
      return;
    }

    final title = _titleController.text.trim();
    final desc = _descController.text.trim();

    if (ContentFilter.hasBlockedContent(title) ||
        ContentFilter.hasBlockedContent(desc)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('İlan içeriğinde uygunsuz ifade bulunamaz'),
            backgroundColor: Colors.redAccent),
      );
      return;
    }

    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Devam etmek için kuralları onaylamalısınız'),
            backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Oturum bulunamadı');

      final item = SecondHandItemModel(
        id: widget.existingItem?.id,
        sellerId: user.id,
        title: title,
        description: desc.isEmpty ? null : desc,
        price: int.parse(_priceController.text.trim()),
        currency: _selectedCurrency,
        category: _selectedCategory,
        subcategory: _selectedSubcategory,
        condition: _selectedCondition,
        imageUrls: _imageUrls,
        city: _selectedCity,
        district: _selectedDistrict,
        showPhone: _showPhone,
        contactPhone: _showPhone && _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
      );

      final repo = ref.read(secondHandRepositoryProvider);
      if (isEditMode) {
        await repo.updateItem(item.id!, item.toJson());
      } else {
        await repo.createItem(item);
      }

      ref.invalidate(secondHandItemsProvider);
      ref.invalidate(mySecondHandItemsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(isEditMode ? 'İlan güncellendi!' : 'İlan yayınlandı!'),
              backgroundColor: Colors.green),
        );
        context.pop();
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
                _buildAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('Fotoğraflar'),
                          _buildImagePicker(),
                          const SizedBox(height: 20),
                          _buildSectionTitle('Eşya Bilgileri'),
                          _buildTextField(
                            controller: _titleController,
                            label: 'Başlık *',
                            hint: 'Örn: Samsung Galaxy S21',
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Başlık zorunludur'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: _descController,
                            label: 'Açıklama',
                            hint: 'Eşyanızı detaylı anlatın...',
                            maxLines: 4,
                          ),
                          const SizedBox(height: 20),
                          _buildSectionTitle('Kategori'),
                          _buildCategorySelector(),
                          const SizedBox(height: 12),
                          _buildSectionTitle('Alt Kategori *'),
                          _buildSubcategorySelector(),
                          const SizedBox(height: 20),
                          _buildSectionTitle('Durum'),
                          _buildConditionSelector(),
                          const SizedBox(height: 20),
                          _buildSectionTitle('Fiyat'),
                          _buildPriceRow(),
                          const SizedBox(height: 20),
                          _buildSectionTitle('Konum *'),
                          _buildCityDropdown(),
                          if (_selectedCity != null) _buildDistrictDropdown(),
                          const SizedBox(height: 20),
                          _buildSectionTitle('İletişim'),
                          _buildPhoneSection(),
                          const SizedBox(height: 20),
                          _buildTermsCheckbox(),
                          const SizedBox(height: 24),
                          _buildSubmitButton(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black38,
              child: const Center(
                  child: CircularProgressIndicator(color: Colors.orangeAccent)),
            ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 20),
          ),
          Text(
            isEditMode ? 'İlanı Düzenle' : '2. El Eşya Sat',
            style: const TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
          border: InputBorder.none,
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildCityDropdown() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          final result =
              await _showCitySearchDialog(context, currentValue: _selectedCity);
          if (result != null) {
            setState(() {
              _selectedCity = result;
              _selectedDistrict = null;
            });
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              const Icon(Icons.location_city, color: Colors.orangeAccent),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _selectedCity ?? 'İl Seçin (Ara...)',
                  style: TextStyle(
                    color: _selectedCity != null
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.6),
                    fontSize: 15,
                  ),
                ),
              ),
              if (_selectedCity != null)
                GestureDetector(
                  onTap: () => setState(() {
                    _selectedCity = null;
                    _selectedDistrict = null;
                  }),
                  child:
                      const Icon(Icons.close, color: Colors.white38, size: 18),
                ),
              const SizedBox(width: 4),
              const Icon(Icons.search, color: Colors.white54, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDistrictDropdown() {
    final districts = TurkishCities.districts[_selectedCity] ?? [];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            style: const TextStyle(color: Colors.white, fontSize: 15),
            items: districts
                .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                .toList(),
            onChanged: (v) => setState(() => _selectedDistrict = v),
          ),
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
        builder: (dialogCtx, setS) {
          final filtered = TurkishCities.cities
              .where((c) => c.toLowerCase().contains(query.toLowerCase()))
              .toList();
          return Dialog(
            backgroundColor: const Color(0xFF1A1640),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Şehir Ara',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
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
                                color:
                                    isSel ? Colors.orangeAccent : Colors.white,
                                fontWeight:
                                    isSel ? FontWeight.bold : FontWeight.normal,
                              )),
                          trailing: isSel
                              ? const Icon(Icons.check,
                                  color: Colors.orangeAccent, size: 18)
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

  Widget _buildImagePicker() {
    return Column(
      children: [
        if (_imageUrls.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _imageUrls.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        _imageUrls[i],
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 100,
                          height: 100,
                          color: Colors.white10,
                          child: const Icon(Icons.broken_image,
                              color: Colors.white24),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => setState(() => _imageUrls.removeAt(i)),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
        if (_imageUrls.length < 8)
          InkWell(
            onTap: _pickImages,
            borderRadius: BorderRadius.circular(12),
            child: GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_a_photo_outlined,
                      color: Colors.orangeAccent, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'Fotoğraf Ekle (${_imageUrls.length}/8)',
                    style: const TextStyle(
                        color: Colors.white70, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: SecondHandItemModel.categories.entries.map((e) {
        final isSelected = _selectedCategory == e.key;
        return InkWell(
          onTap: () => setState(() {
            _selectedCategory = e.key;
            final subcategories = SecondHandItemModel.getSubcategories(e.key);
            if (!subcategories.contains(_selectedSubcategory)) {
              _selectedSubcategory = null;
            }
          }),
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.orangeAccent
                  : Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: isSelected ? Colors.orangeAccent : Colors.white24),
            ),
            child: Text(
              '${e.value.emoji} ${e.value.label}',
              style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSubcategorySelector() {
    final subcategories =
        SecondHandItemModel.getSubcategories(_selectedCategory);

    return GlassContainer(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Seçili kategori: ${SecondHandItemModel.categories[_selectedCategory]?.label ?? ''}',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: subcategories.map((subcategory) {
              final isSelected = _selectedSubcategory == subcategory;
              return InkWell(
                onTap: () => setState(() => _selectedSubcategory = subcategory),
                borderRadius: BorderRadius.circular(18),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.tealAccent.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected ? Colors.tealAccent : Colors.white24,
                    ),
                  ),
                  child: Text(
                    subcategory,
                    style: TextStyle(
                      color: isSelected ? Colors.tealAccent : Colors.white70,
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildConditionSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: SecondHandItemModel.conditions.entries.map((e) {
        final isSelected = _selectedCondition == e.key;
        return InkWell(
          onTap: () => setState(() => _selectedCondition = e.key),
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.tealAccent.withValues(alpha: 0.25)
                  : Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: isSelected ? Colors.tealAccent : Colors.white24),
            ),
            child: Text(
              e.value,
              style: TextStyle(
                  color: isSelected ? Colors.tealAccent : Colors.white70,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPriceRow() {
    return Row(
      children: [
        Expanded(
          child: GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: TextFormField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                labelText: 'Fiyat *',
                labelStyle: TextStyle(color: Colors.white54, fontSize: 13),
                border: InputBorder.none,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Fiyat zorunludur';
                if (int.tryParse(v.trim()) == null) {
                  return 'Geçerli rakam girin';
                }
                return null;
              },
            ),
          ),
        ),
        const SizedBox(width: 10),
        GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCurrency,
              dropdownColor: const Color(0xFF1A1640),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              items: _currencyOptions
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedCurrency = v);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneSection() {
    return Column(
      children: [
        GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Telefon numarası göster',
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
              Switch(
                value: _showPhone,
                onChanged: (v) => setState(() => _showPhone = v),
                activeThumbColor: Colors.orangeAccent,
              ),
            ],
          ),
        ),
        if (_showPhone) ...[
          const SizedBox(height: 8),
          _buildTextField(
            controller: _phoneController,
            label: 'Telefon Numarası',
            hint: '05XX XXX XX XX',
          ),
        ],
      ],
    );
  }

  Widget _buildTermsCheckbox() {
    return GlassContainer(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Checkbox(
            value: _termsAccepted,
            onChanged: (v) => setState(() => _termsAccepted = v ?? false),
            activeColor: Colors.orangeAccent,
            side: const BorderSide(color: Colors.white38),
          ),
          const Expanded(
            child: Text(
              'Yayınlanan ilanın doğru ve gerçek bilgiler içerdiğini onaylıyorum',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orangeAccent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(
          isEditMode ? 'Güncelle' : 'İlanı Yayınla',
          style: const TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
