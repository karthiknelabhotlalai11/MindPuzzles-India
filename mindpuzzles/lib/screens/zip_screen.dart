import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import '../utils/app_theme.dart';
import '../utils/game_state.dart';

class ZipScreen extends StatefulWidget {
  const ZipScreen({super.key});
  @override
  State<ZipScreen> createState() => _ZipScreenState();
}

class _ZipScreenState extends State<ZipScreen> {
  static const int gridSize = 5;
  late List<List<int>> _grid;       // numbered cells (0 = path, N = numbered)
  late List<List<bool>> _visited;   // visited during drawing
  late List<List<int>> _solution;   // solution path order
  List<int> _path = [];             // current drawn path (flat indices)
  bool _isDrawing = false;
  bool _solved = false;
  int _moves = 0;
  late Stopwatch _stopwatch;
  List<int> _numberPositions = [];  // flat indices of numbered cells

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    _generateLevel();
  }

  void _generateLevel() {
    final random = Random(GameState.getZipLevel() * 97 + DateTime.now().millisecond);
    _grid = List.generate(gridSize, (_) => List.generate(gridSize, (_) => 0));
    _visited = List.generate(gridSize, (_) => List.generate(gridSize, (_) => false));
    _solution = List.generate(gridSize, (_) => List.generate(gridSize, (_) => 0));
    _path = [];
    _solved = false;
    _moves = 0;
    _numberPositions = [];

    // Generate a random Hamiltonian path through grid
    final pathOrder = <int>[];
    _generatePath(random, pathOrder);

    // Place numbers at intervals along the path
    final numCount = 4 + random.nextInt(3); // 4-6 numbers
    final interval = pathOrder.length ~/ (numCount - 1);
    final numberedIndices = <int>{};
    for (int i = 0; i < numCount; i++) {
      final idx = min(i * interval, pathOrder.length - 1);
      numberedIndices.add(pathOrder[idx]);
    }
    numberedIndices.add(pathOrder.last);

    int num = 1;
    for (final idx in pathOrder) {
      if (numberedIndices.contains(idx)) {
        final r = idx ~/ gridSize;
        final c = idx % gridSize;
        _grid[r][c] = num++;
        _numberPositions.add(idx);
      }
    }

    setState(() {});
  }

  void _generatePath(Random random, List<int> path) {
    final visited = List.generate(gridSize * gridSize, (_) => false);
    path.clear();

    int start = random.nextInt(gridSize * gridSize);
    path.add(start);
    visited[start] = true;

    while (path.length < gridSize * gridSize) {
      final current = path.last;
      final r = current ~/ gridSize;
      final c = current % gridSize;
      final neighbors = <int>[];
      for (final dir in [[-1,0],[1,0],[0,-1],[0,1]]) {
        final nr = r + dir[0]; final nc = c + dir[1];
        if (nr >= 0 && nr < gridSize && nc >= 0 && nc < gridSize) {
          final ni = nr * gridSize + nc;
          if (!visited[ni]) neighbors.add(ni);
        }
      }
      if (neighbors.isEmpty) break;
      neighbors.shuffle(random);
      path.add(neighbors.first);
      visited[neighbors.first] = true;
    }

    // If path doesn't cover all cells, fill remaining randomly
    for (int i = 0; i < gridSize * gridSize; i++) {
      if (!visited[i]) path.add(i);
    }
  }

  void _onPanStart(DragStartDetails details, int row, int col) {
    final idx = row * gridSize + col;
    if (_grid[row][col] > 0) {
      // Only start from a numbered cell
      setState(() {
        _path = [idx];
        _visited = List.generate(gridSize, (_) => List.generate(gridSize, (_) => false));
        _visited[row][col] = true;
        _isDrawing = true;
        _moves++;
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails details, BuildContext context) {
    if (!_isDrawing) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final cellSize = box.size.width / gridSize;
    final local = box.globalToLocal(details.globalPosition);
    final col = (local.dx / cellSize).floor();
    final row = (local.dy / cellSize).floor();
    if (row < 0 || row >= gridSize || col < 0 || col >= gridSize) return;
    final idx = row * gridSize + col;
    if (_visited[row][col]) return;

    // Check if adjacent to last path cell
    final lastIdx = _path.last;
    final lastR = lastIdx ~/ gridSize;
    final lastC = lastIdx % gridSize;
    if ((lastR - row).abs() + (lastC - col).abs() != 1) return;

    setState(() {
      _path.add(idx);
      _visited[row][col] = true;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isDrawing) return;
    setState(() => _isDrawing = false);
    _checkSolved();
  }

  void _checkSolved() {
    if (_path.length < gridSize * gridSize) return;

    // Check all numbered cells are visited in order
    final numberedInPath = _path.where((idx) {
      final r = idx ~/ gridSize;
      final c = idx % gridSize;
      return _grid[r][c] > 0;
    }).toList();

    bool inOrder = true;
    for (int i = 1; i < numberedInPath.length; i++) {
      final prevNum = _grid[numberedInPath[i-1] ~/ gridSize][numberedInPath[i-1] % gridSize];
      final curNum = _grid[numberedInPath[i] ~/ gridSize][numberedInPath[i] % gridSize];
      if (curNum <= prevNum) { inOrder = false; break; }
    }

    if (inOrder && _path.length == gridSize * gridSize) {
      _solved = true;
      _stopwatch.stop();
      _onSolved();
    }
  }

  void _onSolved() async {
    await GameState.incrementZipLevel();
    final score = max(0, 800 - _moves * 20);
    await GameState.addScore(score);
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SolvedDialog(
        moves: _moves,
        score: score,
        onNext: () {
          Navigator.pop(context);
          if (GameState.zipNeedsSubscription() && !GameState.isSubscribed()) {
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
        title: Text('Zip', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppTheme.zipColor)),
        backgroundColor: Colors.white,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: AppTheme.zipColor), onPressed: () => Navigator.pop(context)),
        actions: [
          TextButton(onPressed: () { setState(() { _stopwatch.reset(); _stopwatch.start(); }); _generateLevel(); },
            child: Text('New', style: GoogleFonts.poppins(color: AppTheme.zipColor, fontWeight: FontWeight.w600))),
        ],
      ),
      body: Column(children: [
        _buildTopBar(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              _buildInstructions(),
              const SizedBox(height: 16),
              Expanded(child: _buildGrid()),
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
      _topStat('Cells', '${_path.length}/${gridSize * gridSize}'),
      _topStat('Level', '${GameState.getZipLevel()}'),
    ]),
  );

  Widget _topStat(String label, String value) => Column(children: [
    Text(value, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.zipColor)),
    Text(label, style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[600])),
  ]);

  Widget _buildInstructions() => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: AppTheme.zipColor.withOpacity(0.06), borderRadius: BorderRadius.circular(12)),
    child: Row(children: [
      const Text('💡', style: TextStyle(fontSize: 16)),
      const SizedBox(width: 8),
      Expanded(child: Text(
        'Draw a path from 1 → 2 → 3... that passes through every cell. Swipe to draw your path!',
        style: GoogleFonts.poppins(fontSize: 11.5, color: AppTheme.zipColor, height: 1.4),
      )),
    ]),
  );

  Widget _buildGrid() {
    return LayoutBuilder(builder: (context, constraints) {
      final cellSize = constraints.maxWidth / gridSize;
      return GestureDetector(
        onPanStart: (d) {
          final col = (d.localPosition.dx / cellSize).floor();
          final row = (d.localPosition.dy / cellSize).floor();
          if (row >= 0 && row < gridSize && col >= 0 && col < gridSize) {
            _onPanStart(d, row, col);
          }
        },
        onPanUpdate: (d) => _onPanUpdate(d, context),
        onPanEnd: _onPanEnd,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.zipColor, width: 2),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: AppTheme.zipColor.withOpacity(0.15), blurRadius: 12)],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CustomPaint(
              painter: _ZipPainter(path: _path, gridSize: gridSize, cellSize: cellSize),
              child: Column(
                children: List.generate(gridSize, (row) => Row(
                  children: List.generate(gridSize, (col) {
                    final idx = row * gridSize + col;
                    final num = _grid[row][col];
                    final inPath = _visited[row][col];
                    return Container(
                      width: cellSize, height: cellSize,
                      decoration: BoxDecoration(
                        color: inPath ? AppTheme.zipColor.withOpacity(0.1) : Colors.white,
                        border: Border(
                          right: col < gridSize - 1 ? BorderSide(color: Colors.grey[200]!) : BorderSide.none,
                          bottom: row < gridSize - 1 ? BorderSide(color: Colors.grey[200]!) : BorderSide.none,
                        ),
                      ),
                      child: Center(
                        child: num > 0 ? Container(
                          width: cellSize * 0.65,
                          height: cellSize * 0.65,
                          decoration: BoxDecoration(color: AppTheme.zipColor, shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: AppTheme.zipColor.withOpacity(0.4), blurRadius: 6)]),
                          child: Center(child: Text('$num', style: GoogleFonts.poppins(color: Colors.white, fontSize: cellSize * 0.3, fontWeight: FontWeight.w800))),
                        ) : null,
                      ),
                    );
                  }),
                )),
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _ZipPainter extends CustomPainter {
  final List<int> path;
  final int gridSize;
  final double cellSize;

  _ZipPainter({required this.path, required this.gridSize, required this.cellSize});

  @override
  void paint(Canvas canvas, Size size) {
    if (path.length < 2) return;
    final paint = Paint()
      ..color = AppTheme.zipColor.withOpacity(0.5)
      ..strokeWidth = cellSize * 0.3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final pathObj = Path();
    for (int i = 0; i < path.length; i++) {
      final r = path[i] ~/ gridSize;
      final c = path[i] % gridSize;
      final x = c * cellSize + cellSize / 2;
      final y = r * cellSize + cellSize / 2;
      if (i == 0) pathObj.moveTo(x, y);
      else pathObj.lineTo(x, y);
    }
    canvas.drawPath(pathObj, paint);
  }

  @override
  bool shouldRepaint(_ZipPainter old) => old.path != path;
}

class _SolvedDialog extends StatelessWidget {
  final int moves, score;
  final VoidCallback onNext, onHome;
  const _SolvedDialog({required this.moves, required this.score, required this.onNext, required this.onHome});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('🎉', style: TextStyle(fontSize: 48)),
          Text('Path Complete!', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _stat('Moves', '$moves'), _stat('Score', '$score'),
          ]),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: onNext,
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.zipColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
            child: Text('Next Level ▶', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
          )),
          const SizedBox(height: 8),
          TextButton(onPressed: onHome, child: Text('Back to Home', style: GoogleFonts.poppins(color: Colors.grey[600]))),
        ]),
      ),
    );
  }

  Widget _stat(String label, String value) => Column(children: [
    Text(value, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.zipColor)),
    Text(label, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600])),
  ]);
}
