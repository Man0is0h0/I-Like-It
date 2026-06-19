import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/sync/sync_manager.dart';
import '../../core/auth/user_session_manager.dart';
import '../../core/widgets/gradient_scaffold.dart'; // New Import
import 'widgets/dashboard_kpi_card.dart';
import 'widgets/folder_distribution_chart.dart';
import 'widgets/user_growth_chart.dart';
import 'widgets/insights_table.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  Map<String, dynamic>? _stats;
  Map<String, int> _folderDistribution = {};
  bool _isLoading = true;
  Key _tableKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (_stats == null) {
      setState(() => _isLoading = true);
    } else {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Refreshing dashboard data...'),
          duration: Duration(seconds: 1),
        ),
      );
    }

    try {
      final results = await Future.wait([
        SyncManager.instance.remoteDataSource.fetchSystemStats(),
        SyncManager.instance.remoteDataSource.fetchSystemCategoryDistribution(),
      ]);

      if (mounted) {
        setState(() {
          _stats = results[0];
          _folderDistribution = results[1] as Map<String, int>;
          _isLoading = false;
          _tableKey = UniqueKey();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading dashboard: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleLogout() {
    UserSessionManager.clearSession();
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    // GradientScaffold handles the background (Light/Dark)
    return GradientScaffold(
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final isDesktop = constraints.maxWidth > 900;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildKpiSection(isDesktop),
                              const SizedBox(height: 24),
                              if (isDesktop)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(flex: 4, child: UserGrowthChart()),
                                    const SizedBox(width: 24),
                                    Expanded(
                                      flex: 3,
                                      child: FolderDistributionChart(
                                        data: _folderDistribution,
                                        onRefresh: _loadData,
                                      ),
                                    ),
                                  ],
                                )
                              else ...[
                                const UserGrowthChart(),
                                const SizedBox(height: 24),
                                FolderDistributionChart(
                                  data: _folderDistribution,
                                  onRefresh: _loadData,
                                ),
                              ],
                              const SizedBox(height: 24),
                              InsightsTable(
                                key: _tableKey,
                                data: _folderDistribution,
                              ),
                              const SizedBox(height: 48),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8),
            border: Border(
              bottom: BorderSide(
                color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: Theme.of(context).iconTheme.color,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.grid_view,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Admin Console',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                ),

                Container(
                  height: 24,
                  width: 1,
                  color: isDark ? Colors.white10 : Colors.black12,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                ),
                IconButton(
                  icon: Icon(
                    Icons.refresh,
                    color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                  ),
                  tooltip: 'Refresh Data',
                  onPressed: _loadData,
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.redAccent),
                  tooltip: 'Logout',
                  onPressed: _handleLogout,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKpiSection(bool isDesktop) {
    if (_stats == null) return const SizedBox();

    final users = _stats!['users'].toString();
    final links = _stats!['links'].toString();
    final folders = _stats!['folders'].toString();
    final active = _stats!['active_users'].toString();

    final cards = [
      DashboardKpiCard(
        title: 'Total Users',
        value: users,
        icon: Icons.people,
        color: Colors.blue,
      ),
      DashboardKpiCard(
        title: 'Active (24h)',
        value: active,
        icon: Icons.offline_bolt,
        color: Colors.orange,
      ),
      DashboardKpiCard(
        title: 'Total Links',
        value: links,
        icon: Icons.link,
        color: Colors.purple,
      ),
      DashboardKpiCard(
        title: 'Total Folders',
        value: folders,
        icon: Icons.folder,
        color: Colors.teal,
      ),
    ];

    if (isDesktop) {
      return Row(
        children: cards
            .map(
              (c) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: c,
                ),
              ),
            )
            .toList(),
      );
    } else {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.0,
        children: cards,
      );
    }
  }
}
