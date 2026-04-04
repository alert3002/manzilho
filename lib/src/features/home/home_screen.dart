import 'dart:async';
import 'dart:ui';
import 'dart:math' show min;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/home_refresh_provider.dart';
import '../../app/theme.dart';
import '../../core/api_client.dart';
import '../../widgets/app_footer_info.dart';
import '../../widgets/shimmer.dart';
import 'widgets/listing_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _slideController = PageController();
  Timer? _slideTimer;
  List<dynamic> slides = [];
  int currentSlide = 0;
  String activeTab = 'buy'; // buy | rent | daily | evaluate
  List<dynamic> topListings = [];
  List<dynamic> regularListings = [];
  bool topLoading = true;
  bool regularLoading = true;
  List<dynamic> realtors = [];
  List<dynamic> agencies = [];
  List<dynamic> developers = [];
  int _topDisplayCount = 20;
  int _regularDisplayCount = 20;

  @override
  void initState() {
    super.initState();
    _loadSlider();
    _loadFeed();
  }

  void _loadSlider() {
    dio.get('/api/listings/slider/').then((r) {
      if (mounted && r.data is List) setState(() => slides = r.data as List);
    }).catchError((_) {});
  }

  void _loadFeed() {
    setState(() { topLoading = true; regularLoading = true; });
    dio.get('/api/listings/top-listings/').then((r) {
      if (mounted) setState(() { topListings = r.data is List ? r.data as List : []; topLoading = false; });
    }).catchError((_) { if (mounted) setState(() => topLoading = false); });

    dio.get('/api/listings/list/').then((r) {
      if (!mounted) return;
      final items = r.data is List ? r.data as List : [];
      bool isTopActive(dynamic item) {
        if (item is! Map) return false;
        if (item['top_tariff'] == null) return false;
        final until = item['top_paid_until'];
        if (until == null) return true;
        try {
          final dt = DateTime.tryParse(until.toString());
          return dt != null && dt.isAfter(DateTime.now());
        } catch (_) { return true; }
      }
      setState(() {
        regularListings = items.where((e) => !isTopActive(e)).toList();
        regularLoading = false;
      });
    }).catchError((_) { if (mounted) setState(() => regularLoading = false); });

    dio.get('/api/auth/realtors/').then((r) {
      if (mounted) setState(() => realtors = ensureArray(r.data));
    }).catchError((_) {});
    dio.get('/api/auth/agencies/').then((r) {
      if (mounted) setState(() => agencies = ensureArray(r.data));
    }).catchError((_) {});
    dio.get('/api/auth/developers/').then((r) {
      if (mounted) setState(() => developers = ensureArray(r.data));
    }).catchError((_) {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (slides.length > 1 && _slideTimer?.isActive != true) {
      _slideTimer?.cancel();
      _slideTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!mounted || slides.length <= 1) return;
        final next = (currentSlide + 1) % slides.length;
        _slideController.animateToPage(next, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
      });
    }
  }

  @override
  void dispose() {
    _slideTimer?.cancel();
    _slideController.dispose();
    super.dispose();
  }

  void _onHeroFind(BuildContext context) {
    if (activeTab == 'evaluate') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Скоро: запрос оценки объекта.')),
      );
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(homeRefreshTickProvider, (previous, next) {
      if (previous == null) return;
      _loadSlider();
      _loadFeed();
    });

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const int pageSize = 20; /* дар приложения ҳамеша 20 шт ва кнопка */

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ——— HERO + SLIDER (ба монанди сайт) ———
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.78,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (slides.isEmpty)
                  Container(color: const Color(0xFF222222))
                else
                  PageView.builder(
                    controller: _slideController,
                    onPageChanged: (i) => setState(() => currentSlide = i),
                    itemCount: slides.length,
                    itemBuilder: (_, i) {
                      final slide = slides[i] is Map ? slides[i] as Map<String, dynamic> : <String, dynamic>{};
                      final img = slide['image']?.toString() ?? '';
                      return Container(
                        decoration: BoxDecoration(
                          image: img.isNotEmpty
                              ? DecorationImage(image: NetworkImage(img), fit: BoxFit.cover)
                              : null,
                          color: img.isEmpty ? const Color(0xFF222222) : null,
                        ),
                      );
                    },
                  ),
                // overlay — торик + blur; каме равшантар то матн зиёд пайда шавад
                Positioned.fill(
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                      child: Container(color: const Color(0x99000000)),
                    ),
                  ),
                ),
                // нишонаҳои слайд (dots) — дар поёни слайдер
                if (slides.length > 1)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 16,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(slides.length, (i) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: currentSlide == i ? 10 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: currentSlide == i ? BoxShape.rectangle : BoxShape.circle,
                          borderRadius: currentSlide == i ? BorderRadius.circular(3) : null,
                          color: Colors.white.withValues(alpha: currentSlide == i ? 1 : 0.5),
                        ),
                      )),
                    ),
                  ),
                // тугмаҳои слайдер ‹ ›
                if (slides.length > 1) ...[
                  Positioned(
                    left: 12,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _SliderBtn(
                        onPressed: () {
                          final prev = (currentSlide - 1 + slides.length) % slides.length;
                          _slideController.animateToPage(prev, duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
                        },
                        child: const Text('‹', style: TextStyle(color: Colors.white, fontSize: 28)),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _SliderBtn(
                        onPressed: () {
                          final next = (currentSlide + 1) % slides.length;
                          _slideController.animateToPage(next, duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
                        },
                        child: const Text('›', style: TextStyle(color: Colors.white, fontSize: 28)),
                      ),
                    ),
                  ),
                ],
                // заголовок + табҳо + қуттии ҷустуҷӯ — дар МИЁНАИ слайдер (ва матн зиёд пайда)
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // «Если недвижимость, то Manzilho.tj» — калонтар, сояи қавӣ барои хонандагӣ
                            RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  height: 1.3,
                                  shadows: [
                                    Shadow(color: Color(0xCC000000), blurRadius: 12, offset: Offset(0, 2)),
                                    Shadow(color: Color(0x99000000), blurRadius: 4, offset: Offset(0, 1)),
                                  ],
                                ),
                                children: const [
                                  TextSpan(text: 'Если недвижимость, то\n'),
                                  TextSpan(text: 'Manzilho.tj', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _HeroTab(label: 'Купить', isActive: activeTab == 'buy', onTap: () => setState(() => activeTab = 'buy')),
                              _HeroTab(label: 'Снять', isActive: activeTab == 'rent', onTap: () => setState(() => activeTab = 'rent')),
                              _HeroTab(label: 'Посуточно', isActive: activeTab == 'daily', onTap: () => setState(() => activeTab = 'daily')),
                              _HeroTab(label: 'Оценить', isActive: activeTab == 'evaluate', onTap: () => setState(() => activeTab = 'evaluate')),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        // қуттии ҷустуҷӯ
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1a1a1a),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: manzilhoOrange.withValues(alpha: 0.22)),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.45), blurRadius: 28, offset: const Offset(0, 14)),
                              BoxShadow(color: manzilhoOrange.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Column(
                            children: [
                              if (activeTab == 'buy' || activeTab == 'rent') ...[
                                _HeroSearchSelect(items: const ['Квартиру в новостройке', 'Квартиру вторичку', 'Дом (Хавли)', 'Офис'], hint: 'Квартиру в новостройке'),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(child: _HeroSearchSelect(items: const ['Комнат', '1', '2', '3+'], hint: 'Комнат')),
                                    const SizedBox(width: 8),
                                    Expanded(child: _HeroSearchInput(placeholder: 'Цена до...')),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                _HeroSearchInput(placeholder: 'Город, район, улица...'),
                              ],
                              if (activeTab == 'daily') ...[
                                _HeroSearchInput(placeholder: 'Куда вы хотите поехать?'),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(child: _HeroSearchSelect(items: const ['Квартиру', 'Дом'], hint: 'Квартиру')),
                                    const SizedBox(width: 8),
                                    Expanded(child: _HeroSearchSelect(items: const ['1 гость', '2 гостя'], hint: '1 гость')),
                                    const SizedBox(width: 8),
                                    Expanded(child: _HeroSearchInput(placeholder: 'Заезд — Отъезд')),
                                  ],
                                ),
                              ],
                              if (activeTab == 'evaluate') _HeroSearchInput(placeholder: 'Адрес или описание объекта для оценки...'),
                              const SizedBox(height: 14),
                              _HeroFindButton(onPressed: () => _onHeroFind(context)),
                            ],
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
          ), // SizedBox
          // ——— SECTIONS ———
          // ТОП: агар бор шуд ва рӯйхат холӣ бошад — тамоман пинҳон (бе placeholder)
          if (topLoading)
            _SectionContainer(
              title: 'ТОП объявления',
              subtitle: 'Лучшие предложения от наших партнеров',
              child: const _ListingsSkeleton(),
            )
          else if (topListings.isNotEmpty)
            _SectionContainer(
              title: 'ТОП объявления',
              subtitle: 'Лучшие предложения от наших партнеров',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.62, crossAxisSpacing: 18, mainAxisSpacing: 18),
                    itemCount: min(_topDisplayCount, topListings.length),
                    itemBuilder: (_, i) => ListingCard(listing: topListings[i] is Map ? topListings[i] as Map<String, dynamic> : {}),
                  ),
                  if (topListings.length > _topDisplayCount)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Center(
                        child: TextButton(
                          onPressed: () => setState(() => _topDisplayCount += pageSize),
                          style: TextButton.styleFrom(
                            foregroundColor: theme.colorScheme.onSurface,
                            side: BorderSide(color: theme.colorScheme.outline),
                            shape: const StadiumBorder(),
                          ),
                          child: const Text('Загрузить ещё'),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          _SectionContainer(
            title: 'Объявления',
            subtitle: 'Обычные объявления',
            child: regularLoading
                ? const _ListingsSkeleton()
                : regularListings.isEmpty
                    ? const _EmptyListingsPlaceholder()
                    : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.62, crossAxisSpacing: 18, mainAxisSpacing: 18),
                        itemCount: min(_regularDisplayCount, regularListings.length),
                        itemBuilder: (_, i) => ListingCard(listing: regularListings[i] is Map ? regularListings[i] as Map<String, dynamic> : {}),
                      ),
                      if (regularListings.length > _regularDisplayCount)
                        Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: Center(
                            child: TextButton(
                              onPressed: () => setState(() => _regularDisplayCount += pageSize),
                              style: TextButton.styleFrom(
                                foregroundColor: theme.colorScheme.onSurface,
                                side: BorderSide(color: theme.colorScheme.outline),
                                shape: const StadiumBorder(),
                              ),
                              child: const Text('Загрузить ещё'),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
          _MotivationSection(isDark: isDark),
          _AuthorsSection(title: 'Риелторы', subtitle: 'Проверенные специалисты', items: realtors, isCircle: true, emptyLabel: 'Пока нет данных.', allLabel: 'Все риелторы'),
          _AuthorsSection(title: 'Агентства', subtitle: 'Лучшие агентства недвижимости', items: agencies, isCircle: false, emptyLabel: 'Пока нет данных.', allLabel: 'Все агентства'),
          _AuthorsSection(title: 'Застройщики', subtitle: 'Новостройки и застройщики недвижимости', items: developers, isCircle: false, emptyLabel: 'Пока нет данных.', allLabel: 'Все застройщики'),
          const SizedBox(height: 18),
          const AppFooterInfo(),
          const SizedBox(height: 18),
        ],
      ),
    );
  }
}

