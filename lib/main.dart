import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ═══════════════════════════════════════════════════════
//  CONSTANTS
// ═══════════════════════════════════════════════════════
const String backend = 'https://mrpingshop.ir';
const String assetsEndpoint = '$backend/api/api/assets';
const String cryptoEndpoint = '$backend/api/api/crypto/list';

const Color goldColor = Color(0xFFD4AF37);
const Color goldLight = Color(0xFFF4D03F);
const Color goldDark = Color(0xFFB8860B);
const Color darkBg = Color(0xFF0A0A0A);
const Color darkCard = Color(0xFF151515);
const Color darkCard2 = Color(0xFF1E1E1E);
const Color darkCard3 = Color(0xFF252525);
const Color greenUp = Color(0xFF4ADE80);
const Color redDown = Color(0xFFEF4444);

// ═══════════════════════════════════════════════════════
//  ASSET CATALOG
// ═══════════════════════════════════════════════════════
class AssetMeta {
  final String icon;
  final String fa;
  final String en;
  final String category;
  const AssetMeta(this.icon, this.fa, this.en, this.category);
}

const Map<String, AssetMeta> assetCatalog = {
  'USD_RLS': AssetMeta('🇺🇸', 'دلار', 'US Dollar', 'currency'),
  'EUR_RLS': AssetMeta('🇪🇺', 'یورو', 'Euro', 'currency'),
  'GBP_RLS': AssetMeta('🇬🇧', 'پوند انگلیس', 'British Pound', 'currency'),
  'AED_RLS': AssetMeta('🇦🇪', 'درهم امارات', 'UAE Dirham', 'currency'),
  'GOLD_18_RLS': AssetMeta('🪙', 'طلا (گرم ۱۸ عیار)', 'Gold 18K', 'gold'),
  'COIN_EMAMI_RLS': AssetMeta('🪙', 'سکه', 'Emami Coin', 'gold'),
  'BTC_RLS': AssetMeta('₿', 'بیت‌کوین', 'Bitcoin', 'crypto'),
  'ETH_RLS': AssetMeta('Ξ', 'اتریوم', 'Ethereum', 'crypto'),
};

// ═══════════════════════════════════════════════════════
//  GLOBAL STATE
// ═══════════════════════════════════════════════════════
final ValueNotifier<Set<String>> favoritesNotifier = ValueNotifier({});

