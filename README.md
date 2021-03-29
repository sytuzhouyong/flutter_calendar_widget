# flutter_calendar_widget

## 集成步骤

### 1. 在pubspec.yaml中引入三方库provider

``` yaml
provider: 3.1.0+1
```

### 2. 创建widget

``` flutter
Widget defaultCalendarWidget(DateTime initDate, DateTime start, DateTime end, {MarkWidgetsBuilder markWidgetBuild}) {
  return CalendarDatePicker(
    initialDate: initDate,
    firstDate: start,
    lastDate: end,
    primaryColor: Colors.blue,
    onSelectedDateChanged: (value) {
      debugPrint('选择日期：$value');

    },
    onDisplayedMonthChanged: (value) {
      debugPrint('选择月份变了：$value');
    },
    calendarType: CalendarType.week,
    showTypeChangeWidget: true,
    showHeaderWidget: false,
    markWidgetsBuilder: (context, displayDatetime) {
      return markWidgetBuild?.call(context, displayDatetime);
    },
  );
}
```
