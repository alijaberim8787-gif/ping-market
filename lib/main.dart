import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ═══════════════════════════════════════════════════════
//  CONFIG
// ═══════════════════════════════════════════════════════
const String kBackend = 'https://mrpingshop.ir';
const String kAssetsUrl = '$kBackend/api/assets';
const String kCryptoUrl = '$kBackend/api/crypto/list';

// ═══════════════════════════════════════════════════════
//  COLORS (Neon & Glass Theme)
// ═══════════════════════════════════════════════════════
class C {
  static const bg = Color(0xFF05050A);
  static const surface = Color(0xFF11111A);
  static const surfaceLight = Color(0xFF1C1C2A);
  
  static const primaryPurple = Color(0xFF8A2BE2);
  static const primaryCyan = Color(0xFF00E5FF);
  static const gold = Color(0xFFFFD700);
  static const green = Color(0xFF00FA9A);
  static const red = Color(0xFFFF3366);
  
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFA0A0B0);
  static const textTertiary = Color(0xFF606070);
}

// ═══════════════════════════════════════════════════════
//  LOCALIZATION
// ═══════════════════════════════════════════════════════
class S {
  static const Map<String, List<String>> _d = {
    'home': ['خانه', 'Home'],
    'prices': ['قیمت‌ها', 'Prices'],
    'favs': ['علاقه‌مندی‌ها', 'Favorites'],
    'settings': ['تنظیمات', 'Settings'],
    'hello': ['سلام', 'Hello'],
    'searchHint': ['جستجوی قیمت‌ها...', 'Search prices...'],
    'trendUp': ['بازار جهانی در اوج رشد', 'Global market at its peak'],
    'upTo': ['تا ۸.۸۷٪ افزایش', 'Up to 8.87% increase'],
    'all': ['همه', 'All'],
    'currency': ['ارزها', 'Currencies'],
    'crypto': ['کریپتو', 'Crypto'],
    'gold': ['طلا', 'Gold'],
    'dollar': ['دلار', 'Dollar'],
    'bitcoin': ['بیت‌کوین', 'Bitcoin'],
    'allMarkets': ['همه بازارها', 'All markets'],
    'iranRial': ['ریال ایران', 'Iranian Rial'],
    'toman': ['تومان', 'Toman'],
    'darkMode': ['حالت نمایش', 'Display mode'],
    'language': ['زبان برنامه', 'App language'],
    'notifications': ['اعلان‌ها', 'Notifications'],
    'support': ['پشتیبانی', 'Support'],
    'privacy': ['حریم خصوصی و امنیت', 'Privacy & Security'],
    'about': ['درباره ما', 'About'],
    'loading': ['در حال بارگذاری...', 'Loading...'],
  };

  static String get(String key, String lang) {
    final v = _d[key];
    if (v == null) return key;
    return lang == 'en' ? v[1] : v[0];
  }
}

// ═══════════════════════════════════════════════════════
//  MODELS & STATE (Same as before)
// ═══════════════════════════════════════════════════════
class MarketAsset {
  final String code;
  final String symbol;
  final String labelFa;
  final String labelEn;
  final String icon;
  final String? imageUrl;
  final bool isCrypto;
  final double? value;
  final double? valueUsd;
  final double change;
  final List<double> sparkline;

  MarketAsset({
    required this.code, required this.symbol, required this.labelFa, required this.labelEn,
    required this.icon, this.imageUrl, required this.isCrypto, this.value, this.valueUsd,
    required this.change, required this.sparkline,
  });

  factory MarketAsset.fromJson(Map<String, dynamic> j) {
    final code = j['code']?.toString() ?? '';
    final isCrypto = code.startsWith('CG_');
    final symbol = j['symbol']?.toString() ?? (isCrypto ? code.substring(3) : code.replaceAll('_RLS', ''));
    final changeRaw = j['change24h'];
    final double change = changeRaw is num ? changeRaw.toDouble() : ((code.hashCode.abs() % 500) - 200) / 100.0;

    List<double> spark = [];
    final sp = j['sparkline'];
    if (sp is List && sp.length > 1) {
      final step = max(1, sp.length ~/ 30);
      for (int i = 0; i < sp.length; i += step) {
        if (sp[i] is num) spark.add((sp[i] as num).toDouble());
      }
    }
    if (spark.length < 2) {
      final r = Random(code.hashCode.abs());
      double v = 100;
      spark = List.generate(20, (_) { v += (r.nextDouble() - 0.45) * 2; return v; });
    }

    return MarketAsset(
      code: code, symbol: symbol, labelFa: j['labelFa']?.toString() ?? symbol,
      labelEn: j['labelEn']?.toString() ?? symbol, icon: j['icon']?.toString() ?? '🪙',
      imageUrl: j['image']?.toString(), isCrypto: isCrypto,
      value: j['value'] is num ? (j['value'] as num).toDouble() : null,
      valueUsd: j['valueUsd'] is num ? (j['valueUsd'] as num).toDouble() : null,
      change: change, sparkline: spark,
    );
  }

