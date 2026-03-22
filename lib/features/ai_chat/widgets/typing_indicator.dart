import 'package:flutter/material.dart';

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key, this.label});
  final String? label;

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10, right: 80),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F3F7),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(18),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.label != null) ...[
              Text(
                widget.label!,
                style: const TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF8E95A4),
                ),
              ),
              const SizedBox(width: 8),
            ],
            AnimatedBuilder(
              animation: _ctrl,
              builder: (context, _) => Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  final delay = i * 0.2;
                  final t = (_ctrl.value - delay).clamp(0.0, 1.0);
                  final y = -4 * (1 - (2 * t - 1) * (2 * t - 1));
                  return Transform.translate(
                    offset: Offset(0, y),
                    child: Container(
                      width: 7,
                      height: 7,
                      margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                      decoration: BoxDecoration(
                        color: Color.lerp(
                          const Color(0xFFBBBFC8),
                          const Color(0xFF6C63FF),
                          t,
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AnimatedBuilder extends AnimatedWidget {
  const AnimatedBuilder({
    super.key,
    required Animation<double> animation,
    required this.builder,
  }) : super(listenable: animation);

  final Widget Function(BuildContext, Widget?) builder;

  @override
  Widget build(BuildContext context) => builder(context, null);
}
