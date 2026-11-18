import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tack_icons.dart';
import '../../../shared/widgets/app_bottom_sheet.dart';

class MermaidTemplateItem {
  final String title;
  final String subtitle;
  final String code;
  final dynamic icon;
  final String paletteId;

  const MermaidTemplateItem({
    required this.title,
    required this.subtitle,
    required this.code,
    required this.icon,
    required this.paletteId,
  });
}

/// Interactive, visual Mermaid Diagram Builder & Template Sheet.
/// Offers categorized, beautiful templates instead of cryptic text dumps.
class MermaidTemplateSheet extends StatefulWidget {
  final ValueChanged<String> onSelectTemplate;

  const MermaidTemplateSheet({super.key, required this.onSelectTemplate});

  static Future<void> show(
    BuildContext context, {
    required ValueChanged<String> onSelectTemplate,
  }) {
    return AppBottomSheet.show(
      context: context,
      maxHeightFactor: 0.80,
      builder: (ctx) =>
          MermaidTemplateSheet(onSelectTemplate: onSelectTemplate),
    );
  }

  @override
  State<MermaidTemplateSheet> createState() => _MermaidTemplateSheetState();
}

class _MermaidTemplateSheetState extends State<MermaidTemplateSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const List<String> _categories = [
    'Flowchart',
    'Pipeline',
    'Sequence',
    'Pie / Metrics',
    'Timeline',
    'ERD & Gantt',
  ];

  static const Map<String, List<MermaidTemplateItem>> _templatesByCategory = {
    'Flowchart': [
      MermaidTemplateItem(
        title: 'Decision & Branching Logic',
        subtitle: 'Start, process steps, conditional branch and outcome',
        icon: TackIcons.flow,
        paletteId: 'peach',
        code: '''```mermaid
graph TD
    A([Start Task]) --> B[Inspect Input]
    B --> C{Valid?}
    C -->|Yes| D[Execute Process]
    C -->|No| E[Log Warning]
    D --> F([Completed])
    E --> B
```
''',
      ),
      MermaidTemplateItem(
        title: 'System Architecture Flow',
        subtitle: 'Client, API Gateway, Services and Database',
        icon: TackIcons.play,
        paletteId: 'cyan',
        code: '''```mermaid
graph TD
    User([User App]) --> API[API Gateway]
    API --> Auth[Auth Service]
    API --> Core[Core Engine]
    Core --> DB[(Database)]
    Core --> Cache[(Redis Cache)]
```
''',
      ),
      MermaidTemplateItem(
        title: 'Approval Hierarchy',
        subtitle: 'Multi-stage validation and confirmation',
        icon: TackIcons.checkCircle,
        paletteId: 'lime',
        code: '''```mermaid
graph TD
    Draft[Draft Created] --> Review{Peer Review}
    Review -->|Approved| Lead{Lead Signoff}
    Review -->|Changes Needed| Draft
    Lead -->|Accepted| Deploy([Deploy to Production])
    Lead -->|Rejected| Draft
```
''',
      ),
    ],
    'Pipeline': [
      MermaidTemplateItem(
        title: 'Horizontal Data Pipeline',
        subtitle: 'Linear left-to-right flow from input to output',
        icon: TackIcons.play,
        paletteId: 'cyan',
        code: '''```mermaid
graph LR
    Source[Raw Input] --> Ingest[Ingestion]
    Ingest --> Transform[Transform & Clean]
    Transform --> Model[ML Inference]
    Model --> Storage[(Data Lake)]
    Storage --> Dashboard([Live Dashboard])
```
''',
      ),
      MermaidTemplateItem(
        title: 'CI/CD Build Pipeline',
        subtitle: 'Lint, unit test, build artifact, and staging deploy',
        icon: TackIcons.bolt,
        paletteId: 'amber',
        code: '''```mermaid
graph LR
    Commit([Git Commit]) --> Lint[Lint & Analyze]
    Lint --> Test[Run Tests]
    Test --> Build[Build Bundle]
    Build --> Release([Deploy Staging])
```
''',
      ),
    ],
    'Sequence': [
      MermaidTemplateItem(
        title: 'API Request & Response Flow',
        subtitle: 'Client, Gateway, Auth and DB communication',
        icon: TackIcons.notes,
        paletteId: 'lavender',
        code: '''```mermaid
sequenceDiagram
    User->>App: Open Note
    App->>Server: GET /notes/101
    Server->>Database: Query Document
    Database-->>Server: Note Payload
    Server-->>App: 200 OK (Data)
    App-->>User: Render Note View
```
''',
      ),
      MermaidTemplateItem(
        title: 'User Authentication Cycle',
        subtitle: 'Token validation and session establishment',
        icon: TackIcons.lock,
        paletteId: 'coral',
        code: '''```mermaid
sequenceDiagram
    Client->>AuthService: Submit Credentials
    AuthService->>Database: Verify Hash
    Database-->>AuthService: Valid
    AuthService-->>Client: JWT Token
    Client->>AppService: Request with Token
    AppService-->>Client: Authorized Session
```
''',
      ),
    ],
    'Pie / Metrics': [
      MermaidTemplateItem(
        title: 'Project Resource Allocation',
        subtitle: 'Visual pie distribution of team time or budget',
        icon: TackIcons.tag,
        paletteId: 'lime',
        code: '''```mermaid
pie title Project Allocation
    "Frontend Engineering" : 40
    "Backend & Cloud" : 30
    "UI/UX Design" : 18
    "QA & Testing" : 12
```
''',
      ),
      MermaidTemplateItem(
        title: 'Time Breakdown Chart',
        subtitle: 'Weekly focus and productivity metric',
        icon: TackIcons.clock,
        paletteId: 'amber',
        code: '''```mermaid
pie title Weekly Focus
    "Deep Work" : 50
    "Code Reviews" : 20
    "Architecture" : 15
    "Sync Meetings" : 15
```
''',
      ),
    ],
    'Timeline': [
      MermaidTemplateItem(
        title: 'Product Roadmap & Milestones',
        subtitle: 'Sequential releases with key deliverables',
        icon: TackIcons.calendar,
        paletteId: 'cyan',
        code: '''```mermaid
timeline
    title 2026 Product Roadmap
    Q1 2026 : Research & Design : Architecture Draft
    Q2 2026 : Alpha Release : Internal Dogfooding
    Q3 2026 : Beta Testing : Security Audit
    Q4 2026 : Global Launch : Enterprise Sync
```
''',
      ),
      MermaidTemplateItem(
        title: 'Sprint Release Schedule',
        subtitle: 'Bi-weekly sprint targets and deployments',
        icon: TackIcons.checkCircle,
        paletteId: 'peach',
        code: '''```mermaid
timeline
    title Sprint Schedule
    Week 1 : Sprint Kickoff : Core Logic
    Week 2 : Feature Complete : Code Freeze
    Week 3 : Regression Tests : Deployment
```
''',
      ),
    ],
    'ERD & Gantt': [
      MermaidTemplateItem(
        title: 'Entity Relationship Diagram',
        subtitle: 'Tables, keys, and one-to-many data links',
        icon: TackIcons.table,
        paletteId: 'lavender',
        code: '''```mermaid
erDiagram
    WORKSPACE ||--o{ NOTE : contains
    NOTE ||--o{ TASK : tracks
    NOTE }o--o{ TAG : labeled_with
```
''',
      ),
      MermaidTemplateItem(
        title: 'Project Gantt Schedule',
        subtitle: 'Timed tasks, milestones, and parallel workstreams',
        icon: TackIcons.calendar,
        paletteId: 'cyan',
        code: '''```mermaid
gantt
    title Release Schedule
    dateFormat YYYY-MM-DD
    section Build
    Core Engine :a1, 2026-11-01, 5d
    UI Polish   :after a1, 4d
```
''',
      ),
    ],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
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
    final tokens = context.tokens;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sheet title and close
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s6),
            child: Row(
              children: [
                Builder(
                  builder: (context) {
                    final headerAccent = AppColors.getPaletteById('cyan')
                        .resolveAccentColor(isDark);
                    return Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: headerAccent.withValues(
                          alpha: isDark ? 0.25 : 0.15,
                        ),
                        borderRadius: AppSpacing.roundedXs,
                      ),
                      child: TackIcon(
                        TackIcons.flow,
                        size: 20,
                        color: headerAccent,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mermaid Diagram Studio',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleSm(
                          color: tokens.textPrimary,
                          weight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Tap a template to insert editable ```mermaid code into your note.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption(
                          color: tokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  constraints: const BoxConstraints(
                    minWidth: AppSpacing.minTouchTarget,
                    minHeight: AppSpacing.minTouchTarget,
                  ),
                  icon: const TackIcon(TackIcons.close, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          // Category Tab Bar
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelPadding: const EdgeInsets.symmetric(horizontal: 14),
            indicatorSize: TabBarIndicatorSize.label,
            labelColor: tokens.textPrimary,
            unselectedLabelColor: tokens.textSecondary,
            labelStyle: AppTypography.label(
              color: tokens.textPrimary,
              weight: FontWeight.w700,
            ),
            indicatorColor: tokens.actionPrimary,
            indicatorWeight: 3,
            tabs: _categories
                .map((cat) => Tab(height: AppSpacing.minTouchTarget, text: cat))
                .toList(),
          ),
          const Divider(height: 1),

          // Tab Views with Template Cards
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _categories.map((cat) {
                final list = _templatesByCategory[cat] ?? [];
                return ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final template = list[i];
                    return _buildTemplateCard(template, isDark, tokens);
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(
    MermaidTemplateItem template,
    bool isDark,
    TackTokens tokens,
  ) {
    final cardAccent = AppColors.getPaletteById(template.paletteId)
        .resolveAccentColor(isDark);
    final pillInk = cardAccent.computeLuminance() > 0.45
        ? AppColors.lightTextPrimary
        : Colors.white;
    return Semantics(
      button: true,
      label: 'Insert ${template.title} diagram template',
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: AppSpacing.roundedMd,
            boxShadow: AppSpacing.elev1(isDark),
          ),
          child: Material(
            color: tokens.canvasSunken,
            shape: AppSpacing.smoothMd(
              side: BorderSide(color: tokens.borderSubtle, width: 1.2),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              customBorder: AppSpacing.smoothMd(),
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pop();
                widget.onSelectTemplate(template.code);
              },
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: cardAccent.withValues(
                              alpha: isDark ? 0.22 : 0.14,
                            ),
                            borderRadius: AppSpacing.roundedXs,
                          ),
                          child: TackIcon(
                            template.icon,
                            size: 18,
                            color: cardAccent,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                template.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.label(
                                  color: tokens.textPrimary,
                                  weight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                template.subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.caption(
                                  color: tokens.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: cardAccent,
                            borderRadius: AppSpacing.roundedPill,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TackIcon(
                                TackIcons.plus,
                                size: 14,
                                color: pillInk,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                'Insert',
                                style: AppTypography.caption(
                                  color: pillInk,
                                  weight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Code snippet preview block
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: tokens.surfacePrimary,
                        borderRadius: AppSpacing.roundedXs,
                        border: Border.all(color: tokens.borderSubtle),
                      ),
                      child: Text(
                        template.code.trim(),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.mono(color: tokens.textSecondary)
                            .copyWith(height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
