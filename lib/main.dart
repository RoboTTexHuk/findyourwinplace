import 'dart:io' show Platform;
import 'package:atlaswinplace/popo.dart';
import 'package:atlaswinplace/win.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'dart:convert';
import 'dart:async';
// УДАЛЕНО: import ATT
import 'package:appsflyer_sdk/appsflyer_sdk.dart' as zax_fly;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart' show MethodChannel, SystemChrome, SystemUiOverlayStyle;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'package:package_info_plus/package_info_plus.dart';

import 'package:timezone/data/latest.dart' as zax_time;
import 'package:timezone/timezone.dart' as zax_tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:provider/provider.dart';

import 'package:provider/provider.dart' as p;
import 'package:flutter_riverpod/flutter_riverpod.dart' as r;
import 'package:url_launcher/url_launcher.dart';

// ---------------------- Новый кастомный лоадер ----------------------
import 'dart:async';
import 'package:flutter/material.dart';


import 'dart:async';
import 'package:flutter/material.dart';

import 'dart:async';
import 'package:flutter/material.dart';

import 'dart:async';
import 'package:flutter/material.dart';

import 'dart:async';
import 'package:flutter/material.dart';

class CustomLoader extends StatefulWidget {
  const CustomLoader({super.key});

  @override
  State<CustomLoader> createState() => _CustomLoaderState();
}

class _CustomLoaderState extends State<CustomLoader> {
  bool _showText = false;
  Timer? _timer;

  static const _visibleDuration = Duration(milliseconds: 1200);
  static const _fadeDuration = Duration(milliseconds: 250);

  @override
  void initState() {
    super.initState();
    // Сразу показываем только текст (фон уже есть и не анимируется)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => _showText = true);
      _timer = Timer(_visibleDuration, () {
        if (!mounted) return;
        setState(() => _showText = false);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Фон ВСЕГДА подложен в body. Никакой анимации фона.
      body: Stack(
        children: [
          // Постоянный градиентный фон (без анимаций)
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  // Можно сделать left->right. Я оставил диагональ для плавности.
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFACFA9B), // #ACFA9B
                    Color(0xFFBDAEFF), // #BDAEFF
                  ],
                ),
              ),
            ),
          ),
          // Только текст анимируем по прозрачности
          Positioned.fill(
            child: IgnorePointer(
              ignoring: !_showText,
              child: AnimatedOpacity(
                opacity: _showText ? 1.0 : 0.0,
                duration: _fadeDuration,
                curve: Curves.easeOut,
                child: const Center(
                  child: Text(
                    'WIN PLACE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// ---------------------- DI ----------------------

final storageInstance = const FlutterSecureStorage();
final connectivityInstance = Connectivity();

void initServices() {
  // Ничего не регистрируем, используем глобальные переменные
}

// ---------------------- Заглушечный BLoC (без ATT) ----------------------

enum XyzEvent { foo }
enum XyzState { bar, baz, qux, quux }

class XyzBloc extends Bloc<XyzEvent, XyzState> {
  XyzBloc() : super(XyzState.bar) {
    on<XyzEvent>((e, emit) async {
      // Больше не запрашиваем ATT -- сразу "успех"
      emit(XyzState.baz);
    });
  }
}

// ---------------------- Сеть ----------------------

class NetworkHelper {
  Future<bool> checkInternet() async {
    var n = await connectivityInstance.checkConnectivity();
    return n != ConnectivityResult.none;
  }

  Future<void> postData(String u, Map<String, dynamic> d) async {
    try {
      await http.post(Uri.parse(u), body: jsonEncode(d));
    } catch (e) {
      print("Net error: $e");
    }
  }
}

// ---------------------- Providers ----------------------

final deviceProvider = r.FutureProvider<DeviceData>((ref) async {
  final d = DeviceData();
  await d.initialize();
  return d;
});

class TrackingManager with ChangeNotifier {
  zax_fly.AppsflyerSdk? coreSdk;
  String trackingId = "";
  String conversionData = "";

  void initializeTracking(VoidCallback cb) {
    final cfg = zax_fly.AppsFlyerOptions(
      afDevKey: "qsBLmy7dAXDQhowM8V3ca4",
      appId: "6751948449",
      showDebug: true,
      timeToWaitForATTUserAuthorization: 0,
    );
    coreSdk = zax_fly.AppsflyerSdk(cfg);
    coreSdk?.initSdk(
      registerConversionDataCallback: true,
      registerOnAppOpenAttributionCallback: true,
      registerOnDeepLinkingCallback: true,
    );
    coreSdk?.startSDK(
      onSuccess: () => print("Tracking initialized"),
      onError: (int c, String m) => print("Tracking error $c: $m"),
    );
    coreSdk?.onInstallConversionData((res) {
      conversionData = res.toString();
      cb();
    });
    coreSdk?.getAppsFlyerUID().then((v) {
      trackingId = v.toString();
      cb();
    });
  }
}

class DeviceData {
  String? deviceId;
  String? sessionId = "unique-session-mark";
  String? platformType;
  String? osVersion;
  String? appVersion;
  String? language;
  String? timezone;
  bool notificationsEnabled = true;

  Future<void> initialize() async {
    final di = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final x = await di.androidInfo;
      deviceId = x.id;
      platformType = "android";
      osVersion = x.version.release;
    } else if (Platform.isIOS) {
      final x = await di.iosInfo;
      deviceId = x.identifierForVendor;
      platformType = "ios";
      osVersion = x.systemVersion;
    }
    final appInfo = await PackageInfo.fromPlatform();
    appVersion = appInfo.version;
    language = Platform.localeName.split('_')[0];
    timezone = zax_tz.local.name;
    sessionId = "session-${DateTime.now().millisecondsSinceEpoch}";
  }

  Map<String, dynamic> toMap({required String token}) => {
    "fcm_token": token,
    "device_id": deviceId ?? 'missing_id',
    "app_name": "atlaswinplace",
    "instance_id": sessionId ?? 'missing_session',
    "platform": platformType ?? 'missing_system',
    "os_version": osVersion ?? 'missing_build',
    "app_version": appVersion ?? 'missing_app',
    "language": language ?? 'en',
    "timezone": timezone ?? 'UTC',
    "push_enabled": notificationsEnabled,
  };
}

final trackingProvider = ChangeNotifierProvider(create: (_) => TrackingManager());

// ---------------------- main ----------------------

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  initServices();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(backgroundMessageHandler);
  if (Platform.isAndroid) {
    await InAppWebViewController.setWebContentsDebuggingEnabled(true);
  }
  zax_time.initializeTimeZones();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TrackingManager()),
      ],
      child: r.ProviderScope(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          // Без экрана согласия -- стартуем сразу с онбординга
          home: BlocProvider(
            create: (_) => XyzBloc(),
            child: const InitialScreen(),
          ),
        ),
      ),
    ),
  );
}

