import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:yabai_app/core/network/api_client.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/features/auth/data/repositories/auth_repository.dart';
import 'package:yabai_app/features/auth/providers/auth_session_provider.dart';
import 'package:yabai_app/features/auth/providers/login_form_provider.dart';
import 'package:yabai_app/features/auth/presentation/pages/login_page.dart';
import 'package:yabai_app/features/home/presentation/pages/home_page.dart';

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
          builder: (context, state) => const HomePage(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => ApiClient()),
        Provider(
          create: (context) => AuthRepository(context.read<ApiClient>()),
        ),
        ChangeNotifierProvider(create: (_) => AuthSessionProvider()),
        ChangeNotifierProvider(create: (_) => LoginFormProvider()),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: '崖柏',
        theme: AppTheme.lightTheme,
        routerConfig: _router,
      ),
    );
  }
}