class _SliderBtn extends StatelessWidget {
  const _SliderBtn({required this.onPressed, required this.child});
  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0x80000000),
      shape: const CircleBorder(),
      child: InkWell(onTap: onPressed, customBorder: const CircleBorder(), child: SizedBox(width: 40, height: 40, child: Center(child: child))),
    );
  }
}

/// Таб дар hero: торик, матни сафед; актив каме торики дигар.
class _HeroTab extends StatelessWidget {
  const _HeroTab({required this.label, required this.isActive, required this.onTap});
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 5),
      child: Material(
        color: isActive ? const Color(0xFF2c2c2c) : const Color(0x66000000),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        child: InkWell(
          onTap: onTap,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Center(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600))),
          ),
        ),
      ),
    );
  }
}

/// Майдони ҷустуҷӯ — фон равшан, канорҳои нарм, сояи сабук.
class _HeroSearchInput extends StatelessWidget {
  const _HeroSearchInput({required this.placeholder});
  final String placeholder;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFfafafa),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      alignment: Alignment.centerLeft,
      child: TextField(
        style: const TextStyle(color: Color(0xFF1a1a1a), fontSize: 14, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.w400),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

class _HeroSearchSelect extends StatelessWidget {
  const _HeroSearchSelect({required this.items, required this.hint});
  final List<String> items;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFfafafa),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(hint) ? hint : items.first,
          isExpanded: true,
          isDense: true,
          icon: Icon(Icons.expand_more_rounded, color: Colors.grey.shade700, size: 22),
          style: const TextStyle(color: Color(0xFF1a1a1a), fontSize: 14, fontWeight: FontWeight.w500),
          dropdownColor: const Color(0xFFfafafa),
          borderRadius: BorderRadius.circular(12),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: (_) {},
        ),
      ),
    );
  }
}

