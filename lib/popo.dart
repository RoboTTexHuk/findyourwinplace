import 'dart:convert';
import 'dart:io';

import 'package:appsflyer_sdk/appsflyer_sdk.dart' show AppsFlyerOptions, AppsflyerSdk;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MethodCall, MethodChannel, SystemUiOverlayStyle;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'main.dart' show MainHandler, WebPage, PortalView, ScreenPortal, GateVortex, ZxHubView, MainView;

// FCM Background Handler
@pragma('vm:entry-point')
Future<void> xyzMessageHandler(RemoteMessage message) async {
  print("Message ID: ${message.messageId}");
  print("Message Data: ${message.data}");
}

class AbcWidget extends StatefulWidget with WidgetsBindingObserver {
  String initialUrl;
  AbcWidget(this.initialUrl, {super.key});
  @override
  State<AbcWidget> createState() => AbcWidgetState(initialUrl);
}

class AbcWidgetState extends State<AbcWidget> with WidgetsBindingObserver {
  AbcWidgetState(this.currentUrl);

  late InAppWebViewController webController;
  String? abcToken;
  String? defId;
  String? ghiId;
  String? jklPlatform;
  String? mnoVersion;
  String? pqrVersion;
  bool rstEnabled = true;
  bool isLoading = false;
  var someBool = true;
  String currentUrl;
  DateTime? pauseTime;

