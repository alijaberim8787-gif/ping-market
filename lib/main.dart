import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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
  static const primaryPurple = Color(0xFF9D4EDD);
  static const primaryCyan = Color(0xFF00F5D4);
  static const gold = Color(0xFFFFD700);
  static const green = Color(0xFF00F5A0);
  static const red = Color(0xFFFF3366);
  static const bg = Color(0xFF0A0A10);
  static const cardBg = Color(0xFF151522);
}

ThemeData get darkTheme => ThemeData(
  useMaterial3: true, brightness: Brightness.dark, scaffoldBackgroundColor: C.bg,
  colorScheme: ColorScheme.fromSeed(seedColor: C.primaryPurple, brightness: Brightness.dark),
  appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0, centerTitle: true),
);

ThemeData get lightTheme => ThemeData(
  useMaterial3: true, brightness: Brightness.light, scaffoldBackgroundColor: const Color(0xFFF0F2F5),
  colorScheme: ColorScheme.fromSeed(seedColor: C.primaryPurple, brightness: Brightness.light),
  appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0, centerTitle: true),
);

// ═══════════════════════════════════════════════════════
//  NOTIFICATION MANAGER
// ═══════════════════════════════════════════════════════
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> initNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

Future<void> showNotification(String title, String body) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
    'chat_channel', 'Chat Notifications',
    channelDescription: 'Notifications for broadcast messages',
    importance: Importance.max, priority: Priority.high, showWhen: false,
  );
  const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
  await flutterLocalNotificationsPlugin.show(0, title, body, platformChannelSpecifics);
}

// ═══════════════════════════════════════════════════════
//  LOCALIZATION
// ═══════════════════════════════════════════════════════
class S {
  static const Map<String, List<String>> _d = {
    'home': ['خانه', 'Home'], 'prices': ['قیمت‌ها', 'Prices'], 'chat': ['چت روم', 'Chat'],
    'favs': ['علاقه‌مندی‌ها', 'Favorites'], 'profile': ['پروفایل', 'Profile'],
    'searchHint': ['جستجوی قیمت‌ها...', 'Search prices...'],
    'all': ['همه', 'All'], 'iran': ['ایران', 'Iran'], 'crypto': ['کریپتو', 'Crypto'],
    'gold': ['طلا', 'Gold'], 'dollar': ['دلار', 'Dollar'], 'bitcoin': ['بیت‌کوین', 'Bitcoin'],
    'allMarkets': ['همه بازارها', 'All markets'], 'toman': ['تومان', 'Toman'],
    'darkMode': ['حالت تاریک', 'Dark mode'], 'language': ['زبان', 'Language'],
    'currentPrice': ['قیمت فعلی', 'Current Price'], 'dailyChange': ['تغییرات', 'Change'],
    'addToWatch': ['ذخیره', 'Add to Favorites'], 'removeFromWatch': ['حذف', 'Remove'],
    'noFavs': ['لیست شما خالی است', 'Your list is empty'], 'noResults': ['موردی یافت نشد', 'No results'],
    'loading': ['در حال بارگذاری...', 'Loading...'], 'retry': ['تلاش دوباره', 'Retry'],
    'login': ['ورود', 'Login'], 'register': ['ثبت‌نام', 'Register'],
    'loginTitle': ['ورود به حساب', 'Login'], 'registerTitle': ['ساخت حساب', 'Create Account'],
    'username': ['نام کاربری', 'Username'], 'password': ['رمز عبور', 'Password'],
    'logout': ['خروج', 'Logout'], 'adminPanel': ['پنل مدیریت', 'Admin Panel'],
    'editProfile': ['تغییر آواتار', 'Change Avatar'], 'save': ['ذخیره', 'Save'], 'cancel': ['لغو', 'Cancel'],
    'typeMessage': ['پیام بنویسید...', 'Type a message...'],
    'loginToChat': ['برای ارسال پیام وارد شوید', 'Login to send messages'],
    'admin': ['مدیر', 'Admin'], 'user': ['کاربر', 'User'], 'banned': ['مسدود', 'Banned'],
    'noAccount': ['حساب ندارید؟ ثبت‌نام کنید', 'No account? Register'],
    'haveAccount': ['حساب دارید؟ وارد شوید', 'Have account? Login'],
    'adminDashboard': ['داشبورد', 'Dashboard'], 'adminUsers': ['کاربران', 'Users'], 'adminChat': ['چت', 'Chat'],
    'totalUsers': ['کل کاربران', 'Total Users'], 'totalMsgs': ['کل پیام‌ها', 'Total Messages'], 'bannedUsers': ['مسدودها', 'Banned'],
    'clearChat': ['پاک کردن چت', 'Clear Chat'], 'promote': ['ادمین کن', 'Make Admin'], 'demote': ['سلب ادمینی', 'Remove Admin'],
    'ban': ['مسدود', 'Ban'], 'unban': ['رفع مسدودی', 'Unban'], 'delete': ['حذف', 'Delete'],
    'broadcast': ['پیام همگانی', 'Broadcast'], 'broadcastHint': ['پیام برای همه...', 'Message for all...'],
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

  String? token, username, avatar; bool isAdmin = false;
  
  List<ChatMessage> chatMessages = [];
  int _lastSystemMsgId = 0;

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
    avatar = p.getString('avatar'); isAdmin = p.getBool('isAdmin') ?? false;
    notifyListeners(); await refresh();
  }