/// Тугмаи «Найти» — градиент норанҷӣ, соя, иконка ҷустуҷӯ.
class _HeroFindButton extends StatelessWidget {
  const _HeroFindButton({required this.onPressed});
  final VoidCallback onPressed;

  static const _orangeDeep = Color(0xFFc76b1a);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              colors: [manzilhoOrange, _orangeDeep],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(color: manzilhoOrange.withValues(alpha: 0.45), blurRadius: 16, offset: const Offset(0, 6)),
              BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.search_rounded, color: Colors.white, size: 22),
                SizedBox(width: 10),
                Text('Найти', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 0.3)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionContainer extends StatelessWidget {
  const _SectionContainer({required this.title, required this.subtitle, required this.child});
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _ListingsSkeleton extends StatelessWidget {
  const _ListingsSkeleton();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.75, crossAxisSpacing: 18, mainAxisSpacing: 18),
      itemCount: 4,
      itemBuilder: (_, i) => ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: DecoratedBox(
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: ShimmerBox(radius: 14),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(10, 0, 10, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(height: 14, radius: 10),
                    SizedBox(height: 8),
                    ShimmerBox(height: 12, width: 110, radius: 10),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Вақте объявление нест — логотип ва матн мобайнба нишон дода мешаванд.
class _EmptyListingsPlaceholder extends StatelessWidget {
  const _EmptyListingsPlaceholder();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/logo512.png',
              height: 80,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(Icons.home_rounded, size: 64, color: theme.colorScheme.outline),
            ),
            const SizedBox(height: 16),
            Text(
              'Пока нет объявлений',
              style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
            ),
          ],
        ),
      ),
    );
  }
}

