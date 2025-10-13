import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:yabai_app/core/network/api_client.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/core/providers/theme_provider.dart';
import 'package:yabai_app/features/auth/data/repositories/auth_repository.dart';
import 'package:yabai_app/features/auth/providers/auth_session_provider.dart';
import 'package:yabai_app/features/auth/providers/login_form_provider.dart';
import 'package:yabai_app/features/auth/presentation/pages/login_page.dart';
import 'package:yabai_app/features/home/data/models/announcement_model.dart';
import 'package:yabai_app/features/home/data/repositories/announcement_repository.dart';
import 'package:yabai_app/features/home/data/repositories/post_repository.dart';
import 'package:yabai_app/features/home/data/repositories/project_statistics_repository.dart';
import 'package:yabai_app/features/home/presentation/pages/announcement_detail_page.dart';
import 'package:yabai_app/features/home/presentation/pages/create_post_page.dart';
import 'package:yabai_app/features/home/presentation/pages/home_page.dart';
import 'package:yabai_app/features/home/providers/create_post_provider.dart';
import 'package:yabai_app/features/home/providers/home_announcements_provider.dart';
import 'package:yabai_app/features/home/providers/project_statistics_provider.dart';

class YabaiApp extends StatefulWidget {
  const YabaiApp({super.key});

  @override
  State<YabaiApp> createState() => _YabaiAppState();
}

class _YabaiAppState extends State<YabaiApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = GoRouter(
      initialLocation: LoginPage.routePath,
      routes: [
        GoRoute(
          path: LoginPage.routePath,
          name: LoginPage.routeName,
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: HomePage.routePath,
          name: HomePage.routeName,
          builder: (context, state) {
            return MultiProvider(
              providers: [
                ChangeNotifierProvider(
                  create: (context) => HomeAnnouncementsProvider(
                    context.read<AnnouncementRepository>(),
                  )..loadInitial(),
                ),
                ChangeNotifierProvider(
                  create: (context) => ProjectStatisticsProvider(
                    context.read<ProjectStatisticsRepository>(),
                  )..load(),
                ),
              ],
              child: const HomePage(),
            );
          },
          routes: [
            GoRoute(
              path: 'announcement/:id',
              name: AnnouncementDetailPage.routeName,
              builder: (context, state) {
                AnnouncementModel? announcement;
                final extra = state.extra;
                if (extra is AnnouncementModel) {
                  announcement = extra;
                } else {
                  final idParam = state.pathParameters['id'];
                  final id = int.tryParse(idParam ?? '');
                  if (id != null) {
                    HomeAnnouncementsProvider? provider;
                    try {
                      provider = context.read<HomeAnnouncementsProvider>();
                    } catch (_) {
                      provider = null;
                    }
                    announcement = provider?.findById(id);
                  }
                }

                if (announcement == null) {
                  return const _AnnouncementMissingPage();
                }

                return AnnouncementDetailPage(announcement: announcement);
              },
            ),
            GoRoute(
              path: 'create-post',
              name: CreatePostPage.routeName,
              builder: (context, state) {
                return ChangeNotifierProvider(
                  create: (context) => CreatePostProvider(
                    context.read<PostRepository>(),
                  ),
                  child: const CreatePostPage(),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthSessionProvider()),
        ProxyProvider<AuthSessionProvider, ApiClient>(
          update: (context, session, client) {
            final apiClient = client ?? ApiClient();
            apiClient.updateAuthToken(session.tokens?.accessToken);
            return apiClient;
          },
        ),
        Provider(
          create: (context) => AuthRepository(context.read<ApiClient>()),
        ),
        Provider(
          create: (context) =>
              AnnouncementRepository(context.read<ApiClient>()),
        ),
        Provider(
          create: (context) =>
              ProjectStatisticsRepository(context.read<ApiClient>()),
        ),
        Provider(
          create: (context) => PostRepository(context.read<ApiClient>()),
        ),
        ChangeNotifierProvider(create: (_) => LoginFormProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: '崖柏',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            routerConfig: _router,
          );
        },
      ),
    );
  }
}

class _AnnouncementMissingPage extends StatelessWidget {
  const _AnnouncementMissingPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('通知公告')),
      body: const Center(child: Text('找不到对应的通知公告，可能已被删除。')),
    );
  }
}
