// main.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AtlasApp());
}

// ========================= Glass AppBar =========================

class GlassAppBar extends StatelessWidget {
  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final double blurSigma;
  final double opacity;
  final double borderOpacity;
  final Color tintColor;
  final Color? foregroundColor;
  final SystemUiOverlayStyle? systemUiOverlayStyle;

  const GlassAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.blurSigma = 20,
    this.opacity = 0.18,
    this.borderOpacity = 0.25,
    this.tintColor = Colors.white,
    this.foregroundColor,
    this.systemUiOverlayStyle,
  });

  @override
  Widget build(BuildContext context) {
    final fg = foregroundColor ?? Theme.of(context).colorScheme.onSurface;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemUiOverlayStyle ??
          const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
      child: Container(
        decoration: BoxDecoration(
          color: tintColor.withOpacity(opacity),
          border: Border(
            bottom: BorderSide(
              color: Colors.white.withOpacity(borderOpacity),
              width: 0.6,
            ),
          ),
        ),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: kToolbarHeight,
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    if (leading != null)
                      IconTheme(
                        data: IconThemeData(color: fg),
                        child: leading!,
                      )
                    else
                      const SizedBox.shrink(),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DefaultTextStyle(
                        style: TextStyle(
                          color: fg,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                        child: title ?? const SizedBox.shrink(),
                      ),
                    ),
                    if (actions != null)
                      IconTheme(
                        data: IconThemeData(color: fg),
                        child: Row(children: actions!),
                      ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ========================= App =========================

class AtlasApp extends StatelessWidget {
  const AtlasApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.dark,
        seedColor: const Color(0xFFC77DFF),
        primary: const Color(0xFFC77DFF),
        secondary: const Color(0xFF68D5FF),
      ),
      scaffoldBackgroundColor: const Color(0xFF120F1D),
      useMaterial3: true,
      fontFamily: 'Roboto',
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1C182B),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3B3B5A)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3B3B5A)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFC77DFF)),
        ),
      ),
    );
    return MaterialApp(
      title: 'Atlas win place',
      theme: theme,
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ========================= Home =========================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  SharedPreferences? _prefs;
  bool _eulaAccepted = false;

  @override
  void initState() {
    super.initState();
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      _prefs = p;
      _eulaAccepted = p.getBool('eula_accepted') ?? false;
    });
    if (!_eulaAccepted) {
      await Future.delayed(Duration.zero);
      _showEulaDialog();
    }
  }

  void _showEulaDialog() {
    bool ack = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1C182B),
          title: const Text('End User License Agreement (EULA)'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                const Text(
                  '1) Acceptance of Terms\n'
                      '2) Zero tolerance for objectionable content\n'
                      '3) User conduct\n'
                      '4) Content & Moderation\n'
                      '5) Provided “as is”\n'
                      '6) Changes to Terms\n'
                      '7) Contact: support@example.com',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Checkbox(
                      value: ack,
                      onChanged: (v) => setS(() => ack = v ?? false),
                    ),
                    const Expanded(child: Text('I have read and accept the EULA.')),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () {
                if (!ack) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please accept the EULA')));
                  return;
                }
                _prefs?.setBool('eula_accepted', true);
                setState(() => _eulaAccepted = true);
                Navigator.of(ctx).pop();
              },
              child: const Text('Accept'),
            ),
          ],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_prefs == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final tabs = [
      GuideTab(prefs: _prefs!),
      SubmitTab(prefs: _prefs!),
      const AnalyticsTab(),
      ProfileTab(prefs: _prefs!),
      const ReviewsTab(),
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: GlassAppBar(
          title: const Center(
            child: Text(
              'Find your win place',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          foregroundColor: Colors.white,
          blurSigma: 20,
          opacity: 0.18,
          borderOpacity: 0.25,
          tintColor: Colors.white,
          systemUiOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
        ),
      ),
      body: SafeArea(child: tabs[_index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.explore), label: 'Guide'),
          NavigationDestination(icon: Icon(Icons.send), label: 'Submit'),
          NavigationDestination(icon: Icon(Icons.pie_chart), label: 'Analytics'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
          NavigationDestination(icon: Icon(Icons.forum), label: 'Reviews'),
        ],
        backgroundColor: const Color(0xFF1C182B),
        indicatorColor: const Color(0x33C77DFF),
      ),
    );
  }
}

