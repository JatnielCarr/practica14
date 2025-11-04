import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class TickerBuilder extends StatefulWidget {
  const TickerBuilder({required this.builder, super.key});
  final Widget Function(BuildContext context) builder;
  @override
  State<TickerBuilder> createState() => _TickerBuilderState();
}

class _TickerBuilderState extends State<TickerBuilder>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_handleTick);
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _handleTick(Duration elapsed) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}
