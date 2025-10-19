import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:yabai_app/core/network/api_client.dart';
import 'package:yabai_app/core/network/auth_interceptor.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/core/providers/theme_provider.dart';
import 'package:yabai_app/features/auth/data/repositories/auth_repository.dart';
import 'package:yabai_app/features/auth/data/models/auth_exception.dart';
import 'package:yabai_app/features/auth/data/repositories/user_profile_repository.dart';
import 'package:yabai_app/features/auth/providers/auth_session_provider.dart';
import 'package:yabai_app/features/auth/providers/login_form_provider.dart';
import 'package:yabai_app/features/auth/providers/user_profile_provider.dart';
import 'package:yabai_app/features/auth/presentation/pages/login_page.dart';
import 'package:yabai_app/features/home/data/models/announcement_model.dart';
import 'package:yabai_app/features/home/data/repositories/announcement_repository.dart';
import 'package:yabai_app/features/home/data/repositories/comment_repository.dart';
import 'package:yabai_app/features/home/data/repositories/post_repository.dart';
import 'package:yabai_app/features/home/data/repositories/project_repository.dart';
import 'package:yabai_app/features/home/data/repositories/project_statistics_repository.dart';
import 'package:yabai_app/features/home/presentation/pages/announcement_detail_page.dart';
import 'package:yabai_app/features/home/presentation/pages/create_post_page.dart';
import 'package:yabai_app/features/home/presentation/pages/home_page.dart';
import 'package:yabai_app/features/home/presentation/pages/project_detail_page.dart';
import 'package:yabai_app/features/home/presentation/pages/project_list_page.dart';
import 'package:yabai_app/features/home/providers/comment_list_provider.dart';
import 'package:yabai_app/features/home/providers/create_post_provider.dart';
import 'package:yabai_app/features/home/providers/home_announcements_provider.dart';
import 'package:yabai_app/features/home/providers/project_detail_provider.dart';
import 'package:yabai_app/features/home/providers/project_list_provider.dart';
import 'package:yabai_app/features/home/providers/project_statistics_provider.dart';
import 'package:yabai_app/features/profile/data/repositories/my_posts_repository.dart';
import 'package:yabai_app/features/profile/providers/my_posts_provider.dart';
import 'package:yabai_app/features/profile/presentation/pages/profile_page.dart';
import 'package:yabai_app/features/learning/data/models/learning_resource_model.dart';
import 'package:yabai_app/features/learning/data/repositories/learning_resource_repository.dart';
import 'package:yabai_app/features/learning/providers/learning_resource_list_provider.dart';
import 'package:yabai_app/features/learning/providers/learning_resource_detail_provider.dart';
import 'package:yabai_app/features/learning/presentation/pages/learning_resource_list_page.dart';
import 'package:yabai_app/features/learning/presentation/pages/learning_resource_detail_page.dart';
import 'package:yabai_app/features/messages/data/models/message_model.dart';
import 'package:yabai_app/features/messages/data/repositories/message_repository.dart';
import 'package:yabai_app/features/messages/providers/message_unread_count_provider.dart';
import 'package:yabai_app/features/messages/providers/message_list_provider.dart';
import 'package:yabai_app/features/messages/providers/message_detail_provider.dart';
import 'package:yabai_app/features/messages/presentation/pages/message_list_page.dart';
import 'package:yabai_app/features/messages/presentation/pages/message_detail_page.dart';

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
                ChangeNotifierProvider(
                  create: (context) => MyPostsProvider(
                    context.read<MyPostsRepository>(),
                  ),
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

                // 确保 announcement 非 null
                final validAnnouncement = announcement;
                
                return ChangeNotifierProvider(
                  create: (context) => CommentListProvider(
                    context.read<CommentRepository>(),
                    noticeId: validAnnouncement.id,
                  )..loadInitial(),
                  child: AnnouncementDetailPage(announcement: validAnnouncement),
                );
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
            GoRoute(
              path: ProjectListPage.routePath,
              name: ProjectListPage.routeName,
              builder: (context, state) {
                return ChangeNotifierProvider(
                  create: (context) => ProjectListProvider(
                    context.read<ProjectRepository>(),
                  )..loadInitial(),
                  child: const ProjectListPage(),
                );
              },
              routes: [
                GoRoute(
                  path: ProjectDetailPage.routePath,
                  name: ProjectDetailPage.routeName,
                  builder: (context, state) {
                    final idParam = state.pathParameters['id'];
                    final id = int.tryParse(idParam ?? '');

                    if (id == null) {
                      return Scaffold(
                        appBar: AppBar(title: const Text('错误')),
                        body: const Center(child: Text('无效的项目ID')),
                      );
                    }

                    return ChangeNotifierProvider(
                      create: (context) => ProjectDetailProvider(
                        context.read<ProjectRepository>(),
                      ),
                      child: ProjectDetailPage(projectId: id),
                    );
                  },
                ),
              ],
            ),
            GoRoute(
              path: ProfilePage.routePath,
              name: ProfilePage.routeName,
              builder: (context, state) {
                return ChangeNotifierProvider(
                  create: (context) => MyPostsProvider(
                    context.read<MyPostsRepository>(),
                  ),
                  child: const ProfilePage(),
                );
              },
            ),
            GoRoute(
              path: LearningResourceListPage.routePath,
              name: LearningResourceListPage.routeName,
              builder: (context, state) {
                return ChangeNotifierProvider(
                  create: (context) => LearningResourceListProvider(
                    context.read<LearningResourceRepository>(),
                  ),
                  child: const LearningResourceListPage(),
                );
              },
              routes: [
                GoRoute(
                  path: LearningResourceDetailPage.routePath,
                  name: LearningResourceDetailPage.routeName,
                  builder: (context, state) {
                    final idParam = state.pathParameters['id'];
                    final id = int.tryParse(idParam ?? '');

                    if (id == null) {
                      return Scaffold(
                        appBar: AppBar(title: const Text('错误')),
                        body: const Center(child: Text('无效的资源ID')),
                      );
                    }

                    LearningResource? resource;
                    final extra = state.extra;
                    if (extra is LearningResource) {
                      resource = extra;
                    }

                    return ChangeNotifierProvider(
                      create: (context) => LearningResourceDetailProvider(
                        context.read<LearningResourceRepository>(),
                      ),
                      child: LearningResourceDetailPage(
                        resourceId: id,
                        resource: resource,
                      ),
                    );
                  },
                ),
              ],
            ),
            GoRoute(
              path: MessageListPage.routePath,
              name: MessageListPage.routeName,
              builder: (context, state) {
                return MultiProvider(
                  providers: [
                    ChangeNotifierProvider(
                      create: (context) => MessageListProvider(
                        context.read<MessageRepository>(),
                      ),
                    ),
                  ],
                  child: const MessageListPage(),
                );
              },
              routes: [
                GoRoute(
                  path: MessageDetailPage.routePath,
                  name: MessageDetailPage.routeName,
                  builder: (context, state) {
                    final idParam = state.pathParameters['id'];
                    final id = int.tryParse(idParam ?? '');

                    if (id == null) {
                      return Scaffold(
                        appBar: AppBar(title: const Text('错误')),
                        body: const Center(child: Text('无效的消息ID')),
                      );
                    }

                    final extra = state.extra;
                    return ChangeNotifierProvider(
                      create: (context) => MessageDetailProvider(
                        context.read<MessageRepository>(),
                      ),
                      child: MessageDetailPage(
                        messageId: id,
                        message: extra is Message ? extra : null,
                      ),
                    );
                  },
                ),
              ],
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
        ProxyProvider<ApiClient, UserProfileRepository>(
          update: (context, apiClient, previous) =>
              previous ?? UserProfileRepository(apiClient),
        ),
        ChangeNotifierProxyProvider<UserProfileRepository, UserProfileProvider>(
          create: (context) => UserProfileProvider(
            context.read<UserProfileRepository>(),
          ),
          update: (context, repository, previous) =>
              previous ?? UserProfileProvider(repository),
        ),
        ProxyProvider2<ApiClient, AuthSessionProvider, AuthRepository>(
          update: (context, apiClient, session, previous) {
            // 只在首次创建时添加拦截器
            if (previous == null) {
              final authRepository = AuthRepository(apiClient);
              
              // 添加认证拦截器
              apiClient.addInterceptor(
                AuthInterceptor(
                  apiClient: apiClient,
                  authRepository: authRepository,
                  authSessionProvider: session,
                  onSessionExpired: () {
                    // 会话过期时跳转到登录页
                    _router.go(LoginPage.routePath);
                    
                    // 显示提示
                    final BuildContext? currentContext = _router.routerDelegate.navigatorKey.currentContext;
                    if (currentContext != null && currentContext.mounted) {
                      ScaffoldMessenger.of(currentContext).showSnackBar(
                        const SnackBar(
                          content: Text('登录已过期，请重新登录'),
                          duration: Duration(seconds: 3),
                        ),
                      );
                    }
                  },
                ),
              );
              
              return authRepository;
            }
            
            return previous;
          },
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
        Provider(
          create: (context) => ProjectRepository(context.read<ApiClient>()),
        ),
        Provider(
          create: (context) => MyPostsRepository(context.read<ApiClient>()),
        ),
        Provider(
          create: (context) => CommentRepository(context.read<ApiClient>()),
        ),
        Provider(
          create: (context) => LearningResourceRepository(context.read<ApiClient>()),
        ),
        ChangeNotifierProvider(
          create: (context) => LearningResourceListProvider(
            context.read<LearningResourceRepository>(),
          ),
        ),
        Provider(
          create: (context) => MessageRepository(context.read<ApiClient>()),
        ),
        ChangeNotifierProvider(
          create: (context) => MessageUnreadCountProvider(
            context.read<MessageRepository>(),
          )..loadUnreadCount(),
        ),
        ChangeNotifierProvider(create: (_) => LoginFormProvider()),
      ],
      child: _AppInitializer(
        router: _router,
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
      ),
    );
  }
}