// ========================= Models =========================

class Spot {
  final String id;
  final String title;
  final String city;
  final String category;
  final double luck;
  final String description;
  final String imageAsset; // локальный путь assets/...
  final String? moderationStatus;
  final String? moderationNote;

  Spot({
    required this.id,
    required this.title,
    required this.city,
    required this.category,
    required this.luck,
    required this.description,
    required this.imageAsset,
    this.moderationStatus,
    this.moderationNote,
  });

  factory Spot.fromJson(Map<String, dynamic> m) {
    final id = (m['id'] ?? '').toString();
    final title = (m['title'] ?? '') as String;
    final city = (m['city'] ?? '') as String;
    final category = (m['category'] ?? '') as String;
    final luck = (m['luck'] is num) ? (m['luck'] as num).toDouble() : double.tryParse('${m['luck']}') ?? 0.0;
    final description = (m['description'] ?? '') as String;
    final image = (m['image'] ?? '') as String;
    final moderationStatus = m['moderation_status']?.toString();
    final moderationNote = m['moderation_note']?.toString();

    // Принудительно подставляем "assets/" в начало пути к файлу.
    // Нормализуем относительные пути: "./images/x", "/images/x", "images/x" => "assets/images/x"
    final normalized = _normalizeImageToAsset(image);

    return Spot(
      id: id,
      title: title,
      city: city,
      category: category,
      luck: luck,
      description: description,
      imageAsset: normalized,
      moderationStatus: moderationStatus,
      moderationNote: moderationNote,
    );
  }

  static String _normalizeImageToAsset(String raw) {
    // Уберём ведущие "./" и "/" и пробелы
    String p = raw.trim();
    while (p.startsWith('./')) {
      p = p.substring(2);
    }
    while (p.startsWith('/')) {
      p = p.substring(1);
    }
    // Если уже начинается с assets/, оставим как есть
    if (p.startsWith('assets/')) {
      return p;
    }
    // Если начинается с http, всё равно заменяем на assets/ и оставляем имя файла после последнего слэша
    if (p.startsWith('http')) {
      final uri = Uri.tryParse(p);
      final last = uri?.pathSegments.isNotEmpty == true ? uri!.pathSegments.last : 'image.jpg';
      return 'assets/images/$last';
    }
    // Иначе считаем, что это относительный путь типа "images/xxx.png" или "whispering_falls.png"
    if (!p.contains('/')) {
      // нет папок — положим в images/
      return 'assets/images/$p';
    }
    // есть подпапки — префиксуем assets/
    return 'assets/$p';
  }
}

// ========================= Guide Tab =========================

class GuideTab extends StatefulWidget {
  final SharedPreferences prefs;
  const GuideTab({super.key, required this.prefs});

  @override
  State<GuideTab> createState() => _GuideTabState();
}

class _GuideTabState extends State<GuideTab> {
  List<Spot> _spots = [];
  String _query = '';
  String _filter = 'high';
  late Set<String> _visited;
  int luckRating = 42;
  int visitedCount = 0;

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _visited = widget.prefs.getStringList('visits')?.toSet() ?? <String>{};
    final pr = widget.prefs.getString('profile') ?? '{}';
    final map = jsonDecode(pr) as Map<String, dynamic>;
    luckRating = (map['luckRating'] ?? 42) as int;
    visitedCount = (map['visitedCount'] ?? 0) as int;

