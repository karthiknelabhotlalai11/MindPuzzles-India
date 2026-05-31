import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';
import '../utils/game_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(child: _buildStats()),
            SliverToBoxAdapter(child: _buildSectionTitle('Choose Your Puzzle')),
            SliverToBoxAdapter(child: _buildGameCards()),
            SliverToBoxAdapter(child: _buildSubscriptionBanner()),
            const SliverToBoxAdapter(child: SizedBox(height: 30)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1565C0), Color(0xFF1E88E5), Color(0xFF42A5F5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
                      child: const Center(child: Text('🧩', style: TextStyle(fontSize: 26))),
                    ),
                    const SizedBox(width: 14),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('MindPuzzles', style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                      Text('India', style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.85), fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 3)),
                    ]),
                    const Spacer(),
                    if (GameState.isSubscribed())
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: AppTheme.gold, borderRadius: BorderRadius.circular(20)),
                        child: Row(children: [
                          const Icon(Icons.star, color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text('PRO', style: GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                        ]),
                      ),
                  ]),
                  const SizedBox(height: 8),
                  Text('Train your brain daily 🧠', style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(children: [
        _statCard('🔢', 'Sudoku', 'Level ${GameState.getSudokuLevel()}', AppTheme.sudokuColor),
        const SizedBox(width: 10),
        _statCard('🟦', 'Patches', 'Level ${GameState.getPatchesLevel()}', AppTheme.patchesColor),
        const SizedBox(width: 10),
        _statCard('🔗', 'Zip', 'Level ${GameState.getZipLevel()}', AppTheme.zipColor),
      ]),
    );
  }

  Widget _statCard(String emoji, String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: AppTheme.cardDecoration(),
        child: Column(children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(title, style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[600])),
          Text(value, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        ]),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A2E))),
    );
  }

  Widget _buildGameCards() {
    final games = [
      {
        'emoji': '🔢', 'title': 'Mini Sudoku', 'subtitle': 'Fill the 4×4 or 6×6 grid\nEasy • Medium • Hard',
        'color1': const Color(0xFF1565C0), 'color2': const Color(0xFF1E88E5),
        'level': GameState.getSudokuLevel(), 'route': '/sudoku', 'locked': GameState.sudokuNeedsSubscription() && !GameState.isSubscribed(),
      },
      {
        'emoji': '🟦', 'title': 'Patches', 'subtitle': 'Place patches to fill the board\nLinkedIn-style puzzle',
        'color1': const Color(0xFF6A1B9A), 'color2': const Color(0xFF9C27B0),
        'level': GameState.getPatchesLevel(), 'route': '/patches', 'locked': GameState.patchesNeedsSubscription() && !GameState.isSubscribed(),
      },
      {
        'emoji': '🔗', 'title': 'Zip', 'subtitle': 'Connect numbers in sequence\nLinkedIn-style path puzzle',
        'color1': const Color(0xFF00695C), 'color2': const Color(0xFF00897B),
        'level': GameState.getZipLevel(), 'route': '/zip', 'locked': GameState.zipNeedsSubscription() && !GameState.isSubscribed(),
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: games.map((game) => _GameCard(
          emoji: game['emoji'] as String,
          title: game['title'] as String,
          subtitle: game['subtitle'] as String,
          color1: game['color1'] as Color,
          color2: game['color2'] as Color,
          level: game['level'] as int,
          route: game['route'] as String,
          locked: game['locked'] as bool,
          onTap: () {
            if (game['locked'] as bool) {
              Navigator.pushNamed(context, '/subscription');
            } else {
              Navigator.pushNamed(context, game['route'] as String).then((_) => setState(() {}));
            }
          },
        )).toList(),
      ),
    );
  }

  Widget _buildSubscriptionBanner() {
    if (GameState.isSubscribed()) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/subscription'),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFFFB300), Color(0xFFFF8F00)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: const Color(0xFFFFB300).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Row(children: [
            const Text('👑', style: TextStyle(fontSize: 32)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Unlock All Levels', style: GoogleFonts.poppins(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
              Text('10 free levels per game • Upgrade for unlimited access', style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.9), fontSize: 11.5)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Text('Unlock', style: GoogleFonts.poppins(color: const Color(0xFFFF8F00), fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ]),
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final String emoji, title, subtitle, route;
  final Color color1, color2;
  final int level;
  final bool locked;
  final VoidCallback onTap;

  const _GameCard({required this.emoji, required this.title, required this.subtitle, required this.color1, required this.color2, required this.level, required this.route, required this.locked, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: AppTheme.cardDecoration(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(children: [
            Row(children: [
              Container(
                width: 90,
                height: 110,
                decoration: BoxDecoration(gradient: LinearGradient(colors: [color1, color2], begin: Alignment.topLeft, end: Alignment.bottomRight)),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(emoji, style: const TextStyle(fontSize: 32)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                    child: Text('Lvl $level', style: GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                ]),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title, style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A2E))),
                    const SizedBox(height: 4),
                    Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600], height: 1.4)),
                    const SizedBox(height: 10),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: color1.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                        child: Text(locked ? '🔒 Locked' : '▶ Play', style: GoogleFonts.poppins(fontSize: 11, color: locked ? Colors.grey : color1, fontWeight: FontWeight.w600)),
                      ),
                      if (!locked) ...[
                        const SizedBox(width: 8),
                        _levelProgress(level),
                      ],
                    ]),
                  ]),
                ),
              ),
            ]),
            if (locked)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.7), borderRadius: BorderRadius.circular(16)),
                  child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.lock_rounded, color: Color(0xFFFFB300), size: 32),
                    Text('Upgrade to continue', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A2E))),
                  ])),
                ),
              ),
          ]),
        ),
      ),
    );
  }

  Widget _levelProgress(int level) {
    final progress = (level % 10) / 10.0;
    return Row(children: [
      SizedBox(
        width: 60,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: progress == 0 ? 1.0 : progress, backgroundColor: Colors.grey[200], color: color1, minHeight: 5),
        ),
      ),
      const SizedBox(width: 4),
      Text('${(progress * 10).toInt()}/10', style: GoogleFonts.poppins(fontSize: 9, color: Colors.grey)),
    ]);
  }
}
