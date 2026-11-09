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
const List<String> kAssetsUrls = ['$kBackend/api/assets'];
// If the first URL fails, the second one is tried automatically.
const List<String> kCryptoUrls = [
  '$kBackend/api/crypto/list',
  '$kBackend/api/api/crypto/list',
];

// ═══════════════════════════════════════════════════════
//  THEME PALETTE (dark + light)
// ═══════════════════════════════════════════════════════
extension ColorOp on Color {
  Color op(double o) => withAlpha((o * 255).round().clamp(0, 255));
}

class Pal {
  final Brightness brightness;
  final Color bg, surface, surfaceLight, cardFill, cardBorder;
  final Color purple, cyan, gold, green, red;
  final Color text, textSecondary, textTertiary;

  const Pal({
    required this.brightness,
    required this.bg,
    required this.surface,
    required this.surfaceLight,
    required this.cardFill,
    required this.cardBorder,
    required this.purple,
    required this.cyan,
    required this.gold,
    required this.green,
    required this.red,
    required this.text,
    required this.textSecondary,
    required this.textTertiary,
  });

  static const dark = Pal(
    brightness: Brightness.dark,
    bg: Color(0xFF05050A),
    surface: Color(0xFF11111A),
    surfaceLight: Color(0xFF1C1C2A),
    cardFill: Color(0x661C1C2A),
    cardBorder: Color(0x0DFFFFFF),
    purple: Color(0xFF8A2BE2),
    cyan: Color(0xFF00E5FF),
    gold: Color(0xFFFFD700),
    green: Color(0xFF00FA9A),
    red: Color(0xFFFF3366),
    text: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFA0A0B0),
    textTertiary: Color(0xFF606070),
  );

  static const light = Pal(
    brightness: Brightness.light,
    bg: Color(0xFFF4F2FB),
    surface: Color(0xFFFFFFFF),
    surfaceLight: Color(0xFFEAE6F6),
    cardFill: Color(0xB3FFFFFF),
    cardBorder: Color(0x14000000),
    purple: Color(0xFF7B2FE0),
    cyan: Color(0xFF0097B2),
    gold: Color(0xFFB8860B),
    green: Color(0xFF00A86B),
    red: Color(0xFFE0245E),
    text: Color(0xFF14142B),
    textSecondary: Color(0xFF5A5A70),
    textTertiary: Color(0xFF9A9AB0),
  );
}

Pal get pal => appState.dark ? Pal.dark : Pal.light;

ThemeData buildTheme(Pal p) => ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      scaffoldBackgroundColor: p.bg,
      colorScheme: ColorScheme.fromSeed(seedColor: p.purple, brightness: p.brightness),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: p.text,
        centerTitle: true,
      ),
    );

