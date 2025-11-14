import 'package:flutter/material.dart';
import 'dart:async';

class AuctionCountdownTimer extends StatefulWidget {
  final int timeRemainingSeconds;
  final VoidCallback? onExpired;
  final bool showLabel;
  final TextStyle? textStyle;

  const AuctionCountdownTimer({
    super.key,
    required this.timeRemainingSeconds,
    this.onExpired,
    this.showLabel = true,
    this.textStyle,
  });

  @override
  State<AuctionCountdownTimer> createState() => _AuctionCountdownTimerState();
}

class _AuctionCountdownTimerState extends State<AuctionCountdownTimer> {
  late int _remainingSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.timeRemainingSeconds;
    _startTimer();
  }

  @override
  void didUpdateWidget(AuctionCountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.timeRemainingSeconds != widget.timeRemainingSeconds) {
      _remainingSeconds = widget.timeRemainingSeconds;
      if (_remainingSeconds > 0) {
        _startTimer();
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    if (_remainingSeconds <= 0) {
      widget.onExpired?.call();
      return;
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
          } else {
            timer.cancel();
            widget.onExpired?.call();
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    if (seconds < 0) return '00:00:00';
    
    final days = seconds ~/ 86400;
    final hours = (seconds % 86400) ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (days > 0) {
      return '${days}d ${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
  }

  Color _getColor() {
    if (_remainingSeconds <= 0) {
      return Colors.grey;
    } else if (_remainingSeconds < 3600) {
      // Less than 1 hour - red
      return Colors.red;
    } else if (_remainingSeconds < 86400) {
      // Less than 1 day - orange
      return Colors.orange;
    } else {
      // More than 1 day - green
      return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isExpired = _remainingSeconds <= 0;
    final color = _getColor();
    final defaultStyle = TextStyle(
      fontSize: widget.textStyle?.fontSize ?? 14,
      fontWeight: widget.textStyle?.fontWeight ?? FontWeight.bold,
      color: widget.textStyle?.color ?? color,
    );

    final timeText = isExpired ? 'Ended' : _formatTime(_remainingSeconds);

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        if (widget.showLabel) ...[
          Icon(
            isExpired ? Icons.timer_off : Icons.timer,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: Text(
            timeText,
            style: defaultStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.left,
          ),
        ),
      ],
    );
  }
}



