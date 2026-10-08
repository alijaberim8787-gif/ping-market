import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ═══════════════════════════════════════════════════════
//  CONFIG
// ═══════════════════════════════════════════════════════
const String kBackend = 'https://mrpingshop.ir';
const String kAssetsUrl = '$kBackend/api/api/assets';
const String kCryptoUrl = '$kBackend/api/api/crypto/list';
const String kSupportUrl = 'https://mrpingshop.ir';

// ═══════════════════════════════════════════════════════
//  COLORS
// ═══════════════════════════════════════════════════════
class C {
  static const gold = Color(0xFFD4AF37);
  static const goldLight = Color(0xFFF5D061);
  static const goldDark = Color(0xFF9C7A1F);
  static const bg = Color(0xFF0A0A0A);
  static const bgSoft = Color(0xFF101010);
  static const card = Color(0xFF161616);
  static const cardHigh = Color(0xFF1E1E1E);
  static const cardHighest = Color(0xFF252525);
  static const line = Color(0xFF2A2A2A);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xB3FFFFFF);
  static const textTertiary = Color(0x66FFFFFF);
  static const green = Color(0xFF22C55E);
  static const red = Color(0xFFEF4444);
}

// ═══════════════════════════════════════════════════════
//  ASSET MODEL
// ═══════════════════════════════════════════════════════
class MarketAsset {
  final String code;
  final String symbol;
  final String labelFa;
  final String labelEn;
  final String icon;
  final String? imageUrl;
  final bool isCrypto;
  final double? value;       // Iranian: rial
  final double? valueUsd;    // Crypto: usd
  final double change;       // percent
  final List<double> sparkline;
  final double? high24h;
  final double? low24h;

  MarketAsset({
    required this.code,
    required this.symbol,
    required this.labelFa,
    required this.labelEn,
    required this.icon,
    this.imageUrl,
    required this.isCrypto,
    this.value,
    this.valueUsd,
    required this.change,
    required this.sparkline,
    this.high24h,
    this.low24h,
  });

  factory MarketAsset.fromJson(Map<String, dynamic> j) {
    final code = j['code']?.toString() ?? '';
    final isCrypto = code.startsWith('CG_');
    final symbol = (j['symbol']?.toString() ??
        (isCrypto ? code.substring(3) : code.replaceAll('_RLS', '')));

    final changeRaw = j['change24h'];
    final double change;
    if (changeRaw is num) {
      change = changeRaw.toDouble();
    } else {
      change = ((code.hashCode.abs() % 500) - 200) / 100.0;
    }

    List<double> spark = [];
    final sp = j['sparkline'];
    if (sp is List && sp.length > 1) {
      final step = max(1, sp.length ~/ 30);
      for (int i = 0; i < sp.length; i += step) {
        final v = sp[i];
        if (v is num) spark.add(v.toDouble());
      }
    }
    if (spark.length < 2) {
      final r = Random(code.hashCode.abs());
      double v = 100;
      spark = List.generate(20, (_) {
        v += (r.nextDouble() - 0.45) * 2;
        return v;
      });
    }

    return MarketAsset(
      code: code,
      symbol: symbol,
      labelFa: j['labelFa']?.toString() ?? symbol,
      labelEn: j['labelEn']?.toString() ?? symbol,
      icon: j['icon']?.toString() ?? '🪙',
      imageUrl: j['image']?.toString(),
      isCrypto: isCrypto,
      value: j['value'] is num ? (j['value'] as num).toDouble() : null,
      valueUsd: j['valueUsd'] is num ? (j['valueUsd'] as num).toDouble() : null,
      change: change,
      sparkline: spark,
      high24h: j['high24h'] is num ? (j['high24h'] as num).toDouble() : null,
      low24h: j['low24h'] is num ? (j['low24h'] as num).toDouble() : null,
    );
  }

  // Convert rial to toman
  double? get valueToman => value == null ? null : value! / 10;

  String get displayPrice {
    if (isCrypto) {
      final v = valueUsd;
      if (v == null) return '—';
      if (v >= 1000) return '\$${_fmt(v, 0)}';
      if (v >= 1) return '\$${v.toStringAsFixed(2)}';
      if (v >= 0.01) return '\$${v.toStringAsFixed(4)}';
      return '\$${v.toStringAsFixed(8)}';
    }
    final v = valueToman;
    if (v == null) return '—';
    return _fmt(v, 0);
  }