// ═══════════════════════════════════════════════════════
//  LOCALIZATION
// ═══════════════════════════════════════════════════════
class S {
  static const Map<String, List<String>> _d = {
    'home': ['خانه', 'Home'],
    'prices': ['قیمت‌ها', 'Prices'],
    'favs': ['علاقه‌مندی‌ها', 'Favorites'],
    'settings': ['تنظیمات', 'Settings'],
    'tagline': ['قیمت لحظه‌ای بازار', 'Real-time Prices'],
    'searchHint': ['جستجوی قیمت‌ها...', 'Search prices...'],
    'trendUp': ['بازار امروز صعودی است', 'Market is up today'],
    'trendDown': ['بازار امروز نزولی است', 'Market is down today'],
    'maxGain': ['بیشترین رشد: {v}٪', 'Top gainer: {v}%'],
    'maxLoss': ['بیشترین افت: {v}٪', 'Top loser: {v}%'],
    'all': ['همه', 'All'],
    'currency': ['ارزها', 'Currencies'],
    'crypto': ['کریپتو', 'Crypto'],
    'gold': ['طلا', 'Gold'],
    'dollar': ['دلار', 'Dollar'],
    'bitcoin': ['بیت‌کوین', 'Bitcoin'],
    'allMarkets': ['همه بازارها', 'All markets'],
    'toman': ['تومان', 'Toman'],
    'darkMode': ['حالت تاریک', 'Dark mode'],
    'language': ['زبان برنامه', 'App language'],
    'notifications': ['اعلان‌ها', 'Notifications'],
    'support': ['پشتیبانی', 'Support'],
    'privacy': ['حریم خصوصی و امنیت', 'Privacy & Security'],
    'about': ['درباره ما', 'About'],
    'currentPrice': ['قیمت فعلی', 'Current Price'],
    'dailyChange': ['تغییرات روزانه', 'Daily Change'],
    'chartLow': ['کمترین (نمودار)', 'Chart low'],
    'chartHigh': ['بیشترین (نمودار)', 'Chart high'],
    'noChart': ['نموداری برای این مورد موجود نیست', 'No chart data available'],
    'addToWatch': ['افزودن به علاقه‌مندی‌ها', 'Add to Favorites'],
    'removeFromWatch': ['حذف از علاقه‌مندی‌ها', 'Remove from Favorites'],
    'noFavs': ['هنوز چیزی اضافه نکردی', 'Nothing added yet'],
    'noResults': ['موردی یافت نشد', 'No results found'],
    'loading': ['در حال دریافت اطلاعات...', 'Loading data...'],
    'retry': ['تلاش دوباره', 'Retry'],
    'ok': ['باشه', 'OK'],
    'partialWarn': ['بخشی از داده‌ها به‌روزرسانی نشد', 'Some data could not be updated'],
    'connError': [
      'اتصال به سرور برقرار نشد. لطفاً اینترنت خود را بررسی کنید.',
      'Connection failed. Please check your internet.'
    ],
    'aboutText': [
      'پینگ مارکت یک پلتفرم برای مشاهده قیمت لحظه‌ای ارزها، طلا و ارزهای دیجیتال است.\n\nنسخه ۱.۰.۰',
      'Ping Market is a platform to view live prices of currencies, gold, and crypto.\n\nVersion 1.0.0'
    ],
    'supportText': [
      'برای ارتباط با پشتیبانی به وب‌سایت ما مراجعه کنید:\n\nmrpingshop.ir',
      'Contact support via our website:\n\nmrpingshop.ir'
    ],
    'privacyText': [
      'اطلاعات شما در این اپلیکیشن محرمانه باقی می‌ماند و هیچ داده‌ای بدون اجازه شما ارسال نمی‌شود.',
      'Your data stays private. No data is sent without your permission.'
    ],
    'noNotif': ['اعلان جدیدی وجود ندارد.', 'No new notifications.'],
  };

  static String get(String key, String lang) {
    final v = _d[key];
    if (v == null) return key;
    return lang == 'en' ? v[1] : v[0];
  }
}

/// Converts digits and separators to Persian forms when [fa] is true.
String fd(String s, bool fa) {
  if (!fa) return s;
  const en = '0123456789';
  const faDigits = '۰۱۲۳۴۵۶۷۸۹';
  final b = StringBuffer();
  for (final ch in s.split('')) {
    final i = en.indexOf(ch);
    if (i >= 0) {
      b.write(faDigits[i]);
    } else if (ch == ',') {
      b.write('٬');
    } else if (ch == '.') {
      b.write('٫');
    } else {
      b.write(ch);
    }
  }
  return b.toString();
}

// ═══════════════════════════════════════════════════════
//  MODEL
// ═══════════════════════════════════════════════════════
class MarketAsset {
  final String code;
  final String symbol;
  final String labelFa;
  final String labelEn;
  final String icon;
  final String? imageUrl;
  final bool isCrypto;
  final double? value; // Rial for Iran assets
  final double? valueUsd; // USD for crypto
  final double? change; // 24h % (null when the API does not provide it)
  final List<double> sparkline;

  const MarketAsset({
    required this.code,
    required this.symbol,
    required this.labelFa,
    required this.labelEn,
    required this.icon,
    this.imageUrl,
    required this.isCrypto,
    this.value,
    this.valueUsd,
    this.change,
    required this.sparkline,
  });

