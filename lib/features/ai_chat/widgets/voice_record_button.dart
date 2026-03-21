import 'package:flutter/material.dart';

class VoiceRecordButton extends StatefulWidget {
  const VoiceRecordButton({
    super.key,
    required this.isListening,
    required this.onTap,
  });

  final bool isListening;
  final VoidCallback onTap;

  @override
  State<VoiceRecordButton> createState() => _VoiceRecordButtonState();
}

class _VoiceRecordButtonState extends State<VoiceRecordButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.35).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant VoiceRecordButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isListening && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        listenable: _pulseAnim,
        builder: (BuildContext context, Widget? child) {
          final double value = _pulseAnim.value;
          return Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.isListening
                  ? const Color(0xFFEF5350)
                  : const Color(0xFFF2F3F7),
              boxShadow: widget.isListening
                  ? <BoxShadow>[
                      BoxShadow(
                        color: const Color(0xFFEF5350)
                            .withValues(alpha: 0.3 * (value - 1) / 0.35),
                        blurRadius: 12 * value,
                        spreadRadius: 4 * (value - 1),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              widget.isListening ? Icons.stop_rounded : Icons.mic_rounded,
              color: widget.isListening
                  ? Colors.white
                  : const Color(0xFF8E95A4),
              size: 20,
            ),
          );
        },
      ),
    );
  }
}

/// Lightweight animated widget that rebuilds when [listenable] ticks.
class AnimatedBuilder extends StatelessWidget {
  const AnimatedBuilder({
    super.key,
    required this.listenable,
    required this.builder,
  });

  final Listenable listenable;
  final Widget Function(BuildContext context, Widget? child) builder;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilderCore(listenable: listenable, builder: builder);
  }
}

class AnimatedBuilderCore extends AnimatedWidget {
  const AnimatedBuilderCore({
    super.key,
    required super.listenable,
    required this.builder,
  });

  final Widget Function(BuildContext context, Widget? child) builder;

  @override
  Widget build(BuildContext context) => builder(context, null);
}