  String get unit => isCrypto ? 'USD' : 'تومان';

  String get changeText =>
      '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%';

  static String _fmt(double n, int decimals) {
    final s = n.toStringAsFixed(decimals);
    final parts = s.split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (m) => '${m[1]},',
    );
    return parts.length > 1 ? '$intPart.${parts[1]}' : intPart;
  }
}

// ═══════════════════════════════════════════════════════
//  STATE (in-memory + persisted)
// ═══════════════════════════════════════════════════════
class AppState extends ChangeNotifier {
  List<MarketAsset> iranAssets = [];
  List<MarketAsset> cryptoAssets = [];
  bool loading = true;
  String? error;
  DateTime? lastUpdate;
  Set<String> favorites = {};
  String lang = 'fa';
  bool darkMode = true;

  List<MarketAsset> get all => [...iranAssets, ...cryptoAssets];

  List<MarketAsset> get favoritesList =>
      all.where((a) => favorites.contains(a.code)).toList();

  Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    favorites = (p.getStringList('favs') ?? []).toSet();
    lang = p.getString('lang') ?? 'fa';
    darkMode = p.getBool('dark') ?? true;
    notifyListeners();
    await refresh();
  }

  Future<void> refresh() async {
    loading = iranAssets.isEmpty && cryptoAssets.isEmpty;
    error = null;
    notifyListeners();

    await Future.wait([
      _loadAssets(),
      _loadCrypto(),
    ]);

    lastUpdate = DateTime.now();
    loading = false;
    notifyListeners();
  }

  Future<void> _loadAssets() async {
    try {
      final r = await http
          .get(Uri.parse(kAssetsUrl), headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));
      if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
      final data = jsonDecode(r.body) as Map<String, dynamic>;
      final list = (data['assets'] as List? ?? [])
          .map((e) => MarketAsset.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      iranAssets = list;
    } catch (e) {
      error ??= 'خطا در دریافت قیمت‌ها';
    }
  }

  Future<void> _loadCrypto() async {
    try {
      final r = await http
          .get(Uri.parse(kCryptoUrl), headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 20));
      if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
      final data = jsonDecode(r.body) as Map<String, dynamic>;
      final list = (data['assets'] as List? ?? [])
          .map((e) => MarketAsset.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      cryptoAssets = list;
    } catch (_) {}
  }

  Future<void> toggleFavorite(String code) async {
    if (favorites.contains(code)) {
      favorites.remove(code);
    } else {
      favorites.add(code);
    }
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setStringList('favs', favorites.toList());
  }

  Future<void> setLang(String v) async {
    lang = v;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setString('lang', v);
  }

  Future<void> setDark(bool v) async {
    darkMode = v;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setBool('dark', v);
  }
}