// ---------------------- Экран инициализации уведомлений ----------------------

class InitialScreen extends StatefulWidget {
  const InitialScreen({Key? key}) : super(key: key);
  @override
  State<InitialScreen> createState() => InitialScreenState();
}

class InitialScreenState extends State<InitialScreen> {
  final fcmHandler = FcmHandler();
  bool initialized = false;
  Timer? timer;
  bool showLoader = true;
  String pendingSignal = '';

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ));

    // Слушаем токен: источник ВСЕГДА только тут
    fcmHandler.listenForSignal((sig) {
      pendingSignal = sig;
      if (mounted) navigateToNext(sig);
    });

    // Фолбэк по времени — просто переход к MainView (токен может прийти позже; MainView тоже слушает канал)
    timer = Timer(const Duration(seconds: 8), () {
      if (mounted) navigateToNext(pendingSignal);
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => showLoader = false);
    });
  }

  void navigateToNext(String sig) {
    if (initialized || !mounted) return;
    initialized = true;
    timer?.cancel();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MainView(signal: sig),
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (showLoader)
            const CustomLoader(),
          if (!showLoader)
            const Center(child: CustomLoader()),
        ],
      ),
    );
  }
}

// ---------------------- FCM канал ----------------------

class FcmHandler extends ChangeNotifier {
  String? signalValue;
  void listenForSignal(Function(String signal) cb) {
    const MethodChannel('com.example.fcm/token').setMethodCallHandler((call) async {
      if (call.method == 'setToken') {
        final String s = call.arguments as String;
        cb(s);
      }
    });
  }
}

// ---------------------- Главный WebView экран ----------------------

class MainView extends StatefulWidget {
  final String? signal;
  const MainView({super.key, required this.signal});
  @override
  State<MainView> createState() => MainViewState();
}