  factory MarketAsset.fromJson(Map<String, dynamic> j) {
    final code = j['code']?.toString() ?? '';
    final isCrypto = code.startsWith('CG_');
    final symbol = j['symbol']?.toString() ??
        (isCrypto ? code.substring(3) : code.replaceAll('_RLS', ''));

    final changeRaw = j['change24h'];
    final double? change = changeRaw is num ? changeRaw.toDouble() : double.tryParse('$changeRaw');

    final spark = <double>[];
    final sp = j['sparkline'];
    if (sp is List && sp.length > 1) {
      final step = max(1, sp.length ~/ 30);
      for (int i = 0; i < sp.length; i += step) {
        final v = sp[i];
        if (v is num) spark.add(v.toDouble());
      }
    }

    double? num0(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v');

    return MarketAsset(
      code: code,
      symbol: symbol,
      labelFa: j['labelFa']?.toString() ?? symbol,
      labelEn: j['labelEn']?.toString() ?? symbol,
      icon: j['icon']?.toString() ?? '🪙',
      imageUrl: j['image']?.toString(),
      isCrypto: isCrypto,
      value: num0(j['value']),
      valueUsd: num0(j['valueUsd']),
      change: change,
      sparkline: spark,
    );
  }

  bool get isGold {
    if (isCrypto) return false;
    final c = code.toUpperCase();
    return c.contains('GOLD') ||
        c.contains('SEKKE') ||
        c.contains('COIN') ||
        labelFa.contains('طلا') ||
        labelFa.contains('سکه');
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

  bool get isUp => (change ?? 0) >= 0;
  String get changeText =>
      change == null ? '—' : '${change! >= 0 ? '+' : ''}${change!.toStringAsFixed(2)}%';
  Color changeColor(Pal p) => change == null ? p.textSecondary : (isUp ? p.green : p.red);
  String labelFor(String lang) => lang == 'en' ? labelEn : labelFa;

  static String _fmt(double n, int decimals) {
    final s = n.toStringAsFixed(decimals);
    final parts = s.split('.');
    final intPart =
        parts[0].replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
    return parts.length > 1 ? '$intPart.${parts[1]}' : intPart;
  }
}

// ═══════════════════════════════════════════════════════
//  API
// ═══════════════════════════════════════════════════════
class Api {
  static Future<List<MarketAsset>> assets() => _fetch(kAssetsUrls);
  static Future<List<MarketAsset>> crypto() => _fetch(kCryptoUrls);

  /// Tries each URL in order and returns the first successful result.
  static Future<List<MarketAsset>> _fetch(List<String> urls) async {
    Object? last;
    for (final url in urls) {
      try {
        final r = await http
            .get(Uri.parse(url), headers: {'Accept': 'application/json'})
            .timeout(const Duration(seconds: 15));
        if (r.statusCode != 200) {
          last = 'HTTP ${r.statusCode}';
          continue;
        }
        // utf8.decode keeps Persian labels intact regardless of the server charset header.
        final decoded = jsonDecode(utf8.decode(r.bodyBytes));
        final list = decoded is List
            ? decoded
            : (decoded is Map ? (decoded['assets'] ?? decoded['data']) : null);
        if (list is! List) {
          last = 'Bad response format';
          continue;
        }
        return list
            .whereType<Map>()
            .map((e) => MarketAsset.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } catch (e) {
        last = e;
      }
    }
    throw last ?? Exception('Request failed');
  }
}

// ═══════════════════════════════════════════════════════
//  STATE  (single ChangeNotifier; every screen listens to it)
// ═══════════════════════════════════════════════════════
enum PriceFilter { all, currency, gold, crypto }

class AppState extends ChangeNotifier {
  List<MarketAsset> iran = [];
  List<MarketAsset> crypto = [];
  bool loading = true;
  bool failed = false; // nothing could be loaded
  bool partial = false; // some sources failed but we have data
  Set<String> favorites = {};
  String lang = 'fa';
  bool dark = true;
  int tab = 0;
  PriceFilter filter = PriceFilter.all;
  String query = '';
  final List<String> notifications = []; // empty -> no red dot

  Future<void>? _inflight;

  bool get isFa => lang == 'fa';
  TextDirection get dir => isFa ? TextDirection.rtl : TextDirection.ltr;
  String t(String key) => S.get(key, lang);

  List<MarketAsset> get all => [...iran, ...crypto];
  List<MarketAsset> get favList => all.where((a) => favorites.contains(a.code)).toList();

  List<MarketAsset> get filtered {
    Iterable<MarketAsset> list;
    switch (filter) {
      case PriceFilter.all:
        list = all;
        break;
      case PriceFilter.currency:
        list = iran.where((a) => !a.isGold);
        break;
      case PriceFilter.gold:
        list = iran.where((a) => a.isGold);
        break;
      case PriceFilter.crypto:
        list = crypto;
        break;
    }
    final q = query.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((a) =>
          a.labelFa.toLowerCase().contains(q) ||
          a.labelEn.toLowerCase().contains(q) ||
          a.symbol.toLowerCase().contains(q) ||
          a.code.toLowerCase().contains(q));
    }
    return list.toList();
  }

  Future<void> init() async {
    try {
      final p = await SharedPreferences.getInstance();
      favorites = (p.getStringList('favs') ?? []).toSet();
      lang = p.getString('lang') ?? 'fa';
      dark = p.getBool('dark') ?? true;
    } catch (_) {}
    notifyListeners();
    await refresh();
  }

  Future<void> refresh() {
    // Prevents overlapping requests (e.g. double pull-to-refresh).
    return _inflight ??= _doRefresh().whenComplete(() => _inflight = null);
  }

  Future<void> _doRefresh() async {
    if (all.isEmpty) loading = true;
    failed = false;
    notifyListeners();

    Future<List<MarketAsset>?> safe(Future<List<MarketAsset>> Function() f) async {
      try {
        return await f();
      } catch (_) {
        return null;
      }
    }

    final res = await Future.wait([safe(Api.assets), safe(Api.crypto)]);
    if (res[0] != null) iran = res[0]!;
    if (res[1] != null) crypto = res[1]!;

    final fails = res.where((e) => e == null).length;
    failed = fails > 0 && all.isEmpty;
    partial = fails > 0 && all.isNotEmpty;
    loading = false;
    notifyListeners();
  }

  // ─ navigation / filters
  void setTab(int i) {
    tab = i;
    notifyListeners();
  }

  void setFilter(PriceFilter f) {
    filter = f;
    notifyListeners();
  }

  void setQuery(String q) {
    query = q;
    notifyListeners();
  }

  /// Used by the home shortcuts.
  void openPrices(PriceFilter f, {String q = ''}) {
    filter = f;
    query = q;
    tab = 1;
    notifyListeners();
  }

  // ─ preferences
  Future<void> toggleFav(String code) async {
    favorites.contains(code) ? favorites.remove(code) : favorites.add(code);
    notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setStringList('favs', favorites.toList());
    } catch (_) {}
  }

  Future<void> setLang(String v) async {
    lang = v;
    notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString('lang', v);
    } catch (_) {}
  }