    _fetchGuides();
  }

  Future<void> _fetchGuides() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final uri = Uri.parse('https://winplace-app-l5jbl.ondigitalocean.app/guides');
      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) {
        throw HttpException('HTTP ${res.statusCode}');
      }
      final body = jsonDecode(utf8.decode(res.bodyBytes));
      if (body is! List) {
        throw const FormatException('Unexpected JSON format');
      }
      final list = body.map<Spot>((e) => Spot.fromJson(e as Map<String, dynamic>)).toList();

      list.sort((a, b) => b.luck.compareTo(a.luck));

      setState(() {
        _spots = list;
        _loading = false;
      });
    } on TimeoutException {
      setState(() {
        _error = 'Timeout: server took too long to respond.';
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load guides: $e';
        _loading = false;
      });
    }
  }

  void _saveVisits() {
    widget.prefs.setStringList('visits', _visited.toList());
  }

  void _updateProfile() {
    final existing = jsonDecode(widget.prefs.getString('profile') ?? '{}') as Map<String, dynamic>;
    final map = {
      'name': existing['name'] ?? '',
      'city': existing['city'] ?? '',
      'avatar': existing['avatar'] ?? '',
      'luckRating': luckRating,
      'visitedCount': visitedCount,
    };
    widget.prefs.setString('profile', jsonEncode(map));
  }

  List<Spot> get _filtered {
    final q = _query.trim().toLowerCase();
    return _spots.where((s) {
      if (q.isNotEmpty) {
        final t = '${s.title} ${s.city} ${s.description}'.toLowerCase();
        if (!t.contains(q)) return false;
      }
      if (_filter == 'high') return s.luck >= 8.5;
      if (_filter == 'nature') return s.category.toLowerCase() == 'nature';
      if (_filter == 'urban') return s.category.toLowerCase() == 'urban';
      if (_filter == 'coastal') return s.category.toLowerCase() == 'coastal';
      return true;
    }).toList();
  }

  Future<void> _openReport(Spot spot) async {
    String? selected;
    final descCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final shotCtrl = TextEditingController();
    bool ack = false;
    String? error;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1C182B),
          title: const Text('Report Content'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reporting: ${spot.title}', style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 12),
                const Text('Select a reason'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    'Harassment or hate speech',
                    'Violence or graphic content',
                    'Sexually explicit content',
                    'Spam or scam',
                    'Illegal activities',
                    'Other',
                  ].map((e) {
                    final active = selected == e;
                    return ChoiceChip(
                      label: Text(e),
                      selected: active,
                      onSelected: (_) => setS(() => selected = e),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                const Text('Describe the issue (optional)'),
                const SizedBox(height: 6),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(hintText: 'Add details...'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email (optional)'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: shotCtrl,
                  decoration: const InputDecoration(labelText: 'Screenshot URL (optional)'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Checkbox(value: ack, onChanged: (v) => setS(() => ack = v ?? false)),
                    const Expanded(child: Text('I acknowledge zero-tolerance policy.')),
                  ],
                ),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(error!, style: const TextStyle(color: Colors.redAccent)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (selected == null) {
                  setS(() => error = 'Please select a reason.');
                  return;
                }
                if (!ack) {
                  setS(() => error = 'Please confirm acknowledgement.');
                  return;
                }
                await Future.delayed(const Duration(milliseconds: 600));
                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report submitted. Thank you.')));
                }
              },
              child: const Text('Submit Report'),
            ),
          ],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: 'Search for a Luck Spot...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip('High Luck', 'high'),
                _buildFilterChip('Nature', 'nature'),
                _buildFilterChip('Urban', 'urban'),
                _buildFilterChip('Coastal', 'coastal'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : (_error != null
                ? _errorView()
                : (_filtered.isEmpty
                ? const Center(child: Text('Nothing found'))
                : ListView.builder(
              itemCount: _filtered.length,
              itemBuilder: (ctx, i) {
                final s = _filtered[i];
                final visited = _visited.contains(s.id);
                return Card(
                  color: const Color(0xFF1C182B),
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFF3B3B5A))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                            child: _SpotAssetImage(src: s.imageAsset),
                          ),
                          Positioned(
                            left: 12,
                            top: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black26,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.auto_awesome, size: 16, color: Color(0xFFA9FF68)),
                                  const SizedBox(width: 6),
                                  Text(s.luck.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            right: 12,
                            top: 12,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: const Color(0x30EF4444),
                                side: const BorderSide(color: Color(0x59EF4444)),
                                shape: const StadiumBorder(),
                              ),
                              onPressed: () => _openReport(s),
                              icon: const Icon(Icons.flag, color: Color(0xFFFECACA)),
                              label: const Text('Report', style: TextStyle(color: Color(0xFFFECACA))),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.place, size: 16, color: Colors.white60),
                                const SizedBox(width: 4),
                                Text(s.city, style: const TextStyle(color: Colors.white70)),
                                const SizedBox(width: 12),
                                const Icon(Icons.category, size: 16, color: Colors.white60),
                                const SizedBox(width: 4),
                                Text(s.category, style: const TextStyle(color: Colors.white70)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(s.description),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                FilledButton.icon(
                                  onPressed: visited
                                      ? null
                                      : () {
                                    setState(() {
                                      _visited.add(s.id);
                                      visitedCount += 1;
                                      luckRating = min(100, luckRating + 5);
                                    });
                                    _saveVisits();
                                    _updateProfile();
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Visit logged!')));
                                  },
                                  icon: const Icon(Icons.check),
                                  label: Text(visited ? 'Visited' : 'Mark as Visited'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    setState(() => luckRating = min(100, luckRating + 1));
                                    _updateProfile();
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Luck boosted!')));
                                  },
                                  icon: const Icon(Icons.auto_awesome),
                                  label: const Text('Boost Luck'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ))),
          ),
        ],
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Failed to load data'),
          const SizedBox(height: 8),
          if (_error != null) Text(_error!, style: const TextStyle(color: Colors.white60), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _fetchGuides,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String key) {
    final active = _filter == key;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: active,
        onSelected: (_) => setState(() => _filter = key),
      ),
    );
  }
}

