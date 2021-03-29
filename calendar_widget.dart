import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'datetime_utils.dart' as utils;

const Duration _monthScrollDuration = Duration(milliseconds: 200);
const List<String> kWeekDayTexts = ['日', '一', '二', '三', '四' ,'五' ,'六'];
const double _dayPickerRowHeight = 36.0;
const int _maxDayPickerRowCount = 6; // A 31 day month that starts on Saturday.

const double _maxDayPickerHeight = _dayPickerRowHeight * (_maxDayPickerRowCount);

typedef MarkWidgetsBuilder = List<Widget> Function(BuildContext context, DateTime dateTime);
typedef HeaderWidgetBuilder = Widget Function(BuildContext context, DateTime dateTime);

enum CalendarType {
  /// 只显示当前周
  week,
  /// 显示当前月
  month,
}


/// Displays a grid of days for a given month and allows the user to select a date.
/// See also [CalendarDatePicker]
// ignore: must_be_immutable
class CalendarDatePicker extends StatefulWidget {
  CalendarPickerConfig _pickerConfig;

  CalendarDatePicker({
    Key key,
    @required DateTime initialDate,
    @required DateTime firstDate,
    @required DateTime lastDate,
    Color primaryColor,
    ValueChanged<DateTime> onSelectedDateChanged,
    ValueChanged<DateTime> onDisplayedMonthChanged,
    CalendarType calendarType,
    SelectableDayPredicate selectableDayPredicate,
    EdgeInsets padding,
    MarkWidgetsBuilder markWidgetsBuilder,
    HeaderWidgetBuilder headerWidgetBuilder,
    bool showHeaderWidget,
    bool showTypeChangeWidget,
  }) : assert(initialDate != null),
       assert(firstDate != null),
       assert(lastDate != null),
       super(key: key) {
    assert(
      !lastDate.isBefore(firstDate),
      'lastDate $lastDate must be on or after firstDate $firstDate.'
    );
    if (initialDate.isBefore(firstDate)) {
      initialDate = firstDate;
    }
    if (initialDate.isAfter(lastDate)) {
      initialDate = lastDate;
    }
    selectableDayPredicate ??= (DateTime day) => true;
    padding ??= EdgeInsets.zero;
    showTypeChangeWidget ??= false;

    _pickerConfig = CalendarPickerConfig(
      firstDate: firstDate,
      lastDate: lastDate,
      initialDate: initialDate,
      primaryColor: primaryColor,
      onSelectedDateChanged: onSelectedDateChanged,
      onDisplayedMonthChanged: onDisplayedMonthChanged,
      calendarType: calendarType ?? CalendarType.month,
      selectableDayPredicate: selectableDayPredicate,
      padding: padding,
      markWidgetsBuilder: markWidgetsBuilder,
      headerWidgetBuilder: headerWidgetBuilder,
      showHeaderWidget: showHeaderWidget,
      showTypeChangeWidget: showTypeChangeWidget,
    );
  }

  @override
  _CalendarDatePickerState createState() => _CalendarDatePickerState();
}

class _CalendarDatePickerState extends State<CalendarDatePicker> {
  CalendarPickerConfig _pickerConfig;
  
  /// 当前显示的月份
  DateTime _currentDisplayedMonthDate;
  DateTime _selectedDate;

  final GlobalKey _monthPickerKey = GlobalKey();

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _pickerConfig = widget._pickerConfig;
    _currentDisplayedMonthDate = DateTime(_pickerConfig.initialDate.year, _pickerConfig.initialDate.month);
    _selectedDate = _pickerConfig.initialDate;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }
  
  void refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  void _handleMonthChanged(DateTime date) {
    if (_currentDisplayedMonthDate.year != date.year || _currentDisplayedMonthDate.month != date.month) {
      _currentDisplayedMonthDate = DateTime(date.year, date.month);
      _pickerConfig.onDisplayedMonthChanged?.call(_currentDisplayedMonthDate);
    }
    refresh();
  }

  void _handleDayChanged(DateTime value) {
    _selectedDate = value;
    _pickerConfig.onSelectedDateChanged?.call(_selectedDate);
    refresh();
  }

  Widget _buildPicker() {
    assert(_pickerConfig.calendarType != null);
    return _MonthPicker(
      key: _monthPickerKey,
      initialMonth: _currentDisplayedMonthDate,
      currentDate: DateTime.now(),
      selectedDate: _selectedDate,
      onSelectedDateChanged: _handleDayChanged,
      onDisplayedMonthChanged: _handleMonthChanged,
      padding: _pickerConfig.padding,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<CalendarPickerConfig>.value(
      value: _pickerConfig,
      child: Container(
        padding: _pickerConfig.padding,
        // decoration: BoxDecoration(
        //   border: Border.all(
        //     color: Colors.red,
        //     width: 1,
        //   )
        // ),
        child: _buildPicker(),
      ),
    );
  }
}

