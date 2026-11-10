import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

// ═══════════════════════════════════════════════════════
//  CONFIG & COLORS
// ═══════════════════════════════════════════════════════
const String kBackend = 'https://mrpingshop.ir';
const String kAssetsUrl = '$kBackend/api/assets';
const String kCryptoUrl = '$kBackend/api/crypto/list';

class C {
  static const primaryPurple = Color(0xFF8A2BE2);
  static const primaryCyan = Color(0xFF00E5FF);
  static const gold = Color(0xFFFFD700);
  static const green = Color(0xFF00FA9A);
  static const red = Color(0xFFFF3366);
  static const bg = Color(0xFF05050A);
}

ThemeData get darkTheme => ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: C.bg,
  colorScheme: ColorScheme.fromSeed(seedColor: C.primaryPurple, brightness: Brightness.dark),
  appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0),
  pageTransitionsTheme: const PageTransitionsTheme(builders: {
    TargetPlatform.android: CupertinoPageTransitionsBuilder(),
    TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
  }),
);

ThemeData get lightTheme => ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  scaffoldBackgroundColor: const Color(0xFFF4F6FA),
  colorScheme: ColorScheme.fromSeed(seedColor: C.primaryPurple, brightness: Brightness.light),
  appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0),
  pageTransitionsTheme: const PageTransitionsTheme(builders: {
    TargetPlatform.android: CupertinoPageTransitionsBuilder(),
    TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
  }),
);

// ═══════════════════════════════════════════════════════
//  LOCALIZATION
// ═══════════════════════════════════════════════════════
class S {
  static const Map<String, List<String>> _d = {
    'home': ['خانه', 'Home'], 'prices': ['قیمت‌ها', 'Prices'], 'favs': ['علاقه‌مندی‌ها', 'Favorites'],
    'settings': ['تنظیمات', 'Settings'], 'searchHint': ['جستجوی قیمت‌ها...', 'Search prices...'],
    'all': ['همه', 'All'], 'currency': ['ارزها', 'Currencies'], 'crypto': ['کریپتو', 'Crypto'],
    'gold': ['طلا', 'Gold'], 'dollar': ['دلار', 'Dollar'], 'bitcoin': ['بیت‌کوین', 'Bitcoin'],
    'allMarkets': ['همه بازارها', 'All markets'], 'toman': ['تومان', 'Toman'],
    'darkMode': ['حالت نمایش', 'Display mode'], 'language': ['زبان برنامه', 'App language'],
    'notifications': ['اعلان‌ها', 'Notifications'], 'support': ['پشتیبانی', 'Support'],
    'privacy': ['حریم خصوصی و امنیت', 'Privacy & Security'], 'about': ['درباره ما', 'About'],
    'currentPrice': ['قیمت فعلی', 'Current Price'], 'dailyChange': ['تغییرات روزانه', 'Daily Change'],
    'addToWatch': ['افزودن به علاقه‌مندی‌ها', 'Add to Favorites'], 'removeFromWatch': ['حذف از علاقه‌مندی‌ها', 'Remove from Favorites'],
    'noFavs': ['هنوز چیزی اضافه نکردی', 'Nothing added yet'], 'noResults': ['موردی یافت نشد', 'No results found'],
    'loading': ['در حال دریافت اطلاعات...', 'Loading data...'], 'retry': ['تلاش دوباره', 'Retry'],
    'connError': ['اتصال به اینترنت برقرار نشد.', 'Connection failed.'],
    'aboutText': ['پینگ مارکت یک پلتفرم برای مشاهده قیمت لحظه‌ای است.\n\nنسخه ۲.۱.۰', 'Ping Market is a platform for live prices.\n\nVersion 2.1.0'],
    'supportText': ['mrpingshop.ir', 'mrpingshop.ir'], 'privacyText': ['اطلاعات شما کاملاً محرمانه است.', 'Your data is private.'],
    'noNotif': ['اعلان جدیدی وجود ندارد.', 'No new notifications.'], 'selectFeatured': ['انتخاب ارز برای نمایش در صفحه اصلی', 'Select asset for home banner'],
  };
  static String get(String key, String lang) {
    final v = _d[key];
    return v == null ? key : (lang == 'en' ? v[1] : v[0]);
  }
}

// ═══════════════════════════════════════════════════════
//  MODELS
// ═══════════════════════════════════════════════════════
class MarketAsset {
  final String code, symbol, labelFa, labelEn, icon;
  final String? imageUrl;
  final bool isCrypto;
  final double? value, valueUsd;
  final double change;
  final List<double> sparkline;