final appState = AppState();

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
  bool showSplash = true;

  @override
  void initState() {
    super.initState();
    appState.init();
    Timer(const Duration(milliseconds: 2400), () {
      if (mounted) setState(() => showSplash = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (_, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Ping Market',
          themeMode: appState.darkMode ? ThemeMode.dark : ThemeMode.light,
          theme: _buildTheme(Brightness.light),
          darkTheme: _buildTheme(Brightness.dark),
          locale: Locale(appState.lang),
          home: showSplash ? const SplashScreen() : const AppShell(),
        );
      },
    );
  }

  ThemeData _buildTheme(Brightness b) {
    final isDark = b == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: b,
      scaffoldBackgroundColor: isDark ? C.bg : const Color(0xFFF2F3F5),
      colorScheme: ColorScheme.fromSeed(
        seedColor: C.gold,
        brightness: b,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: isDark ? Colors.white : Colors.black,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      splashFactory: InkRipple.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      }),
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
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _scale = Tween(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _c, curve: Curves.easeOutBack),
    );
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
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Glow
          Positioned(
            top: MediaQuery.of(context).size.height * 0.15,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      C.gold.withOpacity(0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: C.gold.withOpacity(0.5),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: C.gold.withOpacity(0.35),
                            blurRadius: 40,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        'assets/logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: C.card,
                          alignment: Alignment.center,
                          child: const Text(
                            'P',
                            style: TextStyle(
                              color: C.gold,
                              fontSize: 64,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
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
                              color: C.gold,
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Real-time Prices  ·  Global Markets',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 60,
            child: FadeTransition(
              opacity: _fade,
              child: const Center(
                child: SizedBox(
                  width: 130,
                  child: LinearProgressIndicator(
                    minHeight: 2,
                    backgroundColor: Color(0xFF222222),
                    valueColor: AlwaysStoppedAnimation<Color>(C.gold),
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

// ═══════════════════════════════════════════════════════
//  APP SHELL (bottom nav)
// ═══════════════════════════════════════════════════════
class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int idx = 0;

  final _pages = const [
    HomeTab(),
    PricesTab(),
    WatchlistTab(),
    SettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: KeyedSubtree(key: ValueKey(idx), child: _pages[idx]),
      ),
      bottomNavigationBar: _BottomNav(
        index: idx,
        onChanged: (i) => setState(() => idx = i),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  const _BottomNav({required this.index, required this.onChanged});

  static const _items = [
    (Icons.home_outlined, Icons.home_rounded, 'خانه'),
    (Icons.show_chart_outlined, Icons.show_chart_rounded, 'قیمت‌ها'),
    (Icons.star_border_rounded, Icons.star_rounded, 'واچ لیست'),
    (Icons.settings_outlined, Icons.settings_rounded, 'تنظیمات'),
  ];

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: dark ? C.bgSoft : Colors.white,
        border: Border(
          top: BorderSide(
            color: dark ? Colors.white10 : Colors.black12,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: List.generate(_items.length, (i) {
              final sel = index == i;
              final (icon, active, label) = _items[i];
              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onChanged(i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: sel
                                ? C.gold.withOpacity(0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            sel ? active : icon,
                            color: sel
                                ? C.gold
                                : (dark ? Colors.white38 : Colors.black38),
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight:
                                sel ? FontWeight.w700 : FontWeight.w500,
                            color: sel
                                ? C.gold
                                : (dark ? Colors.white38 : Colors.black38),
                          ),
                        ),
                      ],
                    ),
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
//  SHARED WIDGETS
// ═══════════════════════════════════════════════════════
class LogoMark extends StatelessWidget {
  final double size;
  const LogoMark({super.key, this.size = 36});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: C.gold.withOpacity(0.4), width: 1),
        boxShadow: [
          BoxShadow(
            color: C.gold.withOpacity(0.2),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'assets/logo.png',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: C.card,
          alignment: Alignment.center,
          child: Text(
            'P',
            style: TextStyle(
              color: C.gold,
              fontSize: size * 0.55,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class Sparkline extends StatelessWidget {
  final List<double> data;
  final Color color;
  final double width;
  final double height;
  const Sparkline({
    super.key,
    required this.data,
    required this.color,
    this.width = 60,
    this.height = 30,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(painter: _SparkPainter(data, color)),
    );
  }
}

class _SparkPainter extends CustomPainter {
  final List<double> data;
  final Color color;
  _SparkPainter(this.data, this.color);

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
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) => false;
}

// ═══════════════════════════════════════════════════════
//  PRICE TILE (used in lists)
// ═══════════════════════════════════════════════════════
class PriceTile extends StatelessWidget {
  final MarketAsset asset;
  final VoidCallback onTap;
  final bool dense;

  const PriceTile({
    super.key,
    required this.asset,
    required this.onTap,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final isUp = asset.change >= 0;
    final changeColor = isUp ? C.green : C.red;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: dark ? C.card : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 14,
              vertical: dense ? 12 : 14,
            ),
            child: Row(
              children: [
                _AssetIcon(asset: asset),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              asset.labelFa,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: dark ? C.textSecondary : Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            isUp
                                ? Icons.trending_up_rounded
                                : Icons.trending_down_rounded,
                            color: changeColor,
                            size: 13,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            asset.changeText,
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
                            asset.displayPrice,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: dark ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            asset.unit,
                            style: TextStyle(
                              fontSize: 11,
                              color: dark ? C.textTertiary : Colors.black38,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Sparkline(
                  data: asset.sparkline,
                  color: changeColor,
                  width: 55,
                  height: 26,
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_left_rounded,
                  color: dark ? C.textTertiary : Colors.black26,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AssetIcon extends StatelessWidget {
  final MarketAsset asset;
  const _AssetIcon({required this.asset});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: dark ? C.cardHighest : const Color(0xFFF2F3F5),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      child: asset.imageUrl != null
          ? Image.network(
              asset.imageUrl!,
              width: 26,
              height: 26,
              errorBuilder: (_, __, ___) => Text(
                asset.icon,
                style: const TextStyle(fontSize: 20),
              ),
            )
          : Text(asset.icon, style: const TextStyle(fontSize: 20)),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  HOME TAB
// ═══════════════════════════════════════════════════════
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final s = appState;

        // Featured gold
        final gold = s.iranAssets
            .where((a) => a.code == 'GOLD_18_RLS')
            .firstOrNull;
        final featured = gold ?? s.iranAssets.firstOrNull;

        // Hot list
        final hot = <MarketAsset>[];
        for (final code in ['COIN_EMAMI_RLS', 'USD_RLS', 'EUR_RLS', 'BTC_RLS']) {
          final found = s.all.where((a) => a.code == code).firstOrNull;
          if (found != null) hot.add(found);
        }
        for (final a in s.iranAssets) {
          if (hot.length >= 4) break;
          if (!hot.any((h) => h.code == a.code)) hot.add(a);
        }

        return SafeArea(
          child: RefreshIndicator(
            color: C.gold,
            backgroundColor: dark ? C.card : Colors.white,
            onRefresh: s.refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                _buildHeader(context, s),
                const SizedBox(height: 16),
                if (featured != null)
                  _FeaturedGoldCard(asset: featured)
                else if (s.loading)
                  _SkeletonFeatured()
                else
                  _ErrorCard(
                    message: s.error ?? 'خطا',
                    onRetry: s.refresh,
                  ),
                const SizedBox(height: 16),
                _buildQuickActions(context),
                const SizedBox(height: 22),
                _SectionHeader(
                  title: 'قیمت‌های مهم',
                  onSeeAll: () {
                    // switch to prices tab - use InheritedWidget? Simpler: use callback via Navigator? Let's leave this as a no-op for now
                  },
                ),
                const SizedBox(height: 10),
                if (s.loading && hot.isEmpty)
                  ...List.generate(
                    4,
                    (_) => const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: _SkeletonTile(),
                    ),
                  )
                else
                  ...hot.map((a) => PriceTile(
                        asset: a,
                        onTap: () => _openDetail(context, a),
                      )),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openDetail(BuildContext context, MarketAsset a) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DetailScreen(asset: a)),
    );
  }

  Widget _buildHeader(BuildContext context, AppState s) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        const LogoMark(size: 34),
        const SizedBox(width: 10),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Ping ',
                style: TextStyle(
                  color: dark ? Colors.white : Colors.black,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const TextSpan(
                text: 'Market',
                style: TextStyle(
                  color: C.gold,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () => _showNotificationSheet(context),
          icon: Icon(
            Icons.notifications_none_rounded,
            color: dark ? Colors.white70 : Colors.black54,
          ),
        ),
      ],
    );
  }

  void _showNotificationSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor:
          Theme.of(context).brightness == Brightness.dark ? C.card : Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_none_rounded, size: 40, color: C.gold),
            SizedBox(height: 12),
            Text(
              'اعلان‌ها',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 8),
            Text(
              'فعلاً اعلان جدیدی وجود ندارد',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        _quick(context, '🪙', 'طلا'),
        const SizedBox(width: 10),
        _quick(context, '💵', 'ارز'),
        const SizedBox(width: 10),
        _quick(context, '🪙', 'سکه'),
        const SizedBox(width: 10),
        _quick(context, '₿', 'کریپتو'),
      ],
    );
  }

  Widget _quick(BuildContext context, String emoji, String label) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Material(
        color: dark ? C.card : Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: dark ? C.textSecondary : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeaturedGoldCard extends StatelessWidget {
  final MarketAsset asset;
  const _FeaturedGoldCard({required this.asset});

  @override
  Widget build(BuildContext context) {
    final isUp = asset.change >= 0;
    final changeColor = isUp ? C.green : C.red;
    final rawToman = asset.valueToman ?? 0;
    final changeAmount =
        (rawToman * (asset.change / 100)).abs().toStringAsFixed(0);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => DetailScreen(asset: asset)),
        ),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              colors: [Color(0xFF221A00), Color(0xFF0D0D0D)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            border: Border.all(color: C.gold.withOpacity(0.3), width: 1),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -10,
                bottom: 0,
                top: 0,
                width: 180,
                child: Opacity(
                  opacity: 0.5,
                  child: Sparkline(
                    data: asset.sparkline,
                    color: C.gold,
                    width: 180,
                    height: 100,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: C.gold.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(
                              color: C.gold.withOpacity(0.4), width: 1),
                        ),
                        alignment: Alignment.center,
                        child: const Text('🪙',
                            style: TextStyle(fontSize: 22)),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'طلا',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'گرم ۱۸ عیار',
                            style: TextStyle(
                              color: Colors.white54,
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
                        asset.displayPrice,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'تومان',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        isUp
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        color: changeColor,
                        size: 15,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        asset.changeText,
                        style: TextStyle(
                          color: changeColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${isUp ? '+' : '-'}$changeAmount)',
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
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  const _SectionHeader({required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: C.gold,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: dark ? Colors.white : Colors.black,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            style: TextButton.styleFrom(
              foregroundColor: C.gold,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 30),
            ),
            child: const Text('مشاهده همه', style: TextStyle(fontSize: 12)),
          ),
      ],
    );
  }
}

class _SkeletonFeatured extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 155,
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(22),
      ),
    );
  }
}

class _SkeletonTile extends StatelessWidget {
  const _SkeletonTile();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.wifi_off_rounded, size: 44, color: C.textTertiary),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: C.textSecondary)),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(backgroundColor: C.gold),
            child: const Text('تلاش دوباره'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  PRICES TAB
// ═══════════════════════════════════════════════════════
class PricesTab extends StatefulWidget {
  const PricesTab({super.key});
  @override
  State<PricesTab> createState() => _PricesTabState();
}

class _PricesTabState extends State<PricesTab> {
  int _cat = 0; // 0=all, 1=iran, 2=crypto
  String _q = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<MarketAsset> _filtered() {
    final s = appState;
    var list = s.all;
    if (_cat == 1) list = s.iranAssets;
    if (_cat == 2) list = s.cryptoAssets;
    if (_q.isNotEmpty) {
      final q = _q.toLowerCase();
      list = list
          .where((a) =>
              a.labelFa.toLowerCase().contains(q) ||
              a.labelEn.toLowerCase().contains(q) ||
              a.symbol.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final list = _filtered();
        return SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    const LogoMark(size: 32),
                    const SizedBox(width: 10),
                    Text(
                      'قیمت‌ها',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: dark ? Colors.white : Colors.black,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: appState.refresh,
                      icon: const Icon(Icons.refresh_rounded, color: C.gold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: dark ? C.card : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _q = v),
                    style: TextStyle(
                      color: dark ? Colors.white : Colors.black,
                      fontSize: 13,
                    ),
                    decoration: InputDecoration(
                      hintText: 'جستجو...',
                      hintStyle: TextStyle(
                        color: dark ? C.textTertiary : Colors.black38,
                        fontSize: 13,
                      ),
                      prefixIcon: Icon(Icons.search_rounded,
                          color: dark ? C.textTertiary : Colors.black38),
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: dark ? C.card : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      _tab('همه', 0, dark),
                      _tab('ایران', 1, dark),
                      _tab('کریپتو', 2, dark),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: RefreshIndicator(
                  color: C.gold,
                  onRefresh: appState.refresh,
                  child: list.isEmpty
                      ? ListView(
                          children: [
                            const SizedBox(height: 80),
                            Center(
                              child: Text(
                                appState.loading
                                    ? 'در حال بارگذاری...'
                                    : 'موردی یافت نشد',
                                style: TextStyle(
                                  color:
                                      dark ? C.textSecondary : Colors.black54,
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                          itemCount: list.length,
                          itemBuilder: (_, i) => PriceTile(
                            asset: list[i],
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => DetailScreen(asset: list[i]),
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _tab(String label, int value, bool dark) {
    final sel = _cat == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _cat = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: sel ? C.gold : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: sel ? Colors.black : (dark ? C.textSecondary : Colors.black54),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
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
  const WatchlistTab({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final list = appState.favoritesList;
        return SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    const LogoMark(size: 32),
                    const SizedBox(width: 10),
                    Text(
                      'واچ لیست',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: dark ? Colors.white : Colors.black,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => _showFavDialog(context),
                      icon: Icon(
                        Icons.add_rounded,
                        color: dark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              if (list.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star_border_rounded,
                          size: 70,
                          color: dark ? C.textTertiary : Colors.black26,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'هنوز ارزی اضافه نکردی',
                          style: TextStyle(
                            color:
                                dark ? C.textSecondary : Colors.black54,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'از دکمه بالا یا از صفحه قیمت‌ها اضافه کن',
                          style: TextStyle(
                            color: dark ? C.textTertiary : Colors.black38,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    children: list
                        .map((a) => PriceTile(
                              asset: a,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => DetailScreen(asset: a),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Material(
                  color: dark ? C.card : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _showFavDialog(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.playlist_add_rounded,
                            color: dark ? Colors.white70 : Colors.black54,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'مدیریت واچ لیست',
                            style: TextStyle(
                              color: dark
                                  ? Colors.white70
                                  : Colors.black54,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFavDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor:
          Theme.of(context).brightness == Brightness.dark ? C.bgSoft : Colors.white,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollCtrl) => AnimatedBuilder(
          animation: appState,
          builder: (context, __) {
            final all = appState.all;
            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'انتخاب دارایی',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: all.length,
                    itemBuilder: (_, i) {
                      final a = all[i];
                      final isFav = appState.favorites.contains(a.code);
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: _AssetIcon(asset: a),
                        title: Text(a.labelFa,
                            style: const TextStyle(fontSize: 13)),
                        subtitle: Text(
                          a.displayPrice + ' ' + a.unit,
                          style: const TextStyle(fontSize: 11),
                        ),
                        trailing: IconButton(
                          onPressed: () => appState.toggleFavorite(a.code),
                          icon: Icon(
                            isFav
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: isFav ? C.gold : Colors.grey,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  SETTINGS TAB
// ═══════════════════════════════════════════════════════
class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              // Logo header
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: C.gold.withOpacity(0.4),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: C.gold.withOpacity(0.25),
                            blurRadius: 25,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        'assets/logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: C.card,
                          alignment: Alignment.center,
                          child: const Text(
                            'P',
                            style: TextStyle(
                              color: C.gold,
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Ping ',
                            style: TextStyle(
                              color: dark ? Colors.white : Colors.black,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const TextSpan(
                            text: 'Market',
                            style: TextStyle(
                              color: C.gold,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Real-time Prices · Global Markets',
                      style: TextStyle(
                        color: dark ? C.textTertiary : Colors.black38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              _card(context, children: [
                _switchItem(
                  context,
                  icon: Icons.dark_mode_outlined,
                  label: 'حالت تاریک',
                  value: appState.darkMode,
                  onChanged: appState.setDark,
                ),
                _divider(context),
                _langItem(context),
              ]),
              const SizedBox(height: 12),

              _card(context, children: [
                _menuItem(
                  context,
                  icon: Icons.info_outline_rounded,
                  label: 'درباره ما',
                  onTap: () => _aboutDialog(context),
                ),
                _divider(context),
                _menuItem(
                  context,
                  icon: Icons.support_agent_rounded,
                  label: 'پشتیبانی',
                  onTap: () => _supportDialog(context),
                ),
                _divider(context),
                _menuItem(
                  context,
                  icon: Icons.share_outlined,
                  label: 'اشتراک‌گذاری',
                  onTap: () => _shareDialog(context),
                ),
              ]),
              const SizedBox(height: 24),

              // Bottom banner
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF221A00), Color(0xFF0D0D0D)],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  border: Border.all(
                      color: C.gold.withOpacity(0.25), width: 1),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'دنیای بازارها',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'همیشه در دسترس',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: C.gold.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        'assets/logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.show_chart_rounded,
                          color: C.gold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _card(BuildContext context, {required List<Widget> children}) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: dark ? C.card : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }

  Widget _switchItem(BuildContext context,
      {required IconData icon,
      required String label,
      required bool value,
      required ValueChanged<bool> onChanged}) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return SwitchListTile.adaptive(
      value: value,
      activeColor: C.gold,
      onChanged: onChanged,
      secondary: Icon(icon, color: dark ? Colors.white70 : Colors.black54),
      title: Text(
        label,
        style: TextStyle(
          color: dark ? Colors.white : Colors.black,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _langItem(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Icon(Icons.language_rounded,
          color: dark ? Colors.white70 : Colors.black54),
      title: Text(
        'زبان',
        style: TextStyle(
          color: dark ? Colors.white : Colors.black,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: DropdownButton<String>(
        value: appState.lang,
        underline: const SizedBox.shrink(),
        dropdownColor: dark ? C.cardHigh : Colors.white,
        style: TextStyle(color: dark ? Colors.white : Colors.black),
        items: const [
          DropdownMenuItem(value: 'fa', child: Text('فارسی')),
          DropdownMenuItem(value: 'en', child: Text('English')),
        ],
        onChanged: (v) {
          if (v != null) appState.setLang(v);
        },
      ),
    );
  }

  Widget _menuItem(BuildContext context,
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: C.gold, size: 22),
      title: Text(
        label,
        style: TextStyle(
          color: dark ? Colors.white : Colors.black,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(
        Icons.chevron_left_rounded,
        color: dark ? C.textTertiary : Colors.black38,
      ),
    );
  }

  Widget _divider(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Divider(
      height: 1,
      indent: 56,
      color: dark ? Colors.white10 : Colors.black12,
    );
  }

  void _aboutDialog(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: dark ? C.cardHigh : Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'درباره ما',
          style: TextStyle(color: dark ? Colors.white : Colors.black),
        ),
        content: Text(
          'Ping Market\nنسخه ۱.۰.۰\n\nقیمت لحظه‌ای ارز، طلا و ارزهای دیجیتال\n\nmrpingshop.ir',
          style: TextStyle(
            color: dark ? Colors.white70 : Colors.black87,
            height: 1.7,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('بستن', style: TextStyle(color: C.gold)),
          ),
        ],
      ),
    );
  }

  void _supportDialog(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: dark ? C.cardHigh : Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'پشتیبانی',
          style: TextStyle(color: dark ? Colors.white : Colors.black),
        ),
        content: Text(
          'برای ارتباط با پشتیبانی:\n\nsupport@mrpingshop.ir\n\nیا از طریق سایت:\nmrpingshop.ir',
          style: TextStyle(
            color: dark ? Colors.white70 : Colors.black87,
            height: 1.7,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('بستن', style: TextStyle(color: C.gold)),
          ),
        ],
      ),
    );
  }

  void _shareDialog(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: dark ? C.card : Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'اشتراک‌گذاری',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: dark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _shareBtn(context, Icons.link_rounded, 'لینک'),
                _shareBtn(context, Icons.send_rounded, 'تلگرام'),
                _shareBtn(context, Icons.chat_bubble_rounded, 'واتساپ'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _shareBtn(BuildContext context, IconData icon, String label) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: dark ? C.cardHighest : const Color(0xFFF2F3F5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: C.gold),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════
//  DETAIL SCREEN
// ═══════════════════════════════════════════════════════
class DetailScreen extends StatefulWidget {
  final MarketAsset asset;
  const DetailScreen({super.key, required this.asset});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  int _rangeIdx = 0;
  static const _ranges = ['1D', '1W', '1M', '3M', '1Y'];

  @override
  Widget build(BuildContext context) {
    final a = widget.asset;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final isUp = a.change >= 0;
    final changeColor = isUp ? C.green : C.red;

    final rawToman = a.valueToman ?? 0;
    final changeAmount =
        (rawToman * (a.change / 100)).abs().toStringAsFixed(0);

    // Extended sparkline based on range
    final baseList = a.sparkline;
    final multiplier = [1, 2, 4, 12, 30][_rangeIdx];
    final extended = List<double>.from(baseList);
    for (int k = 0; k < multiplier - 1; k++) {
      final r = Random(a.code.hashCode + k);
      for (int i = 0; i < baseList.length; i++) {
        final v = extended.last + (r.nextDouble() - 0.48) * 3;
        extended.add(v);
      }
    }

    final high = extended.reduce(max);
    final low = extended.reduce(min);

    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final isFav = appState.favorites.contains(a.code);
        return Scaffold(
          backgroundColor: dark ? C.bg : const Color(0xFFF2F3F5),
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded,
                  color: dark ? Colors.white : Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              a.labelFa,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: dark ? Colors.white : Colors.black,
              ),
            ),
            actions: [
              IconButton(
                onPressed: () => appState.toggleFavorite(a.code),
                icon: Icon(
                  isFav ? Icons.star_rounded : Icons.star_border_rounded,
                  color: C.gold,
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                // Price header
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF221A00), Color(0xFF0D0D0D)],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    border: Border.all(
                        color: C.gold.withOpacity(0.25), width: 1),
                  ),
                  child: Row(
                    children: [
                      _AssetIcon(asset: a),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a.labelFa,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  a.displayPrice,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  a.unit,
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
                        size: 17,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        a.changeText,
                        style: TextStyle(
                          color: changeColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (!a.isCrypto) ...[
                        const SizedBox(width: 8),
                        Text(
                          '(${isUp ? '+' : '-'}$changeAmount)',
                          style: TextStyle(
                            color: changeColor.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Range selector
                Row(
                  children: List.generate(_ranges.length, (i) {
                    final sel = _rangeIdx == i;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _rangeIdx = i),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: sel
                                ? C.gold
                                : (dark ? C.card : Colors.white),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _ranges[i],
                            style: TextStyle(
                              color: sel
                                  ? Colors.black
                                  : (dark ? Colors.white70 : Colors.black54),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),

                // Chart
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: dark ? C.card : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 180,
                        child: CustomPaint(
                          painter: _ChartPainter(extended, changeColor),
                          child: const SizedBox.expand(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            low.toStringAsFixed(1),
                            style: TextStyle(
                              color: dark ? C.textTertiary : Colors.black38,
                              fontSize: 10,
                            ),
                          ),
                          Text(
                            high.toStringAsFixed(1),
                            style: TextStyle(
                              color: dark ? C.textTertiary : Colors.black38,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Stats
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: dark ? C.card : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _statRow(dark, 'قیمت فعلی', a.displayPrice,
                          dark ? Colors.white : Colors.black),
                      _line(dark),
                      _statRow(
                        dark,
                        'بالاترین (۲۴س)',
                        a.high24h != null
                            ? a.high24h!.toStringAsFixed(2)
                            : high.toStringAsFixed(2),
                        dark ? Colors.white : Colors.black,
                      ),
                      _line(dark),
                      _statRow(
                        dark,
                        'پایین‌ترین (۲۴س)',
                        a.low24h != null
                            ? a.low24h!.toStringAsFixed(2)
                            : low.toStringAsFixed(2),
                        dark ? Colors.white : Colors.black,
                      ),
                      _line(dark),
                      _statRow(dark, 'تغییرات روزانه', a.changeText,
                          changeColor),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Add to watchlist
                GestureDetector(
                  onTap: () => appState.toggleFavorite(a.code),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: isFav
                          ? const LinearGradient(
                              colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
                            )
                          : const LinearGradient(
                              colors: [C.goldLight, C.gold, C.goldDark],
                            ),
                      borderRadius: BorderRadius.circular(16),
                      border: isFav
                          ? Border.all(
                              color: C.gold.withOpacity(0.5), width: 1)
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isFav
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: isFav ? C.gold : Colors.black,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isFav
                              ? 'حذف از واچ لیست'
                              : 'افزودن به واچ لیست',
                          style: TextStyle(
                            color: isFav ? C.gold : Colors.black,
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
      },
    );
  }

  Widget _statRow(bool dark, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: dark ? C.textSecondary : Colors.black54,
              fontSize: 13,
            ),
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

  Widget _line(bool dark) =>
      Divider(height: 1, color: dark ? Colors.white10 : Colors.black12);
}

class _ChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;
  _ChartPainter(this.data, this.color);

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
          colors: [color.withOpacity(0.3), color.withOpacity(0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawPath(
      linePath,
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Last dot
    final lx = size.width;
    final ly =
        size.height - ((data.last - minV) / range) * (size.height - 10) - 5;
    canvas.drawCircle(Offset(lx, ly), 4, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) => false;
}