  Future<void> refresh() async {
    loading = iran.isEmpty && crypto.isEmpty; error = null; notifyListeners();
    try { await Future.wait([_loadAssets(), _loadCrypto()]).timeout(const Duration(seconds: 15)); } 
    catch (e) { error = 'Connection Error'; } finally { loading = false; notifyListeners(); }
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
        token = data['token']; username = data['username']; isAdmin = data['isAdmin'] ?? false; avatar = data['avatar'];
        final p = await SharedPreferences.getInstance();
        await p.setString('token', token!); await p.setString('username', username!); await p.setBool('isAdmin', isAdmin); await p.setString('avatar', avatar!);
        notifyListeners(); return null;
      }
      return data['error'] ?? 'Error';
    } catch (e) { return 'Connection error'; }
  }

  Future<String?> register(String user, String pass) async {
    try {
      final r = await http.post(Uri.parse(kRegisterUrl), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'username': user, 'password': pass}));
      final data = jsonDecode(r.body);
      if (r.statusCode == 200 && data['success']) {
        token = data['token']; username = data['username']; isAdmin = data['isAdmin'] ?? false; avatar = data['avatar'];
        final p = await SharedPreferences.getInstance();
        await p.setString('token', token!); await p.setString('username', username!); await p.setBool('isAdmin', isAdmin); await p.setString('avatar', avatar!);
        notifyListeners(); return null;
      }
      return data['error'] ?? 'Error';
    } catch (e) { return 'Connection error'; }
  }

  Future<void> updateAvatar(String newAvatar) async {
    try {
      final r = await http.post(Uri.parse(kUpdateProfileUrl), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}, body: jsonEncode({'avatar': newAvatar}));
      if (r.statusCode == 200) {
        avatar = newAvatar; notifyListeners();
        final p = await SharedPreferences.getInstance(); await p.setString('avatar', newAvatar);
      }
    } catch (_) {}
  }

  Future<void> logout() async {
    token = null; username = null; isAdmin = false; avatar = null;
    final p = await SharedPreferences.getInstance(); await p.remove('token'); await p.remove('username'); await p.remove('isAdmin'); await p.remove('avatar');
    notifyListeners();
  }

  // Chat Methods
  Future<void> fetchChatMessages() async {
    try {
      final r = await http.get(Uri.parse(kChatUrl));
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        if (data['success']) {
          final newMessages = (data['messages'] as List).map((e) => ChatMessage.fromJson(e)).toList();
          
          // Check for new system message to show notification
          if (newMessages.isNotEmpty) {
            final lastMsg = newMessages.last;
            if (lastMsg.isSystem && lastMsg.id != _lastSystemMsgId) {
              if (_lastSystemMsgId != 0) { // Don't notify on first load
                showNotification('پیام همگانی', lastMsg.text);
              }
              _lastSystemMsgId = lastMsg.id;
            }
          }

          chatMessages = newMessages;
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
    notifyListeners();

    try {
      final r = await http.post(Uri.parse(kSendMsgUrl), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}, body: jsonEncode({'text': text}));
      if (r.statusCode != 200) {
        chatMessages.removeWhere((m) => m.id == tempId);
      }
    } catch (_) {
      chatMessages.removeWhere((m) => m.id == tempId);
    } finally {
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
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initNotifications();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.light));
  runApp(ChangeNotifierProvider(create: (_) => AppState()..init(), child: const PingMarketApp()));
}

class PingMarketApp extends StatelessWidget {
  const PingMarketApp({super.key});
  @override Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return MaterialApp(
      debugShowCheckedModeBanner: false, title: 'Ping Market',
      themeMode: state.isDarkMode ? ThemeMode.dark : ThemeMode.light, theme: lightTheme, darkTheme: darkTheme, locale: Locale(state.lang),
      home: const AppShell(),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  APP SHELL (FIXED ANIMATION)
// ═══════════════════════════════════════════════════════
class AppShell extends StatelessWidget {
  const AppShell({super.key});
  @override Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      extendBody: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: IndexedStack(key: ValueKey(state.selectedTab), index: state.selectedTab, children: const [HomeTab(), PricesTab(), ChatTab(), FavoritesTab(), ProfileTab()]),
      ),
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
      (Icons.bar_chart_outlined, Icons.bar_chart_rounded, t('prices')),
      (Icons.forum_outlined, Icons.forum_rounded, t('chat')),
      (Icons.star_border_rounded, Icons.star_rounded, t('favs')),
      (Icons.person_outline_rounded, Icons.person_rounded, t('profile')),
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16), height: 72,
      decoration: BoxDecoration(color: isDark ? C.cardBg.withOpacity(0.9) : Colors.white, borderRadius: BorderRadius.circular(25), border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05), width: 1.5), boxShadow: [BoxShadow(color: C.primaryPurple.withOpacity(0.2), blurRadius: 30, spreadRadius: 2)]),
      child: ClipRRect(borderRadius: BorderRadius.circular(25), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15), child: Row(children: List.generate(items.length, (i) {
        final sel = index == i; final (icon, active, label) = items[i];
        return Expanded(child: TapScale(onTap: () => onChanged(i), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(sel ? active : icon, color: sel ? C.primaryPurple : (isDark ? Colors.white38 : Colors.black38), size: 26),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, color: sel ? C.primaryPurple : (isDark ? Colors.white38 : Colors.black38), fontWeight: sel ? FontWeight.w800 : FontWeight.w500)),
        ])));
      })))),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  CORE WIDGETS & ANIMATIONS