  Future<void> setDark(bool v) async {
    dark = v;
    notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool('dark', v);
    } catch (_) {}
  }
}

final appState = AppState();

// ═══════════════════════════════════════════════════════
//  APP
// ═══════════════════════════════════════════════════════
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
  @override
  void initState() {
    super.initState();
    appState.init();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (_, __) {
        final p = pal;
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Ping Market',
          theme: buildTheme(p),
          // RTL / LTR is applied here, above the Navigator, so every route follows it.
          builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness:
                  p.brightness == Brightness.dark ? Brightness.light : Brightness.dark,
              systemNavigationBarColor: Colors.transparent,
            ),
            child: Directionality(textDirection: appState.dir, child: child!),
          ),
          home: const AppShell(),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════
//  SHELL + FLOATING NAV
// ═══════════════════════════════════════════════════════
class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        return Scaffold(
          extendBody: true,
          body: IndexedStack(
            index: appState.tab,
            children: const [HomeTab(), PricesTab(), FavoritesTab(), SettingsTab()],
          ),
          bottomNavigationBar: const _FloatingNav(),
        );
      },
    );
  }
}

class _FloatingNav extends StatelessWidget {
  const _FloatingNav();

  @override
  Widget build(BuildContext context) {
    final p = pal;
    final t = appState.t;
    final items = [
      (Icons.home_outlined, Icons.home_rounded, t('home')),
      (Icons.show_chart_outlined, Icons.show_chart_rounded, t('prices')),
      (Icons.favorite_border_rounded, Icons.favorite_rounded, t('favs')),
      (Icons.settings_outlined, Icons.settings_rounded, t('settings')),
    ];

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        height: 72,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: p.cardBorder, width: 1.5),
          boxShadow: [BoxShadow(color: p.purple.op(0.15), blurRadius: 30, spreadRadius: 2)],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              color: p.surface.op(0.85),
              child: Row(
                children: List.generate(items.length, (i) {
                  final sel = appState.tab == i;
                  final (icon, active, label) = items[i];
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => appState.setTab(i),
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(sel ? active : icon,
                              color: sel ? p.purple : p.textSecondary, size: 26),
                          const SizedBox(height: 4),
                          Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: sel ? p.purple : p.textSecondary,
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
    final p = pal;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: p.cardFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.cardBorder),
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
      child: data.length < 2 ? null : CustomPaint(painter: _SparkPainter(data, color)),
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
    final range = (maxV - minV) == 0 ? 1.0 : (maxV - minV);

    final path = Path();
    final fill = Path()..moveTo(0, size.height);
    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height - ((data[i] - minV) / range) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      fill.lineTo(x, y);
    }
    fill
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          colors: [color.op(0.3), color.op(0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) => old.data != data || old.color != color;
}

class AssetIcon extends StatelessWidget {
  final MarketAsset asset;
  final double size;
  const AssetIcon({super.key, required this.asset, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final p = pal;
    Color bg = p.surfaceLight;
    final Widget fallback = Text(asset.icon, style: TextStyle(fontSize: size * 0.5));
    Widget icon = fallback;

    Widget glyph(String s, Color c, double fs) =>
        Text(s, style: TextStyle(color: c, fontSize: fs, fontWeight: FontWeight.bold));

    if (asset.code == 'USD_RLS') {
      bg = p.green.op(0.18);
      icon = glyph('\$', p.green, 24);
    } else if (asset.code == 'GOLD_18_RLS') {
      bg = p.gold.op(0.18);
      icon = Icon(Icons.diamond, color: p.gold, size: 24);
    } else if (asset.symbol == 'BTC') {
      bg = Colors.orange.op(0.18);
      icon = glyph('₿', Colors.orange, 26);
    } else if (asset.symbol == 'ETH') {
      bg = Colors.blueAccent.op(0.18);
      icon = glyph('Ξ', Colors.blueAccent, 26);
    } else if (asset.symbol == 'USDT') {
      bg = const Color(0xFF26A17B).op(0.18);
      icon = glyph('₮', const Color(0xFF26A17B), 24);
    } else if (asset.imageUrl != null && asset.imageUrl!.isNotEmpty) {
      bg = Colors.transparent;
      icon = Image.network(
        asset.imageUrl!,
        width: size * 0.6,
        height: size * 0.6,
        errorBuilder: (_, __, ___) => fallback,
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      alignment: Alignment.center,
      child: icon,
    );
  }
}

/// One row used in Home, Prices and Favorites.
class AssetTile extends StatelessWidget {
  final MarketAsset asset;
  final bool removable;
  const AssetTile({super.key, required this.asset, this.removable = false});

  @override
  Widget build(BuildContext context) {
    final p = pal;
    final fa = appState.isFa;
    final color = asset.changeColor(p);
    final priceLine = fd(asset.displayPrice, fa) +
        (asset.isCrypto || asset.value == null ? '' : ' ${appState.t('toman')}');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => DetailScreen(asset: asset))),
        child: GlassCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              AssetIcon(asset: asset, size: 46),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(asset.labelFor(appState.lang),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: p.text, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(priceLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: p.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(fd(asset.changeText, fa),
                        style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 4),
                  Sparkline(data: asset.sparkline, color: color),
                ],
              ),
              const SizedBox(width: 8),
              if (removable)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => appState.toggleFav(asset.code),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(Icons.delete_outline_rounded, color: p.red),
                  ),
                )
              else
                Icon(Icons.chevron_right_rounded, color: p.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});
  @override
  Widget build(BuildContext context) {
    final p = pal;
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: p.purple),
          const SizedBox(height: 16),
          Text(appState.t('loading'), style: TextStyle(color: p.textSecondary)),
        ],
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key});
  @override
  Widget build(BuildContext context) {
    final p = pal;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off_rounded, color: p.red, size: 48),
          const SizedBox(height: 16),
          Text(appState.t('connError'),
              style: TextStyle(color: p.textSecondary), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: appState.refresh,
            style: ElevatedButton.styleFrom(
                backgroundColor: p.purple, foregroundColor: Colors.white),
            child: Text(appState.t('retry')),
          ),
        ],
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  final String text;
  const EmptyView(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(40),
        child: Center(child: Text(text, style: TextStyle(color: pal.textSecondary))),
      );
}

