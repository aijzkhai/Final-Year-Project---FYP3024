// screens/analytics_screen.dart (fixed date filtering)
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/task_model.dart';
import '../widgets/side_menu.dart';
import '../utils/constants.dart';
import '../services/storage_service.dart';
import '../widgets/analytics_charts.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool _isLoading = true;
  List<Task> _filteredTasks = [];
  DateTime? _selectedDay;
  DateTime _focusedDay = DateTime.now();
  String _userId = '';
  final StorageService _storageService = StorageService();
  CalendarFormat _calendarFormat = CalendarFormat.week;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    // Set selected day to today initially
    _selectedDay = _focusedDay;

    // Load tasks for today
    await _filterTasksByDate(_selectedDay!);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _filterTasksByDate(DateTime date) async {
    // Normalize the date to remove time component
    final DateTime normalizedDate = DateTime(date.year, date.month, date.day);

    try {
      // Get all completed tasks from storage
      final allTasks = await _storageService.getTasks();
      final List<Task> filteredTasks = [];

      // Filter tasks by completion date
      for (final task in allTasks) {
        if (task.isCompleted && task.completedAt != null) {
          // Normalize the completion date for comparison
          final DateTime taskDate = DateTime(
            task.completedAt!.year,
            task.completedAt!.month,
            task.completedAt!.day,
          );

          // If completion date matches the selected date, include it
          if (taskDate.isAtSameMomentAs(normalizedDate)) {
            filteredTasks.add(task);
          }
        }
      }

      if (mounted) {
        setState(() {
          _filteredTasks = filteredTasks;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load tasks')),
        );
      }
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedDay = null;
      _loadAllCompletedTasks();
    });
  }

  Future<void> _loadAllCompletedTasks() async {
    try {
      final allTasks = await _storageService.getTasks();
      final completedTasks =
          allTasks.where((task) => task.isCompleted).toList();

      if (mounted) {
        setState(() {
          _filteredTasks = completedTasks;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load tasks')),
        );
      }
    }
  }

  Future<void> _loadFilteredTasks() async {
    setState(() {
      _isLoading = true;
    });

    if (_selectedDay != null) {
      await _filterTasksByDate(_selectedDay!);
    } else {
      await _loadAllCompletedTasks();
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () {
              setState(() {
                if (_calendarFormat == CalendarFormat.week) {
                  _calendarFormat = CalendarFormat.month;
                } else {
                  _calendarFormat = CalendarFormat.week;
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_alt_off),
            onPressed: _clearFilters,
          ),
        ],
      ),
      drawer: const SideMenu(selectedIndex: 1),
      body: SafeArea(
        child: _buildAnalyticsContent(),
      ),
    );
  }

  Widget _buildAnalyticsContent() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrowScreen = screenWidth <
        400; // Width threshold for narrow screens like Fold outer display
    final screenHeight = MediaQuery.of(context).size.height;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCalendarSection(isNarrowScreen),
          if (_isLoading)
            Container(
              height: screenHeight * 0.4,
              alignment: Alignment.center,
              child: CircularProgressIndicator(),
            )
          else if (_filteredTasks.isEmpty)
            Container(height: screenHeight * 0.4, child: _buildEmptyState())
          else
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isNarrowScreen
                    ? AppConstants.spacing8
                    : AppConstants.spacing16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppConstants.spacing8,
                    ),
                    child: Text(
                      _selectedDay == null
                          ? 'Overall Analytics'
                          : 'Analytics for ${DateFormat('MMM d').format(_selectedDay!)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacing8),

                  // Completion line chart - shows tasks completed over time
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(isNarrowScreen
                          ? AppConstants.spacing8
                          : AppConstants.spacing16),
                      child: SizedBox(
                        height: isNarrowScreen ? 180 : 220,
                        width: double.infinity,
                        child: CompletionTimeLineChart(tasks: _filteredTasks),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacing8),

                  // Category pie chart - shows distribution of task categories
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(isNarrowScreen
                          ? AppConstants.spacing8
                          : AppConstants.spacing16),
                      child: SizedBox(
                        height: isNarrowScreen ? 180 : 220,
                        width: double.infinity,
                        child: CategoryPieChart(tasks: _filteredTasks),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacing8),

                  // Focus time by hour chart - shows when user is most productive
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(isNarrowScreen
                          ? AppConstants.spacing8
                          : AppConstants.spacing16),
                      child: SizedBox(
                        height: isNarrowScreen ? 180 : 220,
                        width: double.infinity,
                        child: FocusDurationByTimeChart(
                          sessions: _filteredTasks
                              .map((task) => PomodoroSession(
                                    startTime:
                                        task.completedAt ?? DateTime.now(),
                                    duration:
                                        task.pomodoroCount * task.pomodoroTime,
                                  ))
                              .toList(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacing8),

                  // Pomodoro bar chart (existing) - shows focus time by task
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(isNarrowScreen
                          ? AppConstants.spacing8
                          : AppConstants.spacing16),
                      child: SizedBox(
                        height: isNarrowScreen ? 180 : 220,
                        width: double.infinity,
                        child: PomodoroBarChart(tasks: _filteredTasks),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacing16),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCalendarSection(bool isNarrowScreen) {
    final availableWidth = MediaQuery.of(context).size.width;

    return Card(
      margin: EdgeInsets.symmetric(
        horizontal:
            isNarrowScreen ? AppConstants.spacing8 : AppConstants.spacing16,
        vertical: AppConstants.spacing8,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacing8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacing8,
                vertical: AppConstants.spacing4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Select Date',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedDay = null;
                        _loadFilteredTasks();
                      });
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: isNarrowScreen ? 8.0 : 16.0,
                      ),
                    ),
                    child: Text(
                      'View All',
                      style: TextStyle(
                        fontSize: isNarrowScreen ? 12 : 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: availableWidth - (isNarrowScreen ? 32 : 64),
              child: TableCalendar(
                firstDay: DateTime.utc(2021, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                onDaySelected: (selectedDay, focusedDay) {
                  if (!isSameDay(_selectedDay, selectedDay)) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                      _loadFilteredTasks();
                    });
                  }
                },
                onFormatChanged: (format) {
                  if (_calendarFormat != format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  }
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  defaultTextStyle:
                      TextStyle(fontSize: isNarrowScreen ? 12 : 14),
                  weekendTextStyle:
                      TextStyle(fontSize: isNarrowScreen ? 12 : 14),
                  selectedTextStyle: TextStyle(
                    color: Colors.white,
                    fontSize: isNarrowScreen ? 12 : 14,
                    fontWeight: FontWeight.bold,
                  ),
                  todayTextStyle: TextStyle(fontSize: isNarrowScreen ? 12 : 14),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: TextStyle(fontSize: isNarrowScreen ? 10 : 12),
                  weekendStyle: TextStyle(fontSize: isNarrowScreen ? 10 : 12),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: !isNarrowScreen,
                  titleCentered: true,
                  titleTextStyle: TextStyle(
                    fontSize: isNarrowScreen ? 14 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                  leftChevronIcon: Icon(
                    Icons.chevron_left,
                    size: isNarrowScreen ? 16 : 24,
                  ),
                  rightChevronIcon: Icon(
                    Icons.chevron_right,
                    size: isNarrowScreen ? 16 : 24,
                  ),
                  headerPadding: EdgeInsets.symmetric(
                      vertical: isNarrowScreen ? 4.0 : 8.0),
                ),
                rowHeight: isNarrowScreen ? 36 : 48,
                daysOfWeekHeight: isNarrowScreen ? 16 : 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.spacing32),
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: AppConstants.spacing16),
          Text(
            _selectedDay != null
                ? 'No tasks completed on this day'
                : 'No tasks completed yet',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
          ),
          const SizedBox(height: AppConstants.spacing8),
          Text(
            _selectedDay != null
                ? 'Try selecting a different day'
                : 'Complete tasks to see analytics',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildPomodoroChart() {
    // Calculate total pomodoro time
    int totalPomodoroMinutes = 0;
    for (final task in _filteredTasks) {
      totalPomodoroMinutes += task.pomodoroCount * task.pomodoroTime;
    }

    // Create bar chart data
    final List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < _filteredTasks.length; i++) {
      final taskMinutes =
          _filteredTasks[i].pomodoroCount * _filteredTasks[i].pomodoroTime;
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: taskMinutes.toDouble(),
              color: Theme.of(context).colorScheme.primary,
              width: 16,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppConstants.radiusSmall),
                topRight: Radius.circular(AppConstants.radiusSmall),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Text(
          'Total Focus Time: ${totalPomodoroMinutes} minutes',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppConstants.spacing16),
        Expanded(
          child: barGroups.isEmpty
              ? const Center(child: Text('No data to display'))
              : BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: (barGroups.isNotEmpty
                            ? barGroups
                                .map((group) => group.barRods.first.toY)
                                .reduce((a, b) => a > b ? a : b)
                            : 0) *
                        1.2,
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value >= 0 && value < _filteredTasks.length) {
                              String title =
                                  _filteredTasks[value.toInt()].title;
                              // Get just first word or truncate
                              if (title.contains(" ")) {
                                title = title.split(" ")[0];
                              }
                              if (title.length > 5) {
                                title = title.substring(0, 5) + "...";
                              }

                              return SizedBox(
                                width: 40, // Fixed width for title
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    title,
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox();
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toInt().toString(),
                              style: Theme.of(context).textTheme.bodySmall,
                            );
                          },
                        ),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(
                      show: true,
                      horizontalInterval: 20,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.1),
                          strokeWidth: 1,
                        );
                      },
                    ),
                    barGroups: barGroups,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildCompletedTasksList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Completed Tasks',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppConstants.spacing16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredTasks.length,
              itemBuilder: (context, index) {
                final task = _filteredTasks[index];
                return ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: Text(task.title),
                  subtitle: Text(
                    'Pomodoros: ${task.pomodoroCount} • ${task.pomodoroTime} min each',
                  ),
                  trailing: task.completedAt != null
                      ? Text(
                          DateFormat('HH:mm').format(task.completedAt!),
                          style: Theme.of(context).textTheme.bodySmall,
                        )
                      : null,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