// ═══════════════════════════════════════════════════════
class TapScale extends StatefulWidget { final Widget child; final VoidCallback onTap; const TapScale({super.key, required this.child, required this.onTap}); @override State<TapScale> createState() => _TapScaleState(); }
class _TapScaleState extends State<TapScale> with SingleTickerProviderStateMixin {
  late AnimationController _c; late Animation<double> _s;
  @override void initState() { super.initState(); _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 150)); _s = Tween(begin: 1.0, end: 0.90).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutBack)); }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => GestureDetector(onTapDown: (_) => _c.forward(), onTapUp: (_) { _c.reverse(); widget.onTap(); }, onTapCancel: () => _c.reverse(), child: ScaleTransition(scale: _s, child: widget.child));
}

class StaggeredEntrance extends StatelessWidget {
  final int index; final Widget child;
  const StaggeredEntrance({super.key, required this.index, required this.child});
  @override Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0.0, end: 1.0), duration: Duration(milliseconds: 500 + (index * 80)), curve: Curves.easeOutExpo,
    builder: (context, value, child) => Opacity(opacity: value, child: Transform.translate(offset: Offset(0, 40 * (1 - value)), child: child)),
    child: child,
  );
}

class GlassCard extends StatelessWidget {
  final Widget child; final EdgeInsets padding; final Gradient? gradient;
  const GlassCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.gradient});
  @override Widget build(BuildContext context) {
    final isDark = context.watch<AppState>().isDarkMode;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? (isDark ? C.cardBg.withOpacity(0.6) : Colors.white) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05), width: 1.5),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: child,
    );
  }
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
    return Hero(tag: 'icon_${asset.code}', child: Container(width: size, height: size, decoration: BoxDecoration(color: C.cardBg, borderRadius: BorderRadius.circular(size * 0.3), border: Border.all(color: Colors.white.withOpacity(0.1), width: 1)), alignment: Alignment.center, child: iconWidget));
  }
  Widget _fallbackIcon() => Text(asset.icon, style: TextStyle(fontSize: size * 0.5));
}

class ShimmerCard extends StatefulWidget { final double height; const ShimmerCard({super.key, required this.height}); @override State<ShimmerCard> createState() => _ShimmerCardState(); }
class _ShimmerCardState extends State<ShimmerCard> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override void initState() { super.initState(); _c = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true); }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => AnimatedBuilder(animation: _c, builder: (context, child) => Container(height: widget.height, margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: Color.lerp(C.cardBg, C.primaryPurple.withOpacity(0.1), _c.value), borderRadius: BorderRadius.circular(24))));
}

// ═══════════════════════════════════════════════════════
//  TAB 1: HOME
// ═══════════════════════════════════════════════════════
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});
  @override Widget build(BuildContext context) {
    final state = context.watch<AppState>(); final isDark = state.isDarkMode; final t = state.t;
    return SafeArea(bottom: false, child: RefreshIndicator(
      color: C.primaryPurple, backgroundColor: C.cardBg, onRefresh: state.refresh,
      child: ListView(padding: const EdgeInsets.fromLTRB(20, 10, 20, 100), children: [
        StaggeredEntrance(index: 0, child: Row(children: [
          GlassCard(padding: const EdgeInsets.all(10), child: const Icon(Icons.notifications_none_rounded, color: Colors.white)),
          const Spacer(),
          Column(children: [
            RichText(text: TextSpan(children: [TextSpan(text: 'Ping ', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 24, fontWeight: FontWeight.w900)), const TextSpan(text: 'Market', style: TextStyle(color: C.primaryPurple, fontSize: 24, fontWeight: FontWeight.w900))])),
            Text('Real-time Prices', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 10, letterSpacing: 2)),
          ]),
          const Spacer(),
          TapScale(onTap: state.toggleLang, child: GlassCard(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), child: Text(state.lang == 'fa' ? 'FA' : 'EN', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
        ])),
        const SizedBox(height: 30),
        StaggeredEntrance(index: 1, child: _buildFeaturedCard(state, state.featuredAsset ?? MarketAsset(code: 'USD', symbol: 'USD', labelFa: 'دلار', labelEn: 'Dollar', icon: '💵', isCrypto: false, change: 0, sparkline: []))),
        const SizedBox(height: 30),
        StaggeredEntrance(index: 2, child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _quickAction(context, state, 'GOLD_18_RLS', 'طلا', Icons.diamond_rounded, C.gold),
          _quickAction(context, state, 'USD_RLS', 'دلار', Icons.attach_money_rounded, C.green),
          _quickAction(context, state, 'CG_BTC', 'بیت‌کوین', Icons.currency_bitcoin_rounded, Colors.orange),
          _allMarketsAction(context, state, 'بازارها', Icons.grid_view_rounded, C.primaryCyan),
        ])),
        const SizedBox(height: 30),
        StaggeredEntrance(index: 3, child: Text('Top Assets', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.bold))),
        const SizedBox(height: 16),
        if (state.loading) ...List.generate(3, (_) => const ShimmerCard(height: 80)) 
        else if (state.all.isNotEmpty) ...state.all.take(5).toList().asMap().entries.map((e) => StaggeredEntrance(index: e.key + 4, child: _homePriceRow(context, state, e.value))),
      ]),
    ));
  }

  Widget _buildFeaturedCard(AppState state, MarketAsset asset) {
    final isUp = asset.change >= 0; final changeColor = isUp ? C.green : C.red;
    return GlassCard(
      padding: const EdgeInsets.all(24), gradient: const LinearGradient(colors: [Color(0xFF3A0CA3), Color(0xFF7209B7)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      child: Stack(children: [
        Positioned(right: -20, bottom: -20, child: Icon(Icons.show_chart_rounded, size: 140, color: Colors.white.withOpacity(0.1))),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [AssetIcon(asset: asset, size: 50), const SizedBox(width: 16), Text(asset.displayLabelFor(state.lang), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), const Spacer(), const Icon(Icons.touch_app_rounded, color: Colors.white54, size: 24)]),
          const SizedBox(height: 30), Text(asset.displayPrice, style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: -1)), const SizedBox(height: 12),
          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, color: changeColor, size: 16), const SizedBox(width: 6), Text(asset.changeText, style: TextStyle(color: changeColor, fontSize: 14, fontWeight: FontWeight.bold))])),
        ]),
      ]),
    );
  }

  Widget _quickAction(BuildContext context, AppState state, String code, String label, IconData icon, Color color) {
    return TapScale(onTap: () { if (state.byCode(code) != null) Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(asset: state.byCode(code)!))); else { state.setTab(1); } }, child: GlassCard(padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16), child: Column(children: [Icon(icon, color: color, size: 32), const SizedBox(height: 8), Text(label, style: TextStyle(color: state.isDarkMode ? Colors.white : Colors.black, fontSize: 11, fontWeight: FontWeight.bold))])));
  }
  Widget _allMarketsAction(BuildContext context, AppState state, String label, IconData icon, Color color) {
    return TapScale(onTap: () { state.setTab(1); }, child: GlassCard(padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16), child: Column(children: [Icon(icon, color: color, size: 32), const SizedBox(height: 8), Text(label, style: TextStyle(color: state.isDarkMode ? Colors.white : Colors.black, fontSize: 11, fontWeight: FontWeight.bold))])));
  }
  Widget _homePriceRow(BuildContext context, AppState state, MarketAsset a) {
    final isUp = a.change >= 0;
    return TapScale(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(asset: a))), child: Padding(padding: const EdgeInsets.only(bottom: 12), child: GlassCard(padding: const EdgeInsets.all(16), child: Row(children: [AssetIcon(asset: a, size: 46), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(a.displayLabelFor(state.lang), style: TextStyle(color: state.isDarkMode ? Colors.white : Colors.black, fontWeight: FontWeight.w700, fontSize: 15)), const SizedBox(height: 6), Text(a.displayPrice, style: TextStyle(color: state.isDarkMode ? Colors.white54 : Colors.black54, fontSize: 14, fontWeight: FontWeight.w500))])), Text(a.changeText, style: TextStyle(color: isUp ? C.green : C.red, fontWeight: FontWeight.bold))]))));
  }
}