class _MotivationSection extends StatelessWidget {
  const _MotivationSection({required this.isDark});
  final bool isDark;

  static const _slateGradient = [Color(0xFF334155), Color(0xFF1e293b)];
  static const _accentGradient = [Color(0xFFea8c2e), Color(0xFFc76b1a)];
  static const _tealGradient = [Color(0xFF0d9488), Color(0xFF0f766e)];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 44),
      child: Column(
        children: [
          _MotivationCard(
            gradient: _slateGradient,
            icon: Icons.apartment,
            title: 'Выгодная покупка новостроек',
            text: 'Актуальные объекты от застройщиков. Спецпредложения и скидки — подберите вариант под бюджет.',
          ),
          const SizedBox(height: 20),
          _MotivationCard(
            gradient: _accentGradient,
            icon: Icons.home_work,
            title: 'Ипотека на выгодных условиях',
            text: 'Ставки от 14% годовых. Помощь в оформлении и одобрении — жильё в новостройках доступнее.',
          ),
          const SizedBox(height: 20),
          _MotivationCard(
            gradient: _tealGradient,
            icon: Icons.lock_open,
            title: 'Аренда квартир без посредников',
            text: 'Проверенные объявления, быстрый отклик. Снимайте жильё в новостройках удобно и безопасно.',
          ),
        ],
      ),
    );
  }
}

