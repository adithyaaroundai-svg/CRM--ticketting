import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../sales/presentation/widgets/create_lead_dialog.dart';
import '../../../sales/presentation/pages/leads_page.dart';
import '../../../sales/presentation/providers/lead_provider.dart';

class SalesChatPage extends ConsumerStatefulWidget {
  final int initialTab;

  const SalesChatPage({super.key, this.initialTab = 0});

  @override
  ConsumerState<SalesChatPage> createState() => _SalesChatPageState();
}

class _SalesChatPageState extends ConsumerState<SalesChatPage> {
  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.toString();
    final tab = int.tryParse(GoRouterState.of(context).uri.queryParameters['tab'] ?? '0') ?? 0;

    Widget content;
    switch (tab) {
      case 1:
        content = const _SalesTab();
        break;
      case 2:
        content = const _PipelineTab();
        break;
      default:
        content = const _ChatTab();
    }

    return MainLayout(
      currentPath: currentPath,
      child: Scaffold(
        backgroundColor: AppColors.slate50,
        body: Stack(
          children: [
            Positioned.fill(child: content),
            // Create Sale button at top right
            Positioned(
              top: 6,
              right: 24,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => ref.invalidate(leadsProvider),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.slate200),
                        ),
                        child: const Icon(LucideIcons.refreshCw, size: 16, color: AppColors.slate500),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => const CreateLeadDialog(),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.plus,
                          size: 16,
                          color: Colors.white,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Create a Lead',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              ], // close Row children
              ), // close Row
            ), // close Positioned
          ],
        ),
      ),
    );
  }
}

class _ChatTab extends ConsumerWidget {
  const _ChatTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Center(
      child: Text(
        'Sales Chat - Coming Soon',
        style: TextStyle(fontSize: 16, color: AppColors.slate500),
      ),
    );
  }
}

class _SalesTab extends ConsumerWidget {
  const _SalesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Center(
      child: Text(
        'Sales - Coming Soon',
        style: TextStyle(fontSize: 16, color: AppColors.slate500),
      ),
    );
  }
}

class _PipelineTab extends ConsumerWidget {
  const _PipelineTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const LeadsPage(isEmbedded: true);
  }
}