// ═══════════════════════════════════════════════════════
//  TAB 2: PRICES
// ═══════════════════════════════════════════════════════
class PricesTab extends StatefulWidget { const PricesTab({super.key}); @override State<PricesTab> createState() => _PricesTabState(); }
class _PricesTabState extends State<PricesTab> {
  String _query = '';
  @override Widget build(BuildContext context) {
    final state = context.watch<AppState>(); final isDark = state.isDarkMode; final t = state.t;
    List<MarketAsset> list = state.all; if (state.pricesFilter == 1) list = state.iran; if (state.pricesFilter == 2) list = state.crypto;
    if (_query.isNotEmpty) { list = list.where((a) => a.displayLabelFor(state.lang).toLowerCase().contains(_query.toLowerCase())).toList(); }
    return SafeArea(bottom: false, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 10), child: Row(children: [const Icon(Icons.bar_chart_rounded, color: C.primaryCyan, size: 32), const SizedBox(width: 12), Text(t('prices'), style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 26, fontWeight: FontWeight.w900))])),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: GlassCard(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), child: TextField(focusNode: state.searchFocusNode, onChanged: (v) => setState(() => _query = v), style: TextStyle(color: isDark ? Colors.white : Colors.black), decoration: InputDecoration(hintText: t('searchHint'), hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38), border: InputBorder.none, icon: Icon(Icons.search_rounded, color: isDark ? Colors.white54 : Colors.black54))))),
      const SizedBox(height: 16),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Row(children: [_filterPill(state, t('all'), 0), _filterPill(state, t('iran'), 1), _filterPill(state, t('crypto'), 2)])),
      const SizedBox(height: 16),
      Expanded(child: state.loading ? ListView(padding: const EdgeInsets.symmetric(horizontal: 20), children: const [ShimmerCard(height: 80), ShimmerCard(height: 80), ShimmerCard(height: 80)]) : list.isEmpty ? Center(child: Text(t('noResults'), style: TextStyle(color: isDark ? Colors.white54 : Colors.black54))) : ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 100), children: list.asMap().entries.map((e) => StaggeredEntrance(index: e.key > 10 ? 10 : e.key, child: _priceRow(context, state, e.value))).toList())),
    ]));
  }
  Widget _priceRow(BuildContext context, AppState state, MarketAsset a) {
    final isUp = a.change >= 0;
    return TapScale(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(asset: a))), child: Padding(padding: const EdgeInsets.only(bottom: 12), child: GlassCard(padding: const EdgeInsets.all(16), child: Row(children: [AssetIcon(asset: a, size: 46), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(a.displayLabelFor(state.lang), style: TextStyle(color: state.isDarkMode ? Colors.white : Colors.black, fontWeight: FontWeight.w700, fontSize: 15)), const SizedBox(height: 6), Text(a.displayPrice, style: TextStyle(color: state.isDarkMode ? Colors.white54 : Colors.black54, fontSize: 14, fontWeight: FontWeight.w500))])), Text(a.changeText, style: TextStyle(color: isUp ? C.green : C.red, fontWeight: FontWeight.bold))]))));
  }
  Widget _filterPill(AppState state, String label, int idx) {
    final sel = state.pricesFilter == idx;
    return TapScale(onTap: () => state.setPricesFilter(idx), child: Container(margin: const EdgeInsets.only(left: 12), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), decoration: BoxDecoration(gradient: sel ? const LinearGradient(colors: [C.primaryPurple, C.primaryCyan]) : null, color: sel ? null : C.cardBg, borderRadius: BorderRadius.circular(16)), child: Text(label, style: TextStyle(color: sel ? Colors.white : Colors.white54, fontWeight: FontWeight.bold))));
  }
}

