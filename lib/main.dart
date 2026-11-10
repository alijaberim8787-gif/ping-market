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

// ... (کلاس S برای Localization و MarketAsset بدون تغییر اینجا قرار می‌گیرند) ...
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
//  APP STATE
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
    loading = iran.isEmpty && crypto.isEmpty;
    error = null; notifyListeners();
    try { await Future.wait([_loadAssets(), _loadCrypto()]).timeout(const Duration(seconds: 15)); } 
    catch (e) { error = t('connError'); } 
    finally { loading = false; notifyListeners(); }
  }

  Future<void> _loadAssets() async {
    try {
      final r = await http.get(Uri.parse(kAssetsUrl), headers: {'Accept': 'application/json'}).timeout(const Duration(seconds: 10));
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        if (data['assets'] != null) iran = (data['assets'] as List).map((e) => MarketAsset.fromJson(Map<String, dynamic>.from(e))).toList();
      }
    } catch (e) {}
  }

  Future<void> _loadCrypto() async {
    try {
      final r = await http.get(Uri.parse(kCryptoUrl), headers: {'Accept': 'application/json'}).timeout(const Duration(seconds: 10));
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        if (data['assets'] != null) crypto = (data['assets'] as List).map((e) => MarketAsset.fromJson(Map<String, dynamic>.from(e))).toList();
      }
    } catch (_) {}
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
//  MAIN APP (WITH ANIMATED SPLASH)
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
    Timer(const Duration(milliseconds: 3500), () {
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
        duration: const Duration(milliseconds: 800),
        child: showSplash ? const SplashScreen() : const AppShell(),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  BEAUTIFUL ANIMATED SPLASH SCREEN
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
    // 1. Logo Animation
    _logoController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _logoScale = Tween(begin: 0.6, end: 1.0).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack));
    _logoOpacity = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeIn));

    // 2. Text Animation (Starts after logo)
    _textController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _textSlide = Tween(begin: const Offset(0, 0.5), end: Offset.zero).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic));
    _textOpacity = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _textController, curve: Curves.easeIn));

    // 3. Glow Pulse Animation (Infinite)
    _glowController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _glowOpacity = Tween(begin: 0.3, end: 0.8).animate(CurvedAnimation(parent: _glowController, curve: Curves.easeInOut));

    // Start Sequence
    _logoController.forward().then((_) {
      _textController.forward();
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
          // Background Glow
          Center(
            child: AnimatedBuilder(
              animation: _glowOpacity,
              builder: (context, child) {
                return Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        C.primaryPurple.withOpacity(0.15 * _glowOpacity.value),
                        Colors.transparent,
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Main Content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated Logo
                ScaleTransition(
                  scale: _logoScale,
                  child: FadeTransition(
                    opacity: _logoOpacity,
                    child: Container(
                      width: 140,
                      height: 140,
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
                
                // Animated Text
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
                
                // Beautiful Loading Bar
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


// ... (کلاس‌های AppShell, _FloatingNav, GlassCard, Sparkline, AssetIcon و ... دقیقاً مانند قبل هستند و نیازی به تغییر ندارند) ...
// برای جلوگیری از طولانی شدن، از اینجا به بعد همان کدهای قبلی است. فقط نسخه SplashScreen تغییر کرد.

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

// (کدهای HomeTab, PricesTab, FavoritesTab, SettingsTab و DetailScreen دقیقاً مانند پیام قبلی هستند، نیازی به تکرار نیست)
// فقط کافیه همون کدهای قبلی رو بعد از این بخش در فایل main.dart کپی کنی.