  MarketAsset({required this.code, required this.symbol, required this.labelFa, required this.labelEn, required this.icon, this.imageUrl, required this.isCrypto, this.value, this.valueUsd, required this.change, required this.sparkline});

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
      for (int i = 0; i < sp.length; i += step) { if (sp[i] is num) spark.add((sp[i] as num).toDouble()); }
    }
    if (spark.length < 2) {
      final r = Random(code.hashCode.abs());
      double v = 100;
      spark = List.generate(20, (_) { v += (r.nextDouble() - 0.45) * 2; return v; });
    }
    return MarketAsset(code: code, symbol: symbol, labelFa: j['labelFa']?.toString() ?? symbol, labelEn: j['labelEn']?.toString() ?? symbol, icon: j['icon']?.toString() ?? '🪙', imageUrl: j['image']?.toString(), isCrypto: isCrypto, value: j['value'] is num ? (j['value'] as num).toDouble() : null, valueUsd: j['valueUsd'] is num ? (j['valueUsd'] as num).toDouble() : null, change: change, sparkline: spark);
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
    return valueToman == null ? '—' : _fmt(valueToman!, 0);
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

// ═══════════════════════════════════════════════════════
//  APP STATE (Fix: Network Error Catching)
// ═══════════════════════════════════════════════════════
class AppState extends ChangeNotifier {
  List<MarketAsset> iran = [], crypto = [];
  bool loading = true;
  String? error;
  Set<String> favorites = {};
  String lang = 'fa';
  bool isDarkMode = true;
  int selectedTab = 0, pricesFilter = 0;
  String featuredCode = 'USD_RLS';

  List<MarketAsset> get all => [...iran, ...crypto];
  List<MarketAsset> get favList => all.where((a) => favorites.contains(a.code)).toList();
  MarketAsset? get featuredAsset => all.isEmpty ? null : all.firstWhere((a) => a.code == featuredCode, orElse: () => all.first);

  void setTab(int index) { selectedTab = index; notifyListeners(); }
  void setPricesFilter(int index) { pricesFilter = index; notifyListeners(); }

  Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    favorites = (p.getStringList('favs') ?? []).toSet();
    lang = p.getString('lang') ?? 'fa';
    isDarkMode = p.getBool('dark') ?? true;
    featuredCode = p.getString('featured') ?? 'USD_RLS';
    notifyListeners();
    await refresh();
  }

  Future<void> refresh() async {
    loading = true;
    error = null; 
    notifyListeners();
    
    try { 
      await Future.wait([_loadAssets(), _loadCrypto()]).timeout(const Duration(seconds: 15)); 
    } catch (e) { 
      error = t('connError'); 
    } finally { 
      loading = false; 
      notifyListeners(); 
    }
  }

  Future<void> _loadAssets() async {
    final r = await http.get(Uri.parse(kAssetsUrl), headers: {'Accept': 'application/json'}).timeout(const Duration(seconds: 10));
    if (r.statusCode == 200) {
      final data = jsonDecode(r.body);
      if (data['assets'] != null) {
        iran = (data['assets'] as List).map((e) => MarketAsset.fromJson(Map<String, dynamic>.from(e))).toList();
      }
    } else {
      throw Exception('Failed to load assets');
    }
  }

  Future<void> _loadCrypto() async {
    final r = await http.get(Uri.parse(kCryptoUrl), headers: {'Accept': 'application/json'}).timeout(const Duration(seconds: 10));
    if (r.statusCode == 200) {
      final data = jsonDecode(r.body);
      if (data['assets'] != null) {
        crypto = (data['assets'] as List).map((e) => MarketAsset.fromJson(Map<String, dynamic>.from(e))).toList();
      }
    } else {
      throw Exception('Failed to load crypto');
    }
  }

  Future<void> toggleFav(String code) async {
    favorites.contains(code) ? favorites.remove(code) : favorites.add(code);
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setStringList('favs', favorites.toList());
  }

  Future<void> setFeatured(String code) async {
    featuredCode = code; notifyListeners();
    final p = await SharedPreferences.getInstance(); await p.setString('featured', code);
  }

  Future<void> toggleLang() async {
    lang = lang == 'fa' ? 'en' : 'fa'; notifyListeners();
    final p = await SharedPreferences.getInstance(); await p.setString('lang', lang);
  }

  Future<void> toggleTheme() async {
    isDarkMode = !isDarkMode; notifyListeners();
    final p = await SharedPreferences.getInstance(); await p.setBool('dark', isDarkMode);
  }

  String t(String key) => S.get(key, lang);
}

