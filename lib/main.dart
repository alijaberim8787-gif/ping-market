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
const Color darkBg = Color(0xFF000000);
const Color darkCard = Color(0xFF1A1A1A);
const Color darkCard2 = Color(0xFF242424);
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
  'USD_RLS': AssetMeta('🇺🇸', 'دلار آمریکا', 'US Dollar', 'currency'),
  'EUR_RLS': AssetMeta('🇪🇺', 'یورو', 'Euro', 'currency'),
  'GBP_RLS': AssetMeta('🇬🇧', 'پوند انگلیس', 'British Pound', 'currency'),
  'AED_RLS': AssetMeta('🇦🇪', 'درهم امارات', 'UAE Dirham', 'currency'),
  'GOLD_18_RLS': AssetMeta('🪙', 'طلا (گرم ۱۸ عیار)', 'Gold 18K', 'gold'),
  'COIN_EMAMI_RLS': AssetMeta('🪙', 'سکه امامی', 'Emami Coin', 'gold'),
  'BTC_RLS': AssetMeta('₿', 'بیت‌کوین', 'Bitcoin', 'crypto'),
  'ETH_RLS': AssetMeta('Ξ', 'اتریوم', 'Ethereum', 'crypto'),
};

// ═══════════════════════════════════════════════════════
//  GLOBAL FAVORITES
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
    Timer(const Duration(milliseconds: 2500), () {
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

  Future<void> _setDark(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('dark', v);
    if (mounted) {
      setState(() => themeMode = v ? ThemeMode.dark : ThemeMode.light);
    }
  }

  Future<void> _setLang(String v) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('lang', v);
    if (mounted) setState(() => locale = Locale(v));
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
          : MainNav(
              dark: themeMode == ThemeMode.dark,
              lang: locale.languageCode,
              onDarkChanged: _setDark,
              onLangChanged: _setLang,
            ),
    );
  }

  ThemeData _theme(Brightness b) {
    final isDark = b == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: b,
      scaffoldBackgroundColor: isDark ? darkBg : const Color(0xFFF2F2F7),
      colorScheme: ColorScheme.fromSeed(
        seedColor: goldColor,
        brightness: b,
      ),
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
//  SPLASH
// ═══════════════════════════════════════════════════════
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBg,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [goldColor.withOpacity(0.15), Colors.transparent],
                  radius: 1.2,
                ),
              ),
            ),
          ),
          Center(
            child: FadeTransition(
              opacity: _fade,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(34),
                      gradient: const LinearGradient(
                        colors: [goldLight, goldColor, goldDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: goldColor.withOpacity(0.5),
                          blurRadius: 40,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'P',
                      style: TextStyle(
                        fontSize: 76,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                        height: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'Ping ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        TextSpan(
                          text: 'Market',
                          style: TextStyle(
                            color: goldColor,
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'بازار همیشه در دسترس',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 60),
                  SizedBox(
                    width: 160,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: const LinearProgressIndicator(
                        backgroundColor: Color(0xFF2C2C2E),
                        valueColor: AlwaysStoppedAnimation<Color>(goldColor),
                        minHeight: 3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'در حال بارگذاری...',
                    style: TextStyle(color: Colors.white38, fontSize: 11),
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

// ═══════════════════════════════════════════════════════
//  MAIN NAV
// ═══════════════════════════════════════════════════════
class MainNav extends StatefulWidget {
  final bool dark;
  final String lang;
  final ValueChanged<bool> onDarkChanged;
  final ValueChanged<String> onLangChanged;

  const MainNav({
    super.key,
    required this.dark,
    required this.lang,
    required this.onDarkChanged,
    required this.onLangChanged,
  });

  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> {
  int tab = 0;
  List<Map<String, dynamic>> assets = [];
  List<Map<String, dynamic>> cryptos = [];
  bool loadingAssets = true;
  bool loadingCryptos = true;
  String? errorAssets;
  String? errorCryptos;

  @override
  void initState() {
    super.initState();
    _loadAssets();
    _loadCryptos();
  }

  Future<void> _loadAssets() async {
    if (!mounted) return;
    setState(() {
      loadingAssets = assets.isEmpty;
      errorAssets = null;
    });
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
        loadingAssets = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loadingAssets = false;
        errorAssets = 'خطا در دریافت قیمت‌های بازار';
      });
    }
  }

  Future<void> _loadCryptos() async {
    if (!mounted) return;
    setState(() {
      loadingCryptos = cryptos.isEmpty;
      errorCryptos = null;
    });
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
        loadingCryptos = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loadingCryptos = false;
        errorCryptos = 'خطا در دریافت قیمت‌های کریپتو';
      });
    }
  }

  Future<void> _refreshAll() async {
    await Future.wait([_loadAssets(), _loadCryptos()]);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeTab(
        assets: assets,
        cryptos: cryptos,
        loading: loadingAssets || loadingCryptos,
        error: errorAssets ?? errorCryptos,
        onRefresh: _refreshAll,
        onSeeAll: () => setState(() => tab = 1),
        onOpenAsset: _openDetail,
      ),
      BazaarTab(
        assets: assets,
        cryptos: cryptos,
        loadingAssets: loadingAssets,
        loadingCryptos: loadingCryptos,
        errorAssets: errorAssets,
        errorCryptos: errorCryptos,
        onRefresh: _refreshAll,
        onOpenAsset: _openDetail,
      ),
      FavoritesTab(
        assets: [...assets, ...cryptos],
        onOpenAsset: _openDetail,
      ),
      SettingsTab(
        dark: widget.dark,
        lang: widget.lang,
        onDarkChanged: widget.onDarkChanged,
        onLangChanged: widget.onLangChanged,
      ),
    ];

    return Scaffold(
      body: pages[tab],
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  void _openDetail(Map<String, dynamic> asset) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DetailScreen(asset: asset),
      ),
    );
  }

  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.home_outlined, 'active': Icons.home_rounded, 'label': 'خانه'},
      {'icon': Icons.show_chart_outlined, 'active': Icons.show_chart_rounded, 'label': 'بازار'},
      {'icon': Icons.star_border_rounded, 'active': Icons.star_rounded, 'label': 'علاقه‌مندی‌ها'},
      {'icon': Icons.settings_outlined, 'active': Icons.settings_rounded, 'label': 'تنظیمات'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: widget.dark ? darkCard : Colors.white,
        border: Border(
          top: BorderSide(
            color: widget.dark ? Colors.white10 : Colors.black12,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
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
                        color: sel
                            ? goldColor
                            : (widget.dark ? Colors.white38 : Colors.black38),
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        items[i]['label'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          color: sel
                              ? goldColor
                              : (widget.dark ? Colors.white38 : Colors.black38),
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
//  SHARED HELPERS
// ═══════════════════════════════════════════════════════
bool isDark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;

Color cardBg(BuildContext c) => isDark(c) ? darkCard : Colors.white;
Color cardBg2(BuildContext c) => isDark(c) ? darkCard2 : const Color(0xFFF2F2F7);
Color txtPrimary(BuildContext c) => isDark(c) ? Colors.white : Colors.black;
Color txtSecondary(BuildContext c) =>
    isDark(c) ? Colors.white54 : Colors.black54;
Color txtTertiary(BuildContext c) =>
    isDark(c) ? Colors.white38 : Colors.black38;

AssetMeta? metaFor(String? code) {
  if (code == null) return null;
  return assetCatalog[code];
}

bool isCrypto(Map<String, dynamic> a) {
  final code = a['code']?.toString() ?? '';
  return code.startsWith('CG_');
}

String displayLabel(Map<String, dynamic> a) {
  final code = a['code']?.toString() ?? '';
  final meta = metaFor(code);
  if (meta != null) return meta.fa;
  return a['labelFa']?.toString() ?? a['labelEn']?.toString() ?? code;
}

String displayIcon(Map<String, dynamic> a) {
  final code = a['code']?.toString() ?? '';
  final meta = metaFor(code);
  if (meta != null) return meta.icon;
  return a['icon']?.toString() ?? '🪙';
}

String displaySymbol(Map<String, dynamic> a) {
  final symbol = a['symbol']?.toString();
  if (symbol != null && symbol.isNotEmpty) return symbol;
  final code = a['code']?.toString() ?? '';
  if (code.startsWith('CG_')) return code.substring(3);
  if (code.endsWith('_RLS')) return code.substring(0, code.length - 4);
  return code;
}

// Check if asset uses USD (crypto from CoinGecko)
bool usesUsd(Map<String, dynamic> a) {
  return a['quoteUnit']?.toString() == 'USD';
}

// Format USD price (for crypto)
String formatUsd(dynamic value) {
  if (value == null) return '—';
  final n = (value as num).toDouble();
  if (n >= 1000) {
    return '\$${n.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}';
  } else if (n >= 1) {
    return '\$${n.toStringAsFixed(2)}';
  } else if (n >= 0.01) {
    return '\$${n.toStringAsFixed(4)}';
  } else {
    return '\$${n.toStringAsFixed(8)}';
  }
}

// Format toman/rial price (for Iranian market)
String formatToman(dynamic value, bool toman) {
  if (value == null) return '—';
  final n = (value as num).toDouble();
  final v = toman ? n / 10 : n;
  return v.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+$)'),
        (m) => '${m[1]},',
      );
}

double assetChange(Map<String, dynamic> a) {
  final c = a['change24h'];
  if (c is num) return c.toDouble();
  // For Iranian assets, use stable pseudo
  final code = a['code']?.toString() ?? '';
  final h = code.hashCode.abs();
  return ((h % 500) - 200) / 100.0;
}

List<double> assetSparkline(Map<String, dynamic> a) {
  final sp = a['sparkline'];
  if (sp is List && sp.isNotEmpty) {
    final list = <double>[];
    // Downsample if too many points
    final step = max(1, sp.length ~/ 30);
    for (int i = 0; i < sp.length; i += step) {
      final v = sp[i];
      if (v is num) list.add(v.toDouble());
    }
    if (list.length >= 2) return list;
  }
  // Fallback pseudo
  final code = a['code']?.toString() ?? '';
  final h = code.hashCode.abs();
  final r = Random(h);
  final list = <double>[];
  double v = 100.0;
  for (int i = 0; i < 20; i++) {
    v += (r.nextDouble() - 0.45) * 2;
    list.add(v);
  }
  return list;
}

// ═══════════════════════════════════════════════════════
//  SPARKLINE PAINTER
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

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant SparklinePainter old) => false;
}

