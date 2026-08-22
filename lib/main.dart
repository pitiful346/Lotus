import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'auth/firebase_auth/firebase_user_provider.dart';
import 'auth/firebase_auth/auth_util.dart';

import 'backend/firebase/firebase_config.dart';
import 'custom_code/notifications/firebase_notification_coordinator.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'custom_code/notifications/lotus_deep_link_handler.dart';
import 'index.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'flutter_flow/flutter_flow_util.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoRouter.optionURLReflectsImperativeAPIs = true;
  usePathUrlStrategy();
  await initializeDateFormatting('pt_PT', null);

  await initFirebase();
  await FirebaseNotificationCoordinator.instance.start();

  await FlutterFlowTheme.initialize();

  final appState = FFAppState(); // Initialize FFAppState
  await appState.initializePersistedState();

  runApp(ChangeNotifierProvider(create: (context) => appState, child: MyApp()));
}

class MyApp extends StatefulWidget {
  // This widget is the root of your application.
  @override
  State<MyApp> createState() => _MyAppState();

  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;
}

class MyAppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  };
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = FlutterFlowTheme.themeMode;

  late AppStateNotifier _appStateNotifier;
  late GoRouter _router;
  String getRoute([RouteMatch? routeMatch]) {
    final RouteMatch lastMatch =
        routeMatch ?? _router.routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : _router.routerDelegate.currentConfiguration;
    return matchList.uri.path;
  }

  List<String> getRouteStack() => _router
      .routerDelegate
      .currentConfiguration
      .matches
      .map((e) => getRoute(e))
      .toList();
  late Stream<BaseAuthUser> userStream;

  final authUserSub = authenticatedUserStream.listen((_) {});
  StreamSubscription<RemoteMessage>? _foregroundNotificationSub;
  StreamSubscription<RemoteMessage>? _openedNotificationSub;
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();

    _appStateNotifier = AppStateNotifier.instance;
    _router = createRouter(_appStateNotifier);
    userStream = lotusFirebaseUserStream()
      ..listen((user) {
        _appStateNotifier.update(user);
      });
    jwtTokenStream.listen((_) {});
    _foregroundNotificationSub = FirebaseNotificationCoordinator
        .instance
        .foregroundMessages
        .listen(_showForegroundNotification);
    _openedNotificationSub = FirebaseNotificationCoordinator
        .instance
        .openedMessages
        .listen(_openNotification);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final initial = await FirebaseNotificationCoordinator.instance
          .takeInitialMessage();
      if (initial != null) await _openNotification(initial);
    });
    Future.delayed(
      Duration(milliseconds: 1000),
      () => _appStateNotifier.stopShowingSplashImage(),
    );
  }

  @override
  void dispose() {
    authUserSub.cancel();
    _foregroundNotificationSub?.cancel();
    _openedNotificationSub?.cancel();

    super.dispose();
  }

  void setThemeMode(ThemeMode mode) => safeSetState(() {
    _themeMode = mode;
    FlutterFlowTheme.saveThemeMode(mode);
  });

  void _showForegroundNotification(RemoteMessage message) {
    final title = message.notification?.title ?? 'Lotus';
    final body = message.notification?.body;
    _scaffoldMessengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(body == null ? title : '$title\n$body')),
      );
  }

  Future<void> _openNotification(RemoteMessage message) async {
    final context = appNavigatorKey.currentContext;
    if (context == null || !context.mounted) return;

    final handled = await LotusDeepLinkHandler.instance
        .handleRemoteMessage(context, message);
    if (handled) return;

    if (message.data['route'] == 'saved') {
      context.pushNamed(SavedWidget.routeName);
      return;
    }

    _scaffoldMessengerKey.currentState?.showSnackBar(
      const SnackBar(content: Text('Não foi possível abrir o conteúdo da notificação.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      scaffoldMessengerKey: _scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      title: 'LOTUS',
      scrollBehavior: MyAppScrollBehavior(),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', '')],
      theme: _buildLotusTheme(),
      darkTheme: _buildLotusTheme(),
      themeMode: _themeMode,
      routerConfig: _router,
    );
  }
}

ThemeData _buildLotusTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    useMaterial3: false,
    scaffoldBackgroundColor: const Color(0xFF080B10),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFB7F34A),
      onPrimary: Color(0xFF11161D),
      secondary: Color(0xFFB7F34A),
      onSecondary: Color(0xFF11161D),
      surface: Color(0xFF151B23),
      onSurface: Colors.white,
      error: Color(0xFFFF5252),
      onError: Colors.white,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFF151B23),
      disabledColor: const Color(0xFF1A222C),
      selectedColor: const Color(0xFFB7F34A),
      secondarySelectedColor: const Color(0xFFB7F34A),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      labelStyle: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      secondaryLabelStyle: const TextStyle(
        color: Color(0xFF11161D),
        fontSize: 13,
        fontWeight: FontWeight.w800,
      ),
      brightness: Brightness.dark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFF293342)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xFF151B23),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF293342)),
      ),
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
      contentTextStyle: const TextStyle(
        color: Color(0xFFCBD5E1),
        fontSize: 15,
        height: 1.4,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Color(0xFF151B23),
      modalBackgroundColor: Color(0xFF151B23),
    ),
    dividerColor: const Color(0xFF242E3B),
  );
}