class _MonthPicker extends StatefulWidget {
  /// Creates a month picker.
  _MonthPicker({
    Key key,
    @required this.initialMonth,
    @required this.currentDate,
    @required this.selectedDate,
    @required this.onSelectedDateChanged,
    @required this.onDisplayedMonthChanged,
    this.padding,
  }) : assert(selectedDate != null),
       assert(currentDate != null),
       assert(onSelectedDateChanged != null),
       super(key: key);

  final DateTime initialMonth;
  final DateTime currentDate;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelectedDateChanged;
  final ValueChanged<DateTime> onDisplayedMonthChanged;
  final EdgeInsets padding;

  @override
  State<StatefulWidget> createState() => _MonthPickerState();
}

class _MonthPickerState extends State<_MonthPicker> {
  DateTime _currentMonth;
  DateTime _nextMonthDate;
  DateTime _previousMonthDate;
  /// 当前选中的日期，当月份改变后，选中日期自动变成1号
  DateTime _selectedDate;
  PageController _pageController;
  MaterialLocalizations _localizations;
  TextDirection _textDirection;
  CalendarPickerConfig _pickerConfig;

  @override
  void initState() {
    super.initState();
    _currentMonth = widget.initialMonth;
    _selectedDate = widget.selectedDate;
    _previousMonthDate = utils.addMonthsToMonthDate(_currentMonth, -1);
    _nextMonthDate = utils.addMonthsToMonthDate(_currentMonth, 1);
    _pickerConfig = Provider.of(context, listen: false);
    _pageController = PageController(initialPage: utils.monthDelta(_pickerConfig.firstDate, _currentMonth));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _localizations = MaterialLocalizations.of(context);
    _textDirection = Directionality.of(context);
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  /// 月份改变回调
  void _handleMonthPageChanged(int monthPage) {
    final DateTime monthDate = utils.addMonthsToMonthDate(_pickerConfig.firstDate, monthPage);
    if (_currentMonth.year != monthDate.year || _currentMonth.month != monthDate.month) {
      _currentMonth = DateTime(monthDate.year, monthDate.month);
      _previousMonthDate = utils.addMonthsToMonthDate(_currentMonth, -1);
      _nextMonthDate = utils.addMonthsToMonthDate(_currentMonth, 1);
      widget.onDisplayedMonthChanged?.call(_currentMonth);
      // 当月份改变后，默认选择显示月份的1号
      _selectedDate = _currentMonth;
      if (this.mounted) {
        setState(() {});
      }
    }
  }

  void _handleNextMonth() {
    if (!_isDisplayingLastMonth) {
      SemanticsService.announce(
        _localizations.formatMonthYear(_nextMonthDate),
        _textDirection,
      );
      _pageController.nextPage(
        duration: _monthScrollDuration,
        curve: Curves.ease,
      );
    }
  }

  void _handlePreviousMonth() {
    if (!_isDisplayingFirstMonth) {
      SemanticsService.announce(
        _localizations.formatMonthYear(_previousMonthDate),
        _textDirection,
      );
      _pageController.previousPage(
        duration: _monthScrollDuration,
        curve: Curves.ease,
      );
    }
  }

  /// True if the earliest allowable month is displayed.
  bool get _isDisplayingFirstMonth {
    return !_currentMonth.isAfter(
      DateTime(_pickerConfig.firstDate.year, _pickerConfig.firstDate.month),
    );
  }

  /// True if the latest allowable month is displayed.
  bool get _isDisplayingLastMonth {
    return !_currentMonth.isBefore(
      DateTime(_pickerConfig.lastDate.year, _pickerConfig.lastDate.month),
    );
  }

  Widget _buildItems(BuildContext context, int index) {
    final DateTime month = utils.addMonthsToMonthDate(_pickerConfig.firstDate, index);
    return _DayPicker(
      key: ValueKey<DateTime>(month),
      displayedMonth: month,
      currentDate: DateTime.now(),
      selectedDate: _selectedDate,
      onSelectedDateChanged: (datetime) {
        _selectedDate = datetime;
        widget.onSelectedDateChanged(datetime);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [
      weekDayHeaderWidget(),
      Container(
        height: _pickerConfig.calendarType == CalendarType.month ? _maxDayPickerHeight : _dayPickerRowHeight,
        child: PageView.builder(
          controller: _pageController,
          physics: _pickerConfig.calendarType == CalendarType.week ? NeverScrollableScrollPhysics() : AlwaysScrollableScrollPhysics(),
          itemBuilder: _buildItems,
          itemCount: utils.monthDelta(_pickerConfig.firstDate, _pickerConfig.lastDate) + 1,
          scrollDirection: Axis.horizontal,
          onPageChanged: _handleMonthPageChanged,
        ),
      ),
    ];

    // 头部组件
    var headerWidget = _pickerConfig.headerWidgetBuilder?.call(context, _currentMonth);
    if (_pickerConfig.showHeaderWidget) {
      headerWidget ??= dataTimeHeaderWidget();
      children.insert(0, headerWidget);
    }

    // 周模式和月模式切换组件
    if (_pickerConfig.showTypeChangeWidget) {
      children.add(expandWidget());
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  /// 日历展开和收缩的组件
  Widget expandWidget() {
    var isExpanded = _pickerConfig.calendarType == CalendarType.month;
    return GestureDetector(
      onTap: () {
        _pickerConfig.calendarType =  isExpanded ? CalendarType.week : CalendarType.month;
        if (mounted) {
          setState(() {});
        }
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Transform.rotate(
            angle: isExpanded ? 0 : math.pi ,
            child: Container(child: Icon(Icons.arrow_drop_up, color: Color(0xFF999999),),),
          ),
          SizedBox(width: 5,),
          Text('${isExpanded ? "收起" : "展开"}', style: TextStyle(color: Color(0xFF999999), fontSize: 12,)),
        ],
      ),
    );
  }

  /// 显示当前年月的标题，可切换
  Widget dataTimeHeaderWidget() {
    return Container(
      height: 40,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
           IconButton(
            icon: const Icon(Icons.chevron_left),
            color: Color(0xFF888888),
            tooltip: _isDisplayingLastMonth ? null : '上一月',
            onPressed: _isDisplayingLastMonth ? null : _handlePreviousMonth,
          ),
          Expanded(
            child: Text(
              '${_currentMonth.year}年${_currentMonth.month}月',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, color: Color(0xFF222222), fontWeight: FontWeight.w500),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            color: Color(0xFF888888),
            tooltip: _isDisplayingLastMonth ? null : '下一月',
            onPressed: _isDisplayingLastMonth ? null : _handleNextMonth,
          ),
        ],
      ),
    );
  }

  /// 星期的标题
  Widget weekDayHeaderWidget() {
    // 周一至周五的标题样式
    var textStyleWorkDay = TextStyle(color: Color(0xFF222222), fontSize: 13);
    // 周六周日的标题样式
    var textStyleRestDay = TextStyle(color: Color(0xFFFB5E21), fontSize: 13);

    List<Widget> weekdayWidgets = [];
    for (int i=0; i<DateTime.daysPerWeek; i++) {
      var style = (i == 0 || i == 6) ? textStyleRestDay : textStyleWorkDay;
      weekdayWidgets.add(Text(kWeekDayTexts[i], style: style)); 
    }
    return Container(
      height: 30,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: weekdayWidgets,
      ),
    );
  }
}

/// Displays the days of a given month and allows choosing a day.
class _DayPicker extends StatelessWidget {
  _DayPicker({
    Key key,
    this.displayedMonth,
    this.currentDate,
    this.selectedDate,
    this.onSelectedDateChanged,
  }) : super(key: key);

