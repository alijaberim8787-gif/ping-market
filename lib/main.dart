import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PingMarketApp());
}

// ============================================================
// CONSTANTS
// ============================================================

const String kBackend = 'https://mrpingshop.ir';
const String kAssetsEndpoint = '$kBackend/api/assets';
const String kCryptoEndpoint = '$kBackend/api/crypto/list';

const Duration kApiTimeout = Duration(seconds: 15);

// ============================================================
// ENUMS
// ============================================================

enum AppLanguage {
  fa,
  en,
}

enum PriceFilter {
  all,
  currency,
  gold,
  crypto,
}

// ============================================================
// MARKET ASSET
// ============================================================

class MarketAsset {
  final String code;
  final String icon;
  final String labelFa;
  final String labelEn;
  final String quoteUnit;
  final double value;
  final double? change24h;
  final DateTime? businessTime;
  final DateTime? updatedAt;

  const MarketAsset({
    required this.code,
    required this.icon,
    required this.labelFa,
    required this.labelEn,
    required this.quoteUnit,
    required this.value,
    this.change24h,
    this.businessTime,
    this.updatedAt,
  });

  String get label => labelEn;

  String get symbol {
    final parts = code.split('_');
    return parts.isNotEmpty ? parts.first : code;
  }

  bool get isGold {
    final c = code.toUpperCase();
    final fa = labelFa.toLowerCase();

    return c.contains('GOLD') ||
        c.contains('XAU') ||
        fa.contains('طلا') ||
        labelEn.toLowerCase().contains('gold');
  }

  bool get isCrypto {
    final c = code.toUpperCase();

    const cryptoSymbols = {
      'BTC',
      'ETH',
      'BNB',
      'SOL',
      'XRP',
      'DOGE',
      'ADA',
      'TRX',
      'TON',
      'DOT',
      'AVAX',
      'LINK',
      'LTC',
      'BCH',
      'USDT',
      'USDC',
      'SHIB',
      'MATIC',
      'POL',
      'PEPE',
      'TRUMP',
    };

    if (c.startsWith('CG_')) return true;

    final base = c.split('_').first;

    return cryptoSymbols.contains(base) ||
        labelEn.toLowerCase().contains('bitcoin') ||
        labelEn.toLowerCase().contains('ethereum') ||
        labelEn.toLowerCase().contains('crypto') ||
        labelFa.contains('بیت') ||
        labelFa.contains('اتریوم');
  }

  bool get isCurrency {
    if (isGold || isCrypto) return false;

    final c = code.toUpperCase();

    return c.contains('USD') ||
        c.contains('EUR') ||
        c.contains('GBP') ||
        c.contains('AED') ||
        c.contains('CAD') ||
        c.contains('AUD') ||
        c.contains('TRY') ||
        c.contains('CHF') ||
        c.contains('JPY');
  }

  factory MarketAsset.fromJson(Map<String, dynamic> json) {
    double? parseDouble(dynamic value) {
      if (value == null) return null;

      if (value is num) {
        return value.toDouble();
      }

      return double.tryParse(
        value.toString().replaceAll(',', '').trim(),
      );
    }

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;

      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return null;
      }
    }

    final code = (json['code'] ?? json['symbol'] ?? '').toString();

    final value =
        parseDouble(json['value']) ??
        parseDouble(json['price']) ??
        parseDouble(json['valueRls']) ??
        parseDouble(json['valueUsd']) ??
        0;

    return MarketAsset(
      code: code,
      icon: (json['icon'] ?? '💹').toString(),
      labelFa: (
        json['labelFa'] ??
        json['nameFa'] ??
        json['name_fa'] ??
        json['name'] ??
        code
      ).toString(),
      labelEn: (
        json['labelEn'] ??
        json['nameEn'] ??
        json['name_en'] ??
        json['name'] ??
        code
      ).toString(),
      quoteUnit: (
        json['quoteUnit'] ??
        json['quote'] ??
        'RLS'
      ).toString().toUpperCase(),
      value: value,
      change24h: parseDouble(
        json['change24h'] ??
        json['change_24h'] ??
        json['change'] ??
        json['percentChange'],
      ),
      businessTime: parseDate(json['businessTime']),
      updatedAt: parseDate(
        json['updatedAt'] ??
        json['updated_at'],
      ),
    );
  }
}

// ============================================================
// API RESULT
// ============================================================

class ApiResult {
  final List<MarketAsset> assets;
  final String? error;

  const ApiResult({
    required this.assets,
    this.error,
  });

  bool get success => assets.isNotEmpty;
}

// ============================================================
// API SERVICE
// ============================================================

class MarketApi {
  final http.Client client;

  MarketApi({
    http.Client? client,
  }) : client = client ?? http.Client();

  Future<dynamic> _getJson(String url) async {
    final response = await client
        .get(
          Uri.parse(url),
          headers: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        )
        .timeout(kApiTimeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'HTTP ${response.statusCode}',
      );
    }

    return jsonDecode(response.body);
  }

  List<Map<String, dynamic>> _extractList(dynamic json) {
    dynamic data = json;

    if (json is Map<String, dynamic>) {
      data =
          json['assets'] ??
          json['data'] ??
          json['coins'] ??
          json['results'] ??
          json['items'] ??
          json['list'] ??
          [];
    }

    if (data is! List) {
      return [];
    }

    return data
        .whereType<Map>()
        .map(
          (item) => Map<String, dynamic>.from(item),
        )
        .toList();
  }

  Future<ApiResult> fetchAssets() async {
    try {
      final json = await _getJson(kAssetsEndpoint);

      final list = _extractList(json);

      final assets = list
          .map(MarketAsset.fromJson)
          .where((asset) => asset.code.isNotEmpty)
          .toList();

      return ApiResult(
        assets: assets,
      );
    } catch (e) {
      return ApiResult(
        assets: const [],
        error: e.toString(),
      );
    }
  }

  Future<ApiResult> fetchCrypto() async {
    try {
      final json = await _getJson(kCryptoEndpoint);

      final list = _extractList(json);

      final assets = list
          .map(MarketAsset.fromJson)
          .where((asset) => asset.code.isNotEmpty)
          .toList();

      return ApiResult(
        assets: assets,
      );
    } catch (e) {
      return ApiResult(
        assets: const [],
        error: e.toString(),
      );
    }
  }

  Future<ApiResult> fetchAll() async {
    final results = await Future.wait([
      fetchAssets(),
      fetchCrypto(),
    ]);

    final first = results[0];
    final second = results[1];

    final Map<String, MarketAsset> unique = {};

    for (final asset in first.assets) {
      unique[asset.code] = asset;
    }

    for (final asset in second.assets) {
      unique.putIfAbsent(asset.code, () => asset);
    }

    String? error;

    if (first.error != null && second.error != null) {
      error = 'هر دو منبع قیمت در دسترس نیستند.';
    } else if (first.error != null && first.assets.isEmpty) {
      error = 'منبع قیمت‌های اصلی در دسترس نیست.';
    } else if (second.error != null) {
      error = 'منبع ارزهای دیجیتال در دسترس نیست.';
    }

    return ApiResult(
      assets: unique.values.toList(),
      error: error,
    );
  }

  void dispose() {
    client.close();
  }
}

