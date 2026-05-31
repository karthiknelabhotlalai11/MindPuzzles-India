import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import '../utils/app_theme.dart';
import '../utils/game_state.dart';

enum SudokuDifficulty { easy, medium, hard }

class SudokuScreen extends StatefulWidget {
  const SudokuScreen({super.key});
  @override
  State<SudokuScreen> createState() => _SudokuScreenState();
}

class _SudokuScreenState extends State<SudokuScreen> {
  SudokuDifficulty _difficulty = SudokuDifficulty.easy;
  List<List<int>> _board = [];
  List<List<int>> _solution = [];
  List<List<bool>> _fixed = [];
  List<List<bool>> _errors = [];
  int _selected = -1;
  int _selectedCol = -1;
  int _moves = 0;
  bool _solved = false;
  int _gridSize = 4;
  late Stopwatch _stopwatch;
  bool _showDifficultyPicker = true;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch();
  }

  void _startGame(SudokuDifficulty difficulty) {
    setState(() {
      _difficulty = difficulty;
      _showDifficultyPicker = false;
      _gridSize = difficulty == SudokuDifficulty.hard ? 6 : 4;
      _solved = false;
      _moves = 0;
      _selected = -1;
      _selectedCol = -1;
    });
    _generatePuzzle();
    _stopwatch.reset();
    _stopwatch.start();
  }

  void _generatePuzzle() {
    if (_gridSize == 4) {
      _generate4x4();
    } else {
      _generate6x6();
    }
  }

  void _generate4x4() {
    final random = Random();
    // Valid 4x4 sudoku solutions
    final solutions = [
      [[1,2,3,4],[3,4,1,2],[2,1,4,3],[4,3,2,1]],
      [[1,2,3,4],[3,4,1,2],[4,3,2,1],[2,1,4,3]],
      [[2,1,4,3],[4,3,2,1],[1,2,3,4],[3,4,1,2]],
      [[3,4,1,2],[1,2,3,4],[4,3,2,1],[2,1,4,3]],
      [[4,3,2,1],[2,1,4,3],[3,4,1,2],[1,2,3,4]],
    ];
    final sol = solutions[random.nextInt(solutions.length)];
    _solution = sol.map((r) => List<int>.from(r)).toList();

    int removals = _difficulty == SudokuDifficulty.easy ? 4 : 8;
    _board = _solution.map((r) => List<int>.from(r)).toList();
    _fixed = List.generate(4, (_) => List.generate(4, (_) => true));
    _errors = List.generate(4, (_) => List.generate(4, (_) => false));

    final positions = [(0,0),(0,1),(0,2),(0,3),(1,0),(1,1),(1,2),(1,3),(2,0),(2,1),(2,2),(2,3),(3,0),(3,1),(3,2),(3,3)];
    positions.shuffle(random);
    for (int i = 0; i < removals; i++) {
      final (r, c) = positions[i];
      _board[r][c] = 0;
      _fixed[r][c] = false;
    }
  }

  void _generate6x6() {
    final random = Random();
    final solutions = [
      [[1,2,3,4,5,6],[4,5,6,1,2,3],[2,3,1,6,4,5],[5,6,4,3,1,2],[3,1,5,2,6,4],[6,4,2,5,3,1]],
      [[1,2,3,4,5,6],[5,6,4,1,2,3],[2,1,5,3,6,4],[4,3,6,5,1,2],[3,5,1,6,4,2],[6,4,2,2,3,5]],
      [[2,1,4,3,6,5],[3,6,5,2,1,4],[1,2,3,4,5,6],[4,5,6,1,2,3],[5,3,2,6,4,1],[6,4,1,5,3,2]],
    ];
    final sol = solutions[random.nextInt(solutions.length)];
    _solution = sol.map((r) => List<int>.from(r)).toList();

    int removals = 14;
    _board = _solution.map((r) => List<int>.from(r)).toList();
    _fixed = List.generate(6, (_) => List.generate(6, (_) => true));
    _errors = List.generate(6, (_) => List.generate(6, (_) => false));

    final positions = <(int,int)>[];
    for (int r = 0; r < 6; r++) for (int c = 0; c < 6; c++) positions.add((r,c));
    positions.shuffle(random);
    for (int i = 0; i < removals; i++) {
      final (r, c) = positions[i];
      _board[r][c] = 0;
      _fixed[r][c] = false;
    }
  }

  void _selectCell(int row, int col) {
    if (_solved || _fixed[row][col]) return;
    setState(() { _selected = row; _selectedCol = col; });
  }

  void _inputNumber(int num) {
    if (_selected < 0 || _selectedCol < 0 || _solved) return;
    if (_fixed[_selected][_selectedCol]) return;
    setState(() {
      _board[_selected][_selectedCol] = num;
      _errors[_selected][_selectedCol] = (num != _solution[_selected][_selectedCol]);
      _moves++;
      _checkSolved();
    });
  }

  void _checkSolved() {
    for (int r = 0; r < _gridSize; r++) {
      for (int c = 0; c < _gridSize; c++) {
        if (_board[r][c] != _solution[r][c]) return;
      }
    }
    _solved = true;
    _stopwatch.stop();
    _onSolved();
  }

  void _onSolved() async {
    await GameState.incrementSudokuLevel();
    final seconds = _stopwatch.elapsed.inSeconds;
    final score = max(0, 1000 - (_moves * 10) - seconds);
    await GameState.addScore(score);
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SolvedDialog(
        title: 'Sudoku Solved! 🎉',
        moves: _moves,
        seconds: seconds,
        score: score,
        onNext: () {
          Navigator.pop(context);
          if (GameState.sudokuNeedsSubscription() && !GameState.isSubscribed()) {
            Navigator.pushReplacementNamed(context, '/subscription');
          } else {
            _startGame(_difficulty);
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
        title: Text('Mini Sudoku', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppTheme.sudokuColor)),
        backgroundColor: Colors.white,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: AppTheme.sudokuColor), onPressed: () => Navigator.pop(context)),
        actions: [
          if (!_showDifficultyPicker)
            TextButton(
              onPressed: () => setState(() => _showDifficultyPicker = true),
              child: Text('New', style: GoogleFonts.poppins(color: AppTheme.sudokuColor, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: _showDifficultyPicker ? _buildDifficultyPicker() : _buildGame(),
    );
  }

  Widget _buildDifficultyPicker() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('🔢', style: const TextStyle(fontSize: 60)),
          const SizedBox(height: 16),
          Text('Select Difficulty', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: AppTheme.sudokuColor)),
          const SizedBox(height: 8),
          Text('Level ${GameState.getSudokuLevel()}', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600])),
          const SizedBox(height: 32),
          _difficultyButton('😊 Easy', 'Small 4×4 grid • Fewer blanks', SudokuDifficulty.easy, const Color(0xFF43A047)),
          const SizedBox(height: 14),
          _difficultyButton('🤔 Medium', 'Small 4×4 grid • More blanks', SudokuDifficulty.medium, const Color(0xFFFFA726)),
          const SizedBox(height: 14),
          _difficultyButton('😤 Hard', 'Bigger 6×6 grid • Maximum blanks', SudokuDifficulty.hard, const Color(0xFFE53935)),
        ]),
      ),
    );
  }

  Widget _difficultyButton(String title, String subtitle, SudokuDifficulty diff, Color color) {
    return GestureDetector(
      onTap: () => _startGame(diff),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
        ),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
            Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
          ])),
          Icon(Icons.arrow_forward_ios, color: color, size: 16),
        ]),
      ),
    );
  }

  Widget _buildGame() {
    return Column(children: [
      _buildTopBar(),
      Expanded(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              _buildGrid(),
              const SizedBox(height: 24),
              _buildNumberPad(),
            ]),
          ),
        ),
      ),
    ]);
  }

  Widget _buildTopBar() {
    final elapsed = _stopwatch.elapsed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: Colors.white,
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        _topStat('Moves', '$_moves'),
        _topStat('Time', '${elapsed.inMinutes}:${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}'),
        _topStat('Level', '${GameState.getSudokuLevel()}'),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: AppTheme.sudokuColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(_difficulty.name.toUpperCase(), style: GoogleFonts.poppins(fontSize: 10, color: AppTheme.sudokuColor, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }

  Widget _topStat(String label, String value) => Column(children: [
    Text(value, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.sudokuColor)),
    Text(label, style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[600])),
  ]);

  Widget _buildGrid() {
    final cellSize = (MediaQuery.of(context).size.width - 64) / _gridSize;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.sudokuColor, width: 2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: AppTheme.sudokuColor.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Column(
          children: List.generate(_gridSize, (row) => Row(
            children: List.generate(_gridSize, (col) {
              final isSelected = _selected == row && _selectedCol == col;
              final isRelated = _selected == row || _selectedCol == col;
              final isFixed = _fixed[row][col];
              final val = _board[row][col];
              final isError = _errors[row][col];
              final isSameNum = val != 0 && val == (_selected >= 0 && _selectedCol >= 0 ? _board[_selected][_selectedCol] : 0);

              Color bgColor = Colors.white;
              if (isSelected) bgColor = AppTheme.sudokuColor.withOpacity(0.2);
              else if (isSameNum) bgColor = AppTheme.sudokuColor.withOpacity(0.1);
              else if (isRelated) bgColor = AppTheme.background;

              return GestureDetector(
                onTap: () => _selectCell(row, col),
                child: Container(
                  width: cellSize,
                  height: cellSize,
                  decoration: BoxDecoration(
                    color: bgColor,
                    border: Border(
                      right: col < _gridSize - 1 ? BorderSide(color: Colors.grey[300]!) : BorderSide.none,
                      bottom: row < _gridSize - 1 ? BorderSide(color: Colors.grey[300]!) : BorderSide.none,
                    ),
                  ),
                  child: Center(
                    child: val == 0 ? null : Text(
                      '$val',
                      style: GoogleFonts.poppins(
                        fontSize: cellSize * 0.4,
                        fontWeight: isFixed ? FontWeight.w700 : FontWeight.w500,
                        color: isError ? AppTheme.error : (isFixed ? AppTheme.sudokuColor : const Color(0xFF1A1A2E)),
                      ),
                    ),
                  ),
                ),
              );
            }),
          )),
        ),
      ),
    );
  }

  Widget _buildNumberPad() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: [
        ...List.generate(_gridSize, (i) => _numButton(i + 1)),
        _numButton(0, isErase: true),
      ],
    );
  }

  Widget _numButton(int num, {bool isErase = false}) {
    return GestureDetector(
      onTap: () => _inputNumber(isErase ? 0 : num),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: isErase ? Colors.grey[100] : AppTheme.sudokuColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isErase ? Colors.grey[300]! : AppTheme.sudokuColor.withOpacity(0.3)),
        ),
        child: Center(
          child: isErase
              ? Icon(Icons.backspace_outlined, color: Colors.grey[600], size: 20)
              : Text('$num', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.sudokuColor)),
        ),
      ),
    );
  }
}

class _SolvedDialog extends StatelessWidget {
  final String title;
  final int moves, seconds, score;
  final VoidCallback onNext, onHome;
  const _SolvedDialog({required this.title, required this.moves, required this.seconds, required this.score, required this.onNext, required this.onHome});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('🎉', style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 8),
          Text(title, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _stat('Moves', '$moves'),
            _stat('Time', '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}'),
            _stat('Score', '$score'),
          ]),
          const SizedBox(height, 20),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: onNext,
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
            child: Text('Next Level ▶', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
          )),
          const SizedBox(height: 8),
          TextButton(onPressed: onHome, child: Text('Back to Home', style: GoogleFonts.poppins(color: Colors.grey[600]))),
        ]),
      ),
    );
  }

  Widget _stat(String label, String value) => Column(children: [
    Text(value, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.primary)),
    Text(label, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600])),
  ]);
}
