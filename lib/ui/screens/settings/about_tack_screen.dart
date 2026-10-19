import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tack_icons.dart';

/// Comprehensive About Tack screen showcasing:
/// 1. The Tech Stack journey and architectural evolution from start to now.
/// 2. Open-source libraries and packages used with descriptions and licenses.
/// 3. Offline-first privacy and local storage principles.
class AboutTackScreen extends StatefulWidget {
  const AboutTackScreen({super.key});

  @override
  State<AboutTackScreen> createState() => _AboutTackScreenState();
}

class _AboutTackScreenState extends State<AboutTackScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const TackIcon(TackIcons.back, size: 22),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
          },
          tooltip: 'Back',
        ),
        title: Text(
          'About Tack',
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          // Header Hero Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 6),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.25)
                        : const Color(0xFF191A23).withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // App Brand Icon Container
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: AppColors.accentAmber.withValues(alpha: isDark ? 0.2 : 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.accentAmber.withValues(alpha: 0.4),
                        width: 1.2,
                      ),
                    ),
                    child: Center(
                      child: Image.asset(
                        'icon.png',
                        width: 36,
                        height: 36,
                        errorBuilder: (context, error, stackTrace) => const TackIcon(
                          TackIcons.notes,
                          size: 30,
                          color: AppColors.accentAmber,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Tack',
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.6,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.pastelCyanLight.withValues(alpha: isDark ? 0.25 : 0.18),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'v1.0.0',
                                style: TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                  color: isDark ? AppColors.pastelCyanLight : AppColors.pastelCyanDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Tactile Workspace, Flowcharts & Notes',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.2,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Segmented Tab Selector
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceAlt : const Color(0xFFEFF1F5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              labelColor: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              unselectedLabelColor: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              labelStyle: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                letterSpacing: -0.2,
              ),
              unselectedLabelStyle: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontWeight: FontWeight.w500,
                fontSize: 13,
                letterSpacing: -0.2,
              ),
              tabs: const [
                Tab(text: 'Stack & Journey'),
                Tab(text: 'Open Source'),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildStackJourneyTab(isDark),
                _buildOpenSourceTab(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= 1. Stack & Journey Tab =================
  Widget _buildStackJourneyTab(bool isDark) {
    final stages = [
      _JourneyStage(
        phase: 'Stage 1',
        title: 'Core OOP Domain Modeling',
        color: AppColors.pastelPeachLight,
        icon: TackIcons.notes,
        description:
            'Engineered strict Object-Oriented Dart abstractions. Created abstract `BaseWorkspaceItem` '
            'with dynamic polymorphism across `TextNote`, `StickyNote`, `WhiteboardCanvasItem`, and `ClipboardItem`.',
      ),
      _JourneyStage(
        phase: 'Stage 2',
        title: 'Decoupled Repository & Storage',
        color: AppColors.pastelAmberLight,
        icon: TackIcons.exportData,
        description:
            'Implemented Clean Architecture with `IWorkspaceRepository` and atomic JSON file persistence. '
            'Provides offline-first storage with local on-device persistence.',
      ),
      _JourneyStage(
        phase: 'Stage 3',
        title: 'Tactile Android Design System',
        color: AppColors.pastelCyanLight,
        icon: TackIcons.palette,
        description:
            'Crafted the signature stationery aesthetic: 8 curated sticky pastels, DM Sans typography (-2% tracking), '
            'soft diffused drop shadows, 48dp ergonomics, and micro-press physics animations.',
      ),
      _JourneyStage(
        phase: 'Stage 4',
        title: 'Flowchart Whiteboard Canvas',
        color: AppColors.pastelLimeLight,
        icon: TackIcons.whiteboard,
        description:
            'Constructed a 6000px virtual infinite canvas with 2D matrix transformations, magnetic 20px snap-to-grid, '
            'flowchart shapes (Start/End, Process, Decision, I/O), Bézier edge routing, and a live radar minimap.',
      ),
      _JourneyStage(
        phase: 'Stage 5',
        title: 'Clipboard Studio & Rich Export',
        color: AppColors.pastelLavenderLight,
        icon: TackIcons.clipboard,
        description:
            'Integrated seamless clipboard history capture, multi-line snippet management, interactive checklists, '
            'and native vector PDF + high-resolution PNG document generation.',
      ),
      _JourneyStage(
        phase: 'Stage 6',
        title: 'ABI Split & Performance Polish',
        color: AppColors.pastelRoseLight,
        icon: TackIcons.bolt,
        description:
            'Optimized release binaries with ABI-split compilation (ARM64, ARMv7, x86_64), icon tree-shaking '
            '(reducing icon fonts by >98%), and gesture navigation safe-area clearances.',
      ),
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 12),
      physics: const BouncingScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'HOW WE BUILT TACK (FROM START TO NOW)',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          ),
        ),
        ...stages.map((stage) => _buildStageCard(stage, isDark)),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildStageCard(_JourneyStage stage, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: stage.color.withValues(alpha: isDark ? 0.22 : 0.16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: TackIcon(
                stage.icon,
                size: 18,
                color: isDark ? stage.color : AppColors.primaryDark,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      stage.title,
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    Text(
                      stage.phase,
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  stage.description,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 12.5,
                    height: 1.45,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= 2. Open Source Libraries Tab =================
  Widget _buildOpenSourceTab(bool isDark) {
    final packages = [
      _OssPackage(
        name: 'flutter',
        author: 'Google LLC',
        version: 'SDK 3.29.0',
        license: 'BSD-3-Clause',
        role: 'Cross-platform reactive UI framework and rendering engine.',
      ),
      _OssPackage(
        name: 'provider',
        author: 'Remi Rousselet',
        version: '^6.1.2',
        license: 'MIT',
        role: 'State management and dependency injection for workspace and themes.',
      ),
      _OssPackage(
        name: 'google_fonts',
        author: 'Material Design & Google',
        version: '^8.2.1',
        license: 'Apache-2.0 / OFL',
        role: 'Typography engine delivering DM Sans modern geometric letterforms.',
      ),
      _OssPackage(
        name: 'lucide_icons_flutter',
        author: 'Lucide Team',
        version: '^3.1.19',
        license: 'ISC',
        role: 'Minimalist, rounded-cap SVG iconography across workspace controls.',
      ),
      _OssPackage(
        name: 'flutter_svg',
        author: 'Dan Field & Community',
        version: '^2.3.0',
        license: 'MIT',
        role: 'Scalable vector graphics rendering for app badges and brand assets.',
      ),
      _OssPackage(
        name: 'pdf & printing',
        author: 'David PHAM-VAN',
        version: '^3.13.0 / ^5.15.0',
        license: 'Apache-2.0',
        role: 'Native multi-page document layout and vector PDF export engine.',
      ),
      _OssPackage(
        name: 'share_plus',
        author: 'Flutter Community',
        version: '^13.3.0',
        license: 'BSD-3-Clause',
        role: 'Android platform sharing intents for backups, notes, and exports.',
      ),
      _OssPackage(
        name: 'path_provider',
        author: 'Flutter Team',
        version: '^2.1.6',
        license: 'BSD-3-Clause',
        role: 'Android file system directory resolution for offline JSON storage.',
      ),
      _OssPackage(
        name: 'image_picker',
        author: 'Flutter Team',
        version: '^1.2.3',
        license: 'BSD-3-Clause',
        role: 'Device gallery and camera integration for whiteboard media nodes.',
      ),
      _OssPackage(
        name: 'image',
        author: 'Brendan Duncan',
        version: '^4.9.2',
        license: 'Apache-2.0',
        role: 'Pure Dart pixel processing and PNG rasterization generator.',
      ),
      _OssPackage(
        name: 'vector_math',
        author: 'Dart Team',
        version: '^2.1.4',
        license: 'BSD-3-Clause',
        role: '2D/3D affine transformation matrices for whiteboard zooming and panning.',
      ),
      _OssPackage(
        name: 'shared_preferences',
        author: 'Flutter Team',
        version: '^2.5.5',
        license: 'BSD-3-Clause',
        role: 'Lightweight on-device persistent key-value store for app settings.',
      ),
      _OssPackage(
        name: 'url_launcher',
        author: 'Flutter Team',
        version: '^6.3.2',
        license: 'BSD-3-Clause',
        role: 'Web hyperlink dispatching from markdown content and preview sheets.',
      ),
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 12),
      physics: const BouncingScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'OPEN SOURCE PACKAGES & ATTRIBUTIONS',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          ),
        ),
        ...packages.map((pkg) => _buildPackageCard(pkg, isDark)),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildPackageCard(_OssPackage pkg, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                pkg.name,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceAlt : const Color(0xFFF1F3F6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  pkg.license,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.pastelCyanLight : AppColors.pastelCyanDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            '${pkg.author}  •  ${pkg.version}',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            pkg.role,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 12,
              height: 1.35,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _JourneyStage {
  final String phase;
  final String title;
  final Color color;
  final IconData icon;
  final String description;

  const _JourneyStage({
    required this.phase,
    required this.title,
    required this.color,
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
