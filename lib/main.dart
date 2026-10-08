import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String backend = 'https://mrpingshop.ir';
const String assetsEndpoint = '$backend/api/api/assets';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PingMarketApp());
}

class PingMarketApp extends StatefulWidget {
  const PingMarketApp({super.key});
  @override
  State<PingMarketApp> createState() => _PingMarketAppState();
}

class _PingMarketAppState extends State<PingMarketApp> {
  ThemeMode themeMode = ThemeMode.dark;
  Locale locale = const Locale('fa');

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      themeMode = (p.getBool('dark') ?? true) ? ThemeMode.dark : ThemeMode.light;
      locale = Locale(p.getString('lang') ?? 'fa');
    });
  }

  Future<void> _setDark(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('dark', value);
    if (mounted) {
      setState(() => themeMode = value ? ThemeMode.dark : ThemeMode.light);
    }
  }

  Future<void> _setLang(String value) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('lang', value);
    if (mounted) setState(() => locale = Locale(value));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ping Market',
      themeMode: themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.amber,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.amber,
        brightness: Brightness.dark,
      ),
      locale: locale,
      home: HomePage(
        dark: themeMode == ThemeMode.dark,
        lang: locale.languageCode,
        onDarkChanged: _setDark,
        onLangChanged: _setLang,
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final bool dark;
  final String lang;
  final ValueChanged<bool> onDarkChanged;
  final ValueChanged<String> onLangChanged;

  const HomePage({
    super.key,
    required this.dark,
    required this.lang,
    required this.onDarkChanged,
    required this.onLangChanged,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> assets = [];
  bool loading = true;
  String? error;
  int refreshSeconds = 30;
  bool toman = true;
  int tab = 0;
  Timer? timer;
  DateTime? updatedAt;

  bool get fa => widget.lang == 'fa';

  @override
  void initState() {
    super.initState();
    loadSettings();
    getPrices();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> loadSettings() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      refreshSeconds = p.getInt('refresh') ?? 30;
      toman = p.getBool('toman') ?? true;
    });
    startTimer();
  }

  void startTimer() {
    timer?.cancel();
    timer = Timer.periodic(Duration(seconds: refreshSeconds), (_) => getPrices());
  }

  Future<void> getPrices() async {
    if (!mounted) return;
    setState(() {
      loading = assets.isEmpty;
      error = null;
    });

    try {
      final response = await http
          .get(
            Uri.parse(assetsEndpoint),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final list = (data['assets'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      if (!mounted) return;
      setState(() {
        assets = list;
        loading = false;
        updatedAt = DateTime.now();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = fa ? 'دریافت قیمت‌ها ناموفق بود' : 'Failed to load prices';
      });
    }
  }

  double displayValue(dynamic value) {
    final n = (value as num).toDouble();
    return toman ? n / 10 : n;
  }

  String formatNumber(dynamic value) {
    final n = displayValue(value);
    return n.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+$)'),
          (m) => '${m[1]},',
        );
  }

  String titleFor(Map<String, dynamic> a) {
    if (fa) return a['labelFa']?.toString() ?? a['code'].toString();
    return a['labelEn']?.toString() ?? a['code'].toString();
  }

  String unitText() =>
      toman ? (fa ? 'تومان' : 'Toman') : (fa ? 'ریال' : 'Rial');

  Map<String, dynamic>? byCode(String code) {
    for (final a in assets) {
      if (a['code'] == code) return a;
    }
    return null;
  }

  Widget priceCard(String code) {
    final a = byCode(code);
    if (a == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              radius: 27,
              child: Text(
                a['icon']?.toString() ?? '₿',
                style: const TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titleFor(a),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    '${formatNumber(a['value'])} ${unitText()}',
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> openSettings() async {
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                fa ? 'تنظیمات' : 'Settings',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SwitchListTile(
                title: Text(fa ? 'حالت تاریک' : 'Dark mode'),
                value: widget.dark,
                onChanged: (v) {
                  widget.onDarkChanged(v);
                  setSheet(() {});
                },
              ),
              SwitchListTile(
                title: Text(fa ? 'نمایش تومان' : 'Show Toman'),
                value: toman,
                onChanged: (v) async {
                  final p = await SharedPreferences.getInstance();
                  await p.setBool('toman', v);
                  if (mounted) setState(() => toman = v);
                  setSheet(() {});
                },
              ),
              ListTile(
                title: Text(fa ? 'زبان' : 'Language'),
                trailing: DropdownButton<String>(
                  value: widget.lang,
                  items: const [
                    DropdownMenuItem(value: 'fa', child: Text('فارسی')),
                    DropdownMenuItem(value: 'en', child: Text('English')),
                  ],
                  onChanged: (v) {
                    if (v != null) widget.onLangChanged(v);
                    setSheet(() {});
                  },
                ),
              ),
              ListTile(
                title: Text(fa ? 'بروزرسانی خودکار' : 'Auto refresh'),
                trailing: DropdownButton<int>(
                  value: refreshSeconds,
                  items: const [15, 30, 60, 120]
                      .map((v) => DropdownMenuItem(value: v, child: Text('${v}s')))
                      .toList(),
                  onChanged: (v) async {
                    if (v == null) return;
                    final p = await SharedPreferences.getInstance();
                    await p.setInt('refresh', v);
                    if (mounted) setState(() => refreshSeconds = v);
                    startTimer();
                    setSheet(() {});
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget dashboard() {
    if (loading) return const Center(child: CircularProgressIndicator());

    if (error != null && assets.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error!),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: getPrices,
              icon: const Icon(Icons.refresh),
              label: Text(fa ? 'تلاش دوباره' : 'Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: getPrices,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  const Icon(Icons.show_chart, size: 34),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fa ? 'بازار لحظه‌ای' : 'Live Market',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          updatedAt == null
                              ? ''
                              : '${fa ? "آخرین بروزرسانی" : "Updated"}: '
                                  '${updatedAt!.hour.toString().padLeft(2, '0')}:'
                                  '${updatedAt!.minute.toString().padLeft(2, '0')}',
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: getPrices,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          priceCard('USD_RLS'),
          priceCard('EUR_RLS'),
          priceCard('GOLD_18_RLS'),
          priceCard('BTC_RLS'),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(error!, textAlign: TextAlign.center),
            ),
        ],
      ),
    );
  }

  Widget favorites() => Center(
        child: Text(
          fa
              ? 'هنوز ارزی به علاقه‌مندی‌ها اضافه نشده است'
              : 'No favorites yet',
          style: const TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ping Market',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: openSettings,
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: tab == 0 ? dashboard() : favorites(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: fa ? 'بازار' : 'Market',
          ),
          NavigationDestination(
            icon: const Icon(Icons.star_border),
            selectedIcon: const Icon(Icons.star),
            label: fa ? 'علاقه‌مندی' : 'Favorites',
          ),
        ],
      ),
    );
  }
}
