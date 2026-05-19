import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/conversation_model.dart';
import '../providers/chat_provider.dart';
import '../../../../core/widgets/glass_container.dart';

class ConversationsScreen extends ConsumerStatefulWidget {
  const ConversationsScreen({super.key});

  @override
  ConsumerState<ConversationsScreen> createState() =>
      _ConversationsScreenState();
}

class _ConversationsScreenState extends ConsumerState<ConversationsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String _dateFilter = 'all'; // 'all', 'today', 'week', 'month'

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

  List<ConversationModel> _filterByDate(List<ConversationModel> convs) {
    if (_dateFilter == 'all') return convs;
    final now = DateTime.now();
    return convs.where((c) {
      final dt = c.lastMessageAt;
      switch (_dateFilter) {
        case 'today':
          return dt.year == now.year &&
              dt.month == now.month &&
              dt.day == now.day;
        case 'week':
          return now.difference(dt).inDays < 7;
        case 'month':
          return dt.year == now.year && dt.month == now.month;
        default:
          return true;
      }
    }).toList();
  }

  Future<void> _deleteConversation(ConversationModel conv) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1640),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Sohbeti Sil',
          style:
              TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Bu sohbeti silmek istediğinize emin misiniz? Tüm mesajlar silinecek.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal',
                style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(chatRepositoryProvider).deleteConversation(conv.id);
        ref.invalidate(conversationsProvider);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sohbet silinemedi: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  void _showDateFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1640),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        final options = [
          ('all', 'Tümü', Icons.all_inclusive),
          ('today', 'Bugün', Icons.today),
          ('week', 'Bu Hafta', Icons.date_range),
          ('month', 'Bu Ay', Icons.calendar_month),
        ];
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white30,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Tarih Filtrele',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...options.map((opt) => StatefulBuilder(
                    builder: (context, setSheetState) => ListTile(
                      leading: Icon(opt.$3,
                          color: _dateFilter == opt.$1
                              ? Colors.orangeAccent
                              : Colors.white70),
                      title: Text(
                        opt.$2,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: _dateFilter == opt.$1
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      trailing: _dateFilter == opt.$1
                          ? const Icon(Icons.check_circle,
                              color: Colors.orangeAccent)
                          : null,
                      onTap: () {
                        setState(() => _dateFilter = opt.$1);
                        Navigator.pop(ctx);
                      },
                    ),
                  )),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final conversationsAsync = ref.watch(conversationsProvider);
    final currentUserId =
        Supabase.instance.client.auth.currentUser?.id ?? '';

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
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                _buildTabBar(),
                Expanded(
                  child: conversationsAsync.when(
                    data: (conversations) {
                      final listingConvs = _filterByDate(
                        conversations
                            .where((c) => c.listingType == 'listing')
                            .toList(),
                      );
                      final secondHandConvs = _filterByDate(
                        conversations
                            .where((c) => c.listingType == 'second_hand')
                            .toList(),
                      );
                      return TabBarView(
                        controller: _tabController,
                        children: [
                          _buildList(context, listingConvs, currentUserId),
                          _buildList(
                              context, secondHandConvs, currentUserId),
                        ],
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                          color: Colors.orangeAccent),
                    ),
                    error: (e, _) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.redAccent, size: 48),
                          const SizedBox(height: 12),
                          const Text(
                            'Sohbetler yüklenemedi',
                            style: TextStyle(
                                color: Colors.white, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () =>
                                ref.refresh(conversationsProvider),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orangeAccent),
                            child: const Text('Tekrar Dene',
                                style: TextStyle(color: Colors.white)),
                          ),
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

  Widget _buildHeader(BuildContext context) {
    final isFiltered = _dateFilter != 'all';
    final filterLabels = {
      'all': 'Tümü',
      'today': 'Bugün',
      'week': 'Bu Hafta',
      'month': 'Bu Ay',
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          const Expanded(
            child: Text(
              'Mesajlarım',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
            ),
          ),
          GestureDetector(
            onTap: _showDateFilterSheet,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: isFiltered
                    ? Colors.orangeAccent
                    : Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isFiltered ? Colors.orangeAccent : Colors.white30,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color:
                        isFiltered ? Colors.black87 : Colors.white70,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    filterLabels[_dateFilter] ?? 'Tümü',
                    style: TextStyle(
                      color:
                          isFiltered ? Colors.black87 : Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(30),
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: Colors.orangeAccent,
            borderRadius: BorderRadius.circular(30),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 14),
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: '🏠  Ev İlanları'),
            Tab(text: '🛍️  Elden Ele'),
          ],
        ),
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    List<ConversationModel> conversations,
    String currentUserId,
  ) {
    if (conversations.isEmpty) {
      return _buildEmpty();
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: conversations.length,
      itemBuilder: (context, index) {
        final conv = conversations[index];
        return _buildTile(context, conv, currentUserId);
      },
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline,
                size: 80, color: Colors.white.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              'Henüz mesajınız yok',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'İlan detay sayfasındaki mesaj butonuna basarak bir sohbet başlatabilirsiniz.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile(
    BuildContext context,
    ConversationModel conv,
    String currentUserId,
  ) {
    final otherName = conv.otherUserName(currentUserId);
    final timeStr = _formatTime(conv.lastMessageAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: Key(conv.id),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) => _confirmDelete(),
        onDismissed: (_) async {
          try {
            await ref
                .read(chatRepositoryProvider)
                .deleteConversation(conv.id);
            ref.invalidate(conversationsProvider);
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Sohbet silinemedi: $e'),
                  backgroundColor: Colors.redAccent,
                ),
              );
            }
          }
        },
        background: Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.redAccent.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.delete_outline, color: Colors.white, size: 26),
              SizedBox(height: 4),
              Text('Sil',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        child: GestureDetector(
          onTap: () => context.push(
            '/chat/${conv.id}',
            extra: {
              'otherUserName': otherName,
              'listingTitle': conv.listingTitle,
            },
          ),
          onLongPress: () => _deleteConversation(conv),
          child: GlassContainer(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Avatar: ilan görseli
                _buildAvatar(conv),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              otherName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            timeStr,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      // İlan başlığı
                      if (conv.listingTitle != null &&
                          conv.listingTitle!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          conv.listingTitle!,
                          style: const TextStyle(
                            color: Colors.orangeAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      // Son mesaj
                      if (conv.lastMessage != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          conv.lastMessage!,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, color: Colors.white38),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1640),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Sohbeti Sil',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'Bu sohbeti silmek istediğinize emin misiniz?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal',
                style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(ConversationModel conv) {
    if (conv.listingImageUrl != null && conv.listingImageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          conv.listingImageUrl!,
          width: 54,
          height: 54,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFallbackAvatar(conv),
        ),
      );
    }
    return _buildFallbackAvatar(conv);
  }

  Widget _buildFallbackAvatar(ConversationModel conv) {
    final isSecondHand = conv.listingType == 'second_hand';
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: isSecondHand
            ? Colors.purpleAccent.withValues(alpha: 0.2)
            : Colors.orangeAccent.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSecondHand ? Colors.purpleAccent : Colors.orangeAccent,
          width: 1,
        ),
      ),
      child: Icon(
        isSecondHand ? Icons.storefront_outlined : Icons.home_outlined,
        color: isSecondHand ? Colors.purpleAccent : Colors.orangeAccent,
        size: 26,
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'şimdi';
    if (diff.inMinutes < 60) return '${diff.inMinutes}d önce';
    if (diff.inHours < 24) return '${diff.inHours}s önce';
    if (diff.inDays < 7) return '${diff.inDays}g önce';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
