import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/content_filter.dart';
import '../../data/models/campus_announcement_model.dart';
import '../providers/campus_provider.dart';
import '../../../../core/widgets/glass_container.dart';

class AddCampusAnnouncementScreen extends ConsumerStatefulWidget {
  final String university;
  final String? campus;
  final CampusAnnouncementModel? existingAnnouncement;

  const AddCampusAnnouncementScreen({
    super.key,
    required this.university,
    this.campus,
    this.existingAnnouncement,
  });

  @override
  ConsumerState<AddCampusAnnouncementScreen> createState() =>
      _AddCampusAnnouncementScreenState();
}

class _AddCampusAnnouncementScreenState
    extends ConsumerState<AddCampusAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _addressController = TextEditingController();
  final _maxParticipantsController = TextEditingController();
  final _participationFeeController = TextEditingController();
  final _lastSeenLocationController = TextEditingController();

  String _selectedCategory = 'genel';
  String _visibilityScope = 'campus';
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _eventDate;
  DateTime? _lastSeenDate;
  bool _isSaving = false;

  bool get _isEditing => widget.existingAnnouncement != null;

  @override
  void initState() {
    super.initState();

    // Campus bilinmiyorsa üniversite geneli kapsam varsayılan olsun
    if (widget.campus == null || widget.campus!.isEmpty) {
      _visibilityScope = 'university';
    }

    final existing = widget.existingAnnouncement;
    if (existing != null) {
      _titleController.text = existing.title;
      _contentController.text = existing.content ?? '';
      _addressController.text = existing.addressText ?? '';
      _selectedCategory = existing.category;
      _visibilityScope = existing.visibilityScope;
      _startDate = existing.startDate;
      _endDate = existing.endDate;
      _eventDate = existing.eventDate;
      _lastSeenDate = existing.lastSeenDate;
      if (existing.maxParticipants != null) {
        _maxParticipantsController.text = existing.maxParticipants.toString();
      }
      _participationFeeController.text = existing.participationFee ?? '';
      _lastSeenLocationController.text = existing.lastSeenLocation ?? '';
    } else {
      final now = DateTime.now();
      _startDate = DateTime(now.year, now.month, now.day);
      _endDate = DateTime(now.year, now.month, now.day + 7);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _addressController.dispose();
    _maxParticipantsController.dispose();
    _participationFeeController.dispose();
    _lastSeenLocationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final address = _addressController.text.trim();
    final startDate = _startDate;
    final endDate = _endDate;
    final eventDate = _eventDate;

    if (startDate == null || endDate == null) {
      _showError('Lütfen başlangıç ve bitiş tarihini seçin.');
      return;
    }
    if (endDate.isBefore(startDate)) {
      _showError('Bitiş tarihi başlangıç tarihinden önce olamaz.');
      return;
    }
    if (_selectedCategory == 'etkinlik' && eventDate == null) {
      _showError('Etkinlik kategorisinde etkinlik tarihi zorunludur.');
      return;
    }
    if (_selectedCategory == 'kayip_esya' && _lastSeenDate == null) {
      _showError('Kayıp eşya ilanlarında son görülme tarihi zorunludur.');
      return;
    }

    final blockedWords = ContentFilter.findBlockedWords(
      '$title $content $address ${_lastSeenLocationController.text}',
    );
    if (blockedWords.isNotEmpty) {
      _showError('Duyuruda uygunsuz/argo içerik kullanılamaz.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final announcement = CampusAnnouncementModel(
        id: widget.existingAnnouncement?.id,
        authorId: user.id,
        university: widget.university,
        campus: widget.campus,
        visibilityScope: _visibilityScope,
        title: title,
        content: content.isEmpty ? null : content,
        category: _selectedCategory,
        startDate: startDate,
        endDate: endDate,
        eventDate: eventDate,
        addressText: address.isEmpty ? null : address,
        maxParticipants: _selectedCategory == 'etkinlik'
            ? int.tryParse(_maxParticipantsController.text.trim())
            : null,
        participationFee: _selectedCategory == 'etkinlik' &&
                _participationFeeController.text.trim().isNotEmpty
            ? _participationFeeController.text.trim()
            : null,
        lastSeenLocation: _selectedCategory == 'kayip_esya' &&
                _lastSeenLocationController.text.trim().isNotEmpty
            ? _lastSeenLocationController.text.trim()
            : null,
        lastSeenDate: _selectedCategory == 'kayip_esya' ? _lastSeenDate : null,
      );

      final repository = ref.read(campusRepositoryProvider);
      if (_isEditing) {
        await repository.updateAnnouncement(announcement);
      } else {
        await repository.createAnnouncement(announcement);
      }

      ref.invalidate(campusAnnouncementsProvider((
        university: widget.university,
        campus: widget.campus,
      )));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(_isEditing ? 'Duyuru güncellendi!' : 'Duyuru yayınlandı!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
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
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
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
                // App bar
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios,
                            color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Expanded(
                        child: Text(
                          'Topluluk Duyurusu',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Üniversite bilgisi
                          GlassContainer(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                const Icon(Icons.school,
                                    color: Colors.orangeAccent, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.university,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14),
                                      ),
                                      if (widget.campus != null)
                                        Text(
                                          widget.campus!,
                                          style: const TextStyle(
                                              color: Colors.white54,
                                              fontSize: 12),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Kategori seçimi
                          _buildLabel('Kategori'),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 42,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: CampusAnnouncementModel
                                  .categories.entries
                                  .map((e) {
                                final isSelected = _selectedCategory == e.key;
                                return GestureDetector(
                                  onTap: () =>
                                      setState(() => _selectedCategory = e.key),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.orangeAccent
                                          : Colors.white
                                              .withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.orangeAccent
                                            : Colors.white
                                                .withValues(alpha: 0.2),
                                      ),
                                    ),
                                    child: Text(
                                      '${e.value['emoji']} ${e.value['label']}',
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.white70,
                                        fontSize: 12,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Görünürlük kapsamı
                          _buildLabel('Duyuru Kapsamı'),
                          const SizedBox(height: 8),
                          _buildVisibilityScopeSelector(),
                          const SizedBox(height: 20),
                          // Başlık
                          _buildLabel('Başlık *'),
                          const SizedBox(height: 8),
                          _buildField(
                            controller: _titleController,
                            hint: 'Duyuru başlığını girin...',
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Başlık zorunludur'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          // İçerik
                          _buildLabel('Açıklama'),
                          const SizedBox(height: 8),
                          _buildField(
                            controller: _contentController,
                            hint: 'Duyurunuzu detaylandırın...',
                            maxLines: 5,
                          ),
                          const SizedBox(height: 16),
                          // Başlangıç / Bitiş / Etkinlik tarihi
                          _buildLabel('Yayın Aralığı *'),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDatePickerTile(
                                  label: 'Başlangıç',
                                  value: _startDate,
                                  onPick: (d) => setState(() => _startDate = d),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildDatePickerTile(
                                  label: 'Bitiş',
                                  value: _endDate,
                                  onPick: (d) => setState(() => _endDate = d),
                                ),
                              ),
                            ],
                          ),
                          if (_selectedCategory == 'etkinlik') ...[
                            const SizedBox(height: 12),
                            _buildDatePickerTile(
                              label: 'Etkinlik Tarihi *',
                              value: _eventDate,
                              onPick: (d) => setState(() => _eventDate = d),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildLabel('Katılımcı Sınırı'),
                                      const SizedBox(height: 8),
                                      _buildField(
                                        controller: _maxParticipantsController,
                                        hint: 'Örn: 50',
                                        prefixIcon: Icons.people_outline,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildLabel('Ücret'),
                                      const SizedBox(height: 8),
                                      _buildField(
                                        controller: _participationFeeController,
                                        hint: 'Örn: Ücretsiz, 50 TL',
                                        prefixIcon: Icons.attach_money,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (_selectedCategory == 'kayip_esya') ...[
                            const SizedBox(height: 16),
                            _buildLabel('Kaybolan Yer / Son Görülme *'),
                            const SizedBox(height: 8),
                            _buildField(
                              controller: _lastSeenLocationController,
                              hint: 'Örn: Ek Bina Kantini...',
                              prefixIcon: Icons.location_on_outlined,
                            ),
                            const SizedBox(height: 12),
                            _buildDatePickerTile(
                              label: 'Son Görülme Tarihi *',
                              value: _lastSeenDate,
                              onPick: (d) => setState(() => _lastSeenDate = d),
                            ),
                          ],
                          const SizedBox(height: 16),
                          // Konum/adres
                          _buildLabel('Konum / Adres (isteğe bağlı)'),
                          const SizedBox(height: 8),
                          _buildField(
                            controller: _addressController,
                            hint: 'Örn: Kütüphane önü, Ek Bina B Blok...',
                            prefixIcon: Icons.location_on_outlined,
                          ),
                          const SizedBox(height: 32),
                          // Kaydet butonu
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _save,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orangeAccent,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2),
                                    )
                                  : Text(
                                      _isEditing
                                          ? 'Duyuruyu Güncelle'
                                          : 'Duyuruyu Yayınla',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 24),
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
          color: Colors.white.withValues(alpha: 0.7),
          fontSize: 13,
          fontWeight: FontWeight.w500),
    );
  }

  Widget _buildVisibilityScopeSelector() {
    final options = [
      (
        value: 'campus',
        emoji: '🏫',
        label: 'Sadece bu kampüs',
        sub: widget.campus ?? 'Kampüsünüz',
      ),
      (
        value: 'university',
        emoji: '🌐',
        label: 'Tüm üniversite',
        sub: widget.university,
      ),
    ];

    return Row(
      children: options.map((opt) {
        final isSelected = _visibilityScope == opt.value;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _visibilityScope = opt.value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(
                right: opt.value == 'campus' ? 8 : 0,
              ),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.orangeAccent.withValues(alpha: 0.18)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? Colors.orangeAccent
                      : Colors.white.withValues(alpha: 0.15),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  Text(opt.emoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(height: 4),
                  Text(
                    opt.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected ? Colors.orangeAccent : Colors.white70,
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    opt.sub,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white38, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    IconData? prefixIcon,
    String? Function(String?)? validator,
  }) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white38),
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, color: Colors.white38, size: 20)
              : null,
          border: InputBorder.none,
          contentPadding: prefixIcon != null
              ? const EdgeInsets.symmetric(vertical: 14)
              : const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildDatePickerTile({
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime> onPick,
  }) {
    return GestureDetector(
      onTap: () async {
        final picked = await _pickDate(value);
        if (picked != null) {
          onPick(picked);
        }
      },
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.calendar_today,
                color: Colors.orangeAccent, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value != null ? _formatDate(value) : 'Tarih seç',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<DateTime?> _pickDate(DateTime? initial) async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 1, 1, 1);
    final lastDate = DateTime(now.year + 3, 12, 31);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Tarih Seç',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.orangeAccent,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return null;
    return DateTime(picked.year, picked.month, picked.day);
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }
}
