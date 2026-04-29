import 'package:flutter/material.dart';
import '../theme.dart';
import 'game_screen.dart';

class PlayerSetupScreen extends StatefulWidget {
  final String categoryId;
  final String? subcategoryId;
  final bool twoPlayerMode;

  const PlayerSetupScreen({
    super.key,
    required this.categoryId,
    required this.subcategoryId,
    required this.twoPlayerMode,
  });

  @override
  State<PlayerSetupScreen> createState() => _PlayerSetupScreenState();
}

class _PlayerSetupScreenState extends State<PlayerSetupScreen> {
  final _p1Controller = TextEditingController(text: 'Player 1');
  final _p2Controller = TextEditingController(text: 'Player 2');
  final _focus1 = FocusNode();
  final _focus2 = FocusNode();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 100), () {
      _focus1.requestFocus();
    });
  }

  @override
  void dispose() {
    _p1Controller.dispose();
    _p2Controller.dispose();
    _focus1.dispose();
    _focus2.dispose();
    super.dispose();
  }

  void _launch() {
    final p1 = _p1Controller.text.trim().isEmpty ? 'Player 1' : _p1Controller.text.trim();
    final p2 = widget.twoPlayerMode
        ? (_p2Controller.text.trim().isEmpty ? 'Player 2' : _p2Controller.text.trim())
        : null;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          categoryId: widget.categoryId,
          subcategoryId: widget.subcategoryId,
          twoPlayerMode: widget.twoPlayerMode,
          playerOneName: p1,
          playerTwoName: p2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 16, color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(height: 36),
              Text(
                widget.twoPlayerMode ? 'Who\'s playing?' : 'What\'s your name?',
                style: const TextStyle(
                  fontSize: 30, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary, letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.twoPlayerMode
                    ? 'Enter names to personalise the game'
                    : 'Let us know who\'s playing',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 40),

              // Player 1
              _NameField(
                label: widget.twoPlayerMode ? 'Player 1 name' : 'Your name',
                controller: _p1Controller,
                focusNode: _focus1,
                nextFocus: widget.twoPlayerMode ? _focus2 : null,
                color: const Color(0xFF29B6F6),
                icon: Icons.person_rounded,
                onSubmit: widget.twoPlayerMode ? null : _launch,
              ),

              if (widget.twoPlayerMode) ...[
                const SizedBox(height: 16),
                _NameField(
                  label: 'Player 2 name',
                  controller: _p2Controller,
                  focusNode: _focus2,
                  color: const Color(0xFFFF6B6B),
                  icon: Icons.person_rounded,
                  onSubmit: _launch,
                ),
              ],

              const Spacer(),

              // Start button
              GestureDetector(
                onTap: _launch,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.35),
                        blurRadius: 20, offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.play_arrow_rounded,
                          color: Colors.white, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        "Let's Play!",
                        style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700,
                          color: Colors.white, letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }
}

class _NameField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusNode? nextFocus;
  final Color color;
  final IconData icon;
  final VoidCallback? onSubmit;

  const _NameField({
    required this.label, required this.controller,
    required this.focusNode, this.nextFocus,
    required this.color, required this.icon, this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600,
              color: color, letterSpacing: 0.8,
            )),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: AppColors.surface,
            border: Border.all(color: color.withOpacity(0.4), width: 1.5),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Icon(icon, color: color, size: 20),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  textInputAction: nextFocus != null
                      ? TextInputAction.next
                      : TextInputAction.done,
                  onSubmitted: (_) {
                    if (nextFocus != null) {
                      FocusScope.of(context).requestFocus(nextFocus);
                    } else {
                      onSubmit?.call();
                    }
                  },
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: label,
                    hintStyle: TextStyle(
                        color: AppColors.textSecondary.withOpacity(0.5),
                        fontWeight: FontWeight.w400),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