class MainViewState extends State<MainView> with WidgetsBindingObserver {
  late InAppWebViewController webController;
  bool isLoading = false;
  final String baseUrl = "https://ios.atlaswinplace.buzz/";
  final DeviceData deviceData = DeviceData();
  final TrackingManager trackingManager = TrackingManager();
  int keyCounter = 0;
  DateTime? pauseTime;
  bool showOverlay = false;
  double progress = 0.0;
  late Timer progressTimer;
  final int loadingTime = 6;
  bool showSplash = true;

  // Локально храним единственный источник токена от FcmHandler
  String? fcmToken;

  // Платформенные схемы
  final Set<String> platformSchemes = {
    'tg', 'telegram',
    'whatsapp',
    'viber',
    'skype',
    'fb-messenger',
    'sgnl',
    'tel',
    'mailto',
    'bnl',
  };

  // Платформенные хосты
  final Set<String> platformHosts = {
    't.me', 'telegram.me', 'telegram.dog',
    'wa.me', 'api.whatsapp.com', 'chat.whatsapp.com',
    'm.me',
    'signal.me',
    'bnl.com', 'www.bnl.com',
  };

  // Канал FCM для получения токена в этом экране (на случай если пришёл позже)
  final FcmHandler fcmHandler = FcmHandler();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Слушаем только канал FcmHandler — это единственный источник токена
    fcmHandler.listenForSignal((sig) {
      if (sig.isNotEmpty) {
        fcmToken = sig;
        // Как только получили токен — отправляем данные в веб
        if (mounted && webController != null) {
          sendDeviceInfo();
          sendTrackingData();
        }
      }
    });