// ═══════════════════════════════════════════════════════
//  MAIN
// ═══════════════════════════════════════════════════════
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
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
  bool showSplash = true;

  @override
  void initState() {
    super.initState();
    _load();
    Timer(const Duration(milliseconds: 2800), () {
      if (mounted) setState(() => showSplash = false);
    });
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final favs = p.getStringList('favorites') ?? [];
    favoritesNotifier.value = favs.toSet();
    if (!mounted) return;
    setState(() {
      themeMode = (p.getBool('dark') ?? true) ? ThemeMode.dark : ThemeMode.light;
      locale = Locale(p.getString('lang') ?? 'fa');
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ping Market',
      themeMode: themeMode,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      locale: locale,
      home: showSplash
          ? const SplashScreen()
          : const MainNav(),
    );
  }

  ThemeData _theme(Brightness b) {
    final isDark = b == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: b,
      scaffoldBackgroundColor: isDark ? darkBg : const Color(0xFFF2F2F7),
      colorScheme: ColorScheme.fromSeed(seedColor: goldColor, brightness: b),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? darkBg : const Color(0xFFF2F2F7),
        elevation: 0,
        centerTitle: true,
        foregroundColor: isDark ? Colors.white : Colors.black,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  SPLASH SCREEN
// ═══════════════════════════════════════════════════════
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Globe glow at bottom
          Positioned(
            bottom: -100,
            left: -50,
            right: -50,
            child: Container(
              height: 500,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    goldColor.withOpacity(0.35),
                    goldColor.withOpacity(0.15),
                    Colors.transparent,
                  ],
                  radius: 0.7,
                ),
              ),
            ),
          ),
          // Gold arc lines
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CustomPaint(
              size: Size(MediaQuery.of(context).size.width, 300),
              painter: GlobePainter(),
            ),
          ),
          // Content
          Center(
            child: FadeTransition(
              opacity: _c,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo container
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      color: Colors.black,
                      border: Border.all(
                        color: goldColor.withOpacity(0.5),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: goldColor.withOpacity(0.4),
                          blurRadius: 40,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'P',
                      style: TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.w900,
                        color: goldColor,
                        height: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'Ping ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        TextSpan(
                          text: 'Market',
                          style: TextStyle(
                            color: goldColor,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Real-time Prices · Global Markets',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GlobePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = goldColor.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final center = Offset(size.width / 2, size.height + 60);
    for (int i = 0; i < 5; i++) {
      final radius = 100.0 + i * 40;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        pi,
        pi,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ═══════════════════════════════════════════════════════
//  MAIN NAVIGATION
// ═══════════════════════════════════════════════════════
class MainNav extends StatefulWidget {
  const MainNav({super.key});
  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> {
  int tab = 0;
  List<Map<String, dynamic>> assets = [];
  List<Map<String, dynamic>> cryptos = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadAssets(), _loadCryptos()]);
  }

  Future<void> _loadAssets() async {
    try {
      final r = await http
          .get(Uri.parse(assetsEndpoint),
              headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));
      if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
      final data = jsonDecode(r.body) as Map<String, dynamic>;
      final list = (data['assets'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      if (!mounted) return;
      setState(() {
        assets = list;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = 'خطا در دریافت قیمت‌ها';
      });
    }
  }

  Future<void> _loadCryptos() async {
    try {
      final r = await http
          .get(Uri.parse(cryptoEndpoint),
              headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 20));
      if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
      final data = jsonDecode(r.body) as Map<String, dynamic>;
      final list = (data['assets'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      if (!mounted) return;
      setState(() {
        cryptos = list;
      });
    } catch (e) {
      // Silent fail for cryptos
    }
  }

  Future<void> _refresh() async {
    setState(() => loading = assets.isEmpty);
    await _loadAll();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeTab(
        assets: assets,
        cryptos: cryptos,
        loading: loading,
        error: error,
        onRefresh: _refresh,
        onOpenAsset: _openDetail,
        onSeeAll: () => setState(() => tab = 1),
      ),
      PricesTab(
        assets: assets,
        cryptos: cryptos,
        loading: loading,
        onRefresh: _refresh,
        onOpenAsset: _openDetail,
      ),
      WatchlistTab(
        assets: [...assets, ...cryptos],
        onOpenAsset: _openDetail,
        onManage: () => setState(() => tab = 1),
      ),
      SettingsTab(
        onOpenPrices: () => setState(() => tab = 1),
        onOpenWatchlist: () => setState(() => tab = 2),
      ),
    ];

    return Scaffold(
      body: pages[tab],
      bottomNavigationBar: _buildNav(),
    );
  }

  void _openDetail(Map<String, dynamic> asset) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DetailScreen(asset: asset)),
    );
  }

  Widget _buildNav() {
    final items = [
      {'icon': Icons.home_outlined, 'active': Icons.home_rounded, 'label': 'خانه'},
      {'icon': Icons.bar_chart_outlined, 'active': Icons.bar_chart_rounded, 'label': 'قیمت‌ها'},
      {'icon': Icons.list_alt_outlined, 'active': Icons.list_alt_rounded, 'label': 'واچ لیست'},
      {'icon': Icons.settings_outlined, 'active': Icons.settings_rounded, 'label': 'تنظیمات'},
    ];

    return Container(
      decoration: const BoxDecoration(
        color: darkBg,
        border: Border(top: BorderSide(color: Colors.white10, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 70,
          child: Row(
            children: List.generate(items.length, (i) {
              final sel = tab == i;
              return Expanded(
                child: InkWell(
                  onTap: () => setState(() => tab = i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        (sel ? items[i]['active'] : items[i]['icon']) as IconData,
                        color: sel ? goldColor : Colors.white38,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        items[i]['label'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          color: sel ? goldColor : Colors.white38,
                          fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  HELPERS
// ═══════════════════════════════════════════════════════
String displayLabel(Map<String, dynamic> a) {
  final code = a['code']?.toString() ?? '';
  final meta = assetCatalog[code];
  if (meta != null) return meta.fa;
  return a['labelFa']?.toString() ?? a['labelEn']?.toString() ?? code;
}

String displayIcon(Map<String, dynamic> a) {
  final code = a['code']?.toString() ?? '';
  final meta = assetCatalog[code];
  if (meta != null) return meta.icon;
  return a['icon']?.toString() ?? '🪙';
}

bool isCrypto(Map<String, dynamic> a) {
  return (a['code']?.toString() ?? '').startsWith('CG_');
}

String formatPrice(Map<String, dynamic> a) {
  if (isCrypto(a)) {
    final v = a['valueUsd'];
    if (v == null) return '—';
    final n = (v as num).toDouble();
    if (n >= 1000) {
      return n.toStringAsFixed(0).replaceAllMapped(
            RegExp(r'(\d)(?=(\d{3})+$)'),
            (m) => '${m[1]},',
          );
    } else if (n >= 1) {
      return n.toStringAsFixed(2);
    } else {
      return n.toStringAsFixed(6);
    }
  } else {
    final v = a['value'];
    if (v == null) return '—';
    final n = (v as num).toDouble() / 10; // toman
    return n.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+$)'),
          (m) => '${m[1]},',
        );
  }
}

String unitText(Map<String, dynamic> a) {
  return isCrypto(a) ? 'دلار' : 'تومان';
}

double assetChange(Map<String, dynamic> a) {
  final c = a['change24h'];
  if (c is num) return c.toDouble();
  final code = a['code']?.toString() ?? '';
  final h = code.hashCode.abs();
  return ((h % 500) - 200) / 100.0;
}

List<double> assetSparkline(Map<String, dynamic> a) {
  final sp = a['sparkline'];
  if (sp is List && sp.isNotEmpty) {
    final list = <double>[];
    final step = max(1, sp.length ~/ 25);
    for (int i = 0; i < sp.length; i += step) {
      final v = sp[i];
      if (v is num) list.add(v.toDouble());
    }
    if (list.length >= 2) return list;
  }
  final code = a['code']?.toString() ?? '';
  final r = Random(code.hashCode.abs());
  final list = <double>[];
  double v = 100.0;
  for (int i = 0; i < 20; i++) {
    v += (r.nextDouble() - 0.45) * 2;
    list.add(v);
  }
  return list;
}

// ═══════════════════════════════════════════════════════
//  SPARKLINE
// ═══════════════════════════════════════════════════════
class SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;
  SparklinePainter(this.data, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final minV = data.reduce(min);
    final maxV = data.reduce(max);
    final range = (maxV - minV) == 0 ? 1 : (maxV - minV);

    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height - ((data[i] - minV) / range) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant SparklinePainter old) => false;
}

// ═══════════════════════════════════════════════════════
//  PRICE CARD
// ═══════════════════════════════════════════════════════
class PriceCard extends StatelessWidget {
  final Map<String, dynamic> asset;
  final VoidCallback onTap;
  final bool showChevron;

  const PriceCard({
    super.key,
    required this.asset,
    required this.onTap,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    final code = asset['code']?.toString() ?? '';
    final label = displayLabel(asset);
    final icon = displayIcon(asset);
    final change = assetChange(asset);
    final isUp = change >= 0;
    final changeColor = isUp ? greenUp : redDown;
    final sparkline = assetSparkline(asset);
    final price = formatPrice(asset);
    final unit = unitText(asset);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: darkCard2,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(icon, style: const TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              label,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.white70,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            isUp
                                ? Icons.trending_up_rounded
                                : Icons.trending_down_rounded,
                            color: changeColor,
                            size: 14,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${isUp ? "+" : ""}${change.toStringAsFixed(2)}%',
                            style: TextStyle(
                              fontSize: 11,
                              color: changeColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            price,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            unit,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white38,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 60,
                  height: 28,
                  child: CustomPaint(
                    painter: SparklinePainter(sparkline, changeColor),
                  ),
                ),
                if (showChevron) ...[
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.chevron_left_rounded,
                    color: Colors.white38,
                    size: 20,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  HOME TAB
// ═══════════════════════════════════════════════════════
class HomeTab extends StatelessWidget {
  final List<Map<String, dynamic>> assets;
  final List<Map<String, dynamic>> cryptos;
  final bool loading;
  final String? error;
  final Future<void> Function() onRefresh;
  final void Function(Map<String, dynamic>) onOpenAsset;
  final VoidCallback onSeeAll;

  const HomeTab({
    super.key,
    required this.assets,
    required this.cryptos,
    required this.loading,
    required this.error,
    required this.onRefresh,
    required this.onOpenAsset,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    // Featured: gold (big card at top)
    final gold = assets.firstWhere(
      (a) => a['code'] == 'GOLD_18_RLS',
      orElse: () => assets.isNotEmpty ? assets.first : {},
    );

    // Hot items: coin, dollar, BTC, ETH
    final hot = <Map<String, dynamic>>[];
    for (final code in ['COIN_EMAMI_RLS', 'USD_RLS', 'BTC_RLS', 'ETH_RLS']) {
      final item = [...assets, ...cryptos].firstWhere(
        (a) => a['code'] == code,
        orElse: () => {},
      );
      if (item.isNotEmpty) hot.add(item);
    }
    // Fill from assets if not enough
    for (final a in assets) {
      if (hot.length >= 4) break;
      if (!hot.any((h) => h['code'] == a['code'])) hot.add(a);
    }

    return SafeArea(
      child: RefreshIndicator(
        color: goldColor,
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          children: [
            // Header: Ping Market + search + dots
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: darkCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: goldColor.withOpacity(0.3)),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'P',
                    style: TextStyle(
                      color: goldColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'Ping ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TextSpan(
                        text: 'Market',
                        style: TextStyle(
                          color: goldColor,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.search_rounded,
                      color: Colors.white70, size: 22),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.more_horiz_rounded,
                      color: Colors.white70, size: 22),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Big gold card
            if (gold.isNotEmpty) _buildFeaturedGold(gold),
            const SizedBox(height: 16),

            // Quick actions row (3 items)
            Row(
              children: [
                _quickAction('🪙', 'طلا', onTap: () => onSeeAll()),
                const SizedBox(width: 10),
                _quickAction('💲', 'دلار', onTap: () => onSeeAll()),
                const SizedBox(width: 10),
                _quickAction('🪙', 'سکه', onTap: () => onSeeAll()),
              ],
            ),
            const SizedBox(height: 22),

            // Section title
            Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: goldColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'قیمت‌های مهم',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (loading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                    child: CircularProgressIndicator(color: goldColor)),
              )
            else if (error != null && hot.isEmpty)
              _buildError()
            else
              ...hot
                  .map((a) => PriceCard(
                        asset: a,
                        onTap: () => onOpenAsset(a),
                      ))
                  .toList(),
          ],
        ),
      ),
    );
  }

  Widget _quickAction(String icon, String label, {VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: darkCard,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Text(icon, style: const TextStyle(fontSize: 26)),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedGold(Map<String, dynamic> gold) {
    final change = assetChange(gold);
    final isUp = change >= 0;
    final changeColor = isUp ? greenUp : redDown;
    final price = formatPrice(gold);
    final rawValue = gold['value'];
    final changeAmount = rawValue is num
        ? (rawValue.toDouble() * (change / 100) / 10).abs().toStringAsFixed(0)
        : '0';

    return GestureDetector(
      onTap: () => onOpenAsset(gold),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A1500), Color(0xFF0D0D0D)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: goldColor.withOpacity(0.25), width: 0.8),
        ),
        child: Stack(
          children: [
            // Background chart line
            Positioned(
              right: 0,
              bottom: 0,
              top: 0,
              width: 160,
              child: CustomPaint(
                painter: SparklinePainter(
                  assetSparkline(gold),
                  goldColor.withOpacity(0.4),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: goldColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: goldColor.withOpacity(0.4), width: 1),
                      ),
                      alignment: Alignment.center,
                      child: const Text('🪙',
                          style: TextStyle(fontSize: 24)),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'طلا',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'گرم ۱۸ عیار',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      price,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'تومان',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      isUp
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      color: changeColor,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${isUp ? "+" : ""}${change.toStringAsFixed(2)}%',
                      style: TextStyle(
                        color: changeColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${isUp ? "+" : ""}$changeAmount)',
                      style: TextStyle(
                        color: changeColor.withOpacity(0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          const Icon(Icons.wifi_off_rounded, size: 50, color: Colors.white38),
          const SizedBox(height: 12),
          Text(error ?? 'خطا',
              style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => onRefresh(),
            style: FilledButton.styleFrom(backgroundColor: goldColor),
            child: const Text('تلاش دوباره'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  PRICES TAB (with tabs: همه / ارزهای دیجیتال / ارزهای بین‌المللی)
// ═══════════════════════════════════════════════════════
class PricesTab extends StatefulWidget {
  final List<Map<String, dynamic>> assets;
  final List<Map<String, dynamic>> cryptos;
  final bool loading;
  final Future<void> Function() onRefresh;
  final void Function(Map<String, dynamic>) onOpenAsset;

  const PricesTab({
    super.key,
    required this.assets,
    required this.cryptos,
    required this.loading,
    required this.onRefresh,
    required this.onOpenAsset,
  });

  @override
  State<PricesTab> createState() => _PricesTabState();
}

class _PricesTabState extends State<PricesTab> {
  int category = 0; // 0=all, 1=crypto, 2=international

  @override
  Widget build(BuildContext context) {
    final all = [...widget.assets, ...widget.cryptos];
    final filtered = () {
      if (category == 0) return all;
      if (category == 1)
        return all.where((a) => isCrypto(a) || a['code'] == 'BTC_RLS').toList();
      return all.where((a) => !isCrypto(a)).toList();
    }();

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => widget.onRefresh(),
                  icon: const Icon(Icons.refresh_rounded,
                      color: Colors.white70),
                ),
                const Expanded(
                  child: Text(
                    'دلار و ارزها',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: darkCard,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  _tab('ارزهای بین‌المللی', 2),
                  _tab('ارزهای دیجیتال', 1),
                  _tab('همه', 0),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: RefreshIndicator(
              color: goldColor,
              onRefresh: widget.onRefresh,
              child: widget.loading
                  ? const Center(
                      child: CircularProgressIndicator(color: goldColor))
                  : filtered.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 80),
                            Center(
                              child: Text('موردی یافت نشد',
                                  style: TextStyle(color: Colors.white70)),
                            ),
                          ],
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                          children: filtered
                              .map((a) => PriceCard(
                                    asset: a,
                                    onTap: () => widget.onOpenAsset(a),
                                  ))
                              .toList(),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tab(String label, int value) {
    final sel = category == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => category = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: sel ? goldColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: sel ? Colors.black : Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  WATCHLIST TAB
// ═══════════════════════════════════════════════════════
class WatchlistTab extends StatelessWidget {
  final List<Map<String, dynamic>> assets;
  final void Function(Map<String, dynamic>) onOpenAsset;
  final VoidCallback onManage;

  const WatchlistTab({
    super.key,
    required this.assets,
    required this.onOpenAsset,
    required this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ValueListenableBuilder<Set<String>>(
        valueListenable: favoritesNotifier,
        builder: (context, favs, _) {
          final items = assets
              .where((a) => favs.contains(a['code']?.toString()))
              .toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.star_border_rounded,
                          color: Colors.white70),
                    ),
                    const Expanded(
                      child: Text(
                        'واچ لیست',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              if (items.isEmpty)
                const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_border_rounded,
                            size: 60, color: Colors.white24),
                        SizedBox(height: 12),
                        Text(
                          'هنوز ارزی به واچ لیست اضافه نشده',
                          style: TextStyle(color: Colors.white54, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    children: items
                        .map((a) => PriceCard(
                              asset: a,
                              onTap: () => onOpenAsset(a),
                            ))
                        .toList(),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: GestureDetector(
                  onTap: onManage,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: darkCard,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_rounded, color: Colors.white70, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'مدیریت واچ لیست',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  SETTINGS TAB
// ═══════════════════════════════════════════════════════
class SettingsTab extends StatefulWidget {
  final VoidCallback onOpenPrices;
  final VoidCallback onOpenWatchlist;

  const SettingsTab({
    super.key,
    required this.onOpenPrices,
    required this.onOpenWatchlist,
  });

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  bool darkMode = true;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
        children: [
          // Logo header
          Center(
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: darkCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: goldColor.withOpacity(0.3)),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'P',
                    style: TextStyle(
                      color: goldColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'Ping ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TextSpan(
                        text: 'Market',
                        style: TextStyle(
                          color: goldColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Real-time Prices · Global Markets',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          _menuItem(
            icon: Icons.bar_chart_rounded,
            label: 'قیمت‌ها',
            onTap: widget.onOpenPrices,
          ),
          const SizedBox(height: 8),
          _menuItem(
            icon: Icons.star_border_rounded,
            label: 'واچ لیست',
            onTap: widget.onOpenWatchlist,
          ),
          const SizedBox(height: 8),
          _menuItem(
            icon: Icons.settings_outlined,
            label: 'تنظیمات',
            onTap: () => _showSettingsDialog(),
          ),
          const SizedBox(height: 8),
          _menuItem(
            icon: Icons.info_outline_rounded,
            label: 'درباره ما',
            onTap: () => _showAbout(),
          ),
          const SizedBox(height: 30),

          // Bottom card: "دنیای بازارها"
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A1500), Color(0xFF0D0D0D)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: goldColor.withOpacity(0.2), width: 0.8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'دنیای بازارها',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'همیشه در دسترس',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: goldColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'P',
                    style: TextStyle(
                      color: goldColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 26,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: darkCard,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: goldColor, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.chevron_left_rounded,
                color: Colors.white38, size: 20),
          ],
        ),
      ),
    );
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('درباره ما', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Ping Market\nنسخه ۱.۰.۰\n\nقیمت لحظه‌ای ارز، طلا و ارزهای دیجیتال\n\nmrpingshop.ir',
          style: TextStyle(color: Colors.white70, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('بستن', style: TextStyle(color: goldColor)),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: darkCard,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'تنظیمات',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('حالت تاریک',
                    style: TextStyle(color: Colors.white)),
                value: darkMode,
                activeColor: goldColor,
                onChanged: (v) {
                  setState(() => darkMode = v);
                  setSheet(() {});
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  DETAIL SCREEN
// ═══════════════════════════════════════════════════════
class DetailScreen extends StatefulWidget {
  final Map<String, dynamic> asset;
  const DetailScreen({super.key, required this.asset});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  String range = '1D';
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    isFavorite =
        favoritesNotifier.value.contains(widget.asset['code']?.toString());
    favoritesNotifier.addListener(_onFavChange);
  }

  @override
  void dispose() {
    favoritesNotifier.removeListener(_onFavChange);
    super.dispose();
  }

  void _onFavChange() {
    if (mounted) {
      setState(() {
        isFavorite = favoritesNotifier.value
            .contains(widget.asset['code']?.toString());
      });
    }
  }

  Future<void> _toggleFavorite() async {
    final code = widget.asset['code']?.toString() ?? '';
    final newSet = Set<String>.from(favoritesNotifier.value);
    if (newSet.contains(code)) {
      newSet.remove(code);
    } else {
      newSet.add(code);
    }
    final p = await SharedPreferences.getInstance();
    await p.setStringList('favorites', newSet.toList());
    favoritesNotifier.value = newSet;
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.asset['code']?.toString() ?? '';
    final label = displayLabel(widget.asset);
    final icon = displayIcon(widget.asset);
    final change = assetChange(widget.asset);
    final isUp = change >= 0;
    final changeColor = isUp ? greenUp : redDown;
    final price = formatPrice(widget.asset);
    final unit = unitText(widget.asset);

    final rawValue = widget.asset['value'];
    final changeAmount = rawValue is num
        ? (rawValue.toDouble() * (change / 100) / 10).abs().toStringAsFixed(0)
        : '0';

    final baseSpark = assetSparkline(widget.asset);
    final detailData = List.generate(40, (i) {
      final base = baseSpark.isEmpty ? 100.0 : baseSpark[i % baseSpark.length];
      return base;
    });

    // High/low values
    final highVal = detailData.reduce(max);
    final lowVal = detailData.reduce(min);

    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        backgroundColor: darkBg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _toggleFavorite,
            icon: Icon(
              isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
              color: goldColor,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          children: [
            // Header price
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A1500), Color(0xFF0D0D0D)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: goldColor.withOpacity(0.25), width: 0.8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: goldColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: goldColor.withOpacity(0.4), width: 1),
                    ),
                    alignment: Alignment.center,
                    child: Text(icon, style: const TextStyle(fontSize: 30)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              price,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              unit,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  Icon(
                    isUp
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    color: changeColor,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${isUp ? "+" : ""}${change.toStringAsFixed(2)}%',
                    style: TextStyle(
                      color: changeColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${isUp ? "+" : ""}$changeAmount)',
                    style: TextStyle(
                      color: changeColor.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Range selector
            Row(
              children: ['1D', '1W', '1M', '3M', '1Y'].map((r) {
                final sel = range == r;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => range = r),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: sel ? goldColor : darkCard,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        r,
                        style: TextStyle(
                          color: sel ? Colors.black : Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Chart with y-axis labels
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: darkCard,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  SizedBox(
                    height: 180,
                    width: 50,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(highVal.toStringAsFixed(1),
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 9)),
                        Text(((highVal + lowVal) / 2).toStringAsFixed(1),
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 9)),
                        Text(lowVal.toStringAsFixed(1),
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 9)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SizedBox(
                      height: 180,
                      child: CustomPaint(
                        painter: ChartPainter(detailData, changeColor),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Time labels
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 60),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('09:00',
                      style: TextStyle(color: Colors.white38, fontSize: 10)),
                  Text('12:00',
                      style: TextStyle(color: Colors.white38, fontSize: 10)),
                  Text('15:00',
                      style: TextStyle(color: Colors.white38, fontSize: 10)),
                  Text('18:00',
                      style: TextStyle(color: Colors.white38, fontSize: 10)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Stats
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: darkCard,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _statRow('قیمت فعلی', price, Colors.white),
                  _divider(),
                  _statRow('بالاترین قیمت', price, Colors.white),
                  _divider(),
                  _statRow('پایین‌ترین قیمت', price, Colors.white),
                  _divider(),
                  _statRow(
                    'تغییرات روزانه',
                    '${isUp ? "+" : ""}${change.toStringAsFixed(2)}%',
                    changeColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Add to watchlist button
            GestureDetector(
              onTap: _toggleFavorite,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isFavorite
                        ? [const Color(0xFF2A2A2A), const Color(0xFF1A1A1A)]
                        : [goldLight, goldColor, goldDark],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: isFavorite
                      ? Border.all(color: goldColor.withOpacity(0.5))
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isFavorite
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: isFavorite ? goldColor : Colors.black,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isFavorite
                          ? 'حذف از واچ لیست'
                          : 'افزودن به واچ لیست',
                      style: TextStyle(
                        color: isFavorite ? goldColor : Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Divider(height: 1, color: Colors.white.withOpacity(0.05));
  }
}

// ═══════════════════════════════════════════════════════
//  CHART PAINTER
// ═══════════════════════════════════════════════════════
class ChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;
  ChartPainter(this.data, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final minV = data.reduce(min);
    final maxV = data.reduce(max);
    final range = (maxV - minV) == 0 ? 1 : (maxV - minV);

    // Grid
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 0.5;
    for (int i = 0; i <= 4; i++) {
      final y = (i / 4) * size.height;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final linePath = Path();
    final fillPath = Path();
    fillPath.moveTo(0, size.height);

    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y =
          size.height - ((data[i] - minV) / range) * (size.height - 10) - 5;
      if (i == 0) {
        linePath.moveTo(x, y);
      } else {
        linePath.lineTo(x, y);
      }
      fillPath.lineTo(x, y);
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          colors: [color.withOpacity(0.35), color.withOpacity(0.0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..style = PaintingStyle.fill,
    );

    canvas.drawPath(
      linePath,
      Paint()
        ..color = color
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Last point dot
    final lastX = size.width;
    final lastY =
        size.height - ((data.last - minV) / range) * (size.height - 10) - 5;
    canvas.drawCircle(Offset(lastX, lastY), 4, Paint()..color = color);
    canvas.drawCircle(
      Offset(lastX, lastY),
      8,
      Paint()..color = color.withOpacity(0.25),
    );
  }

  @override
  bool shouldRepaint(covariant ChartPainter old) => false;
}