class _MotivationCard extends StatelessWidget {
  const _MotivationCard({required this.gradient, required this.icon, required this.title, required this.text});
  final List<Color> gradient;
  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: gradient),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 24, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 18),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Text(text, style: TextStyle(color: Colors.white.withValues(alpha: 0.95), fontSize: 13, height: 1.58)),
        ],
      ),
    );
  }
}

class _AuthorsSection extends StatelessWidget {
  const _AuthorsSection({
    required this.title,
    required this.subtitle,
    required this.items,
    required this.isCircle,
    required this.emptyLabel,
    required this.allLabel,
  });
  final String title;
  final String subtitle;
  final List<dynamic> items;
  final bool isCircle;
  final String emptyLabel;
  final String allLabel;

  static const brandPrimary = Color(0xFF1a3c55);
  static const brandAccent = Color(0xFFe79a3e);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final list = items.take(10).toList(); /* риелторҳо 10, агентство 10, застройщики 10 */
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark ? const Color(0xFF1e1e1e) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleLarge?.copyWith(color: brandPrimary, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF6b7280))),
          const SizedBox(height: 16),
          if (list.isEmpty)
            Text(emptyLabel, style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF6b7280)))
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 2.2, crossAxisSpacing: 10, mainAxisSpacing: 10),
              itemCount: list.length,
              itemBuilder: (_, i) {
                final item = list[i] is Map ? list[i] as Map<String, dynamic> : <String, dynamic>{};
                final name = item['name'] ?? item['full_name'] ?? (isCircle ? 'Риелтор' : 'Агентство');
                final avatar = item['avatar']?.toString();
                final count = item['listings_count'] ?? 0;
                return InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(9999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: brandPrimary),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(isCircle ? 20 : 8),
                          child: avatar != null && avatar.isNotEmpty
                              ? Image.network(getImageUrl(avatar), width: 36, height: 36, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _AuthorPlaceholder(name: name, isCircle: isCircle, size: 36))
                              : _AuthorPlaceholder(name: name, isCircle: isCircle, size: 36),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(name.toString(), style: const TextStyle(color: brandPrimary, fontWeight: FontWeight.w600, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text(count > 0 ? '$count предложений' : (isCircle ? 'Агент' : 'Агентство'), style: const TextStyle(color: Color(0xFF6b7280), fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              backgroundColor: brandAccent,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(), /* овальный / pill */
            ),
            child: Text(allLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _AuthorPlaceholder extends StatelessWidget {
  const _AuthorPlaceholder({required this.name, required this.isCircle, this.size = 40});
  final String name;
  final bool isCircle;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF1f2937),
        borderRadius: BorderRadius.circular(isCircle ? size / 2 : 8),
      ),
      child: Center(child: Text((name.toString().isNotEmpty ? name.toString()[0] : '?').toUpperCase(), style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: size * 0.35))),
    );
  }
}