// ═══════════════════════════════════════════════════════
//  MAIN APP (WITH SPLASH FIX)
// ═══════════════════════════════════════════════════════
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.light));
  runApp(ChangeNotifierProvider(create: (_) => AppState()..init(), child: const PingMarketApp()));
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
    Timer(const Duration(milliseconds: 3200), () {
      if (mounted) setState(() => showSplash = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ping Market',
      themeMode: state.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: lightTheme,
      darkTheme: darkTheme,
      locale: Locale(state.lang),
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        child: showSplash ? const SplashScreen() : const AppShell(),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  BEAUTIFUL ANIMATED SPLASH SCREEN (Fix: Mounted Check)
// ═══════════════════════════════════════════════════════
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _glowController;
  
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _textOpacity;
  late Animation<double> _glowOpacity;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _logoScale = Tween(begin: 0.6, end: 1.0).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack));
    _logoOpacity = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeIn));

    _textController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _textSlide = Tween(begin: const Offset(0, 0.5), end: Offset.zero).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic));
    _textOpacity = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _textController, curve: Curves.easeIn));

    _glowController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _glowOpacity = Tween(begin: 0.3, end: 0.8).animate(CurvedAnimation(parent: _glowController, curve: Curves.easeInOut));

    _logoController.forward().then((_) {
      if (mounted) _textController.forward(); // Fix: Prevent crash if disposed
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      body: Stack(
        children: [
          Center(
            child: AnimatedBuilder(
              animation: _glowOpacity,
              builder: (context, child) {
                return Container(
                  width: 300, height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [C.primaryPurple.withOpacity(0.15 * _glowOpacity.value), Colors.transparent],
                    ),
                  ),
                );
              },
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: _logoScale,
                  child: FadeTransition(
                    opacity: _logoOpacity,
                    child: Container(
                      width: 140, height: 140,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(35),
                        boxShadow: [
                          BoxShadow(color: C.primaryPurple.withOpacity(0.4), blurRadius: 40, spreadRadius: 10),
                          BoxShadow(color: C.primaryCyan.withOpacity(0.2), blurRadius: 20, spreadRadius: 2),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(35),
                        child: Image.asset('assets/logo.png', fit: BoxFit.cover),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SlideTransition(
                  position: _textSlide,
                  child: FadeTransition(
                    opacity: _textOpacity,
                    child: Column(
                      children: [
                        RichText(
                          text: const TextSpan(
                            children: [
                              TextSpan(text: 'Ping ', style: TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w900, letterSpacing: -1)),
                              TextSpan(text: 'Market', style: TextStyle(color: C.primaryCyan, fontSize: 38, fontWeight: FontWeight.w900, letterSpacing: -1)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text('Real-time Prices · Global Markets', style: TextStyle(color: Colors.white54, fontSize: 13, letterSpacing: 1.2)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 60),
                FadeTransition(
                  opacity: _textOpacity,
                  child: SizedBox(
                    width: 180,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: const LinearProgressIndicator(
                        minHeight: 4,
                        backgroundColor: Color(0xFF1C1C2A),
                        valueColor: AlwaysStoppedAnimation<Color>(C.primaryPurple),
                      ),
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
}

// ═══════════════════════════════════════════════════════
//  APP SHELL
// ═══════════════════════════════════════════════════════
class AppShell extends StatelessWidget {
  const AppShell({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: state.selectedTab,
        children: const [HomeTab(), PricesTab(), FavoritesTab(), SettingsTab()],
      ),
      bottomNavigationBar: _FloatingNav(index: state.selectedTab, onChanged: (i) => state.setTab(i)),
    );
  }
}

class _FloatingNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  const _FloatingNav({required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = state.isDarkMode;
    final t = state.t;
    final items = [
      (Icons.home_outlined, Icons.home_rounded, t('home')),
      (Icons.show_chart_outlined, Icons.show_chart_rounded, t('prices')),
      (Icons.favorite_border_rounded, Icons.favorite_rounded, t('favs')),
      (Icons.settings_outlined, Icons.settings_rounded, t('settings')),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      height: 72,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF11111A).withOpacity(0.85) : Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05), width: 1.5),
        boxShadow: [BoxShadow(color: C.primaryPurple.withOpacity(0.15), blurRadius: 30, spreadRadius: 2)],
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
                child: TapScale(
                  onTap: () => onChanged(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(sel ? active : icon, color: sel ? C.primaryPurple : (isDark ? const Color(0xFFA0A0B0) : Colors.black54), size: 26),
                      const SizedBox(height: 4),
                      Text(label, style: TextStyle(fontSize: 11, color: sel ? C.primaryPurple : (isDark ? const Color(0xFFA0A0B0) : Colors.black54), fontWeight: sel ? FontWeight.w700 : FontWeight.w500)),
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
//  ANIMATION & CORE WIDGETS
// ═══════════════════════════════════════════════════════
class TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const TapScale({super.key, required this.child, required this.onTap});
  @override
  State<TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<TapScale> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween(begin: 1.0, end: 0.92).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) { _controller.reverse(); widget.onTap(); },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

class StaggeredListItem extends StatelessWidget {
  final int index;
  final Widget child;
  const StaggeredListItem({super.key, required this.index, required this.child});
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(opacity: value, child: Transform.translate(offset: Offset(0, 30 * (1 - value)), child: child));
      },
      child: child,
    );
  }
}

class ShimmerSkeleton extends StatefulWidget {
  final double height;
  const ShimmerSkeleton({super.key, required this.height});
  @override
  State<ShimmerSkeleton> createState() => _ShimmerSkeletonState();
}

class _ShimmerSkeletonState extends State<ShimmerSkeleton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() { super.initState(); _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true); }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          height: widget.height, margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Color.lerp(const Color(0xFF1C1C2A), const Color(0xFF2C2C3A), _controller.value),
            borderRadius: BorderRadius.circular(20),
          ),
        );
      },
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const GlassCard({super.key, required this.child, this.padding = const EdgeInsets.all(16)});
  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<AppState>().isDarkMode;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C2A).withOpacity(0.4) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
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
    return SizedBox(width: 70, height: 30, child: CustomPaint(painter: _SparkPainter(data, color)));
  }
}

class _SparkPainter extends CustomPainter {
  final List<double> data;
  final Color color;
  _SparkPainter(this.data, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final minV = data.reduce(min).toDouble();
    final maxV = data.reduce(max).toDouble();
    final range = (maxV - minV) == 0 ? 1.0 : (maxV - minV);
    final path = Path();
    final fillPath = Path()..moveTo(0, size.height);
    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height - ((data[i] - minV) / range) * size.height;
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
      fillPath.lineTo(x, y);
    }
    fillPath..lineTo(size.width, size.height)..close();
    canvas.drawPath(fillPath, Paint()..shader = LinearGradient(colors: [color.withOpacity(0.3), color.withOpacity(0)], begin: Alignment.topCenter, end: Alignment.bottomCenter).createShader(Rect.fromLTWH(0, 0, size.width, size.height)));
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
    Color bgColor = const Color(0xFF1C1C2A);
    Widget iconWidget = Text(asset.icon, style: TextStyle(fontSize: size * 0.5));
    if (asset.code == 'USD_RLS') { bgColor = const Color(0xFF0B4A29); iconWidget = const Text('\$', style: TextStyle(color: C.green, fontSize: 24, fontWeight: FontWeight.bold)); } 
    else if (asset.code == 'GOLD_18_RLS') { bgColor = const Color(0xFF4A3E0B); iconWidget = const Icon(Icons.diamond, color: C.gold, size: 24); } 
    else if (asset.symbol == 'BTC') { bgColor = const Color(0xFF4A260B); iconWidget = const Text('₿', style: TextStyle(color: Colors.orange, fontSize: 26, fontWeight: FontWeight.bold)); } 
    else if (asset.symbol == 'ETH') { bgColor = const Color(0xFF1F1F4A); iconWidget = const Text('Ξ', style: TextStyle(color: Colors.blueAccent, fontSize: 26, fontWeight: FontWeight.bold)); } 
    else if (asset.symbol == 'USDT') { bgColor = const Color(0xFF0B4A3D); iconWidget = const Text('₮', style: TextStyle(color: Color(0xFF26A17B), fontSize: 24, fontWeight: FontWeight.bold)); } 
    else if (asset.imageUrl != null && asset.imageUrl!.isNotEmpty) {
      iconWidget = Image.network(asset.imageUrl!, width: size * 0.6, height: size * 0.6, errorBuilder: (_,__,___) => iconWidget);
      bgColor = Colors.transparent;
    }
    return Hero(tag: 'icon_${asset.code}', child: Container(width: size, height: size, decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(14)), alignment: Alignment.center, child: iconWidget));
  }
}

// ═══════════════════════════════════════════════════════
//  HOME TAB
// ═══════════════════════════════════════════════════════
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = state.isDarkMode;
    final t = state.t;
    final textColor = isDark ? Colors.white : Colors.black;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: C.primaryPurple,
        backgroundColor: isDark ? const Color(0xFF11111A) : Colors.white,
        onRefresh: state.refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
          children: [
            Row(
              children: [
                TapScale(
                  onTap: () => _showNotif(context, state),
                  child: GlassCard(
                    padding: const EdgeInsets.all(10),
                    child: Icon(Icons.notifications_none_rounded, color: textColor),
                  ),
                ),
                const Spacer(),
                Column(
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(text: 'Ping ', style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.w800)),
                          const TextSpan(text: 'Market', style: TextStyle(color: C.primaryPurple, fontSize: 20, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                    Text('Real-time Prices', style: TextStyle(color: isDark ? const Color(0xFFA0A0B0) : Colors.black54, fontSize: 10)),
                  ],
                ),
                const Spacer(),
                TapScale(
                  onTap: state.toggleLang,
                  child: GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Text(state.lang == 'fa' ? 'فا' : 'EN', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (!state.loading && state.featuredAsset != null)
              TapScale(
                onTap: () => _showFeaturedSelector(context, state),
                child: _buildFeaturedCard(state, state.featuredAsset!),
              )
            else if (state.loading)
              const ShimmerSkeleton(height: 160)
            else
              _buildErrorCard(context, state),
            
            const SizedBox(height: 20),

            TapScale(
              onTap: () => state.setTab(1),
              child: GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, color: isDark ? const Color(0xFFA0A0B0) : Colors.black54),
                    const SizedBox(width: 10),
                    Expanded(child: Text(t('searchHint'), style: TextStyle(color: isDark ? const Color(0xFF606070) : Colors.black38))),
                    Icon(Icons.tune_rounded, color: isDark ? const Color(0xFFA0A0B0) : Colors.black54),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _quickAction(context, state, Icons.diamond_rounded, t('gold'), C.gold, 1),
                _quickAction(context, state, Icons.attach_money_rounded, t('dollar'), C.green, 1),
                _quickAction(context, state, Icons.currency_bitcoin_rounded, t('bitcoin'), Colors.orange, 2),
                _quickAction(context, state, Icons.grid_view_rounded, t('allMarkets'), Colors.blueAccent, 0),
              ],
            ),
            
            const SizedBox(height: 24),
            
            if (state.loading) ...[
              const ShimmerSkeleton(height: 80),
              const ShimmerSkeleton(height: 80),
              const ShimmerSkeleton(height: 80),
            ]
            else if (state.error != null && state.all.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      const Icon(Icons.wifi_off_rounded, color: C.red, size: 48),
                      const SizedBox(height: 16),
                      Text(state.error!, style: TextStyle(color: isDark ? const Color(0xFFA0A0B0) : Colors.black54), textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: state.refresh,
                        style: ElevatedButton.styleFrom(backgroundColor: C.primaryPurple),
                        child: Text(t('retry')),
                      ),
                    ],
                  ),
                ),
              )
            else if (state.all.isNotEmpty)
              ...state.all.take(4).toList().asMap().entries.map((entry) {
                return StaggeredListItem(
                  index: entry.key,
                  child: _homePriceRow(context, state, entry.value),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedCard(AppState state, MarketAsset asset) {
    final isUp = asset.change >= 0;
    final changeColor = isUp ? C.green : C.red;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF4A148C), Color(0xFF1A237E)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: C.primaryPurple.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Stack(
        children: [
          Positioned(right: -20, bottom: -20, child: Icon(Icons.show_chart_rounded, size: 120, color: Colors.white.withOpacity(0.05))),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AssetIcon(asset: asset, size: 40),
                  const SizedBox(width: 12),
                  Text(asset.displayLabelFor(state.lang), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  const Icon(Icons.touch_app_rounded, color: Colors.white54, size: 20),
                ],
              ),
              const SizedBox(height: 24),
              Text(asset.displayPrice, style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: -1)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, color: changeColor, size: 16),
                  const SizedBox(width: 4),
                  Text(asset.changeText, style: TextStyle(color: changeColor, fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showFeaturedSelector(BuildContext context, AppState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: state.isDarkMode ? const Color(0xFF11111A) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(state.t('selectFeatured'), style: TextStyle(color: state.isDarkMode ? Colors.white : Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: state.all.length,
                  itemBuilder: (_, i) {
                    final a = state.all[i];
                    return ListTile(
                      leading: AssetIcon(asset: a, size: 40),
                      title: Text(a.displayLabelFor(state.lang), style: TextStyle(color: state.isDarkMode ? Colors.white : Colors.black)),
                      onTap: () { state.setFeatured(a.code); Navigator.pop(ctx); },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _quickAction(BuildContext context, AppState state, IconData icon, String label, Color color, int filter) {
    return TapScale(
      onTap: () { state.setPricesFilter(filter); state.setTab(1); },
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: state.isDarkMode ? Colors.white : Colors.black, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _homePriceRow(BuildContext context, AppState state, MarketAsset a) {
    final isUp = a.change >= 0;
    return TapScale(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(asset: a))),
      child: Padding(
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
                    Text(a.displayLabelFor(state.lang), style: TextStyle(color: state.isDarkMode ? Colors.white : Colors.black, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(a.displayPrice, style: TextStyle(color: state.isDarkMode ? const Color(0xFFA0A0B0) : Colors.black54, fontSize: 13)),
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
              Icon(Icons.chevron_right_rounded, color: state.isDarkMode ? const Color(0xFF606070) : Colors.black38),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, AppState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(Icons.wifi_off_rounded, color: C.red, size: 48),
            const SizedBox(height: 16),
            Text(state.error ?? 'Error', style: TextStyle(color: state.isDarkMode ? const Color(0xFFA0A0B0) : Colors.black54), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: state.refresh, style: ElevatedButton.styleFrom(backgroundColor: C.primaryPurple), child: Text(state.t('retry'))),
          ],
        ),
      ),
    );
  }

  void _showNotif(BuildContext context, AppState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: state.isDarkMode ? const Color(0xFF11111A) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.notifications_none_rounded, color: C.primaryPurple, size: 40),
            const SizedBox(height: 16),
            Text(state.t('notifications'), style: TextStyle(color: state.isDarkMode ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(state.t('noNotif'), style: TextStyle(color: state.isDarkMode ? const Color(0xFFA0A0B0) : Colors.black54)),
          ],
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
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = state.isDarkMode;
    final t = state.t;
    final textColor = isDark ? Colors.white : Colors.black;
    
    List<MarketAsset> list = state.all;
    if (state.pricesFilter == 1) list = state.iran;
    if (state.pricesFilter == 2) list = state.crypto;
    
    if (_query.isNotEmpty) {
      list = list.where((a) => a.displayLabelFor(state.lang).toLowerCase().contains(_query.toLowerCase())).toList();
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
                const Icon(Icons.bar_chart_rounded, color: C.primaryCyan, size: 28),
                const SizedBox(width: 10),
                Text(t('prices'), style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v),
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: t('searchHint'),
                  hintStyle: TextStyle(color: isDark ? const Color(0xFF606070) : Colors.black38),
                  border: InputBorder.none,
                  icon: Icon(Icons.search_rounded, color: isDark ? const Color(0xFFA0A0B0) : Colors.black54),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _filterPill(state, t('all'), 0),
                _filterPill(state, t('currency'), 1),
                _filterPill(state, t('crypto'), 2),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: RefreshIndicator(
              color: C.primaryPurple,
              backgroundColor: isDark ? const Color(0xFF11111A) : Colors.white,
              onRefresh: state.refresh,
              child: state.loading 
                  ? ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: const [ShimmerSkeleton(height: 80), ShimmerSkeleton(height: 80), ShimmerSkeleton(height: 80)],
                    )
                  : list.isEmpty
                      ? Center(child: Text(t('noResults'), style: TextStyle(color: isDark ? const Color(0xFFA0A0B0) : Colors.black54)))
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                          children: list.asMap().entries.map((entry) {
                            final a = entry.value;
                            final isUp = a.change >= 0;
                            return StaggeredListItem(
                              index: entry.key > 10 ? 10 : entry.key,
                              child: TapScale(
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(asset: a))),
                                child: Padding(
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
                                              Text(a.displayLabelFor(state.lang), style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                                              const SizedBox(height: 4),
                                              Text(a.displayPrice, style: TextStyle(color: isDark ? const Color(0xFFA0A0B0) : Colors.black54, fontSize: 13)),
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
                                        Icon(Icons.chevron_right_rounded, color: isDark ? const Color(0xFF606070) : Colors.black38),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterPill(AppState state, String label, int idx) {
    final sel = state.pricesFilter == idx;
    return TapScale(
      onTap: () => state.setPricesFilter(idx),
      child: Container(
        margin: const EdgeInsets.only(left: 10),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          gradient: sel ? const LinearGradient(colors: [C.primaryPurple, C.primaryCyan]) : null,
          color: sel ? null : (state.isDarkMode ? const Color(0xFF1C1C2A) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: sel ? null : Border.all(color: state.isDarkMode ? Colors.white10 : Colors.black12),
        ),
        child: Text(label, style: TextStyle(color: sel ? Colors.white : (state.isDarkMode ? const Color(0xFFA0A0B0) : Colors.black54), fontWeight: FontWeight.bold)),
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
    final state = context.watch<AppState>();
    final isDark = state.isDarkMode;
    final t = state.t;
    final textColor = isDark ? Colors.white : Colors.black;

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
                Text(t('favs'), style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: state.favList.isEmpty
                ? Center(child: Text(t('noFavs'), style: TextStyle(color: isDark ? const Color(0xFFA0A0B0) : Colors.black54)))
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                    children: state.favList.asMap().entries.map((entry) {
                      final a = entry.value;
                      final isUp = a.change >= 0;
                      return StaggeredListItem(
                        index: entry.key,
                        child: TapScale(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(asset: a))),
                          child: Padding(
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
                                        Text(a.displayLabelFor(state.lang), style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 4),
                                        Text(a.displayPrice, style: TextStyle(color: isDark ? const Color(0xFFA0A0B0) : Colors.black54, fontSize: 13)),
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
                                  TapScale(
                                    onTap: () => state.toggleFav(a.code),
                                    child: const Padding(
                                      padding: EdgeInsets.all(4.0),
                                      child: Icon(Icons.delete_outline_rounded, color: C.red),
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
    final state = context.watch<AppState>();
    final isDark = state.isDarkMode;
    final t = state.t;
    final textColor = isDark ? Colors.white : Colors.black;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        children: [
          Row(
            children: [
              const Icon(Icons.settings_rounded, color: C.primaryCyan, size: 28),
              const SizedBox(width: 10),
              Text(t('settings'), style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 30),
          _settingItem(
            context, state,
            Icons.wb_sunny_rounded, t('darkMode'), 
            trailing: Icon(isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded, color: C.primaryPurple),
            onTap: state.toggleTheme,
          ),
          _settingItem(
            context, state,
            Icons.language_rounded, t('language'), 
            trailing: Text(state.lang == 'fa' ? 'فارسی' : 'English', style: TextStyle(color: isDark ? const Color(0xFFA0A0B0) : Colors.black54)),
            onTap: state.toggleLang,
          ),
          _settingItem(
            context, state,
            Icons.notifications_none_rounded, t('notifications'),
            onTap: () => _showMsg(context, t('notifications'), t('noNotif'), isDark),
          ),
          _settingItem(
            context, state,
            Icons.headset_mic_rounded, t('support'),
            onTap: () => _showMsg(context, t('support'), t('supportText'), isDark),
          ),
          _settingItem(
            context, state,
            Icons.shield_outlined, t('privacy'),
            onTap: () => _showMsg(context, t('privacy'), t('privacyText'), isDark),
          ),
          _settingItem(
            context, state,
            Icons.info_outline_rounded, t('about'),
            onTap: () => _showMsg(context, t('about'), t('aboutText'), isDark),
          ),
        ],
      ),
    );
  }

  void _showMsg(BuildContext context, String title, String text, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C2A) : Colors.white,
        title: Text(title, style: TextStyle(color: isDark ? Colors.white : Colors.black)),
        content: Text(text, style: TextStyle(color: isDark ? const Color(0xFFA0A0B0) : Colors.black54, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('باشه', style: TextStyle(color: C.primaryPurple, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _settingItem(BuildContext context, AppState state, IconData icon, String title, {Widget? trailing, required VoidCallback onTap}) {
    final isDark = state.isDarkMode;
    return TapScale(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: isDark ? const Color(0xFFA0A0B0) : Colors.black54),
              const SizedBox(width: 16),
              Expanded(child: Text(title, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w600))),
              if (trailing != null) trailing,
              if (trailing == null) Icon(Icons.chevron_left_rounded, color: isDark ? const Color(0xFF606070) : Colors.black38),
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
    final state = context.watch<AppState>();
    final isDark = state.isDarkMode;
    final a = widget.asset;
    final t = state.t;
    final isUp = a.change >= 0;
    final changeColor = isUp ? C.green : C.red;
    final isFav = state.favorites.contains(a.code);
    final textColor = isDark ? Colors.white : Colors.black;

    final base = a.sparkline;
    final mult = [1, 2, 4, 12, 30][_rangeIdx];
    final ext = List<double>.from(base);
    for (int k = 0; k < mult - 1; k++) {
      final r = Random(a.code.hashCode + k);
      for (int i = 0; i < base.length; i++) {
        ext.add(ext.last + (r.nextDouble() - 0.48) * 3);
      }
    }
    final high = ext.reduce(max).toDouble();
    final low = ext.reduce(min).toDouble();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF05050A) : const Color(0xFFF4F6FA),
      appBar: AppBar(
        leading: TapScale(
          onTap: () => Navigator.pop(context),
          child: Icon(Icons.arrow_back_rounded, color: textColor),
        ),
        title: Text(a.displayLabelFor(state.lang), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textColor)),
        actions: [
          TapScale(
            onTap: () => state.toggleFav(a.code),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Icon(isFav ? Icons.star_rounded : Icons.star_border_rounded, color: C.gold),
            ),
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
                        Text(a.displayLabelFor(state.lang), style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14)),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(a.displayPrice, style: TextStyle(color: textColor, fontSize: 28, fontWeight: FontWeight.w900)),
                            const SizedBox(width: 6),
                            Text(a.isCrypto ? 'USD' : t('toman'), style: TextStyle(color: isDark ? Colors.white54 : Colors.black38, fontSize: 14)),
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
                Icon(isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded, color: changeColor, size: 20),
                const SizedBox(width: 6),
                Text(a.changeText, style: TextStyle(color: changeColor, fontSize: 16, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 24),

            Row(
              children: List.generate(_ranges.length, (i) {
                final sel = _rangeIdx == i;
                return Expanded(
                  child: TapScale(
                    onTap: () => setState(() => _rangeIdx = i),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: sel ? C.primaryPurple : (isDark ? const Color(0xFF1C1C2A) : Colors.white),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: sel ? C.primaryCyan : (isDark ? Colors.white10 : Colors.black12)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _ranges[i],
                        style: TextStyle(color: sel ? Colors.white : (isDark ? const Color(0xFFA0A0B0) : Colors.black54), fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),

            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SizedBox(
                    height: 200,
                    child: CustomPaint(painter: _ChartPainter(ext, changeColor), child: const SizedBox.expand()),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(low.toStringAsFixed(1), style: TextStyle(color: isDark ? const Color(0xFF606070) : Colors.black38, fontSize: 11)),
                      Text(high.toStringAsFixed(1), style: TextStyle(color: isDark ? const Color(0xFF606070) : Colors.black38, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _statRow(t('currentPrice'), a.displayPrice, textColor, isDark),
                  Divider(height: 24, color: isDark ? Colors.white.withOpacity(0.05) : Colors.black12),
                  _statRow(t('dailyChange'), a.changeText, changeColor, isDark),
                ],
              ),
            ),
            const SizedBox(height: 30),

            TapScale(
              onTap: () => state.toggleFav(a.code),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: isFav ? null : const LinearGradient(colors: [C.primaryPurple, C.primaryCyan]),
                  color: isFav ? (isDark ? const Color(0xFF1C1C2A) : Colors.white) : null,
                  borderRadius: BorderRadius.circular(16),
                  border: isFav ? Border.all(color: C.primaryPurple) : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(isFav ? Icons.star_rounded : Icons.star_border_rounded, color: isFav ? C.primaryPurple : Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      isFav ? t('removeFromWatch') : t('addToWatch'),
                      style: TextStyle(color: isFav ? C.primaryPurple : Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
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

  Widget _statRow(String label, String value, Color color, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: isDark ? const Color(0xFFA0A0B0) : Colors.black54, fontSize: 14)),
        Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
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
    final minV = data.reduce(min).toDouble();
    final maxV = data.reduce(max).toDouble();
    final range = (maxV - minV) == 0 ? 1.0 : (maxV - minV);

    final linePath = Path();
    final fillPath = Path()..moveTo(0, size.height);

    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height - ((data[i] - minV) / range) * (size.height - 10) - 5;
      if (i == 0) {
        linePath.moveTo(x, y);
      } else {
        linePath.lineTo(x, y);
      }
      fillPath.lineTo(x, y);
    }
    fillPath..lineTo(size.width, size.height)..close();

    canvas.drawPath(fillPath, Paint()..shader = LinearGradient(
      colors: [color.withOpacity(0.3), color.withOpacity(0)],
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)));

    canvas.drawPath(linePath, Paint()..color = color..strokeWidth = 2.5..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
    
    final lx = size.width;
    final ly = size.height - ((data.last - minV) / range) * (size.height - 10) - 5;
    canvas.drawCircle(Offset(lx, ly), 4, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) => false;
}
