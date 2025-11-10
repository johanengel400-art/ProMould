// lib/widgets/overrun_indicator.dart
// Reusable widgets for displaying job overrun status

import 'package:flutter/material.dart';
import '../utils/job_status.dart';

/// Badge showing overrun status
class OverrunBadge extends StatelessWidget {
  final Map job;
  final bool compact;
  
  const OverrunBadge({
    super.key,
    required this.job,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final shotsCompleted = job['shotsCompleted'] as int? ?? 0;
    final targetShots = job['targetShots'] as int? ?? 0;
    final overrunShots = JobStatus.getOverrunShots(shotsCompleted, targetShots);
    
    if (overrunShots == 0) return const SizedBox.shrink();
    
    final percentage = JobStatus.getOverrunPercentage(shotsCompleted, targetShots);
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B6B).withOpacity(0.2),
        borderRadius: BorderRadius.circular(compact ? 4 : 6),
        border: Border.all(color: const Color(0xFFFF6B6B).withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning,
            color: const Color(0xFFFF6B6B),
            size: compact ? 12 : 14,
          ),
          SizedBox(width: compact ? 4 : 6),
          Text(
            compact 
                ? '+$overrunShots'
                : '+$overrunShots (${percentage.toStringAsFixed(1)}%)',
            style: TextStyle(
              color: const Color(0xFFFF6B6B),
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated pulsing indicator for overrunning jobs
class OverrunPulseIndicator extends StatefulWidget {
  final Map job;
  final double size;
  
  const OverrunPulseIndicator({
    super.key,
    required this.job,
    this.size = 12,
  });

  @override
  State<OverrunPulseIndicator> createState() => _OverrunPulseIndicatorState();
}

class _OverrunPulseIndicatorState extends State<OverrunPulseIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = job['status'] as String?;
    if (status != JobStatus.overrunning) return const SizedBox.shrink();
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFFF6B6B).withOpacity(_animation.value),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF6B6B).withOpacity(_animation.value * 0.5),
                blurRadius: widget.size * 0.5,
                spreadRadius: widget.size * 0.2,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Progress bar with overrun visualization
class OverrunProgressBar extends StatelessWidget {
  final Map job;
  final double height;
  final bool showPercentage;
  
  const OverrunProgressBar({
    super.key,
    required this.job,
    this.height = 8,
    this.showPercentage = true,
  });

  @override
  Widget build(BuildContext context) {
    final shotsCompleted = job['shotsCompleted'] as int? ?? 0;
    final targetShots = job['targetShots'] as int? ?? 0;
    
    if (targetShots == 0) return const SizedBox.shrink();
    
    final progress = (shotsCompleted / targetShots).clamp(0.0, 1.0);
    final isOverrun = shotsCompleted > targetShots;
    final overrunProgress = isOverrun 
        ? ((shotsCompleted - targetShots) / targetShots).clamp(0.0, 0.5)
        : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            // Background
            Container(
              height: height,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(height / 2),
              ),
            ),
            // Normal progress
            FractionallySizedBox(
              widthFactor: progress,
              child: Container(
                height: height,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isOverrun
                        ? [const Color(0xFF06D6A0), const Color(0xFFFFD166)]
                        : [const Color(0xFF06D6A0), const Color(0xFF4CC9F0)],
                  ),
                  borderRadius: BorderRadius.circular(height / 2),
                ),
              ),
            ),
            // Overrun progress
            if (isOverrun)
              FractionallySizedBox(
                widthFactor: (1.0 + overrunProgress).clamp(0.0, 1.0),
                child: Container(
                  height: height,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD166), Color(0xFFFF6B6B)],
                    ),
                    borderRadius: BorderRadius.circular(height / 2),
                  ),
                ),
              ),
          ],
        ),
        if (showPercentage) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$shotsCompleted / $targetShots',
                style: TextStyle(
                  color: isOverrun ? const Color(0xFFFF6B6B) : Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (isOverrun)
                Text(
                  '+${shotsCompleted - targetShots} over',
                  style: const TextStyle(
                    color: Color(0xFFFF6B6B),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Status badge with icon and color
class JobStatusBadge extends StatelessWidget {
  final String? status;
  final bool compact;
  
  const JobStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = JobStatus.getColor(status);
    final icon = JobStatus.getIcon(status);
    final displayName = JobStatus.getDisplayName(status);
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(compact ? 4 : 6),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: compact ? 12 : 14),
          if (!compact) ...[
            SizedBox(width: compact ? 4 : 6),
            Text(
              displayName,
              style: TextStyle(
                color: color,
                fontSize: compact ? 10 : 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Overrun duration display
class OverrunDurationDisplay extends StatelessWidget {
  final Map job;
  final bool compact;
  
  const OverrunDurationDisplay({
    super.key,
    required this.job,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final duration = JobStatus.getOverrunDuration(job);
    if (duration == null) return const SizedBox.shrink();
    
    final formatted = JobStatus.formatOverrunDuration(duration);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.timer,
          color: const Color(0xFFFF6B6B),
          size: compact ? 12 : 14,
        ),
        SizedBox(width: compact ? 4 : 6),
        Text(
          'Overrun: $formatted',
          style: TextStyle(
            color: const Color(0xFFFF6B6B),
            fontSize: compact ? 10 : 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