/// 应用初始化器：在应用启动时恢复会话
class _AppInitializer extends StatefulWidget {
  const _AppInitializer({
    required this.router,
    required this.child,
  });

  final GoRouter router;
  final Widget child;

  @override
  State<_AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<_AppInitializer> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final authSession = context.read<AuthSessionProvider>();
    final userProfile = context.read<UserProfileProvider>();
    final authRepository = context.read<AuthRepository>();
    
    // 从本地存储恢复会话
    await authSession.initialize();
    
    // 从本地存储恢复用户信息缓存
    await userProfile.initialize();

    if (!mounted) {
      return;
    }
    
    // 如果有有效的 token，跳转到首页
    if (authSession.isAuthenticated) {
      widget.router.go(HomePage.routePath);
      return;
    }

    // 如果 access token 已过期但仍有 refresh token，尝试静默刷新
    final tokens = authSession.tokens;
    if (tokens != null && tokens.refreshToken.isNotEmpty) {
      try {
        final newTokens = await authRepository.refreshTokens(
          refreshToken: tokens.refreshToken,
        );

        await authSession.save(newTokens);

        // 刷新成功后重新拉取用户信息
        await userProfile.loadProfile();

        if (!mounted) {
          return;
        }

        widget.router.go(HomePage.routePath);
        return;
      } on AuthException catch (error) {
        debugPrint('启动时刷新令牌失败: ${error.message}');
      } catch (error) {
        debugPrint('启动时刷新令牌异常: $error');
      }

      await authSession.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
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