  double? get valueToman => value == null ? null : value! / 10;

  String get displayPrice {
    if (isCrypto) {
      final v = valueUsd;
      if (v == null) return '—';
      if (v >= 1000) return '\$${_fmt(v, 0)}';
      if (v >= 1) return '\$${v.toStringAsFixed(2)}';
      return '\$${v.toStringAsFixed(4)}';
    }
    final v = valueToman;
    if (v == null) return '—';
    return _fmt(v, 0);
  }

  String get changeText => '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%';
  String displayLabelFor(String lang) => lang == 'en' ? labelEn : labelFa;

  static String _fmt(double n, int decimals) {
    final s = n.toStringAsFixed(decimals);
    final parts = s.split('.');
    final intPart = parts[0].replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
    return parts.length > 1 ? '$intPart.${parts[1]}' : intPart;
  }
}

final ValueNotifier<int> shellTab = ValueNotifier(0);

class AppState extends ChangeNotifier {
  List<MarketAsset> iran = [];
  List<MarketAsset> crypto = [];
  bool loading = true;
  Set<String> favorites = {};
  String lang = 'fa';

  List<MarketAsset> get all => [...iran, ...crypto];
  List<MarketAsset> get favList => all.where((a) => favorites.contains(a.code)).toList();

  MarketAsset? byCode(String code) {
    for (final a in all) { if (a.code == code) return a; }
    return null;
  }

  Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    favorites = (p.getStringList('favs') ?? []).toSet();
    lang = p.getString('lang') ?? 'fa';
    notifyListeners();
    await refresh();
  }

  Future<void> refresh() async {
    loading = iran.isEmpty && crypto.isEmpty;
    notifyListeners();
    await Future.wait([_loadAssets(), _loadCrypto()]);
    loading = false;
    notifyListeners();
  }

  Future<void> _loadAssets() async {
    try {
      final r = await http.get(Uri.parse(kAssetsUrl)).timeout(const Duration(seconds: 15));
      if (r.statusCode == 200) {
        iran = (jsonDecode(r.body)['assets'] as List).map((e) => MarketAsset.fromJson(e)).toList();
      }
    } catch (_) {}
  }

  Future<void> _loadCrypto() async {
    try {
      final r = await http.get(Uri.parse(kCryptoUrl)).timeout(const Duration(seconds: 20));
      if (r.statusCode == 200) {
        crypto = (jsonDecode(r.body)['assets'] as List).map((e) => MarketAsset.fromJson(e)).toList();
      }
    } catch (_) {}
  }

  Future<void> toggleFav(String code) async {
    if (favorites.contains(code)) favorites.remove(code); else favorites.add(code);
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setStringList('favs', favorites.toList());
  }

  String t(String key) => S.get(key, lang);
}

final appState = AppState();

// ═══════════════════════════════════════════════════════
//  MAIN APP
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
  @override
  void initState() {
    super.initState();
    appState.init();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (_, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Ping Market',
          themeMode: ThemeMode.dark,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: C.bg,
            colorScheme: ColorScheme.fromSeed(seedColor: C.primaryPurple, brightness: Brightness.dark),
            appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0),
          ),
          locale: Locale(appState.lang),
          home: const AppShell(),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════
//  APP SHELL & FLOATING NAV BAR
// ═══════════════════════════════════════════════════════
class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: shellTab,
      builder: (context, index, _) {
        return Scaffold(
          extendBody: true,
          body: IndexedStack(
            index: index,
            children: const [HomeTab(), PricesTab(), FavoritesTab(), SettingsTab()],
          ),
          bottomNavigationBar: _FloatingNav(
            index: index,
            onChanged: (i) => shellTab.value = i,
          ),
        );
      },
    );
  }
}

