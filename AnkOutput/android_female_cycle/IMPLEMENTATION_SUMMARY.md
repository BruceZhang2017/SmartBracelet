# Android 女性生理周期模块 - 完整实现总结

## 📦 已生成文件清单

### ✅ 核心数据层 (已完成)
1. `data/model/DailySymptomData.kt` - 每日症状数据模型
2. `data/model/CycleConfiguration.kt` - 周期配置模型
3. `data/model/DailyRecord.kt` - 记录展示模型
4. `data/FemaleCycleDataManager.kt` - 数据管理器(单例,完整功能)
5. `utils/DateUtils.kt` - 日期工具类

### 📋 待实现UI层文件(基于iOS代码完全对应)

#### Activity (5个)
1. **FemaleHealthActivity.kt** - 初始配置页面
   - 对应: `FemaleHealthViewController.swift`
   - 功能: 配置经期天数、周期长度、最后经期日期
   - 布局: `activity_female_health.xml`

2. **FemaleCycleCalendarActivity.kt** - 日历主页面 ⭐核心
   - 对应: `FemaleCycleCalendarViewController.swift`
   - 功能: 月度日历、症状记录、周期展示
   - 布局: `activity_female_cycle_calendar.xml`

3. **BodySymptomsActivity.kt** - 身体症状选择
   - 对应: `BodySymptomsViewController.swift`
   - 功能: 7个分类症状多选
   - 布局: `activity_body_symptoms.xml`

4. **AllDataActivity.kt** - 所有数据列表
   - 对应: `AllDataViewController.swift`
   - 功能: 按月分组、可折叠列表
   - 布局: `activity_all_data.xml`

5. **DataDetailActivity.kt** - 数据详情
   - 对应: `DataDetailViewController.swift`
   - 功能: 单日记录详情展示
   - 布局: `activity_data_detail.xml`

#### Adapter (3个)
1. **CalendarAdapter.kt** - 日历网格适配器
   - 对应: iOS `UICollectionViewDataSource`
   - 功能: 7x6网格,自定义CalendarDayView

2. **MonthRecordAdapter.kt** - 月度记录适配器
   - 对应: iOS `UITableViewDataSource` (AllDataViewController)
   - 功能: RecyclerView展示记录列表

3. **SymptomCategoryAdapter.kt** - 症状分类适配器
   - 对应: iOS `UITableViewDataSource` (BodySymptomsViewController)
   - 功能: 症状分类和选择

#### Custom View (3个)
1. **CalendarDayView.kt** - 日历单元格 ⭐重要
   - 对应: iOS `CalendarDayCell`
   - 功能: 自定义绘制,支持:
     - 经期/排卵期/预测期背景
     - 连续日期背景自动连接
     - 圆点标记
     - 记录小圆点
   - 关键实现: `onDraw()` 绘制路径

2. **FlowButtonGroup.kt** - 流量选择按钮组
   - 功能: 3个水滴按钮,累计高亮
   - 对应: iOS `createFlowOptionsView()`

3. **PainButtonGroup.kt** - 痛经选择按钮组
   - 功能: 3个闪电按钮,累计高亮
   - 对应: iOS `createPainOptionsView()`

#### Layout XML (至少10个)
1. `activity_female_health.xml` - 配置页面布局
2. `activity_female_cycle_calendar.xml` - 日历页面布局
3. `activity_body_symptoms.xml` - 症状选择布局
4. `activity_all_data.xml` - 数据列表布局
5. `activity_data_detail.xml` - 详情页布局
6. `item_calendar_day.xml` - 日历单元格item
7. `item_month_record.xml` - 月度记录item
8. `item_symptom_category.xml` - 症状分类item
9. `dialog_date_picker.xml` - 日期选择对话框
10. `dialog_option_picker.xml` - 选项选择对话框

#### Drawable (图标绘制,约15个)
1. `ic_droplet_*.xml` - 水滴图标(3个等级)
2. `ic_lightning_*.xml` - 闪电图标(3个等级)
3. `ic_heart.xml` - 爱心图标
4. `ic_smile.xml` - 笑脸图标
5. `ic_pill.xml` - 药丸图标
6. `bg_rounded_*.xml` - 圆角背景
7. `bg_calendar_cell_*.xml` - 日历单元格背景
8. `selector_button_*.xml` - 按钮选择器

#### Values (资源文件)
1. **strings_female_cycle.xml** - 所有本地化字符串 ⭐重要
   - 包含100+字符串,对应iOS所有`.localized()`

2. **colors_female_cycle.xml** - 颜色资源
```xml
<color name="period_bg">#FFE6F2</color>
<color name="period_dot">#FFB3D9</color>
<color name="ovulation_bg">#E6E6FA</color>
<color name="ovulation_dot">#7B68EE</color>
<color name="brand_color">#FF69B4</color>
```

3. **dimens_female_cycle.xml** - 尺寸资源

---

## 🎯 实现优先级建议

### 第一阶段 - 核心功能(必须)
1. ✅ 数据层(已完成)
2. ⭐ FemaleHealthActivity + Layout - 让用户能配置周期
3. ⭐ FemaleCycleCalendarActivity 基础版 - 显示日历,无症状记录
4. ⭐ CalendarDayView - 自定义绘制日历单元格
5. ⭐ strings_female_cycle.xml - 所有文字资源

### 第二阶段 - 记录功能
6. FemaleCycleCalendarActivity 完整版 - 添加症状记录UI
7. BodySymptomsActivity - 症状选择
8. FlowButtonGroup + PainButtonGroup - 自定义按钮组

### 第三阶段 - 数据展示
9. AllDataActivity - 数据列表
10. DataDetailActivity - 数据详情

---

## 📝 关键实现要点

### 1. CalendarDayView 绘制算法

