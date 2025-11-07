// lib/widgets/empty_state.dart
// Reusable empty state widget

import 'package:flutter/material.dart';

/// Empty state widget for when lists or data are empty
class EmptyState extends StatelessWidget {
  final String message;
  final String? subtitle;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;

  const EmptyState({
    super.key,
    required this.message,
    this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 80,
              color: iconColor ?? Colors.white24,
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white54,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Empty state for no machines
class NoMachinesState extends StatelessWidget {
  final VoidCallback? onAdd;

  const NoMachinesState({super.key, this.onAdd});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.precision_manufacturing_outlined,
      message: 'No Machines Found',
      subtitle: 'Add your first machine to get started',
      actionLabel: 'Add Machine',
      onAction: onAdd,
      iconColor: const Color(0xFF4CC9F0),
    );
  }
}

/// Empty state for no jobs
class NoJobsState extends StatelessWidget {
  final VoidCallback? onAdd;

  const NoJobsState({super.key, this.onAdd});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.work_outline,
      message: 'No Jobs Found',
      subtitle: 'Create a job to start production',
      actionLabel: 'Create Job',
      onAction: onAdd,
      iconColor: const Color(0xFF80ED99),
    );
  }
}

/// Empty state for no moulds
class NoMouldsState extends StatelessWidget {
  final VoidCallback? onAdd;

  const NoMouldsState({super.key, this.onAdd});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.category_outlined,
      message: 'No Moulds Found',
      subtitle: 'Add moulds to your inventory',
      actionLabel: 'Add Mould',
      onAction: onAdd,
      iconColor: const Color(0xFFFFD166),
    );
  }
}

/// Empty state for no issues
class NoIssuesState extends StatelessWidget {
  const NoIssuesState({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.check_circle_outline,
      message: 'No Issues',
      subtitle: 'Everything is running smoothly!',
      iconColor: Color(0xFF00D26A),
    );
  }
}

/// Empty state for no data/results
class NoDataState extends StatelessWidget {
  final String? message;

  const NoDataState({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.search_off,
      message: message ?? 'No Data Available',
      subtitle: 'Try adjusting your filters or date range',
    );
  }
}

/// Empty state for search results
class NoSearchResultsState extends StatelessWidget {
  final String searchQuery;

  const NoSearchResultsState({super.key, required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.search_off,
      message: 'No Results Found',
      subtitle: 'No results for "$searchQuery"',
    );
  }
}
