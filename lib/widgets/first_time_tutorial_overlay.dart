import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class FirstTimeTutorialStep {
  const FirstTimeTutorialStep({
    required this.title,
    required this.message,
    this.targetKey,
  });

  final String title;
  final String message;
  final GlobalKey? targetKey;
}

class FirstTimeTutorialOverlay extends StatefulWidget {
  const FirstTimeTutorialOverlay({
    required this.steps,
    required this.onComplete,
    this.onStepChanged,
    super.key,
  }) : assert(steps.length > 0);

  final List<FirstTimeTutorialStep> steps;
  final Future<void> Function() onComplete;
  final Future<void> Function(int index)? onStepChanged;

  @override
  State<FirstTimeTutorialOverlay> createState() =>
      _FirstTimeTutorialOverlayState();
}

class _FirstTimeTutorialOverlayState extends State<FirstTimeTutorialOverlay> {
  final GlobalKey _overlayBoundsKey = GlobalKey();
  int _stepIndex = 0;
  bool _isSaving = false;
  bool _isCompleted = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _advance() async {
    if (_isSaving) return;

    if (_stepIndex == widget.steps.length - 1) {
      setState(() {
        _isSaving = true;
        _saveError = null;
      });
      try {
        await widget.onComplete();
        if (!mounted) return;
        setState(() => _isCompleted = true);
      } catch (error, stackTrace) {
        debugPrint(
          '[FirstTimeTutorialOverlay] Finish save callback failed: '
          'type=${error.runtimeType}, message=$error.',
        );
        if (kDebugMode) debugPrintStack(stackTrace: stackTrace);
        if (mounted) {
          setState(() {
            _isSaving = false;
            _saveError = 'Could not save your progress. Please try again.';
          });
        }
      }
      return;
    }

    final nextIndex = _stepIndex + 1;
    try {
      await widget.onStepChanged?.call(nextIndex);
      if (!mounted) return;
      setState(() {
        _stepIndex = nextIndex;
        _saveError = null;
      });
    } catch (error, stackTrace) {
      debugPrint('Unable to focus tutorial feature: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Rect? _targetRect() {
    final targetContext = widget.steps[_stepIndex].targetKey?.currentContext;
    final overlayContext = _overlayBoundsKey.currentContext;
    final targetObject = targetContext?.findRenderObject();
    final overlayObject = overlayContext?.findRenderObject();
    if (targetObject is! RenderBox ||
        overlayObject is! RenderBox ||
        !targetObject.hasSize ||
        !overlayObject.hasSize) {
      return null;
    }

    final topLeft = targetObject.localToGlobal(Offset.zero);
    final overlayTopLeft = overlayObject.localToGlobal(Offset.zero);
    return (topLeft - overlayTopLeft & targetObject.size).inflate(5);
  }

  @override
  Widget build(BuildContext context) {
    if (_isCompleted) return const SizedBox.shrink();

    final step = widget.steps[_stepIndex];
    final targetRect = _targetRect();

    return LayoutBuilder(
      key: _overlayBoundsKey,
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final maxHeight = constraints.maxHeight;
        final isWide = maxWidth > maxHeight;
        final panelHeight = math.min(maxHeight * (isWide ? 0.68 : 0.46), 280.0);
        final characterWidth = math.min(
          math.max(maxWidth * (isWide ? 0.26 : 0.28), 72.0),
          isWide ? 220.0 : 112.0,
        );

        return Stack(
          fit: StackFit.expand,
          children: [
            const ModalBarrier(
              dismissible: false,
              color: Color(0xB8000000),
            ),
            if (targetRect != null)
              Positioned.fromRect(
                rect: targetRect,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border:
                          Border.all(color: const Color(0xFFFFD65A), width: 4),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0xCCFFD65A),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            SafeArea(
              minimum: const EdgeInsets.all(12),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 820,
                    maxHeight: panelHeight,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: characterWidth,
                        height: panelHeight,
                        child: Image.asset(
                          'assets/images/npcs/npc6.png',
                          fit: BoxFit.contain,
                          alignment: Alignment.bottomCenter,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildDialogue(step, maxHeight),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDialogue(FirstTimeTutorialStep step, double availableHeight) {
    final isFinalStep = _stepIndex == widget.steps.length - 1;

    return Container(
      constraints:
          BoxConstraints(maxHeight: math.min(availableHeight * 0.46, 280)),
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF5A3620), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  step.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF3C2A1C),
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${_stepIndex + 1}/${widget.steps.length}',
                style: const TextStyle(
                  color: Color(0xFF76563D),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                step.message,
                style: const TextStyle(
                  color: Color(0xFF3C2A1C),
                  fontSize: 14,
                  height: 1.3,
                ),
              ),
            ),
          ),
          if (_saveError != null) ...[
            const SizedBox(height: 4),
            Text(
              _saveError!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _isSaving ? null : _advance,
              style: TextButton.styleFrom(
                minimumSize: const Size(64, 34),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                backgroundColor: const Color(0xFF8F5C2D),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(isFinalStep ? 'Finish' : 'Next'),
            ),
          ),
        ],
      ),
    );
  }
}
