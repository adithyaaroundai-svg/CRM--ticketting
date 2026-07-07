import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/design_system.dart';
import '../widgets/deals_table.dart';
import '../widgets/animated_create_deal_fab.dart';
import '../widgets/create_deal_dialog.dart';

class DealsTrackerPage extends StatelessWidget {
  const DealsTrackerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.toString();

    return MainLayout(
      currentPath: currentPath,
      child: Scaffold(
        backgroundColor: AppColors.slate50,
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
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: AppColors.slate200)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                      child: const Text(
                        'Deals',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
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
                    const Text(
                      'Deals Tracker',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.slate900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Track all your incoming deals and their current statuses.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.slate500,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const DealsTable(),
                    const SizedBox(height: 80), // Padding for the FAB
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
