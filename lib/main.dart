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
const String kLoginUrl = '$kBackend/api/auth/login';
const String kRegisterUrl = '$kBackend/api/auth/register';
const String kUpdateProfileUrl = '$kBackend/api/user/update';
const String kChatUrl = '$kBackend/api/chat/messages';
const String kSendMsgUrl = '$kBackend/api/chat/send';
const String kAdminStatsUrl = '$kBackend/api/admin/stats';
const String kAdminUsersUrl = '$kBackend/api/admin/users';
const String kAdminBroadcastUrl = '$kBackend/api/admin/broadcast';
const String kAdminClearChatUrl = '$kBackend/api/admin/chat/clear';

class C {
  static const primaryPurple = Color(0xFF8A2BE2);
  static const primaryCyan = Color(0xFF00E5FF);
  static const gold = Color(0xFFFFD700);
  static const green = Color(0xFF00FA9A);
  static const red = Color(0xFFFF3366);
  static const bg = Color(0xFF05050A);
}

ThemeData get darkTheme => ThemeData(
  useMaterial3: true, brightness: Brightness.dark, scaffoldBackgroundColor: C.bg,
  colorScheme: ColorScheme.fromSeed(seedColor: C.primaryPurple, brightness: Brightness.dark),
  appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0),
  pageTransitionsTheme: const PageTransitionsTheme(builders: {
    TargetPlatform.android: CupertinoPageTransitionsBuilder(), TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
  }),
);

ThemeData get lightTheme => ThemeData(
  useMaterial3: true, brightness: Brightness.light, scaffoldBackgroundColor: const Color(0xFFF4F6FA),
  colorScheme: ColorScheme.fromSeed(seedColor: C.primaryPurple, brightness: Brightness.light),
  appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0),
  pageTransitionsTheme: const PageTransitionsTheme(builders: {
    TargetPlatform.android: CupertinoPageTransitionsBuilder(), TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
  }),
);

// ═══════════════════════════════════════════════════════
//  LOCALIZATION
// ═══════════════════════════════════════════════════════
class S {
  static const Map<String, List<String>> _d = {
    'home': ['خانه', 'Home'], 'prices': ['قیمت‌ها', 'Prices'], 'chat': ['چت روم', 'Chat'],
    'favs': ['علاقه‌مندی‌ها', 'Favorites'], 'settings': ['پروفایل', 'Profile'],
    'searchHint': ['جستجوی قیمت‌ها...', 'Search prices...'],
    'all': ['همه', 'All'], 'currency': ['ارزها', 'Currencies'], 'crypto': ['کریپتو', 'Crypto'],
    'gold': ['طلا', 'Gold'], 'dollar': ['دلار', 'Dollar'], 'bitcoin': ['بیت‌کوین', 'Bitcoin'],
    'allMarkets': ['همه بازارها', 'All markets'], 'toman': ['تومان', 'Toman'],
    'darkMode': ['حالت نمایش', 'Display mode'], 'language': ['زبان برنامه', 'App language'],
    'notifications': ['اعلان‌ها', 'Notifications'], 'support': ['پشتیبانی', 'Support'],
    'privacy': ['حریم خصوصی', 'Privacy'], 'about': ['درباره ما', 'About'],
    'currentPrice': ['قیمت فعلی', 'Current Price'], 'dailyChange': ['تغییرات روزانه', 'Daily Change'],
    'addToWatch': ['افزودن به علاقه‌مندی‌ها', 'Add to Favorites'], 'removeFromWatch': ['حذف از علاقه‌مندی‌ها', 'Remove from Favorites'],
    'noFavs': ['هنوز چیزی اضافه نکردی', 'Nothing added yet'], 'noResults': ['موردی یافت نشد', 'No results found'],
    'loading': ['در حال دریافت اطلاعات...', 'Loading data...'], 'retry': ['تلاش دوباره', 'Retry'],
    'connError': ['اتصال به اینترنت برقرار نشد.', 'Connection failed.'],
    'aboutText': ['پینگ مارکت نسخه ۲.۱.۷', 'Ping Market v2.1.7'],
    'supportText': ['mrpingshop.ir', 'mrpingshop.ir'], 'privacyText': ['اطلاعات شما محرمانه است.', 'Your data is private.'],
    'noNotif': ['اعلان جدیدی وجود ندارد.', 'No new notifications.'], 'selectFeatured': ['انتخاب ارز برای صفحه اصلی', 'Select asset for home'],
    'login': ['ورود', 'Login'], 'register': ['ثبت‌نام', 'Register'],
    'loginTitle': ['ورود به حساب', 'Login'], 'registerTitle': ['ساخت حساب جدید', 'Create Account'],
    'username': ['نام کاربری', 'Username'], 'password': ['رمز عبور', 'Password'],
    'logout': ['خروج', 'Logout'], 'adminPanel': ['پنل مدیریت', 'Admin Panel'],
    'editProfile': ['ویرایش پروفایل', 'Edit Profile'], 'save': ['ذخیره', 'Save'], 'cancel': ['لغو', 'Cancel'],
    'bio': ['بیوگرافی', 'Bio'], 'avatar': ['آواتار', 'Avatar'],
    'typeMessage': ['پیام خود را بنویسید...', 'Type a message...'],
    'loginToChat': ['برای ارسال پیام وارد شوید', 'Login to send messages'],
    'admin': ['مدیر', 'Admin'], 'user': ['کاربر', 'User'], 'banned': ['مسدود', 'Banned'],
    'noAccount': ['حساب ندارید؟ ثبت‌نام کنید', 'No account? Register'],
    'haveAccount': ['حساب دارید؟ وارد شوید', 'Have account? Login'],
    'adminDashboard': ['داشبورد', 'Dashboard'], 'adminUsers': ['مدیریت کاربران', 'Users Mgmt'],
    'adminChat': ['مدیریت چت', 'Chat Mgmt'], 'adminBroadcast': ['ارسال پیام همگانی', 'Broadcast'],
    'totalUsers': ['کل کاربران', 'Total Users'], 'totalMsgs': ['کل پیام‌ها', 'Total Messages'],
    'bannedUsers': ['کاربران مسدود', 'Banned Users'], 'clearChat': ['پاک کردن کل چت', 'Clear All Chat'],
    'promote': ['ادمین کن', 'Make Admin'], 'demote': ['سلب ادمینی', 'Remove Admin'],
    'ban': ['مسدود کن', 'Ban'], 'unban': ['رفع مسدودی', 'Unban'], 'delete': ['حذف', 'Delete'],
    'broadcastHint': ['متن پیام برای همه...', 'Message text for everyone...'],
    'send': ['ارسال', 'Send'], 'systemMsg': ['پیام سیستم', 'System Message'],
  };
  static String get(String key, String lang) { final v = _d[key]; return v == null ? key : (lang == 'en' ? v[1] : v[0]); }
}

// ═══════════════════════════════════════════════════════
//  MODELS
// ═══════════════════════════════════════════════════════
class MarketAsset {
  final String code, symbol, labelFa, labelEn, icon;
  final String? imageUrl; final bool isCrypto; final double? value, valueUsd;
  final double change; final List<double> sparkline;

  MarketAsset({required this.code, required this.symbol, required this.labelFa, required this.labelEn, required this.icon, this.imageUrl, required this.isCrypto, this.value, this.valueUsd, required this.change, required this.sparkline});

  factory MarketAsset.fromJson(Map<String, dynamic> j) {
    final code = j['code']?.toString() ?? ''; final isCrypto = code.startsWith('CG_');
    final symbol = j['symbol']?.toString() ?? (isCrypto ? code.substring(3) : code.replaceAll('_RLS', ''));
    final changeRaw = j['change24h']; final double change = changeRaw is num ? changeRaw.toDouble() : ((code.hashCode.abs() % 500) - 200) / 100.0;
    List<double> spark = []; final sp = j['sparkline'];
    if (sp is List && sp.length > 1) { final step = max(1, sp.length ~/ 30); for (int i = 0; i < sp.length; i += step) { if (sp[i] is num) spark.add((sp[i] as num).toDouble()); } }
    if (spark.length < 2) { final r = Random(code.hashCode.abs()); double v = 100; spark = List.generate(20, (_) { v += (r.nextDouble() - 0.45) * 2; return v; }); }
    return MarketAsset(code: code, symbol: symbol, labelFa: j['labelFa']?.toString() ?? symbol, labelEn: j['labelEn']?.toString() ?? symbol, icon: j['icon']?.toString() ?? '🪙', imageUrl: j['image']?.toString(), isCrypto: isCrypto, value: j['value'] is num ? (j['value'] as num).toDouble() : null, valueUsd: j['valueUsd'] is num ? (j['valueUsd'] as num).toDouble() : null, change: change, sparkline: spark);
  }
  double? get valueToman => value == null ? null : value! / 10;
  String get displayPrice {
    if (isCrypto) { final v = valueUsd; if (v == null) return '—'; if (v >= 1000) return '\$${_fmt(v, 0)}'; if (v >= 1) return '\$${v.toStringAsFixed(2)}'; return '\$${v.toStringAsFixed(4)}'; }
    return valueToman == null ? '—' : _fmt(valueToman!, 0);
  }
  String get changeText => '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%';
  String displayLabelFor(String lang) => lang == 'en' ? labelEn : labelFa;
  static String _fmt(double n, int decimals) { final s = n.toStringAsFixed(decimals); final parts = s.split('.'); final intPart = parts[0].replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},'); return parts.length > 1 ? '$intPart.${parts[1]}' : intPart; }
}

