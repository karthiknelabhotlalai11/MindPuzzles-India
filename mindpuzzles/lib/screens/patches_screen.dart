import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import '../utils/app_theme.dart';
import '../utils/game_state.dart';

class PatchesScreen extends StatefulWidget {
  const PatchesScreen({super.key});
  @override
  State<PatchesScreen> createState() => _PatchesScreenState();
}

class _PatchesScreenState extends State<PatchesScreen> {
  static const int gridSize = 5;
  List<List<int>> _board = [];      // 0=empty, 1=filled, -1=target
  List<List<List<int>>> _patches = [];  // Available patch shapes
  List<List<int>> _patchColors = [];
  int _selectedPatch = -1;
  int _moves = 0;
  bool _solved = false;
  late Stopwatch _stopwatch;

  static const patchColors = [
    Color(0xFF6A1B9A), Color(0xFF1565C0), Color(0xFF00695C),
    Color(0xFFE65100), Color(0xFFC62828), Color(0xFF00838F),
  ];

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    _generateLevel();
  }

  void _generateLevel() {
    final random = Random(GameState.getPatchesLevel() * 137 + DateTime.now().millisecond);
    _board = List.generate(gridSize, (_) => List.generate(gridSize, (_) => 0));
    _solved = false;
    _moves = 0;
    _selectedPatch = -1;

    // Generate target pattern - some cells need to be filled
    final targetCells = <(int,int)>[];
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        if (random.nextBool()) {
          _board[r][c] = -1; // target
          targetCells.add((r, c));
        }
      }
    }
    if (targetCells.isEmpty) {
      _board[0][0] = -1;
      _board[0][1] = -1;
      targetCells.addAll([(0,0),(0,1)]);
    }

    // Generate patches that can fill the target
    _patches = [];
    _patchColors = [];
    _generatePatchesForTarget(targetCells, random);
    setState(() {});
  }

  void _generatePatchesForTarget(List<(int,int)> targets, Random random) {
    final remaining = List<(int,int)>.from(targets);
    remaining.shuffle(random);
    int colorIdx = 0;

    while (remaining.isNotEmpty) {
      final size = min(random.nextInt(3) + 1, remaining.length);
      final patch = <List<int>>[];
      for (int i = 0; i < size; i++) {
        final (r, c) = remaining[i];
        patch.add([r, c]);
      }
      remaining.removeRange(0, size);
      _patches.add(patch);
      _patchColors.add([colorIdx % patchColors.length]);
      colorIdx++;
    }
  }

  void _placePatch(int row, int col) {
    if (_selectedPatch < 0 || _solved) return;
    final patch = _patches[_selectedPatch];
    // Check if all patch cells are targets at this offset
    final baseRow = patch[0][0];
    final baseCol = patch[0][1];
    final dRow = row - baseRow;
    final dCol = col - baseCol;

    bool canPlace = true;
    for (final cell in patch) {
      final nr = cell[0] + dRow;
      final nc = cell[1] + dCol;
      if (nr < 0 || nr >= gridSize || nc < 0 || nc >= gridSize) { canPlace = false; break; }
      if (_board[nr][nc] != -1) { canPlace = false; break; }
    }

    if (canPlace) {
      setState(() {
        for (final cell in patch) {
          _board[cell[0] + dRow][cell[1] + dCol] = _selectedPatch + 2;
        }
        _patches.removeAt(_selectedPatch);
        _patchColors.removeAt(_selectedPatch);
        _selectedPatch = -1;
        _moves++;
        _checkSolved();
      });
    } else {
      // Direct place on any target cell
      if (row >= 0 && row < gridSize && col >= 0 && col < gridSize && _board[row][col] == -1) {
        setState(() {
          _board[row][col] = _selectedPatch + 2;
          // place remaining patch cells adjacent if possible
          for (int i = 1; i < patch.length; i++) {
            // find adjacent empty target
            for (final dir in [[-1,0],[1,0],[0,-1],[0,1]]) {
              final nr = row + dir[0];
              final nc = col + dir[1];
              if (nr >= 0 && nr < gridSize && nc >= 0 && nc < gridSize && _board[nr][nc] == -1) {
                _board[nr][nc] = _selectedPatch + 2;
                break;
              }
            }
          }
          _patches.removeAt(_selectedPatch);
          _patchColors.removeAt(_selectedPatch);
          _selectedPatch = -1;
          _moves++;
          _checkSolved();
        });
      }
    }
  }

  void _checkSolved() {
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        if (_board[r][c] == -1) return;
      }
    }
    _solved = true;
    _stopwatch.stop();
    _onSolved();
  }

  void _onSolved() async {
    await GameState.incrementPatchesLevel();
    final score = max(0, 500 - _moves * 10);
    await GameState.addScore(score);
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SolvedDialog(
        title: 'Board Filled! 🎉',
        moves: _moves,
        score: score,
        onNext: () {
          Navigator.pop(context);
          if (GameState.patchesNeedsSubscription() && !GameState.isSubscribed()) {
            Navigator.pushReplacementNamed(context, '/subscription');
          } else {
            setState(() { _stopwatch.reset(); _stopwatch.start(); });
            _generateLevel();
          }
        },
        onHome: () { Navigator.pop(context); Navigator.pop(context); },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Patches', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppTheme.patchesColor)),
        backgroundColor: Colors.white,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: AppTheme.patchesColor), onPressed: () => Navigator.pop(context)),
        actions: [
          TextButton(onPressed: () { setState(() { _stopwatch.reset(); _stopwatch.start(); }); _generateLevel(); },
            child: Text('New', style: GoogleFonts.poppins(color: AppTheme.patchesColor, fontWeight: FontWeight.w600))),
        ],
      ),
      body: Column(children: [
        _buildTopBar(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              _buildInstructions(),
              const SizedBox(height: 16),
              _buildGrid(),
              const SizedBox(height: 24),
              _buildPatchSelector(),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildTopBar() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    color: Colors.white,
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      _topStat('Moves', '$_moves'),
      _topStat('Patches Left', '${_patches.length}'),
      _topStat('Level', '${GameState.getPatchesLevel()}'),
    ]),
  );

  Widget _topStat(String label, String value) => Column(children: [
    Text(value, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.patchesColor)),
    Text(label, style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[600])),
  ]);

  Widget _buildInstructions() => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: AppTheme.patchesColor.withOpacity(0.06), borderRadius: BorderRadius.circular(12)),
    child: Row(children: [
      const Text('💡', style: TextStyle(fontSize: 16)),
      const SizedBox(width: 8),
      Expanded(child: Text(
        'Select a patch below, then tap a purple cell on the board to place it. Fill all purple cells to win!',
        style: GoogleFonts.poppins(fontSize: 11.5, color: AppTheme.patchesColor, height: 1.4),
      )),
    ]),
  );

  Widget _buildGrid() {
    final cellSize = (MediaQuery.of(context).size.width - 64) / gridSize;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.patchesColor, width: 2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: AppTheme.patchesColor.withOpacity(0.15), blurRadius: 12)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Column(
          children: List.generate(gridSize, (row) => Row(
            children: List.generate(gridSize, (col) {
              final val = _board[row][col];
              Color bg;
              if (val == -1) bg = AppTheme.patchesColor.withOpacity(0.15); // target
              else if (val == 0) bg = Colors.white; // empty
              else bg = patchColors[(val - 2) % patchColors.length].withOpacity(0.6); // filled

              return GestureDetector(
                onTap: () => _placePatch(row, col),
                child: Container(
                  width: cellSize, height: cellSize,
                  decoration: BoxDecoration(
                    color: bg,
                    border: Border(
                      right: col < gridSize - 1 ? BorderSide(color: Colors.grey[200]!) : BorderSide.none,
                      bottom: row < gridSize - 1 ? BorderSide(color: Colors.grey[200]!) : BorderSide.none,
                    ),
                  ),
                  child: val == -1 ? Center(child: Container(width: 8, height: 8, decoration: BoxDecoration(color: AppTheme.patchesColor, shape: BoxShape.circle))) : null,
                ),
              );
            }),
          )),
        ),
      ),
    );
  }

  Widget _buildPatchSelector() {
    if (_patches.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Available Patches', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A2E))),
      const SizedBox(height: 10),
      Wrap(
        spacing: 10, runSpacing: 10,
        children: List.generate(_patches.length, (i) {
          final color = patchColors[_patchColors[i][0] % patchColors.length];
          final isSelected = _selectedPatch == i;
          return GestureDetector(
            onTap: () => setState(() => _selectedPatch = isSelected ? -1 : i),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.15) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isSelected ? color : Colors.grey[300]!, width: isSelected ? 2 : 1),
                boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.2), blurRadius: 8)] : null,
              ),
              child: Column(children: [
                Text('Patch ${i + 1}', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
                Text('${_patches[i].length} cell${_patches[i].length > 1 ? 's' : ''}', style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[600])),
              ]),
            ),
          );
        }),
      ),
    ]);
  }
}

class _SolvedDialog extends StatelessWidget {
  final String title;
  final int moves, score;
  final VoidCallback onNext, onHome;
  const _SolvedDialog({required this.title, required this.moves, required this.score, required this.onNext, required this.onHome});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('🎉', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 8),
          Text(title, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _stat('Moves', '$moves'), _stat('Score', '$score'),
          ]),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: onNext,
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.patchesColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
            child: Text('Next Level ▶', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
          )),
          const SizedBox(height: 8),
          TextButton(onPressed: onHome, child: Text('Back to Home', style: GoogleFonts.poppins(color: Colors.grey[600]))),
        ]),
      ),
    );
  }

  Widget _stat(String label, String value) => Column(children: [
    Text(value, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.patchesColor)),
    Text(label, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600])),
  ]);
}
