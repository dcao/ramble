import 'package:flutter/material.dart';

enum ViewState {
  shrunk,
  shrink,
  enlarge,
  enlarged,
}

class DestinationTitleContent extends StatelessWidget {
  final String text;
  final double fontSize;
  final int maxLines;
  final TextOverflow overflow;
  final bool isOverflow;

  const DestinationTitleContent({
    Key key,
    this.text,
    this.fontSize,
    this.maxLines,
    this.overflow,
    this.isOverflow,
  }) : super(key: key);

  Widget _buildTitleText() => Text(
        text,
        maxLines: maxLines,
        overflow: overflow,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: fontSize,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Material(
        color: Colors.transparent,
        child: isOverflow
            ? OverflowBox(
                alignment: Alignment.topLeft,
                maxWidth: MediaQuery.of(context).size.width - 20,
                maxHeight: double.infinity,
                child: _buildTitleText(),
              )
            : _buildTitleText(),
      ),
    );
  }
}

class SharedText extends StatefulWidget {
  final String title;
  final ViewState viewState;
  final double smallFontSize;
  final double largeFontSize;
  final int maxLines;
  final TextOverflow textOverflow;
  final bool isOverflow;

  const SharedText(
    this.title, {
    Key key,
    @required this.viewState,
    this.smallFontSize = 16.0,
    this.largeFontSize = 28.0,
    this.maxLines = 3,
    this.textOverflow = TextOverflow.ellipsis,
    this.isOverflow = false,
  }) : super(key: key);

  @override
  _SharedTextState createState() => _SharedTextState();
}

class _SharedTextState extends State<SharedText>
    with SingleTickerProviderStateMixin {
  AnimationController _animationController;
  Animation<double> _fontSizeTween;

  double fontSize;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 370),
    )..addListener(() {
        setState(() {
          fontSize = _fontSizeTween.value;
        });
      });

    switch (widget.viewState) {
      case ViewState.enlarge:
        _fontSizeTween = Tween<double>(
          begin: widget.smallFontSize,
          end: widget.largeFontSize,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );

        _animationController.forward(from: 0.0);
        break;

      case ViewState.enlarged:
        fontSize = widget.largeFontSize;
        break;

      case ViewState.shrink:
        _fontSizeTween = Tween<double>(
          begin: widget.largeFontSize,
          end: widget.smallFontSize,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );

        _animationController.forward(from: 0.0);
        break;

      case ViewState.shrunk:
        fontSize = widget.smallFontSize;
        break;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DestinationTitleContent(
      text: widget.title,
      fontSize: fontSize,
      maxLines: widget.maxLines,
      overflow: widget.textOverflow,
      isOverflow: widget.isOverflow,
    );
  }
}