class ChatMessage {
  final int id; final String username, text; final bool isSystem;
  ChatMessage({required this.id, required this.username, required this.text, this.isSystem = false});
  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(id: j['id'], username: j['username'], text: j['text'], isSystem: j['is_system'] == 1);
}

// ═══════════════════════════════════════════════════════
//  APP STATE
// ═══════════════════════════════════════════════════════
class AppState extends ChangeNotifier {
  List<MarketAsset> iran = [], crypto = [];
  bool loading = true; String? error; Set<String> favorites = {};
  String lang = 'fa'; bool isDarkMode = true; int selectedTab = 0, pricesFilter = 0;
  String featuredCode = 'USD_RLS'; final FocusNode searchFocusNode = FocusNode();

  String? token, username, avatar; String bio = 'بدون بیوگرافی'; bool isAdmin = false;
  
  List<ChatMessage> chatMessages = [];
  bool isSendingMsg = false;

  List<MarketAsset> get all => [...iran, ...crypto];
  List<MarketAsset> get favList => all.where((a) => favorites.contains(a.code)).toList();
  MarketAsset? get featuredAsset => all.isEmpty ? null : all.firstWhere((a) => a.code == featuredCode, orElse: () => all.first);

  MarketAsset? byCode(String code) { for (var a in all) { if (a.code == code) return a; } return null; }
  void setTab(int index) { selectedTab = index; notifyListeners(); }
  void setPricesFilter(int index) { pricesFilter = index; notifyListeners(); }

  Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    favorites = (p.getStringList('favs') ?? []).toSet();
    lang = p.getString('lang') ?? 'fa'; isDarkMode = p.getBool('dark') ?? true;
    featuredCode = p.getString('featured') ?? 'USD_RLS';
    token = p.getString('token'); username = p.getString('username');
    avatar = p.getString('avatar'); bio = p.getString('bio') ?? 'بدون بیوگرافی'; isAdmin = p.getBool('isAdmin') ?? false;
    notifyListeners(); await refresh();
  }

  Future<void> refresh() async {
    loading = iran.isEmpty && crypto.isEmpty; error = null; notifyListeners();
    try { await Future.wait([_loadAssets(), _loadCrypto()]).timeout(const Duration(seconds: 15)); } 
    catch (e) { error = t('connError'); } finally { loading = false; notifyListeners(); }
  }

  Future<void> _loadAssets() async {
    try { final r = await http.get(Uri.parse(kAssetsUrl)).timeout(const Duration(seconds: 10)); if (r.statusCode == 200) { final data = jsonDecode(r.body); if (data['assets'] != null) iran = (data['assets'] as List).map((e) => MarketAsset.fromJson(Map<String, dynamic>.from(e))).toList(); } } catch (e) {}
  }
  Future<void> _loadCrypto() async {
    try { final r = await http.get(Uri.parse(kCryptoUrl)).timeout(const Duration(seconds: 10)); if (r.statusCode == 200) { final data = jsonDecode(r.body); if (data['assets'] != null) crypto = (data['assets'] as List).map((e) => MarketAsset.fromJson(Map<String, dynamic>.from(e))).toList(); } } catch (_) {}
  }

  Future<void> toggleFav(String code) async { favorites.contains(code) ? favorites.remove(code) : favorites.add(code); notifyListeners(); final p = await SharedPreferences.getInstance(); await p.setStringList('favs', favorites.toList()); }
  Future<void> setFeatured(String code) async { featuredCode = code; notifyListeners(); final p = await SharedPreferences.getInstance(); await p.setString('featured', code); }
  Future<void> toggleLang() async { lang = lang == 'fa' ? 'en' : 'fa'; notifyListeners(); final p = await SharedPreferences.getInstance(); await p.setString('lang', lang); }
  Future<void> toggleTheme() async { isDarkMode = !isDarkMode; notifyListeners(); final p = await SharedPreferences.getInstance(); await p.setBool('dark', isDarkMode); }

  // Auth Methods
  Future<String?> login(String user, String pass) async {
    try {
      final r = await http.post(Uri.parse(kLoginUrl), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'username': user, 'password': pass}));
      final data = jsonDecode(r.body);
      if (r.statusCode == 200 && data['success']) {
        token = data['token']; username = data['username']; isAdmin = data['isAdmin'] ?? false; avatar = data['avatar']; bio = data['bio'];
        final p = await SharedPreferences.getInstance();
        await p.setString('token', token!); await p.setString('username', username!); await p.setBool('isAdmin', isAdmin); await p.setString('avatar', avatar!); await p.setString('bio', bio);
        notifyListeners(); return null;
      }
      return data['error'] ?? 'خطا در ورود';
    } catch (e) { return 'خطای اتصال'; }
  }

  Future<String?> register(String user, String pass) async {
    try {
      final r = await http.post(Uri.parse(kRegisterUrl), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'username': user, 'password': pass}));
      final data = jsonDecode(r.body);
      if (r.statusCode == 200 && data['success']) {
        token = data['token']; username = data['username']; isAdmin = data['isAdmin'] ?? false; avatar = data['avatar']; bio = data['bio'];
        final p = await SharedPreferences.getInstance();
        await p.setString('token', token!); await p.setString('username', username!); await p.setBool('isAdmin', isAdmin); await p.setString('avatar', avatar!); await p.setString('bio', bio);
        notifyListeners(); return null;
      }
      return data['error'] ?? 'خطا در ثبت‌نام';
    } catch (e) { return 'خطای اتصال'; }
  }

  Future<void> updateProfile(String newAvatar, String newBio) async {
    try {
      final r = await http.post(Uri.parse(kUpdateProfileUrl), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}, body: jsonEncode({'avatar': newAvatar, 'bio': newBio}));
      if (r.statusCode == 200) {
        avatar = newAvatar; bio = newBio; notifyListeners();
        final p = await SharedPreferences.getInstance(); await p.setString('avatar', newAvatar); await p.setString('bio', newBio);
      }
    } catch (_) {}
  }

  Future<void> logout() async {
    token = null; username = null; isAdmin = false; avatar = null; bio = 'بدون بیوگرافی';
    final p = await SharedPreferences.getInstance(); await p.remove('token'); await p.remove('username'); await p.remove('isAdmin'); await p.remove('avatar'); await p.remove('bio');
    notifyListeners();
  }

  // Chat Methods (Optimistic)
  Future<void> fetchChatMessages() async {
    try {
      final r = await http.get(Uri.parse(kChatUrl));
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        if (data['success']) {
          chatMessages = (data['messages'] as List).map((e) => ChatMessage.fromJson(e)).toList();
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  Future<void> sendChatMessage(String text) async {
    if (token == null || text.trim().isEmpty) return;
    final tempId = -DateTime.now().millisecondsSinceEpoch;
    final tempMsg = ChatMessage(id: tempId, username: username!, text: text);
    chatMessages.add(tempMsg);
    isSendingMsg = true;
    notifyListeners();

    try {
      final r = await http.post(Uri.parse(kSendMsgUrl), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}, body: jsonEncode({'text': text}));
      if (r.statusCode != 200) {
        chatMessages.removeWhere((m) => m.id == tempId);
      }
    } catch (_) {
      chatMessages.removeWhere((m) => m.id == tempId);
    } finally {
      isSendingMsg = false;
      notifyListeners();
    }
  }

  // Admin Methods
  Future<Map<String, dynamic>> adminFetchStats() async {
    try { final r = await http.get(Uri.parse(kAdminStatsUrl), headers: {'Authorization': 'Bearer $token'}); if (r.statusCode == 200) return jsonDecode(r.body); } catch (_) {}
    return {};
  }
  Future<List<Map<String, dynamic>>> adminFetchUsers() async {
    try { final r = await http.get(Uri.parse(kAdminUsersUrl), headers: {'Authorization': 'Bearer $token'}); if (r.statusCode == 200) return List<Map<String, dynamic>>.from(jsonDecode(r.body)['users'] ?? []); } catch (_) {}
    return [];
  }
  Future<void> adminAction(String path, int id) async {
    try { await http.post(Uri.parse('$kAdminUsersUrl/$id/$path'), headers: {'Authorization': 'Bearer $token'}); } catch (_) {}
  }
  Future<void> adminDeleteUser(int id) async {
    try { await http.delete(Uri.parse('$kAdminUsersUrl/$id'), headers: {'Authorization': 'Bearer $token'}); } catch (_) {}
  }
  Future<void> adminDeleteMsg(int id) async {
    try { await http.delete(Uri.parse('$kBackend/api/admin/messages/$id'), headers: {'Authorization': 'Bearer $token'}); } catch (_) {}
  }
  Future<void> adminClearChat() async {
    try { await http.delete(Uri.parse(kAdminClearChatUrl), headers: {'Authorization': 'Bearer $token'}); } catch (_) {}
  }
  Future<void> adminBroadcast(String text) async {
    try { await http.post(Uri.parse(kAdminBroadcastUrl), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}, body: jsonEncode({'text': text})); } catch (_) {}
  }

  String t(String key) => S.get(key, lang);
}

