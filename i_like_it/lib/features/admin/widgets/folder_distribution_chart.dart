import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/utils/category_colors.dart'; // New import


class FolderDistributionChart extends StatefulWidget {
  final Map<String, int> data;
  final VoidCallback onRefresh;

  const FolderDistributionChart({
    super.key,
    required this.data,
    required this.onRefresh,
  });

  @override
  State<FolderDistributionChart> createState() => _FolderDistributionChartState();
}

class _FolderDistributionChartState extends State<FolderDistributionChart> {
  int _touchedIndex = -1;

  // Consistent Color Map
  Color _getCategoryColor(String category) {
    return CategoryColors.getColor(category);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return GlassContainer(
        height: 250,
        padding: EdgeInsets.zero,
        child: const Center(child: Text('No folders yet')),
      );
    }
    
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final total = widget.data.values.fold(0, (sum, val) => sum + val);

    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Folder Topics', 
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.onSurface, letterSpacing: -0.5)),
                  Text('Distribution by category', 
                    style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                ],
              ),
              IconButton(
                icon: Icon(Icons.more_horiz, color: colorScheme.onSurfaceVariant, size: 20),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 24),
          Stack(
            children: [
               LayoutBuilder(
                 builder: (context, constraints) {
                   // Responsive switch: if width is small, stack vertically
                   final bool isNarrow = constraints.maxWidth < 350;
                   
                   // The chart widget (reused)
                   final chartWidget = SizedBox(
                    width: 200,
                    height: 200,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            pieTouchData: PieTouchData(
                              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                setState(() {
                                  if (!event.isInterestedForInteractions ||
                                      pieTouchResponse == null ||
                                      pieTouchResponse.touchedSection == null) {
                                    _touchedIndex = -1;
                                    return;
                                  }
                                  _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                });
                              },
                            ),
                            borderData: FlBorderData(show: false),
                            sectionsSpace: 4, 
                            centerSpaceRadius: 60, 
                            sections: _generateSections(total),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: _touchedIndex != -1 && _touchedIndex < widget.data.length
                                ? Text(
                                    widget.data.entries.toList()[_touchedIndex].value.toString(),
                                    key: ValueKey('val_$_touchedIndex'),
                                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                                  )
                                : Text(
                                    total.toString(),
                                    key: const ValueKey('total'),
                                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                                  ),
                            ),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: _touchedIndex != -1 && _touchedIndex < widget.data.length
                                ? Text(
                                    widget.data.entries.toList()[_touchedIndex].key,
                                    key: ValueKey('name_$_touchedIndex'),
                                    style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant, letterSpacing: 1.0),
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : Text(
                                    'Topics',
                                    key: const ValueKey('label'),
                                    style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant, letterSpacing: 1.0),
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );

                   if (isNarrow) {
                     return Center(
                       child: Column(
                         mainAxisSize: MainAxisSize.min,
                         children: [
                           chartWidget,
                           const SizedBox(height: 20),
                           _buildLegend(context),
                         ],
                       ),
                     );
                   } else {
                     return SizedBox(
                       height: 200, // Fixed height only for Row mode to align nicely
                       child: Row(
                         children: [
                           chartWidget,
                           const SizedBox(width: 24),
                           Expanded(child: _buildLegend(context)),
                         ],
                       ),
                     );
                   }
                 },
               ),
            ],
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _generateSections(int total) {
    final entries = widget.data.entries.toList();

    return List.generate(entries.length, (i) {
      final isTouched = i == _touchedIndex;
      final radius = isTouched ? 25.0 : 20.0;
      final entry = entries[i];
      
      return PieChartSectionData(
        color: _getCategoryColor(entry.key),
        value: entry.value.toDouble(),
        title: '', // Hide title on chart for clean look
        radius: radius,
        showTitle: false,
      );
    });
  }

  Widget _buildLegend(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final entries = widget.data.entries.toList();
    // Sort by value descending
    entries.sort((a, b) => b.value.compareTo(a.value));
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: entries.take(4).map((entry) {
        final color = _getCategoryColor(entry.key);
        
        final total = widget.data.values.fold(0, (sum, val) => sum + val);
        final percentage = (entry.value / total * 100).toStringAsFixed(1);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(entry.key,
                       style: theme.textTheme.bodyMedium?.copyWith(
                         color: colorScheme.onSurface.withOpacity(0.8),
                         fontWeight: FontWeight.w600,
                         fontSize: 13,
                       )), 
                ],
              ),
              GlassContainer(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                borderRadius: BorderRadius.circular(4),
                color: colorScheme.onSurface.withOpacity(0.05),
                enableBlur: false, // Optimize
                child: Text('$percentage%', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 11)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