// ═══════════════════════════════════════════════════════
//  TAB 3: CHAT ROOM (REWRITTEN & FIXED)
// ═══════════════════════════════════════════════════════
class ChatTab extends StatefulWidget { const ChatTab({super.key}); @override State<ChatTab> createState() => _ChatTabState(); }
class _ChatTabState extends State<ChatTab> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  Timer? _timer;

  @override void initState() { 
    super.initState(); 
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _fetch()); 
    _fetch(); 
  }
  
  @override void dispose() { _timer?.cancel(); _msgCtrl.dispose(); _scrollCtrl.dispose(); super.dispose(); }

  void _fetch() async { if (mounted) await context.read<AppState>().fetchChatMessages(); }
  
  void _scroll() { 
    WidgetsBinding.instance.addPostFrameCallback((_) { 
      if (_scrollCtrl.hasClients) _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic); 
    }); 
  }

  void _send() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    context.read<AppState>().sendChatMessage(text);
    _scroll();
  }

  @override Widget build(BuildContext context) {
    final state = context.watch<AppState>(); final t = state.t;
    if (state.chatMessages.isNotEmpty) _scroll();

    return SafeArea(bottom: false, child: Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 10), child: Row(children: [const Icon(Icons.forum_rounded, color: C.primaryCyan, size: 32), const SizedBox(width: 12), Text(t('chat'), style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900))])),
      
      Expanded(child: Container(margin: const EdgeInsets.symmetric(horizontal: 20), decoration: BoxDecoration(color: C.cardBg.withOpacity(0.5), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white.withOpacity(0.05))), child: ClipRRect(borderRadius: BorderRadius.circular(30), child: ListView.builder(
        controller: _scrollCtrl, padding: const EdgeInsets.all(20), itemCount: state.chatMessages.length,
        itemBuilder: (context, index) {
          final msg = state.chatMessages[index];
          final isMe = msg.username == state.username;
          return _bubble(msg, isMe, index);
        },
      )))),

      Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 100), child: state.token == null 
        ? Center(child: TextButton.icon(onPressed: () => state.setTab(4), icon: const Icon(Icons.login_rounded, color: C.primaryPurple), label: Text(t('loginToChat'), style: const TextStyle(color: C.primaryPurple, fontWeight: FontWeight.bold))))
        : GlassCard(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), child: Row(children: [
            Expanded(child: TextField(controller: _msgCtrl, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: t('typeMessage'), hintStyle: const TextStyle(color: Colors.white38), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16)), onSubmitted: (_) => _send())),
            TapScale(onTap: _send, child: Container(padding: const EdgeInsets.all(14), decoration: const BoxDecoration(gradient: LinearGradient(colors: [C.primaryPurple, C.primaryCyan]), shape: BoxShape.circle), child: const Icon(Icons.send_rounded, color: Colors.white, size: 22))),
          ])),
      ),
    ]));
  }

  Widget _bubble(ChatMessage msg, bool isMe, int index) {
    if (msg.isSystem) {
      return StaggeredEntrance(index: index, child: Center(child: Container(margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), decoration: BoxDecoration(color: C.gold.withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: C.gold.withOpacity(0.3))), child: Text(msg.text, style: const TextStyle(color: C.gold, fontSize: 13, fontWeight: FontWeight.bold)))));
    }
    return StaggeredEntrance(index: index, child: Align(alignment: isMe ? AlignmentDirectional.centerStart : AlignmentDirectional.centerEnd, child: Container(
      margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
      decoration: BoxDecoration(gradient: isMe ? const LinearGradient(colors: [C.primaryPurple, Color(0xFF5A189A)]) : null, color: isMe ? null : C.bg, borderRadius: BorderRadius.only(topLeft: const Radius.circular(24), topRight: const Radius.circular(24), bottomLeft: Radius.circular(isMe ? 24 : 4), bottomRight: Radius.circular(isMe ? 4 : 24)), boxShadow: [BoxShadow(color: isMe ? C.primaryPurple.withOpacity(0.3) : Colors.transparent, blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(crossAxisAlignment: isMe ? CrossAxisAlignment.start : CrossAxisAlignment.end, children: [
        if (!isMe) Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(msg.username, style: const TextStyle(color: C.primaryCyan, fontSize: 12, fontWeight: FontWeight.bold))),
        Text(msg.text, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4)),
      ]),
    )));
  }
}

// ═══════════════════════════════════════════════════════
//  TAB 4: FAVORITES
// ═══════════════════════════════════════════════════════
class FavoritesTab extends StatelessWidget {
  const FavoritesTab({super.key});
  @override Widget build(BuildContext context) {
    final state = context.watch<AppState>(); final t = state.t;
    return SafeArea(bottom: false, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 10), child: Row(children: [const Icon(Icons.star_rounded, color: C.primaryCyan, size: 32), const SizedBox(width: 12), Text(t('favs'), style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900))])),
      Expanded(child: state.favList.isEmpty ? Center(child: Text(t('noFavs'), style: const TextStyle(color: Colors.white54))) : ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 100), children: state.favList.asMap().entries.map((e) => StaggeredEntrance(index: e.key, child: TapScale(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(asset: e.value))), child: Padding(padding: const EdgeInsets.only(bottom: 12), child: GlassCard(padding: const EdgeInsets.all(16), child: Row(children: [AssetIcon(asset: e.value, size: 46), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(e.value.displayLabelFor(state.lang), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)), const SizedBox(height: 6), Text(e.value.displayPrice, style: const TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.w500))])), TapScale(onTap: () => state.toggleFav(e.value.code), child: const Padding(padding: EdgeInsets.all(8.0), child: Icon(Icons.delete_outline_rounded, color: C.red)))])))))).toList())),
    ]));
  }
}

