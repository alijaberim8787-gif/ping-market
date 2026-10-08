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
  ThemeMode themeMode = ThemeMode.light;
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
      themeMode =
          (p.getBool('dark') ?? false) ? ThemeMode.dark : ThemeMode.light;
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
      theme: _lightTheme(),
      darkTheme: _darkTheme(),
      locale: locale,
      home: HomePage(
        dark: themeMode == ThemeMode.dark,
        lang: locale.languageCode,
        onDarkChanged: _setDark,
        onLangChanged: _setLang,
      ),
    );
  }

  ThemeData _lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF2F2F7),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFD4AF37),
        brightness: Brightness.light,
      ),
      fontFamily: 'Vazirmatn',
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF2F2F7),
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.black,
        titleTextStyle: TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  ThemeData _darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF000000),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFD4AF37),
        brightness: Brightness.dark,
      ),
      fontFamily: 'Vazirmatn',
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF000000),
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
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

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  List<Map<String, dynamic>> assets = [];
  bool loading = true;
  String? error;
  int refreshSeconds = 30;
  bool toman = true;
  int tab = 0;
  Timer? timer;
  DateTime? updatedAt;
  bool _refreshing = false;
  late AnimationController _animController;

  bool get fa => widget.lang == 'fa';

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    loadSettings();
    getPrices();
  }

  @override
  void dispose() {
    timer?.cancel();
    _animController.dispose();
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
      _refreshing = true;
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
        _refreshing = false;
        updatedAt = DateTime.now();
      });
      _animController.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        _refreshing = false;
        error = fa ? 'دریافت قیمت‌ها ناموفق بود' : 'Failed to load prices';
      });
    }
  }

  double displayValue(dynamic value) {
    if (value == null) return 0;
    final n = (value as num).toDouble();
    return toman ? n / 10 : n;
  }

  String formatNumber(dynamic value) {
    if (value == null) return '—';
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

  Color cardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1C1C1E)
        : Colors.white;
  }

  Color textColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black;
  }

  Color subTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white60
        : Colors.black54;
  }

  Widget modernPriceCard(String code, {int index = 0}) {
    final a = byCode(code);
    if (a == null) return const SizedBox.shrink();

    final delay = index * 0.1;
    final animation = CurvedAnimation(
      parent: _animController,
      curve: Interval(delay, (delay + 0.5).clamp(0.0, 1.0),
          curve: Curves.easeOutCubic),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(animation),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: cardColor(context),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {},
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: _iconBg(a['code']),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        a['icon']?.toString() ?? '₿',
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            titleFor(a),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: subTextColor(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                formatNumber(a['value']),
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: textColor(context),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                unitText(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: subTextColor(context),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_left,
                      color: subTextColor(context),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _iconBg(String? code) {
    switch (code) {
      case 'USD_RLS':
        return const Color(0xFFE8F5E9);
      case 'EUR_RLS':
        return const Color(0xFFE3F2FD);
      case 'GOLD_18_RLS':
        return const Color(0xFFFFF8E1);
      case 'BTC_RLS':
        return const Color(0xFFFFF3E0);
      default:
        return const Color(0xFFF5F5F5);
    }
  }

  Widget sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: subTextColor(context),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Future<void> openSettings() async {
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: cardColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                fa ? 'تنظیمات' : 'Settings',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: textColor(context),
                ),
              ),
              const SizedBox(height: 10),
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
                      .map((v) =>
                          DropdownMenuItem(value: v, child: Text('${v}s')))
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
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null && assets.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 60,
              color: subTextColor(context),
            ),
            const SizedBox(height: 16),
            Text(error!, style: TextStyle(color: subTextColor(context))),
            const SizedBox(height: 16),
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
      color: const Color(0xFFD4AF37),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
        children: [
          // Header card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: Theme.of(context).brightness == Brightness.dark
                    ? [const Color(0xFF1C1C1E), const Color(0xFF2C2C2E)]
                    : [Colors.white, const Color(0xFFFAFAFA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD4AF37), Color(0xFFB8860B)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.show_chart_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fa ? 'بازار لحظه‌ای' : 'Live Market',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: textColor(context),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        updatedAt == null
                            ? (fa ? 'در حال بروزرسانی...' : 'Updating...')
                            : '${fa ? "بروزرسانی" : "Updated"}: '
                                '${updatedAt!.hour.toString().padLeft(2, '0')}:'
                                '${updatedAt!.minute.toString().padLeft(2, '0')}:'
                                '${updatedAt!.second.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 12,
                          color: subTextColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: _refreshing ? 1 : 0,
                  duration: const Duration(milliseconds: 600),
                  child: IconButton(
                    onPressed: getPrices,
                    icon: const Icon(Icons.refresh_rounded),
                    color: const Color(0xFFD4AF37),
                  ),
                ),
              ],
            ),
          ),

          // Currency section
          sectionTitle(fa ? 'ارز' : 'CURRENCY'),
          modernPriceCard('USD_RLS', index: 0),
          modernPriceCard('EUR_RLS', index: 1),

          // Gold section
          sectionTitle(fa ? 'طلا' : 'GOLD'),
          modernPriceCard('GOLD_18_RLS', index: 2),

          // Crypto section
          sectionTitle(fa ? 'ارز دیجیتال' : 'CRYPTO'),
          modernPriceCard('BTC_RLS', index: 3),

          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: subTextColor(context), fontSize: 12),
              ),
            ),

          const SizedBox(height: 20),
          Center(
            child: Text(
              'Ping Market © 2026',
              style: TextStyle(
                fontSize: 11,
                color: subTextColor(context).withOpacity(0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget favorites() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star_border_rounded,
              size: 60,
              color: subTextColor(context),
            ),
            const SizedBox(height: 16),
            Text(
              fa
                  ? 'هنوز ارزی به علاقه‌مندی‌ها اضافه نشده است'
                  : 'No favorites yet',
              style: TextStyle(fontSize: 15, color: subTextColor(context)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFD4AF37), Color(0xFFB8860B)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: const Text(
                'P',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text('Ping Market'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: openSettings,
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: tab == 0 ? dashboard() : favorites(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: cardColor(context),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          backgroundColor: cardColor(context),
          indicatorColor: const Color(0xFFD4AF37).withOpacity(0.2),
          selectedIndex: tab,
          onDestinationSelected: (i) => setState(() => tab = i),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(
                Icons.home_rounded,
                color: Color(0xFFD4AF37),
              ),
              label: fa ? 'بازار' : 'Market',
            ),
            NavigationDestination(
              icon: const Icon(Icons.star_border_rounded),
              selectedIcon: const Icon(
                Icons.star_rounded,
                color: Color(0xFFD4AF37),
              ),
              label: fa ? 'علاقه‌مندی' : 'Favorites',
            ),
          ],
        ),
      ),
    );
  }
}
