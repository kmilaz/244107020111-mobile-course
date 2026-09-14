import 'package:flutter/cupertino.dart';

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
    final bg = isDark
        ? CupertinoColors.black
        : CupertinoColors.systemGroupedBackground;

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Academic Overview'),
      ),
      backgroundColor: bg,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 600;
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
                  _ProfileHeader(isDark: isDark),
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

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark
        ? CupertinoColors.systemGrey6.darkColor
        : CupertinoColors.white;
    final subColor = isDark
        ? CupertinoColors.systemGrey
        : CupertinoColors.systemGrey.darkColor;

    return Semantics(
      label: 'Student profile: Kamila Zahwa, Teknik Informatika, Semester 5',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: CupertinoColors.activeBlue,
              ),
              alignment: Alignment.center,
              child: const Text(
                'KA',
                style: TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kamila Zahwa',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Teknik Informatika • Semester 5',
                    style: TextStyle(fontSize: 13, color: subColor),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'NIM 244107020111',
                    style: TextStyle(fontSize: 13, color: subColor),
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
    super.key,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isDark =
        CupertinoTheme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? CupertinoColors.systemGrey6.darkColor
        : CupertinoColors.white;

    return Semantics(
      label: '$title: $value',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                Icon(
                  icon,
                  size: 20,
                  color: CupertinoColors.systemGrey.resolveFrom(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
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
    final cardColor = isDark
        ? CupertinoColors.systemGrey6.darkColor
        : CupertinoColors.white;

    return Semantics(
      label: isDark ? 'Dark mode enabled' : 'Light mode enabled',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Appearance',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
                Icon(
                  isDark
                      ? CupertinoIcons.moon_fill
                      : CupertinoIcons.sun_max_fill,
                  size: 20,
                  color: isDark
                      ? CupertinoColors.white
                      : CupertinoColors.systemOrange,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    isDark ? 'Dark' : 'Light',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Semantics(
                  label: isDark
                      ? 'Switch to light mode'
                      : 'Switch to dark mode',
                  button: true,
                  child: CupertinoSwitch(
                    value: isDark,
                    onChanged: onDarkChanged,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