  /// The current date at the time the picker is displayed.
  final DateTime currentDate;
  /// The month whose days are displayed by this picker.
  final DateTime displayedMonth;
  /// 当前选择的日期
  final DateTime selectedDate;
  /// 选择日期改变的函数回调
  final ValueChanged<DateTime> onSelectedDateChanged;

  @override
  Widget build(BuildContext context) {
    CalendarPickerConfig _pickerConfig = Provider.of(context, listen: false);
    final MaterialLocalizations localizations = MaterialLocalizations.of(context);
    final int year = displayedMonth.year;
    final int month = displayedMonth.month;

    final DateTime lastMonth = utils.addMonthsToMonthDate(displayedMonth, -1);
    final int daysInLastMonth = utils.getDaysInMonth(lastMonth.year, lastMonth.month);
    int nextMonthDaysDisplayed = 7 - utils.lastDayOffset(year, month, localizations);
    if (nextMonthDaysDisplayed == 7) {
      nextMonthDaysDisplayed = 0;
    }

    final int daysInMonth = utils.getDaysInMonth(year, month);
    final int dayOffset = utils.firstDayOffset(year, month, localizations);

    // 可被选中的天的颜色
    var enabledDayColor = Color(0xFF222222);
     // 不能被选中的天的颜色
    var disabledDayColor = Color(0xFF999999);
    // 当前被选中的天的颜色
    var selectedDayColor = Colors.white;
    var selectedDayBackground = _pickerConfig.primaryColor;
    // 当前天，但是没有选中时的颜色
    var todayColor = _pickerConfig.primaryColor;
    var todayBackground = Colors.white;

    // 当前显示月份的天数组件集合
    List<Widget> dayItems = <Widget>[];

    int dayStart, dayEnd;
    // 根据日历类型计算出需要显示的日期范围
    switch (_pickerConfig.calendarType) {
      case CalendarType.month:
        dayStart = -dayOffset;
        dayEnd = daysInMonth + nextMonthDaysDisplayed;
        break;
      case CalendarType.week: {
        DateTime weekStart = currentDate.subtract(Duration(days: currentDate.weekday));
        DateTime weekEnd = currentDate.add(Duration(days: DateTime.daysPerWeek - 1 - currentDate.weekday));
        dayStart = utils.isSameMonth(weekStart, currentDate) ? weekStart.day - 1 : -dayOffset;
        dayEnd = utils.isSameMonth(weekEnd, currentDate) ? weekEnd.day : weekEnd.day + nextMonthDaysDisplayed;
        break;
      }
    }

    int day = dayStart;
    while (day++ < dayEnd) {
      final DateTime dayToBuild = DateTime(year, month, day);
      bool datePredicate = _pickerConfig.selectableDayPredicate?.call(dayToBuild);
      final bool isDisabled = dayToBuild.isAfter(_pickerConfig.lastDate) || dayToBuild.isBefore(_pickerConfig.firstDate) || !datePredicate;
      final bool isInDisplayMonth = dayToBuild.month == displayedMonth.month;

      BoxDecoration decoration;
      Color dayColor = enabledDayColor;

      final bool isSelectedDay = utils.isSameDay(selectedDate, dayToBuild);
      if (isSelectedDay) {
        dayColor = selectedDayColor;
        decoration = BoxDecoration(
          color: selectedDayBackground,
          borderRadius: BorderRadius.circular(4),
        );
      } else if (isDisabled || !isInDisplayMonth) {
        dayColor = disabledDayColor;
      } else if (utils.isSameDay(currentDate, dayToBuild)) {
        dayColor = todayColor;
        // decoration = BoxDecoration(
        //   border: Border.all(color: selectedDayBackground, width: 1),
        //   borderRadius: BorderRadius.circular(4),
        //   color: todayBackground,
        // );
      }

      // 显示的数字
      var dayText = '$day';
      if (day < 1) {
        dayText = '${daysInLastMonth + day}';
      } else if (day > daysInMonth) {
        dayText = '${day - daysInMonth}';
      }

      // 显示日期的子组件列表
      List<Widget> children = [
        Container(
          constraints: BoxConstraints(maxHeight: 26, maxWidth: 26),
          decoration: decoration,
          alignment: Alignment.center,
          child: Text(dayText, style: TextStyle(color: dayColor, fontSize: 14, fontWeight: FontWeight.w500)),
        ),
      ];

      List<Widget> markWidgets = _pickerConfig.markWidgetsBuilder?.call(context, dayToBuild);
      if (markWidgets != null && markWidgets.isNotEmpty) {
        children.add(Stack(
          alignment: Alignment.center,
          children: markWidgets,
        ),);
      }
      
      Widget dayWidget = Stack(
        alignment: AlignmentDirectional.center,
        children: children,
      );

      if (!isDisabled) {
        dayWidget = GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onSelectedDateChanged(dayToBuild),
          child: dayWidget,
        );
        dayItems.add(dayWidget);
      }
    }