class PartialWarning extends StatelessWidget {
  const PartialWarning({super.key});
  @override
  Widget build(BuildContext context) {
    final p = pal;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: p.gold, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(appState.t('partialWarn'),
                style: TextStyle(color: p.textSecondary, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  HOME TAB
// ═══════════════════════════════════════════════════════
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  void _showNotifications(BuildContext context) {
    final p = pal;
    final t = appState.t;
    showModalBottomSheet(
      context: context,
      backgroundColor: p.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.notifications_none_rounded, color: p.purple, size: 40),
              const SizedBox(height: 16),
              Text(t('notifications'),
                  style: TextStyle(color: p.text, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (appState.notifications.isEmpty)
                Text(t('noNotif'), style: TextStyle(color: p.textSecondary))
              else
                ...appState.notifications
                    .map((n) => Text(n, style: TextStyle(color: p.textSecondary))),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final p = pal;
        final t = appState.t;
        final fa = appState.isFa;

        Widget content;
        if (appState.loading) {
          content = const Center(child: LoadingView());
        } else if (appState.failed) {
          content = const Center(child: ErrorView());
        } else {
          content = Column(children: [
            if (appState.partial) const PartialWarning(),
            ...appState.all.take(4).map((a) => AssetTile(asset: a)),
          ]);
        }

        return SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: p.purple,
            backgroundColor: p.surface,
            onRefresh: appState.refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 110),
              children: [
                // Top bar
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _showNotifications(context),
                      child: Stack(
                        children: [
                          GlassCard(
                            padding: const EdgeInsets.all(10),
                            child: Icon(Icons.notifications_none_rounded, color: p.text),
                          ),
                          if (appState.notifications.isNotEmpty)
                            Positioned(
                              right: 10,
                              top: 10,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(color: p.red, shape: BoxShape.circle),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                    text: 'Ping ',
                                    style: TextStyle(
                                        color: p.text, fontSize: 20, fontWeight: FontWeight.w800)),
                                TextSpan(
                                    text: 'Market',
                                    style: TextStyle(
                                        color: p.purple,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800)),
                              ],
                            ),
                          ),
                          Text(t('tagline'),
                              style: TextStyle(color: p.textSecondary, fontSize: 10)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => appState.setLang(fa ? 'en' : 'fa'),
                      child: GlassCard(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Text(fa ? 'EN' : 'فا',
                            style: TextStyle(color: p.text, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                _banner(p, t, fa),

                // Search shortcut
                GestureDetector(
                  onTap: () => appState.openPrices(PriceFilter.all),
                  child: GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Icon(Icons.search_rounded, color: p.textSecondary),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Text(t('searchHint'),
                                style: TextStyle(color: p.textTertiary))),
                        Icon(Icons.tune_rounded, color: p.textSecondary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Quick actions
                Row(
                  children: [
                    _quick(Icons.diamond_rounded, t('gold'), p.gold,
                        () => appState.openPrices(PriceFilter.gold)),
                    _quick(Icons.attach_money_rounded, t('dollar'), p.green,
                        () => appState.openPrices(PriceFilter.currency, q: 'USD')),
                    _quick(Icons.currency_bitcoin_rounded, t('bitcoin'), Colors.orange,
                        () => appState.openPrices(PriceFilter.crypto)),
                    _quick(Icons.grid_view_rounded, t('allMarkets'), Colors.blueAccent,
                        () => appState.openPrices(PriceFilter.all)),
                  ],
                ),
                const SizedBox(height: 24),

                content,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _banner(Pal p, String Function(String) t, bool fa) {
    final withChange = appState.all.where((a) => a.change != null).toList();
    if (withChange.isEmpty) return const SizedBox.shrink();

    final avg = withChange.fold<double>(0, (s, a) => s + a.change!) / withChange.length;
    final up = avg >= 0;
    final best = up
        ? withChange.map((a) => a.change!).reduce(max)
        : withChange.map((a) => a.change!).reduce(min);
    final detail =
        t(up ? 'maxGain' : 'maxLoss').replaceAll('{v}', fd(best.abs().toStringAsFixed(2), fa));
    final accent = up ? p.green : p.red;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [p.purple.op(0.6), p.bg],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: p.purple.op(0.3)),
        ),
        child: Stack(
          children: [
            PositionedDirectional(
              end: -20,
              bottom: 0,
              top: 20,
              width: 200,
              child: Opacity(
                opacity: 0.35,
                child: CustomPaint(painter: _BannerChartPainter(p.cyan)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(up ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                          color: p.cyan),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(t(up ? 'trendUp' : 'trendDown'),
                            style: TextStyle(color: p.text, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(up ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
                          color: accent),
                      Text(detail, style: TextStyle(color: accent, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quick(IconData icon, String label, Color color, VoidCallback onTap) {
    final p = pal;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: GlassCard(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
            child: Column(
              children: [
                Icon(icon, color: color, size: 30),
                const SizedBox(height: 8),
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: p.text, fontSize: 11)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BannerChartPainter extends CustomPainter {
  final Color color;
  _BannerChartPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final w = size.width / 8;
    for (int i = 0; i < 8; i++) {
      final h = (i * 10.0) + 20;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(i * w, size.height - h, w * 0.6, h), const Radius.circular(4)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BannerChartPainter old) => old.color != color;
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
  final TextEditingController _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    appState.addListener(_syncQuery);
  }

  @override
  void dispose() {
    appState.removeListener(_syncQuery);
    _ctrl.dispose();
    super.dispose();
  }

  // Keeps the text field in sync when the query is set from outside (home shortcuts).
  void _syncQuery() {
    if (_ctrl.text != appState.query) {
      _ctrl.value = TextEditingValue(
        text: appState.query,
        selection: TextSelection.collapsed(offset: appState.query.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final p = pal;
        final t = appState.t;
        final list = appState.filtered;

        Widget body;
        if (appState.loading) {
          body = const Center(child: LoadingView());
        } else if (appState.failed) {
          body = const Center(child: ErrorView());
        } else if (list.isEmpty) {
          body = EmptyView(t('noResults'));
        } else {
          body = Column(children: [
            if (appState.partial) const PartialWarning(),
            ...list.map((a) => AssetTile(asset: a)),
          ]);
        }

        return SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Row(
                  children: [
                    Icon(Icons.bar_chart_rounded, color: p.cyan, size: 28),
                    const SizedBox(width: 10),
                    Text(t('prices'),
                        style: TextStyle(
                            color: p.text, fontSize: 22, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: TextField(
                    controller: _ctrl,
                    onChanged: appState.setQuery,
                    style: TextStyle(color: p.text),
                    cursorColor: p.purple,
                    decoration: InputDecoration(
                      hintText: t('searchHint'),
                      hintStyle: TextStyle(color: p.textTertiary),
                      border: InputBorder.none,
                      icon: Icon(Icons.search_rounded, color: p.textSecondary),
                      suffixIcon: appState.query.isEmpty
                          ? null
                          : IconButton(
                              icon: Icon(Icons.close_rounded, color: p.textSecondary),
                              onPressed: () => appState.setQuery(''),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _pill(p, t('all'), PriceFilter.all),
                    _pill(p, t('currency'), PriceFilter.currency),
                    _pill(p, t('gold'), PriceFilter.gold),
                    _pill(p, t('crypto'), PriceFilter.crypto),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: RefreshIndicator(
                  color: p.purple,
                  backgroundColor: p.surface,
                  onRefresh: appState.refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                    children: [body],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _pill(Pal p, String label, PriceFilter f) {
    final sel = appState.filter == f;
    return GestureDetector(
      onTap: () => appState.setFilter(f),
      child: Container(
        margin: const EdgeInsetsDirectional.only(end: 10),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        decoration: BoxDecoration(
          gradient: sel ? LinearGradient(colors: [p.purple, p.cyan]) : null,
          color: sel ? null : p.surfaceLight,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                color: sel ? Colors.white : p.textSecondary, fontWeight: FontWeight.bold)),
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
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final p = pal;
        final t = appState.t;
        final favs = appState.favList;

        return SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Row(
                  children: [
                    Icon(Icons.star_rounded, color: p.cyan, size: 28),
                    const SizedBox(width: 10),
                    Text(t('favs'),
                        style: TextStyle(
                            color: p.text, fontSize: 22, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: p.purple,
                  backgroundColor: p.surface,
                  onRefresh: appState.refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 110),
                    children: favs.isEmpty
                        ? [EmptyView(t('noFavs'))]
                        : favs.map((a) => AssetTile(asset: a, removable: true)).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final p = pal;
        final t = appState.t;
        return SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
            children: [
              Row(
                children: [
                  Icon(Icons.settings_rounded, color: p.cyan, size: 28),
                  const SizedBox(width: 10),
                  Text(t('settings'),
                      style:
                          TextStyle(color: p.text, fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 30),
              _item(
                p,
                appState.dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                t('darkMode'),
                trailing: Switch(
                  value: appState.dark,
                  activeColor: p.purple,
                  onChanged: appState.setDark,
                ),
                onTap: () => appState.setDark(!appState.dark),
              ),
              _item(
                p,
                Icons.language_rounded,
                t('language'),
                trailing: Text(appState.isFa ? 'فارسی' : 'English',
                    style: TextStyle(color: p.textSecondary)),
                onTap: () => appState.setLang(appState.isFa ? 'en' : 'fa'),
              ),
              _item(p, Icons.notifications_none_rounded, t('notifications'),
                  onTap: () => _showMsg(context, t('notifications'), t('noNotif'))),
              _item(p, Icons.headset_mic_rounded, t('support'),
                  onTap: () => _showMsg(context, t('support'), t('supportText'))),
              _item(p, Icons.shield_outlined, t('privacy'),
                  onTap: () => _showMsg(context, t('privacy'), t('privacyText'))),
              _item(p, Icons.info_outline_rounded, t('about'),
                  onTap: () => _showMsg(context, t('about'), t('aboutText'))),
            ],
          ),
        );
      },
    );
  }

  void _showMsg(BuildContext context, String title, String text) {
    final p = pal;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.surface,
        title: Text(title, style: TextStyle(color: p.text)),
        content: Text(text, style: TextStyle(color: p.textSecondary, height: 1.6)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(appState.t('ok'),
                style: TextStyle(color: p.purple, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _item(Pal p, IconData icon, String title,
      {Widget? trailing, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GlassCard(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: trailing is Switch ? 6 : 16),
          child: Row(
            children: [
              Icon(icon, color: p.textSecondary),
              const SizedBox(width: 16),
              Expanded(
                  child: Text(title,
                      style: TextStyle(color: p.text, fontWeight: FontWeight.w600))),
              trailing ?? Icon(Icons.chevron_right_rounded, color: p.textTertiary),
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
class DetailScreen extends StatelessWidget {
  final MarketAsset asset;
  const DetailScreen({super.key, required this.asset});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final p = pal;
        final t = appState.t;
        final fa = appState.isFa;
        final a = asset;
        final color = a.changeColor(p);
        final isFav = appState.favorites.contains(a.code);
        final hasChart = a.sparkline.length >= 2;
        final low = hasChart ? a.sparkline.reduce(min) : null;
        final high = hasChart ? a.sparkline.reduce(max) : null;

        String fmtChart(double v) =>
            fd(v >= 100 ? v.toStringAsFixed(0) : v.toStringAsFixed(2), fa);

        return Scaffold(
          backgroundColor: p.bg,
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: p.text),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(a.labelFor(appState.lang),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: p.text)),
            actions: [
              IconButton(
                onPressed: () => appState.toggleFav(a.code),
                icon: Icon(isFav ? Icons.star_rounded : Icons.star_border_rounded, color: p.gold),
              ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
              children: [
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      AssetIcon(asset: a, size: 60),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.labelFor(appState.lang),
                                style: TextStyle(color: p.textSecondary, fontSize: 14)),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Flexible(
                                  child: Text(fd(a.displayPrice, fa),
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          color: p.text,
                                          fontSize: 28,
                                          fontWeight: FontWeight.w900)),
                                ),
                                const SizedBox(width: 6),
                                Text(a.isCrypto ? 'USD' : t('toman'),
                                    style: TextStyle(color: p.textSecondary, fontSize: 14)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Icon(a.isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                        color: color, size: 20),
                    const SizedBox(width: 6),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(fd(a.changeText, fa),
                          style: TextStyle(
                              color: color, fontSize: 16, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: hasChart
                      ? SizedBox(
                          height: 200,
                          child: CustomPaint(
                              painter: _ChartPainter(a.sparkline, color),
                              child: const SizedBox.expand()),
                        )
                      : SizedBox(
                          height: 120,
                          child: Center(
                              child: Text(t('noChart'),
                                  style: TextStyle(color: p.textSecondary)))),
                ),
                const SizedBox(height: 24),
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _stat(p, t('currentPrice'), fd(a.displayPrice, fa), p.text),
                      Divider(height: 24, color: p.cardBorder),
                      _stat(p, t('dailyChange'), fd(a.changeText, fa), color),
                      if (hasChart) ...[
                        Divider(height: 24, color: p.cardBorder),
                        _stat(p, t('chartLow'), fmtChart(low!), p.text),
                        Divider(height: 24, color: p.cardBorder),
                        _stat(p, t('chartHigh'), fmtChart(high!), p.text),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                GestureDetector(
                  onTap: () => appState.toggleFav(a.code),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: isFav ? null : LinearGradient(colors: [p.purple, p.cyan]),
                      color: isFav ? p.surfaceLight : null,
                      borderRadius: BorderRadius.circular(16),
                      border: isFav ? Border.all(color: p.purple) : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(isFav ? Icons.star_rounded : Icons.star_border_rounded,
                            color: isFav ? p.purple : Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          isFav ? t('removeFromWatch') : t('addToWatch'),
                          style: TextStyle(
                              color: isFav ? p.purple : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15),
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

  Widget _stat(Pal p, String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: p.textSecondary, fontSize: 14)),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Text(value,
              style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
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
    final range = (maxV - minV) == 0 ? 1.0 : (maxV - minV);

    final line = Path();
    final fill = Path()..moveTo(0, size.height);
    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height - ((data[i] - minV) / range) * (size.height - 10) - 5;
      if (i == 0) {
        line.moveTo(x, y);
      } else {
        line.lineTo(x, y);
      }
      fill.lineTo(x, y);
    }
    fill
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          colors: [color.op(0.3), color.op(0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) => old.data != data || old.color != color;
}