// ═══════════════════════════════════════════════════════
//  PRICE CARD
// ═══════════════════════════════════════════════════════
class PriceCard extends StatelessWidget {
  final Map<String, dynamic> asset;
  final bool toman;
  final bool showChart;
  final VoidCallback onTap;

  const PriceCard({
    super.key,
    required this.asset,
    required this.toman,
    required this.onTap,
    this.showChart = true,
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
    final crypto = isCrypto(asset);
    final priceText = crypto
        ? formatUsd(asset['valueUsd'] ?? asset['value'])
        : formatToman(asset['value'], toman);
    final unit = crypto ? 'USD' : (toman ? 'تومان' : 'ریال');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cardBg(context),
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
                    color: cardBg2(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(icon, style: const TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: txtSecondary(context),
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
                              fontWeight: FontWeight.w600,
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
                            priceText,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: txtPrimary(context),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            unit,
                            style: TextStyle(
                              fontSize: 11,
                              color: txtTertiary(context),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (showChart)
                  SizedBox(
                    width: 60,
                    height: 28,
                    child: CustomPaint(
                      painter: SparklinePainter(sparkline, changeColor),
                    ),
                  ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_left_rounded,
                  color: txtTertiary(context),
                  size: 20,
                ),
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
  final VoidCallback onSeeAll;
  final void Function(Map<String, dynamic>) onOpenAsset;

  const HomeTab({
    super.key,
    required this.assets,
    required this.cryptos,
    required this.loading,
    required this.error,
    required this.onRefresh,
    required this.onSeeAll,
    required this.onOpenAsset,
  });

  @override
  Widget build(BuildContext context) {
    final hotItems = <Map<String, dynamic>>[];
    // First 3 from Iranian assets
    for (final a in assets.take(3)) {
      hotItems.add(a);
    }
    // Then BTC from crypto
    final btc = cryptos.firstWhere(
      (c) => c['symbol'] == 'BTC',
      orElse: () => {},
    );
    if (btc.isNotEmpty) hotItems.add(btc);

    return SafeArea(
      child: RefreshIndicator(
        color: goldColor,
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.notifications_none_rounded,
                      color: txtPrimary(context)),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [goldLight, goldColor, goldDark],
                          ),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'P',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Ping Market',
                        style: TextStyle(
                          color: txtPrimary(context),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.person_outline_rounded,
                      color: txtPrimary(context)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildBanner(context),
            const SizedBox(height: 18),
            _buildQuickActions(context),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'قیمت‌های مهم',
                  style: TextStyle(
                    color: txtPrimary(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextButton(
                  onPressed: onSeeAll,
                  child: const Text(
                    'مشاهده همه',
                    style: TextStyle(color: goldColor, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (loading)
              const Padding(
                padding: EdgeInsets.all(40),
                child:
                    Center(child: CircularProgressIndicator(color: goldColor)),
              )
            else if (error != null && hotItems.isEmpty)
              _buildError(context)
            else
              ...hotItems.map((a) => PriceCard(
                    asset: a,
                    toman: true,
                    onTap: () => onOpenAsset(a),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildBanner(BuildContext context) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1500), Color(0xFF0A0A0A)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        border: Border.all(color: goldColor.withOpacity(0.2), width: 0.5),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: CustomPaint(
                painter: SparklinePainter(
                  List.generate(30, (i) => 100 + (i * 1.5) + sin(i / 2) * 5),
                  goldColor.withOpacity(0.35),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'سلام،',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'به پینگ مارکت خوش آمدید',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 20,
                      height: 3,
                      decoration: BoxDecoration(
                        color: goldColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 5,
                      height: 3,
                      decoration: BoxDecoration(
                        color: Colors.white30,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 5,
                      height: 3,
                      decoration: BoxDecoration(
                        color: Colors.white30,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      {'icon': '🪙', 'label': 'طلا'},
      {'icon': '💵', 'label': 'ارزهای خارجی'},
      {'icon': '💲', 'label': 'دلار'},
      {'icon': '₿', 'label': 'بیت‌کوین'},
    ];

    return Row(
      children: actions.map((a) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: cardBg(context),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Text(a['icon']!, style: const TextStyle(fontSize: 26)),
                const SizedBox(height: 6),
                Text(
                  a['label']!,
                  style: TextStyle(
                    color: txtSecondary(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildError(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.wifi_off_rounded, size: 50, color: txtTertiary(context)),
          const SizedBox(height: 12),
          Text(error ?? 'خطا', style: TextStyle(color: txtSecondary(context))),
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
//  BAZAAR TAB (with chip: Iran / Crypto)
// ═══════════════════════════════════════════════════════
class BazaarTab extends StatefulWidget {
  final List<Map<String, dynamic>> assets;
  final List<Map<String, dynamic>> cryptos;
  final bool loadingAssets;
  final bool loadingCryptos;
  final String? errorAssets;
  final String? errorCryptos;
  final Future<void> Function() onRefresh;
  final void Function(Map<String, dynamic>) onOpenAsset;

  const BazaarTab({
    super.key,
    required this.assets,
    required this.cryptos,
    required this.loadingAssets,
    required this.loadingCryptos,
    required this.errorAssets,
    required this.errorCryptos,
    required this.onRefresh,
    required this.onOpenAsset,
  });

  @override
  State<BazaarTab> createState() => _BazaarTabState();
}

class _BazaarTabState extends State<BazaarTab> {
  int section = 0; // 0 = Iran, 1 = Crypto
  String category = 'all';
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get currentSource =>
      section == 0 ? widget.assets : widget.cryptos;

  List<Map<String, dynamic>> get filtered {
    final q = _search.text.trim().toLowerCase();
    return currentSource.where((a) {
      final code = a['code']?.toString() ?? '';
      final meta = metaFor(code);
      final cat = meta?.category ?? (code.startsWith('CG_') ? 'crypto' : 'other');
      if (section == 0 && category != 'all' && cat != category) return false;
      if (q.isEmpty) return true;
      final label = displayLabel(a).toLowerCase();
      final symbol = displaySymbol(a).toLowerCase();
      return label.contains(q) ||
          symbol.contains(q) ||
          code.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final loading = section == 0 ? widget.loadingAssets : widget.loadingCryptos;
    final error = section == 0 ? widget.errorAssets : widget.errorCryptos;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'بازار',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: txtPrimary(context),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Section selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: cardBg(context),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        section = 0;
                        category = 'all';
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: section == 0
                              ? goldColor
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'ارز و طلا',
                          style: TextStyle(
                            color: section == 0
                                ? Colors.black
                                : txtSecondary(context),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        section = 1;
                        category = 'all';
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: section == 1
                              ? goldColor
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'کریپتو',
                          style: TextStyle(
                            color: section == 1
                                ? Colors.black
                                : txtSecondary(context),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: cardBg(context),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                style: TextStyle(color: txtPrimary(context), fontSize: 13),
                decoration: InputDecoration(
                  hintText: section == 0
                      ? 'جستجو در بازار...'
                      : 'جستجو در کریپتو...',
                  hintStyle:
                      TextStyle(color: txtTertiary(context), fontSize: 13),
                  prefixIcon: Icon(Icons.search_rounded,
                      color: txtTertiary(context)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Category chips (only for Iran section)
          if (section == 0)
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _chip('همه', 'all'),
                  _chip('ارزها', 'currency'),
                  _chip('طلا و سکه', 'gold'),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // List
          Expanded(
            child: RefreshIndicator(
              color: goldColor,
              onRefresh: widget.onRefresh,
              child: loading
                  ? const Center(
                      child: CircularProgressIndicator(color: goldColor))
                  : (error != null && filtered.isEmpty)
                      ? _errorView(error)
                      : filtered.isEmpty
                          ? ListView(
                              children: [
                                const SizedBox(height: 80),
                                Center(
                                  child: Text(
                                    'موردی یافت نشد',
                                    style: TextStyle(
                                        color: txtSecondary(context)),
                                  ),
                                ),
                              ],
                            )
                          : ListView(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 0, 16, 20),
                              children: filtered
                                  .map((a) => PriceCard(
                                        asset: a,
                                        toman: true,
                                        onTap: () =>
                                            widget.onOpenAsset(a),
                                      ))
                                  .toList(),
                            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorView(String? err) {
    return ListView(
      children: [
        const SizedBox(height: 80),
        Center(
          child: Column(
            children: [
              Icon(Icons.wifi_off_rounded,
                  size: 50, color: txtTertiary(context)),
              const SizedBox(height: 12),
              Text(err ?? 'خطا',
                  style: TextStyle(color: txtSecondary(context))),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => widget.onRefresh(),
                style: FilledButton.styleFrom(backgroundColor: goldColor),
                child: const Text('تلاش دوباره'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _chip(String label, String value) {
    final sel = category == value;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: GestureDetector(
        onTap: () => setState(() => category = value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: sel ? goldColor : cardBg(context),
            borderRadius: BorderRadius.circular(20),
            border: sel
                ? null
                : Border.all(color: txtTertiary(context).withOpacity(0.2)),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: sel ? Colors.black : txtPrimary(context),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  FAVORITES TAB
// ═══════════════════════════════════════════════════════
class FavoritesTab extends StatefulWidget {
  final List<Map<String, dynamic>> assets;
  final void Function(Map<String, dynamic>) onOpenAsset;

  const FavoritesTab({
    super.key,
    required this.assets,
    required this.onOpenAsset,
  });

  @override
  State<FavoritesTab> createState() => _FavoritesTabState();
}

class _FavoritesTabState extends State<FavoritesTab> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ValueListenableBuilder<Set<String>>(
        valueListenable: favoritesNotifier,
        builder: (context, favs, _) {
          final items = widget.assets
              .where((a) => favs.contains(a['code']?.toString()))
              .toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'علاقه‌مندی‌ها',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: txtPrimary(context),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (items.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_border_rounded,
                            size: 60, color: txtTertiary(context)),
                        const SizedBox(height: 12),
                        Text(
                          'هنوز ارزی به علاقه‌مندی‌ها اضافه نشده است',
                          style: TextStyle(
                              color: txtSecondary(context), fontSize: 13),
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
                              toman: true,
                              onTap: () => widget.onOpenAsset(a),
                            ))
                        .toList(),
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
class SettingsTab extends StatelessWidget {
  final bool dark;
  final String lang;
  final ValueChanged<bool> onDarkChanged;
  final ValueChanged<String> onLangChanged;

  const SettingsTab({
    super.key,
    required this.dark,
    required this.lang,
    required this.onDarkChanged,
    required this.onLangChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        children: [
          Text(
            'حساب کاربری',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: txtPrimary(context),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg(context),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [goldLight, goldColor, goldDark],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'P',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ping Market',
                        style: TextStyle(
                          color: txtPrimary(context),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'نسخه ۱.۰.۰',
                        style: TextStyle(
                          color: txtSecondary(context),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_left_rounded, color: txtTertiary(context)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _group(context, [
            _item(context,
                icon: Icons.notifications_none_rounded, label: 'اطلاعیه‌ها'),
            _item(context,
                icon: Icons.tune_rounded, label: 'تنظیمات اعلان‌ها'),
            _item(
              context,
              icon: Icons.dark_mode_outlined,
              label: 'تغییر تم',
              trailing: Switch(
                value: dark,
                activeColor: goldColor,
                onChanged: onDarkChanged,
              ),
            ),
            _item(
              context,
              icon: Icons.language_rounded,
              label: 'زبان',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    lang == 'fa' ? 'فارسی' : 'English',
                    style: TextStyle(
                        color: txtSecondary(context), fontSize: 13),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    lang == 'fa' ? '🇮🇷' : '🇬🇧',
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
            _item(context,
                icon: Icons.support_agent_rounded, label: 'پشتیبانی'),
            _item(context,
                icon: Icons.info_outline_rounded, label: 'درباره ما'),
          ]),
        ],
      ),
    );
  }

  Widget _group(BuildContext context, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }

  Widget _item(BuildContext context,
      {required IconData icon, required String label, Widget? trailing}) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: txtSecondary(context), size: 22),
          title: Text(
            label,
            style: TextStyle(
              color: txtPrimary(context),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: trailing ??
              Icon(Icons.chevron_left_rounded, color: txtTertiary(context)),
        ),
        Divider(
          height: 1,
          color: txtTertiary(context).withOpacity(0.1),
          indent: 56,
        ),
      ],
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

  @override
  Widget build(BuildContext context) {
    final code = widget.asset['code']?.toString() ?? '';
    final label = displayLabel(widget.asset);
    final icon = displayIcon(widget.asset);
    final change = assetChange(widget.asset);
    final isUp = change >= 0;
    final changeColor = isUp ? greenUp : redDown;
    final crypto = isCrypto(widget.asset);

    final price = crypto
        ? formatUsd(widget.asset['valueUsd'] ?? widget.asset['value'])
        : formatToman(widget.asset['value'], true);

    final unit = crypto ? 'USD' : 'تومان';

    final rawValue = widget.asset['value'];
    final changeAmount = rawValue is num
        ? rawValue.toDouble() * (change / 100)
        : 0.0;

    final sparkline = assetSparkline(widget.asset);
    // For detail screen, extend sparkline
    final detailData = sparkline.length >= 30
        ? sparkline
        : List.generate(40, (i) {
            final base = sparkline.isEmpty
                ? 100.0
                : sparkline[i % sparkline.length];
            return base;
          });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_forward_rounded, color: txtPrimary(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          label,
          style: TextStyle(
            color: txtPrimary(context),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          ValueListenableBuilder<Set<String>>(
            valueListenable: favoritesNotifier,
            builder: (context, favs, _) {
              final isFav = favs.contains(code);
              return IconButton(
                onPressed: () async {
                  final newSet = Set<String>.from(favs);
                  if (isFav) {
                    newSet.remove(code);
                  } else {
                    newSet.add(code);
                  }
                  final p = await SharedPreferences.getInstance();
                  await p.setStringList('favorites', newSet.toList());
                  favoritesNotifier.value = newSet;
                },
                icon: Icon(
                  isFav ? Icons.star_rounded : Icons.star_border_rounded,
                  color: goldColor,
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: cardBg(context),
                    borderRadius: BorderRadius.circular(18),
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
                        style: TextStyle(
                          color: txtSecondary(context),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            price,
                            style: TextStyle(
                              color: txtPrimary(context),
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            unit,
                            style: TextStyle(
                              color: txtTertiary(context),
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
            const SizedBox(height: 12),
            Row(
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
                  '(${isUp ? "+" : ""}${changeAmount.abs().toStringAsFixed(0)})',
                  style: TextStyle(
                    color: changeColor.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: ['1D', '1W', '1M', '3M', '1Y'].map((r) {
                final sel = range == r;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => range = r),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: sel ? goldColor : cardBg(context),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        r,
                        style: TextStyle(
                          color:
                              sel ? Colors.black : txtSecondary(context),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Container(
              height: 200,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cardBg(context),
                borderRadius: BorderRadius.circular(16),
              ),
              child: CustomPaint(
                painter: ChartPainter(detailData, changeColor),
                child: const SizedBox.expand(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: ['09:00', '12:00', '15:00', '18:00']
                  .map((t) => Text(
                        t,
                        style: TextStyle(
                          color: txtTertiary(context),
                          fontSize: 10,
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg(context),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _statRow(context, 'بیشترین قیمت', price, goldColor),
                  _divider(context),
                  _statRow(context, 'کمترین قیمت', price, goldColor),
                  _divider(context),
                  _statRow(
                    context,
                    'تغییرات روزانه',
                    '${isUp ? "+" : ""}${change.toStringAsFixed(2)}%',
                    changeColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ValueListenableBuilder<Set<String>>(
              valueListenable: favoritesNotifier,
              builder: (context, favs, _) {
                final isFav = favs.contains(code);
                return GestureDetector(
                  onTap: () async {
                    final newSet = Set<String>.from(favs);
                    if (isFav) {
                      newSet.remove(code);
                    } else {
                      newSet.add(code);
                    }
                    final p = await SharedPreferences.getInstance();
                    await p.setStringList('favorites', newSet.toList());
                    favoritesNotifier.value = newSet;
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [goldLight, goldColor, goldDark],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isFav
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: Colors.black,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isFav
                              ? 'حذف از علاقه‌مندی‌ها'
                              : 'افزودن به علاقه‌مندی‌ها',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _statRow(
      BuildContext context, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: txtSecondary(context), fontSize: 13),
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

  Widget _divider(BuildContext context) {
    return Divider(
      height: 1,
      color: txtTertiary(context).withOpacity(0.1),
    );
  }
}

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

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [color.withOpacity(0.3), color.withOpacity(0.0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(covariant ChartPainter old) => false;
}