// ═══════════════════════════════════════════════════════
//  MAIN APP
// ═══════════════════════════════════════════════════════
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.light));
  runApp(ChangeNotifierProvider(create: (_) => AppState()..init(), child: const PingMarketApp()));
}

class PingMarketApp extends StatefulWidget {
  const PingMarketApp({super.key});
  @override State<PingMarketApp> createState() => _PingMarketAppState();
}

class _PingMarketAppState extends State<PingMarketApp> {
  bool showSplash = true;
  @override void initState() { super.initState(); Timer(const Duration(milliseconds: 3500), () { if (mounted) setState(() => showSplash = false); }); }
  @override Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return MaterialApp(
      debugShowCheckedModeBanner: false, title: 'Ping Market',
      themeMode: state.isDarkMode ? ThemeMode.dark : ThemeMode.light, theme: lightTheme, darkTheme: darkTheme, locale: Locale(state.lang),
      home: AnimatedSwitcher(duration: const Duration(milliseconds: 800), child: showSplash ? const SplashScreen() : const AppShell()),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  SPLASH & SHELL
// ═══════════════════════════════════════════════════════
class SplashScreen extends StatefulWidget { const SplashScreen({super.key}); @override State<SplashScreen> createState() => _SplashScreenState(); }
class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController, _textController, _glowController;
  late Animation<double> _logoScale, _logoOpacity, _textOpacity, _glowOpacity;
  late Animation<Offset> _textSlide;

  @override void initState() {
    super.initState();
    _logoController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _logoScale = Tween(begin: 0.6, end: 1.0).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack));
    _logoOpacity = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeIn));
    _textController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _textSlide = Tween(begin: const Offset(0, 0.5), end: Offset.zero).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic));
    _textOpacity = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _textController, curve: Curves.easeIn));
    _glowController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _glowOpacity = Tween(begin: 0.3, end: 0.8).animate(CurvedAnimation(parent: _glowController, curve: Curves.easeInOut));
    _logoController.forward().then((_) { if (mounted) _textController.forward(); });
  }
  @override void dispose() { _logoController.dispose(); _textController.dispose(); _glowController.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) {
    return Scaffold(backgroundColor: C.bg, body: Stack(children: [
      Center(child: AnimatedBuilder(animation: _glowOpacity, builder: (context, child) => Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [C.primaryPurple.withOpacity(0.15 * _glowOpacity.value), Colors.transparent]))))),
      Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        ScaleTransition(scale: _logoScale, child: FadeTransition(opacity: _logoOpacity, child: Container(width: 140, height: 140, decoration: BoxDecoration(borderRadius: BorderRadius.circular(35), boxShadow: [BoxShadow(color: C.primaryPurple.withOpacity(0.4), blurRadius: 40, spreadRadius: 10), BoxShadow(color: C.primaryCyan.withOpacity(0.2), blurRadius: 20, spreadRadius: 2)]), child: ClipRRect(borderRadius: BorderRadius.circular(35), child: Image.asset('assets/logo.png', fit: BoxFit.cover))))),
        const SizedBox(height: 32),
        SlideTransition(position: _textSlide, child: FadeTransition(opacity: _textOpacity, child: Column(children: [RichText(text: const TextSpan(children: [TextSpan(text: 'Ping ', style: TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w900, letterSpacing: -1)), TextSpan(text: 'Market', style: TextStyle(color: C.primaryCyan, fontSize: 38, fontWeight: FontWeight.w900, letterSpacing: -1))])), const SizedBox(height: 8), const Text('Real-time Prices · Global Markets', style: TextStyle(color: Colors.white54, fontSize: 13, letterSpacing: 1.2))]))),
        const SizedBox(height: 60),
        FadeTransition(opacity: _textOpacity, child: SizedBox(width: 180, child: ClipRRect(borderRadius: BorderRadius.circular(10), child: const LinearProgressIndicator(minHeight: 4, backgroundColor: Color(0xFF1C1C2A), valueColor: AlwaysStoppedAnimation<Color>(C.primaryPurple))))),
      ])),
    ]));
  }
}

class AppShell extends StatelessWidget {
  const AppShell({super.key});
  @override Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: state.selectedTab, children: const [HomeTab(), PricesTab(), ChatTab(), FavoritesTab(), ProfileTab()]),
      bottomNavigationBar: _FloatingNav(index: state.selectedTab, onChanged: (i) => state.setTab(i)),
    );
  }
}

class _FloatingNav extends StatelessWidget {
  final int index; final ValueChanged<int> onChanged;
  const _FloatingNav({required this.index, required this.onChanged});
  @override Widget build(BuildContext context) {
    final state = context.watch<AppState>(); final isDark = state.isDarkMode; final t = state.t;
    final items = [
      (Icons.home_outlined, Icons.home_rounded, t('home')),
      (Icons.show_chart_outlined, Icons.show_chart_rounded, t('prices')),
      (Icons.forum_outlined, Icons.forum_rounded, t('chat')),
      (Icons.favorite_border_rounded, Icons.favorite_rounded, t('favs')),
      (Icons.person_outline_rounded, Icons.person_rounded, t('settings')),
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16), height: 72,
      decoration: BoxDecoration(color: isDark ? const Color(0xFF11111A).withOpacity(0.85) : Colors.white.withOpacity(0.95), borderRadius: BorderRadius.circular(25), border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05), width: 1.5), boxShadow: [BoxShadow(color: C.primaryPurple.withOpacity(0.15), blurRadius: 30, spreadRadius: 2)]),
      child: ClipRRect(borderRadius: BorderRadius.circular(25), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15), child: Row(children: List.generate(items.length, (i) {
        final sel = index == i; final (icon, active, label) = items[i];
        return Expanded(child: TapScale(onTap: () => onChanged(i), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(sel ? active : icon, color: sel ? C.primaryPurple : (isDark ? const Color(0xFFA0A0B0) : Colors.black54), size: 24),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, color: sel ? C.primaryPurple : (isDark ? const Color(0xFFA0A0B0) : Colors.black54), fontWeight: sel ? FontWeight.w700 : FontWeight.w500)),
        ])));
      })))),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  CORE WIDGETS
// ═══════════════════════════════════════════════════════
class TapScale extends StatefulWidget { final Widget child; final VoidCallback onTap; const TapScale({super.key, required this.child, required this.onTap}); @override State<TapScale> createState() => _TapScaleState(); }
class _TapScaleState extends State<TapScale> with SingleTickerProviderStateMixin {
  late AnimationController _c; late Animation<double> _s;
  @override void initState() { super.initState(); _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 100)); _s = Tween(begin: 1.0, end: 0.92).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut)); }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => GestureDetector(onTapDown: (_) => _c.forward(), onTapUp: (_) { _c.reverse(); widget.onTap(); }, onTapCancel: () => _c.reverse(), child: ScaleTransition(scale: _s, child: widget.child));
}

class StaggeredListItem extends StatelessWidget { final int index; final Widget child; const StaggeredListItem({super.key, required this.index, required this.child}); @override Widget build(BuildContext context) => TweenAnimationBuilder<double>(tween: Tween(begin: 0.0, end: 1.0), duration: Duration(milliseconds: 400 + (index * 50)), curve: Curves.easeOutCubic, builder: (context, value, child) => Opacity(opacity: value, child: Transform.translate(offset: Offset(0, 20 * (1 - value)), child: child)), child: child); }

class ShimmerSkeleton extends StatefulWidget { final double height; const ShimmerSkeleton({super.key, required this.height}); @override State<ShimmerSkeleton> createState() => _ShimmerSkeletonState(); }
class _ShimmerSkeletonState extends State<ShimmerSkeleton> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override void initState() { super.initState(); _c = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true); }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => AnimatedBuilder(animation: _c, builder: (context, child) => Container(height: widget.height, margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: Color.lerp(const Color(0xFF1C1C2A), const Color(0xFF2C2C3A), _c.value), borderRadius: BorderRadius.circular(20))));
}

class GlassCard extends StatelessWidget {
  final Widget child; final EdgeInsets padding;
  const GlassCard({super.key, required this.child, this.padding = const EdgeInsets.all(16)});
  @override Widget build(BuildContext context) {
    final isDark = context.watch<AppState>().isDarkMode;
    return Container(padding: padding, decoration: BoxDecoration(color: isDark ? const Color(0xFF1C1C2A).withOpacity(0.4) : Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)), boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]), child: child);
  }
}

