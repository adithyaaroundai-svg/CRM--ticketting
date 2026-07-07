import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/design_system/theme/app_colors.dart';
import '../../../../core/design_system/components/app_card.dart';

/// Widget for editing ticket workflow settings (response times, visible statuses).
class WorkflowConfigEditor extends StatefulWidget {
  final Map<String, int> slaMinutes;
  final List<String> visibleStatuses;
  final void Function(Map<String, int> sla, List<String> statuses) onSave;

  const WorkflowConfigEditor({
    super.key,
    required this.slaMinutes,
    required this.visibleStatuses,
    required this.onSave,
  });

  @override
  State<WorkflowConfigEditor> createState() => _WorkflowConfigEditorState();
}

class _WorkflowConfigEditorState extends State<WorkflowConfigEditor> {
  late Map<String, int> _slaMinutes;
  late Set<String> _enabledStatuses;
  bool _hasChanges = false;

  static const priorities = ['critical', 'high', 'normal', 'low'];
  static const priorityLabels = {
    'critical': 'Critical',
    'high': 'High',
    'normal': 'Normal',
    'low': 'Low',
  };
  static const priorityColors = {
    'critical': AppColors.error,
    'high': AppColors.warning,
    'normal': AppColors.info,
    'low': AppColors.slate500,
  };

  static const allStatuses = [
    'New',
    'Open',
    'In Progress',
    'On Hold',
    'Waiting for Customer',
    'Resolved',
    'Closed',
    'BillRaised',
    'BillProcessed',
  ];

  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _slaMinutes = Map.from(widget.slaMinutes);
    _enabledStatuses = Set.from(widget.visibleStatuses);

    // Initialize controllers
    for (final p in priorities) {
      _controllers[p] = TextEditingController(
        text: (_slaMinutes[p] ?? _defaultSla(p)).toString(),
      );
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  int _defaultSla(String priority) {
    switch (priority) {
      case 'critical':
        return 60;
      case 'high':
        return 180;
      case 'normal':
        return 480;
      case 'low':
        return 1440;
      default:
        return 480;
    }
  }

  void _onSlaChanged(String priority, String value) {
    final minutes = int.tryParse(value);
    if (minutes != null && minutes > 0) {
      setState(() {
        _slaMinutes[priority] = minutes;
        _hasChanges = true;
      });
    }
  }

  void _toggleStatus(String status, bool enabled) {
    setState(() {
      if (enabled) {
        _enabledStatuses.add(status);
      } else {
        _enabledStatuses.remove(status);
      }
      _hasChanges = true;
    });
  }

  void _save() {
    widget.onSave(_slaMinutes, _enabledStatuses.toList());
    setState(() => _hasChanges = false);
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '$minutes min';
    if (minutes < 1440) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
    }
    final days = minutes ~/ 1440;
    final remaining = minutes % 1440;
    if (remaining == 0) return '${days}d';
    return '${days}d ${remaining ~/ 60}h';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(LucideIcons.clock, size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text(
              'Workflow & Response Times',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.slate900,
              ),
            ),
            const Spacer(),
            if (_hasChanges)
              ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(LucideIcons.save, size: 16),
                label: const Text('Save Changes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Configure response time targets and visible ticket statuses',
          style: TextStyle(fontSize: 13, color: AppColors.slate500),
        ),
        const SizedBox(height: 24),

        // Response time configuration
        const Text(
          'Response Time Targets',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.slate700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Time in minutes before a ticket is considered at risk',
          style: TextStyle(fontSize: 12, color: AppColors.slate500),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            children: priorities.map((priority) {
              final color = priorityColors[priority] ?? AppColors.slate500;
              final currentMinutes =
                  _slaMinutes[priority] ?? _defaultSla(priority);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 80,
                      child: Text(
                        priorityLabels[priority] ?? priority,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: AppColors.slate700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 100,
                      child: TextField(
                        controller: _controllers[priority],
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          suffixText: 'min',
                        ),
                        onChanged: (v) => _onSlaChanged(priority, v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '= ${_formatDuration(currentMinutes)}',
                      style: TextStyle(fontSize: 12, color: AppColors.slate500),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),

        // Visible Statuses
        const Text(
          'Visible Ticket Statuses',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.slate700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Uncheck statuses to hide them from status dropdowns',
          style: TextStyle(fontSize: 12, color: AppColors.slate500),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: allStatuses.map((status) {
              final enabled = _enabledStatuses.contains(status);
              return FilterChip(
                label: Text(
                  status,
                  style: TextStyle(
                    color: enabled ? AppColors.primary : AppColors.textPrimary,
                    fontWeight: enabled ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                selected: enabled,
                onSelected: (v) => _toggleStatus(status, v),
                selectedColor: AppColors.primary.withValues(alpha: 0.15),
                checkmarkColor: AppColors.primary,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