class _SpotAssetImage extends StatelessWidget {
  final String src;
  const _SpotAssetImage({required this.src});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      src,
      height: 180,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      height: 180,
      color: const Color(0xFF221E33),
      alignment: Alignment.center,
      child: const Icon(Icons.landscape, size: 48, color: Colors.white30),
    );
  }
}

// ========================= Submit Tab =========================

class SubmitTab extends StatefulWidget {
  final SharedPreferences prefs;
  const SubmitTab({super.key, required this.prefs});

  @override
  State<SubmitTab> createState() => _SubmitTabState();
}

class _SubmitTabState extends State<SubmitTab> {
  final _formKey = GlobalKey<FormState>();
  final _authorCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _category = '';
  double _luck = 5;
  File? _imageFile;
  String _debug = '—';
  bool _sending = false;

  // Демонстрационный endpoint — замените на свой
  static const String apiBase = 'https://httpbin.org';
  static const String endpointPath = '/post';

  @override
  void initState() {
    super.initState();
    _authorCtrl.text = widget.prefs.getString('author_id') ?? '';
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery, imageQuality: 100);
    if (x == null) return;
    final f = File(x.path);
    final compressed = await _compressImage(f, 1280, 0.8);
    setState(() => _imageFile = compressed);
  }

  Future<File> _compressImage(File src, int maxDim, double quality) async {
    final bytes = await src.readAsBytes();
    final image = img.decodeImage(bytes)!;
    final scale = maxDim / max(image.width, image.height);
    final resized = scale < 1 ? img.copyResize(image, width: (image.width * scale).round()) : image;
    final jpg = img.encodeJpg(resized, quality: (quality * 100).round());
    final dir = await getTemporaryDirectory();
    final out = File('${dir.path}/upload_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await out.writeAsBytes(jpg, flush: true);
    return out;
  }

  Future<void> _prefillLocation() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location denied')));
          }
          return;
        }
      }
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low);
      final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=${pos.latitude}&lon=${pos.longitude}');
      final res = await http.get(url, headers: {'Accept-Language': 'en', 'User-Agent': 'atlas-win-place/1.0'});
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final addr = (data['address'] ?? {}) as Map<String, dynamic>;
      final city = addr['city'] ?? addr['town'] ?? addr['village'] ?? addr['state'] ?? '';
      final country = addr['country'] ?? '';
      setState(() => _cityCtrl.text = [city, country].where((e) => (e as String).isNotEmpty).join(', '));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location filled')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to prefill')));
      }
    }
  }

  String? _validate() {
    if (_titleCtrl.text.trim().isEmpty) return 'Введите Spot Name';
    if (_cityCtrl.text.trim().isEmpty) return 'Введите City / Region';
    if (_category.isEmpty) return 'Выберите Category';
    if (_descCtrl.text.trim().isEmpty) return 'Введите Description';
    return null;
  }

  Future<void> _send() async {
    final err = _validate();
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    setState(() {
      _sending = true;
      _debug = '—';
    });

    String imageBase64 = '';
    if (_imageFile != null && await _imageFile!.exists()) {
      final bytes = await _imageFile!.readAsBytes();
      imageBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
    }

    final payload = {
      'title': _titleCtrl.text.trim(),
      'city': _cityCtrl.text.trim(),
      'category': _category,
      'luck': _luck,
      'description': _descCtrl.text.trim(),
      'image': imageBase64,
    };

    widget.prefs.setString('author_id', _authorCtrl.text.trim());

    try {
      final uri = Uri.parse('$apiBase$endpointPath?id=1');
      final res = await _postWithTimeout(uri, payload, const Duration(seconds: 15));
      if (res.ok) {
        setState(() {
          _debug = const JsonEncoder.withIndent('  ').convert({
            'ok': true,
            'status': res.statusCode,
            'response': res.bodyParsed,
            'url': uri.toString(),
          });
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Submitted for review!')));
        }
        _formKey.currentState?.reset();
        setState(() {
          _imageFile = null;
          _luck = 5;
          _category = '';
          _titleCtrl.clear();
          _cityCtrl.clear();
          _descCtrl.clear();
        });
      } else {
        setState(() {
          _debug = const JsonEncoder.withIndent('  ').convert({
            'ok': false,
            'status': res.statusCode,
            'statusText': res.statusText,
            'response': res.bodyParsed,
            'url': uri.toString(),
          });
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error ${res.statusCode}')));
        }
      }
    } catch (e) {
      final url = '$apiBase$endpointPath?id=${Uri.encodeQueryComponent(_authorCtrl.text.trim())}';
      final diag = _analyzeError(e, url);
      setState(() => _debug = const JsonEncoder.withIndent('  ').convert(diag));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(diag['code'] as String)));
      }
    } finally {
      setState(() => _sending = false);
    }
  }

  Future<_HttpResult> _postWithTimeout(Uri url, Map<String, dynamic> body, Duration timeout) async {
    final client = http.Client();
    try {
      final res = await client
          .post(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body))
          .timeout(timeout);
      final ct = res.headers['content-type'] ?? '';
      dynamic parsed;
      try {
        parsed = ct.contains('application/json') ? jsonDecode(res.body) : res.body;
      } catch (_) {
        parsed = res.body;
      }
      return _HttpResult(ok: res.statusCode >= 200 && res.statusCode < 300, statusCode: res.statusCode, statusText: res.reasonPhrase ?? '', bodyParsed: parsed);
    } on TimeoutException catch (e) {
      throw e;
    } on SocketException catch (e) {
      throw e;
    } finally {
      client.close();
    }
  }

  Map<String, dynamic> _analyzeError(Object err, String url) {
    final List<String> hints = [];
    String code = 'NETWORK_ERROR';
    String message = err.toString();
    if (err is TimeoutException) {
      code = 'ABORT_ERROR';
      hints.add('Timeout: server took too long to respond (15s).');
    }
    if (err is SocketException) {
      hints.add('SocketException: DNS/TLS/connection refused.');
    }
    return {'ok': false, 'code': code, 'message': message, 'hints': hints, 'url': url};
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            const SizedBox(height: 8),
            const Center(child: Text('Share a New Luck Spot', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22))),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _authorCtrl,
                    decoration: const InputDecoration(hintText: 'Author ID (required for ?id=...)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(controller: _titleCtrl, decoration: const InputDecoration(hintText: 'Spot Name')),
            const SizedBox(height: 8),
            TextFormField(
              controller: _cityCtrl,
              decoration: InputDecoration(
                hintText: 'City / Region',
                suffixIcon: IconButton(icon: const Icon(Icons.my_location), onPressed: _prefillLocation),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(hintText: 'Select Category'),
              value: _category.isEmpty ? null : _category,
              items: const [
                DropdownMenuItem(value: 'Nature', child: Text('Nature')),
                DropdownMenuItem(value: 'Urban', child: Text('Urban')),
                DropdownMenuItem(value: 'Historical', child: Text('Historical')),
                DropdownMenuItem(value: 'Coastal', child: Text('Coastal')),
              ],
              onChanged: (v) => setState(() => _category = v ?? ''),
            ),
            const SizedBox(height: 8),
            const Text('Luck Intensity (1-10)'),
            Slider(
              value: _luck,
              min: 1,
              max: 10,
              divisions: 9,
              label: _luck.toStringAsFixed(0),
              onChanged: (v) => setState(() => _luck = v),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(hintText: 'Description'),
              maxLines: 4,
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.cloud_upload),
              label: const Text('Upload a Photo'),
            ),
            if (_imageFile != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_imageFile!, height: 180, fit: BoxFit.cover),
              ),
              const SizedBox(height: 6),
              const Text('Image is compressed to JPEG (max 1280px, q=0.8)', style: TextStyle(fontSize: 12, color: Colors.white54)),
            ],
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _sending ? null : _send,
              child: _sending ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Send for Review'),
            ),
            const SizedBox(height: 16),
            const Text('Submit Details', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1C182B),
                border: Border.all(color: const Color(0xFF3B3B5A)),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(12),
              child: Text(_debug, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}