    var rowCount = _pickerConfig.calendarType == CalendarType.month ? _maxDayPickerRowCount : 1;
    return GridView.custom(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      // gridDelegate: _dayPickerGridDelegate,
      // gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      //   crossAxisCount: DateTime.daysPerWeek,
      //   childAspectRatio: 1.2,
      // ),
      gridDelegate: _DayPickerGridDelegate(maxDayPickerRowCount: rowCount),
      childrenDelegate: SliverChildListDelegate(
        dayItems,
        addRepaintBoundaries: false,
      ),
    );
  }
}

class _DayPickerGridDelegate extends SliverGridDelegate {
  final int maxDayPickerRowCount;
  const _DayPickerGridDelegate({this.maxDayPickerRowCount});

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    const int columnCount = DateTime.daysPerWeek;
    final double tileWidth = constraints.crossAxisExtent / columnCount;
    final double tileHeight = math.min(_dayPickerRowHeight,
      constraints.viewportMainAxisExtent / maxDayPickerRowCount);
    return SliverGridRegularTileLayout(
      childCrossAxisExtent: tileWidth,
      childMainAxisExtent: tileHeight,
      crossAxisCount: columnCount,
      crossAxisStride: tileWidth,
      mainAxisStride: tileHeight,
      reverseCrossAxis: axisDirectionIsReversed(constraints.crossAxisDirection),
    );
  }

  @override
  bool shouldRelayout(_DayPickerGridDelegate oldDelegate) => false;
}