// ============================================================
// APP CONTROLLER
// ============================================================

class AppController extends ChangeNotifier {
  final MarketApi api;

  AppController({
    MarketApi? api,
  }) : api = api ?? MarketApi();

  ThemeMode themeMode = ThemeMode.dark;
  AppLanguage language = AppLanguage.fa;

  List<MarketAsset> assets = [];

  Set<String> favorites = {};

  String selectedHomeAsset = 'USD_RLS';

  bool isLoading = true;
  bool isRefreshing = false;

  String? errorMessage;

  DateTime? lastUpdated;

  bool _initialized = false;

  bool get isDark {
    return themeMode == ThemeMode.dark;
  }

  Locale get locale {
    return language == AppLanguage.fa
        ? const Locale('fa')
        : const Locale('en');
  }

  bool get isRTL {
    return language == AppLanguage.fa;
  }

  List<MarketAsset> get favoriteAssets {
    return assets
        .where(
          (asset) => favorites.contains(asset.code),
        )
        .toList();
  }

  MarketAsset? get homeAsset {
    for (final asset in assets) {
      if (asset.code == selectedHomeAsset) {
        return asset;
      }
    }

    if (assets.isNotEmpty) {
      return assets.first;
    }

    return null;
  }

  Future<void> initialize() async {
    if (_initialized) return;

    _initialized = true;

    final prefs = await SharedPreferences.getInstance();

    final savedTheme = prefs.getString('theme_mode');
    final savedLanguage = prefs.getString('language');
    final savedHomeAsset = prefs.getString('home_asset');

    if (savedTheme == 'light') {
      themeMode = ThemeMode.light;
    } else {
      themeMode = ThemeMode.dark;
    }

    if (savedLanguage == 'en') {
      language = AppLanguage.en;
    } else {
      language = AppLanguage.fa;
    }

    if (savedHomeAsset != null &&
        savedHomeAsset.trim().isNotEmpty) {
      selectedHomeAsset = savedHomeAsset;
    }

    notifyListeners();

    await loadPrices();
  }

  Future<void> loadPrices() async {
    isLoading = true;
    errorMessage = null;

    notifyListeners();

    final result = await api.fetchAll();

    assets = _sortAssets(result.assets);

    if (result.error != null && assets.isEmpty) {
      errorMessage = result.error;
    }

    if (assets.isNotEmpty) {
      final exists = assets.any(
        (asset) => asset.code == selectedHomeAsset,
      );

      if (!exists) {
        selectedHomeAsset = assets.first.code;
      }
    }

    lastUpdated = DateTime.now();

    isLoading = false;

    notifyListeners();
  }

  Future<void> refreshPrices() async {
    if (isRefreshing) return;

    isRefreshing = true;
    errorMessage = null;

    notifyListeners();

    final result = await api.fetchAll();

    final newAssets = _sortAssets(result.assets);

    if (newAssets.isNotEmpty) {
      assets = newAssets;
      lastUpdated = DateTime.now();

      final exists = assets.any(
        (asset) => asset.code == selectedHomeAsset,
      );

      if (!exists) {
        selectedHomeAsset = assets.first.code;
      }
    }

    if (result.error != null && assets.isEmpty) {
      errorMessage = result.error;
    }

    isRefreshing = false;

    notifyListeners();
  }

  List<MarketAsset> _sortAssets(
    List<MarketAsset> input,
  ) {
    final list = [...input];

    list.sort((a, b) {
      int priority(MarketAsset asset) {
        final code = asset.code.toUpperCase();

        if (code == 'USD_RLS') return 0;
        if (code == 'EUR_RLS') return 1;
        if (asset.isGold) return 2;
        if (asset.isCrypto) return 3;

        return 10;
      }

      return priority(a).compareTo(priority(b));
    });

    return list;
  }

  void setThemeMode(ThemeMode mode) async {
    themeMode = mode;

    notifyListeners();

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'theme_mode',
      mode == ThemeMode.light ? 'light' : 'dark',
    );
  }

  void toggleTheme() {
    setThemeMode(
      isDark ? ThemeMode.light : ThemeMode.dark,
    );
  }

  void setLanguage(AppLanguage value) async {
    if (language == value) return;

    language = value;

    notifyListeners();

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'language',
      value == AppLanguage.fa ? 'fa' : 'en',
    );
  }

  void toggleLanguage() {
    setLanguage(
      language == AppLanguage.fa
          ? AppLanguage.en
          : AppLanguage.fa,
    );
  }

  void selectHomeAsset(String code) async {
    selectedHomeAsset = code;

    notifyListeners();

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'home_asset',
      code,
    );
  }

  void toggleFavorite(String code) async {
    if (favorites.contains(code)) {
      favorites.remove(code);
    } else {
      favorites.add(code);
    }

    notifyListeners();

    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      'favorites',
      favorites.toList(),
    );
  }

  Future<void> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();

    final list = prefs.getStringList('favorites');

    if (list != null) {
      favorites = list.toSet();
    }

    notifyListeners();
  }

  List<MarketAsset> filterAssets(
    PriceFilter filter,
    String query,
  ) {
    Iterable<MarketAsset> result = assets;

    switch (filter) {
      case PriceFilter.all:
        break;

      case PriceFilter.currency:
        result = result.where(
          (asset) => asset.isCurrency,
        );
        break;

      case PriceFilter.gold:
        result = result.where(
          (asset) => asset.isGold,
        );
        break;

      case PriceFilter.crypto:
        result = result.where(
          (asset) => asset.isCrypto,
        );
        break;
    }

    final q = query.trim().toLowerCase();

    if (q.isNotEmpty) {
      result = result.where((asset) {
        return asset.code.toLowerCase().contains(q) ||
            asset.labelFa.toLowerCase().contains(q) ||
            asset.labelEn.toLowerCase().contains(q) ||
            asset.symbol.toLowerCase().contains(q);
      });
    }

    return result.toList();
  }

  @override
  void dispose() {
    api.dispose();
    super.dispose();
  }
}

// ============================================================
// LOCALIZATION
// ============================================================

