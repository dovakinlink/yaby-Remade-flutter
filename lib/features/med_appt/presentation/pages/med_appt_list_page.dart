import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/features/med_appt/data/models/med_appt_model.dart';
import 'package:yabai_app/features/med_appt/providers/med_appt_list_provider.dart';
import 'package:yabai_app/features/med_appt/presentation/widgets/med_appt_action_dialog.dart';
import 'package:yabai_app/features/med_appt/presentation/widgets/med_appt_card.dart';
import 'package:yabai_app/features/med_appt/utils/date_utils.dart' as med_date_utils;

class MedApptListPage extends StatefulWidget {
  const MedApptListPage({super.key});

  static const routePath = 'med-appt';
  static const routeName = 'med-appt';

  @override
  State<MedApptListPage> createState() => _MedApptListPageState();
}

class _MedApptListPageState extends State<MedApptListPage> {
  late final ScrollController _scrollController;
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_handleScroll);

    // 初始加载
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MedApptListProvider>().loadInitial();
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final provider = context.read<MedApptListProvider>();
    if (!provider.hasNext || provider.isLoadingMore) {
      return;
    }

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 160) {
      unawaited(provider.loadMore());
    }
  }

  /// 处理点击预约项目
  Future<void> _handleAppointmentTap(MedApptModel appointment) async {
    final result = await showMedApptActionDialog(context, appointment);
    
    if (result == 'confirm' && mounted) {
      // 显示加载提示
      final scaffold = ScaffoldMessenger.of(context);
      scaffold.showSnackBar(
        const SnackBar(
          content: Text('正在确认预约...'),
          duration: Duration(seconds: 1),
        ),
      );

      // 确认预约
      final provider = context.read<MedApptListProvider>();
      final success = await provider.confirmAppointment(appointment.id);

      if (mounted) {
        if (success) {
          scaffold.showSnackBar(
            const SnackBar(
              content: Text('预约确认成功！'),
              backgroundColor: AppColors.brandGreen,
            ),
          );
        } else {
          scaffold.showSnackBar(
            const SnackBar(
              content: Text('预约确认失败，请重试'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<MedApptListProvider>();

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkScaffoldBackground
          : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('用药预约'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark
            ? AppColors.darkScaffoldBackground
            : const Color(0xFFF8F9FA),
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.refresh(),
        backgroundColor: isDark ? AppColors.darkCardBackground : Colors.white,
        color: AppColors.brandGreen,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // 日历组件
            SliverToBoxAdapter(
              child: _buildCalendar(provider, isDark),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // 预约列表标题
            if (provider.appointments.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        '本周预约',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkNeutralText : null,
                            ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '共 ${provider.totalCount} 条',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isDark
                                  ? AppColors.darkSecondaryText
                                  : Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // 预约列表
            ..._buildAppointmentList(provider),

            // 底部加载状态
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(child: _buildFooter(provider)),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.pushNamed('med-appt-create').then((result) {
            if (result == true) {
              // 创建成功后刷新列表
              provider.refresh();
            }
          });
        },
        backgroundColor: AppColors.brandGreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCalendar(MedApptListProvider provider, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TableCalendar(
        firstDay: DateTime(2020, 1, 1),
        lastDay: DateTime(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) {
          return isSameDay(provider.selectedDate, day);
        },
        calendarFormat: _calendarFormat,
        startingDayOfWeek: StartingDayOfWeek.monday,
        locale: 'zh_CN',
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkNeutralText : Colors.grey[800],
          ),
          leftChevronIcon: Icon(
            Icons.chevron_left,
            color: isDark ? AppColors.darkNeutralText : Colors.grey[800],
          ),
          rightChevronIcon: Icon(
            Icons.chevron_right,
            color: isDark ? AppColors.darkNeutralText : Colors.grey[800],
          ),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            color: isDark ? AppColors.darkSecondaryText : Colors.grey[600],
          ),
          weekendStyle: TextStyle(
            color: isDark ? AppColors.darkSecondaryText : Colors.grey[600],
          ),
        ),
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: AppColors.brandGreen.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          selectedDecoration: const BoxDecoration(
            color: AppColors.brandGreen,
            shape: BoxShape.circle,
          ),
          todayTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
          selectedTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
          defaultTextStyle: TextStyle(
            color: isDark ? AppColors.darkNeutralText : Colors.grey[800],
          ),
          weekendTextStyle: TextStyle(
            color: isDark ? AppColors.darkNeutralText : Colors.grey[800],
          ),
          outsideTextStyle: TextStyle(
            color: isDark ? AppColors.darkSecondaryText : Colors.grey[400],
          ),
          markerDecoration: const BoxDecoration(
            color: AppColors.brandGreen,
            shape: BoxShape.circle,
          ),
        ),
        eventLoader: (day) {
          // 返回该日期的预约标记
          final count = provider.getAppointmentCountForDate(day);
          return List.generate(count > 3 ? 3 : count, (index) => '•');
        },
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _focusedDay = focusedDay;
          });
          provider.selectDate(selectedDay);
        },
        onFormatChanged: (format) {
          setState(() {
            _calendarFormat = format;
          });
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
      ),
    );
  }

  List<Widget> _buildAppointmentList(MedApptListProvider provider) {
    if (provider.isInitialLoading && provider.appointments.isEmpty) {
      return [
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(
              child: SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation(AppColors.brandGreen),
                ),
              ),
            ),
          ),
        ),
      ];
    }

    if (provider.errorMessage != null && provider.appointments.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            child: _ErrorState(
              message: provider.errorMessage!,
              onRetry: provider.refresh,
            ),
          ),
        ),
      ];
    }

    if (provider.appointments.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 64),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.event_busy_outlined,
                    size: 64,
                    color: const Color(0xFF94A3B8),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '本周暂无预约',
                    style: TextStyle(
                      color: const Color(0xFF94A3B8),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '点击右下角按钮添加预约',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ];
    }

    // 按日期分组显示
    final appointmentsByDate = provider.appointmentsByDate;
    final sortedDates = appointmentsByDate.keys.toList()..sort();

    return [
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final date = sortedDates[index];
            final appointments = appointmentsByDate[date]!;
            final dateObj = med_date_utils.parseDate(date);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 日期标题
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Text(
                    dateObj != null
                        ? med_date_utils.formatDateWithWeekday(dateObj)
                        : date,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.brandGreen,
                        ),
                  ),
                ),
                // 该日期的预约列表
                ...appointments.map((appointment) => MedApptCard(
                      appointment: appointment,
                      onTap: () => _handleAppointmentTap(appointment),
                    )),
              ],
            );
          },
          childCount: sortedDates.length,
        ),
      ),
    ];
  }

  Widget _buildFooter(MedApptListProvider provider) {
    if (provider.appointments.isEmpty) {
      return const SizedBox.shrink();
    }

    if (provider.isLoadingMore) {
      return const SizedBox(
        width: 26,
        height: 26,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation(AppColors.brandGreen),
        ),
      );
    }

    if (provider.loadMoreError != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            provider.loadMoreError!,
            style: const TextStyle(color: Color(0xFFEF4444)),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              provider.loadMore();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.brandGreen,
            ),
            child: const Text('重试加载'),
          ),
        ],
      );
    }

    if (!provider.hasNext) {
      return const Text(
        '已经浏览完全部预约',
        style: TextStyle(color: Color(0xFF94A3B8)),
      );
    }

    return const Text(
      '下拉刷新，继续加载更多内容',
      style: TextStyle(color: Color(0xFF94A3B8)),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.error_outline,
          size: 64,
          color: Color(0xFFEF4444),
        ),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFEF4444),
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () {
            onRetry();
          },
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.brandGreen,
            foregroundColor: Colors.white,
          ),
          child: const Text('重新加载'),
        ),
      ],
    );
  }
}