class _FloatingNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  const _FloatingNav({required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final t = appState.t;
    final items = [
      (Icons.home_outlined, Icons.home_rounded, t('home')),
      (Icons.show_chart_outlined, Icons.show_chart_rounded, t('prices')),
      (Icons.favorite_border_rounded, Icons.favorite_rounded, t('favs')),
      (Icons.settings_outlined, Icons.settings_rounded, t('settings')),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      height: 70,
      decoration: BoxDecoration(
        color: C.surface.withOpacity(0.85),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1.5),
        boxShadow: [
          BoxShadow(color: C.primaryPurple.withOpacity(0.15), blurRadius: 30, spreadRadius: 2),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Row(
            children: List.generate(items.length, (i) {
              final sel = index == i;
              final (icon, active, label) = items[i];
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        sel ? active : icon,
                        color: sel ? C.primaryPurple : C.textSecondary,
                        size: 26,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          color: sel ? C.primaryPurple : C.textSecondary,
                          fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
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
//  REUSABLE WIDGETS
// ═══════════════════════════════════════════════════════
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const GlassCard({super.key, required this.child, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: C.surfaceLight.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: child,
    );
  }
}

class Sparkline extends StatelessWidget {
  final List<double> data;
  final Color color;
  const Sparkline({super.key, required this.data, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 70,
      height: 30,
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
    final fillPath = Path()..moveTo(0, size.height);

    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height - ((data[i] - minV) / range) * size.height;
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
      fillPath.lineTo(x, y);
    }
    fillPath..lineTo(size.width, size.height)..close();

    canvas.drawPath(fillPath, Paint()..shader = LinearGradient(
      colors: [color.withOpacity(0.3), color.withOpacity(0)],
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)));

    canvas.drawPath(path, Paint()..color = color..strokeWidth = 2..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
  }
  @override
  bool shouldRepaint(covariant _SparkPainter old) => false;
}

class AssetIcon extends StatelessWidget {
  final MarketAsset asset;
  final double size;
  const AssetIcon({super.key, required this.asset, this.size = 44});

  @override
  Widget build(BuildContext context) {
    // Fallback colors for known assets
    Color bgColor = C.surfaceLight;
    Widget iconWidget = Text(asset.icon, style: TextStyle(fontSize: size * 0.5));

    if (asset.code == 'USD_RLS') {
      bgColor = const Color(0xFF0B4A29);
      iconWidget = const Text('\$', style: TextStyle(color: C.green, fontSize: 24, fontWeight: FontWeight.bold));
    } else if (asset.code == 'GOLD_18_RLS') {
      bgColor = const Color(0xFF4A3E0B);
      iconWidget = const Icon(Icons.diamond, color: C.gold, size: 24);
    } else if (asset.symbol == 'BTC') {
      bgColor = const Color(0xFF4A260B);
      iconWidget = const Text('₿', style: TextStyle(color: Colors.orange, fontSize: 26, fontWeight: FontWeight.bold));
    } else if (asset.symbol == 'ETH') {
      bgColor = const Color(0xFF1F1F4A);
      iconWidget = const Text('Ξ', style: TextStyle(color: Colors.blueAccent, fontSize: 26, fontWeight: FontWeight.bold));
    } else if (asset.symbol == 'USDT') {
      bgColor = const Color(0xFF0B4A3D);
      iconWidget = const Text('₮', style: TextStyle(color: Color(0xFF26A17B), fontSize: 24, fontWeight: FontWeight.bold));
    } else if (asset.imageUrl != null && asset.imageUrl!.isNotEmpty) {
      iconWidget = Image.network(asset.imageUrl!, width: size * 0.6, height: size * 0.6, errorBuilder: (_,__,___) => iconWidget);
      bgColor = Colors.transparent;
    }

    return Container(
      width: size, height: size,
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(14)),
      alignment: Alignment.center,
      child: iconWidget,
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
    final t = appState.t;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
        children: [
          // Top Bar
          Row(
            children: [
              Stack(
                children: [
                  GlassCard(
                    padding: const EdgeInsets.all(10),
                    child: const Icon(Icons.notifications_none_rounded, color: Colors.white),
                  ),
                  Positioned(right: 10, top: 10, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: C.red, shape: BoxShape.circle))),
                ],
              ),
              const Spacer(),
              Column(
                children: [
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(text: 'Ping ', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                        TextSpan(text: 'Market', style: TextStyle(color: C.primaryPurple, fontSize: 20, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  const Text('Real-time Prices · Global Markets', style: TextStyle(color: C.textSecondary, fontSize: 10)),
                ],
              ),
              const Spacer(),
              GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Text(appState.lang == 'fa' ? 'فا' : 'EN', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Banner
          Container(
            height: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [C.primaryPurple.withOpacity(0.6), C.bg],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              border: Border.all(color: C.primaryPurple.withOpacity(0.3)),
            ),
            child: Stack(
              children: [
                // Decorative chart
                Positioned(
                  right: -20, bottom: 0, top: 20, width: 200,
                  child: Opacity(
                    opacity: 0.5,
                    child: CustomPaint(painter: _BannerChartPainter()),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.trending_up_rounded, color: C.primaryCyan),
                          const SizedBox(width: 8),
                          Text(t('trendUp'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.arrow_drop_up_rounded, color: C.green),
                          Text(t('upTo'), style: const TextStyle(color: C.green, fontSize: 12)),
                        ],
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Search
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: C.textSecondary),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: t('searchHint'),
                      hintStyle: const TextStyle(color: C.textTertiary),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const Icon(Icons.tune_rounded, color: C.textSecondary),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Quick Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _quickAction(Icons.diamond_rounded, t('gold'), C.gold),
              _quickAction(Icons.attach_money_rounded, t('dollar'), C.green),
              _quickAction(Icons.currency_bitcoin_rounded, t('bitcoin'), Colors.orange),
              _quickAction(Icons.grid_view_rounded, t('allMarkets'), Colors.blueAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickAction(IconData icon, String label, Color color) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
        ],
      ),
    );
  }
}

class _BannerChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = C.primaryCyan.withOpacity(0.8);
    final w = size.width / 8;
    for (int i = 0; i < 8; i++) {
      final h = (i * 10.0) + 20;
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(i * w, size.height - h, w * 0.6, h), const Radius.circular(4)), p);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
  int _filter = 0;

  @override
  Widget build(BuildContext context) {
    final t = appState.t;
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              children: [
                const Icon(Icons.bar_chart_rounded, color: C.primaryCyan, size: 28),
                const SizedBox(width: 10),
                Text(t('prices'), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          // Filter Pills
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _filterPill(t('all'), 0),
                _filterPill(t('currency'), 1),
                _filterPill(t('crypto'), 2),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              children: appState.all.map((a) => _priceRow(a)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterPill(String label, int idx) {
    final sel = _filter == idx;
    return GestureDetector(
      onTap: () => setState(() => _filter = idx),
      child: Container(
        margin: const EdgeInsets.only(left: 10),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          gradient: sel ? const LinearGradient(colors: [C.primaryPurple, C.primaryCyan]) : null,
          color: sel ? null : C.surfaceLight,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(color: sel ? Colors.white : C.textSecondary, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _priceRow(MarketAsset a) {
    final isUp = a.change >= 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            AssetIcon(asset: a, size: 46),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.displayLabelFor(appState.lang), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(a.displayPrice, style: const TextStyle(color: C.textSecondary, fontSize: 13)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(a.changeText, style: TextStyle(color: isUp ? C.green : C.red, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Sparkline(data: a.sparkline, color: isUp ? C.green : C.red),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: C.textTertiary),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  FAVORITES TAB
// ═══════════════════════════════════════════════════════
class FavoritesTab extends StatelessWidget {
  const FavoritesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final t = appState.t;
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              children: [
                const Icon(Icons.star_rounded, color: C.primaryCyan, size: 28),
                const SizedBox(width: 10),
                Text(t('favs'), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                const Spacer(),
                GlassCard(padding: const EdgeInsets.all(8), child: const Icon(Icons.add_rounded, color: Colors.white)),
              ],
            ),
          ),
          Expanded(
            child: appState.favList.isEmpty
                ? Center(child: Text(t('noResults'), style: const TextStyle(color: C.textSecondary)))
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                    children: appState.favList.map((a) {
                      final isUp = a.change >= 0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GlassCard(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              AssetIcon(asset: a, size: 46),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(a.displayLabelFor(appState.lang), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 4),
                                    Text(a.displayPrice, style: const TextStyle(color: C.textSecondary, fontSize: 13)),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(a.changeText, style: TextStyle(color: isUp ? C.green : C.red, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Sparkline(data: a.sparkline, color: isUp ? C.green : C.red),
                                ],
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.more_vert_rounded, color: C.textTertiary),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
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
    final t = appState.t;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        children: [
          Row(
            children: [
              const Icon(Icons.settings_rounded, color: C.primaryCyan, size: 28),
              const SizedBox(width: 10),
              Text(t('settings'), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 30),
          _settingItem(Icons.wb_sunny_rounded, t('darkMode'), trailing: Icon(Icons.dark_mode_rounded, color: C.primaryPurple)),
          _settingItem(Icons.language_rounded, t('language'), trailing: Text(appState.lang == 'fa' ? 'فارسی' : 'English', style: const TextStyle(color: C.textSecondary))),
          _settingItem(Icons.notifications_none_rounded, t('notifications')),
          _settingItem(Icons.headset_mic_rounded, t('support')),
          _settingItem(Icons.shield_outlined, t('privacy')),
          _settingItem(Icons.info_outline_rounded, t('about')),
        ],
      ),
    );
  }

  Widget _settingItem(IconData icon, String title, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: C.textSecondary),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
            if (trailing != null) trailing,
            if (trailing == null) const Icon(Icons.chevron_left_rounded, color: C.textTertiary),
          ],
        ),
      ),
    );
  }
}