class Sparkline extends StatelessWidget {
  final List<double> data; final Color color;
  const Sparkline({super.key, required this.data, required this.color});
  @override Widget build(BuildContext context) => SizedBox(width: 70, height: 30, child: CustomPaint(painter: _SparkPainter(data, color)));
}
class _SparkPainter extends CustomPainter {
  final List<double> data; final Color color; _SparkPainter(this.data, this.color);
  @override void paint(Canvas canvas, Size size) {
    if (data.length < 2) return; final minV = data.reduce(min).toDouble(); final maxV = data.reduce(max).toDouble(); final range = (maxV - minV) == 0 ? 1.0 : (maxV - minV);
    final path = Path(); final fillPath = Path()..moveTo(0, size.height);
    for (int i = 0; i < data.length; i++) { final x = (i / (data.length - 1)) * size.width; final y = size.height - ((data[i] - minV) / range) * size.height; if (i == 0) path.moveTo(x, y); else path.lineTo(x, y); fillPath.lineTo(x, y); }
    fillPath..lineTo(size.width, size.height)..close();
    canvas.drawPath(fillPath, Paint()..shader = LinearGradient(colors: [color.withOpacity(0.3), color.withOpacity(0)], begin: Alignment.topCenter, end: Alignment.bottomCenter).createShader(Rect.fromLTWH(0, 0, size.width, size.height)));
    canvas.drawPath(path, Paint()..color = color..strokeWidth = 2..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
  }
  @override bool shouldRepaint(covariant _SparkPainter old) => false;
}

class AssetIcon extends StatelessWidget {
  final MarketAsset asset; final double size;
  const AssetIcon({super.key, required this.asset, this.size = 44});
  @override Widget build(BuildContext context) {
    Widget iconWidget;
    if (asset.imageUrl != null && asset.imageUrl!.isNotEmpty) { iconWidget = Padding(padding: EdgeInsets.all(size * 0.15), child: Image.network(asset.imageUrl!, fit: BoxFit.contain, errorBuilder: (_,__,___) => _fallbackIcon())); }
    else if (asset.code == 'USD_RLS') { iconWidget = ClipOval(child: Image.network('https://flagcdn.com/w80/us.png', width: size * 0.7, height: size * 0.7, fit: BoxFit.cover, errorBuilder: (_,__,___) => _fallbackIcon())); }
    else if (asset.code == 'EUR_RLS') { iconWidget = ClipOval(child: Image.network('https://flagcdn.com/w80/eu.png', width: size * 0.7, height: size * 0.7, fit: BoxFit.cover, errorBuilder: (_,__,___) => _fallbackIcon())); }
    else if (asset.code == 'GOLD_18_RLS') { iconWidget = Icon(Icons.diamond_rounded, color: C.gold, size: size * 0.6); }
    else if (asset.code == 'COIN_EMAMI_RLS') { iconWidget = Icon(Icons.monetization_on_rounded, color: C.gold, size: size * 0.6); }
    else if (asset.symbol == 'BTC') { iconWidget = Icon(Icons.currency_bitcoin_rounded, color: Colors.orange, size: size * 0.6); }
    else { iconWidget = _fallbackIcon(); }
    return Hero(tag: 'icon_${asset.code}', child: Container(width: size, height: size, decoration: BoxDecoration(color: const Color(0xFF1C1C2A), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withOpacity(0.05), width: 1)), alignment: Alignment.center, child: iconWidget));
  }
  Widget _fallbackIcon() => Text(asset.icon, style: TextStyle(fontSize: size * 0.5));
}

// ═══════════════════════════════════════════════════════
//  TAB 1: HOME
// ═══════════════════════════════════════════════════════
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});
  @override Widget build(BuildContext context) {
    final state = context.watch<AppState>(); final isDark = state.isDarkMode; final t = state.t; final textColor = isDark ? Colors.white : Colors.black;
    return SafeArea(bottom: false, child: RefreshIndicator(
      color: C.primaryPurple, backgroundColor: isDark ? const Color(0xFF11111A) : Colors.white, onRefresh: state.refresh,
      child: ListView(padding: const EdgeInsets.fromLTRB(20, 10, 20, 100), children: [
        Row(children: [TapScale(onTap: () => _showNotif(context, state), child: GlassCard(padding: const EdgeInsets.all(10), child: Icon(Icons.notifications_none_rounded, color: textColor))), const Spacer(), Column(children: [RichText(text: TextSpan(children: [TextSpan(text: 'Ping ', style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.w800)), const TextSpan(text: 'Market', style: TextStyle(color: C.primaryPurple, fontSize: 20, fontWeight: FontWeight.w800))])), Text('Real-time Prices', style: TextStyle(color: isDark ? const Color(0xFFA0A0B0) : Colors.black54, fontSize: 10))]), const Spacer(), TapScale(onTap: state.toggleLang, child: GlassCard(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), child: Text(state.lang == 'fa' ? 'فا' : 'EN', style: TextStyle(color: textColor, fontWeight: FontWeight.bold))))]),
        const SizedBox(height: 24),
        if (!state.loading && state.featuredAsset != null) TapScale(onTap: () => _showFeaturedSelector(context, state), child: _buildFeaturedCard(state, state.featuredAsset!)) else if (state.loading) const ShimmerSkeleton(height: 160) else _buildErrorCard(context, state),
        const SizedBox(height: 20),
        TapScale(onTap: () { state.setTab(1); Future.delayed(const Duration(milliseconds: 300), () { state.searchFocusNode.requestFocus(); }); }, child: GlassCard(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), child: Row(children: [Icon(Icons.search_rounded, color: isDark ? const Color(0xFFA0A0B0) : Colors.black54), const SizedBox(width: 10), Expanded(child: Text(t('searchHint'), style: TextStyle(color: isDark ? const Color(0xFF606070) : Colors.black38))), Icon(Icons.tune_rounded, color: isDark ? const Color(0xFFA0A0B0) : Colors.black54)]))),
        const SizedBox(height: 24),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_quickAction(context, state, 'GOLD_18_RLS', 'طلا', Icons.diamond_rounded, C.gold), _quickAction(context, state, 'USD_RLS', 'دلار', Icons.attach_money_rounded, C.green), _quickAction(context, state, 'CG_BTC', 'بیت‌کوین', Icons.currency_bitcoin_rounded, Colors.orange), _allMarketsAction(context, state, 'همه بازارها', Icons.grid_view_rounded, Colors.blueAccent)]),
        const SizedBox(height: 24),
        if (state.loading) ...List.generate(3, (_) => const ShimmerSkeleton(height: 80)) else if (state.error != null && state.all.isEmpty) Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(children: [const Icon(Icons.wifi_off_rounded, color: C.red, size: 48), const SizedBox(height: 16), Text(state.error!, style: TextStyle(color: isDark ? const Color(0xFFA0A0B0) : Colors.black54), textAlign: TextAlign.center), const SizedBox(height: 16), ElevatedButton(onPressed: state.refresh, style: ElevatedButton.styleFrom(backgroundColor: C.primaryPurple), child: Text(t('retry')))]))) else if (state.all.isNotEmpty) ...state.all.take(4).toList().asMap().entries.map((e) => StaggeredListItem(index: e.key, child: _homePriceRow(context, state, e.value))),
      ]),
    ));
  }

  Widget _buildFeaturedCard(AppState state, MarketAsset asset) {
    final isUp = asset.change >= 0; final changeColor = isUp ? C.green : C.red;
    return Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF4A148C), Color(0xFF1A237E)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: C.primaryPurple.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))]),
      child: Stack(children: [
        Positioned(right: -20, bottom: -20, child: Icon(Icons.show_chart_rounded, size: 120, color: Colors.white.withOpacity(0.05))),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [AssetIcon(asset: asset, size: 40), const SizedBox(width: 12), Text(asset.displayLabelFor(state.lang), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)), const Spacer(), const Icon(Icons.touch_app_rounded, color: Colors.white54, size: 20)]),
          const SizedBox(height: 24), Text(asset.displayPrice, style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: -1)), const SizedBox(height: 8),
          Row(children: [Icon(isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, color: changeColor, size: 16), const SizedBox(width: 4), Text(asset.changeText, style: TextStyle(color: changeColor, fontSize: 14, fontWeight: FontWeight.bold))]),
        ]),
      ]),
    );
  }

  void _showFeaturedSelector(BuildContext context, AppState state) {
    showModalBottomSheet(context: context, backgroundColor: state.isDarkMode ? const Color(0xFF11111A) : Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))), builder: (ctx) {
      return SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(padding: const EdgeInsets.all(20), child: Text(state.t('selectFeatured'), style: TextStyle(color: state.isDarkMode ? Colors.white : Colors.black, fontSize: 16, fontWeight: FontWeight.bold))),
        Flexible(child: ListView.builder(shrinkWrap: true, itemCount: state.all.length, itemBuilder: (_, i) { final a = state.all[i]; return ListTile(leading: AssetIcon(asset: a, size: 40), title: Text(a.displayLabelFor(state.lang), style: TextStyle(color: state.isDarkMode ? Colors.white : Colors.black)), onTap: () { state.setFeatured(a.code); Navigator.pop(ctx); }); })),
      ]));
    });
  }

  Widget _quickAction(BuildContext context, AppState state, String code, String label, IconData fallbackIcon, Color color) {
    final asset = state.byCode(code) ?? state.byCode('CG_${code.replaceAll('CG_', '')}');
    return TapScale(onTap: () { if (asset != null) Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(asset: asset))); else { state.setPricesFilter(0); state.setTab(1); } }, child: GlassCard(padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16), child: Column(children: [if (asset != null) AssetIcon(asset: asset, size: 32) else Icon(fallbackIcon, color: color, size: 30), const SizedBox(height: 8), Text(label, style: TextStyle(color: state.isDarkMode ? Colors.white : Colors.black, fontSize: 11))])));
  }
  Widget _allMarketsAction(BuildContext context, AppState state, String label, IconData icon, Color color) {
    return TapScale(onTap: () { state.setPricesFilter(0); state.setTab(1); }, child: GlassCard(padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16), child: Column(children: [Icon(icon, color: color, size: 30), const SizedBox(height: 8), Text(label, style: TextStyle(color: state.isDarkMode ? Colors.white : Colors.black, fontSize: 11))])));
  }
  Widget _homePriceRow(BuildContext context, AppState state, MarketAsset a) {
    final isUp = a.change >= 0;
    return TapScale(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(asset: a))), child: Padding(padding: const EdgeInsets.only(bottom: 12), child: GlassCard(padding: const EdgeInsets.all(14), child: Row(children: [AssetIcon(asset: a, size: 46), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(a.displayLabelFor(state.lang), style: TextStyle(color: state.isDarkMode ? Colors.white : Colors.black, fontWeight: FontWeight.w600)), const SizedBox(height: 4), Text(a.displayPrice, style: TextStyle(color: state.isDarkMode ? const Color(0xFFA0A0B0) : Colors.black54, fontSize: 13))])), Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(a.changeText, style: TextStyle(color: isUp ? C.green : C.red, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Sparkline(data: a.sparkline, color: isUp ? C.green : C.red)]), const SizedBox(width: 8), Icon(Icons.chevron_right_rounded, color: state.isDarkMode ? const Color(0xFF606070) : Colors.black38)]))));
  }
  Widget _buildErrorCard(BuildContext context, AppState state) {
    return Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(children: [const Icon(Icons.wifi_off_rounded, color: C.red, size: 48), const SizedBox(height: 16), Text(state.error ?? 'Error', style: TextStyle(color: state.isDarkMode ? const Color(0xFFA0A0B0) : Colors.black54), textAlign: TextAlign.center), const SizedBox(height: 16), ElevatedButton(onPressed: state.refresh, style: ElevatedButton.styleFrom(backgroundColor: C.primaryPurple), child: Text(state.t('retry')))])));
  }
  void _showNotif(BuildContext context, AppState state) {
    showModalBottomSheet(context: context, backgroundColor: state.isDarkMode ? const Color(0xFF11111A) : Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (_) => Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.notifications_none_rounded, color: C.primaryPurple, size: 40), const SizedBox(height: 16), Text(state.t('notifications'), style: TextStyle(color: state.isDarkMode ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 8), Text(state.t('noNotif'), style: TextStyle(color: state.isDarkMode ? const Color(0xFFA0A0B0) : Colors.black54))])));
  }
}