class T {
  static const Map<String, String> fa = {
    'appName': 'Ping Market',
    'home': 'خانه',
    'prices': 'قیمت‌ها',
    'favorites': 'علاقه‌مندی‌ها',
    'settings': 'تنظیمات',
    'market': 'بازار',
    'live': 'زنده',
    'updated': 'آخرین بروزرسانی',
    'refresh': 'بروزرسانی',
    'retry': 'تلاش مجدد',
    'search': 'جستجوی ارز، طلا یا رمزارز',
    'all': 'همه',
    'currency': 'ارز',
    'gold': 'طلا',
    'crypto': 'رمزارز',
    'dollar': 'دلار',
    'euro': 'یورو',
    'bitcoin': 'بیت‌کوین',
    'gold18': 'طلای ۱۸ عیار',
    'favorite': 'علاقه‌مندی',
    'noFavorites': 'هنوز موردی به علاقه‌مندی‌ها اضافه نکرده‌اید.',
    'noResults': 'موردی پیدا نشد.',
    'theme': 'پوسته',
    'dark': 'تاریک',
    'light': 'روشن',
    'language': 'زبان',
    'persian': 'فارسی',
    'english': 'English',
    'support': 'پشتیبانی',
    'about': 'درباره Ping Market',
    'privacy': 'حریم خصوصی',
    'appearance': 'ظاهر برنامه',
    'general': 'عمومی',
    'information': 'اطلاعات',
    'chooseHomePrice': 'قیمت موردنظر برای صفحه خانه',
    'selectPrice': 'انتخاب قیمت',
    'noData': 'اطلاعاتی برای نمایش وجود ندارد.',
    'connectionError': 'دریافت اطلاعات با مشکل مواجه شد.',
    'tryAgain': 'لطفاً دوباره تلاش کنید.',
    'tomans': 'تومان',
    'rial': 'ریال',
    'usd': 'دلار آمریکا',
    'eur': 'یورو',
    'price': 'قیمت',
    'change24h': 'تغییر ۲۴ ساعته',
    'unknown': 'نامشخص',
    'supportText': 'برای پشتیبانی و ارتباط با ما می‌توانید از راه‌های ارتباطی پروژه استفاده کنید.',
    'aboutText': 'Ping Market یک اپلیکیشن نمایش قیمت بازار است که اطلاعات ارز، طلا و رمزارزها را در یک رابط کاربری سریع و حرفه‌ای نمایش می‌دهد.',
    'privacyText': 'Ping Market اطلاعات حساس یا اطلاعات مالی کاربران را ذخیره نمی‌کند. تنظیمات ظاهری و علاقه‌مندی‌ها به‌صورت محلی روی دستگاه ذخیره می‌شوند.',
    'chooseLanguage': 'انتخاب زبان',
    'chooseTheme': 'انتخاب پوسته',
    'close': 'بستن',
    'done': 'انجام شد',
    'select': 'انتخاب',
    'favoritesEmptyHint': 'روی ستاره کنار هر قیمت بزنید تا اینجا ذخیره شود.',
    'lastUpdate': 'بروزرسانی',
    'marketOverview': 'نمای کلی بازار',
    'quickAccess': 'دسترسی سریع',
    'yourFavoritePrice': 'قیمت منتخب شما',
    'change': 'تغییر',
    'failedToLoad': 'بارگذاری انجام نشد',
    'partialData': 'برخی داده‌ها در دسترس نیستند.',
    'offline': 'اتصال برقرار نیست',
  };

  static const Map<String, String> en = {
    'appName': 'Ping Market',
    'home': 'Home',
    'prices': 'Prices',
    'favorites': 'Favorites',
    'settings': 'Settings',
    'market': 'Market',
    'live': 'LIVE',
    'updated': 'Last update',
    'refresh': 'Refresh',
    'retry': 'Retry',
    'search': 'Search currency, gold or crypto',
    'all': 'All',
    'currency': 'Currency',
    'gold': 'Gold',
    'crypto': 'Crypto',
    'dollar': 'Dollar',
    'euro': 'Euro',
    'bitcoin': 'Bitcoin',
    'gold18': '18K Gold',
    'favorite': 'Favorite',
    'noFavorites': 'You have not added anything to favorites yet.',
    'noResults': 'No results found.',
    'theme': 'Theme',
    'dark': 'Dark',
    'light': 'Light',
    'language': 'Language',
    'persian': 'فارسی',
    'english': 'English',
    'support': 'Support',
    'about': 'About Ping Market',
    'privacy': 'Privacy',
    'appearance': 'Appearance',
    'general': 'General',
    'information': 'Information',
    'chooseHomePrice': 'Price shown on the home screen',
    'selectPrice': 'Select price',
    'noData': 'No data available.',
    'connectionError': 'Could not load market data.',
    'tryAgain': 'Please try again.',
    'tomans': 'Tomans',
    'rial': 'Rial',
    'usd': 'US Dollar',
    'eur': 'Euro',
    'price': 'Price',
    'change24h': '24h Change',
    'unknown': 'Unknown',
    'supportText': 'For support and communication, please use the project contact channels.',
    'aboutText': 'Ping Market is a market price application that displays currency, gold and crypto prices in a fast and professional interface.',
    'privacyText': 'Ping Market does not store sensitive or financial user information. Appearance settings and favorites are stored locally on the device.',
    'chooseLanguage': 'Choose language',
    'chooseTheme': 'Choose theme',
    'close': 'Close',
    'done': 'Done',
    'select': 'Select',
    'favoritesEmptyHint': 'Tap the star next to any price to save it here.',
    'lastUpdate': 'Updated',
    'marketOverview': 'Market overview',
    'quickAccess': 'Quick access',
    'yourFavoritePrice': 'Your selected price',
    'change': 'Change',
    'failedToLoad': 'Loading failed',
    'partialData': 'Some data is unavailable.',
    'offline': 'Connection unavailable',
  };

  static String get(
    AppLanguage language,
    String key,
  ) {
    final map = language == AppLanguage.fa ? fa : en;

    return map[key] ?? key;
  }
}

// ============================================================
// HELPERS
// ============================================================

String tr(
  BuildContext context,
  String key,
) {
  final controller = PingMarketScope.of(context);

  return T.get(
    controller.language,
    key,
  );
}

String formatNumber(
  double value, {
  int decimals = 0,
}) {
  if (value.isNaN || value.isInfinite) {
    return '—';
  }

  final fixed = value.toStringAsFixed(decimals);

  final parts = fixed.split('.');

  String integer = parts.first;

  final negative = integer.startsWith('-');

  if (negative) {
    integer = integer.substring(1);
  }

  final chars = integer.split('');
  final result = <String>[];

  for (int i = 0; i < chars.length; i++) {
    if (i > 0 &&
        (chars.length - i) % 3 == 0) {
      result.add(',');
    }

    result.add(chars[i]);
  }

  var output = result.join();

  if (negative) {
    output = '-$output';
  }

  if (decimals > 0 && parts.length > 1) {
    output += '.${parts[1]}';
  }

  return output;
}

String persianDigits(String text) {
  const english = '0123456789';
  const persian = '۰۱۲۳۴۵۶۷۸۹';

  for (int i = 0; i < english.length; i++) {
    text = text.replaceAll(
      english[i],
      persian[i],
    );
  }

  return text;
}

String displayPrice(
  MarketAsset asset,
  AppLanguage language,
) {
  final unit = asset.quoteUnit.toUpperCase();

  double value = asset.value;

  String suffix = unit;

  if (unit == 'RLS' ||
      unit == 'IRR' ||
      asset.code.toUpperCase().endsWith('_RLS')) {
    value = value / 10;
    suffix = language == AppLanguage.fa
        ? 'تومان'
        : 'Toman';
  }

  final number = formatNumber(
    value,
    decimals: value >= 1000 ? 0 : 2,
  );

  if (language == AppLanguage.fa) {
    return '${persianDigits(number)} $suffix';
  }

  return '$number $suffix';
}

