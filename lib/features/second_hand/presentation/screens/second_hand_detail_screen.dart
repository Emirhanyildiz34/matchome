import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/second_hand_item_model.dart';
import '../providers/second_hand_provider.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../chat/data/chat_repository.dart';

class SecondHandDetailScreen extends ConsumerStatefulWidget {
  final SecondHandItemModel item;

  const SecondHandDetailScreen({super.key, required this.item});

  @override
  ConsumerState<SecondHandDetailScreen> createState() =>
      _SecondHandDetailScreenState();
}

class _SecondHandDetailScreenState
    extends ConsumerState<SecondHandDetailScreen> {
  late final PageController _pageController;
  int _currentPage = 0;

  SecondHandItemModel get item => widget.item;

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

  bool get _isOwner =>
      Supabase.instance.client.auth.currentUser?.id == item.sellerId;

  Future<void> _callPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _deleteItem() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1640),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('İlanı Sil',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('Bu ilanı silmek istediğinize emin misiniz?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(secondHandRepositoryProvider).deleteItem(item.id!);
        ref.invalidate(secondHandItemsProvider);
        ref.invalidate(mySecondHandItemsProvider);
        if (mounted) context.pop();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Silme hatası: $e'),
                backgroundColor: Colors.redAccent),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final catInfo = SecondHandItemModel.categories[item.category];
    final condLabel =
        SecondHandItemModel.conditions[item.condition] ?? item.condition;

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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildImageGallery(),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildPriceRow(),
                              const SizedBox(height: 12),
                              Text(
                                item.title,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  _buildBadge(
                                    label:
                                        '${catInfo?.emoji ?? '📦'} ${catInfo?.label ?? 'Diğer'}',
                                    color: Colors.tealAccent,
                                    bgColor: Colors.tealAccent
                                        .withValues(alpha: 0.12),
                                  ),
                                  if (item.subcategory != null &&
                                      item.subcategory!.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    _buildBadge(
                                      label: item.subcategory!,
                                      color: Colors.orangeAccent,
                                      bgColor: Colors.orangeAccent
                                          .withValues(alpha: 0.12),
                                    ),
                                  ],
                                  const SizedBox(width: 8),
                                  _buildBadge(
                                    label: condLabel,
                                    color: Colors.purpleAccent,
                                    bgColor: Colors.purpleAccent
                                        .withValues(alpha: 0.12),
                                  ),
                                ],
                              ),
                              if (item.locationLabel.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on,
                                        color: Colors.white54, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      item.locationLabel,
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 14),
                                    ),
                                  ],
                                ),
                              ],
                              if (item.description != null &&
                                  item.description!.isNotEmpty) ...[
                                const SizedBox(height: 20),
                                const Text(
                                  'Açıklama',
                                  style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5),
                                ),
                                const SizedBox(height: 8),
                                GlassContainer(
                                  padding: const EdgeInsets.all(14),
                                  child: Text(
                                    item.description!,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        height: 1.6),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 24),
                              _buildContactSection(),
                              if (_isOwner) ...[
                                const SizedBox(height: 16),
                                _buildOwnerActions(),
                              ],
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
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
          const Expanded(
            child: Text(
              '2. El Eşya',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
          ),
          if (_isOwner)
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'edit') {
                  context.push('/edit-second-hand', extra: item);
                } else if (v == 'delete') {
                  _deleteItem();
                }
              },
              color: const Color(0xFF302B63),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(children: [
                    Icon(Icons.edit_outlined, color: Colors.white70, size: 18),
                    SizedBox(width: 10),
                    Text('Düzenle', style: TextStyle(color: Colors.white70)),
                  ]),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [
                    Icon(Icons.delete_outline,
                        color: Colors.redAccent, size: 18),
                    SizedBox(width: 10),
                    Text('Sil', style: TextStyle(color: Colors.redAccent)),
                  ]),
                ),
              ],
              child: const Icon(Icons.more_vert, color: Colors.white),
            ),
        ],
      ),
    );
  }

  Widget _buildImageGallery() {
    if (item.imageUrls.isEmpty) {
      return Container(
        height: 260,
        color: Colors.white10,
        child: const Center(
          child:
              Icon(Icons.storefront_outlined, size: 80, color: Colors.white24),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 260,
          child: PageView.builder(
            controller: _pageController,
            itemCount: item.imageUrls.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => _openFullscreen(i),
              child: Image.network(
                item.imageUrls[i],
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.white10,
                  child: const Icon(Icons.broken_image,
                      color: Colors.white24, size: 40),
                ),
              ),
            ),
          ),
        ),
        if (item.imageUrls.length > 1)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(item.imageUrls.length, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentPage == i ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _currentPage == i
                        ? Colors.orangeAccent
                        : Colors.white24,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  void _openFullscreen(int initialIndex) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) => _FullscreenGallery(
          imageUrls: item.imageUrls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  Widget _buildPriceRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '${formatPrice(item.price)} ${currencySymbol(item.currency)}',
          style: const TextStyle(
              color: Colors.orangeAccent,
              fontSize: 28,
              fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildBadge({
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildContactSection() {
    if (_isOwner) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'İletişim',
          style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5),
        ),
        const SizedBox(height: 8),
        // Uygulama içi mesaj — her zaman göster
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () async {
              final currentUser = Supabase.instance.client.auth.currentUser;
              if (currentUser == null) return;
              try {
                final chatRepo = ChatRepository(Supabase.instance.client);
                final conversationId = await chatRepo.findOrCreateConversation(
                  hostId: item.sellerId,
                  listingType: 'second_hand',
                  listingId: item.id,
                  listingImageUrl:
                      item.imageUrls.isNotEmpty ? item.imageUrls[0] : null,
                  listingTitle: item.title,
                );
                if (!mounted) return;
                context.push(
                  '/chat/$conversationId',
                  extra: {
                    'otherUserName': 'Satıcı',
                    'listingTitle': item.title,
                  },
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Sohbet başlatılamadı: $e'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.chat_bubble_outline,
                color: Colors.white, size: 20),
            label: const Text(
              'Uygulama Üzerinden Mesaj Gönder',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ),
        // Numara izni varsa WhatsApp + Ara butonlarını göster
        if (item.showPhone && item.contactPhone != null) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final phone =
                        item.contactPhone!.replaceAll(RegExp(r'[^0-9+]'), '');
                    final uri = Uri.parse('https://wa.me/$phone');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon:
                      const Icon(Icons.message, color: Colors.white, size: 18),
                  label: const Text('WhatsApp',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _callPhone(item.contactPhone!),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.call, color: Colors.white, size: 18),
                  label: const Text('Ara',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildOwnerActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context.push('/edit-second-hand', extra: item),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.orangeAccent),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.edit_outlined,
                color: Colors.orangeAccent, size: 18),
            label: const Text('Düzenle',
                style: TextStyle(color: Colors.orangeAccent)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _deleteItem,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.redAccent),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.delete_outline,
                color: Colors.redAccent, size: 18),
            label: const Text('Sil', style: TextStyle(color: Colors.redAccent)),
          ),
        ),
      ],
    );
  }
}

class _FullscreenGallery extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const _FullscreenGallery(
      {required this.imageUrls, required this.initialIndex});

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
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            PageView.builder(
              controller: _ctrl,
              itemCount: widget.imageUrls.length,
              onPageChanged: (i) => setState(() => _current = i),
              itemBuilder: (_, i) => InteractiveViewer(
                child: Image.network(
                  widget.imageUrls[i],
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.broken_image,
                        color: Colors.white24, size: 60),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 22),
                ),
              ),
            ),
            if (widget.imageUrls.length > 1)
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.imageUrls.length, (i) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: _current == i ? 16 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _current == i ? Colors.white : Colors.white38,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