// ═══════════════════════════════════════════════════════
//  TAB 2: PRICES
// ═══════════════════════════════════════════════════════
class PricesTab extends StatefulWidget { const PricesTab({super.key}); @override State<PricesTab> createState() => _PricesTabState(); }
class _PricesTabState extends State<PricesTab> {
  String _query = '';
  @override Widget build(BuildContext context) {
    final state = context.watch<AppState>(); final isDark = state.isDarkMode; final t = state.t; final textColor = isDark ? Colors.white : Colors.black;
    List<MarketAsset> list = state.all; if (state.pricesFilter == 1) list = state.iran; if (state.pricesFilter == 2) list = state.crypto;
    if (_query.isNotEmpty) { list = list.where((a) => a.displayLabelFor(state.lang).toLowerCase().contains(_query.toLowerCase())).toList(); }
    return SafeArea(bottom: false, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 10), child: Row(children: [const Icon(Icons.bar_chart_rounded, color: C.primaryCyan, size: 28), const SizedBox(width: 10), Text(t('prices'), style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.bold))])),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: GlassCard(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), child: TextField(focusNode: state.searchFocusNode, onChanged: (v) => setState(() => _query = v), style: TextStyle(color: textColor), decoration: InputDecoration(hintText: t('searchHint'), hintStyle: TextStyle(color: isDark ? const Color(0xFF606070) : Colors.black38), border: InputBorder.none, icon: Icon(Icons.search_rounded, color: isDark ? const Color(0xFFA0A0B0) : Colors.black54))))),
      const SizedBox(height: 12),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Row(children: [_filterPill(state, t('all'), 0), _filterPill(state, t('currency'), 1), _filterPill(state, t('crypto'), 2)])),
      const SizedBox(height: 16),
      Expanded(child: RefreshIndicator(color: C.primaryPurple, backgroundColor: isDark ? const Color(0xFF11111A) : Colors.white, onRefresh: state.refresh, child: state.loading ? ListView(padding: const EdgeInsets.symmetric(horizontal: 20), children: const [ShimmerSkeleton(height: 80), ShimmerSkeleton(height: 80), ShimmerSkeleton(height: 80)]) : list.isEmpty ? Center(child: Text(t('noResults'), style: TextStyle(color: isDark ? const Color(0xFFA0A0B0) : Colors.black54))) : ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 100), children: list.asMap().entries.map((e) => StaggeredListItem(index: e.key > 10 ? 10 : e.key, child: _priceRow(context, state, e.value))).toList()))),
    ]));
  }
  Widget _priceRow(BuildContext context, AppState state, MarketAsset a) {
    final isUp = a.change >= 0;
    return TapScale(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(asset: a))), child: Padding(padding: const EdgeInsets.only(bottom: 12), child: GlassCard(padding: const EdgeInsets.all(14), child: Row(children: [AssetIcon(asset: a, size: 46), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(a.displayLabelFor(state.lang), style: TextStyle(color: state.isDarkMode ? Colors.white : Colors.black, fontWeight: FontWeight.w600)), const SizedBox(height: 4), Text(a.displayPrice, style: TextStyle(color: state.isDarkMode ? const Color(0xFFA0A0B0) : Colors.black54, fontSize: 13))])), Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(a.changeText, style: TextStyle(color: isUp ? C.green : C.red, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Sparkline(data: a.sparkline, color: isUp ? C.green : C.red)]), const SizedBox(width: 8), Icon(Icons.chevron_right_rounded, color: state.isDarkMode ? const Color(0xFF606070) : Colors.black38)]))));
  }
  Widget _filterPill(AppState state, String label, int idx) {
    final sel = state.pricesFilter == idx;
    return TapScale(onTap: () => state.setPricesFilter(idx), child: Container(margin: const EdgeInsets.only(left: 10), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10), decoration: BoxDecoration(gradient: sel ? const LinearGradient(colors: [C.primaryPurple, C.primaryCyan]) : null, color: sel ? null : (state.isDarkMode ? const Color(0xFF1C1C2A) : Colors.white), borderRadius: BorderRadius.circular(20), border: sel ? null : Border.all(color: state.isDarkMode ? Colors.white10 : Colors.black12)), child: Text(label, style: TextStyle(color: sel ? Colors.white : (state.isDarkMode ? const Color(0xFFA0A0B0) : Colors.black54), fontWeight: FontWeight.bold))));
  }
}