String displayCompactPrice(
  MarketAsset asset,
  AppLanguage language,
) {
  final unit = asset.quoteUnit.toUpperCase();

  double value = asset.value;

  if (unit == 'RLS' ||
      unit == 'IRR' ||
      asset.code.toUpperCase().endsWith('_RLS')) {
    value /= 10;
  }

  if (value >= 1000000000) {
    return '${(value / 1000000000).toStringAsFixed(2)}B';
  }

  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(2)}M';
  }

  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(2)}K';
  }

  return formatNumber(
    value,
    decimals: 2,
  );
}

Color changeColor(
  BuildContext context,
  double? change,
) {
  if (change == null || change == 0) {
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }

  return change > 0
      ? const Color(0xFF20D68B)
      : const Color(0xFFFF5577);
}

// ============================================================
// APP SCOPE
// ============================================================

class PingMarketScope extends InheritedNotifier<AppController> {
  const PingMarketScope({
    super.key,
    required AppController controller,
    required Widget child,
  }) : super(
          notifier: controller,
          child: child,
        );

  static AppController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<PingMarketScope>();

    if (scope == null || scope.notifier == null) {
      throw FlutterError(
        'PingMarketScope was not found.',
      );
    }

    return scope.notifier!;
  }
}

// ============================================================
// APP
// ============================================================

class PingMarketApp extends StatefulWidget {
  const PingMarketApp({
    super.key,
  });

  @override
  State<PingMarketApp> createState() => _PingMarketAppState();
}

class _PingMarketAppState extends State<PingMarketApp> {
  late final AppController controller;

  @override
  void initState() {
    super.initState();

    controller = AppController();

    _initialize();
  }

  Future<void> _initialize() async {
    await controller.initialize();
    await controller.loadFavorites();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final isDark =
            controller.themeMode == ThemeMode.dark;

        return PingMarketScope(
          controller: controller,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Ping Market',
            locale: controller.locale,
            supportedLocales: const [
              Locale('fa'),
              Locale('en'),
            ],
            theme: PingTheme.light(),
            darkTheme: PingTheme.dark(),
            themeMode: controller.themeMode,
            builder: (context, child) {
              return Directionality(
                textDirection: controller.isRTL
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                child: child ?? const SizedBox(),
              );
            },
            home: const AppShell(),
          ),
        );
      },
    );
  }
}

// ============================================================
// THEME
// ============================================================

class PingTheme {
  static ThemeData dark() {
    const bg = Color(0xFF08090D);
    const surface = Color(0xFF11131A);
    const primary = Color(0xFF8B5CF6);

    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme.copyWith(
        surface: surface,
      ),
      scaffoldBackgroundColor: bg,
      cardColor: surface,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF0D0F15),
        indicatorColor: primary.withOpacity(.20),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) {
            return const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
            );
          },
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  static ThemeData light() {
    const bg = Color(0xFFF5F6FA);
    const surface = Colors.white;
    const primary = Color(0xFF6D3FEF);

    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme.copyWith(
        surface: surface,
      ),
      scaffoldBackgroundColor: bg,
      cardColor: surface,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: primary.withOpacity(.14),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) {
            return const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
            );
          },
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

// ============================================================
// APP SHELL
// ============================================================

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;

  final pages = const [
    HomeScreen(),
    PricesScreen(),
    FavoritesScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = PingMarketScope.of(context);

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.02, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ),
              ),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey(index),
          child: pages[index],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) {
          setState(() {
            index = value;
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home_rounded),
            label: tr(context, 'home'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.show_chart_outlined),
            selectedIcon: const Icon(Icons.show_chart_rounded),
            label: tr(context, 'prices'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.star_outline_rounded),
            selectedIcon: const Icon(Icons.star_rounded),
            label: tr(context, 'favorites'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings_rounded),
            label: tr(context, 'settings'),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PRESSABLE
// ============================================================

class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius borderRadius;

  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = const BorderRadius.all(
      Radius.circular(20),
    ),
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        if (widget.onTap != null) {
          setState(() {
            pressed = true;
          });
        }
      },
      onTapCancel: () {
        setState(() {
          pressed = false;
        });
      },
      onTapUp: (_) {
        setState(() {
          pressed = false;
        });
      },
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: pressed ? .96 : 1,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

// ============================================================
// GLASS CARD
// ============================================================

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.borderRadius = const BorderRadius.all(
      Radius.circular(26),
    ),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final dark =
        theme.brightness == Brightness.dark;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        color: dark
            ? Colors.white.withOpacity(.055)
            : Colors.white.withOpacity(.88),
        border: Border.all(
          color: dark
              ? Colors.white.withOpacity(.07)
              : Colors.black.withOpacity(.055),
        ),
        boxShadow: [
          if (!dark)
            BoxShadow(
              blurRadius: 30,
              offset: const Offset(0, 12),
              color: Colors.black.withOpacity(.06),
            ),
        ],
      ),
      child: child,
    );
  }
}

// ============================================================
// HOME SCREEN
// ============================================================

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final controller = PingMarketScope.of(context);

    return RefreshIndicator(
      onRefresh: controller.refreshPrices,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: _HomeHeader(),
          ),
          SliverToBoxAdapter(
            child: const SizedBox(height: 14),
          ),
          SliverToBoxAdapter(
            child: FeaturedAssetCard(),
          ),
          SliverToBoxAdapter(
            child: const SizedBox(height: 20),
          ),
          SliverToBoxAdapter(
            child: QuickActions(),
          ),
          SliverToBoxAdapter(
            child: const SizedBox(height: 24),
          ),
          SliverToBoxAdapter(
            child: MarketOverview(),
          ),
          SliverToBoxAdapter(
            child: const SizedBox(height: 100),
          ),
        ],
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = PingMarketScope.of(context);

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          20,
          18,
          20,
          0,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    tr(context, 'appName'),
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -.5,
                        ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF20D68B),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        tr(context, 'live'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.greenAccent.shade400,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Pressable(
              onTap: controller.refreshPrices,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context)
                      .colorScheme
                      .surface,
                  border: Border.all(
                    color: Theme.of(context)
                        .dividerColor
                        .withOpacity(.15),
                  ),
                ),
                child: controller.isRefreshing
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.refresh_rounded,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// FEATURED ASSET CARD
// ============================================================

class FeaturedAssetCard extends StatelessWidget {
  const FeaturedAssetCard({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final controller = PingMarketScope.of(context);

    if (controller.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: LoadingCard(),
      );
    }

    if (controller.errorMessage != null &&
        controller.assets.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: ErrorCard(
          message: controller.errorMessage!,
          onRetry: controller.loadPrices,
        ),
      );
    }

    final asset = controller.homeAsset;

