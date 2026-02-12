import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
import 'package:yabai_app/features/auth/presentation/pages/register_page.dart';
import 'package:yabai_app/features/app_update/data/services/app_update_service.dart';
import 'package:yabai_app/features/app_update/presentation/widgets/app_update_dialog.dart';
import 'package:yabai_app/features/home/data/models/announcement_model.dart';
import 'package:yabai_app/features/home/data/repositories/announcement_repository.dart';
import 'package:yabai_app/features/home/data/repositories/comment_repository.dart';
import 'package:yabai_app/features/home/data/repositories/favorite_repository.dart';
import 'package:yabai_app/features/home/data/repositories/post_repository.dart';
import 'package:yabai_app/features/home/data/repositories/project_repository.dart';
import 'package:yabai_app/features/home/data/repositories/project_statistics_repository.dart';
import 'package:yabai_app/features/home/presentation/pages/announcement_detail_page.dart';
import 'package:yabai_app/features/home/presentation/pages/create_post_page.dart';
import 'package:yabai_app/features/home/presentation/pages/home_page.dart';
import 'package:yabai_app/features/home/presentation/pages/project_detail_page.dart';
import 'package:yabai_app/features/home/presentation/pages/project_list_page.dart';
import 'package:yabai_app/features/home/presentation/pages/project_list_by_person_page.dart';
import 'package:yabai_app/features/home/presentation/pages/my_projects_page.dart';
import 'package:yabai_app/features/home/providers/comment_list_provider.dart';
import 'package:yabai_app/features/home/providers/create_post_provider.dart';
import 'package:yabai_app/features/home/providers/favorite_provider.dart';
import 'package:yabai_app/features/home/providers/home_announcements_provider.dart';
import 'package:yabai_app/features/home/providers/project_detail_provider.dart';
import 'package:yabai_app/features/home/providers/project_list_provider.dart';
import 'package:yabai_app/features/home/providers/project_list_by_person_provider.dart';
import 'package:yabai_app/features/home/providers/project_statistics_provider.dart';
import 'package:yabai_app/features/home/providers/share_link_provider.dart';
import 'package:yabai_app/features/screening/data/repositories/screening_repository.dart';
import 'package:yabai_app/features/screening/presentation/pages/screening_detail_page.dart';
import 'package:yabai_app/features/screening/presentation/pages/screening_submit_page.dart';
import 'package:yabai_app/features/screening/providers/screening_detail_provider.dart';
import 'package:yabai_app/features/screening/providers/screening_submit_provider.dart';
import 'package:yabai_app/features/home/data/models/project_criteria_model.dart';
import 'package:yabai_app/features/profile/data/repositories/my_posts_repository.dart';
import 'package:yabai_app/features/profile/providers/my_favorites_provider.dart';
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
import 'package:yabai_app/features/profile/providers/user_profile_detail_provider.dart';
import 'package:yabai_app/features/profile/presentation/pages/user_profile_detail_page.dart';
import 'package:yabai_app/features/ai/data/repositories/ai_repository.dart';
import 'package:yabai_app/features/address_book/data/repositories/address_book_repository.dart';
import 'package:yabai_app/features/address_book/providers/address_book_provider.dart';
import 'package:yabai_app/features/address_book/providers/patient_lookup_provider.dart';
import 'package:yabai_app/features/address_book/presentation/pages/address_book_page.dart';
import 'package:yabai_app/features/address_book/presentation/pages/patient_lookup_page.dart';
import 'package:yabai_app/features/med_appt/data/repositories/med_appt_repository.dart';
import 'package:yabai_app/features/med_appt/providers/med_appt_list_provider.dart';
import 'package:yabai_app/features/med_appt/providers/med_appt_create_provider.dart';
import 'package:yabai_app/features/med_appt/providers/project_selection_provider.dart';
import 'package:yabai_app/features/med_appt/presentation/pages/med_appt_list_page.dart';
import 'package:yabai_app/features/med_appt/presentation/pages/med_appt_create_page.dart';
import 'package:yabai_app/features/med_appt/presentation/pages/project_selection_page.dart';
import 'package:yabai_app/features/im/data/repositories/im_repository.dart';
import 'package:yabai_app/features/im/data/services/websocket_service.dart';
import 'package:yabai_app/features/im/providers/websocket_provider.dart';
import 'package:yabai_app/features/im/providers/conversation_list_provider.dart';
import 'package:yabai_app/features/im/providers/chat_provider.dart';
import 'package:yabai_app/features/im/providers/unread_count_provider.dart';
import 'package:yabai_app/features/im/presentation/pages/chat_page.dart';
import 'package:yabai_app/features/im/presentation/pages/conversation_selector_page.dart';

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
          path: RegisterPage.routePath,
          name: RegisterPage.routeName,
          builder: (context, state) => const RegisterPage(),
        ),
        GoRoute(
          path: HomePage.routePath,
          name: HomePage.routeName,
          builder: (context, state) {
            return MultiProvider(
              providers: [
                ChangeNotifierProvider(
                  create: (context) =>
                      HomeAnnouncementsProvider(
                          context.read<AnnouncementRepository>(),
                        )
                        ..loadInitial()
                        ..loadAnnouncementTags(),
                ),
                ChangeNotifierProvider(
                  create: (context) => ProjectStatisticsProvider(
                    context.read<ProjectStatisticsRepository>(),
                  )..load(),
                ),
                ChangeNotifierProvider(
                  create: (context) =>
                      MyPostsProvider(context.read<MyPostsRepository>()),
                ),
                ChangeNotifierProvider(
                  create: (context) =>
                      MyFavoritesProvider(context.read<FavoriteRepository>()),
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
                  child: AnnouncementDetailPage(
                    announcement: validAnnouncement,
                  ),
                );
              },
            ),
            GoRoute(
              path: 'create-post',
              name: CreatePostPage.routeName,
              builder: (context, state) {
                return ChangeNotifierProvider(
                  create: (context) =>
                      CreatePostProvider(context.read<PostRepository>()),
                  child: const CreatePostPage(),
                );
              },
            ),
            GoRoute(
              path: ProjectListPage.routePath,
              name: ProjectListPage.routeName,
              builder: (context, state) {
                return ChangeNotifierProvider(
                  create: (context) =>
                      ProjectListProvider(context.read<ProjectRepository>())
                        ..loadInitial(),
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

                    return MultiProvider(
                      providers: [
                        ChangeNotifierProvider(
                          create: (context) => ProjectDetailProvider(
                            context.read<ProjectRepository>(),
                          ),
                        ),
                        ChangeNotifierProvider(
                          create: (context) => FavoriteProvider(
                            context.read<FavoriteRepository>(),
                          ),
                        ),
                        ChangeNotifierProvider(
                          create: (context) => ShareLinkProvider(
                            context.read<ProjectRepository>(),
                          ),
                        ),
                      ],
                      child: ProjectDetailPage(projectId: id),
                    );
                  },
                  routes: [
                    GoRoute(
                      path: ScreeningSubmitPage.routePath,
                      name: ScreeningSubmitPage.routeName,
                      builder: (context, state) {
                        final extra = state.extra as Map<String, dynamic>?;

                        if (extra == null) {
                          return Scaffold(
                            appBar: AppBar(title: const Text('错误')),
                            body: const Center(child: Text('缺少必要参数')),
                          );
                        }

                        final projectId = extra['projectId'] as int;
                        final projectName = extra['projectName'] as String;
                        final criteria =
                            extra['criteria'] as List<ProjectCriteriaModel>;

                        return ChangeNotifierProvider(
                          create: (context) => ScreeningSubmitProvider(
                            repository: context.read<ScreeningRepository>(),
                            projectId: projectId,
                            criteria: criteria,
                          ),
                          child: ScreeningSubmitPage(
                            projectId: projectId,
                            projectName: projectName,
                            criteria: criteria,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
            GoRoute(
              path: ProjectListByPersonPage.routePath,
              name: ProjectListByPersonPage.routeName,
              builder: (context, state) {
                final personIdParam = state.pathParameters['personId'];
                if (personIdParam == null || personIdParam.isEmpty) {
                  return Scaffold(
                    appBar: AppBar(title: const Text('错误')),
                    body: const Center(child: Text('无效的人员ID')),
                  );
                }

                final extra = state.extra as Map<String, dynamic>?;
                final personName = extra?['personName'] as String?;

                return ChangeNotifierProvider(
                  create: (context) => ProjectListByPersonProvider(
                    repository: context.read<ProjectRepository>(),
                    personId: personIdParam,
                  ),
                  child: ProjectListByPersonPage(
                    personId: personIdParam,
                    personName: personName,
                  ),
                );
              },
            ),
            GoRoute(
              path: MyProjectsPage.routePath,
              name: MyProjectsPage.routeName,
              builder: (context, state) {
                final userProfile = context.read<UserProfileProvider>().profile;
                final personId = userProfile?.personId;
                
                if (personId == null || personId.isEmpty) {
                  return Scaffold(
                    appBar: AppBar(title: const Text('我的项目')),
                    body: const Center(
                      child: Text('无法获取用户信息，请稍后重试'),
                    ),
                  );
                }

                return ChangeNotifierProvider(
                  create: (context) => ProjectListByPersonProvider(
                    repository: context.read<ProjectRepository>(),
                    personId: personId,
                  ),
                  child: const MyProjectsPage(),
                );
              },
            ),
            GoRoute(
              path: ProfilePage.routePath,
              name: ProfilePage.routeName,
              builder: (context, state) {
                return MultiProvider(
                  providers: [
                    ChangeNotifierProvider(
                      create: (context) =>
                          MyPostsProvider(context.read<MyPostsRepository>()),
                    ),
                    ChangeNotifierProvider(
                      create: (context) =>
                          MyFavoritesProvider(context.read<FavoriteRepository>()),
                    ),
                  ],
                  child: const ProfilePage(),
                );
              },
            ),
            GoRoute(
              path: AddressBookPage.routePath,
              name: AddressBookPage.routeName,
              builder: (context, state) {
                return ChangeNotifierProvider(
                  create: (context) => AddressBookProvider(
                    context.read<AddressBookRepository>(),
                  ),
                  child: const AddressBookPage(),
                );
              },
              routes: [
                GoRoute(
                  path: PatientLookupPage.routePath,
                  name: PatientLookupPage.routeName,
                  builder: (context, state) {
                    return ChangeNotifierProvider(
                      create: (context) => PatientLookupProvider(
                        context.read<AddressBookRepository>(),
                      ),
                      child: const PatientLookupPage(),
                    );
                  },
                ),
              ],
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
              path: ScreeningDetailPage.routePath,
              name: ScreeningDetailPage.routeName,
              builder: (context, state) {
                final idParam = state.pathParameters['screeningId'];
                final id = int.tryParse(idParam ?? '');

                if (id == null) {
                  return Scaffold(
                    appBar: AppBar(title: const Text('错误')),
                    body: const Center(child: Text('无效的筛查ID')),
                  );
                }

                return ChangeNotifierProvider(
                  create: (context) => ScreeningDetailProvider(
                    repository: context.read<ScreeningRepository>(),
                    screeningId: id,
                  )..loadDetail(),
                  child: ScreeningDetailPage(screeningId: id),
                );
              },
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
            GoRoute(
              path: UserProfileDetailPage.routePath,
              name: UserProfileDetailPage.routeName,
              builder: (context, state) {
                final idParam = state.pathParameters['userId'];
                final id = int.tryParse(idParam ?? '');

                if (id == null) {
                  return Scaffold(
                    appBar: AppBar(title: const Text('错误')),
                    body: const Center(child: Text('无效的用户ID')),
                  );
                }

                return ChangeNotifierProvider(
                  create: (context) => UserProfileDetailProvider(
                    repository: context.read<UserProfileRepository>(),
                    userId: id,
                  )..loadProfile(),
                  child: UserProfileDetailPage(userId: id),
                );
              },
            ),
            GoRoute(
              path: MedApptListPage.routePath,
              name: MedApptListPage.routeName,
              builder: (context, state) {
                return ChangeNotifierProvider(
                  create: (context) => MedApptListProvider(
                    context.read<MedApptRepository>(),
                  ),
                  child: const MedApptListPage(),
                );
              },
              routes: [
                GoRoute(
                  path: MedApptCreatePage.routePath,
                  name: MedApptCreatePage.routeName,
                  builder: (context, state) {
                    return ChangeNotifierProvider(
                      create: (context) => MedApptCreateProvider(
                        context.read<MedApptRepository>(),
                      ),
                      child: const MedApptCreatePage(),
                    );
                  },
                ),
                GoRoute(
                  path: ProjectSelectionPage.routePath,
                  name: ProjectSelectionPage.routeName,
                  builder: (context, state) {
                    return ChangeNotifierProvider(
                      create: (context) => ProjectSelectionProvider(
                        context.read<ProjectRepository>(),
                      )..loadInitial(),
                      child: const ProjectSelectionPage(),
                    );
                  },
                ),
              ],
            ),
            GoRoute(
              path: ChatPage.routePath,
              name: ChatPage.routeName,
              builder: (context, state) {
                final convId = state.pathParameters['convId'];
                final title = state.uri.queryParameters['title'];
                
                if (convId == null) {
                  return Scaffold(
                    appBar: AppBar(title: const Text('错误')),
                    body: const Center(child: Text('无效的会话ID')),
                  );
                }

                final userProfile = context.read<UserProfileProvider>();
                final currentUserId = userProfile.profile?.id ?? 0;
                final currentUserAvatar = userProfile.profile?.avatar;
                final currentUserName = userProfile.profile?.displayName;
                
                return ChangeNotifierProvider(
                  create: (context) => ChatProvider(
                    repository: context.read<ImRepository>(),
                    websocketProvider: context.read<WebSocketProvider>(),
                    convId: convId,
                    currentUserId: currentUserId,
                    currentUserAvatar: currentUserAvatar,
                    currentUserName: currentUserName,
                  ),
                  child: ChatPage(convId: convId, title: title),
                );
              },
            ),
            GoRoute(
              path: ConversationSelectorPage.routePath,
              name: ConversationSelectorPage.routeName,
              builder: (context, state) {
                final extra = state.extra as Map<String, dynamic>?;
                
                if (extra == null) {
                  return Scaffold(
                    appBar: AppBar(title: const Text('错误')),
                    body: const Center(child: Text('缺少分享数据')),
                  );
                }
                
                return ConversationSelectorPage(
                  shareData: extra['shareData'] as Map<String, dynamic>,
                  shareType: extra['shareType'] as String,
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
        ProxyProvider<ApiClient, UserProfileRepository>(
          update: (context, apiClient, previous) =>
              previous ?? UserProfileRepository(apiClient),
        ),
        ChangeNotifierProxyProvider<UserProfileRepository, UserProfileProvider>(
          create: (context) =>
              UserProfileProvider(context.read<UserProfileRepository>()),
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
                    final BuildContext? currentContext =
                        _router.routerDelegate.navigatorKey.currentContext;
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
          create: (context) => ScreeningRepository(context.read<ApiClient>()),
        ),
        Provider(
          create: (context) => MyPostsRepository(context.read<ApiClient>()),
        ),
        Provider(
          create: (context) => CommentRepository(context.read<ApiClient>()),
        ),
        Provider(
          create: (context) => FavoriteRepository(context.read<ApiClient>()),
        ),
        Provider(
          create: (context) =>
              LearningResourceRepository(context.read<ApiClient>()),
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
          create: (context) =>
              MessageUnreadCountProvider(context.read<MessageRepository>())
                ..loadUnreadCount(),
        ),
        ChangeNotifierProvider(create: (_) => LoginFormProvider()),
        Provider(
          create: (context) => AiRepository(apiClient: context.read<ApiClient>()),
        ),
        Provider(
          create: (context) => AddressBookRepository(context.read<ApiClient>()),
        ),
        Provider(
          create: (context) => MedApptRepository(context.read<ApiClient>()),
        ),
        Provider(
          create: (context) => ImRepository(context.read<ApiClient>()),
        ),
        ChangeNotifierProvider(
          create: (context) => UnreadCountProvider(
            context.read<ImRepository>(),
          ),
        ),
        Provider(
          create: (context) => WebSocketService(),
        ),
        ChangeNotifierProxyProvider2<UserProfileProvider, UnreadCountProvider, WebSocketProvider>(
          create: (context) {
            return WebSocketProvider(
              context.read<WebSocketService>(),
              authSessionProvider: context.read<AuthSessionProvider>(),
              authRepository: context.read<AuthRepository>(),
              currentUserId: context.read<UserProfileProvider>().profile?.id,
              unreadCountProvider: context.read<UnreadCountProvider>(),
            );
          },
          update: (context, userProfileProvider, unreadCountProvider, previous) {
            if (previous == null) {
              return WebSocketProvider(
                context.read<WebSocketService>(),
                authSessionProvider: context.read<AuthSessionProvider>(),
                authRepository: context.read<AuthRepository>(),
                currentUserId: userProfileProvider.profile?.id,
                unreadCountProvider: unreadCountProvider,
              );
            }
            // 更新未读消息数Provider引用（当UnreadCountProvider变化时）
            previous.setUnreadCountProvider(unreadCountProvider);
            return previous;
          },
        ),
        ChangeNotifierProvider(
          create: (context) => ConversationListProvider(
            context.read<ImRepository>(),
            websocketProvider: context.read<WebSocketProvider>(),
          ),
        ),
      ],
      child: _AppInitializer(
        router: _router,
        child: Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return MaterialApp.router(
              debugShowCheckedModeBanner: false,
              title: '友研',
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeProvider.themeMode,
              routerConfig: _router,
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('zh', 'CN'),
                Locale('en', 'US'),
              ],
              locale: const Locale('zh', 'CN'),
            );
          },
        ),
      ),
    );
  }
}

/// 应用初始化器：在应用启动时恢复会话
class _AppInitializer extends StatefulWidget {
  const _AppInitializer({required this.router, required this.child});

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
      // 刷新用户信息（确保头像等信息是最新的）
      userProfile.loadProfile().catchError((e) {
        debugPrint('启动时加载用户信息失败: $e');
      });
      widget.router.go(HomePage.routePath);
      
      // 登录成功后检测版本更新
      _checkAppUpdate();
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
        
        // 登录成功后检测版本更新
        _checkAppUpdate();
        return;
      } on AuthException catch (error) {
        debugPrint('启动时刷新令牌失败: ${error.message}');
      } catch (error) {
        debugPrint('启动时刷新令牌异常: $error');
      }

      await authSession.clear();
    }
  }

  /// 检测应用版本更新
  Future<void> _checkAppUpdate() async {
    // 延迟一帧，确保页面已构建完成
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    try {
      final apiClient = context.read<ApiClient>();
      final updateService = AppUpdateService(apiClient);
      final updateInfo = await updateService.checkUpdate();

      if (!mounted) return;

      debugPrint('📦 [AppInitializer] 启动时更新检测结果: updateInfo=${updateInfo != null}, hasUpdate=${updateInfo?.hasUpdate}');

      // 如果有更新，显示更新对话框
      if (updateInfo != null && updateInfo.hasUpdate) {
        debugPrint('📦 [AppInitializer] 显示更新对话框');
        final navigatorContext = widget.router.routerDelegate.navigatorKey.currentContext;
        if (navigatorContext != null && navigatorContext.mounted) {
          await AppUpdateDialog.show(navigatorContext, updateInfo);
        }
      } else {
        debugPrint('📦 [AppInitializer] 无更新或检测失败（网络错误/服务不可用），静默处理');
      }
      // 如果检测失败（网络错误、服务不可用等），静默处理，不在界面显示任何错误
    } catch (e, stackTrace) {
      // 输出控制台日志，但不显示界面错误提示
      debugPrint('📦 [AppInitializer] 启动时检测更新异常: $e');
      debugPrint('📦 [AppInitializer] 堆栈: $stackTrace');
      // 静默处理，不在界面显示错误
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
