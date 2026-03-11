import 'package:flutter/material.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/utils/category_colors.dart'; // New import

class InsightsTable extends StatelessWidget {
  final Map<String, int> data;
  final bool isLoading;

  const InsightsTable({
    super.key,
    required this.data,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (data.isEmpty) {
      return GlassContainer(
         height: 100,
         padding: EdgeInsets.zero,
         child: Center(
           child: Text(
             'No data available', 
             style: TextStyle(color: colorScheme.onSurfaceVariant),
           ),
         ),
      );
    }

    // Sort valid data
    var sortedEntries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Calculate total for percentage
    final total = data.values.fold(0, (sum, val) => sum + val);

    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detailed Breakdown',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600, 
              color: colorScheme.onSurface, 
              letterSpacing: -0.5
            ),
          ),
          const SizedBox(height: 24),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 600),
              child: DataTable(
                horizontalMargin: 0,
                columnSpacing: 24,
                headingRowHeight: 40,
                dataRowMinHeight: 60,
                dataRowMaxHeight: 60,
                dividerThickness: 0.00001, // Hide default divider if we want custom or none
                border: TableBorder(
                   horizontalInside: BorderSide(
                     color: colorScheme.onSurface.withOpacity(0.05), 
                     width: 1
                   ),
                ),
                columns: [
                  DataColumn(label: Text('CATEGORY', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.0))),
                  DataColumn(label: Text('FOLDERS', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.0))),
                  DataColumn(label: Text('SHARE', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.0))),
                  DataColumn(label: Text('STATUS', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.0))),
                ],
                rows: sortedEntries.map((entry) {
                  final percentage = total > 0 
                      ? (entry.value / total * 100).toStringAsFixed(1) 
                      : "0.0";
                  
                  return DataRow(cells: [
                    DataCell(Row(
                      children: [
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: _getColorForCategory(entry.key).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.folder_rounded, 
                              size: 16, color: _getColorForCategory(entry.key)),
                        ),
                        const SizedBox(width: 12),
                        Text(entry.key, style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w500, fontSize: 14)),
                      ],
                    )),
                    DataCell(Text(entry.value.toString(), style: TextStyle(color: colorScheme.onSurface.withOpacity(0.8), fontSize: 14))),
                    DataCell(Text('$percentage%', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.8), fontSize: 14))),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669).withOpacity(0.15), // Emerald 600/15
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF059669).withOpacity(0.2)),
                        ),
                        child: const Text('Active', 
                          style: TextStyle(color: Color(0xFF059669), fontSize: 12, fontWeight: FontWeight.w500)),
                      ),
                    ),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForCategory(String category) {
    return CategoryColors.getColor(category);
  }
}