/// 日历组件的配置项
class CalendarPickerConfig extends ChangeNotifier {
  /// The initially selected [DateTime] that the picker should display.
  DateTime initialDate;

  /// The earliest allowable [DateTime] that the user can select.
  DateTime firstDate;

  /// The latest allowable [DateTime] that the user can select.
  DateTime lastDate;

  /// 主题色
  Color primaryColor;

  /// Called when the user selects a date in the picker.
  ValueChanged<DateTime> onSelectedDateChanged;

  /// Called when the user navigates to a new month/year in the picker.
  ValueChanged<DateTime> onDisplayedMonthChanged;

  CalendarType calendarType;

  /// Function to provide full control over which dates in the calendar can be selected.
  SelectableDayPredicate selectableDayPredicate;

  /// 内边距 默认左右各8px
  EdgeInsets padding;

  /// 在日期显示范围内附加其他标记widget，存在Stack组件内，需要由Position组件包裹
  /// 默认是居中显示
  MarkWidgetsBuilder markWidgetsBuilder;

  /// 标题组件
  HeaderWidgetBuilder headerWidgetBuilder;
  /// 是否显示日历标题组件
  bool showHeaderWidget;
/// 是否显示日历周模式和月模式切换开关
  bool showTypeChangeWidget;

  CalendarPickerConfig({
    this.initialDate,
    this.firstDate,
    this.lastDate,
    this.primaryColor,
    this.onSelectedDateChanged,
    this.onDisplayedMonthChanged,
    this.calendarType,
    this.selectableDayPredicate,
    this.padding,
    this.markWidgetsBuilder,
    this.headerWidgetBuilder,
    this.showHeaderWidget,
    this.showTypeChangeWidget,
  }) {
    this.showHeaderWidget ??= true;
    this.primaryColor ??= Color(0xFF0A53E0);
  }
}

