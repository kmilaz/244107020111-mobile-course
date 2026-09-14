import 'package:flutter/cupertino.dart';
const double kWideBreakpoint = 700;

void main() => runApp(const AcademicApp());

class AcademicApp extends StatefulWidget {
  const AcademicApp({super.key});

  @override
  State<AcademicApp> createState() => _AcademicAppState();
}

class _AcademicAppState extends State<AcademicApp> {
  bool isDark = false;

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      debugShowCheckedModeBanner: false,
      theme: CupertinoThemeData(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primaryColor: CupertinoColors.activeBlue,
      ),
      home: AcademicOverviewPage(
        isDark: isDark,
        onDarkChanged: (value) => setState(() => isDark = value),
      ),
    );
  }
}

class AcademicOverviewPage extends StatelessWidget {
  const AcademicOverviewPage({
    required this.isDark,
    required this.onDarkChanged,
    super.key,
  });

  final bool isDark;
  final ValueChanged<bool> onDarkChanged;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Academic Overview'),
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= kWideBreakpoint;
            final cells = <Widget>[
              ThemeToggleCard(
                isDark: isDark,
                onDarkChanged: onDarkChanged,
              ),
              const InfoCard(
                title: 'GPA',
                value: '3.85',
                icon: CupertinoIcons.chart_bar_fill,
              ),
              const InfoCard(
                title: 'Credits',
                value: '96 SKS',
                icon: CupertinoIcons.book_fill,
              ),
              const InfoCard(
                title: 'Attendance',
                value: '92%',
                icon: CupertinoIcons.person_3_fill,
              ),
              const InfoCard(
                title: 'Assignments',
                value: '8 due',
                icon: CupertinoIcons.doc_text_fill,
              ),
            ];
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _ProfileHeader(),
                  const SizedBox(height: 12),
                  if (isWide)
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: cells[0]),
                            const SizedBox(width: 12),
                            Expanded(child: cells[1]),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: cells[2]),
                            const SizedBox(width: 12),
                            Expanded(child: cells[3]),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: cells[4]),
                            const SizedBox(width: 12),
                            // Fills the last 2-column row so the toggle keeps one column.
                            const Expanded(child: SizedBox.shrink()),
                          ],
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        for (var i = 0; i < cells.length; i++) ...[
                          if (i > 0) const SizedBox(height: 12),
                          cells[i],
                        ],
                      ],
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final secondary =
        CupertinoColors.secondaryLabel.resolveFrom(context);

    return Semantics(
      label: 'Student profile: Kamila Zahwa, Teknik Informatika, Semester 5',
      child: _Card(
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.primaryColor,
              ),
              alignment: Alignment.center,
              child: Text(
                'KA',
                style: theme.textTheme.navTitleTextStyle.copyWith(
                  color: CupertinoColors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kamila Zahwa',
                    style: theme.textTheme.navTitleTextStyle,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Teknik Informatika • Semester 5',
                    style: theme.textTheme.textStyle
                        .copyWith(color: secondary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'NIM 244107020111',
                    style: theme.textTheme.textStyle
                        .copyWith(color: secondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  const InfoCard({
    required this.title,
    required this.value,
    required this.icon,
    this.trailing,
    super.key,
  });

  final String title;
  final String value;
  final IconData icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final secondary =
        CupertinoColors.secondaryLabel.resolveFrom(context);
    final trailing = this.trailing;

    return Semantics(
      label: '$title: $value',
      child: _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.tabLabelTextStyle
                        .copyWith(color: secondary),
                  ),
                ),
                Icon(icon, color: secondary),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: theme.textTheme.navLargeTitleTextStyle,
                  ),
                ),
                ?trailing,
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ThemeToggleCard extends StatelessWidget {
  const ThemeToggleCard({
    required this.isDark,
    required this.onDarkChanged,
    super.key,
  });

  final bool isDark;
  final ValueChanged<bool> onDarkChanged;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      title: 'Appearance',
      value: isDark ? 'Dark' : 'Light',
      icon: isDark
          ? CupertinoIcons.moon_fill
          : CupertinoIcons.sun_max_fill,
      trailing: Semantics(
        label: isDark ? 'Switch to light mode' : 'Switch to dark mode',
        button: true,
        child: CupertinoSwitch(
          value: isDark,
          onChanged: onDarkChanged,
        ),
      ),
    );
  }
}
