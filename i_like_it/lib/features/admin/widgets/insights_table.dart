import 'package:flutter/material.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/utils/category_colors.dart';

class InsightsTable extends StatefulWidget {
  final Map<String, int> data;
  final bool isLoading;

  const InsightsTable({super.key, required this.data, this.isLoading = false});

  @override
  State<InsightsTable> createState() => _InsightsTableState();
}

class _InsightsTableState extends State<InsightsTable> {
  final ScrollController _scrollController = ScrollController();
  bool _showAll = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (widget.data.isEmpty) {
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
    var sortedEntries = widget.data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final displayEntries = _showAll
        ? sortedEntries
        : sortedEntries.take(7).toList();

    // Calculate total for percentage
    final total = widget.data.values.fold(0, (sum, val) => sum + val);

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
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 24),
          RawScrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            trackVisibility: true,
            interactive: true,
            thickness: 6,
            radius: const Radius.circular(8),
            scrollbarOrientation: ScrollbarOrientation.top,
            thumbColor: colorScheme.onSurfaceVariant.withOpacity(0.5),
            trackColor: colorScheme.onSurface.withOpacity(0.05),
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 16.0,
                ), // Room for the scrollbar at the top
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 600),
                  child: DataTable(
                    horizontalMargin: 0,
                    columnSpacing: 24,
                    headingRowHeight: 40,
                    dataRowMinHeight: 60,
                    dataRowMaxHeight: 60,
                    dividerThickness: 0.00001,
                    border: TableBorder(
                      horizontalInside: BorderSide(
                        color: colorScheme.onSurface.withOpacity(0.05),
                        width: 1,
                      ),
                    ),
                    columns: [
                      DataColumn(
                        label: Text(
                          'CATEGORY',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'FOLDERS',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'SHARE',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'STATUS',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                    rows: displayEntries.map((entry) {
                      final percentage = total > 0
                          ? (entry.value / total * 100).toStringAsFixed(1)
                          : "0.0";

                      return DataRow(
                        cells: [
                          DataCell(
                            Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: _getColorForCategory(
                                      entry.key,
                                    ).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.folder_rounded,
                                    size: 16,
                                    color: _getColorForCategory(entry.key),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  entry.key,
                                  style: TextStyle(
                                    color: colorScheme.onSurface,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DataCell(
                            Text(
                              entry.value.toString(),
                              style: TextStyle(
                                color: colorScheme.onSurface.withOpacity(0.8),
                                fontSize: 14,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              '$percentage%',
                              style: TextStyle(
                                color: colorScheme.onSurface.withOpacity(0.8),
                                fontSize: 14,
                              ),
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF059669,
                                ).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(
                                    0xFF059669,
                                  ).withOpacity(0.2),
                                ),
                              ),
                              child: const Text(
                                'Active',
                                style: TextStyle(
                                  color: Color(0xFF059669),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
          if (sortedEntries.length > 7) ...[
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _showAll = !_showAll;
                  });
                },
                child: Text(
                  _showAll ? 'Show Less Categories' : 'View All Categories',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getColorForCategory(String category) {
    return CategoryColors.getColor(category);
  }
}