class _HttpResult {
  final bool ok;
  final int statusCode;
  final String statusText;
  final dynamic bodyParsed;
  _HttpResult({required this.ok, required this.statusCode, required this.statusText, required this.bodyParsed});
}

// ========================= Analytics Tab =========================

class AnalyticsTab extends StatelessWidget {
  const AnalyticsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final series1 = [
      _RegionData('Kyoto', 85),
      _RegionData('Wiltshire', 78),
      _RegionData('Paris', 72),
      _RegionData('Himalayas', 90),
    ];
    final visits = [
      _TimeData(DateTime(2025, 1, 1), 10),
      _TimeData(DateTime(2025, 2, 1), 15),
      _TimeData(DateTime(2025, 3, 1), 12),
      _TimeData(DateTime(2025, 4, 1), 20),
      _TimeData(DateTime(2025, 5, 1), 18),
      _TimeData(DateTime(2025, 6, 1), 25),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
      child: ListView(
        children: [
          const SizedBox(height: 8),
          const Center(child: Text('Your Luck Insights', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22))),
          const SizedBox(height: 12),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Luck Impact by Region', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 220,
                  child: BarChart(
                    BarChartData(
                      gridData: FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: true, reservedSize: 32),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final i = value.toInt();
                              if (i < 0 || i >= series1.length) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(series1[i].region, style: const TextStyle(fontSize: 11)),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: List.generate(series1.length, (i) {
                        final d = series1[i];
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: d.value.toDouble(),
                              width: 18,
                              borderRadius: BorderRadius.circular(6),
                              color: [const Color(0xFFA9FF68), const Color(0xFF68D5FF), const Color(0xFFC77DFF), const Color(0xFFA9FF68)][i % 4],
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Visit Trend Over Time', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 220,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: true, drawVerticalLine: false),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              final i = value.toInt();
                              if (i < 0 || i >= visits.length) return const SizedBox.shrink();
                              final d = visits[i].time;
                              return Text(DateFormat.MMM().format(d), style: const TextStyle(fontSize: 11));
                            },
                          ),
                        ),
                      ),
                      minX: 0,
                      maxX: (visits.length - 1).toDouble(),
                      minY: 0,
                      maxY: visits.map((e) => e.value).reduce(max).toDouble() + 2,
                      lineBarsData: [
                        LineChartBarData(
                          isCurved: true,
                          color: const Color(0xFF68D5FF),
                          barWidth: 3,
                          dotData: FlDotData(show: true),
                          spots: List.generate(visits.length, (i) => FlSpot(i.toDouble(), visits[i].value.toDouble())),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Top Luck Spots', style: TextStyle(fontWeight: FontWeight.w600)),
                SizedBox(height: 8),
                _TopRow(title: 'Whispering Falls', value: '+85%'),
                _TopRow(title: 'Sunstone Pinnacle', value: '+78%'),
                _TopRow(title: 'Gilded Fountain', value: '+72%'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) => Card(
    color: const Color(0xFF1C182B),
    margin: const EdgeInsets.only(bottom: 8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: Color(0xFF3B3B5A)),
    ),
    child: Padding(padding: const EdgeInsets.all(12), child: child),
  );
}

class _RegionData {
  final String region;
  final int value;
  _RegionData(this.region, this.value);
}

class _TimeData {
  final DateTime time;
  final int value;
  _TimeData(this.time, this.value);
}

class _TopRow extends StatelessWidget {
  final String title;
  final String value;
  const _TopRow({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70)),
          Text(value, style: const TextStyle(color: Color(0xFFA9FF68), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ========================= Profile Tab =========================

class ProfileTab extends StatefulWidget {
  final SharedPreferences prefs;
  const ProfileTab({super.key, required this.prefs});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final _nameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  String? _avatarPath;
  int luckRating = 88;
  int visited = 12;
  int submitted = 3;

  @override
  void initState() {
    super.initState();
    final raw = widget.prefs.getString('profile') ?? '{}';
    final map = jsonDecode(raw) as Map<String, dynamic>;
    _nameCtrl.text = (map['name'] ?? 'Alexia') as String;
    _cityCtrl.text = (map['city'] ?? 'Kyoto, Japan') as String;
    _avatarPath = map['avatar'] as String?;
    luckRating = (map['luckRating'] ?? 88) as int;
    visited = (map['visitedCount'] ?? 12) as int;
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (x == null) return;
    setState(() => _avatarPath = x.path);
  }

  void _save() {
    final map = {
      'name': _nameCtrl.text,
      'city': _cityCtrl.text,
      'avatar': _avatarPath ?? '',
      'luckRating': luckRating,
      'visitedCount': visited,
    };
    widget.prefs.setString('profile', jsonEncode(map));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved!')));
  }

  void _reset() {
    widget.prefs.clear();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('App data cleared')));
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
              (_) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
      child: ListView(
        children: [
          const SizedBox(height: 8),
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundImage: _avatarPath != null && _avatarPath!.isNotEmpty ? FileImage(File(_avatarPath!)) : null,
                  child: _avatarPath == null || _avatarPath!.isEmpty ? const Icon(Icons.person, size: 48) : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: FloatingActionButton.small(
                    onPressed: _pickAvatar,
                    child: const Icon(Icons.edit),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextField(controller: _nameCtrl, textAlign: TextAlign.center, decoration: const InputDecoration(hintText: 'Enter Name')),
          const SizedBox(height: 8),
          TextField(controller: _cityCtrl, textAlign: TextAlign.center, decoration: const InputDecoration(hintText: 'Enter City')),
          const SizedBox(height: 16),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Luck Rating', style: TextStyle(color: Color(0xFFA9FF68), fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('$luckRating/100', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFA9FF68))),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: LinearProgressIndicator(
                          value: luckRating / 100,
                          backgroundColor: Colors.white24,
                          color: const Color(0xFF68D5FF),
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _statCard('Spots Visited', visited.toString())),
              const SizedBox(width: 8),
              Expanded(child: _statCard('Spots Submitted', submitted.toString())),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: const Text('Save Profile'))),
              const SizedBox(width: 8),
              Expanded(child: FilledButton.icon(onPressed: _reset, icon: const Icon(Icons.rotate_left), label: const Text('Reset'))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value) => Card(
    color: const Color(0xFF1C182B),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFF3B3B5A))),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: Colors.white60)),
        ],
      ),
    ),
  );

  Widget _card({required Widget child}) => Card(
    color: const Color(0xFF1C182B),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: Color(0xFF3B3B5A)),
    ),
    child: Padding(padding: const EdgeInsets.all(12), child: child),
  );
}

