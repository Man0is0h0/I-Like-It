import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/sync/sync_manager.dart';
import '../../../../core/widgets/glass_container.dart'; // New import

class UserGrowthChart extends StatefulWidget {
  const UserGrowthChart({super.key});

  @override
  State<UserGrowthChart> createState() => _UserGrowthChartState();
}

enum TimeRange {
  last7Days,
  last30Days,
  last6Months,
  lastYear,
  allTime,
}

class _UserGrowthChartState extends State<UserGrowthChart> {
  bool _isLoading = true;
  List<FlSpot> _spots = [];
  List<String> _titles = []; 
  double _maxY = 0;
  List<DateTime> _allDates = []; // Store raw data
  TimeRange _selectedRange = TimeRange.last6Months;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final dates = await SyncManager.instance.remoteDataSource.fetchUserGrowthData();
      if (mounted) {
        _allDates = dates;
        _processData();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _processData() {
    if (_allDates.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    final now = DateTime.now();
    List<DateTime> filteredDates = [];
    int pointsCount = 0;
    bool groupByMonth = true;

    // 1. Filter and Config based on Range
    switch (_selectedRange) {
      case TimeRange.last7Days:
        filteredDates = _allDates.where((d) => now.difference(d).inDays <= 7).toList();
        pointsCount = 7;
        groupByMonth = false;
        break;
      case TimeRange.last30Days:
        filteredDates = _allDates.where((d) => now.difference(d).inDays <= 30).toList();
        pointsCount = 10; // Show tick every ~3 days or just limit axis labels
        groupByMonth = false;
        break;
      case TimeRange.last6Months:
        filteredDates = _allDates.where((d) => _monthDifference(d, now) < 6).toList();
        pointsCount = 6;
        groupByMonth = true;
        break;
      case TimeRange.lastYear:
        filteredDates = _allDates.where((d) => _monthDifference(d, now) < 12).toList();
        pointsCount = 12;
        groupByMonth = true;
        break;
      case TimeRange.allTime:
        filteredDates = _allDates;
        // Calculate spread
        if (filteredDates.isNotEmpty) {
           final first = filteredDates.first; // sorted by DB
           final diffMonths = _monthDifference(first, now);
           pointsCount = diffMonths + 1;
        } else {
           pointsCount = 12;
        }
        groupByMonth = true;
        break;
    }

    // 2. bucket the data
    // Map<Index, Count>
    final Map<int, int> buckets = {};
    
    // For 7D/30D we bucket by Day Difference (0 = today, 1 = yesterday...)
    // For months, we bucket by Month Difference (0 = this month, 1 = last month...)

    if (!groupByMonth) {
       // Daily Bucketing
       // Initialize 0 to (Range-1)
       final maxDays = (_selectedRange == TimeRange.last7Days) ? 6 : 29;

       for (final date in filteredDates) {
          final diff = now.difference(date).inDays;
          if (diff >= 0 && diff <= maxDays) {
             // We want graph left-to-right: oldest -> newest
             // x=0 is oldest.
             // maxDays-diff is the index.
             final index = maxDays - diff;
             buckets[index] = (buckets[index] ?? 0) + 1;
          }
       }
       pointsCount = maxDays + 1;

    } else {
       // Monthly Bucketing
       int maxMonths = 0;
       if (_selectedRange == TimeRange.last6Months) {
         maxMonths = 5;
       } else if (_selectedRange == TimeRange.lastYear) maxMonths = 11;
       else {
          // All time: find oldest
          if (_allDates.isNotEmpty) {
             maxMonths = _monthDifference(_allDates.first, now); // e.g. 24 months ago
          }
       }

       for (final date in filteredDates) {
          final diff = _monthDifference(date, now);
           if (diff >= 0 && diff <= maxMonths) {
             final index = maxMonths - diff;
             buckets[index] = (buckets[index] ?? 0) + 1;
           }
       }
       pointsCount = maxMonths + 1;
    }

    // 3. Convert to Spots and Labels
    final spots = <FlSpot>[];
    double maxVal = 0;
    final titleList = <String>[];
    
    // We might have too many points for All Time or 30 Days to label individually
    // But we need spots for every unit effectively.
    
    for (int i = 0; i < pointsCount; i++) {
        final count = buckets[i] ?? 0;
        spots.add(FlSpot(i.toDouble(), count.toDouble()));
        if (count > maxVal) maxVal = count.toDouble();
        
        // Generate Label
        if (!groupByMonth) {
           // Daily
           final maxDays = (_selectedRange == TimeRange.last7Days) ? 6 : 29;
           final daysAgo = maxDays - i;
           final d = now.subtract(Duration(days: daysAgo));
           titleList.add(DateFormat('d/M').format(d));
        } else {
           // Monthly
           int maxMonths = 0;
           if (_selectedRange == TimeRange.last6Months) {
             maxMonths = 5;
           } else if (_selectedRange == TimeRange.lastYear) maxMonths = 11;
           else if (_allDates.isNotEmpty) maxMonths = _monthDifference(_allDates.first, now);
           
           final monthsAgo = maxMonths - i;
           final d = DateTime(now.year, now.month - monthsAgo, 1);
           titleList.add(DateFormat('MMM').format(d));
        }
    }

    setState(() {
      _spots = spots;
      _titles = titleList;
      _maxY = maxVal + (maxVal * 0.2); 
      _isLoading = false;
    });
  }

  int _monthDifference(DateTime date, DateTime now) {
    return (now.year - date.year) * 12 + now.month - date.month;
  }
  
  String _getRangeLabel(TimeRange range) {
    switch (range) {
      case TimeRange.last7Days: return "Last 7 Days";
      case TimeRange.last30Days: return "Last 30 Days";
      case TimeRange.last6Months: return "Last 6 Months";
      case TimeRange.lastYear: return "Last Year";
      case TimeRange.allTime: return "All Time";
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keep loading only on initial load. Re-filtering is instant usually.
    if (_isLoading && _allDates.isEmpty) {
       return const SizedBox(height: 300, child: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final Color lineColor = colorScheme.primary; 
    final Color gridColor = colorScheme.onSurface.withOpacity(0.05);
    final Color textColor = colorScheme.onSurfaceVariant;

    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                   Row(
                     children: [
                       Text('User Growth',
                         style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.onSurface, letterSpacing: -0.5)),
                       if (_isLoading && _allDates.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
                       ]
                     ],
                   ),
                  Text('New signups over time',
                     style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                ],
              ),
              ),
              const SizedBox(width: 8),
              
              // Filter Menu
              PopupMenuButton<TimeRange>(
                initialValue: _selectedRange,
                onSelected: (TimeRange value) {
                   setState(() {
                     _selectedRange = value;
                     // _isLoading = true; // Optional visual feedback
                     _processData();
                   });
                },
                child: GlassContainer(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  borderRadius: BorderRadius.circular(8),
                  color: colorScheme.onSurface.withOpacity(0.05),
                  enableBlur: false,
                  child: Row(
                    children: [
                      Icon(Icons.filter_list, size: 14, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Text(_getRangeLabel(_selectedRange), style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                itemBuilder: (BuildContext context) => <PopupMenuEntry<TimeRange>>[
                   for (var range in TimeRange.values) 
                     PopupMenuItem<TimeRange>(
                       value: range,
                       child: Text(_getRangeLabel(range)),
                     ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 300,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: _maxY > 0 ? _maxY / 4 : 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: gridColor, strokeWidth: 1);
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: _titles.length > 12 ? (_titles.length / 6).ceilToDouble() : 1, // Skip labels if too many
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < _titles.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(_titles[index], 
                              style: TextStyle(color: textColor, fontSize: 10)), /* smaller font for dense data */
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                     sideTitles: SideTitles(
                       showTitles: true,
                       reservedSize: 40, 
                       getTitlesWidget: (value, meta) {
                          if (value % 1 == 0) { // integer only
                            return Text(value.toInt().toString(),
                               style: TextStyle(color: textColor, fontSize: 12));
                          }
                          return const Text('');
                       },
                     ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                // maxX should match pointsCount - 1
                maxX: (_spots.isNotEmpty) ? (_spots.length - 1).toDouble() : 5, 
                minY: 0,
                maxY: _maxY == 0 ? 5 : _maxY,
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                    tooltipBorder: BorderSide(color: colorScheme.outline.withOpacity(0.1)),
                    tooltipRoundedRadius: 8,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                         // Get date label
                         final index = spot.x.toInt();
                         String dateLabel = '';
                         if (index >= 0 && index < _titles.length) {
                            dateLabel = _titles[index];
                         }
                         
                         return LineTooltipItem(
                           '${spot.y.toInt()} Users\n$dateLabel',
                           TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
                         );
                      }).toList();
                    }
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: _spots,
                    isCurved: true,
                    preventCurveOverShooting: true, 
                    color: lineColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false), 
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          lineColor.withOpacity(0.3),
                          lineColor.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
