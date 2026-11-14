import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/tack_icons.dart';
import 'app_bottom_sheet.dart';

class MermaidTemplateItem {
  final String title;
  final String subtitle;
  final String code;
  final dynamic icon;
  final Color accentColor;

  const MermaidTemplateItem({
    required this.title,
    required this.subtitle,
    required this.code,
    required this.icon,
    required this.accentColor,
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
      builder: (ctx) => MermaidTemplateSheet(onSelectTemplate: onSelectTemplate),
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
  ];

  static const Map<String, List<MermaidTemplateItem>> _templatesByCategory = {
    'Flowchart': [
      MermaidTemplateItem(
        title: 'Decision & Branching Logic',
        subtitle: 'Start, process steps, conditional branch and outcome',
        icon: TackIcons.flow,
        accentColor: AppColors.pastelPeachLight,
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
        accentColor: AppColors.accentCyan,
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
        accentColor: AppColors.pastelLimeLight,
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
        accentColor: AppColors.accentCyan,
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
        accentColor: AppColors.accentAmber,
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
        accentColor: AppColors.pastelLavenderLight,
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
        accentColor: AppColors.pastelCoralLight,
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
        accentColor: AppColors.pastelLimeLight,
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
        accentColor: AppColors.accentAmber,
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
        accentColor: AppColors.accentCyan,
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
        accentColor: AppColors.pastelPeachLight,
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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sheet title and close
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.accentCyan.withValues(alpha: isDark ? 0.25 : 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const TackIcon(TackIcons.flow, size: 20, color: AppColors.accentCyan),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mermaid Diagram Studio',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                        Text(
                          'Select a curated template to insert directly',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
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
              labelColor: isDark ? Colors.white : AppColors.lightTextPrimary,
              unselectedLabelColor: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              indicatorColor: AppColors.accentAmber,
              indicatorWeight: 3,
              tabs: _categories.map((cat) => Tab(text: cat)).toList(),
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
                      return _buildTemplateCard(template, isDark, theme);
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      );
  }

  Widget _buildTemplateCard(MermaidTemplateItem template, bool isDark, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E212B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF333D52) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
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
                        color: template.accentColor.withValues(alpha: isDark ? 0.25 : 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TackIcon(template.icon, size: 18, color: template.accentColor),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            template.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            template.subtitle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: template.accentColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const TackIcon(TackIcons.plus, size: 14, color: Colors.white),
                          const SizedBox(width: 2),
                          const Text(
                            'Insert',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF13151D) : const Color(0xFFEFF2F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    template.code.trim(),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      height: 1.35,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
