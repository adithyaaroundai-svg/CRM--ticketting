import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/design_system/widgets/glass_card.dart';
import '../widgets/deals_table.dart';
import '../widgets/animated_create_deal_fab.dart';
import '../widgets/create_deal_dialog.dart';

class DealsTrackerPage extends ConsumerWidget {
  const DealsTrackerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPath = GoRouterState.of(context).uri.toString();
    final gc = GlassColors.of(context, ref);

    return MainLayout(
      currentPath: currentPath,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
        floatingActionButton: AnimatedCreateDealFab(
          onPressed: () {
            showDialog(
              context: context,
              builder: (ctx) => const CreateDealDialog(),
            );
          },
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Nav / Tabs Area
            ClipRect(
              child: BackdropFilter(
                filter: gc.isGlass
                    ? ImageFilter.blur(sigmaX: 12, sigmaY: 12)
                    : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                child: Container(
                  decoration: BoxDecoration(
                    color: gc.isGlass
                        ? Colors.white.withValues(alpha: 0.07)
                        : gc.surface,
                    border: Border(bottom: BorderSide(color: gc.border)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: gc.primary, width: 2),
                            ),
                          ),
                          child: Text(
                            'Deals',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: gc.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Main Content Area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Deals Tracker',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: gc.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Track all your incoming deals and their current statuses.',
                      style: TextStyle(
                        fontSize: 14,
                        color: gc.onSurfaceMuted,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const DealsTable(),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
