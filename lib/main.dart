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

// ═══════════════════════════════════════════════════════
//  COLORS - Deep navy blue theme
// ═══════════════════════════════════════════════════════
class C {
  static const gold = Color(0xFFD4AF37);
  static const goldLight = Color(0xFFF5D061);
  static const goldDark = Color(0xFF9C7A1F);

  // Dark navy palette
  static const bg = Color(0xFF0B1020);
  static const bgSoft = Color(0xFF10162A);
  static const card = Color(0xFF181E33);
  static const cardHigh = Color(0xFF232A45);
  static const cardHighest = Color(0xFF2D3455);
  static const line = Color(0xFF2C3454);

  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xB3FFFFFF);
  static const textTertiary = Color(0x66FFFFFF);

  static const green = Color(0xFF22C55E);
  static const red = Color(0xFFEF4444);

  // Light theme
  static const lightBg = Color(0xFFF4F6FA);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightLine = Color(0xFFE5E8EF);
}

// ═══════════════════════════════════════════════════════
//  LOCALIZATION
// ═══════════════════════════════════════════════════════
class S {
  static const Map<String, List<String>> _d = {
    'home': ['خانه', 'Home'],
    'prices': ['قیمت‌ها', 'Prices'],
    'watchlist': ['واچ لیست', 'Watchlist'],
    'settings': ['تنظیمات', 'Settings'],
    'hello': ['سلام', 'Hello'],
    'welcome': ['به پینگ مارکت خوش آمدید', 'Welcome to Ping Market'],
    'searchHint': ['جستجوی دارایی...', 'Search assets...'],
    'importantPrices': ['قیمت‌های مهم', 'Top Prices'],
    'seeAll': ['مشاهده همه', 'See All'],
    'popularCrypto': ['کریپتوی پرطرفدار', 'Popular Crypto'],
    'all': ['همه', 'All'],
    'iran': ['ایران', 'Iran'],
    'crypto': ['Crypto', 'Crypto'],
    'toman': ['تومان', 'Toman'],
    'noResults': ['موردی یافت نشد', 'No results'],
    'emptyWatch': ['هنوز دارایی اضافه نکردی', 'No assets added yet'],
    'emptyWatchHint': ['از دکمه + بالا یا صفحه قیمت‌ها اضافه کن',
                       'Add from + button above or the prices page'],
    'manageWatch': ['مدیریت واچ لیست', 'Manage Watchlist'],
    'chooseAsset': ['انتخاب دارایی', 'Choose Asset'],
    'darkMode': ['حالت تاریک', 'Dark mode'],
    'language': ['زبان', 'Language'],
    'about': ['درباره ما', 'About'],
    'support': ['پشتیبانی', 'Support'],
    'close': ['بستن', 'Close'],
    'retry': ['تلاش دوباره', 'Retry'],
    'errorLoading': ['خطا در دریافت اطلاعات', 'Failed to load data'],
    'notifications': ['اعلان‌ها', 'Notifications'],
    'noNotifications': ['اعلان جدیدی وجود ندارد', 'No new notifications'],
    'currentPrice': ['قیمت فعلی', 'Current Price'],
    'high24': ['بالاترین (۲۴س)', 'High (24h)'],
    'low24': ['پایین‌ترین (۲۴س)', 'Low (24h)'],
    'dailyChange': ['تغییرات روزانه', 'Daily Change'],
    'addToWatch': ['افزودن به واچ لیست', 'Add to Watchlist'],
    'removeFromWatch': ['حذف از واچ لیست', 'Remove from Watchlist'],
    'gold': ['طلا', 'Gold'],
    'coin': ['سکه', 'Coin'],
    'dollar': ['دلار', 'Dollar'],
    'currency': ['ارز', 'Currency'],
    'loading': ['در حال بارگذاری...', 'Loading...'],
    'favs': ['علاقه‌مندی', 'Favorites'],
    'aboutTextFa': ['Ping Market\nنسخه ۱.۰.۰\n\nقیمت لحظه‌ای ارز، طلا و ارزهای دیجیتال\n\nmrpingshop.ir', 'Ping Market\nVersion 1.0.0\n\nLive prices of currency, gold, and crypto\n\nmrpingshop.ir'],
  };

  static String get(String key, String lang) {
    final v = _d[key];
    if (v == null) return key;
    return lang == 'en' ? v[1] : v[0];
  }
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
  final double? value;
  final double? valueUsd;
  final double change;
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
    final symbol = j['symbol']?.toString() ??
        (isCrypto ? code.substring(3) : code.replaceAll('_RLS', ''));

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

