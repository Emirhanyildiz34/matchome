import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/campus_announcement_model.dart';
import '../../data/models/scraped_announcement_model.dart';
import '../providers/campus_provider.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
import '../../../../core/constants/university_data.dart';
import '../../../../core/utils/distance_utils.dart';
import '../../../../core/widgets/glass_container.dart';
import 'add_campus_announcement_screen.dart';

class CampusScreen extends ConsumerStatefulWidget {
  final String university;
  final String? campus;
  final CampusData? campusData;

  const CampusScreen({
    super.key,
    required this.university,
    this.campus,
    this.campusData,
  });

  @override
  ConsumerState<CampusScreen> createState() => _CampusScreenState();
}

class _CampusScreenState extends ConsumerState<CampusScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Alt sekme çubuğu
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: Colors.orangeAccent.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(25),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            labelStyle:
                const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            unselectedLabelStyle:
                const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            tabs: const [
              Tab(text: '📢  Resmi Duyurular'),
              Tab(text: '👥  Topluluk'),
            ],
          ),
        ),
        // Sekme içerikleri
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _ScrapedTab(university: widget.university),
              _CommunityTab(
                university: widget.university,
                campus: widget.campus,
                campusData: widget.campusData,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Sekme 1: Resmi (Scraped) Duyurular
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _ScrapedTab extends ConsumerWidget {
  final String university;
  const _ScrapedTab({required this.university});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(scrapedAnnouncementsProvider(university));

    return asyncData.when(
      data: (items) {
        if (items.isEmpty) {
          return _buildEmpty(
            icon: Icons.school_outlined,
            title: 'Henüz resmi duyuru yok',
            subtitle:
                'Üniversitenizin resmi duyuruları otomatik olarak buraya gelecek.',
          );
        }
        return RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(scrapedAnnouncementsProvider(university)),
          color: Colors.orangeAccent,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            itemCount: items.length,
            itemBuilder: (_, i) => _ScrapedCard(item: items[i]),
          ),
        );
      },
      loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.orangeAccent)),
      error: (e, _) => _buildEmpty(
        icon: Icons.error_outline,
        title: 'Duyurular yüklenemedi',
        subtitle: '$e',
      ),
    );
  }
}

class _ScrapedCard extends StatelessWidget {
  final ScrapedAnnouncementModel item;
  const _ScrapedCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst satır: rozet + tarih
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified,
                          color: Colors.lightBlueAccent, size: 12),
                      SizedBox(width: 4),
                      Text(
                        'Resmi',
                        style: TextStyle(
                          color: Colors.lightBlueAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (item.publishedAt != null)
                  Text(
                    _formatDate(item.publishedAt!),
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            // Başlık
            Text(
              item.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            // İçerik / özet
            if ((item.summary ?? item.content) != null) ...[
              const SizedBox(height: 6),
              Text(
                item.summary ?? item.content!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
            // Detay linki
            if ((item.externalLink ?? item.sourceUrl) != null) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => _openLink(item.externalLink ?? item.sourceUrl!),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.orangeAccent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.open_in_new,
                          color: Colors.orangeAccent, size: 14),
                      SizedBox(width: 6),
                      Text(
                        'Detayı Gör',
                        style: TextStyle(
                          color: Colors.orangeAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Az önce';
    if (diff.inHours < 1) return '${diff.inMinutes} dk önce';
    if (diff.inDays < 1) return '${diff.inHours} sa önce';
    if (diff.inDays < 7) return '${diff.inDays} gün önce';
    return '${dt.day}.${dt.month}.${dt.year}';
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Sekme 2: Topluluk (Kullanıcı) Duyuruları
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _CommunityTab extends ConsumerWidget {
  final String university;
  final String? campus;
  final CampusData? campusData;

  const _CommunityTab({
    required this.university,
    this.campus,
    this.campusData,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final announcementsAsync = ref.watch(campusAnnouncementsProvider(
      (university: university, campus: campus),
    ));

    return Stack(
      children: [
        announcementsAsync.when(
          data: (items) {
            if (items.isEmpty) {
              return _buildEmpty(
                icon: Icons.campaign_outlined,
                title: 'Henüz topluluk duyurusu yok',
                subtitle: 'İlk duyuruyu sen paylaş!',
              );
            }
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(
                campusAnnouncementsProvider(
                    (university: university, campus: campus)),
              ),
              color: Colors.orangeAccent,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                itemCount: items.length,
                itemBuilder: (_, i) => _CommunityCard(
                  item: items[i],
                  campusData: campusData,
                  isMine: items[i].authorId == currentUserId,
                  onEdit: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AddCampusAnnouncementScreen(
                        university: university,
                        campus: campus,
                        existingAnnouncement: items[i],
                      ),
                    ),
                  ),
                  onDelete: () => _deleteAnnouncement(context, ref, items[i]),
                ),
              ),
            );
          },
          loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.orangeAccent)),
          error: (e, _) => _buildEmpty(
            icon: Icons.error_outline,
            title: 'Duyurular yüklenemedi',
            subtitle: '$e',
          ),
        ),
        // Duyuru ekleme FAB
        Positioned(
          bottom: 20,
          right: 16,
          child: FloatingActionButton.extended(
            heroTag: 'campus_fab',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AddCampusAnnouncementScreen(
                  university: university,
                  campus: campus,
                ),
              ),
            ),
            backgroundColor: Colors.orangeAccent,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Duyuru Paylaş',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _deleteAnnouncement(
    BuildContext context,
    WidgetRef ref,
    CampusAnnouncementModel item,
  ) async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Duyuru silinsin mi?'),
            content: const Text(
              'Bu işlem duyuruyu topluluk akışından kaldırır.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Vazgeç'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Sil'),
              ),
            ],
          ),
        ) ??
        false;

    if (!ok || item.id == null) return;

    await ref.read(campusRepositoryProvider).deactivateAnnouncement(item.id!);
    ref.invalidate(campusAnnouncementsProvider(
      (university: university, campus: campus),
    ));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Duyuru kaldırıldı.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
    }
  }
}

