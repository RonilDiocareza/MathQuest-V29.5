import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../widgets/math_background.dart';
import '../services/auth_service.dart';
import '../services/leaderboard_service.dart';
import '../services/profile_service.dart';
import '../services/tutorial_service.dart';
import '../services/user_progress_service.dart';
import '../widgets/first_time_tutorial_overlay.dart';
import 'badges_screen.dart';
import 'story_levels_screen.dart';
import 'classroom_quest_screen.dart';
import 'teacher_analytics_screen.dart';
import 'profile_screen.dart';
import 'modules_screen.dart';
import 'leaderboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late ProfileService _profileService;
  Uint8List? _profilePhoto;
  String _userName = '';
  bool _isDialogOpen = false;
  bool _showFirstTimeTutorial = false;
  bool _checkingTutorial = false;
  final GlobalKey _profileTutorialKey = GlobalKey();
  final GlobalKey _moduleTutorialKey = GlobalKey();
  final GlobalKey _levelsTutorialKey = GlobalKey();
  final GlobalKey _classroomTutorialKey = GlobalKey();
  final GlobalKey _progressTutorialKey = GlobalKey();
  final GlobalKey _badgesTutorialKey = GlobalKey();
  final GlobalKey _leaderboardTutorialKey = GlobalKey();
  StreamSubscription<List<LeaderboardEntry>>? _leaderboardSubscription;
  int? _currentRank;

  List<FirstTimeTutorialStep> get _tutorialSteps => [
        const FirstTimeTutorialStep(
          title: 'Welcome to MathQuest!',
          message:
              'I’m NPC6, your guide. I’ll show you the main places to explore. Press Next to learn about each one; the highlighted item will not open until you choose it.',
        ),
        FirstTimeTutorialStep(
          title: 'Your Profile',
          message:
              'Tap your profile picture to view your account details, update your profile, or log out.',
          targetKey: _profileTutorialKey,
        ),
        FirstTimeTutorialStep(
          title: 'Modules',
          message:
              'Open Modules to explore lessons and practice the math topics available in the game.',
          targetKey: _moduleTutorialKey,
        ),
        FirstTimeTutorialStep(
          title: 'Levels',
          message:
              'Choose Levels to explore the story map, visit question NPCs, and progress through the available stages.',
          targetKey: _levelsTutorialKey,
        ),
        const FirstTimeTutorialStep(
          title: 'Level Questions & Game Mode',
          message:
              'Answer the problem shown for a level to unlock its Play Game Mode option. In that mode, move around and collect the number requested by the problem.',
        ),
        const FirstTimeTutorialStep(
          title: 'Score, Health & Game Controls',
          message:
              'During play, the HUD shows your score and health hearts. Correct NPC answers and collected number items each add 10 points. Music toggles the soundtrack, Menu lets you resume or quit, and Back leaves the level.',
        ),
        FirstTimeTutorialStep(
          title: 'Classroom Quests',
          message:
              'Open Classroom Quests to view and take part in quests assigned for your classroom.',
          targetKey: _classroomTutorialKey,
        ),
        FirstTimeTutorialStep(
          title: 'My Progress',
          message:
              'My Progress shows your learning activity and progress so you can see how far you have come.',
          targetKey: _progressTutorialKey,
        ),
        FirstTimeTutorialStep(
          title: 'Badges',
          message:
              'Visit Badges to view the achievements you have earned while playing.',
          targetKey: _badgesTutorialKey,
        ),
        FirstTimeTutorialStep(
          title: 'Leaderboard',
          message:
              'The Leaderboard compares players’ scores. Your current rank is also shown near your profile at the top of this screen.',
          targetKey: _leaderboardTutorialKey,
        ),
      ];

  @override
  void initState() {
    super.initState();
    _profileService = ProfileService();
    _checkFirstTimeTutorial();
    _watchCurrentRank();
    _loadProfileData();
    _warmProgressData();
  }

  Future<void> _checkFirstTimeTutorial() async {
    final user = AuthService.currentUser;
    if (user == null || _checkingTutorial) return;
    _checkingTutorial = true;
    try {
      final shouldShow =
          await TutorialService.shouldShowFirstTimeTutorial(user.uid);
      if (!mounted) return;
      setState(() => _showFirstTimeTutorial = shouldShow);
    } catch (error, stackTrace) {
      debugPrint('Unable to check first-time tutorial status: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not check the tutorial status.'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _checkFirstTimeTutorial,
            ),
          ),
        );
      }
    } finally {
      _checkingTutorial = false;
    }
  }

  Future<void> _completeFirstTimeTutorial() async {
    final user = AuthService.currentUser;
    debugPrint(
      '[HomeScreen] Finish pressed: authCurrentUser=${user != null}, '
      'authUid=${user?.uid ?? '(none)'}.',
    );
    debugPrint('[HomeScreen] Awaiting tutorial completion save.');
    await TutorialService.completeFirstTimeTutorial();
    debugPrint('[HomeScreen] Tutorial completion save returned successfully.');
    if (!mounted) {
      debugPrint(
        '[HomeScreen] Widget unmounted after save; no route navigation needed.',
      );
      return;
    }
    debugPrint(
      '[HomeScreen] Dismissing instruction overlay; Home remains the active route.',
    );
    setState(() => _showFirstTimeTutorial = false);
  }

  Future<void> _focusTutorialStep(int index) async {
    final targetKey = _tutorialSteps[index].targetKey;
    final targetContext = targetKey?.currentContext;
    if (targetContext != null) {
      await Scrollable.ensureVisible(
        targetContext,
        alignment: 0.45,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
      );
    }
  }

  void _watchCurrentRank() {
    final uid = AuthService.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;

    _leaderboardSubscription = LeaderboardService.watchTopEntries().listen(
      (entries) {
        LeaderboardEntry? currentEntry;
        for (final entry in entries) {
          if (entry.uid == uid) {
            currentEntry = entry;
            break;
          }
        }

        final currentScore = currentEntry?.totalScore;
        final rank = currentScore == null
            ? null
            : entries.where((entry) => entry.totalScore > currentScore).length +
                1;

        if (!mounted) return;
        setState(() {
          _currentRank = rank;
        });
      },
      onError: (Object error) {
        debugPrint('Unable to watch current leaderboard rank: $error');
        if (!mounted) return;
        setState(() {
          _currentRank = null;
        });
      },
    );
  }

  @override
  void dispose() {
    unawaited(_leaderboardSubscription?.cancel());
    super.dispose();
  }

  Future<void> _warmProgressData() async {
    try {
      await UserProgressService.preloadCurrentUserProgress();
    } catch (error, stackTrace) {
      debugPrint('Unable to preload home progress data: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _openScreen(Widget screen) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  Future<void> _loadProfileData() async {
    try {
      final photoFile = await _profileService.getProfilePhoto();
      final profile = await _profileService.loadProfile();
      if (!mounted) return;
      setState(() {
        _profilePhoto = photoFile;
        _userName = profile['name'] ?? '';
      });
    } catch (error, stackTrace) {
      debugPrint('Unable to load optional home profile data: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MathBackground(
        child: SafeArea(
          child: Stack(
            children: [
              _buildHomeContent(context),
              Positioned(
                top: 6,
                left: 68,
                right: 68,
                child: Image.asset(
                  'assets/images/Icon/Icon2.png',
                  height: 56,
                  fit: BoxFit.contain,
                ),
              ),
              Positioned(
                top: 28,
                right: 18,
                child: GestureDetector(
                  onTap: () => _openProfileDialog(context),
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    key: _profileTutorialKey,
                    child: _profilePhoto != null
                        ? ClipOval(
                            child: Image.memory(
                              _profilePhoto!,
                              fit: BoxFit.cover,
                              width: 54,
                              height: 54,
                            ),
                          )
                        : CircleAvatar(
                            backgroundColor: const Color(0xFFD09F5C),
                            child: Text(
                              _userName.isEmpty
                                  ? 'S'
                                  : _userName[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            ),
                          ),
                  ),
                ),
              ),
              Positioned(
                top: 86,
                right: 18,
                child: Text(
                  _currentRank == null
                      ? "You're Currently Rank: —"
                      : "You're Currently Rank:🏆$_currentRank",
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF744411),
                  ),
                ),
              ),
              if (_showFirstTimeTutorial)
                Positioned.fill(
                  child: FirstTimeTutorialOverlay(
                    steps: _tutorialSteps,
                    onComplete: _completeFirstTimeTutorial,
                    onStepChanged: _focusTutorialStep,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _openProfileDialog(BuildContext context) {
    if (_isDialogOpen) return; // Prevent multiple dialogs

    _isDialogOpen = true;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ProfileScreen(
          isDialog: true,
          onClose: () {
            Navigator.pop(context);
            _loadProfileData(); // Reload profile data when dialog closes
          },
        ),
      ),
    ).then((_) {
      _isDialogOpen = false;
    });
  }

  Widget _buildHomeContent(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 72, 20, 12),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: (constraints.maxHeight - 84).clamp(
              0.0,
              double.infinity,
            ),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  menuCard(
                    context,
                    Icons.view_module,
                    'Module',
                    tutorialKey: _moduleTutorialKey,
                    onTap: () => _openScreen(const ModulesScreen()),
                  ),
                  menuCard(
                    context,
                    Icons.menu_book,
                    'Levels',
                    tutorialKey: _levelsTutorialKey,
                    onTap: () => _openScreen(const StoryLevelsScreen()),
                  ),
                  menuCard(
                    context,
                    Icons.assignment_rounded,
                    'Classroom Quests',
                    tutorialKey: _classroomTutorialKey,
                    onTap: () => _openScreen(const ClassroomQuestScreen()),
                  ),
                  menuCard(
                    context,
                    Icons.bar_chart,
                    'My Progress',
                    tutorialKey: _progressTutorialKey,
                    onTap: () => _openScreen(const TeacherAnalyticsScreen()),
                  ),
                  menuCard(
                    context,
                    Icons.workspace_premium_rounded,
                    'Badges',
                    tutorialKey: _badgesTutorialKey,
                    onTap: () => _openScreen(const BadgesScreen()),
                  ),
                  menuCard(
                    context,
                    Icons.emoji_events,
                    'Leaderboard',
                    tutorialKey: _leaderboardTutorialKey,
                    onTap: () => _openScreen(const LeaderboardScreen()),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget menuCard(
    BuildContext context,
    IconData icon,
    String text, {
    VoidCallback? onTap,
    GlobalKey? tutorialKey,
  }) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final colors = [
      const Color(0xFF348BC4),
      const Color(0xFF57906A),
      const Color(0xFFEF9829),
      const Color(0xFF875DD0),
      const Color(0xFFD94D4A),
      const Color(0xFFE8A02E),
    ];

    final index = [
      'Module',
      'Levels',
      'Classroom Quests',
      'My Progress',
      'Badges',
      'Leaderboard',
    ].indexOf(text);
    final tileColor = colors[index.clamp(0, colors.length - 1)];

    double cardWidth = screenWidth * 0.78;

    if (cardWidth > 690) cardWidth = 690;
    if (cardWidth < 320) cardWidth = screenWidth - 26;

    return GestureDetector(
      key: tutorialKey,
      onTap: onTap,
      child: RepaintBoundary(
        child: Container(
          key: ValueKey('home-menu-$text'),
          width: cardWidth,
          height: 68,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: CustomPaint(
            painter: _PaperMenuCardPainter(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  PhysicalShape(
                    clipper: _MenuIconClipper(),
                    color: tileColor,
                    elevation: 3,
                    shadowColor: Colors.black.withValues(alpha: 0.32),
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: Icon(icon, color: Colors.white, size: 24),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      text,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2E210C),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  if (onTap != null)
                    const Icon(
                      Icons.chevron_right,
                      color: Color(0xFF4C3118),
                      size: 30,
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

class _MenuIconClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => Path()
    ..moveTo(size.width * 0.2, 0)
    ..lineTo(size.width * 0.8, 0)
    ..lineTo(size.width, size.height * 0.2)
    ..lineTo(size.width, size.height * 0.8)
    ..lineTo(size.width * 0.8, size.height)
    ..lineTo(size.width * 0.2, size.height)
    ..lineTo(0, size.height * 0.8)
    ..lineTo(0, size.height * 0.2)
    ..close();

  @override
  bool shouldReclip(_MenuIconClipper oldClipper) => false;
}

class _PaperMenuCardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final card = RRect.fromRectAndRadius(rect, const Radius.circular(15));

    canvas.drawShadow(Path()..addRRect(card), const Color(0xFF2B1B10), 7, true);
    canvas.drawRRect(
      card,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF8EB), Color(0xFFF0E2CA)],
        ).createShader(rect),
    );
    canvas.drawRRect(
      card,
      Paint()
        ..color = const Color(0xFF57371F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );

    final fold = Path()
      ..moveTo(size.width - 23, 2)
      ..lineTo(size.width - 3, 2)
      ..lineTo(size.width - 3, 22)
      ..quadraticBezierTo(size.width - 12, 14, size.width - 23, 2)
      ..close();
    canvas.drawPath(
      fold,
      Paint()..color = const Color(0xFFE5CBA2).withValues(alpha: 0.62),
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width - 23, 2)
        ..quadraticBezierTo(size.width - 14, 14, size.width - 3, 22),
      Paint()
        ..color = const Color(0xFFC69A64).withValues(alpha: 0.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_PaperMenuCardPainter oldDelegate) => false;
}