    if (asset == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: GlassCard(
          child: Center(
            child: Text(
              tr(context, 'noData'),
            ),
          ),
        ),
      );
    }

    final change = asset.change24h;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassCard(
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(30),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Stack(
            children: [
              Positioned(
                top: -80,
                right: -60,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withOpacity(.13),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              AssetIcon(asset: asset),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      T.get(
                                        controller.language,
                                        'yourFavoritePrice',
                                      ),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                        fontWeight:
                                            FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      controller.language ==
                                              AppLanguage.fa
                                          ? asset.labelFa
                                          : asset.labelEn,
                                      maxLines: 1,
                                      overflow:
                                          TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight:
                                            FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Pressable(
                          onTap: () {
                            showHomeAssetSelector(
                              context,
                              controller,
                            );
                          },
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(14),
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(.10),
                            ),
                            child: Row(
                              mainAxisSize:
                                  MainAxisSize.min,
                              children: [
                                Text(
                                  tr(
                                    context,
                                    'select',
                                  ),
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                    fontSize: 12,
                                    fontWeight:
                                        FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons
                                      .keyboard_arrow_down_rounded,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 26),
                    AnimatedSwitcher(
                      duration: const Duration(
                        milliseconds: 350,
                      ),
                      transitionBuilder:
                          (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, .15),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: Text(
                        displayPrice(
                          asset,
                          controller.language,
                        ),
                        key: ValueKey(
                          '${asset.code}_${asset.value}',
                        ),
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        if (change != null)
                          Container(
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(12),
                              color: changeColor(
                                context,
                                change,
                              ).withOpacity(.11),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  change >= 0
                                      ? Icons
                                          .arrow_upward_rounded
                                      : Icons
                                          .arrow_downward_rounded,
                                  size: 14,
                                  color: changeColor(
                                    context,
                                    change,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '${change.abs().toStringAsFixed(2)}%',
                                  style: TextStyle(
                                    color: changeColor(
                                      context,
                                      change,
                                    ),
                                    fontWeight:
                                        FontWeight.w900,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (change == null)
                          Text(
                            tr(
                              context,
                              'live',
                            ),
                            style: TextStyle(
                              color: Colors.greenAccent
                                  .shade400,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        const Spacer(),
                        Text(
                          asset.symbol,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Sparkline(
                      values: _generateSparkline(asset),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<double> _generateSparkline(
    MarketAsset asset,
  ) {
    final seed = asset.code.codeUnits.fold<int>(
      0,
      (a, b) => a + b,
    );

    final random = math.Random(seed);

    final values = <double>[];

    double current = 50;

    for (int i = 0; i < 28; i++) {
      current +=
          (random.nextDouble() - .48) * 7;

      current = current.clamp(15, 85);

      values.add(current);
    }

    return values;
  }
}

// ============================================================
// HOME ASSET SELECTOR
// ============================================================

void showHomeAssetSelector(
  BuildContext context,
  AppController controller,
) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return SafeArea(
        child: Container(
          constraints: const BoxConstraints(
            maxHeight: 620,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context)
                .scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(32),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Theme.of(context)
                      .dividerColor,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  22,
                  22,
                  22,
                  12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        tr(
                          context,
                          'chooseHomePrice',
                        ),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          Navigator.pop(context),
                      icon: const Icon(
                        Icons.close_rounded,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding:
                      const EdgeInsets.fromLTRB(
                    18,
                    4,
                    18,
                    30,
                  ),
                  itemCount: controller.assets.length,
                  itemBuilder: (context, index) {
                    final asset =
                        controller.assets[index];

                    final selected =
                        asset.code ==
                            controller.selectedHomeAsset;

                    return Padding(
                      padding:
                          const EdgeInsets.only(
                        bottom: 10,
                      ),
                      child: Pressable(
                        onTap: () {
                          controller.selectHomeAsset(
                            asset.code,
                          );

                          Navigator.pop(context);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(
                            milliseconds: 220,
                          ),
                          padding:
                              const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(20),
                            color: selected
                                ? Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(.12)
                                : Theme.of(context)
                                    .colorScheme
                                    .surface,
                            border: Border.all(
                              color: selected
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primary
                                  : Theme.of(context)
                                      .dividerColor
                                      .withOpacity(.1),
                              width:
                                  selected ? 1.3 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              AssetIcon(
                                asset: asset,
                                size: 44,
                              ),
                              const SizedBox(width: 13),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      controller.language ==
                                              AppLanguage.fa
                                          ? asset.labelFa
                                          : asset.labelEn,
                                      style:
                                          const TextStyle(
                                        fontWeight:
                                            FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      asset.code,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                        fontWeight:
                                            FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                displayCompactPrice(
                                  asset,
                                  controller.language,
                                ),
                                style: const TextStyle(
                                  fontWeight:
                                      FontWeight.w900,
                                ),
                              ),
                              const SizedBox(width: 8),
                              AnimatedSwitcher(
                                duration:
                                    const Duration(
                                  milliseconds: 180,
                                ),
                                child: selected
                                    ? Icon(
                                        Icons
                                            .check_circle_rounded,
                                        key: const ValueKey(
                                          'selected',
                                        ),
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      )
                                    : const SizedBox(
                                        key: ValueKey(
                                          'notSelected',
                                        ),
                                        width: 24,
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

// ============================================================
// QUICK ACTIONS
// ============================================================

class QuickActions extends StatelessWidget {
  const QuickActions({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            tr(context, 'quickAccess'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 106,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              children: [
                QuickAction(
                  icon: Icons.attach_money_rounded,
                  title: tr(context, 'dollar'),
                  color: const Color(0xFF20D68B),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            const PricesScreen(
                          initialFilter:
                              PriceFilter.currency,
                          initialQuery: 'USD',
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                QuickAction(
                  icon: Icons.euro_rounded,
                  title: tr(context, 'euro'),
                  color: const Color(0xFF4D8DFF),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            const PricesScreen(
                          initialFilter:
                              PriceFilter.currency,
                          initialQuery: 'EUR',
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                QuickAction(
                  icon: Icons.monetization_on_rounded,
                  title: tr(context, 'gold'),
                  color: const Color(0xFFFFC857),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            const PricesScreen(
                          initialFilter:
                              PriceFilter.gold,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                QuickAction(
                  icon: Icons.currency_bitcoin_rounded,
                  title: tr(context, 'crypto'),
                  color: const Color(0xFFFF9D3D),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            const PricesScreen(
                          initialFilter:
                              PriceFilter.crypto,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class QuickAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const QuickAction({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Theme.of(context)
              .colorScheme
              .surface,
          border: Border.all(
            color: Theme.of(context)
                .dividerColor
                .withOpacity(.10),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(13),
                color: color.withOpacity(.13),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// MARKET OVERVIEW
// ============================================================

class MarketOverview extends StatelessWidget {
  const MarketOverview({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final controller = PingMarketScope.of(context);

    final visible = controller.assets
        .take(5)
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  tr(context, 'marketOverview'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          const PricesScreen(),
                    ),
                  );
                },
                child: Text(
                  tr(context, 'prices'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (visible.isEmpty)
            GlassCard(
              child: Center(
                child: Text(
                  tr(context, 'noData'),
                ),
              ),
            )
          else
            ...visible.map(
              (asset) => Padding(
                padding:
                    const EdgeInsets.only(
                  bottom: 10,
                ),
                child: AssetTile(
                  asset: asset,
                  compact: true,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// PRICES SCREEN
// ============================================================

class PricesScreen extends StatefulWidget {
  final PriceFilter initialFilter;
  final String initialQuery;

  const PricesScreen({
    super.key,
    this.initialFilter = PriceFilter.all,
    this.initialQuery = '',
  });

  @override
  State<PricesScreen> createState() =>
      _PricesScreenState();
}

class _PricesScreenState
    extends State<PricesScreen> {
  late PriceFilter filter;
  late TextEditingController searchController;

  @override
  void initState() {
    super.initState();

    filter = widget.initialFilter;

    searchController = TextEditingController(
      text: widget.initialQuery,
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = PingMarketScope.of(context);

    final items = controller.filterAssets(
      filter,
      searchController.text,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          tr(context, 'prices'),
          style: const TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          IconButton(
            onPressed: controller.refreshPrices,
            icon: controller.isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.refresh_rounded,
                  ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              4,
              20,
              10,
            ),
            child: TextField(
              controller: searchController,
              onChanged: (_) {
                setState(() {});
              },
              decoration: InputDecoration(
                hintText: tr(
                  context,
                  'search',
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                ),
                suffixIcon:
                    searchController.text.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              searchController.clear();
                              setState(() {});
                            },
                            icon: const Icon(
                              Icons.close_rounded,
                            ),
                          )
                        : null,
              ),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
              ),
              scrollDirection: Axis.horizontal,
              children: [
                FilterChipButton(
                  label: tr(context, 'all'),
                  selected:
                      filter == PriceFilter.all,
                  onTap: () {
                    setState(() {
                      filter = PriceFilter.all;
                    });
                  },
                ),
                const SizedBox(width: 8),
                FilterChipButton(
                  label: tr(context, 'currency'),
                  selected:
                      filter ==
                          PriceFilter.currency,
                  onTap: () {
                    setState(() {
                      filter =
                          PriceFilter.currency;
                    });
                  },
                ),
                const SizedBox(width: 8),
                FilterChipButton(
                  label: tr(context, 'gold'),
                  selected:
                      filter == PriceFilter.gold,
                  onTap: () {
                    setState(() {
                      filter = PriceFilter.gold;
                    });
                  },
                ),
                const SizedBox(width: 8),
                FilterChipButton(
                  label: tr(context, 'crypto'),
                  selected:
                      filter ==
                          PriceFilter.crypto,
                  onTap: () {
                    setState(() {
                      filter =
                          PriceFilter.crypto;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: controller.isLoading
                ? const LoadingList()
                : items.isEmpty
                    ? EmptyState(
                        icon:
                            Icons.search_off_rounded,
                        title: tr(
                          context,
                          'noResults',
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh:
                            controller.refreshPrices,
                        child: ListView.builder(
                          physics:
                              const AlwaysScrollableScrollPhysics(
                            parent:
                                BouncingScrollPhysics(),
                          ),
                          padding:
                              const EdgeInsets.fromLTRB(
                            20,
                            10,
                            20,
                            100,
                          ),
                          itemCount: items.length,
                          itemBuilder:
                              (context, index) {
                            final asset =
                                items[index];

                            return Padding(
                              padding:
                                  const EdgeInsets.only(
                                bottom: 10,
                              ),
                              child: AssetTile(
                                asset: asset,
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// FILTER CHIP
// ============================================================

class FilterChipButton
    extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const FilterChipButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration:
            const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          borderRadius:
              BorderRadius.circular(16),
          color: selected
              ? Theme.of(context)
                  .colorScheme
                  .primary
                  .withOpacity(.14)
              : Theme.of(context)
                  .colorScheme
                  .surface,
          border: Border.all(
            color: selected
                ? Theme.of(context)
                    .colorScheme
                    .primary
                : Theme.of(context)
                    .dividerColor
                    .withOpacity(.10),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? Theme.of(context)
                    .colorScheme
                    .primary
                : Theme.of(context)
                    .colorScheme
                    .onSurface,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ASSET TILE
// ============================================================

class AssetTile extends StatelessWidget {
  final MarketAsset asset;
  final bool compact;

  const AssetTile({
    super.key,
    required this.asset,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final controller = PingMarketScope.of(context);

    final isFavorite =
        controller.favorites.contains(
      asset.code,
    );

    final change = asset.change24h;

    return Pressable(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                DetailScreen(asset: asset),
          ),
        );
      },
      borderRadius: BorderRadius.circular(22),
      child: GlassCard(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 14 : 17,
          vertical: compact ? 13 : 16,
        ),
        borderRadius:
            BorderRadius.circular(22),
        child: Row(
          children: [
            AssetIcon(
              asset: asset,
              size: compact ? 43 : 48,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.language ==
                            AppLanguage.fa
                        ? asset.labelFa
                        : asset.labelEn,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize:
                          compact ? 13 : 14,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    asset.code,
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment:
                  CrossAxisAlignment.end,
              children: [
                Text(
                  displayPrice(
                    asset,
                    controller.language,
                  ),
                  style: TextStyle(
                    fontSize:
                        compact ? 13 : 14,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                if (change != null)
                  Text(
                    '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%',
                    style: TextStyle(
                      color: changeColor(
                        context,
                        change,
                      ),
                      fontSize: 10,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  )
                else
                  Text(
                    tr(context, 'live'),
                    style: TextStyle(
                      color: Colors.greenAccent
                          .shade400,
                      fontSize: 9,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 8),
            FavoriteButton(
              selected: isFavorite,
              onTap: () {
                controller.toggleFavorite(
                  asset.code,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// FAVORITE BUTTON
// ============================================================

class FavoriteButton extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;

  const FavoriteButton({
    super.key,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration:
            const Duration(milliseconds: 180),
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected
              ? const Color(0xFFFFC857)
                  .withOpacity(.13)
              : Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withOpacity(.045),
        ),
        child: AnimatedSwitcher(
          duration:
              const Duration(milliseconds: 180),
          transitionBuilder:
              (child, animation) {
            return ScaleTransition(
              scale: animation,
              child: child,
            );
          },
          child: Icon(
            selected
                ? Icons.star_rounded
                : Icons.star_outline_rounded,
            key: ValueKey(selected),
            color: selected
                ? const Color(0xFFFFC857)
                : Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant,
            size: 21,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// FAVORITES SCREEN
// ============================================================

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final controller = PingMarketScope.of(context);

    final items = controller.favoriteAssets;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          tr(context, 'favorites'),
          style: const TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: items.isEmpty
          ? EmptyState(
              icon: Icons.star_outline_rounded,
              title: tr(
                context,
                'noFavorites',
              ),
              subtitle: tr(
                context,
                'favoritesEmptyHint',
              ),
            )
          : ListView.builder(
              physics:
                  const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                20,
                10,
                20,
                100,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding:
                      const EdgeInsets.only(
                    bottom: 10,
                  ),
                  child: AssetTile(
                    asset: items[index],
                  ),
                );
              },
            ),
    );
  }
}

// ============================================================
// SETTINGS SCREEN
// ============================================================

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final controller = PingMarketScope.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          tr(context, 'settings'),
          style: const TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: ListView(
        physics:
            const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          20,
          10,
          20,
          100,
        ),
        children: [
          SettingsSectionTitle(
            title: tr(
              context,
              'appearance',
            ),
          ),
          SettingsTile(
            icon: controller.isDark
                ? Icons.dark_mode_rounded
                : Icons.light_mode_rounded,
            title: tr(
              context,
              'theme',
            ),
            subtitle: controller.isDark
                ? tr(context, 'dark')
                : tr(context, 'light'),
            trailing: Switch(
              value: controller.isDark,
              onChanged: (_) {
                controller.toggleTheme();
              },
            ),
            onTap: controller.toggleTheme,
          ),
          const SizedBox(height: 10),
          SettingsTile(
            icon: Icons.language_rounded,
            title: tr(
              context,
              'language',
            ),
            subtitle:
                controller.language ==
                        AppLanguage.fa
                    ? tr(context, 'persian')
                    : tr(context, 'english'),
            onTap: () {
              showLanguageDialog(
                context,
                controller,
              );
            },
          ),
          const SizedBox(height: 24),
          SettingsSectionTitle(
            title: tr(
              context,
              'information',
            ),
          ),
          SettingsTile(
            icon: Icons.support_agent_rounded,
            title: tr(
              context,
              'support',
            ),
            onTap: () {
              showInfoDialog(
                context,
                title: tr(
                  context,
                  'support',
                ),
                text: tr(
                  context,
                  'supportText',
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          SettingsTile(
            icon: Icons.info_outline_rounded,
            title: tr(
              context,
              'about',
            ),
            onTap: () {
              showInfoDialog(
                context,
                title: tr(
                  context,
                  'about',
                ),
                text: tr(
                  context,
                  'aboutText',
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          SettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: tr(
              context,
              'privacy',
            ),
            onTap: () {
              showInfoDialog(
                context,
                title: tr(
                  context,
                  'privacy',
                ),
                text: tr(
                  context,
                  'privacyText',
                ),
              );
            },
          ),
          const SizedBox(height: 30),
          Center(
            child: Text(
              'Ping Market • 1.0.0',
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant,
                fontSize: 11,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SETTINGS TILE
// ============================================================

class SettingsSectionTitle
    extends StatelessWidget {
  final String title;

  const SettingsSectionTitle({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 10,
      ),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context)
              .colorScheme
              .primary,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: .5,
        ),
      ),
    );
  }
}

class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      borderRadius:
          BorderRadius.circular(22),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(
          horizontal: 17,
          vertical: 15,
        ),
        borderRadius:
            BorderRadius.circular(22),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(15),
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withOpacity(.10),
              ),
              child: Icon(
                icon,
                color: Theme.of(context)
                    .colorScheme
                    .primary,
                size: 21,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                        fontSize: 11,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            trailing ??
                const Icon(
                  Icons
                      .arrow_forward_ios_rounded,
                  size: 15,
                ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// LANGUAGE DIALOG
// ============================================================

void showLanguageDialog(
  BuildContext context,
  AppController controller,
) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            20,
            18,
            20,
            28,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context)
                .scaffoldBackgroundColor,
            borderRadius:
                const BorderRadius.vertical(
              top: Radius.circular(30),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .dividerColor,
                    borderRadius:
                        BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                tr(context, 'chooseLanguage'),
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 15),
              LanguageOption(
                title: 'فارسی',
                subtitle: 'RTL',
                selected:
                    controller.language ==
                        AppLanguage.fa,
                onTap: () {
                  controller.setLanguage(
                    AppLanguage.fa,
                  );
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 10),
              LanguageOption(
                title: 'English',
                subtitle: 'LTR',
                selected:
                    controller.language ==
                        AppLanguage.en,
                onTap: () {
                  controller.setLanguage(
                    AppLanguage.en,
                  );
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

class LanguageOption
    extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const LanguageOption({
    super.key,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      borderRadius:
          BorderRadius.circular(20),
      child: AnimatedContainer(
        duration:
            const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius:
              BorderRadius.circular(20),
          color: selected
              ? Theme.of(context)
                  .colorScheme
                  .primary
                  .withOpacity(.12)
              : Theme.of(context)
                  .colorScheme
                  .surface,
          border: Border.all(
            color: selected
                ? Theme.of(context)
                    .colorScheme
                    .primary
                : Theme.of(context)
                    .dividerColor
                    .withOpacity(.10),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(
                Icons.check_circle_rounded,
                color: Theme.of(context)
                    .colorScheme
                    .primary,
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// INFO DIALOG
// ============================================================

void showInfoDialog(
  BuildContext context, {
  required String title,
  required String text,
}) {
  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        backgroundColor: Theme.of(context)
            .colorScheme
            .surface,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(28),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style:
                          const TextStyle(
                        fontSize: 19,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () =>
                        Navigator.pop(context),
                    icon: const Icon(
                      Icons.close_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                text,
                style: TextStyle(
                  height: 1.8,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () =>
                      Navigator.pop(context),
                  child: Text(
                    tr(context, 'done'),
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

// ============================================================
// DETAIL SCREEN
// ============================================================

class DetailScreen extends StatelessWidget {
  final MarketAsset asset;

  const DetailScreen({
    super.key,
    required this.asset,
  });

  @override
  Widget build(BuildContext context) {
    final controller =
        PingMarketScope.of(context);

    final isFavorite =
        controller.favorites.contains(
      asset.code,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          controller.language ==
                  AppLanguage.fa
              ? asset.labelFa
              : asset.labelEn,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          FavoriteButton(
            selected: isFavorite,
            onTap: () {
              controller.toggleFavorite(
                asset.code,
              );
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: ListView(
        physics:
            const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          20,
          10,
          20,
          50,
        ),
        children: [
          GlassCard(
            borderRadius:
                BorderRadius.circular(30),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AssetIcon(
                      asset: asset,
                      size: 58,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Text(
                            controller.language ==
                                    AppLanguage.fa
                                ? asset.labelFa
                                : asset.labelEn,
                            style:
                                const TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.w900,
                            ),
                          ),
                          const SizedBox(
                            height: 4,
                          ),
                          Text(
                            asset.code,
                            style: TextStyle(
                              color: Theme.of(
                                      context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontSize: 11,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Text(
                  displayPrice(
                    asset,
                    controller.language,
                  ),
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                if (asset.change24h != null)
                  Row(
                    children: [
                      Icon(
                        asset.change24h! >= 0
                            ? Icons
                                .trending_up_rounded
                            : Icons
                                .trending_down_rounded,
                        size: 18,
                        color: changeColor(
                          context,
                          asset.change24h,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${asset.change24h! >= 0 ? '+' : ''}${asset.change24h!.toStringAsFixed(2)}%',
                        style: TextStyle(
                          color: changeColor(
                            context,
                            asset.change24h,
                          ),
                          fontWeight:
                              FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 28),
                SizedBox(
                  height: 190,
                  child: Sparkline(
                    values:
                        _detailChart(asset),
                    strokeWidth: 3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          GlassCard(
            child: Column(
              children: [
                DetailRow(
                  title:
                      tr(context, 'price'),
                  value: displayPrice(
                    asset,
                    controller.language,
                  ),
                ),
                const Divider(height: 24),
                DetailRow(
                  title:
                      tr(context, 'change24h'),
                  value:
                      asset.change24h == null
                          ? '—'
                          : '${asset.change24h! >= 0 ? '+' : ''}${asset.change24h!.toStringAsFixed(2)}%',
                ),
                const Divider(height: 24),
                DetailRow(
                  title: 'Code',
                  value: asset.code,
                ),
                const Divider(height: 24),
                DetailRow(
                  title: 'Unit',
                  value: asset.quoteUnit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<double> _detailChart(
    MarketAsset asset,
  ) {
    final seed = asset.code.codeUnits.fold<int>(
      0,
      (a, b) => a * 31 + b,
    );

    final random = math.Random(seed);

    final result = <double>[];

    double current = 48;

    for (int i = 0; i < 40; i++) {
      current +=
          (random.nextDouble() - .47) * 5;

      current = current.clamp(8, 92);

      result.add(current);
    }

    return result;
  }
}

class DetailRow extends StatelessWidget {
  final String title;
  final String value;

  const DetailRow({
    super.key,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant,
              fontSize: 12,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight:
                FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// ASSET ICON
// ============================================================

class AssetIcon extends StatelessWidget {
  final MarketAsset asset;
  final double size;

  const AssetIcon({
    super.key,
    required this.asset,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    final isCrypto = asset.isCrypto;
    final isGold = asset.isGold;

    final color = isCrypto
        ? const Color(0xFFFFA43D)
        : isGold
            ? const Color(0xFFFFC857)
            : Theme.of(context)
                .colorScheme
                .primary;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(
          size * .30,
        ),
        color: color.withOpacity(.11),
      ),
      alignment: Alignment.center,
      child: Text(
        asset.icon,
        style: TextStyle(
          fontSize: size * .43,
        ),
      ),
    );
  }
}

// ============================================================
// SPARKLINE
// ============================================================

class Sparkline extends StatefulWidget {
  final List<double> values;
  final double strokeWidth;

  const Sparkline({
    super.key,
    required this.values,
    this.strokeWidth = 2.5,
  });

  @override
  State<Sparkline> createState() =>
      _SparklineState();
}

class _SparklineState
    extends State<Sparkline>
    with SingleTickerProviderStateMixin {
  late AnimationController animationController;

  @override
  void initState() {
    super.initState();

    animationController =
        AnimationController(
      vsync: this,
      duration:
          const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController,
      builder: (context, _) {
        return CustomPaint(
          painter: SparklinePainter(
            values: widget.values,
            progress:
                Curves.easeOutCubic.transform(
              animationController.value,
            ),
            strokeWidth:
                widget.strokeWidth,
            color: Theme.of(context)
                .colorScheme
                .primary,
          ),
          size: const Size(
            double.infinity,
            double.infinity,
          ),
        );
      },
    );
  }
}

class SparklinePainter
    extends CustomPainter {
  final List<double> values;
  final double progress;
  final double strokeWidth;
  final Color color;

  SparklinePainter({
    required this.values,
    required this.progress,
    required this.strokeWidth,
    required this.color,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    if (values.isEmpty) return;

    final path = Path();

    final count = math.max(
      2,
      (values.length * progress)
          .ceil(),
    );

    final visible =
        values.take(count).toList();

    final minValue =
        values.reduce(math.min);

    final maxValue =
        values.reduce(math.max);

    final range =
        (maxValue - minValue)
            .abs() <
            .001
            ? 1
            : maxValue - minValue;

    for (int i = 0;
        i < visible.length;
        i++) {
      final x = visible.length == 1
          ? 0
          : size.width *
              i /
              (visible.length - 1);

      final normalized =
          (visible[i] - minValue) /
              range;

      final y = size.height -
          (normalized *
              (size.height * .72)) -
          (size.height * .14);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final previousX =
            size.width *
                (i - 1) /
                (visible.length - 1);

        final previousNormalized =
            (visible[i - 1] -
                    minValue) /
                range;

        final previousY =
            size.height -
                (previousNormalized *
                    (size.height *
                        .72)) -
                (size.height * .14);

        final controlX =
            (previousX + x) / 2;

        path.cubicTo(
          controlX,
          previousY,
          controlX,
          y,
          x,
          y,
        );
      }
    }

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin =
          StrokeJoin.round;

    canvas.drawPath(
      path,
      paint,
    );

    if (visible.isNotEmpty) {
      final lastX =
          visible.length == 1
              ? 0
              : size.width;

      final lastNormalized =
          (visible.last - minValue) /
              range;

      final lastY =
          size.height -
              (lastNormalized *
                  (size.height *
                      .72)) -
              (size.height * .14);

      final dotPaint = Paint()
        ..color = color
        ..style =
            PaintingStyle.fill;

      canvas.drawCircle(
        Offset(lastX, lastY),
        strokeWidth + 1,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant SparklinePainter oldDelegate,
  ) {
    return oldDelegate.progress !=
            progress ||
        oldDelegate.values != values ||
        oldDelegate.color != color;
  }
}

// ============================================================
// LOADING
// ============================================================

class LoadingCard extends StatelessWidget {
  const LoadingCard({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius:
          BorderRadius.circular(30),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          ShimmerBox(
            width: 180,
            height: 18,
          ),
          const SizedBox(height: 25),
          ShimmerBox(
            width: 230,
            height: 42,
          ),
          const SizedBox(height: 20),
          ShimmerBox(
            width: double.infinity,
            height: 80,
          ),
        ],
      ),
    );
  }
}

class LoadingList extends StatelessWidget {
  const LoadingList({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 7,
      itemBuilder: (context, index) {
        return Padding(
          padding:
              const EdgeInsets.only(
            bottom: 10,
          ),
          child: GlassCard(
            child: Row(
              children: [
                const ShimmerBox(
                  width: 48,
                  height: 48,
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(
                        width: 130,
                        height: 14,
                      ),
                      SizedBox(height: 8),
                      ShimmerBox(
                        width: 80,
                        height: 10,
                      ),
                    ],
                  ),
                ),
                const ShimmerBox(
                  width: 90,
                  height: 15,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ShimmerBox
    extends StatefulWidget {
  final double width;
  final double height;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
  });

  @override
  State<ShimmerBox> createState() =>
      _ShimmerBoxState();
}

class _ShimmerBoxState
    extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;

  @override
  void initState() {
    super.initState();

    controller =
        AnimationController(
      vsync: this,
      duration:
          const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(10),
            gradient: LinearGradient(
              begin: Alignment(
                -1.5 +
                    controller.value * 3,
                0,
              ),
              end: Alignment(
                -.5 +
                    controller.value * 3,
                0,
              ),
              colors: [
                dark
                    ? Colors.white
                        .withOpacity(.045)
                    : Colors.black
                        .withOpacity(.045),
                dark
                    ? Colors.white
                        .withOpacity(.10)
                    : Colors.black
                        .withOpacity(.085),
                dark
                    ? Colors.white
                        .withOpacity(.045)
                    : Colors.black
                        .withOpacity(.045),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================
// ERROR
// ============================================================

class ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorCard({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius:
          BorderRadius.circular(28),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFF5577)
                  .withOpacity(.12),
            ),
            child: const Icon(
              Icons.cloud_off_rounded,
              color: Color(0xFFFF5577),
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            tr(
              context,
              'failedToLoad',
            ),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
            label: Text(
              tr(context, 'retry'),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// EMPTY STATE
// ============================================================

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withOpacity(.10),
              ),
              child: Icon(
                icon,
                size: 34,
                color: Theme.of(context)
                    .colorScheme
                    .primary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant,
                  fontSize: 12,
                  height: 1.6,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}