  // ADDED: внешние платформы (tg/wa/bnl)
  final Set<String> externalHosts = {
    't.me', 'telegram.me', 'telegram.dog',
    'wa.me', 'api.whatsapp.com', 'chat.whatsapp.com',
    'bnl.com', 'www.bnl.com',
  };
  final Set<String> externalSchemes = {'tg', 'telegram', 'whatsapp', 'bnl'};

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      pauseTime = DateTime.now();
    }
    if (state == AppLifecycleState.resumed) {
      if (Platform.isIOS && pauseTime != null) {
        final now = DateTime.now();
        final backgroundDuration = now.difference(pauseTime!);
        if (backgroundDuration > const Duration(minutes: 25)) {
          _resetView();
        }
      }
      pauseTime = null;
    }
  }

  void _resetView() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => MainView(signal: ""),
        ),
            (route) => false,
      );
    });
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    FirebaseMessaging.onBackgroundMessage(xyzMessageHandler);
    _initAppsFlyer();
    _setupFCM();
    _getDeviceInfo();
    _handleMessages();
    _setupNotifications();

    Future.delayed(const Duration(seconds: 2), () {
      // _initializeTracking();
    });
    Future.delayed(const Duration(seconds: 6), () {
      _sendData();
    });
  }

  void _handleMessages() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.data['uri'] != null) {
        _loadUri(message.data['uri'].toString());
      } else {
        _reloadHome();
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (message.data['uri'] != null) {
        _loadUri(message.data['uri'].toString());
      } else {
        _reloadHome();
      }
    });
  }

  void _loadUri(String uri) async {
    if (webController != null) {
      await webController.loadUrl(
        urlRequest: URLRequest(url: WebUri(uri)),
      );
    }
  }

  void _reloadHome() async {
    Future.delayed(const Duration(seconds: 3), () {
      if (webController != null) {
        webController.loadUrl(
          urlRequest: URLRequest(url: WebUri(currentUrl)),
        );
      }
    });
  }

  Future<void> _setupFCM() async {
    FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
    NotificationSettings settings = await firebaseMessaging.requestPermission(alert: true, badge: true, sound: true);
    abcToken = await firebaseMessaging.getToken();
  }

  AppsflyerSdk? appsFlyerSdk;
  String conversionData = "";
  String afUid = "";

  void _initAppsFlyer() {
    final AppsFlyerOptions options = AppsFlyerOptions(
      afDevKey: "qsBLmy7dAXDQhowM8V3ca4",
      appId: "6745261464",
      showDebug: true,
    );
    appsFlyerSdk = AppsflyerSdk(options);
    appsFlyerSdk?.initSdk(
      registerConversionDataCallback: true,
      registerOnAppOpenAttributionCallback: true,
      registerOnDeepLinkingCallback: true,
    );
    appsFlyerSdk?.startSDK(
      onSuccess: () => print("AppsFlyer OK"),
      onError: (int code, String message) => print("AppsFlyer Error: $code $message"),
    );
    appsFlyerSdk?.onInstallConversionData((data) {
      setState(() {
        conversionData = data.toString();
        afUid = data['payload']['af_status'].toString();
      });
    });
    appsFlyerSdk?.getAppsFlyerUID().then((id) {
      setState(() {
        afUid = id.toString();
      });
    });
  }

  Future<void> _sendData() async {
    print("Conversion Data: $conversionData");
    final Map<String, dynamic> requestData = {
      "content": {
        "af_data": "$conversionData",
        "af_id": "$afUid",
        "fb_app_name": "amonjong",
        "app_name": "amonjong",
        "deep": null,
        "bundle_identifier": "com.amonjongtwostones.famojing.stonesamong.amonjongtwostones",
        "app_version": "1.0.0",
        "apple_id": "6751402817",
        "device_id": defId ?? "default_device_id",
        "instance_id": ghiId ?? "default_instance_id",
        "platform": jklPlatform ?? "unknown_platform",
        "os_version": mnoVersion ?? "default_os_version",
        "app_version": pqrVersion ?? "default_app_version",
        "language": mnoVersion ?? "en",
        "timezone": pqrVersion ?? "UTC",
        "push_enabled": rstEnabled,
        "useruid": "$afUid",
      },
    };

    final jsonData = jsonEncode(requestData);
    print("My JSON Data: $jsonData");
    await webController.evaluateJavascript(
      source: "sendRawData(${jsonEncode(jsonData)});",
    );
  }

  Future<void> _getDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        defId = androidInfo.id;
        jklPlatform = "android";
        ghiId = androidInfo.version.release;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        defId = iosInfo.identifierForVendor;
        jklPlatform = "ios";
        ghiId = iosInfo.systemVersion;
      }
      final packageInfo = await PackageInfo.fromPlatform();
      mnoVersion = Platform.localeName.split('_')[0];
      pqrVersion = timezone.local.name;
    } catch (e) {
      debugPrint("Device Info Error: $e");
    }
  }

  void _setupNotifications() {
    MethodChannel('com.example.fcm/notification').setMethodCallHandler((call) async {
      if (call.method == "onNotificationTap") {
        final Map<String, dynamic> data = Map<String, dynamic>.from(
          call.arguments,
        );
        print("URI data"+data['uri'].toString());
        if (data["uri"] != null && !data["uri"].contains("Нет URI")) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => AbcWidget(data["uri"])),
                (route) => false,
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _setupNotifications();

    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Stack(
          children: [
            InAppWebView(
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
              initialUrlRequest: URLRequest(url: WebUri(currentUrl)),
              onWebViewCreated: (controller) {
                webController = controller;
                webController.addJavaScriptHandler(
                  handlerName: 'onServerResponse',
                  callback: (args) {
                    print("JS Args: $args");
                    return args.reduce((value, element) => value + element);
                  },
                );
              },
              onLoadStart: (controller, url) async {
                if (url != null) {
                  if (_isEmailLike(url)) {
                    try { await controller.stopLoading(); } catch (_) {}
                    final mailto = _convertToMailto(url);
                    await _launchEmailInBrowser(mailto);
                    return;
                  }
                  final s = url.scheme.toLowerCase();
                  if (s != 'http' && s != 'https') {
                    try { await controller.stopLoading(); } catch (_) {}
                  }
                }
              },
              onLoadStop: (controller, url) async {
                await controller.evaluateJavascript(
                  source: "console.log('Hello from JS!');",
                );
              },
              shouldOverrideUrlLoading: (controller, navigationAction) async {
                final uri = navigationAction.request.url;
                if (uri == null) return NavigationActionPolicy.ALLOW;

                if (_isEmailLike(uri)) {
                  final mailto = _convertToMailto(uri);
                  await _launchEmailInBrowser(mailto);
                  return NavigationActionPolicy.CANCEL;
                }

                final scheme = uri.scheme.toLowerCase();

                if (scheme == 'mailto') {
                  await _launchEmailInBrowser(uri);
                  return NavigationActionPolicy.CANCEL;
                }

                if (_isExternalPlatform(uri)) {
                  await _launchInBrowser(_convertToWebUri(uri));
                  return NavigationActionPolicy.CANCEL;
                }

                if (scheme != 'http' && scheme != 'https') {
                  return NavigationActionPolicy.CANCEL;
                }

                return NavigationActionPolicy.ALLOW;
              },
              onCreateWindow: (controller, request) async {
                final uri = request.request.url;
                if (uri == null) return false;

                if (_isEmailLike(uri)) {
                  final mailto = _convertToMailto(uri);
                  await _launchEmailInBrowser(mailto);
                  return false;
                }

                final scheme = uri.scheme.toLowerCase();

                if (scheme == 'mailto') {
                  await _launchEmailInBrowser(uri);
                  return false;
                }

                if (_isExternalPlatform(uri)) {
                  await _launchInBrowser(_convertToWebUri(uri));
                  return false;
                }

                if (scheme == 'http' || scheme == 'https') {
                  controller.loadUrl(urlRequest: URLRequest(url: uri));
                }
                return false;
              },
            ),
            if (isLoading)
              Visibility(
                visible: !isLoading,
                child: SizedBox.expand(
                  child: Container(
                    color: Colors.black,
                    child: Center(
                      child: CircularProgressIndicator(
                        backgroundColor: Colors.grey.shade800,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow),
                        strokeWidth: 8,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _isEmailLike(Uri uri) {
    final s = uri.scheme;
    if (s.isNotEmpty) return false;
    final raw = uri.toString();
    return raw.contains('@') && !raw.contains(' ');
  }

  Uri _convertToMailto(Uri uri) {
    final full = uri.toString();
    final parts = full.split('?');
    final email = parts.first;
    final qp = parts.length > 1 ? Uri.splitQueryString(parts[1]) : <String, String>{};
    return Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: qp.isEmpty ? null : qp,
    );
  }

  bool _isExternalPlatform(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    if (externalSchemes.contains(scheme)) return true;

    if (scheme == 'http' || scheme == 'https') {
      final host = uri.host.toLowerCase();
      if (externalHosts.contains(host)) return true;
    }
    return false;
  }

  Uri _convertToWebUri(Uri uri) {
    final scheme = uri.scheme.toLowerCase();

    if (scheme == 'tg' || scheme == 'telegram') {
      final qp = uri.queryParameters;
      final domain = qp['domain'];
      if (domain != null && domain.isNotEmpty) {
        return Uri.https('t.me', '/$domain', {
          if (qp['start'] != null) 'start': qp['start']!,
        });
      }
      final path = uri.path.isNotEmpty ? uri.path : '';
      return Uri.https('t.me', '/$path',
          uri.queryParameters.isEmpty ? null : uri.queryParameters);
    }

    if (scheme == 'whatsapp') {
      final qp = uri.queryParameters;
      final phone = qp['phone'];
      final text = qp['text'];
      if (phone != null && phone.isNotEmpty) {
        return Uri.https('wa.me', '/${_cleanPhone(phone)}', {
          if (text != null && text.isNotEmpty) 'text': text,
        });
      }
      return Uri.https('wa.me', '/', {if (text != null && text.isNotEmpty) 'text': text});
    }

    if (scheme == 'bnl') {
      final newPath = uri.path.isNotEmpty ? uri.path : '';
      return Uri.https('bnl.com', '/$newPath',
          uri.queryParameters.isEmpty ? null : uri.queryParameters);
    }

    return uri;
  }

  Future<bool> _launchEmailInBrowser(Uri mailtoUri) async {
    final gmailUri = _createGmailUri(mailtoUri);
    return await _launchInBrowser(gmailUri);
  }

  Uri _createGmailUri(Uri mailto) {
    final qp = mailto.queryParameters;
    final params = <String, String>{
      'view': 'cm',
      'fs': '1',
      if (mailto.path.isNotEmpty) 'to': mailto.path,
      if ((qp['subject'] ?? '').isNotEmpty) 'su': qp['subject']!,
      if ((qp['body'] ?? '').isNotEmpty) 'body': qp['body']!,
      if ((qp['cc'] ?? '').isNotEmpty) 'cc': qp['cc']!,
      if ((qp['bcc'] ?? '').isNotEmpty) 'bcc': qp['bcc']!,
    };
    return Uri.https('mail.google.com', '/mail/', params);
  }

  Future<bool> _launchInBrowser(Uri uri) async {
    try {
      if (await launchUrl(uri, mode: LaunchMode.inAppBrowserView)) return true;
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('openInAppBrowser error: $e; url=$uri');
      try {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        return false;
      }
    }
  }

  String _cleanPhone(String input) =>
      input.replaceAll(RegExp(r'[^0-9+]'), '');
}