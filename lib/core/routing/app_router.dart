import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/profile_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/discover/presentation/screens/discover_screen.dart';
import '../../features/listings/presentation/screens/add_listing_screen.dart';
import '../../features/listings/presentation/screens/my_listings_screen.dart';
import '../../features/listings/presentation/screens/listing_detail_screen.dart';
import '../../features/listings/presentation/screens/favorites_screen.dart';
import '../../features/listings/data/models/listing_model.dart';
import '../../features/chat/presentation/screens/conversations_screen.dart';
import '../../features/chat/presentation/screens/chat_screen.dart';
import '../../features/second_hand/presentation/screens/add_second_hand_screen.dart';
import '../../features/second_hand/presentation/screens/second_hand_detail_screen.dart';
import '../../features/second_hand/data/models/second_hand_item_model.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  errorBuilder: (context, state) {
    final uri = state.uri;

    // OAuth callback deep link'i route olarak çözülmeyebilir.
    // Bu durumda login'e geri dönerek Supabase'in oturum işlemesini bekliyoruz.
    if (uri.scheme == 'io.supabase.matchhome' && uri.host == 'login-callback') {
      return const LoginScreen();
    }

    return const LoginScreen();
  },
  redirect: (context, state) async {
    final session = Supabase.instance.client.auth.currentSession;
    final isLoggedIn = session != null;
    final currentPath = state.matchedLocation;

    // Giriş yapılmamışsa her zaman login'e yönlendir
    if (!isLoggedIn && currentPath != '/login') {
      return '/login';
    }

    // Giriş yapılmışsa ve login sayfasındaysa, onboarding kontrolü yap
    if (isLoggedIn && currentPath == '/login') {
      // Kişilik testi tamamlanmış mı kontrol et
      try {
        final userId = session.user.id;
        final result = await Supabase.instance.client
            .from('personality_results')
            .select('profile_id')
            .eq('profile_id', userId)
            .maybeSingle();

        if (result != null) {
          // Onboarding tamamlanmış, discover'a git
          return '/discover';
        } else {
          // Onboarding tamamlanmamış
          return '/onboarding';
        }
      } catch (_) {
        // Hata durumunda onboarding'e yönlendir
        return '/onboarding';
      }
    }

    return null; // Normal akışa devam et
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/discover',
      builder: (context, state) => const DiscoverScreen(),
    ),
    GoRoute(
      path: '/add-listing',
      builder: (context, state) => const AddListingScreen(),
    ),
    GoRoute(
      path: '/edit-listing',
      builder: (context, state) {
        final listing = state.extra as ListingModel?;
        return AddListingScreen(existingListing: listing);
      },
    ),
    GoRoute(
      path: '/listing-detail',
      builder: (context, state) {
        final listing =
            state.extra is ListingModel ? state.extra as ListingModel : null;
        if (listing == null) {
          // Deep link veya geçersiz erişim — ana sayfaya yönlendir
          return const DiscoverScreen();
        }
        return ListingDetailScreen(listing: listing);
      },
    ),
    GoRoute(
      path: '/my-listings',
      builder: (context, state) => const MyListingsScreen(),
    ),
    GoRoute(
      path: '/favorites',
      builder: (context, state) => const FavoritesScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/conversations',
      builder: (context, state) => const ConversationsScreen(),
    ),
    GoRoute(
      path: '/chat/:conversationId',
      builder: (context, state) {
        final conversationId = state.pathParameters['conversationId']!;
        final extra = state.extra as Map<String, dynamic>?;
        return ChatScreen(
          conversationId: conversationId,
          otherUserName: extra?['otherUserName'] as String? ?? 'Kullanıcı',
          listingTitle: extra?['listingTitle'] as String?,
        );
      },
    ),
    GoRoute(
      path: '/add-second-hand',
      builder: (context, state) => const AddSecondHandScreen(),
    ),
    GoRoute(
      path: '/edit-second-hand',
      builder: (context, state) {
        final item = state.extra as SecondHandItemModel?;
        return AddSecondHandScreen(existingItem: item);
      },
    ),
    GoRoute(
      path: '/second-hand-detail',
      builder: (context, state) {
        final item = state.extra is SecondHandItemModel
            ? state.extra as SecondHandItemModel
            : null;
        if (item == null) {
          return const DiscoverScreen();
        }
        return SecondHandDetailScreen(item: item);
      },
    ),
  ],
);