// ═══════════════════════════════════════════════════════
//  TAB 3: CHAT ROOM
// ═══════════════════════════════════════════════════════
class ChatTab extends StatefulWidget { const ChatTab({super.key}); @override State<ChatTab> createState() => _ChatTabState(); }
class _ChatTabState extends State<ChatTab> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  Timer? _pollingTimer;

  @override void initState() {
    super.initState();
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (_) => _fetchMessages());
    _fetchMessages();
  }
  @override void dispose() { _pollingTimer?.cancel(); _msgCtrl.dispose(); _scrollCtrl.dispose(); super.dispose(); }

  void _fetchMessages() async {
    if (!mounted) return;
    await context.read<AppState>().fetchChatMessages();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override Widget build(BuildContext context) {
    final state = context.watch<AppState>(); final isDark = state.isDarkMode; final t = state.t; final textColor = isDark ? Colors.white : Colors.black;

    if (state.chatMessages.isNotEmpty) _scrollToBottom();

    return SafeArea(bottom: false, child: Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 10), child: Row(children: [const Icon(Icons.forum_rounded, color: C.primaryCyan, size: 28), const SizedBox(width: 10), Text(t('chat'), style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.bold))])),
      
      Expanded(child: Container(margin: const EdgeInsets.symmetric(horizontal: 20), decoration: BoxDecoration(color: isDark ? const Color(0xFF11111A).withOpacity(0.6) : Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black12)), child: ClipRRect(borderRadius: BorderRadius.circular(24), child: ListView.builder(
        controller: _scrollCtrl, padding: const EdgeInsets.all(16), itemCount: state.chatMessages.length,
        itemBuilder: (context, index) {
          final msg = state.chatMessages[index];
          final isMe = msg.username == state.username;
          return _buildMessageBubble(msg, isMe, isDark);
        },
      )))),

      Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 100), child: state.token == null 
        ? Center(child: TextButton.icon(onPressed: () => state.setTab(4), icon: const Icon(Icons.login_rounded, color: C.primaryPurple), label: Text(t('loginToChat'), style: const TextStyle(color: C.primaryPurple, fontWeight: FontWeight.bold))))
        : Container(decoration: BoxDecoration(color: isDark ? const Color(0xFF1C1C2A) : Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]), child: Row(children: [
            Expanded(child: TextField(controller: _msgCtrl, style: TextStyle(color: textColor), decoration: InputDecoration(hintText: t('typeMessage'), hintStyle: TextStyle(color: isDark ? const Color(0xFF606070) : Colors.black38), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16)), onSubmitted: (_) { final txt = _msgCtrl.text.trim(); if(txt.isNotEmpty) { _msgCtrl.clear(); state.sendChatMessage(txt); _scrollToBottom(); } })),
            TapScale(onTap: () { final txt = _msgCtrl.text.trim(); if(txt.isNotEmpty) { _msgCtrl.clear(); state.sendChatMessage(txt); _scrollToBottom(); } }, child: Container(margin: const EdgeInsets.all(6), padding: const EdgeInsets.all(12), decoration: const BoxDecoration(gradient: LinearGradient(colors: [C.primaryPurple, C.primaryCyan]), shape: BoxShape.circle), child: const Icon(Icons.send_rounded, color: Colors.white, size: 20))),
          ])),
      ),
    ]));
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isMe, bool isDark) {
    if (msg.isSystem) {
      return Center(child: Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), decoration: BoxDecoration(color: C.gold.withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: C.gold.withOpacity(0.3))), child: Text(msg.text, style: const TextStyle(color: C.gold, fontSize: 12, fontWeight: FontWeight.bold))));
    }
    return Align(alignment: isMe ? AlignmentDirectional.centerStart : AlignmentDirectional.centerEnd, child: Container(
      margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
      decoration: BoxDecoration(gradient: isMe ? const LinearGradient(colors: [C.primaryPurple, C.primaryCyan]) : null, color: isMe ? null : (isDark ? const Color(0xFF2C2C3A) : const Color(0xFFF0F0F5)), borderRadius: BorderRadius.only(topLeft: const Radius.circular(16), topRight: const Radius.circular(16), bottomLeft: Radius.circular(isMe ? 16 : 4), bottomRight: Radius.circular(isMe ? 4 : 16))),
      child: Column(crossAxisAlignment: isMe ? CrossAxisAlignment.start : CrossAxisAlignment.end, children: [
        if (!isMe) Text(msg.username, style: const TextStyle(color: C.primaryPurple, fontSize: 11, fontWeight: FontWeight.bold)),
        if (!isMe) const SizedBox(height: 4),
        Text(msg.text, style: TextStyle(color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black87), fontSize: 14)),
      ]),
    ));
  }
}

// ═══════════════════════════════════════════════════════
//  TAB 4: FAVORITES
// ═══════════════════════════════════════════════════════
class FavoritesTab extends StatelessWidget {
  const FavoritesTab({super.key});
  @override Widget build(BuildContext context) {
    final state = context.watch<AppState>(); final isDark = state.isDarkMode; final t = state.t; final textColor = isDark ? Colors.white : Colors.black;
    return SafeArea(bottom: false, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 10), child: Row(children: [const Icon(Icons.star_rounded, color: C.primaryCyan, size: 28), const SizedBox(width: 10), Text(t('favs'), style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.bold))])),
      Expanded(child: state.favList.isEmpty ? Center(child: Text(t('noFavs'), style: TextStyle(color: isDark ? const Color(0xFFA0A0B0) : Colors.black54))) : ListView(padding: const EdgeInsets.fromLTRB(20, 10, 20, 100), children: state.favList.asMap().entries.map((e) => StaggeredListItem(index: e.key, child: TapScale(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(asset: e.value))), child: Padding(padding: const EdgeInsets.only(bottom: 12), child: GlassCard(padding: const EdgeInsets.all(14), child: Row(children: [AssetIcon(asset: e.value, size: 46), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(e.value.displayLabelFor(state.lang), style: TextStyle(color: textColor, fontWeight: FontWeight.w600)), const SizedBox(height: 4), Text(e.value.displayPrice, style: TextStyle(color: isDark ? const Color(0xFFA0A0B0) : Colors.black54, fontSize: 13))])), TapScale(onTap: () => state.toggleFav(e.value.code), child: const Padding(padding: EdgeInsets.all(4.0), child: Icon(Icons.delete_outline_rounded, color: C.red)))])))))).toList())),
    ]));
  }
}

// ═══════════════════════════════════════════════════════
//  TAB 5: PROFILE & AUTH
// ═══════════════════════════════════════════════════════
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});
  @override Widget build(BuildContext context) {
    final state = context.watch<AppState>(); final isDark = state.isDarkMode; final t = state.t; final textColor = isDark ? Colors.white : Colors.black;
    return SafeArea(bottom: false, child: ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 100), children: [
      Row(children: [const Icon(Icons.person_rounded, color: C.primaryCyan, size: 28), const SizedBox(width: 10), Text(t('settings'), style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.bold))]),
      const SizedBox(height: 30),
      
      if (state.token == null) const AuthForm() else _buildProfileCard(context, state, isDark, textColor),
      
      const SizedBox(height: 24),
      _settingItem(context, state, Icons.wb_sunny_rounded, t('darkMode'), trailing: Icon(isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded, color: C.primaryPurple), onTap: state.toggleTheme),
      _settingItem(context, state, Icons.language_rounded, t('language'), trailing: Text(state.lang == 'fa' ? 'فارسی' : 'English', style: TextStyle(color: isDark ? const Color(0xFFA0A0B0) : Colors.black54)), onTap: state.toggleLang),
      
      if (state.isAdmin) ...[
        const SizedBox(height: 24),
        Text(t('adminPanel'), style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _settingItem(context, state, Icons.admin_panel_settings_rounded, t('adminPanel'), trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: C.primaryPurple), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPanelScreen()))),
      ],
    ]));
  }

  Widget _buildProfileCard(BuildContext context, AppState state, bool isDark, Color textColor) {
    return GlassCard(padding: const EdgeInsets.all(20), child: Column(children: [
      Row(children: [
        Container(width: 60, height: 60, decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [C.primaryPurple, C.primaryCyan])), alignment: Alignment.center, child: Text(state.avatar ?? '👤', style: const TextStyle(fontSize: 30))),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(state.username ?? '', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
          if (state.isAdmin) Text(state.t('admin'), style: const TextStyle(color: C.gold, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4), Text(state.bio, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12)),
        ])),
        TapScale(onTap: state.logout, child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: C.red.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.logout_rounded, color: C.red, size: 20))),
      ]),
      const SizedBox(height: 16),
      Divider(color: isDark ? Colors.white12 : Colors.black12),
      const SizedBox(height: 12),
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        _statItem(context, '⭐', '${state.favList.length}', 'علاقه‌مندی‌ها'),
        _statItem(context, '💬', '${state.chatMessages.where((m) => m.username == state.username).length}', 'پیام‌ها'),
      ]),
      const SizedBox(height: 16),
      TapScale(onTap: () => _showEditProfile(context, state), child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(border: Border.all(color: C.primaryPurple), borderRadius: BorderRadius.circular(12)), alignment: Alignment.center,
        child: Text(state.t('editProfile'), style: const TextStyle(color: C.primaryPurple, fontWeight: FontWeight.bold)),
      )),
    ]));
  }

  Widget _statItem(BuildContext context, String icon, String value, String label) {
    final isDark = context.watch<AppState>().isDarkMode;
    return Column(children: [Text(icon, style: const TextStyle(fontSize: 20)), const SizedBox(height: 4), Text(value, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16, fontWeight: FontWeight.bold)), Text(label, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 11))]);
  }

  void _showEditProfile(BuildContext context, AppState state) {
    final TextEditingController bioCtrl = TextEditingController(text: state.bio);
    String selectedAvatar = state.avatar ?? '👤';
    final avatars = ['👤', '😎', '🦊', '🐱', '🐼', '🦁', '💼', '🚀', '🧠', '🔥'];

    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: state.isDarkMode ? const Color(0xFF1C1C2A) : Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))), builder: (ctx) {
      return StatefulBuilder(builder: (context, setSheet) => Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(state.t('editProfile'), style: TextStyle(color: state.isDarkMode ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Wrap(spacing: 10, runSpacing: 10, children: avatars.map((e) => GestureDetector(
          onTap: () => setSheet(() => selectedAvatar = e),
          child: Container(width: 50, height: 50, decoration: BoxDecoration(shape: BoxShape.circle, color: selectedAvatar == e ? C.primaryPurple : (state.isDarkMode ? Colors.white10 : Colors.black12)), alignment: Alignment.center, child: Text(e, style: const TextStyle(fontSize: 24))),
        )).toList()),
        const SizedBox(height: 20),
        TextField(controller: bioCtrl, style: TextStyle(color: state.isDarkMode ? Colors.white : Colors.black), maxLines: 2, decoration: InputDecoration(hintText: state.t('bio'), hintStyle: TextStyle(color: state.isDarkMode ? Colors.white38 : Colors.black38), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: TextButton(onPressed: () => Navigator.pop(ctx), child: Text(state.t('cancel'), style: const TextStyle(color: Colors.grey)))),
          const SizedBox(width: 10),
          Expanded(child: ElevatedButton(
            onPressed: () { state.updateProfile(selectedAvatar, bioCtrl.text); Navigator.pop(ctx); },
            style: ElevatedButton.styleFrom(backgroundColor: C.primaryPurple, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text(state.t('save'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )),
        ]),
        const SizedBox(height: 20),
      ])));
    });
  }

  Widget _settingItem(BuildContext context, AppState state, IconData icon, String title, {Widget? trailing, required VoidCallback onTap}) {
    final isDark = state.isDarkMode;
    return TapScale(onTap: onTap, child: Padding(padding: const EdgeInsets.only(bottom: 12), child: GlassCard(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), child: Row(children: [Icon(icon, color: isDark ? const Color(0xFFA0A0B0) : Colors.black54), const SizedBox(width: 16), Expanded(child: Text(title, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w600))), if (trailing != null) trailing, if (trailing == null) Icon(Icons.chevron_left_rounded, color: isDark ? const Color(0xFF606070) : Colors.black38)]))));
  }
}