    // Если InitialScreen передал старый сигнал — можем принять как стартовый,
    // но всё равно считаем источником канал. Это просто первичная инициализация.
    if ((widget.signal ?? '').isNotEmpty) {
      fcmToken = widget.signal;
    }

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => showSplash = false);
    });
    Future.delayed(const Duration(seconds: 9), () {
      if (mounted) setState(() => showOverlay = true);
    });
    initializeEverything();
  }

  void initializeEverything() {
    startProgress();
    setupFcmListeners();
    // УДАЛЕНО: attCheck();
    trackingManager.initializeTracking(() {
      // при обновлении AF данных — если уже есть токен и веб готов, переотправим
      if (mounted && fcmToken != null && webController != null) {
        sendTrackingData();
      }
    });
    setupNotificationHandler();
    initializeDevice();
    // УДАЛЕНО: повторный вызов attCheck
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted) {
        // Отправка произойдет только если уже есть fcmToken
        sendDeviceInfo();
        sendTrackingData();
      }
    });
  }

  void setupFcmListeners() {
    FirebaseMessaging.onMessage.listen((msg) {
      final link = msg.data['uri'];
      if (link != null) {
        if (mounted) navigateToUrl(link.toString());
      } else {
        if (mounted) refreshPage();
      }
    });
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      final link = msg.data['uri'];
      if (link != null) {
        if (mounted) navigateToUrl(link.toString());
      } else {
        if (mounted) refreshPage();
      }
    });
  }

  void setupNotificationHandler() {
    MethodChannel('com.example.fcm/notification').setMethodCallHandler((call) async {
      if (call.method == "onNotificationTap") {
        final Map<String, dynamic> payload = Map<String, dynamic>.from(call.arguments);
        final targetUrl = payload["uri"];
        if (payload["uri"] != null && !payload["uri"].contains("Нет URI") && mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => AbcWidget(targetUrl)),
                (route) => false,
          );
        }
      }
    });
  }

  Future<void> initializeDevice() async {
    try {
      await deviceData.initialize();
      await requestPermissions();
      if (webController != null && mounted && fcmToken != null) {
        sendDeviceInfo();
      }
    } catch (e) {
      print("Device initialization failed: $e");
    }
  }

  Future<void> requestPermissions() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);
  }

  // УДАЛЕНО: метод attCheck() и любые обращения к ATT SDK

  void navigateToUrl(String link) async {
    if (webController != null) {
      await webController.loadUrl(urlRequest: URLRequest(url: WebUri(link)));
    }
  }

  void refreshPage() async {
    Future.delayed(const Duration(seconds: 3), () {
      if (webController != null) {
        webController.loadUrl(urlRequest: URLRequest(url: WebUri(baseUrl)));
      }
    });
  }

  Future<void> sendDeviceInfo() async {
    // Отправляем данные только если известен fcmToken
    if (fcmToken == null || fcmToken!.isEmpty) {
      print("Waiting for FCM token from FcmHandler...");
      return;
    }
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final data = deviceData.toMap(token: fcmToken!);
      await webController.evaluateJavascript(source: '''
        localStorage.setItem('app_data', JSON.stringify(${jsonEncode(data)}));
      ''');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> sendTrackingData() async {
    // Отправляем только если есть токен
    if (fcmToken == null || fcmToken!.isEmpty) {
      print("TrackingData: waiting for FCM token...");
      return;
    }
    final data = {
      "content": {
        "af_data": trackingManager.conversionData,
        "af_id": trackingManager.trackingId,
        "fb_app_name": "atlaswinplace",
        "app_name": "atlaswinplace",
        "deep": null,
        "bundle_identifier": "com.yuow.atlaswinplace",
        "app_version": "1.0.0",
        "apple_id": "6751948449",
        "fcm_token": fcmToken!, // только из FcmHandler
        "device_id": deviceData.deviceId ?? "no_device",
        "instance_id": deviceData.sessionId ?? "no_instance",
        "platform": deviceData.platformType ?? "no_type",
        "os_version": deviceData.osVersion ?? "no_os",
        "language": deviceData.language ?? "en",
        "timezone": deviceData.timezone ?? "UTC",
        "push_enabled": deviceData.notificationsEnabled,
        "useruid": trackingManager.trackingId,
      },
    };
    final jsonString = jsonEncode(data);
    print("SendRawData: $jsonString");
    await webController.evaluateJavascript(
      source: "sendRawData(${jsonEncode(jsonString)});",
    );
  }

  void startProgress() {
    int counter = 0;
    progress = 0.0;
    progressTimer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (mounted) {
        setState(() {
          counter++;
          progress = counter / (loadingTime * 10);
          if (progress >= 1.0) {
            progress = 1.0;
            progressTimer.cancel();
          }
        });
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.paused) {
      pauseTime = DateTime.now();
    }
    if (s == AppLifecycleState.resumed) {
      if (Platform.isIOS && pauseTime != null) {
        final now = DateTime.now();
        final duration = now.difference(pauseTime!);
        if (duration > const Duration(minutes: 25)) {
          if (mounted) rebuildScreen();
        }
      }
      pauseTime = null;
    }
  }

  void rebuildScreen() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => MainView(signal: widget.signal),
        ),
            (route) => false,
      );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    progressTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    setupNotificationHandler();
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            if (showSplash)
              const CustomLoader(),
            if (!showSplash)
              Container(
                color: Colors.black,
                child: Stack(
                  children: [
                    InAppWebView(
                      key: ValueKey(keyCounter),
                      initialSettings: InAppWebViewSettings(
                        javaScriptEnabled: true,
                        disableDefaultErrorPage: true,
                        mediaPlaybackRequiresUserGesture: false,
                        allowsInlineMediaPlayback: true,
                        allowsPictureInPictureMediaPlayback: true,
                        useOnDownloadStart: true,
                        javaScriptCanOpenWindowsAutomatically: true,
                        useShouldOverrideUrlLoading: true,
                        supportMultipleWindows: true,
                      ),
                      initialUrlRequest: URLRequest(url: WebUri(baseUrl)),
                      onWebViewCreated: (c) {
                        webController = c;
                        webController.addJavaScriptHandler(
                          handlerName: 'onServerResponse',
                          callback: (args) {
                            print("JS args: $args");
                            print("From the JavaScript side:");
                            print("ResRes${args[0]['savedata']}");
                            if (args[0]['savedata'].toString() = "false" && mounted) {



                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AtlasApp(),
                                ),
                                    (route) => false,
                              );
                            }
                            return args.reduce((curr, next) => curr + next);
                          },
                        );
                      },

                      onLoadStart: (c, u) async {
                        if (mounted) setState(() => isLoading = true);
                        final uri = u;
                        if (uri != null) {
                          if (isPlainEmail(uri)) {
                            try { await c.stopLoading(); } catch (_) {}
                            final mailtoUri = convertToMailto(uri);
                            if (mounted) await openEmail(mailtoUri);
                            return;
                          }
                          final scheme = uri.scheme.toLowerCase();
                          if (scheme != 'http' && scheme != 'https') {
                            try { await c.stopLoading(); } catch (_) {}
                          }
                        }
                      },

                      onLoadStop: (c, u) async {
                        await c.evaluateJavascript(source: "console.log('Portal loaded!');");
                        print("Load my data $u");
                        if (mounted) {
                          // Отправляем только когда есть токен
                          await sendDeviceInfo();
                          sendTrackingData();
                        }
                      },

                      shouldOverrideUrlLoading: (c, action) async {
                        final uri = action.request.url;
                        if (uri == null) return NavigationActionPolicy.ALLOW;

                        if (isPlainEmail(uri)) {
                          final mailtoUri = convertToMailto(uri);
                          if (mounted) await openEmail(mailtoUri);
                          return NavigationActionPolicy.CANCEL;
                        }

                        final scheme = uri.scheme.toLowerCase();

                        if (scheme == 'mailto') {
                          if (mounted) await openEmail(uri);
                          return NavigationActionPolicy.CANCEL;
                        }

                        if (scheme == 'tel') {
                          if (mounted) await launchUrl(uri, mode: LaunchMode.externalApplication);
                          return NavigationActionPolicy.CANCEL;
                        }

                        if (isPlatformLink(uri)) {
                          final webUri = convertToWebUri(uri);
                          if (webUri.scheme == 'http' || webUri.scheme == 'https') {
                            if (mounted) await openInBrowser(webUri);
                          } else {
                            try {
                              if (await canLaunchUrl(uri) && mounted) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              } else if (webUri != uri && (webUri.scheme == 'http' || webUri.scheme == 'https') && mounted) {
                                await openInBrowser(webUri);
                              }
                            } catch (_) {}
                          }
                          return NavigationActionPolicy.CANCEL;
                        }

                        if (scheme != 'http' && scheme != 'https') {
                          return NavigationActionPolicy.CANCEL;
                        }

                        return NavigationActionPolicy.ALLOW;
                      },

                      onCreateWindow: (c, req) async {
                        final uri = req.request.url;
                        if (uri == null) return false;

                        if (isPlainEmail(uri)) {
                          final mailtoUri = convertToMailto(uri);
                          if (mounted) await openEmail(mailtoUri);
                          return false;
                        }

                        final scheme = uri.scheme.toLowerCase();

                        if (scheme == 'mailto') {
                          if (mounted) await openEmail(uri);
                          return false;
                        }

                        if (scheme == 'tel') {
                          if (mounted) await launchUrl(uri, mode: LaunchMode.externalApplication);
                          return false;
                        }

                        if (isPlatformLink(uri)) {
                          final webUri = convertToWebUri(uri);
                          if (webUri.scheme == 'http' || webUri.scheme == 'https') {
                            if (mounted) await openInBrowser(webUri);
                          } else {
                            try {
                              if (await canLaunchUrl(uri) && mounted) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              } else if (webUri != uri && (webUri.scheme == 'http' || webUri.scheme == 'https') && mounted) {
                                await openInBrowser(webUri);
                              }
                            } catch (_) {}
                          }
                          return false;
                        }

                        if (scheme == 'http' || scheme == 'https') {
                          c.loadUrl(urlRequest: URLRequest(url: uri));
                        }
                        return false;
                      },

                      onDownloadStartRequest: (c, req) async {
                        if (mounted) await openInBrowser(req.url);
                      },
                    ),
                    Visibility(
                      visible: !showOverlay,
                      child: CustomLoader(),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ---- "Голый" email -> mailto ----
  bool isPlainEmail(Uri u) {
    final s = u.scheme;
    if (s.isNotEmpty) return false;
    final raw = u.toString();
    return raw.contains('@') && !raw.contains(' ');
  }

  Uri convertToMailto(Uri u) {
    final full = u.toString();
    final parts = full.split('?');
    final email = parts.first;
    final qp = parts.length > 1 ? Uri.splitQueryString(parts[1]) : <String, String>{};
    return Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: qp.isEmpty ? null : qp,
    );
  }

  // ---- Платформенные ссылки ----
  bool isPlatformLink(Uri u) {
    final s = u.scheme.toLowerCase();
    if (platformSchemes.contains(s)) return true;

    if (s == 'http' || s == 'https') {
      final h = u.host.toLowerCase();
      if (platformHosts.contains(h)) return true;
      if (h.endsWith('t.me')) return true;
      if (h.endsWith('wa.me')) return true;
      if (h.endsWith('m.me')) return true;
      if (h.endsWith('signal.me')) return true;
    }
    return false;
  }

  Uri convertToWebUri(Uri u) {
    final s = u.scheme.toLowerCase();

    if (s == 'tg' || s == 'telegram') {
      final qp = u.queryParameters;
      final domain = qp['domain'];
      if (domain != null && domain.isNotEmpty) {
        return Uri.https('t.me', '/$domain', {
          if (qp['start'] != null) 'start': qp['start']!,
        });
      }
      final path = u.path.isNotEmpty ? u.path : '';
      return Uri.https('t.me', '/$path', u.queryParameters.isEmpty ? null : u.queryParameters);
    }

    if ((s == 'http' || s == 'https') && u.host.toLowerCase().endsWith('t.me')) {
      return u;
    }

    if (s == 'viber') {
      return u;
    }

    if (s == 'whatsapp') {
      final qp = u.queryParameters;
      final phone = qp['phone'];
      final text = qp['text'];
      if (phone != null && phone.isNotEmpty) {
        return Uri.https('wa.me', '/${extractDigits(phone)}', {
          if (text != null && text.isNotEmpty) 'text': text,
        });
      }
      return Uri.https('wa.me', '/', {if (text != null && text.isNotEmpty) 'text': text});
    }

    if ((s == 'http' || s == 'https') &&
        (u.host.toLowerCase().endsWith('wa.me') || u.host.toLowerCase().endsWith('whatsapp.com'))) {
      return u;
    }

    if (s == 'skype') {
      return u;
    }

    if (s == 'fb-messenger') {
      final path = u.pathSegments.isNotEmpty ? u.pathSegments.join('/') : '';
      final qp = u.queryParameters;
      final id = qp['id'] ?? qp['user'] ?? path;
      if (id.isNotEmpty) {
        return Uri.https('m.me', '/$id', u.queryParameters.isEmpty ? null : u.queryParameters);
      }
      return Uri.https('m.me', '/', u.queryParameters.isEmpty ? null : u.queryParameters);
    }

    if (s == 'sgnl') {
      final qp = u.queryParameters;
      final ph = qp['phone'];
      final un = qp['username'];
      if (ph != null && ph.isNotEmpty) {
        return Uri.https('signal.me', '/#p/${extractDigits(ph)}');
      }
      if (un != null && un.isNotEmpty) {
        return Uri.https('signal.me', '/#u/$un');
      }
      final path = u.pathSegments.join('/');
      if (path.isNotEmpty) {
        return Uri.https('signal.me', '/$path', u.queryParameters.isEmpty ? null : u.queryParameters);
      }
      return u;
    }

    if (s == 'tel') {
      return Uri.parse('tel:${extractDigits(u.path)}');
    }

    if (s == 'mailto') {
      return u;
    }

    if (s == 'bnl') {
      final newPath = u.path.isNotEmpty ? u.path : '';
      return Uri.https('bnl.com', '/$newPath', u.queryParameters.isEmpty ? null : u.queryParameters);
    }

    return u;
  }

  // ---- Почта через Gmail Web ----
  Future<bool> openEmail(Uri mailto) async {
    final u = convertMailtoToGmail(mailto);
    return await openInBrowser(u);
  }

  Uri convertMailtoToGmail(Uri m) {
    final qp = m.queryParameters;
    final params = <String, String>{
      'view': 'cm',
      'fs': '1',
      if (m.path.isNotEmpty) 'to': m.path,
      if ((qp['subject'] ?? '').isNotEmpty) 'su': qp['subject']!,
      if ((qp['body'] ?? '').isNotEmpty) 'body': qp['body']!,
      if ((qp['cc'] ?? '').isNotEmpty) 'cc': qp['cc']!,
      if ((qp['bcc'] ?? '').isNotEmpty) 'bcc': qp['bcc']!,
    };
    return Uri.https('mail.google.com', '/mail/', params);
  }

  // ---- Открытие http/https ----
  Future<bool> openInBrowser(Uri u) async {
    try {
      if (await launchUrl(u, mode: LaunchMode.inAppBrowserView)) return true;
      return await launchUrl(u, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('openInAppBrowser error: $e; url=$u');
      try {
        return await launchUrl(u, mode: LaunchMode.externalApplication);
      } catch (_) {
        return false;
      }
    }
  }

  String extractDigits(String s) => s.replaceAll(RegExp(r'[^0-9+]'), '');
}

// ---------------------- FCM background ----------------------

@pragma('vm:entry-point')
Future<void> backgroundMessageHandler(RemoteMessage m) async {
  print("Background alert: ${m.messageId}");
  print("Background payload: ${m.data}");
}