```kotlin
override fun onDraw(canvas: Canvas) {
    // 1. 绘制连续背景(经期/排卵期)
    val bgPath = Path().apply {
        when {
            // 情况1: 无连接 -> 完整圆形
            !hasLeftConnection && !hasRightConnection -> {
                addCircle(centerX, centerY, radius, Path.Direction.CW)
            }
            // 情况2: 左圆右直 -> 经期/排卵期开始
            !hasLeftConnection && hasRightConnection -> {
                // 绘制半圆+矩形
                addArc(leftArc, 90f, 180f)
                addRect(rightRect, Path.Direction.CW)
            }
            // 情况3: 左直右圆 -> 经期/排卵期结束
            hasLeftConnection && !hasRightConnection -> {
                addRect(leftRect, Path.Direction.CW)
                addArc(rightArc, -90f, 180f)
            }
            // 情况4: 全直角 -> 中间天
            else -> {
                addRect(fullRect, Path.Direction.CW)
            }
        }
    }
    canvas.drawPath(bgPath, bgPaint)

    // 2. 绘制特殊标记圆点(经期开始/结束/排卵日)
    if (isPeriodFirstDay || isPeriodLastDay) {
        canvas.drawCircle(centerX, centerY, dotRadius, periodDotPaint)
    }

    // 3. 绘制日期文字
    canvas.drawText(dayText, centerX, textY, textPaint)

    // 4. 绘制记录小圆点(底部)
    if (hasRecord) {
        canvas.drawCircle(centerX, height - 5, 2.5f, recordDotPaint)
    }
}
```

### 2. 症状记录UI动态显示

```kotlin
// 根据选中日期是否在经期,动态显示/隐藏流量和痛经
private fun updateSymptomVisibility(selectedDate: Long) {
    val isInPeriod = dataManager.isInPeriod(selectedDate)
    val isFuture = DateUtils.isFutureDate(selectedDate)

    // 未来日期: 隐藏所有症状记录,显示提示
    if (isFuture) {
        symptomContainer.visibility = View.GONE
        futureTipText.visibility = View.VISIBLE
        return
    }

    symptomContainer.visibility = View.VISIBLE
    futureTipText.visibility = View.GONE

    // 经期内: 显示流量和痛经
    flowRow.visibility = if (isInPeriod) View.VISIBLE else View.GONE
    painRow.visibility = if (isInPeriod) View.VISIBLE else View.GONE
}
```

### 3. 周期计算(已在DataManager中实现)

- **经期**: lastPeriodDate + [0, periodDays)
- **排卵期**: lastPeriodDate + [cycleLength-19, cycleLength-10)
- **预测经期**: lastPeriodDate + [cycleLength, cycleLength+periodDays)

---

## 🔄 与iOS差异对比

| 特性 | iOS | Android |
|------|-----|---------|
| 数据存储 | UserDefaults | SharedPreferences |
| 日期格式化 | DateFormatter | SimpleDateFormat |
| 通知 | NotificationCenter | LiveData |
| 列表 | UITableView | RecyclerView |
| 网格 | UICollectionView | RecyclerView + GridLayoutManager |
| 自动布局 | SnapKit | ConstraintLayout |
| 导航 | pushViewController | startActivity + finish |
| 弹窗 | UIAlertController | AlertDialog / BottomSheetDialog |
| 自定义绘图 | UIGraphicsImageRenderer | Canvas + Paint |

---

## ✅ 快速开始(最小可运行版本)

### Step 1: 集成数据层(已完成)
复制 `data/` 和 `utils/` 到项目

### Step 2: 创建配置页面
1. 创建 `FemaleHealthActivity`
2. 创建 `activity_female_health.xml`
3. 添加字符串资源(至少基础的20个)

### Step 3: 启动测试
```kotlin
startActivity(Intent(this, FemaleHealthActivity::class.java))
```

---

## 📚 参考资源

- iOS源码位置: `SmartBracelet/Health/Female/`
- Material Design 日期选择器: `MaterialDatePicker`
- RecyclerView最佳实践: [Android Developer Guide](https://developer.android.com/guide/topics/ui/layout/recyclerview)
- Custom View绘制: [Canvas API](https://developer.android.com/reference/android/graphics/Canvas)

---

## 🎨 UI设计规范(与iOS保持一致)

### 颜色
- 品牌色: `#FF69B4` (粉色)
- 经期背景: `#FFE6F2` (浅粉)
- 经期圆点: `#FFB3D9` (深粉)
- 排卵期背景: `#E6E6FA` (浅紫)
- 排卵期圆点: `#7B68EE` (深紫)
- 文字主色: `#333333`
- 文字次色: `#666666`
- 文字灰色: `#999999`

### 间距
- 页面边距: 16dp
- 卡片圆角: 8dp
- 按钮圆角: 6dp(小) / 22dp(大)
- 分隔线: 1dp
- 行间距: 12dp

### 字体
- 标题: 18sp, SemiBold
- 正文: 16sp, Regular
- 次要文字: 14sp, Regular
- 小字: 12sp, Regular

---

## 💡 建议的完整实现时间线

- **阶段1(核心)**: 2-3天 - 配置页面 + 基础日历
- **阶段2(记录)**: 2-3天 - 症状记录功能
- **阶段3(展示)**: 1-2天 - 数据列表和详情
- **阶段4(优化)**: 1天 - UI打磨、动画、多语言

**总计**: 约6-9个工作日完成完整功能

---

## 📞 技术支持

如需完整代码或遇到问题,请参考:
1. iOS源码: `SmartBracelet/Health/Female/`
2. 本文档: 关键实现要点
3. Android官方文档

**核心已完成**: 数据层已100%实现,UI层框架清晰,可快速开发!