class AuthForm extends StatefulWidget { const AuthForm({super.key}); @override State<AuthForm> createState() => _AuthFormState(); }
class _AuthFormState extends State<AuthForm> {
  bool _isLogin = true; final _userCtrl = TextEditingController(); final _passCtrl = TextEditingController();
  bool _loading = false; String? _error;

  void _submit() async {
    setState(() { _loading = true; _error = null; });
    final state = context.read<AppState>();
    final err = _isLogin ? await state.login(_userCtrl.text, _passCtrl.text) : await state.register(_userCtrl.text, _passCtrl.text);
    if (!mounted) return;
    setState(() { _loading = false; _error = err; });
  }

  @override Widget build(BuildContext context) {
    final isDark = context.watch<AppState>().isDarkMode; final textColor = isDark ? Colors.white : Colors.black; final t = context.read<AppState>().t;
    return GlassCard(padding: const EdgeInsets.all(20), child: Column(children: [
      Text(_isLogin ? t('loginTitle') : t('registerTitle'), style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 20),
      TextField(controller: _userCtrl, style: TextStyle(color: textColor), decoration: InputDecoration(labelText: t('username'), labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54), enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black26), borderRadius: BorderRadius.circular(12)), focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: C.primaryPurple), borderRadius: BorderRadius.circular(12)))),
      const SizedBox(height: 12),
      TextField(controller: _passCtrl, obscureText: true, style: TextStyle(color: textColor), decoration: InputDecoration(labelText: t('password'), labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54), enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black26), borderRadius: BorderRadius.circular(12)), focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: C.primaryPurple), borderRadius: BorderRadius.circular(12)))),
      if (_error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, style: const TextStyle(color: C.red, fontSize: 12))),
      const SizedBox(height: 20),
      TapScale(onTap: _loading ? () {} : _submit, child: Container(padding: const EdgeInsets.symmetric(vertical: 16), decoration: BoxDecoration(gradient: const LinearGradient(colors: [C.primaryPurple, C.primaryCyan]), borderRadius: BorderRadius.circular(12)), alignment: Alignment.center, child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(_isLogin ? t('login') : t('register'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)))),
      const SizedBox(height: 12),
      TextButton(onPressed: () => setState(() => _isLogin = !_isLogin), child: Text(_isLogin ? t('noAccount') : t('haveAccount'), style: const TextStyle(color: C.primaryCyan))),
    ]));
  }
}

// ═══════════════════════════════════════════════════════
//  ADMIN PANEL (10 FEATURES)
// ═══════════════════════════════════════════════════════
class AdminPanelScreen extends StatefulWidget { const AdminPanelScreen({super.key}); @override State<AdminPanelScreen> createState() => _AdminPanelScreenState(); }
class _AdminPanelScreenState extends State<AdminPanelScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;

  @override void initState() { super.initState(); _tabController = TabController(length: 3, vsync: this); _loadData(); }

  Future<void> _loadData() async {
    final state = context.read<AppState>();
    final stats = await state.adminFetchStats();
    final users = await state.adminFetchUsers();
    if (mounted) setState(() { _stats = stats; _users = users; _loading = false; });
  }

  @override Widget build(BuildContext context) {
    final state = context.watch<AppState>(); final isDark = state.isDarkMode; final t = state.t;
    return Scaffold(
      backgroundColor: isDark ? C.bg : const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: Text(t('adminPanel'), style: const TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(controller: _tabController, indicatorColor: C.primaryPurple, labelColor: C.primaryPurple, unselectedLabelColor: Colors.grey, tabs: [
          Tab(text: t('adminDashboard'), icon: const Icon(Icons.dashboard_rounded, size: 20)),
          Tab(text: t('adminUsers'), icon: const Icon(Icons.people_rounded, size: 20)),
          Tab(text: t('adminChat'), icon: const Icon(Icons.forum_rounded, size: 20)),
        ]),
      ),
      body: _loading ? const Center(child: CircularProgressIndicator()) : TabBarView(controller: _tabController, children: [
        _buildDashboard(state, t),
        _buildUsersTab(state, t),
        _buildChatTab(state, t),
      ]),
    );
  }

  Widget _buildDashboard(AppState state, String Function(String) t) {
    final isDark = state.isDarkMode;
    return ListView(padding: const EdgeInsets.all(20), children: [
      Row(children: [
        Expanded(child: _statCard('👥', _stats['users']?.toString() ?? '0', t('totalUsers'), C.primaryPurple, isDark)),
        const SizedBox(width: 12),
        Expanded(child: _statCard('💬', _stats['messages']?.toString() ?? '0', t('totalMsgs'), C.primaryCyan, isDark)),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _statCard('🚫', _stats['banned']?.toString() ?? '0', t('bannedUsers'), C.red, isDark)),
        const SizedBox(width: 12),
        Expanded(child: _statCard('⚡', 'Active', 'Status', C.green, isDark)),
      ]),
      const SizedBox(height: 30),
      Text(t('adminBroadcast'), style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      GlassCard(child: Column(children: [
        TextField(controller: TextEditingController(), style: TextStyle(color: isDark ? Colors.white : Colors.black), maxLines: 2, decoration: InputDecoration(hintText: t('broadcastHint'), hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), onSubmitted: (v) { state.adminBroadcast(v); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('پیام ارسال شد'))); }),
        const SizedBox(height: 12),
        ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.send_rounded), label: Text(t('send')), style: ElevatedButton.styleFrom(backgroundColor: C.primaryPurple, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 45))),
      ])),
    ]);
  }

  Widget _statCard(String icon, String value, String label, Color color, bool isDark) {
    return GlassCard(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(icon, style: const TextStyle(fontSize: 24)), const SizedBox(height: 12),
      Text(value, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 22, fontWeight: FontWeight.bold)),
      Text(label, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12)),
      const SizedBox(height: 8), Container(height: 4, width: 40, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
    ]));
  }

  Widget _buildUsersTab(AppState state, String Function(String) t) {
    final isDark = state.isDarkMode;
    return ListView.builder(padding: const EdgeInsets.all(16), itemCount: _users.length, itemBuilder: (context, i) {
      final u = _users[i];
      final isSelf = u['username'] == state.username;
      return GlassCard(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(backgroundColor: C.primaryPurple.withOpacity(0.2), child: Text(u['username'][0].toUpperCase(), style: const TextStyle(color: C.primaryPurple, fontWeight: FontWeight.bold))),
        title: Text(u['username'], style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
        subtitle: Row(children: [
          if (u['is_admin'] == 1) _badge(t('admin'), C.gold, isDark),
          if (u['is_banned'] == 1) _badge(t('banned'), C.red, isDark),
        ]),
        trailing: isSelf ? null : PopupMenuButton<String>(
          icon: Icon(Icons.more_vert_rounded, color: isDark ? Colors.white54 : Colors.black54),
          onSelected: (val) async {
            if (val == 'promote') await state.adminAction('promote', u['id']);
            if (val == 'demote') await state.adminAction('demote', u['id']);
            if (val == 'ban') await state.adminAction('ban', u['id']);
            if (val == 'unban') await state.adminAction('unban', u['id']);
            if (val == 'delete') await state.adminDeleteUser(u['id']);
            _loadData();
          },
          itemBuilder: (ctx) => [
            if (u['is_admin'] == 0) const PopupMenuItem(value: 'promote', child: Text('ارتقا به ادمین')),
            if (u['is_admin'] == 1) const PopupMenuItem(value: 'demote', child: Text('سلب ادمینی')),
            if (u['is_banned'] == 0) const PopupMenuItem(value: 'ban', child: Text('مسدود کردن', style: TextStyle(color: Colors.orange))),
            if (u['is_banned'] == 1) const PopupMenuItem(value: 'unban', child: Text('رفع مسدودی', style: TextStyle(color: Colors.green))),
            const PopupMenuItem(value: 'delete', child: Text('حذف کامل', style: TextStyle(color: Colors.red))),
          ],
        ),
      ));
    });
  }

  Widget _badge(String text, Color color, bool isDark) {
    return Container(margin: const EdgeInsets.only(left: 6), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(8)), child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)));
  }

  Widget _buildChatTab(AppState state, String Function(String) t) {
    final isDark = state.isDarkMode;
    return Column(children: [
      Padding(padding: const EdgeInsets.all(16), child: Row(children: [
        Expanded(child: ElevatedButton.icon(onPressed: () async { await state.adminClearChat(); state.fetchChatMessages(); _loadData(); }, icon: const Icon(Icons.delete_sweep_rounded), label: Text(t('clearChat')), style: ElevatedButton.styleFrom(backgroundColor: C.red, foregroundColor: Colors.white))),
      ])),
      Expanded(child: ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: state.chatMessages.length, itemBuilder: (context, i) {
        final m = state.chatMessages[i];
        return GlassCard(padding: const EdgeInsets.all(12), child: ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(m.username, style: const TextStyle(color: C.primaryPurple, fontSize: 12, fontWeight: FontWeight.bold)),
          subtitle: Text(m.text, style: TextStyle(color: isDark ? Colors.white : Colors.black)),
          trailing: IconButton(icon: const Icon(Icons.delete_rounded, color: C.red), onPressed: () async { await state.adminDeleteMsg(m.id); state.fetchChatMessages(); _loadData(); }),
        ));
      })),
    ]);
  }
}

