import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tack_icons.dart';

/// About Tack screen with Privacy & Legal and Open Source tabs.
class AboutTackScreen extends StatefulWidget {
  const AboutTackScreen({super.key});

  @override
  State<AboutTackScreen> createState() => _AboutTackScreenState();
}

class _AboutTackScreenState extends State<AboutTackScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _lastTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (!mounted) return;
    if (_tabController.index != _lastTabIndex) {
      _lastTabIndex = _tabController.index;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Scaffold(
      backgroundColor: tokens.canvasPrimary,
      appBar: AppBar(
        backgroundColor: tokens.canvasPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: TackIcon(TackIcons.back, size: 20, color: tokens.textPrimary),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
          },
          tooltip: 'Back',
        ),
        title: Text(
          'About Tack',
          style: AppTypography.title(color: tokens.textPrimary),
        ),
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSpacing.readMaxWidth,
            ),
            child: Column(
              children: [
                // Compact Editorial App Identity Header
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenGutter(
                      MediaQuery.sizeOf(context).width,
                    ),
                    vertical: AppSpacing.s2,
                  ),
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    padding: const EdgeInsets.all(AppSpacing.s4),
                    decoration: ShapeDecoration(
                      color: tokens.surfacePrimary,
                      shape: SmoothRectangleBorder(
                        borderRadius: AppSpacing.roundedMd,
                        smoothness: AppSpacing.defaultSmoothing,
                        side: BorderSide(color: tokens.borderSubtle, width: 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            'icon.png',
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            cacheWidth: 144,
                            errorBuilder: (context, error, stackTrace) =>
                                TackIcon(
                                  TackIcons.notes,
                                  size: 32,
                                  color: tokens.accentPin,
                                ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s3),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      'Tack',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.titleLg(
                                        color: tokens.textPrimary,
                                        fontSize: 20,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.s2),
                                  Text(
                                    'v2.0.0',
                                    style: AppTypography.mono(
                                      fontSize: 12,
                                      weight: FontWeight.w600,
                                      color: tokens.textTertiary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Offline-first notes, tasks & visual boards',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodySm(
                                  color: tokens.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.s2),

                // Segmented Tab Selector
                Container(
                  margin: EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenGutter(
                      MediaQuery.sizeOf(context).width,
                    ),
                  ),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: tokens.canvasSunken,
                    borderRadius: AppSpacing.roundedPill,
                  ),
                  child: TabBar(
                    controller: _tabController,
                    onTap: (_) => HapticFeedback.selectionClick(),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    splashFactory: NoSplash.splashFactory,
                    overlayColor: WidgetStateProperty.all(Colors.transparent),
                    splashBorderRadius: AppSpacing.roundedPill,
                    labelPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s2,
                    ),
                    indicator: BoxDecoration(
                      color: tokens.actionPrimary,
                      borderRadius: AppSpacing.roundedPill,
                    ),
                    labelColor: tokens.actionPrimaryFg,
                    unselectedLabelColor: tokens.textSecondary,
                    labelStyle: AppTypography.label(
                      color: tokens.actionPrimaryFg,
                      weight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: AppTypography.label(
                      color: tokens.textSecondary,
                      weight: FontWeight.w500,
                    ),
                    tabs: const [
                      Tab(
                        height: 40,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('Privacy & Legal'),
                        ),
                      ),
                      Tab(
                        height: 40,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('Open Source'),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.s3),

                Expanded(
                  child: IndexedStack(
                    index: _tabController.index,
                    children: [
                      _buildPrivacyLegalTab(tokens),
                      _buildOpenSourceTab(tokens),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupedSurface({
    required TackTokens tokens,
    required List<Widget> children,
  }) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: tokens.surfacePrimary,
        shape: SmoothRectangleBorder(
          borderRadius: AppSpacing.roundedMd,
          smoothness: AppSpacing.defaultSmoothing,
          side: BorderSide(color: tokens.borderSubtle, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                indent: AppSpacing.s4,
                endIndent: AppSpacing.s4,
                color: tokens.borderSubtle,
              ),
            children[i],
          ],
        ],
      ),
    );
  }

  Widget _buildPrivacyLegalTab(TackTokens tokens) {
    final gutter = AppSpacing.screenGutter(MediaQuery.sizeOf(context).width);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    final policies = [
      (
        paletteId: 'cyan',
        title: 'Local-First Storage & Zero Telemetry',
        body:
            'Tack stores all notes, tasks, folders, whiteboards, and preferences exclusively in your '
            'device app storage. Tack contains no analytics SDKs, ad trackers, user accounts, or remote servers.',
      ),
      (
        paletteId: 'lime',
        title: 'Android Cloud Backup Disabled',
        body:
            'Automatic OS cloud backup is disabled in the app manifest (allowBackup=false) so private workspace '
            'notes are never synced to third-party cloud storage automatically.',
      ),
      (
        paletteId: 'amber',
        title: 'Notifications & Task Reminders',
        body:
            'Notification and exact-alarm permissions are requested only when you schedule a task reminder '
            'or pin a note to the notification shade. Alarms execute locally on Android AlarmManager.',
      ),
      (
        paletteId: 'peach',
        title: 'Photos, Camera & Clipboard Access',
        body:
            'Images are copied into internal app storage only when picked or captured by you. Clipboard text is '
            'read strictly on explicit Paste actions, and shared exports leave the device only via apps you choose.',
      ),
      (
        paletteId: 'lavender',
        title: 'Software Notice & Data Responsibility',
        body:
            'Tack Notes (v2.0.0) is provided as local productivity software without warranty. Because there is no '
            'cloud sync, please use Export Backup in Settings periodically to safeguard important notes.',
      ),
    ];

    return ListView(
      padding: EdgeInsets.fromLTRB(
        gutter,
        AppSpacing.s1,
        gutter,
        AppSpacing.s5 + bottomInset,
      ),
      physics: const ClampingScrollPhysics(),
      children: [
        _buildGroupedSurface(
          tokens: tokens,
          children: policies.map((item) {
            final headingColor = AppColors.getPaletteById(item.paletteId)
                .resolveAccentColor(tokens.isDark);
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: AppTypography.titleSm(
                      color: headingColor,
                      fontSize: 16.5,
                      weight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.body,
                    style: AppTypography.bodySm(color: tokens.textSecondary),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildOpenSourceTab(TackTokens tokens) {
    final packages = [
      const _OssPackage(
        name: 'flutter',
        author: 'Google LLC',
        version: 'Dart SDK ^3.13.1',
        license: 'BSD-3-Clause',
        role: 'Cross-platform reactive UI framework and rendering engine.',
      ),
      const _OssPackage(
        name: 'provider',
        author: 'Remi Rousselet',
        version: '^6.1.2',
        license: 'MIT',
        role: 'State management and dependency injection for workspace and themes.',
      ),
      const _OssPackage(
        name: 'google_fonts',
        author: 'Material Design & Google',
        version: '^9.0.0',
        license: 'Apache-2.0 / OFL',
        role: 'Typography engine delivering DM Sans for UI and JetBrains Mono for code previews.',
      ),
      const _OssPackage(
        name: 'tabler_icons_plus',
        author: 'Tabler & Paweł Kuna',
        version: '^3.52.0',
        license: 'MIT',
        role: 'Unified 2px rounded-stroke and filled iconography across workspace controls.',
      ),
      const _OssPackage(
        name: 'flutter_math_fork',
        author: 'Flutter Math Contributors',
        version: '^0.7.4',
        license: 'Apache-2.0',
        role: 'Inline and block KaTeX math formula typesetting inside notes.',
      ),
      const _OssPackage(
        name: 'pdf & printing',
        author: 'David PHAM-VAN',
        version: '^3.13.0 / ^5.15.0',
        license: 'Apache-2.0',
        role: 'Native multi-page document layout and vector PDF export engine.',
      ),
      const _OssPackage(
        name: 'share_plus',
        author: 'Flutter Community',
        version: '^13.3.0',
        license: 'BSD-3-Clause',
        role:
            'Android platform sharing intents for backups, notes, and exports.',
      ),
      const _OssPackage(
        name: 'path_provider',
        author: 'Flutter Team',
        version: '^2.1.6',
        license: 'BSD-3-Clause',
        role: 'Android file system directory resolution for offline JSON storage.',
      ),
      const _OssPackage(
        name: 'image_picker & image',
        author: 'Flutter Team & Brendan Duncan',
        version: '^1.2.3 / ^4.9.2',
        license: 'BSD-3-Clause / Apache-2.0',
        role: 'Device media integration and pure Dart PNG rasterization.',
      ),
      const _OssPackage(
        name: 'shared_preferences',
        author: 'Flutter Team',
        version: '^2.5.5',
        license: 'BSD-3-Clause',
        role: 'Lightweight on-device persistent key-value store for app settings.',
      ),
      const _OssPackage(
        name: 'url_launcher & vector_math',
        author: 'Flutter Team',
        version: '^6.3.2 / ^2.1.4',
        license: 'BSD-3-Clause / Zlib',
        role:
            'External URL launching and 2D matrix transforms for whiteboards.',
      ),
    ];

    final gutter = AppSpacing.screenGutter(MediaQuery.sizeOf(context).width);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        gutter,
        AppSpacing.s1,
        gutter,
        AppSpacing.s5 + bottomInset,
      ),
      physics: const ClampingScrollPhysics(),
      children: [
        _buildGroupedSurface(
          tokens: tokens,
          children: packages
              .map((pkg) => _buildPackageRow(pkg, tokens))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildPackageRow(_OssPackage pkg, TackTokens tokens) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  pkg.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleSm(
                    color: tokens.textPrimary,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s2),
              Text(
                pkg.license,
                style: AppTypography.mono(
                  fontSize: 11.5,
                  color: tokens.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${pkg.author} · ${pkg.version}',
            style: AppTypography.caption(color: tokens.textTertiary),
          ),
          const SizedBox(height: 6),
          Text(
            pkg.role,
            style: AppTypography.bodySm(color: tokens.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _OssPackage {
  final String name;
  final String author;
  final String version;
  final String license;
  final String role;

  const _OssPackage({
    required this.name,
    required this.author,
    required this.version,
    required this.license,
    required this.role,
  });
}