// ========================= Reviews Tab =========================

class ReviewsTab extends StatefulWidget {
  const ReviewsTab({super.key});

  @override
  State<ReviewsTab> createState() => _ReviewsTabState();
}

class _ReviewsTabState extends State<ReviewsTab> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final items = [
      _ReviewItem(
        text: '“After visiting Whispering Falls, small wins started to happen more often. The app showed me nearby luck spots I never knew about.”',
        meta: 'Kyoto route · +12 luck',
        image: 'assets/images/testimonial_1.png',
      ),
      _ReviewItem(
        text: '“With Sunstone Pinnacle and Gilded Fountain I finally hit two tough goals. Routes and boosts are spot on.”',
        meta: 'Europe trip · +9 luck',
        image: 'assets/images/testimonial_2.png',
      ),
      _ReviewItem(
        text: '“Didn’t believe it until Mystic Lake. Now I start my day by checking the High Luck filter.”',
        meta: 'Canada trail · +15 luck',
        image: 'assets/images/testimonial_3.png',
      ),
    ];

    final isWide = MediaQuery.of(context).size.width >= 700;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
      child: Column(
        children: [
          const SizedBox(height: 8),
          const Text('Reviews', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (isWide)
            GridView.builder(
              shrinkWrap: true,
              itemCount: items.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 3.2, crossAxisSpacing: 10, mainAxisSpacing: 10),
              itemBuilder: (_, i) => _reviewCard(items[i]),
            )
          else ...[
            _reviewCard(items[_index]),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(items.length, (i) {
                final active = i == _index;
                return GestureDetector(
                  onTap: () => setState(() => _index = i),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: active ? const Color(0xFFC77DFF) : const Color(0xFF444444), shape: BoxShape.circle),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }

  Widget _reviewCard(_ReviewItem r) {
    return Card(
      color: const Color(0xFF1C182B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFF3B3B5A))),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _ReviewImage(src: r.image),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.text, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text(r.meta, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewItem {
  final String text;
  final String meta;
  final String image;
  _ReviewItem({required this.text, required this.meta, required this.image});
}

class _ReviewImage extends StatelessWidget {
  final String src;
  const _ReviewImage({required this.src});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      src,
      width: 88,
      height: 88,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: 88,
        height: 88,
        color: const Color(0xFF221E33),
        alignment: Alignment.center,
        child: const Icon(Icons.person, color: Colors.white30, size: 32),
      ),
    );
  }
}