// ═══════════════════════════════════════════════════════
//  TAB 5: PROFILE & AUTH
// ═══════════════════════════════════════════════════════
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});
  @override Widget build(BuildContext context) {
    final state = context.watch<AppState>(); final isDark = state.isDarkMode; final t = state.t;
    return SafeArea(bottom: false, child: ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 100), children: [
      StaggeredEntrance(index: 0, child: Row(children: [const Icon(Icons.person_rounded, color: C.primaryCyan, size: 32), const SizedBox(width: 12), Text(t('profile'), style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 26, fontWeight: FontWeight.w900))])),
      const SizedBox(height: 30),
      
      if (state.token == null) const AuthForm() else _buildProfileCard(context, state, isDark),
      
      const SizedBox(height: 30),
      StaggeredEntrance(index: 1, child: _settingItem(context, state, Icons.wb_sunny_rounded, t('darkMode'), trailing: Icon(isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded, color: C.primaryPurple), onTap: state.toggleTheme)),
      StaggeredEntrance(index: 2, child: _settingItem(context, state, Icons.language_rounded, t('language'), trailing: Text(state.lang == 'fa' ? 'فارسی' : 'English', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)), onTap: state.toggleLang)),
      
      if (state.isAdmin) ...[
        const SizedBox(height: 30),
        StaggeredEntrance(index: 3, child: Text(t('adminPanel'), style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.bold))),
        const SizedBox(height: 16),
        StaggeredEntrance(index: 4, child: _settingItem(context, state, Icons.admin_panel_settings_rounded, t('adminPanel'), trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: C.primaryPurple), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPanelScreen())))),
      ],
    ]));
  }

  Widget _buildProfileCard(BuildContext context, AppState state, bool isDark) {
    return StaggeredEntrance(index: 1, child: GlassCard(padding: const EdgeInsets.all(24), child: Column(children: [
      Row(children: [
        GestureDetector(
          onTap: () => _showAvatarPicker(context, state),
          child: Container(width: 70, height: 70, decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [C.primaryPurple, C.primaryCyan]), boxShadow: [BoxShadow(color: C.primaryPurple.withOpacity(0.4), blurRadius: 20, spreadRadius: 2)]), alignment: Alignment.center, child: Text(state.avatar ?? '👤', style: const TextStyle(fontSize: 36))),
        ),
        const SizedBox(width: 20),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(state.username ?? '', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 22, fontWeight: FontWeight.w900)),
          if (state.isAdmin) Container(margin: const EdgeInsets.only(top: 4), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: C.gold.withOpacity(0.2), borderRadius: BorderRadius.circular(8)), child: Text(state.t('admin'), style: const TextStyle(color: C.gold, fontSize: 12, fontWeight: FontWeight.bold))),
        ])),
        TapScale(onTap: state.logout, child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: C.red.withOpacity(0.1), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.logout_rounded, color: C.red, size: 22))),
      ]),
      const SizedBox(height: 24),
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        _statItem(context, Icons.star_rounded, '${state.favList.length}', 'علاقه‌مندی'),
        Container(width: 1, height: 40, color: Colors.white12),
        _statItem(context, Icons.forum_rounded, '${state.chatMessages.where((m) => m.username == state.username).length}', 'پیام‌ها'),
      ]),
    ])));
  }

  Widget _statItem(BuildContext context, IconData icon, String value, String label) {
    final isDark = context.watch<AppState>().isDarkMode;
    return Column(children: [Icon(icon, color: C.primaryCyan, size: 24), const SizedBox(height: 8), Text(value, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.bold)), Text(label, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12))]);
  }

  void _showAvatarPicker(BuildContext context, AppState state) {
    final avatars = ['👤', '😎', '🦊', '🐱', '🐼', '🦁', '💼', '🚀', '🧠', '🔥'];
    showModalBottomSheet(context: context, backgroundColor: C.cardBg, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))), builder: (ctx) {
      return Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(state.t('editProfile'), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        Wrap(spacing: 16, runSpacing: 16, children: avatars.map((e) => GestureDetector(
          onTap: () { state.updateAvatar(e); Navigator.pop(ctx); },
          child: Container(width: 60, height: 60, decoration: BoxDecoration(shape: BoxShape.circle, color: C.bg, border: Border.all(color: state.avatar == e ? C.primaryCyan : Colors.transparent, width: 2)), alignment: Alignment.center, child: Text(e, style: const TextStyle(fontSize: 30))),
        )).toList()),
      ]));
    });
  }

  Widget _settingItem(BuildContext context, AppState state, IconData icon, String title, {Widget? trailing, required VoidCallback onTap}) {
    final isDark = state.isDarkMode;
    return TapScale(onTap: onTap, child: Padding(padding: const EdgeInsets.only(bottom: 12), child: GlassCard(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18), child: Row(children: [Icon(icon, color: isDark ? Colors.white54 : Colors.black54), const SizedBox(width: 16), Expanded(child: Text(title, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w700, fontSize: 15))), if (trailing != null) trailing, if (trailing == null) Icon(Icons.chevron_left_rounded, color: isDark ? Colors.white38 : Colors.black38)]))));
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
    final t = context.read<AppState>().t;
    return StaggeredEntrance(index: 1, child: GlassCard(padding: const EdgeInsets.all(24), child: Column(children: [
      Text(_isLogin ? t('loginTitle') : t('registerTitle'), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 24),
      TextField(controller: _userCtrl, style: const TextStyle(color: Colors.white), decoration: InputDecoration(labelText: t('username'), labelStyle: const TextStyle(color: Colors.white54), enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white24), borderRadius: BorderRadius.circular(16)), focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: C.primaryPurple), borderRadius: BorderRadius.circular(16)))),
      const SizedBox(height: 16),
      TextField(controller: _passCtrl, obscureText: true, style: const TextStyle(color: Colors.white), decoration: InputDecoration(labelText: t('password'), labelStyle: const TextStyle(color: Colors.white54), enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white24), borderRadius: BorderRadius.circular(16)), focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: C.primaryPurple), borderRadius: BorderRadius.circular(16)))),
      if (_error != null) Padding(padding: const EdgeInsets.only(top: 16), child: Text(_error!, style: const TextStyle(color: C.red, fontSize: 13))),
      const SizedBox(height: 24),
      TapScale(onTap: _loading ? () {} : _submit, child: Container(padding: const EdgeInsets.symmetric(vertical: 18), decoration: BoxDecoration(gradient: const LinearGradient(colors: [C.primaryPurple, C.primaryCyan]), borderRadius: BorderRadius.circular(16)), alignment: Alignment.center, child: _loading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(_isLogin ? t('login') : t('register'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)))),
      const SizedBox(height: 16),
      TextButton(onPressed: () => setState(() => _isLogin = !_isLogin), child: Text(_isLogin ? t('noAccount') : t('haveAccount'), style: const TextStyle(color: C.primaryCyan))),
    ])));
  }
}

