import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';
import '../../../../core/constants/turkish_cities.dart';
import '../../../../core/constants/university_data.dart';
import '../../../../core/widgets/glass_container.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isEditing = false;
  bool _isInitialized = false;
  bool _isUploadingAvatar = false;
  String? _localAvatarUrl;

  // Controllers
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();

  String? _selectedCity;
  String? _selectedDistrict;
  String? _selectedGender;
  String? _selectedUniversity;
  String? _selectedCampus;
  String _userType = 'seeker';

  final List<String> _genders = ['Erkek', 'Kadın', 'Belirtmek İstemiyorum'];
  final ImagePicker _imagePicker = ImagePicker();

  Future<void> _pickAndUploadAvatar() async {
    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 85,
      );
      if (file == null) return;

      setState(() => _isUploadingAvatar = true);

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final bytes = await file.readAsBytes();
      final ext = file.name.split('.').last.toLowerCase();
      final fileName = 'avatars/${user.id}/avatar.$ext';

      await Supabase.instance.client.storage
          .from('listing-images')
          .uploadBinary(fileName, bytes,
              fileOptions: const FileOptions(upsert: true));

      final url = Supabase.instance.client.storage
          .from('listing-images')
          .getPublicUrl(fileName);

      await Supabase.instance.client
          .from('profiles')
          .update({'avatar_url': url}).eq('id', user.id);

      final bustUrl = '$url?t=${DateTime.now().millisecondsSinceEpoch}';
      setState(() => _localAvatarUrl = bustUrl);
      ref.invalidate(profileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Profil fotoğrafı güncellendi!'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Fotoğraf yükleme hatası: $e'),
              backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _populateFields(Map<String, dynamic>? profile) {
    if (profile == null) return;
    _nameController.text = profile['full_name'] ?? '';
    _bioController.text = profile['bio'] ?? '';
    final rawUniversity = profile['university'] as String?;
    final rawCampus = profile['campus'] as String?;
    final resolvedUniversity = (rawUniversity != null && rawUniversity.isNotEmpty)
      ? UniversityData.resolveUniversityName(rawUniversity) ?? rawUniversity
      : null;
    _selectedUniversity = resolvedUniversity;
    _selectedCampus = (resolvedUniversity != null)
      ? UniversityData.getCampusData(resolvedUniversity, rawCampus)?.name
      : null;
    _selectedCity = profile['city'];
    _selectedDistrict = profile['district'];
    _selectedGender = profile['gender'];
    _userType = profile['user_type'] ?? 'seeker';
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Oturum bulunamadı.');

      final db = Supabase.instance.client.from('profiles');
      final userId = user.id;

      await db.update({
        'full_name': _nameController.text.trim(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
        'bio': _bioController.text.trim(),
        'university': _selectedUniversity,
        'campus': _selectedCampus,
        if (_selectedGender != null) 'gender': _selectedGender,
        if (_selectedCity != null) 'city': _selectedCity,
        if (_selectedDistrict != null) 'district': _selectedDistrict,
      }).eq('id', userId);

      ref.invalidate(profileProvider);

      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil başarıyla güncellendi!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                  Color(0xFF24243E),
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
                  child: profileAsync.when(
                    data: (profile) {
                      if (!_isInitialized) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted && !_isInitialized) {
                            _populateFields(profile);
                            _isInitialized = true;
                            setState(() {});
                          }
                        });
                      }
                      return _buildProfileContent(profile);
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                          color: Colors.orangeAccent),
                    ),
                    error: (e, _) => Center(
                      child: Text('Hata: $e',
                          style: const TextStyle(color: Colors.white)),
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
              'Profilim',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              _isEditing ? Icons.close : Icons.edit,
              color: Colors.orangeAccent,
            ),
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
                if (!_isEditing) {
                  // Değişiklikleri geri al
                  final profile = ref.read(profileProvider).value;
                  _populateFields(profile);
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent(Map<String, dynamic>? profile) {
    final name = _nameController.text.isNotEmpty
        ? _nameController.text
        : (profile?['full_name'] ?? 'Kullanıcı');
    final email = Supabase.instance.client.auth.currentUser?.email ?? '';
    final avatarUrl = _localAvatarUrl ?? profile?['avatar_url'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Avatar
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                GestureDetector(
                  onTap: _pickAndUploadAvatar,
                  child: _isUploadingAvatar
                      ? Container(
                          width: 100,
                          height: 100,
                          decoration: const BoxDecoration(
                            color: Colors.orangeAccent,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          ),
                        )
                      : CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.orangeAccent,
                          backgroundImage: avatarUrl != null
                              ? NetworkImage(avatarUrl as String)
                              : null,
                          child: avatarUrl == null
                              ? Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: const TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                )
                              : null,
                        ),
                ),
                GestureDetector(
                  onTap: _pickAndUploadAvatar,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFF0F0C29), width: 2),
                    ),
                    child: const Icon(Icons.camera_alt,
                        color: Colors.white, size: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!_isEditing) ...[
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                email,
                style: const TextStyle(color: Colors.white54, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _userType == 'host' ? 'Ev Sahibi' : 'Ev Arayan',
                  style: const TextStyle(
                    color: Colors.orangeAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              _buildInfoCard(profile),
            ] else ...[
              const SizedBox(height: 24),
              _buildEditForm(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(Map<String, dynamic>? profile) {
    final items = <_InfoItem>[
      _InfoItem(Icons.person, 'Ad Soyad', profile?['full_name'] ?? '-'),
      _InfoItem(Icons.info_outline, 'Hakkında', profile?['bio'] ?? '-'),
      _InfoItem(Icons.wc, 'Cinsiyet', profile?['gender'] ?? '-'),
      _InfoItem(Icons.location_city, 'Şehir', profile?['city'] ?? '-'),
      _InfoItem(Icons.map, 'İlçe', profile?['district'] ?? '-'),
      _InfoItem(Icons.school, 'Üniversite', profile?['university'] ?? '-'),
      _InfoItem(Icons.account_balance, 'Kampüs', profile?['campus'] ?? '-'),
    ];

    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              children: [
                Icon(item.icon, color: Colors.orangeAccent, size: 22),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.label,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.value,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEditForm() {
    return Column(
      children: [
        _buildGlassField(
          controller: _nameController,
          label: 'Ad Soyad',
          icon: Icons.person,
          validator: (v) =>
              v == null || v.isEmpty ? 'Ad Soyad zorunludur' : null,
        ),
        _buildGlassField(
          controller: _bioController,
          label: 'Hakkında',
          icon: Icons.info_outline,
          maxLines: 3,
        ),
        _buildGlassDropdown(
          value: _selectedGender,
          hint: 'Cinsiyet',
          icon: Icons.wc,
          items: _genders,
          onChanged: (v) => setState(() => _selectedGender = v),
        ),
        _buildGlassDropdown(
          value: _selectedCity,
          hint: 'Şehir',
          icon: Icons.location_city,
          items: TurkishCities.cities,
          onChanged: (v) => setState(() {
            _selectedCity = v;
            _selectedDistrict = null;
          }),
        ),
        if (_selectedCity != null)
          _buildGlassDropdown(
            value: _selectedDistrict,
            hint: 'İlçe',
            icon: Icons.map,
            items: TurkishCities.districts[_selectedCity] ?? [],
            onChanged: (v) => setState(() => _selectedDistrict = v),
          ),
        _buildGlassSearchTile(
          value: _selectedUniversity,
          hint: 'Üniversite Seçin',
          icon: Icons.school,
          onTap: () async {
            final result = await _showFullUniversitySearchDialog(
              context,
              currentValue: _selectedUniversity,
            );
            if (result != null) {
              setState(() {
                _selectedUniversity = result;
                _selectedCampus = null;
              });
            }
          },
        ),
        if (_selectedUniversity != null)
          _buildGlassSearchTile(
            value: _selectedCampus,
            hint: 'Kampüs Seçin',
            icon: Icons.account_balance,
            onTap: () async {
              final result = await _showUniversitySearchDialog(
                context,
                items: UniversityData.getCampusNames(_selectedUniversity!),
                title: 'Kampüs Seç',
                hintText: 'Kampüs adı yazın...',
                currentValue: _selectedCampus,
              );
              if (result != null) {
                setState(() => _selectedCampus = result);
              }
            },
          ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveProfile,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              backgroundColor: Colors.orangeAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Text(
                    'Değişiklikleri Kaydet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildGlassField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            prefixIcon: Icon(icon, color: Colors.orangeAccent),
            border: InputBorder.none,
          ),
          validator: validator,
        ),
      ),
    );
  }

  Widget _buildGlassDropdown({
    required String? value,
    required String hint,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    // Eğer value items listesinde yoksa null yap (assertion error önlemi)
    final effectiveValue =
        (value != null && items.contains(value)) ? value : null;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: effectiveValue,
            hint: Row(
              children: [
                Icon(icon, color: Colors.orangeAccent),
                const SizedBox(width: 12),
                Text(hint,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6))),
              ],
            ),
            dropdownColor: const Color(0xFF302B63),
            icon:
                const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
            isExpanded: true,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            items: items
                .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  /// Üniversite/kampüs seçimi için arama dialogı açan tile
  Widget _buildGlassSearchTile({
    required String? value,
    required String hint,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: GlassContainer(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: Colors.orangeAccent, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value ?? hint,
                  style: TextStyle(
                    color: value != null
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.6),
                    fontSize: 16,
                  ),
                ),
              ),
              const Icon(Icons.search, color: Colors.white54, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// TurkishUniversities tam listesiyle üniversite arama dialogu
  Future<String?> _showFullUniversitySearchDialog(
    BuildContext ctx, {
    String? currentValue,
  }) async {
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
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            insetPadding: const EdgeInsets.symmetric(
                horizontal: 24, vertical: 40),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(dialogCtx).size.height * 0.75,
                minWidth: double.infinity,
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Üniversite Seç',
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
                        hintStyle:
                            const TextStyle(color: Colors.white38),
                        prefixIcon: const Icon(Icons.search,
                            color: Colors.orangeAccent),
                        filled: true,
                        fillColor:
                            Colors.white.withValues(alpha: 0.08),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (v) => setS(() => query = v),
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: filtered.isEmpty
                          ? const Center(
                              child: Padding(
                                padding:
                                    EdgeInsets.symmetric(vertical: 32),
                                child: Text('Sonuç bulunamadı',
                                    style: TextStyle(
                                        color: Colors.white54)),
                              ))
                          : ListView.builder(
                              shrinkWrap: true,
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
                                          color: Colors.white38,
                                          fontSize: 12)),
                                  trailing: isSel
                                      ? const Icon(Icons.check,
                                          color: Colors.orangeAccent,
                                          size: 18)
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
            ),
          );
        },
      ),
    );
  }

  /// Aranabilir liste dialogı (kampüs için kullanılıyor)
  Future<String?> _showUniversitySearchDialog(
    BuildContext ctx, {
    required List<String> items,
    required String title,
    required String hintText,
    String? currentValue,
  }) async {
    String query = '';
    return showDialog<String>(
      context: ctx,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setS) {
          final filtered = query.isEmpty
              ? items
              : items
                  .where((c) =>
                      c.toLowerCase().contains(query.toLowerCase()))
                  .toList();
          return Dialog(
            backgroundColor: const Color(0xFF1A1640),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            insetPadding: const EdgeInsets.symmetric(
                horizontal: 24, vertical: 40),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(dialogCtx).size.height * 0.75,
                minWidth: double.infinity,
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextField(
                      autofocus: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: hintText,
                        hintStyle:
                            const TextStyle(color: Colors.white38),
                        prefixIcon: const Icon(Icons.search,
                            color: Colors.orangeAccent),
                        filled: true,
                        fillColor:
                            Colors.white.withValues(alpha: 0.08),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (v) => setS(() => query = v),
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: filtered.isEmpty
                          ? const Center(
                              child: Padding(
                                padding:
                                    EdgeInsets.symmetric(vertical: 32),
                                child: Text('Sonuç bulunamadı',
                                    style: TextStyle(
                                        color: Colors.white54)),
                              ))
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: filtered.length,
                              itemBuilder: (_, i) {
                                final item = filtered[i];
                                final isSel = item == currentValue;
                                return ListTile(
                                  dense: true,
                                  title: Text(item,
                                      style: TextStyle(
                                        color: isSel
                                            ? Colors.orangeAccent
                                            : Colors.white,
                                        fontWeight: isSel
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      )),
                                  trailing: isSel
                                      ? const Icon(Icons.check,
                                          color: Colors.orangeAccent,
                                          size: 18)
                                      : null,
                                  onTap: () =>
                                      Navigator.of(dialogCtx).pop(item),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;

  _InfoItem(this.icon, this.label, this.value);
}