// ═══════════════════════════════════════════════════════
//  DETAIL SCREEN
// ═══════════════════════════════════════════════════════
class DetailScreen extends StatefulWidget { final MarketAsset asset; const DetailScreen({super.key, required this.asset}); @override State<DetailScreen> createState() => _DetailScreenState(); }
class _DetailScreenState extends State<DetailScreen> {
  int _rangeIdx = 0; static const _ranges = ['1D', '1W', '1M', '3M', '1Y'];
  @override Widget build(BuildContext context) {
    final state = context.watch<AppState>(); final isDark = state.isDarkMode; final a = widget.asset; final t = state.t;
    final isUp = a.change >= 0; final changeColor = isUp ? C.green : C.red; final isFav = state.favorites.contains(a.code); final textColor = isDark ? Colors.white : Colors.black;
    final base = a.sparkline; final mult = [1, 2, 4, 12, 30][_rangeIdx]; final ext = List<double>.from(base);
    for (int k = 0; k < mult - 1; k++) { final r = Random(a.code.hashCode + k); for (int i = 0; i < base.length; i++) { ext.add(ext.last + (r.nextDouble() - 0.48) * 3); } }
    final high = ext.reduce(max).toDouble(); final low = ext.reduce(min).toDouble();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF05050A) : const Color(0xFFF4F6FA),
      appBar: AppBar(leading: TapScale(onTap: () => Navigator.pop(context), child: Icon(Icons.arrow_back_rounded, color: textColor)), title: Text(a.displayLabelFor(state.lang), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textColor)), actions: [TapScale(onTap: () => state.toggleFav(a.code), child: Padding(padding: const EdgeInsets.all(12.0), child: Icon(isFav ? Icons.star_rounded : Icons.star_border_rounded, color: C.gold)))]),
      body: SafeArea(child: ListView(padding: const EdgeInsets.fromLTRB(20, 10, 20, 30), children: [
        GlassCard(padding: const EdgeInsets.all(20), child: Row(children: [AssetIcon(asset: a, size: 60), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(a.displayLabelFor(state.lang), style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14)), const SizedBox(height: 6), Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [Text(a.displayPrice, style: TextStyle(color: textColor, fontSize: 28, fontWeight: FontWeight.w900)), const SizedBox(width: 6), Text(a.isCrypto ? 'USD' : t('toman'), style: TextStyle(color: isDark ? Colors.white54 : Colors.black38, fontSize: 14))])]))])),
        const SizedBox(height: 20),
        Row(children: [Icon(isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded, color: changeColor, size: 20), const SizedBox(width: 6), Text(a.changeText, style: TextStyle(color: changeColor, fontSize: 16, fontWeight: FontWeight.w800))]),
        const SizedBox(height: 24),
        Row(children: List.generate(_ranges.length, (i) { final sel = _rangeIdx == i; return Expanded(child: TapScale(onTap: () => setState(() => _rangeIdx = i), child: Container(margin: const EdgeInsets.symmetric(horizontal: 4), padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: sel ? C.primaryPurple : (isDark ? const Color(0xFF1C1C2A) : Colors.white), borderRadius: BorderRadius.circular(12), border: Border.all(color: sel ? C.primaryCyan : (isDark ? Colors.white10 : Colors.black12))), alignment: Alignment.center, child: Text(_ranges[i], style: TextStyle(color: sel ? Colors.white : (isDark ? const Color(0xFFA0A0B0) : Colors.black54), fontSize: 12, fontWeight: FontWeight.bold))))); })),
        const SizedBox(height: 24),
        GlassCard(padding: const EdgeInsets.all(16), child: Column(children: [SizedBox(height: 200, child: CustomPaint(painter: _ChartPainter(ext, changeColor), child: const SizedBox.expand())), const SizedBox(height: 12), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(low.toStringAsFixed(1), style: TextStyle(color: isDark ? const Color(0xFF606070) : Colors.black38, fontSize: 11)), Text(high.toStringAsFixed(1), style: TextStyle(color: isDark ? const Color(0xFF606070) : Colors.black38, fontSize: 11))])])),
        const SizedBox(height: 24),
        GlassCard(padding: const EdgeInsets.all(16), child: Column(children: [_statRow(t('currentPrice'), a.displayPrice, textColor, isDark), Divider(height: 24, color: isDark ? Colors.white.withOpacity(0.05) : Colors.black12), _statRow(t('dailyChange'), a.changeText, changeColor, isDark)])),
        const SizedBox(height: 30),
        TapScale(onTap: () => state.toggleFav(a.code), child: Container(padding: const EdgeInsets.symmetric(vertical: 16), decoration: BoxDecoration(gradient: isFav ? null : const LinearGradient(colors: [C.primaryPurple, C.primaryCyan]), color: isFav ? (isDark ? const Color(0xFF1C1C2A) : Colors.white) : null, borderRadius: BorderRadius.circular(16), border: isFav ? Border.all(color: C.primaryPurple) : null), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(isFav ? Icons.star_rounded : Icons.star_border_rounded, color: isFav ? C.primaryPurple : Colors.white), const SizedBox(width: 8), Text(isFav ? t('removeFromWatch') : t('addToWatch'), style: TextStyle(color: isFav ? C.primaryPurple : Colors.white, fontWeight: FontWeight.bold, fontSize: 15))]))),
      ])),
    );
  }
  Widget _statRow(String label, String value, Color color, bool isDark) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: TextStyle(color: isDark ? const Color(0xFFA0A0B0) : Colors.black54, fontSize: 14)), Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold))]);
}

class _ChartPainter extends CustomPainter {
  final List<double> data; final Color color; _ChartPainter(this.data, this.color);
  @override void paint(Canvas canvas, Size size) {
    if (data.length < 2) return; final minV = data.reduce(min).toDouble(); final maxV = data.reduce(max).toDouble(); final range = (maxV - minV) == 0 ? 1.0 : (maxV - minV);
    final linePath = Path(); final fillPath = Path()..moveTo(0, size.height);
    for (int i = 0; i < data.length; i++) { final x = (i / (data.length - 1)) * size.width; final y = size.height - ((data[i] - minV) / range) * (size.height - 10) - 5; if (i == 0) linePath.moveTo(x, y); else linePath.lineTo(x, y); fillPath.lineTo(x, y); }
    fillPath..lineTo(size.width, size.height)..close();
    canvas.drawPath(fillPath, Paint()..shader = LinearGradient(colors: [color.withOpacity(0.3), color.withOpacity(0)], begin: Alignment.topCenter, end: Alignment.bottomCenter).createShader(Rect.fromLTWH(0, 0, size.width, size.height)));
    canvas.drawPath(linePath, Paint()..color = color..strokeWidth = 2.5..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
    final lx = size.width; final ly = size.height - ((data.last - minV) / range) * (size.height - 10) - 5; canvas.drawCircle(Offset(lx, ly), 4, Paint()..color = color);
  }
  @override bool shouldRepaint(covariant _ChartPainter old) => false;
}