  double? get valueToman => value == null ? null : value! / 10;

  String get displayPrice {
    if (isCrypto) {
      final v = valueUsd;
      if (v == null) return '—';
      if (v >= 1000) return '\$${_fmt(v, 0)}';
      if (v >= 1) return '\$${v.toStringAsFixed(2)}';
      if (v >= 0.01) return '\$${v.toStringAsFixed(4)}';
      return '\$${v.toStringAsFixed(6)}';
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

  // Flag image URL (for currency codes)
  String? get flagUrl {
    switch (code) {
      case 'USD_RLS': return 'https://flagcdn.com/w160/us.png';
      case 'EUR_RLS': return 'https://flagcdn.com/w160/eu.png';
      case 'GBP_RLS': return 'https://flagcdn.com/w160/gb.png';
      case 'AED_RLS': return 'https://flagcdn.com/w160/ae.png';
      case 'JPY_RLS': return 'https://flagcdn.com/w160/jp.png';
      case 'CNY_RLS': return 'https://flagcdn.com/w160/cn.png';
      case 'TRY_RLS': return 'https://flagcdn.com/w160/tr.png';
      case 'RUB_RLS': return 'https://flagcdn.com/w160/ru.png';
      case 'CAD_RLS': return 'https://flagcdn.com/w160/ca.png';
      case 'AUD_RLS': return 'https://flagcdn.com/w160/au.png';
      case 'CHF_RLS': return 'https://flagcdn.com/w160/ch.png';
      case 'IQD_RLS': return 'https://flagcdn.com/w160/iq.png';
      case 'SAR_RLS': return 'https://flagcdn.com/w160/sa.png';
      default: return null;
    }
  }

  String get displayLabel => labelFa;
  String displayLabelFor(String lang) => lang == 'en' ? labelEn : labelFa;
}

// ═══════════════════════════════════════════════════════
//  GLOBAL STATE
// ═══════════════════════════════════════════════════════
final ValueNotifier<int> shellTab = ValueNotifier(0);
final ValueNotifier<int> pricesCategory = ValueNotifier(0);
final ValueNotifier<String> pricesSearch = ValueNotifier('');

class AppState extends ChangeNotifier {
  List<MarketAsset> iran = [];
  List<MarketAsset> crypto = [];
  bool loading = true;
  String? error;
  DateTime? lastUpdate;
  Set<String> favorites = {};
  String lang = 'fa';
  bool darkMode = true;

  List<MarketAsset> get all => [...iran, ...crypto];
  List<MarketAsset> get favList =>
      all.where((a) => favorites.contains(a.code)).toList();

  MarketAsset? byCode(String code) {
    for (final a in all) {
      if (a.code == code) return a;
    }
    return null;
  }

  Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    favorites = (p.getStringList('favs') ?? []).toSet();
    lang = p.getString('lang') ?? 'fa';
    darkMode = p.getBool('dark') ?? true;
    notifyListeners();
    await refresh();
  }

  Future<void> refresh() async {
    loading = iran.isEmpty && crypto.isEmpty;
    error = null;
    notifyListeners();
    await Future.wait([_loadAssets(), _loadCrypto()]);
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
      iran = (data['assets'] as List? ?? [])
          .map((e) => MarketAsset.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      error ??= 'errorLoading';
    }
  }

  Future<void> _loadCrypto() async {
    try {
      final r = await http
          .get(Uri.parse(kCryptoUrl), headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 20));
      if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
      final data = jsonDecode(r.body) as Map<String, dynamic>;
      crypto = (data['assets'] as List? ?? [])
          .map((e) => MarketAsset.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {}
  }

  Future<void> toggleFav(String code) async {
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

  String t(String key) => S.get(key, lang);
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
          theme: _lightTheme(),
          darkTheme: _darkTheme(),
          locale: Locale(appState.lang),
          home: showSplash ? const SplashScreen() : const AppShell(),
        );
      },
    );
  }

  ThemeData _darkTheme() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: C.bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: C.gold,
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          foregroundColor: Colors.white,
        ),
        splashFactory: InkRipple.splashFactory,
        pageTransitionsTheme: const PageTransitionsTheme(builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        }),
      );

  ThemeData _lightTheme() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: C.lightBg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: C.gold,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          foregroundColor: Colors.black,
        ),
        splashFactory: InkRipple.splashFactory,
        pageTransitionsTheme: const PageTransitionsTheme(builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        }),
      );
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
    _scale = Tween(begin: 0.85, end: 1.0)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOutBack));
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
      backgroundColor: C.bg,
      body: Stack(
        children: [
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
                    colors: [C.gold.withOpacity(0.18), Colors.transparent],
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
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                            color: C.gold.withOpacity(0.5), width: 1.2),
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
                      'Real-time Prices · Global Markets',
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
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  APP SHELL
// ═══════════════════════════════════════════════════════
class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  @override
  void initState() {
    super.initState();
    shellTab.addListener(_onTabChange);
  }

  @override
  void dispose() {
    shellTab.removeListener(_onTabChange);
    super.dispose();
  }

  void _onTabChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: shellTab.value,
        children: const [
          HomeTab(),
          PricesTab(),
          WatchlistTab(),
          SettingsTab(),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        index: shellTab.value,
        onChanged: (i) => shellTab.value = i,
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  const _BottomNav({required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final t = appState.t;
    final items = [
      (Icons.home_outlined, Icons.home_rounded, t('home')),
      (Icons.show_chart_outlined, Icons.show_chart_rounded, t('prices')),
      (Icons.star_border_rounded, Icons.star_rounded, t('watchlist')),
      (Icons.settings_outlined, Icons.settings_rounded, t('settings')),
    ];

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
            children: List.generate(items.length, (i) {
              final sel = index == i;
              final (icon, active, label) = items[i];
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
  final bool fill;

  const Sparkline({
    super.key,
    required this.data,
    required this.color,
    this.width = 60,
    this.height = 30,
    this.fill = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(painter: _SparkPainter(data, color, fill)),
    );
  }
}

class _SparkPainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final bool fill;
  _SparkPainter(this.data, this.color, this.fill);

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

    if (fill) {
      final fillPath = Path.from(path);
      fillPath.lineTo(size.width, size.height);
      fillPath.lineTo(0, size.height);
      fillPath.close();
      canvas.drawPath(
        fillPath,
        Paint()
          ..shader = LinearGradient(
            colors: [color.withOpacity(0.28), color.withOpacity(0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
      );
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
  bool shouldRepaint(covariant _SparkPainter old) =>
      old.data != data || old.color != color;
}

// ─── Asset Icon (with proper flags & crypto images) ───
class AssetIcon extends StatelessWidget {
  final MarketAsset asset;
  final double size;

  const AssetIcon({super.key, required this.asset, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    Widget child;
    if (asset.isCrypto && asset.imageUrl != null && asset.imageUrl!.isNotEmpty) {
      child = Padding(
        padding: EdgeInsets.all(size * 0.15),
        child: Image.network(
          asset.imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) =>
              _emoji(asset.icon, size),
          loadingBuilder: (_, c, p) {
            if (p == null) return c;
            return Center(
              child: SizedBox(
                width: size * 0.4,
                height: size * 0.4,
                child: const CircularProgressIndicator(
                    strokeWidth: 1.5, color: C.gold),
              ),
            );
          },
        ),
      );
    } else if (asset.flagUrl != null) {
      child = ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.22),
        child: Image.network(
          asset.flagUrl!,
          width: size * 0.72,
          height: size * 0.72,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _emoji(asset.icon, size),
        ),
      );
    } else {
      child = _emoji(asset.icon, size);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: dark ? C.cardHigh : const Color(0xFFF1F3F7),
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(
          color: dark ? Colors.white.withOpacity(0.04) : Colors.black12,
          width: 0.5,
        ),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }

  Widget _emoji(String e, double sz) =>
      Text(e, style: TextStyle(fontSize: sz * 0.5));
}

// ═══════════════════════════════════════════════════════
//  PRICE TILE
// ═══════════════════════════════════════════════════════
class PriceTile extends StatelessWidget {
  final MarketAsset asset;
  final VoidCallback onTap;
  final bool dense;
  final bool showFavToggle;

  const PriceTile({
    super.key,
    required this.asset,
    required this.onTap,
    this.dense = false,
    this.showFavToggle = false,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final isUp = asset.change >= 0;
    final changeColor = isUp ? C.green : C.red;
    final label = asset.displayLabelFor(appState.lang);
    final unitText = asset.isCrypto ? 'USD' : appState.t('toman');

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
                AssetIcon(asset: asset, size: dense ? 40 : 44),
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
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color:
                                    dark ? C.textSecondary : Colors.black54,
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
                            unitText,
                            style: TextStyle(
                              fontSize: 11,
                              color: dark
                                  ? C.textTertiary
                                  : Colors.black38,
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
                const SizedBox(width: 6),
                if (showFavToggle)
                  GestureDetector(
                    onTap: () => appState.toggleFav(asset.code),
                    child: Icon(
                      appState.favorites.contains(asset.code)
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: appState.favorites.contains(asset.code)
                          ? C.gold
                          : (dark ? C.textTertiary : Colors.black26),
                      size: 20,
                    ),
                  )
                else
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

// ═══════════════════════════════════════════════════════
//  HOME TAB - fully redesigned
// ═══════════════════════════════════════════════════════
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  void _open(BuildContext context, MarketAsset a) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => DetailScreen(asset: a)));
  }

  void _goToPrices(int category) {
    pricesCategory.value = category;
    shellTab.value = 1;
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final s = appState;
        final t = s.t;

        // Featured: USD in toman
        final featured = s.byCode('USD_RLS');

        // Top prices list
        final hot = <MarketAsset>[];
        for (final c in ['GOLD_18_RLS', 'COIN_EMAMI_RLS', 'EUR_RLS', 'GBP_RLS']) {
          final a = s.byCode(c);
          if (a != null) hot.add(a);
        }

        // Top crypto
        final topCrypto = s.crypto.take(4).toList();

        return SafeArea(
          child: RefreshIndicator(
            color: C.gold,
            backgroundColor: dark ? C.card : Colors.white,
            onRefresh: s.refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              children: [
                // ═══ Header ═══
                Row(
                  children: [
                    const LogoMark(size: 38),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                        Text(
                          '${t('hello')} 👋',
                          style: TextStyle(
                            fontSize: 11,
                            color: dark ? C.textTertiary : Colors.black38,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    _iconBtn(
                      context,
                      Icons.notifications_none_rounded,
                      () => _showNotif(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ═══ Search bar ═══
                GestureDetector(
                  onTap: () {
                    pricesSearch.value = '';
                    shellTab.value = 1;
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: dark ? C.card : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: dark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.black12,
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: dark ? C.textTertiary : Colors.black38,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          t('searchHint'),
                          style: TextStyle(
                            fontSize: 13,
                            color: dark ? C.textTertiary : Colors.black38,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // ═══ Featured USD card ═══
                if (featured != null)
                  _FeaturedDollarCard(asset: featured)
                else if (s.loading)
                  Container(
                    height: 170,
                    decoration: BoxDecoration(
                      color: C.card,
                      borderRadius: BorderRadius.circular(22),
                    ),
                  )
                else
                  _errorCard(s, dark),
                const SizedBox(height: 18),

                // ═══ Quick categories ═══
                Row(
                  children: [
                    _catChip(context, '🪙', t('gold'), 1),
                    const SizedBox(width: 8),
                    _catChip(context, '💵', t('dollar'), 1),
                    const SizedBox(width: 8),
                    _catChip(context, '🪙', t('coin'), 1),
                    const SizedBox(width: 8),
                    _catChip(context, '₿', t('crypto'), 2),
                  ],
                ),
                const SizedBox(height: 24),

                // ═══ Important Prices section ═══
                _sectionHeader(
                  context,
                  t('importantPrices'),
                  () => _goToPrices(1),
                ),
                const SizedBox(height: 10),
                if (hot.isEmpty && s.loading)
                  ...List.generate(
                    3,
                    (_) => Container(
                      height: 78,
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: C.card,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  )
                else
                  ...hot.map((a) => PriceTile(
                        asset: a,
                        onTap: () => _open(context, a),
                      )),
                const SizedBox(height: 20),

                // ═══ Popular Crypto section ═══
                _sectionHeader(
                  context,
                  t('popularCrypto'),
                  () => _goToPrices(2),
                ),
                const SizedBox(height: 10),
                if (topCrypto.isEmpty && s.loading)
                  ...List.generate(
                    3,
                    (_) => Container(
                      height: 78,
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: C.card,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  )
                else if (topCrypto.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        t('loading'),
                        style: TextStyle(
                          color: dark ? C.textTertiary : Colors.black38,
                        ),
                      ),
                    ),
                  )
                else
                  ...topCrypto.map((a) => PriceTile(
                        asset: a,
                        onTap: () => _open(context, a),
                      )),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _iconBtn(BuildContext context, IconData icon, VoidCallback onTap) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: dark ? C.card : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: dark ? Colors.white70 : Colors.black54,
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _catChip(BuildContext context, String emoji, String label, int cat) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Material(
        color: dark ? C.card : Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _goToPrices(cat),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: dark ? C.textSecondary : Colors.black54,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title, VoidCallback onSeeAll) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
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
        TextButton(
          onPressed: onSeeAll,
          style: TextButton.styleFrom(
            foregroundColor: C.gold,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: const Size(0, 30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                appState.t('seeAll'),
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(width: 2),
              const Icon(Icons.chevron_left_rounded, size: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _errorCard(AppState s, bool dark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.wifi_off_rounded, size: 40, color: C.textTertiary),
          const SizedBox(height: 12),
          Text(
            s.t(s.error ?? 'errorLoading'),
            style: const TextStyle(color: C.textSecondary),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: s.refresh,
            style: FilledButton.styleFrom(backgroundColor: C.gold),
            child: Text(s.t('retry')),
          ),
        ],
      ),
    );
  }

  void _showNotif(BuildContext context) {
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
            const Icon(Icons.notifications_none_rounded,
                size: 40, color: C.gold),
            const SizedBox(height: 12),
            Text(
              appState.t('notifications'),
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: dark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              appState.t('noNotifications'),
              style: TextStyle(
                fontSize: 13,
                color: dark ? C.textSecondary : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Featured Dollar Card ───
class _FeaturedDollarCard extends StatelessWidget {
  final MarketAsset asset;
  const _FeaturedDollarCard({required this.asset});

  @override
  Widget build(BuildContext context) {
    final isUp = asset.change >= 0;
    final changeColor = isUp ? C.green : C.red;
    final tomanStr = asset.displayPrice;
    final changeAmount = asset.valueToman == null
        ? '0'
        : (asset.valueToman! * (asset.change / 100)).abs().toStringAsFixed(0);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => DetailScreen(asset: asset))),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              colors: [Color(0xFF1F2640), Color(0xFF12172A)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            border: Border.all(color: C.gold.withOpacity(0.25), width: 1),
          ),
          child: Stack(
            children: [
              // Chart background
              Positioned(
                right: -10,
                left: 60,
                top: 0,
                bottom: 0,
                child: Opacity(
                  opacity: 0.4,
                  child: Sparkline(
                    data: asset.sparkline,
                    color: C.gold,
                    width: double.infinity,
                    height: 130,
                    fill: true,
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
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(
                              color: C.gold.withOpacity(0.3), width: 0.8),
                        ),
                        alignment: Alignment.center,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            'https://flagcdn.com/w80/us.png',
                            width: 30,
                            height: 30,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Text('🇺🇸',
                                style: TextStyle(fontSize: 22)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appState.lang == 'en' ? 'US Dollar' : 'دلار آمریکا',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            appState.lang == 'en'
                                ? '1 USD to Toman'
                                : '۱ دلار به تومان',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        tomanStr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        appState.t('toman'),
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: changeColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isUp
                                  ? Icons.trending_up_rounded
                                  : Icons.trending_down_rounded,
                              color: changeColor,
                              size: 13,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              asset.changeText,
                              style: TextStyle(
                                color: changeColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${isUp ? '+' : '-'}$changeAmount',
                        style: TextStyle(
                          color: changeColor.withOpacity(0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
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

// ═══════════════════════════════════════════════════════
//  PRICES TAB
// ═══════════════════════════════════════════════════════
class PricesTab extends StatefulWidget {
  const PricesTab({super.key});
  @override
  State<PricesTab> createState() => _PricesTabState();
}

class _PricesTabState extends State<PricesTab> {
  final _searchCtrl = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    pricesCategory.addListener(_onCatChange);
    pricesSearch.addListener(_onSearchChange);
    _searchCtrl.text = pricesSearch.value;
  }

  @override
  void dispose() {
    pricesCategory.removeListener(_onCatChange);
    pricesSearch.removeListener(_onSearchChange);
    _searchCtrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onCatChange() => setState(() {});
  void _onSearchChange() {
    if (_searchCtrl.text != pricesSearch.value) {
      _searchCtrl.text = pricesSearch.value;
    }
    setState(() {});
  }

  List<MarketAsset> _filtered() {
    final s = appState;
    var list = s.all;
    final cat = pricesCategory.value;
    if (cat == 1) list = s.iran;
    if (cat == 2) list = s.crypto;
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isNotEmpty) {
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
        final t = appState.t;
        final list = _filtered();
        final cat = pricesCategory.value;

        return SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    const LogoMark(size: 34),
                    const SizedBox(width: 10),
                    Text(
                      t('prices'),
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
                    focusNode: _focus,
                    onChanged: (v) => setState(() {}),
                    style: TextStyle(
                      color: dark ? Colors.white : Colors.black,
                      fontSize: 13,
                    ),
                    decoration: InputDecoration(
                      hintText: t('searchHint'),
                      hintStyle: TextStyle(
                        color: dark ? C.textTertiary : Colors.black38,
                        fontSize: 13,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: dark ? C.textTertiary : Colors.black38,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
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
                      _tab(context, t('all'), 0, cat),
                      _tab(context, t('iran'), 1, cat),
                      _tab(context, t('crypto'), 2, cat),
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
                                    ? t('loading')
                                    : t('noResults'),
                                style: TextStyle(
                                  color: dark
                                      ? C.textSecondary
                                      : Colors.black54,
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

  Widget _tab(BuildContext context, String label, int value, int current) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final sel = current == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => pricesCategory.value = value,
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
              color: sel
                  ? Colors.black
                  : (dark ? C.textSecondary : Colors.black54),
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
        final t = appState.t;
        final list = appState.favList;
        return SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    const LogoMark(size: 34),
                    const SizedBox(width: 10),
                    Text(
                      t('watchlist'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: dark ? Colors.white : Colors.black,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => _showAddSheet(context),
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
                    child: Padding(
                      padding: const EdgeInsets.all(32),
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
                            t('emptyWatch'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: dark
                                  ? C.textSecondary
                                  : Colors.black54,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            t('emptyWatchHint'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: dark
                                  ? C.textTertiary
                                  : Colors.black38,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
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
                    onTap: () => _showAddSheet(context),
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
                            t('manageWatch'),
                            style: TextStyle(
                              color:
                                  dark ? Colors.white70 : Colors.black54,
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

  void _showAddSheet(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: dark ? C.bgSoft : Colors.white,
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
            final t = appState.t;
            final all = appState.all;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    t('chooseAsset'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: dark ? Colors.white : Colors.black,
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
                        leading: AssetIcon(asset: a, size: 42),
                        title: Text(
                          a.displayLabelFor(appState.lang),
                          style: TextStyle(
                            fontSize: 13,
                            color: dark ? Colors.white : Colors.black,
                          ),
                        ),
                        subtitle: Text(
                          '${a.displayPrice} ${a.isCrypto ? "USD" : appState.t("toman")}',
                          style: TextStyle(
                            fontSize: 11,
                            color: dark
                                ? C.textSecondary
                                : Colors.black54,
                          ),
                        ),
                        trailing: IconButton(
                          onPressed: () => appState.toggleFav(a.code),
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
//  SETTINGS TAB (no share)
// ═══════════════════════════════════════════════════════
class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final t = appState.t;
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
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
                              fontSize: 42,
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
                  label: t('darkMode'),
                  value: appState.darkMode,
                  onChanged: appState.setDark,
                ),
                _divider(context),
                _langItem(context, t),
              ]),
              const SizedBox(height: 12),
              _card(context, children: [
                _menuItem(
                  context,
                  icon: Icons.info_outline_rounded,
                  label: t('about'),
                  onTap: () => _aboutDialog(context, t),
                ),
                _divider(context),
                _menuItem(
                  context,
                  icon: Icons.support_agent_rounded,
                  label: t('support'),
                  onTap: () => _supportDialog(context, t),
                ),
              ]),
              const SizedBox(height: 24),

              // Bottom banner
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1F2640), Color(0xFF12172A)],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  border:
                      Border.all(color: C.gold.withOpacity(0.25), width: 1),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appState.lang == 'en'
                                ? 'World of Markets'
                                : 'دنیای بازارها',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            appState.lang == 'en'
                                ? 'Always available'
                                : 'همیشه در دسترس',
                            style: const TextStyle(
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

  Widget _langItem(BuildContext context, String Function(String) t) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Icon(Icons.language_rounded,
          color: dark ? Colors.white70 : Colors.black54),
      title: Text(
        t('language'),
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

  void _aboutDialog(BuildContext context, String Function(String) t) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: dark ? C.cardHigh : Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          t('about'),
          style: TextStyle(color: dark ? Colors.white : Colors.black),
        ),
        content: Text(
          t('aboutTextFa'),
          style: TextStyle(
            color: dark ? Colors.white70 : Colors.black87,
            height: 1.7,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('close'),
                style: const TextStyle(color: C.gold)),
          ),
        ],
      ),
    );
  }

  void _supportDialog(BuildContext context, String Function(String) t) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: dark ? C.cardHigh : Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          t('support'),
          style: TextStyle(color: dark ? Colors.white : Colors.black),
        ),
        content: Text(
          appState.lang == 'en'
              ? 'Contact us at:\n\nsupport@mrpingshop.ir\n\nor visit:\nmrpingshop.ir'
              : 'برای ارتباط با پشتیبانی:\n\nsupport@mrpingshop.ir\n\nیا از طریق سایت:\nmrpingshop.ir',
          style: TextStyle(
            color: dark ? Colors.white70 : Colors.black87,
            height: 1.7,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('close'),
                style: const TextStyle(color: C.gold)),
          ),
        ],
      ),
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

    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final t = appState.t;
        final isUp = a.change >= 0;
        final changeColor = isUp ? C.green : C.red;
        final isFav = appState.favorites.contains(a.code);

        final rawToman = a.valueToman ?? 0;
        final changeAmount =
            (rawToman * (a.change / 100)).abs().toStringAsFixed(0);

        final base = a.sparkline;
        final mult = [1, 2, 4, 12, 30][_rangeIdx];
        final ext = List<double>.from(base);
        for (int k = 0; k < mult - 1; k++) {
          final r = Random(a.code.hashCode + k);
          for (int i = 0; i < base.length; i++) {
            ext.add(ext.last + (r.nextDouble() - 0.48) * 3);
          }
        }
        final high = ext.reduce(max);
        final low = ext.reduce(min);

        return Scaffold(
          backgroundColor: dark ? C.bg : C.lightBg,
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded,
                  color: dark ? Colors.white : Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              a.displayLabelFor(appState.lang),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: dark ? Colors.white : Colors.black,
              ),
            ),
            actions: [
              IconButton(
                onPressed: () => appState.toggleFav(a.code),
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
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1F2640), Color(0xFF12172A)],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    border: Border.all(
                        color: C.gold.withOpacity(0.25), width: 1),
                  ),
                  child: Row(
                    children: [
                      AssetIcon(asset: a, size: 60),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a.displayLabelFor(appState.lang),
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
                                  a.isCrypto ? 'USD' : t('toman'),
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

                // Range
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
                                  : (dark
                                      ? Colors.white70
                                      : Colors.black54),
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
                          painter: _ChartPainter(ext, changeColor),
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
                              color:
                                  dark ? C.textTertiary : Colors.black38,
                              fontSize: 10,
                            ),
                          ),
                          Text(
                            high.toStringAsFixed(1),
                            style: TextStyle(
                              color:
                                  dark ? C.textTertiary : Colors.black38,
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
                      _statRow(
                        dark,
                        t('currentPrice'),
                        a.displayPrice,
                        dark ? Colors.white : Colors.black,
                      ),
                      _line(dark),
                      _statRow(
                        dark,
                        t('high24'),
                        a.high24h != null
                            ? a.high24h!.toStringAsFixed(2)
                            : high.toStringAsFixed(2),
                        dark ? Colors.white : Colors.black,
                      ),
                      _line(dark),
                      _statRow(
                        dark,
                        t('low24'),
                        a.low24h != null
                            ? a.low24h!.toStringAsFixed(2)
                            : low.toStringAsFixed(2),
                        dark ? Colors.white : Colors.black,
                      ),
                      _line(dark),
                      _statRow(
                        dark,
                        t('dailyChange'),
                        a.changeText,
                        changeColor,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Add to watchlist button
                GestureDetector(
                  onTap: () => appState.toggleFav(a.code),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: isFav
                          ? const LinearGradient(
                              colors: [Color(0xFF2A2A45), Color(0xFF1A1F33)],
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
                          isFav ? t('removeFromWatch') : t('addToWatch'),
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

    final lx = size.width;
    final ly =
        size.height - ((data.last - minV) / range) * (size.height - 10) - 5;
    canvas.drawCircle(Offset(lx, ly), 4, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) => false;
}
