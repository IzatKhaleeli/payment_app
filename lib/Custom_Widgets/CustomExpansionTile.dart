import 'package:flutter/material.dart';

class CustomExpansionTile extends StatefulWidget {
  final Widget? leading;
  final Widget? title;
  final List<Widget> children;
  final bool initiallyExpanded;
  final Duration animationDuration;
  final ValueChanged<bool>? onExpansionChanged;

  const CustomExpansionTile({
    Key? key,
    this.leading,
    this.title,
    this.children = const <Widget>[],
    this.initiallyExpanded = false,
    this.animationDuration = const Duration(milliseconds: 200),
    this.onExpansionChanged,
  }) : super(key: key);

  @override
  _CustomExpansionTileState createState() => _CustomExpansionTileState();
}

class _CustomExpansionTileState extends State<CustomExpansionTile> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotateAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.animationDuration, vsync: this);
    _expandAnimation = CurvedAnimation(parent: _controller, curve: Curves.fastOutSlowIn);
    _rotateAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(_expandAnimation);
    _isExpanded = PageStorage.of(context)?.readState(context) as bool? ?? widget.initiallyExpanded;
    if (_isExpanded) _controller.value = 1.0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse().then<void>((void value) {
          if (!mounted) return;
          setState(() {
            // Rebuild only after animation ends.
          });
        });
      }
      PageStorage.of(context)?.writeState(context, _isExpanded);
      if (widget.onExpansionChanged != null) {
        widget.onExpansionChanged!(_isExpanded);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool closed = !_isExpanded && _controller.isDismissed;
    return AnimatedBuilder(
      animation: _controller.view,
      builder: (BuildContext context, Widget? child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              onTap: _handleTap,
              leading: widget.leading,
              title: widget.title,
              trailing: widget.leading != null ? RotationTransition(
                turns: _rotateAnimation,
                child: const Icon(Icons.expand_more),
              ) : null,
            ),
            ClipRect(
              child: Align(
                heightFactor: _expandAnimation.value,
                child: child,
              ),
            ),
          ],
        );
      },
      child: closed ? null : Column(children: widget.children),
    );
  }
}