// ═══════════════════════════════════════════════════════
//  ADMIN PANEL (FULLY FIXED)
// ═══════════════════════════════════════════════════════
class AdminPanelScreen extends StatefulWidget { const AdminPanelScreen({super.key}); @override State<AdminPanelScreen> createState() => _AdminPanelScreenState(); }
class _AdminPanelScreenState extends State<AdminPanelScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;
  final TextEditingController _broadcastCtrl = TextEditingController();

  @override void initState() { super.initState(); _tabController = TabController(length: 3, vsync: this); _loadData(); }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final state = context.read<AppState>();
    final stats = await state.adminFetchStats();
    final users = await state.adminFetchUsers();
    if (mounted) setState(() { _stats = stats; _users = users; _loading = false; });
  }

  @override Widget build(BuildContext context) {
    final state = context.watch<AppState>(); final t = state.t;
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        title: Text(t('adminPanel'), style: const TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(controller: _tabController, indicatorColor: C.primaryCyan, labelColor: C.primaryCyan, unselectedLabelColor: Colors.white54, tabs: [
          Tab(text: t('adminDashboard'), icon: const Icon(Icons.dashboard_rounded, size: 20)),
          Tab(text: t('adminUsers'), icon: const Icon(Icons.people_rounded, size: 20)),
          Tab(text: t('adminChat'), icon: const Icon(Icons.forum_rounded, size: 20)),
        ]),
      ),
      body: _loading ? const Center(child: CircularProgressIndicator(color: C.primaryCyan)) : TabBarView(controller: _tabController, children: [
        _buildDashboard(state, t),
        _buildUsersTab(state, t),
        _buildChatTab(state, t),
      ]),
    );
  }

  Widget _buildDashboard(AppState state, String Function(String) t) {
    return ListView(padding: const EdgeInsets.all(20), children: [
      Row(children: [
        Expanded(child: _statCard('👥', _stats['users']?.toString() ?? '0', t('totalUsers'), C.primaryPurple)),
        const SizedBox(width: 16),
        Expanded(child: _statCard('💬', _stats['messages']?.toString() ?? '0', t('totalMsgs'), C.primaryCyan)),
      ]),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: _statCard('🚫', _stats['banned']?.toString() ?? '0', t('bannedUsers'), C.red)),
        const SizedBox(width: 16),
        Expanded(child: _statCard('⚡', 'Active', 'Status', C.green)),
      ]),
      const SizedBox(height: 30),
      Text(t('broadcast'), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      GlassCard(child: Column(children: [
        TextField(controller: _broadcastCtrl, style: const TextStyle(color: Colors.white), maxLines: 2, decoration: InputDecoration(hintText: t('broadcastHint'), hintStyle: const TextStyle(color: Colors.white38), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)))),
        const SizedBox(height: 16),
        TapScale(onTap: () { 
          if (_broadcastCtrl.text.isNotEmpty) {
            state.adminBroadcast(_broadcastCtrl.text); 
            _broadcastCtrl.clear();
            FocusScope.of(context).unfocus();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('پیام ارسال شد')));
          }
        }, child: Container(padding: const EdgeInsets.symmetric(vertical: 16), decoration: BoxDecoration(gradient: const LinearGradient(colors: [C.primaryPurple, C.primaryCyan]), borderRadius: BorderRadius.circular(16)), alignment: Alignment.center, child: Text(t('send'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
      ])),
    ]);
  }

  Widget _statCard(String icon, String value, String label, Color color) {
    return GlassCard(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(icon, style: const TextStyle(fontSize: 28)), const SizedBox(height: 12),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
      Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
      const SizedBox(height: 12), Container(height: 4, width: 40, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
    ]));
  }

  Widget _buildUsersTab(AppState state, String Function(String) t) {
    return ListView.builder(padding: const EdgeInsets.all(20), itemCount: _users.length, itemBuilder: (context, i) {
      final u = _users[i];
      final isSelf = u['username'] == state.username;
      return StaggeredEntrance(index: i, child: GlassCard(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(backgroundColor: C.primaryPurple.withOpacity(0.2), child: Text(u['username'][0].toUpperCase(), style: const TextStyle(color: C.primaryPurple, fontWeight: FontWeight.bold))),
        title: Text(u['username'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Row(children: [
          if (u['is_admin'] == 1) _badge(t('admin'), C.gold),
          if (u['is_banned'] == 1) _badge(t('banned'), C.red),
        ]),
        trailing: isSelf ? null : PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: Colors.white54),
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
      )));
    });
  }

  Widget _badge(String text, Color color) {
    return Container(margin: const EdgeInsets.only(left: 8), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(8)), child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)));
  }

  Widget _buildChatTab(AppState state, String Function(String) t) {
    return Column(children: [
      Padding(padding: const EdgeInsets.all(20), child: Row(children: [
        Expanded(child: ElevatedButton.icon(onPressed: () async { await state.adminClearChat(); state.fetchChatMessages(); _loadData(); }, icon: const Icon(Icons.delete_sweep_rounded), label: Text(t('clearChat')), style: ElevatedButton.styleFrom(backgroundColor: C.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))))),
      ])),
      Expanded(child: ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 20), itemCount: state.chatMessages.length, itemBuilder: (context, i) {
        final m = state.chatMessages[i];
        return GlassCard(padding: const EdgeInsets.all(12), child: ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(m.username, style: const TextStyle(color: C.primaryPurple, fontSize: 12, fontWeight: FontWeight.bold)),
          subtitle: Text(m.text, style: const TextStyle(color: Colors.white)),
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
    final state = context.watch<AppState>(); final a = widget.asset; final t = state.t;
    final isUp = a.change >= 0; final changeColor = isUp ? C.green : C.red; final isFav = state.favorites.contains(a.code);
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Colors.white), onPressed: () => Navigator.pop(context)), title: Text(a.displayLabelFor(state.lang), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)), actions: [IconButton(onPressed: () => state.toggleFav(a.code), icon: Icon(isFav ? Icons.star_rounded : Icons.star_border_rounded, color: C.gold))]),
      body: SafeArea(child: ListView(padding: const EdgeInsets.fromLTRB(20, 10, 20, 30), children: [
        GlassCard(padding: const EdgeInsets.all(24), child: Row(children: [AssetIcon(asset: a, size: 70), const SizedBox(width: 20), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(a.displayLabelFor(state.lang), style: const TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.w500)), const SizedBox(height: 8), Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [Text(a.displayPrice, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1)), const SizedBox(width: 8), Text(a.isCrypto ? 'USD' : t('toman'), style: const TextStyle(color: Colors.white38, fontSize: 14))])]))])),
        const SizedBox(height: 24),
        Row(children: [Icon(isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded, color: changeColor, size: 24), const SizedBox(width: 8), Text(a.changeText, style: TextStyle(color: changeColor, fontSize: 18, fontWeight: FontWeight.w900))]),
        const SizedBox(height: 30),
        Row(children: List.generate(_ranges.length, (i) { final sel = _rangeIdx == i; return Expanded(child: TapScale(onTap: () => setState(() => _rangeIdx = i), child: Container(margin: const EdgeInsets.symmetric(horizontal: 4), padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: sel ? C.primaryPurple : C.cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: sel ? C.primaryCyan : Colors.transparent)), alignment: Alignment.center, child: Text(_ranges[i], style: TextStyle(color: sel ? Colors.white : Colors.white54, fontSize: 13, fontWeight: FontWeight.bold))))); })),
        const SizedBox(height: 30),
        GlassCard(padding: const EdgeInsets.all(20), child: SizedBox(height: 240, child: CustomPaint(painter: _ChartPainter(a.sparkline, changeColor), child: const SizedBox.expand()))),
        const SizedBox(height: 30),
        GlassCard(padding: const EdgeInsets.all(20), child: Column(children: [_statRow(t('currentPrice'), a.displayPrice, Colors.white), const Divider(color: Colors.white12, height: 30), _statRow(t('dailyChange'), a.changeText, changeColor)])),
      ])),
    );
  }
  Widget _statRow(String label, String value, Color color) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(color: Colors.white54, fontSize: 15, fontWeight: FontWeight.w500)), Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold))]);
}

class _ChartPainter extends CustomPainter {
  final List<double> data; final Color color; _ChartPainter(this.data, this.color);
  @override void paint(Canvas canvas, Size size) {
    if (data.length < 2) return; final minV = data.reduce(min).toDouble(); final maxV = data.reduce(max).toDouble(); final range = (maxV - minV) == 0 ? 1.0 : (maxV - minV);
    final linePath = Path(); final fillPath = Path()..moveTo(0, size.height);
    for (int i = 0; i < data.length; i++) { final x = (i / (data.length - 1)) * size.width; final y = size.height - ((data[i] - minV) / range) * (size.height - 20) - 10; if (i == 0) linePath.moveTo(x, y); else linePath.lineTo(x, y); fillPath.lineTo(x, y); }
    fillPath..lineTo(size.width, size.height)..close();
    canvas.drawPath(fillPath, Paint()..shader = LinearGradient(colors: [color.withOpacity(0.4), color.withOpacity(0)], begin: Alignment.topCenter, end: Alignment.bottomCenter).createShader(Rect.fromLTWH(0, 0, size.width, size.height)));
    canvas.drawPath(linePath, Paint()..color = color..strokeWidth = 3..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);
  }
  @override bool shouldRepaint(covariant _ChartPainter old) => false;
}
