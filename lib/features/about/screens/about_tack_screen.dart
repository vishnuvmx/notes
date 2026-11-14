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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (mounted) setState(() {});
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
      body: Column(
        children: [
          // Header Hero Card
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s5,
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
                        errorBuilder: (context, error, stackTrace) => TackIcon(
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

          // Black-Pill Segmented Tab Selector (matching Screenshot 2)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.s5),
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
                Tab(text: 'Stack & Journey'),
                Tab(text: 'Open Source'),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.s2),

          Expanded(
            child: IndexedStack(
              index: _tabController.index,
              children: [
                _buildStackJourneyTab(tokens),
                _buildOpenSourceTab(tokens),
              ],
            ),
          ),
        ],
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
            'Engineered strict Object-Oriented Dart abstractions with `BaseWorkspaceItem` '
            'polymorphism across `TextNote`, `StickyNote`, `WhiteboardCanvasItem`, and `ClipboardItem`.',
      ),
      _JourneyStage(
        phase: 'Stage 2',
        title: 'Decoupled Repository & Storage',
        paletteId: 'amber',
        icon: TackIcons.exportData,
        description:
            'Implemented Clean Architecture with `IWorkspaceRepository`, corrupt-store recovery, '
            'and atomic offline-first JSON persistence.',
      ),
      _JourneyStage(
        phase: 'Stage 3',
        title: 'Soft Monochrome Design System',
        paletteId: 'coral',
        icon: TackIcons.palette,
        description:
            'Crafted a calm neutral-canvas aesthetic with ink primary buttons, editorial Newsreader '
            'serif accents, DM Sans UI hierarchy, and tinted sub-cards.',
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
            'Integrated daily note carry-forward, 1-tap inbox capture triage, cross-note open task checklists, '
            'and vector PDF + PNG document generation.',
      ),
      _JourneyStage(
        phase: 'Stage 6',
        title: 'ABI Split & Performance Polish',
        paletteId: 'cyan',
        icon: TackIcons.bolt,
        description:
            'Optimized release binaries with ABI-split compilation (ARM64, ARMv7, x86_64), icon tree-shaking '
            '(>96% reduction), and edge-to-edge gesture clearances.',
      ),
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s5,
        vertical: AppSpacing.s3,
      ),
      physics: const BouncingScrollPhysics(),
      children: [
        ...stages.map((stage) => _buildStageCard(stage, tokens)),
        const SizedBox(height: AppSpacing.s6),
      ],
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
                style: AppTypography.mono(
                  fontSize: 11,
                  weight: FontWeight.w600,
                  color: tokens.textTertiary,
                ),
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

  Widget _buildOpenSourceTab(TackTokens tokens) {
    final packages = [
      const _OssPackage(
        name: 'flutter',
        author: 'Google LLC',
        version: 'SDK 3.29.0',
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
        version: '^8.2.1',
        license: 'Apache-2.0 / OFL',
        role: 'Typography engine delivering DM Sans, Newsreader, and JetBrains Mono.',
      ),
      const _OssPackage(
        name: 'lucide_icons_flutter',
        author: 'Lucide Team',
        version: '^3.1.19',
        license: 'ISC',
        role: 'Minimalist, rounded-cap iconography across workspace controls.',
      ),
      const _OssPackage(
        name: 'flutter_svg',
        author: 'Dan Field & Community',
        version: '^2.3.0',
        license: 'MIT',
        role: 'Scalable vector graphics rendering for app badges and brand assets.',
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
        role: 'Android platform sharing intents for backups, notes, and exports.',
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
        name: 'url_launcher',
        author: 'Flutter Team',
        version: '^6.3.2',
        license: 'BSD-3-Clause',
        role: 'Web hyperlink dispatching from markdown content and preview sheets.',
      ),
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s5,
        vertical: AppSpacing.s3,
      ),
      physics: const BouncingScrollPhysics(),
      children: [
        ...packages.map((pkg) => _buildPackageCard(pkg, tokens)),
        const SizedBox(height: AppSpacing.s6),
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
