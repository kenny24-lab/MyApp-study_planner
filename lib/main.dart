import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure SQLite for Web/Chrome.
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }

  runApp(const MyStudyPlannerApp());
}

// ============================================================
// MAIN APP
// ============================================================

class MyStudyPlannerApp extends StatefulWidget {
  const MyStudyPlannerApp({super.key});

  @override
  State<MyStudyPlannerApp> createState() =>
      _MyStudyPlannerAppState();
}

class _MyStudyPlannerAppState
    extends State<MyStudyPlannerApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light
              ? ThemeMode.dark
              : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme lightColorScheme =
        ColorScheme.fromSeed(
      seedColor: const Color(0xFF3949AB),
      brightness: Brightness.light,
    );

    final ColorScheme darkColorScheme =
        ColorScheme.fromSeed(
      seedColor: const Color(0xFF7986CB),
      brightness: Brightness.dark,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'StudyFlow',
      themeMode: _themeMode,

      // --------------------------------------------------------
      // LIGHT THEME
      // --------------------------------------------------------
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: lightColorScheme,
        scaffoldBackgroundColor:
            const Color(0xFFF6F7FB),
        appBarTheme: AppBarTheme(
          backgroundColor: lightColorScheme.surface,
          foregroundColor:
              lightColorScheme.onSurface,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme:
            const InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.all(
              Radius.circular(14),
            ),
            borderSide: BorderSide.none,
          ),
          enabledBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.all(
              Radius.circular(14),
            ),
            borderSide: BorderSide(
              color: Color(0xFFE2E4EA),
            ),
          ),
          focusedBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.all(
              Radius.circular(14),
            ),
            borderSide: BorderSide(
              color: Color(0xFF3949AB),
              width: 1.5,
            ),
          ),
          contentPadding:
              EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),

      // --------------------------------------------------------
      // DARK THEME
      // --------------------------------------------------------
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: darkColorScheme,
        scaffoldBackgroundColor:
            const Color(0xFF101218),
        appBarTheme: AppBarTheme(
          backgroundColor:
              const Color(0xFF171922),
          foregroundColor:
              darkColorScheme.onSurface,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme:
            InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1D2029),
          border: const OutlineInputBorder(
            borderRadius:
                BorderRadius.all(
              Radius.circular(14),
            ),
            borderSide: BorderSide.none,
          ),
          enabledBorder:
              const OutlineInputBorder(
            borderRadius:
                BorderRadius.all(
              Radius.circular(14),
            ),
            borderSide: BorderSide(
              color: Color(0xFF30333D),
            ),
          ),
          focusedBorder:
              OutlineInputBorder(
            borderRadius:
                const BorderRadius.all(
              Radius.circular(14),
            ),
            borderSide: BorderSide(
              color: darkColorScheme.primary,
              width: 1.5,
            ),
          ),
          contentPadding:
              const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),

      home: HomeScreen(
        onToggleTheme: _toggleTheme,
        isDarkMode:
            _themeMode == ThemeMode.dark,
      ),
    );
  }
}

// ============================================================
// HOME SCREEN
// ============================================================

class HomeScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const HomeScreen({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  State<HomeScreen> createState() =>
      _HomeScreenState();
}

class _HomeScreenState
    extends State<HomeScreen> {
  final List<Map<String, dynamic>> _goals =
      [];

  Database? _database;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  // ==========================================================
  // DATABASE
  // ==========================================================

  Future<void> _initDatabase() async {
    try {
      String databasePath;

      if (kIsWeb) {
        databasePath =
            'study_planner_web.db';
      } else {
        final String databasesPath =
            await getDatabasesPath();

        databasePath = p.join(
          databasesPath,
          'study_planner_v2.db',
        );
      }

      _database = await openDatabase(
        databasePath,
        version: 1,
        onCreate:
            (Database db, int version) async {
          await db.execute('''
            CREATE TABLE goals (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              subject TEXT NOT NULL,
              hours REAL NOT NULL,
              done INTEGER NOT NULL DEFAULT 0
            )
          ''');

          debugPrint(
            'SQLite Table successfully created!',
          );
        },
      );

      await _loadGoals();
    } catch (e) {
      debugPrint(
        'Error initializing database: $e',
      );

      if (mounted) {
        _showSnackBar(
          'Unable to initialize database.',
          isError: true,
        );
      }
    }
  }

  Future<void> _loadGoals() async {
    if (_database == null) return;

    try {
      final List<Map<String, dynamic>>
          results = await _database!.query(
        'goals',
        orderBy: 'id DESC',
      );

      if (!mounted) return;

      setState(() {
        _goals
          ..clear()
          ..addAll(results);

        _isLoading = false;
      });

      debugPrint(
        'Successfully loaded '
        '${results.length} goals from SQLite.',
      );
    } catch (e) {
      debugPrint(
        'Error loading goals: $e',
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showSnackBar(
        'Could not load study goals.',
        isError: true,
      );
    }
  }

  Future<void> _addGoalToDatabase(
    String subject,
    double hours,
  ) async {
    if (_database == null) {
      _showSnackBar(
        'Database is not ready yet.',
        isError: true,
      );
      return;
    }

    try {
      final int id =
          await _database!.insert(
        'goals',
        {
          'subject': subject,
          'hours': hours,
          'done': 0,
        },
      );

      debugPrint(
        'Goal saved to database with row ID: $id',
      );

      await _loadGoals();

      if (mounted) {
        _showSnackBar(
          'Study goal added successfully.',
        );
      }
    } catch (e) {
      debugPrint(
        'Error saving goal: $e',
      );

      if (mounted) {
        _showSnackBar(
          'Could not save study goal.',
          isError: true,
        );
      }
    }
  }

  Future<void> _toggleGoalStatus(
    int id,
    bool completed,
  ) async {
    if (_database == null) return;

    try {
      await _database!.update(
        'goals',
        {
          'done': completed ? 1 : 0,
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      debugPrint(
        'Goal ID $id completion updated to: '
        '$completed',
      );

      await _loadGoals();
    } catch (e) {
      debugPrint(
        'Error updating goal: $e',
      );

      if (mounted) {
        _showSnackBar(
          'Could not update goal.',
          isError: true,
        );
      }
    }
  }

  Future<void> _deleteGoal(int id) async {
    if (_database == null) return;

    try {
      await _database!.delete(
        'goals',
        where: 'id = ?',
        whereArgs: [id],
      );

      await _loadGoals();

      if (mounted) {
        _showSnackBar(
          'Study goal deleted.',
        );
      }
    } catch (e) {
      debugPrint(
        'Error deleting goal: $e',
      );

      if (mounted) {
        _showSnackBar(
          'Could not delete goal.',
          isError: true,
        );
      }
    }
  }

  // ==========================================================
  // SINGLE ADD GOAL BUTTON
  // ==========================================================

  Future<void> _navigateAndAddGoal() async {
    final Map<String, dynamic>? result =
        await Navigator.push<
            Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder:
            (BuildContext context) {
          return const AddGoalScreen();
        },
      ),
    );

    if (result == null) return;

    final String subject =
        result['subject'] as String;

    final double hours =
        result['hours'] as double;

    await _addGoalToDatabase(
      subject,
      hours,
    );
  }

  // ==========================================================
  // STATISTICS
  // ==========================================================

  int get _totalGoals =>
      _goals.length;

  int get _completedGoals {
    return _goals.where(
      (Map<String, dynamic> goal) {
        return goal['done'] == 1;
      },
    ).length;
  }

  double get _totalHours {
    return _goals.fold<double>(
      0,
      (
        double total,
        Map<String, dynamic> goal,
      ) {
        final dynamic value =
            goal['hours'];

        if (value is num) {
          return total + value.toDouble();
        }

        return total;
      },
    );
  }

  double get _progress {
    if (_totalGoals == 0) {
      return 0;
    }

    return _completedGoals /
        _totalGoals;
  }

  // ==========================================================
  // SNACKBAR
  // ==========================================================

  void _showSnackBar(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isError
                    ? Icons.error_outline
                    : Icons.check_circle_outline,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(message),
              ),
            ],
          ),
          behavior:
              SnackBarBehavior.floating,
          margin:
              const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(12),
          ),
        ),
      );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 24,

        // ------------------------------------------------------
        // STUDYFLOW LOGO
        // ------------------------------------------------------
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary,
                borderRadius:
                    BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.school_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'StudyFlow',
              style: TextStyle(
                fontWeight:
                    FontWeight.w700,
                fontSize: 21,
              ),
            ),
          ],
        ),

        // ------------------------------------------------------
        // ONLY ONE ADD GOAL BUTTON + THEME BUTTON
        // ------------------------------------------------------
        actions: [
          // Theme button
          IconButton(
            tooltip: widget.isDarkMode
                ? 'Switch to Light Mode'
                : 'Switch to Dark Mode',
            onPressed:
                widget.onToggleTheme,
            icon: Icon(
              widget.isDarkMode
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
            ),
          ),

          const SizedBox(width: 4),

          // SINGLE ADD GOAL BUTTON
          Padding(
            padding:
                const EdgeInsets.only(
              right: 20,
            ),
            child: FilledButton.icon(
              onPressed:
                  _navigateAndAddGoal,
              icon: const Icon(
                Icons.add,
                size: 20,
              ),
              label: const Text(
                'Add Goal',
                style: TextStyle(
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),

      // --------------------------------------------------------
      // BODY
      // --------------------------------------------------------
      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : LayoutBuilder(
              builder: (
                BuildContext context,
                BoxConstraints constraints,
              ) {
                final bool isWide =
                    constraints.maxWidth >=
                        800;

                return SingleChildScrollView(
                  padding:
                      EdgeInsets.symmetric(
                    horizontal:
                        isWide ? 32 : 18,
                    vertical: 24,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints:
                          const BoxConstraints(
                        maxWidth: 1100,
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          _buildWelcomeHeader(
                            context,
                          ),
                          const SizedBox(
                            height: 24,
                          ),
                          _buildStatsSection(
                            context,
                          ),
                          const SizedBox(
                            height: 28,
                          ),
                          _buildProgressCard(
                            context,
                          ),
                          const SizedBox(
                            height: 32,
                          ),
                          _buildGoalsHeader(
                            context,
                          ),
                          const SizedBox(
                            height: 14,
                          ),
                          _goals.isEmpty
                              ? _buildEmptyState(
                                  context,
                                )
                              : _buildGoalsList(
                                  context,
                                ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  // ==========================================================
  // WELCOME HEADER
  // ==========================================================

  Widget _buildWelcomeHeader(
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin:
              Alignment.topLeft,
          end:
              Alignment.bottomRight,
          colors: [
            Theme.of(context)
                .colorScheme
                .primary,
            Theme.of(context)
                .colorScheme
                .primaryContainer,
          ],
        ),
        borderRadius:
            BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome to StudyFlow 👋',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(
                    color: Colors.white,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),
                Text(
                  'Plan your study goals, '
                  'track your progress, '
                  'and stay consistent.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(
                    color:
                        Colors.white
                            .withValues(
                      alpha: 0.90,
                    ),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          if (MediaQuery.of(context)
                  .size
                  .width >=
              600)
            const Padding(
              padding:
                  EdgeInsets.only(
                left: 20,
              ),
              child: Icon(
                Icons
                    .auto_stories_rounded,
                size: 80,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  // ==========================================================
  // STATISTICS
  // ==========================================================

  Widget _buildStatsSection(
    BuildContext context,
  ) {
    return LayoutBuilder(
      builder: (
        BuildContext context,
        BoxConstraints constraints,
      ) {
        final bool isSmall =
            constraints.maxWidth < 650;

        if (isSmall) {
          return Column(
            children: [
              _StatCard(
                title: 'Study Goals',
                value:
                    '$_totalGoals',
                icon:
                    Icons.flag_rounded,
              ),
              const SizedBox(
                height: 12,
              ),
              _StatCard(
                title: 'Study Hours',
                value: _formatHours(
                  _totalHours,
                ),
                icon: Icons
                    .schedule_rounded,
              ),
              const SizedBox(
                height: 12,
              ),
              _StatCard(
                title: 'Completed',
                value:
                    '$_completedGoals',
                icon: Icons
                    .check_circle_rounded,
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Study Goals',
                value:
                    '$_totalGoals',
                icon:
                    Icons.flag_rounded,
              ),
            ),
            const SizedBox(
              width: 14,
            ),
            Expanded(
              child: _StatCard(
                title: 'Study Hours',
                value: _formatHours(
                  _totalHours,
                ),
                icon: Icons
                    .schedule_rounded,
              ),
            ),
            const SizedBox(
              width: 14,
            ),
            Expanded(
              child: _StatCard(
                title: 'Completed',
                value:
                    '$_completedGoals',
                icon: Icons
                    .check_circle_rounded,
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatHours(
    double hours,
  ) {
    if (hours ==
        hours.roundToDouble()) {
      return '${hours.toInt()}h';
    }

    return '${hours.toStringAsFixed(1)}h';
  }

  // ==========================================================
  // PROGRESS
  // ==========================================================

  Widget _buildProgressCard(
    BuildContext context,
  ) {
    final int percentage =
        (_progress * 100).round();

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surface,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons
                    .insights_rounded,
                size: 24,
              ),
              const SizedBox(
                width: 10,
              ),
              const Expanded(
                child: Text(
                  'Overall Progress',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '$percentage%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.w700,
                  color: Theme.of(
                    context,
                  )
                      .colorScheme
                      .primary,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 16,
          ),
          ClipRRect(
            borderRadius:
                BorderRadius.circular(
              20,
            ),
            child:
                LinearProgressIndicator(
              value: _progress,
              minHeight: 10,
              backgroundColor:
                  Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest,
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Text(
            _totalGoals == 0
                ? 'Create your first study goal to start tracking.'
                : '$_completedGoals of '
                    '$_totalGoals goals completed',
            style: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // GOALS HEADER
  // ==========================================================

  Widget _buildGoalsHeader(
    BuildContext context,
  ) {
    // There is intentionally NO Add Goal
    // button here anymore.
    return const Text(
      'Study Goals',
      style: TextStyle(
        fontSize: 22,
        fontWeight:
            FontWeight.w700,
      ),
    );
  }

  // ==========================================================
  // EMPTY STATE
  // ==========================================================

  Widget _buildEmptyState(
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 50,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surface,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .outlineVariant,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration:
                BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons
                  .menu_book_rounded,
              size: 38,
              color: Theme.of(
                context,
              )
                  .colorScheme
                  .primary,
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          const Text(
            'No study goals yet',
            style: TextStyle(
              fontSize: 19,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          Text(
            'Click the "Add Goal" button above '
            'to create your first study goal.',
            textAlign:
                TextAlign.center,
            style: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // GOALS LIST
  // ==========================================================

  Widget _buildGoalsList(
    BuildContext context,
  ) {
    return Column(
      children: _goals.map(
        (
          Map<String, dynamic> goal,
        ) {
          final int id =
              goal['id'] as int;

          final String subject =
              goal['subject'] as String;

          final double hours =
              (goal['hours'] as num)
                  .toDouble();

          final bool done =
              goal['done'] == 1;

          return Padding(
            padding:
                const EdgeInsets.only(
              bottom: 12,
            ),
            child: _GoalCard(
              subject: subject,
              hours: hours,
              completed: done,
              onChanged:
                  (bool value) {
                _toggleGoalStatus(
                  id,
                  value,
                );
              },
              onDelete: () {
                _confirmDelete(
                  context,
                  id,
                  subject,
                );
              },
            ),
          );
        },
      ).toList(),
    );
  }

  // ==========================================================
  // DELETE CONFIRMATION
  // ==========================================================

  Future<void> _confirmDelete(
    BuildContext context,
    int id,
    String subject,
  ) async {
    final bool? confirmed =
        await showDialog<bool>(
      context: context,
      builder:
          (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete Study Goal?',
          ),
          content: Text(
            'Are you sure you want to delete '
            '"$subject"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child:
                  const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child:
                  const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _deleteGoal(id);
    }
  }
}

// ============================================================
// STAT CARD
// ============================================================

class _StatCard
    extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surface,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration:
                BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer,
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
            ),
            child: Icon(
              icon,
              color: Theme.of(context)
                  .colorScheme
                  .primary,
            ),
          ),
          const SizedBox(
            width: 14,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    )
                        .colorScheme
                        .onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  value,
                  style:
                      const TextStyle(
                    fontSize: 23,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// GOAL CARD
// ============================================================

class _GoalCard
    extends StatelessWidget {
  final String subject;
  final double hours;
  final bool completed;
  final ValueChanged<bool> onChanged;
  final VoidCallback onDelete;

  const _GoalCard({
    required this.subject,
    required this.hours,
    required this.completed,
    required this.onChanged,
    required this.onDelete,
  });

  String _formatHours() {
    if (hours ==
        hours.roundToDouble()) {
      return '${hours.toInt()} hour'
          '${hours == 1 ? '' : 's'}';
    }

    return '${hours.toStringAsFixed(1)} hours';
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return AnimatedContainer(
      duration:
          const Duration(
        milliseconds: 250,
      ),
      width: double.infinity,
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: completed
            ? Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
            : Theme.of(context)
                .colorScheme
                .surface,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: completed
              ? Theme.of(context)
                  .colorScheme
                  .outline
              : Theme.of(context)
                  .colorScheme
                  .outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: completed,
            onChanged:
                (bool? value) {
              if (value != null) {
                onChanged(value);
              }
            },
          ),
          const SizedBox(
            width: 8,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  subject,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.w700,
                    decoration: completed
                        ? TextDecoration
                            .lineThrough
                        : null,
                    color: completed
                        ? Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                        : null,
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                Row(
                  children: [
                    Icon(
                      Icons
                          .schedule_outlined,
                      size: 16,
                      color: Theme.of(
                        context,
                      )
                          .colorScheme
                          .onSurfaceVariant,
                    ),
                    const SizedBox(
                      width: 5,
                    ),
                    Text(
                      _formatHours(),
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        )
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (completed)
            Container(
              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration:
                  BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer,
                borderRadius:
                    BorderRadius.circular(
                  20,
                ),
              ),
              child: const Text(
                'Completed',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(
            width: 4,
          ),
          IconButton(
            tooltip: 'Delete',
            onPressed: onDelete,
            icon: const Icon(
              Icons
                  .delete_outline_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ADD GOAL SCREEN
// ============================================================

class AddGoalScreen
    extends StatefulWidget {
  const AddGoalScreen({
    super.key,
  });

  @override
  State<AddGoalScreen> createState() =>
      _AddGoalScreenState();
}

class _AddGoalScreenState
    extends State<AddGoalScreen> {
  final GlobalKey<FormState>
      _formKey =
      GlobalKey<FormState>();

  final TextEditingController
      _subjectController =
      TextEditingController();

  final TextEditingController
      _hoursController =
      TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  Future<void> _saveGoal() async {
    if (!_formKey.currentState!
        .validate()) {
      return;
    }

    final String subject =
        _subjectController.text
            .trim();

    final double? hours =
        double.tryParse(
      _hoursController.text.trim(),
    );

    if (hours == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    await Future<void>.delayed(
      const Duration(
        milliseconds: 200,
      ),
    );

    if (!mounted) return;

    Navigator.pop(
      context,
      {
        'subject': subject,
        'hours': hours,
      },
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Study Goal',
          style: TextStyle(
            fontWeight:
                FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth: 650,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.all(
                      24,
                    ),
                    decoration:
                        BoxDecoration(
                      color: Theme.of(
                        context,
                      )
                          .colorScheme
                          .primaryContainer,
                      borderRadius:
                          BorderRadius
                              .circular(
                        20,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons
                              .add_task_rounded,
                          size: 44,
                          color: Theme.of(
                            context,
                          )
                              .colorScheme
                              .primary,
                        ),
                        const SizedBox(
                          width: 16,
                        ),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Text(
                                'Create a new goal',
                                style:
                                    TextStyle(
                                  fontSize:
                                      20,
                                  fontWeight:
                                      FontWeight
                                          .w700,
                                ),
                              ),
                              SizedBox(
                                height: 5,
                              ),
                              Text(
                                'Set a clear target for your study session.',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 28,
                  ),

                  const Text(
                    'Subject',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                  const SizedBox(
                    height: 8,
                  ),

                  TextFormField(
                    controller:
                        _subjectController,
                    textInputAction:
                        TextInputAction.next,
                    decoration:
                        const InputDecoration(
                      hintText:
                          'e.g. Database Systems',
                      prefixIcon:
                          Icon(
                        Icons
                            .menu_book_outlined,
                      ),
                    ),
                    validator:
                        (String? value) {
                      if (value == null ||
                          value
                              .trim()
                              .isEmpty) {
                        return 'Please enter a subject.';
                      }

                      if (value
                              .trim()
                              .length <
                          2) {
                        return 'Subject name is too short.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(
                    height: 22,
                  ),

                  const Text(
                    'Study Hours',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                  const SizedBox(
                    height: 8,
                  ),

                  TextFormField(
                    controller:
                        _hoursController,
                    keyboardType:
                        const TextInputType
                            .numberWithOptions(
                      decimal: true,
                    ),
                    decoration:
                        const InputDecoration(
                      hintText: 'e.g. 2',
                      prefixIcon:
                          Icon(
                        Icons
                            .schedule_outlined,
                      ),
                      suffixText:
                          'hours',
                    ),
                    validator:
                        (String? value) {
                      if (value == null ||
                          value
                              .trim()
                              .isEmpty) {
                        return 'Please enter study hours.';
                      }

                      final double? hours =
                          double.tryParse(
                        value.trim(),
                      );

                      if (hours == null) {
                        return 'Please enter a valid number.';
                      }

                      if (hours <= 0) {
                        return 'Hours must be greater than 0.';
                      }

                      if (hours > 24) {
                        return 'Hours cannot exceed 24.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(
                    height: 32,
                  ),

                  // SAVE BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child:
                        FilledButton.icon(
                      onPressed:
                          _isSaving
                              ? null
                              : _saveGoal,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                                color:
                                    Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons
                                  .check_rounded,
                            ),
                      label: Text(
                        _isSaving
                            ? 'Saving...'
                            : 'Save Study Goal',
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  // CANCEL BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child:
                        OutlinedButton(
                      onPressed:
                          _isSaving
                              ? null
                              : () {
                                  Navigator
                                      .pop(
                                    context,
                                  );
                                },
                      child:
                          const Text(
                        'Cancel',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}