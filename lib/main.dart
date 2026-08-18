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
import 'backend/backend.dart';
import 'custom_code/notifications/firebase_notification_coordinator.dart';
import 'index.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'flutter_flow/flutter_flow_util.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoRouter.optionURLReflectsImperativeAPIs = true;
  usePathUrlStrategy();

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
    if (message.data['route'] == 'saved') {
      final context = appNavigatorKey.currentContext;
      if (context != null && context.mounted) {
        context.pushNamed(SavedWidget.routeName);
      }
      return;
    }
    final rawEventId = message.data['eventId']?.trim();
    if (rawEventId == null || rawEventId.isEmpty) return;
    final eventId = rawEventId.startsWith('events/')
        ? rawEventId.substring('events/'.length)
        : rawEventId;
    if (eventId.isEmpty || eventId.contains('/')) return;
    try {
      final reference = FirebaseFirestore.instance
          .collection('events')
          .doc(eventId);
      final record = await EventsRecord.getDocumentOnce(reference);
      final context = appNavigatorKey.currentContext;
      if (context == null || !context.mounted) return;
      context.pushNamed(
        EventDetailsWidget.routeName,
        queryParameters: {
          'eventoAtual': serializeParam(record, ParamType.Document),
        }.withoutNulls,
        extra: <String, dynamic>{'eventoAtual': record},
      );
    } catch (_) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Este evento já não está disponível.')),
      );
    }
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
      theme: ThemeData(brightness: Brightness.light, useMaterial3: false),
      darkTheme: ThemeData(brightness: Brightness.dark, useMaterial3: false),
      themeMode: _themeMode,
      routerConfig: _router,
    );
  }
}