class _CommunityCard extends ConsumerStatefulWidget {
  final CampusAnnouncementModel item;
  final CampusData? campusData;
  final bool isMine;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CommunityCard({
    required this.item,
    this.campusData,
    required this.isMine,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  ConsumerState<_CommunityCard> createState() => _CommunityCardState();
}

class _CommunityCardState extends ConsumerState<_CommunityCard> {
  bool _isLoading = false;

  void _contactOwner() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(chatRepositoryProvider);
      final conversationId = await repo.findOrCreateConversation(
        hostId: widget.item.authorId,
        listingType: 'campus_announcement',
        listingId: widget.item.id,
        listingTitle: widget.item.title,
      );
      if (mounted) {
        context.push('/chat/$conversationId',
            extra: {'otherUserName': widget.item.authorName});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _markAsResolved() async {
    final act = widget.item.category == 'kayip_esya'
        ? 'Bulundu olarak işaretlesin mi?'
        : 'İlan kapatılsın mı?';
    final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text('Emin misiniz?'),
              content: Text(act),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Vazgeç')),
                TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text('Evet')),
              ],
            ));
    if (ok != true) return;

    setState(() => _isLoading = true);
    try {
      if (widget.item.id != null) {
        await ref
            .read(campusRepositoryProvider)
            .markAsResolved(widget.item.id!);
        ref.invalidate(campusAnnouncementsProvider(
            (university: widget.item.university, campus: widget.item.campus)));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Hata: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyToEvent() async {
    final contactController = TextEditingController();
    final ok = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) {
          return Padding(
              padding:
                  EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Color(0xFF24243E),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Etkinliğe Katıl',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    const Text(
                        'İletişim bilgilerini gir (Telefon No veya IG Kullanıcı Adı vb.)',
                        style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: contactController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'İletişim bilgisi',
                        hintStyle: TextStyle(color: Colors.white38),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Başvuruyu Gönder'),
                      ),
                    )
                  ],
                ),
              ));
        });

    if (ok == true && contactController.text.trim().isNotEmpty) {
      setState(() => _isLoading = true);
      try {
        if (widget.item.id != null) {
          await ref.read(campusRepositoryProvider).applyToEvent(
              announcementId: widget.item.id!,
              contactInfo: contactController.text.trim());
          if (mounted)
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Başvurunuz iletildi!')));
        }
      } catch (e) {
        bool isUniqueViolation = e.toString().contains('duplicate key value') ||
            e.toString().contains('unique');
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(isUniqueViolation
                  ? 'Bu etkinliğe zaten başvurdunuz.'
                  : 'Hata: $e')));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final catInfo = CampusAnnouncementModel.categories[item.category] ??
        {'label': item.category, 'emoji': '📢'};

    String? distanceText;
    if (widget.campusData != null &&
        item.latitude != null &&
        item.longitude != null) {
      final km = DistanceUtils.haversineKm(
        widget.campusData!.latitude,
        widget.campusData!.longitude,
        item.latitude!,
        item.longitude!,
      );
      distanceText = DistanceUtils.formatDistance(km);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst satır: kategori + kapsam rozeti + tarih
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${catInfo['emoji']} ${catInfo['label']}',
                    style: const TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (item.visibilityScope == 'university') ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.blueAccent.withValues(alpha: 0.4)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('🌐', style: TextStyle(fontSize: 10)),
                        SizedBox(width: 3),
                        Text(
                          'Tüm Üniversite',
                          style: TextStyle(
                            color: Colors.lightBlueAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (item.isResolved) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.category == 'kayip_esya'
                          ? '✅ Bulundu'
                          : '🔒 Kapandı',
                      style: const TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  )
                ],
                const Spacer(),
                if (widget.isMine)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_horiz,
                        color: Colors.white54, size: 18),
                    onSelected: (value) {
                      if (value == 'edit') widget.onEdit();
                      if (value == 'delete') widget.onDelete();
                      if (value == 'resolve') _markAsResolved();
                    },
                    itemBuilder: (context) => [
                      if (!item.isResolved)
                        PopupMenuItem(
                            value: 'resolve',
                            child: Text(item.category == 'kayip_esya'
                                ? 'Bulundu İşaretle'
                                : 'Kapat')),
                      const PopupMenuItem(
                          value: 'edit', child: Text('Düzenle')),
                      const PopupMenuItem(value: 'delete', child: Text('Sil')),
                    ],
                  ),
                if (item.createdAt != null && !widget.isMine)
                  Text(
                    _formatDate(item.createdAt!),
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            // Başlık
            Text(
              item.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (item.content != null && item.content!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                item.content!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
            if (item.startDate != null ||
                item.endDate != null ||
                item.eventDate != null) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (item.startDate != null)
                    _buildDateChip(
                      icon: Icons.play_arrow,
                      label: 'Başlangıç ${_formatShortDate(item.startDate!)}',
                      color: Colors.lightGreenAccent,
                    ),
                  if (item.endDate != null)
                    _buildDateChip(
                      icon: Icons.stop,
                      label: 'Bitiş ${_formatShortDate(item.endDate!)}',
                      color: Colors.amberAccent,
                    ),
                  if (item.eventDate != null)
                    _buildDateChip(
                      icon: Icons.event,
                      label: 'Etkinlik ${_formatShortDate(item.eventDate!)}',
                      color: Colors.lightBlueAccent,
                    ),
                ],
              ),
            ],
            // Kayıp eşya özel detaylar
            if (item.category == 'kayip_esya') ...[
              const SizedBox(height: 8),
              if (item.lastSeenLocation != null &&
                  item.lastSeenLocation!.isNotEmpty)
                _buildInfoRow(Icons.map, 'Konum: ${item.lastSeenLocation}'),
              const SizedBox(height: 4),
              if (item.lastSeenDate != null)
                _buildInfoRow(Icons.access_time,
                    'Son Görülme: ${_formatShortDate(item.lastSeenDate!)}'),
            ],
            // Etkinlik özel detaylar
            if (item.category == 'etkinlik') ...[
              const SizedBox(height: 8),
              if (item.maxParticipants != null)
                _buildInfoRow(
                    Icons.people, 'Kontenjan: ${item.maxParticipants} Kişi'),
              if (item.participationFee != null &&
                  item.participationFee!.isNotEmpty) ...[
                const SizedBox(height: 4),
                _buildInfoRow(
                    Icons.monetization_on, 'Ücret: ${item.participationFee}'),
              ]
            ],
            // Konum + mesafe (genel)
            if (item.addressText != null && item.addressText!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on,
                      color: Colors.white38, size: 13),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      item.addressText!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ),
                  if (distanceText != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.school,
                              color: Colors.greenAccent, size: 11),
                          const SizedBox(width: 3),
                          Text(
                            'Kampüse $distanceText',
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
            // Alt Satır (Yazar + Butonlar)
            const SizedBox(height: 14),
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.orangeAccent,
                  backgroundImage: item.authorAvatarUrl != null
                      ? NetworkImage(item.authorAvatarUrl!)
                      : null,
                  child: item.authorAvatarUrl == null
                      ? Text(
                          (item.authorName?.isNotEmpty == true)
                              ? item.authorName![0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Text(
                  item.authorName ?? 'Kullanıcı',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
                if (item.campus != null && item.campus!.isNotEmpty) ...[
                  const Text(' • ',
                      style: TextStyle(color: Colors.white38, fontSize: 12)),
                  Expanded(
                    child: Text(
                      item.campus!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ),
                ] else
                  const Spacer(),

                // Aksiyon butonları (eğer benim duyurum değilse)
                if (!widget.isMine && _isLoading)
                  const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2))),
                if (!widget.isMine && !item.isResolved) ...[
                  if (item.category == 'etkinlik')
                    GestureDetector(
                      onTap: _applyToEvent,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('Katıl',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  GestureDetector(
                    onTap: _contactOwner,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        border: Border.all(
                            color: Colors.orangeAccent.withValues(alpha: 0.5)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.chat_bubble_outline,
                              color: Colors.orangeAccent, size: 12),
                          SizedBox(width: 4),
                          Text('İletişim',
                              style: TextStyle(
                                  color: Colors.orangeAccent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  )
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(children: [
      Icon(icon, color: Colors.white54, size: 14),
      const SizedBox(width: 6),
      Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13)),
    ]);
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Az önce';
    if (diff.inHours < 1) return '${diff.inMinutes} dk önce';
    if (diff.inDays < 1) return '${diff.inHours} sa önce';
    if (diff.inDays < 7) return '${diff.inDays} gün önce';
    return '${dt.day}.${dt.month}.${dt.year}';
  }

  String _formatShortDate(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    return '$day.$month.${dt.year}';
  }

  Widget _buildDateChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Ortak yardımcı
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Widget _buildEmpty({
  required IconData icon,
  required String title,
  required String subtitle,
}) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: GlassContainer(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.orangeAccent),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    ),
  );
}
