import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tack_icons.dart';

/// Comprehensive About Tack screen styled in Soft Monochrome:
/// 1. The Tech Stack journey and architectural evolution from start to now.
/// 2. Open-source libraries and packages used with descriptions and licenses.
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
    _tabController = TabController(length: 3, vsync: this);
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
                // Header Hero Card
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenGutter(
                      MediaQuery.sizeOf(context).width,
                    ),
                    vertical: AppSpacing.s2,
                  ),
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    padding: const EdgeInsets.all(AppSpacing.s5),
                    decoration: ShapeDecoration(
                      color: tokens.surfacePrimary,
                      shape: SmoothRectangleBorder(
                        borderRadius: AppSpacing.roundedLg,
                        smoothness: AppSpacing.defaultSmoothing,
                      ),
                      shadows: AppSpacing.elev1(tokens.isDark),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: ShapeDecoration(
                            color: tokens.canvasSunken,
                            shape: SmoothRectangleBorder(
                              borderRadius: AppSpacing.roundedMd,
                              smoothness: AppSpacing.defaultSmoothing,
                            ),
                          ),
                          child: Center(
                            child: Image.asset(
                              'icon.png',
                              width: 34,
                              height: 34,
                              cacheWidth: 128,
                              errorBuilder: (context, error, stackTrace) =>
                                  TackIcon(
                                    TackIcons.notes,
                                    size: 28,
                                    color: tokens.accentPin,
                                  ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s4),
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
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.s2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.s2,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: tokens.actionPrimary,
                                      borderRadius: AppSpacing.roundedPill,
                                    ),
                                    child: Text(
                                      'v2.0.0',
                                      style: AppTypography.caption(
                                        color: tokens.actionPrimaryFg,
                                        weight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Soft Monochrome Notes, Tasks & Visual Boards',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.serifItalic(
                                  color: tokens.textSecondary,
                                  fontSize: 15,
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

                // Black-Pill Segmented Tab Selector
                Container(
                  margin: EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenGutter(
                      MediaQuery.sizeOf(context).width,
                    ),
                  ),
                  padding: const EdgeInsets.all(AppSpacing.s2),
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
                        height: AppSpacing.minTouchTarget,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('Architecture'),
                        ),
                      ),
                      Tab(
                        height: AppSpacing.minTouchTarget,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('Privacy & Legal'),
                        ),
                      ),
                      Tab(
                        height: AppSpacing.minTouchTarget,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('Open Source'),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.s2),

                Expanded(
                  child: IndexedStack(
                    index: _tabController.index,
                    children: [
                      _buildStackJourneyTab(tokens),
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

  Widget _buildStackJourneyTab(TackTokens tokens) {
    final stages = [
      _JourneyStage(
        phase: 'Stage 1',
        title: 'Core OOP Domain Modeling',
        paletteId: 'peach',
        icon: TackIcons.notes,
        description:
            'Engineered clean Object-Oriented Dart abstractions with BaseWorkspaceItem '
            'polymorphism across TextNote, StickyNote, WhiteboardCanvasItem, and ClipboardItem.',
      ),
      _JourneyStage(
        phase: 'Stage 2',
        title: 'Decoupled Repository & Storage',
        paletteId: 'amber',
        icon: TackIcons.exportData,
        description:
            'Implemented Clean Architecture with IWorkspaceRepository, corrupt-store recovery, '
            'and atomic offline-first JSON persistence.',
      ),
      _JourneyStage(
        phase: 'Stage 3',
        title: 'Soft Monochrome Design System',
        paletteId: 'coral',
        icon: TackIcons.palette,
        description:
            'Crafted a calm neutral-canvas aesthetic with ink primary buttons, unified '
            'DM Sans UI hierarchy, JetBrains Mono code previews, and tinted sub-cards.',
      ),
      _JourneyStage(
        phase: 'Stage 4',
        title: 'Flowchart Whiteboard Canvas',
        paletteId: 'lime',
        icon: TackIcons.whiteboard,
        description:
            'Constructed a 6000px virtual infinite canvas with 2D matrix transformations, magnetic snap-to-grid, '
            'flowchart shapes, live Spec Cards, and Bézier edge routing.',
      ),
      _JourneyStage(
        phase: 'Stage 5',
        title: 'Today Desk & Inbox Triage',
        paletteId: 'lavender',
        icon: TackIcons.today,
        description:
            'Integrated daily note carry-forward, 1-tap inbox capture triage, cross-note task checklists, '
            'task reminders, and vector PDF + PNG document generation.',
      ),
      _JourneyStage(
        phase: 'Stage 6',
        title: 'ABI Split & Performance Polish',
        paletteId: 'cyan',
        icon: TackIcons.bolt,
        description:
            'Optimized release binaries with ABI-split compilation (ARM64, ARMv7, x86_64), icon tree-shaking, '
            'and composited 120fps scrolling.',
      ),
    ];

    final gutter = AppSpacing.screenGutter(MediaQuery.sizeOf(context).width);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        gutter,
        AppSpacing.s3,
        gutter,
        AppSpacing.s7 + bottomInset,
      ),
      physics: const BouncingScrollPhysics(),
      children: [...stages.map((stage) => _buildStageCard(stage, tokens))],
    );
  }

  Widget _buildStageCard(_JourneyStage stage, TackTokens tokens) {
    final palette = AppColors.getPaletteById(stage.paletteId);
    final accent = palette.resolveAccentColor(tokens.isDark);
    final softBg = palette.resolveSoftBackground(tokens.isDark);

    return Container(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: AppSpacing.s3),
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: ShapeDecoration(
        color: tokens.surfacePrimary,
        shape: SmoothRectangleBorder(
          borderRadius: AppSpacing.roundedMd,
          smoothness: AppSpacing.defaultSmoothing,
        ),
        shadows: AppSpacing.elev1(tokens.isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                stage.phase.toUpperCase(),
                style: AppTypography.caption(
                  fontSize: 12,
                  weight: FontWeight.w600,
                  color: tokens.textTertiary,
                ).copyWith(letterSpacing: 0.4),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: softBg,
                  borderRadius: AppSpacing.roundedPill,
                ),
                child: TackIcon(stage.icon, size: 14, color: accent),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s2),
          Container(
            padding: const EdgeInsets.all(AppSpacing.s3),
            decoration: ShapeDecoration(
              color: softBg,
              shape: SmoothRectangleBorder(
                borderRadius: AppSpacing.roundedSm,
                smoothness: AppSpacing.defaultSmoothing,
              ),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 3.5,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: AppSpacing.roundedPill,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stage.title,
                          style: AppTypography.titleSm(
                            color: tokens.textPrimary,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          stage.description,
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
        ],
      ),
    );
  }

  Widget _buildPrivacyLegalTab(TackTokens tokens) {
    final gutter = AppSpacing.screenGutter(MediaQuery.sizeOf(context).width);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    final policies = [
      (
        icon: TackIcons.lock,
        paletteId: 'cyan',
        title: 'Local-First Storage & Zero Telemetry',
        body:
            'Tack stores all notes, tasks, folders, whiteboards, and preferences exclusively in your '
            'device app storage. Tack contains no analytics SDKs, ad trackers, user accounts, or remote servers.',
      ),
      (
        icon: TackIcons.shield,
        paletteId: 'lime',
        title: 'Android Cloud Backup Disabled',
        body:
            'Automatic OS cloud backup is disabled in the app manifest (allowBackup=false) so private workspace '
            'notes are never synced to third-party cloud storage automatically.',
      ),
      (
        icon: TackIcons.notification,
        paletteId: 'amber',
        title: 'Notifications & Task Reminders',
        body:
            'Notification and exact-alarm permissions are requested only when you schedule a task reminder '
            'or pin a note to the notification shade. Alarms execute locally on Android AlarmManager.',
      ),
      (
        icon: TackIcons.photo,
        paletteId: 'peach',
        title: 'Photos, Camera & Clipboard Access',
        body:
            'Images are copied into internal app storage only when picked or captured by you. Clipboard text is '
            'read strictly on explicit Paste actions, and shared exports leave the device only via apps you choose.',
      ),
      (
        icon: TackIcons.info,
        paletteId: 'slate',
        title: 'Software Notice & Data Responsibility',
        body:
            'Tack Notes (v2.0.0) is provided as local productivity software without warranty. Because there is no '
            'cloud sync, please use Export Backup in Settings periodically to safeguard important notes.',
      ),
    ];

    return ListView(
      padding: EdgeInsets.fromLTRB(
        gutter,
        AppSpacing.s3,
        gutter,
        AppSpacing.s7 + bottomInset,
      ),
      physics: const BouncingScrollPhysics(),
      children: policies.map((item) {
        final palette = AppColors.getPaletteById(item.paletteId);
        final accent = palette.resolveAccentColor(tokens.isDark);
        final softBg = palette.resolveSoftBackground(tokens.isDark);
        return Container(
          clipBehavior: Clip.antiAlias,
          margin: const EdgeInsets.only(bottom: AppSpacing.s3),
          padding: const EdgeInsets.all(AppSpacing.s4),
          decoration: ShapeDecoration(
            color: tokens.surfacePrimary,
            shape: SmoothRectangleBorder(
              borderRadius: AppSpacing.roundedMd,
              smoothness: AppSpacing.defaultSmoothing,
            ),
            shadows: AppSpacing.elev1(tokens.isDark),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: softBg,
                  borderRadius: AppSpacing.roundedSm,
                ),
                child: Center(
                  child: TackIcon(item.icon, size: 18, color: accent),
                ),
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: AppTypography.titleSm(
                        color: tokens.textPrimary,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s1),
                    Text(
                      item.body,
                      style: AppTypography.bodySm(color: tokens.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
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
        AppSpacing.s3,
        gutter,
        AppSpacing.s7 + bottomInset,
      ),
      physics: const BouncingScrollPhysics(),
      children: [
        ...packages.map((pkg) => _buildPackageCard(pkg, tokens)),
        const SizedBox(height: AppSpacing.s2),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(AppSpacing.minTouchTarget),
            side: BorderSide(color: tokens.borderSubtle),
            shape: const RoundedRectangleBorder(
              borderRadius: AppSpacing.roundedPill,
            ),
          ),
          onPressed: () {
            showLicensePage(
              context: context,
              applicationName: 'Tack',
              applicationVersion: 'v2.0.0',
            );
          },
          child: Text(
            'View Full License Notices',
            style: AppTypography.label(
              color: tokens.textPrimary,
              weight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPackageCard(_OssPackage pkg, TackTokens tokens) {
    return Container(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: AppSpacing.s3),
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: ShapeDecoration(
        color: tokens.surfacePrimary,
        shape: SmoothRectangleBorder(
          borderRadius: AppSpacing.roundedMd,
          smoothness: AppSpacing.defaultSmoothing,
        ),
        shadows: AppSpacing.elev1(tokens.isDark),
      ),
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s2,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: tokens.canvasSunken,
                  borderRadius: AppSpacing.roundedPill,
                ),
                child: Text(
                  pkg.license,
                  style: AppTypography.caption(
                    color: tokens.textSecondary,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            '${pkg.author}  •  ${pkg.version}',
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

class _JourneyStage {
  final String phase;
  final String title;
  final String paletteId;
  final dynamic icon;
  final String description;

  const _JourneyStage({
    required this.phase,
    required this.title,
    required this.paletteId,
    required this.icon,
    required this.description,
  });
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
