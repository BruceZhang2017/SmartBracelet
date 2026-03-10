# Android 女性生理周期模块实现

## 📋 功能概述

完全对应iOS端女性生理周期功能的Android Kotlin实现,包含:

### 核心功能
1. **周期配置** - 经期天数(3-10天)、周期长度(21-35天)、最后经期日期
2. **日历视图** - 月度日历展示,标记经期/排卵期/预测经期
3. **症状记录** - 流量、痛经、性行为、心情、身体症状
4. **数据管理** - 本地持久化、数据查询、通知机制
5. **数据展示** - 按月分组、详情查看

### 技术栈
- **语言**: Kotlin
- **UI**: Material Design 3 + ConstraintLayout
- **数据**: SharedPreferences + Gson
- **架构**: MVVM + LiveData/Flow

## 📁 文件结构

```
com.yourapp.health.female/
├── data/
│   ├── model/
│   │   ├── DailySymptomData.kt          # 每日症状数据模型
│   │   ├── CycleConfiguration.kt         # 周期配置模型
│   │   └── DailyRecord.kt                # 记录展示模型
│   └── FemaleCycleDataManager.kt         # 数据管理器(单例)
│
├── ui/
│   ├── FemaleHealthActivity.kt           # 初始配置页面
│   ├── FemaleCycleCalendarActivity.kt    # 日历主页面
│   ├── BodySymptomsActivity.kt           # 身体症状选择
│   ├── AllDataActivity.kt                # 所有数据列表
│   ├── DataDetailActivity.kt             # 数据详情
│   │
│   ├── adapter/
│   │   ├── CalendarAdapter.kt            # 日历适配器
│   │   ├── MonthRecordAdapter.kt         # 月度记录适配器
│   │   └── SymptomCategoryAdapter.kt     # 症状分类适配器
│   │
│   └── view/
│       ├── CalendarDayView.kt            # 日历单元格自定义View
│       ├── FlowButtonGroup.kt            # 流量选择按钮组
│       └── PainButtonGroup.kt            # 痛经选择按钮组
│
└── utils/
    ├── DateUtils.kt                      # 日期工具类
    └── NotificationHelper.kt             # 通知辅助类
```

## 🎨 UI设计还原

### 1. 配置页面 (FemaleHealthActivity)
- 3个选择项卡片布局
- 下拉选择器(经期天数、周期长度)
- 日期选择器(最后经期日期)
- 底部确认按钮

### 2. 日历页面 (FemaleCycleCalendarActivity)
- 月份切换导航
- 7x6网格日历
- 颜色标记:
  - 经期: `#FFE6F2` (粉色背景) + `#FFB3D9` (深粉圆点)
  - 排卵期: `#E6E6FA` (紫色背景) + `#7B68EE` (深紫圆点)
  - 预测经期: 粉色虚线边框
- 连续日期的背景自动连接(行首行尾圆角处理)
- 症状记录区域(根据选中日期动态显示/隐藏)

### 3. 症状选择 (BodySymptomsActivity)
- 7个分类,每个分类4-5个症状
- 2列网格布局
- 选中状态: `#FFE6F2` 背景 + `#FF69B4` 边框和文字
- 未选中: `#F8F8F8` 背景 + `#E0E0E0` 边框

### 4. 数据列表 (AllDataActivity)
- 按月分组,可折叠
- 每条记录显示日期、状态、图标
- 图标类型: 💧流量、⚡痛经、💗性行为、😊心情、💊症状

## 🔧 关键实现

### 数据持久化
```kotlin
// 使用 SharedPreferences + Gson
private val prefs = context.getSharedPreferences("female_cycle", MODE_PRIVATE)

// 保存配置
val json = Gson().toJson(cycleConfig)
prefs.edit().putString("cycle_config", json).apply()

// 保存每日数据
val dailyDataJson = Gson().toJson(dailyDataMap)
prefs.edit().putString("daily_data", dailyDataJson).apply()
```

### 周期计算算法
```kotlin
// 排卵期计算: 排卵日 = 下次月经第一天 - 14天
val ovulationDay = cycleLength - 14
val ovulationStart = ovulationDay - 5  // 排卵期开始
val ovulationEnd = ovulationDay + 4     // 排卵期结束(共10天)
```

### 日历绘制
```kotlin
// 自定义View绘制连续背景
override fun onDraw(canvas: Canvas) {
    // 绘制背景路径(根据左右连接状态调整圆角)
    val path = Path().apply {
        when {
            !hasLeftConnection && !hasRightConnection -> {
                // 完整圆形
                addCircle(centerX, centerY, radius, Path.Direction.CW)
            }
            !hasLeftConnection && hasRightConnection -> {
                // 左圆右直
                addRoundRect(rect, leftRadius, rightRadius, Path.Direction.CW)
            }
            hasLeftConnection && !hasRightConnection -> {
                // 左直右圆
                addRoundRect(rect, leftRadius, rightRadius, Path.Direction.CW)
            }
            else -> {
                // 全直角
                addRect(rect, Path.Direction.CW)
            }
        }
    }
    canvas.drawPath(path, bgPaint)
}
```

### LiveData数据监听
```kotlin
// ViewModel中发布数据变更
private val _dataChanged = MutableLiveData<String>()
val dataChanged: LiveData<String> = _dataChanged

// Activity中监听
viewModel.dataChanged.observe(this) { dateString ->
    // 刷新UI
    calendarAdapter.notifyDataSetChanged()
}
```

## 📱 使用说明

### 1. 集成到项目

1. 复制 `com.yourapp.health.female` 包到项目
2. 添加依赖:
```gradle
dependencies {
    implementation 'com.google.android.material:material:1.10.0'
    implementation 'com.google.code.gson:gson:2.10.1'
    implementation 'androidx.lifecycle:lifecycle-viewmodel-ktx:2.6.2'
    implementation 'androidx.lifecycle:lifecycle-livedata-ktx:2.6.2'
}
```

3. 在 `AndroidManifest.xml` 注册Activity:
```xml
<activity android:name=".health.female.ui.FemaleHealthActivity" />
<activity android:name=".health.female.ui.FemaleCycleCalendarActivity" />
<activity android:name=".health.female.ui.BodySymptomsActivity" />
<activity android:name=".health.female.ui.AllDataActivity" />
<activity android:name=".health.female.ui.DataDetailActivity" />
```

### 2. 启动配置页面
```kotlin
startActivity(Intent(this, FemaleHealthActivity::class.java))
```

### 3. 直接进入日历页面
```kotlin
// 确保已配置过
if (FemaleCycleDataManager.getInstance(this).isConfigured()) {
    startActivity(Intent(this, FemaleCycleCalendarActivity::class.java))
} else {
    startActivity(Intent(this, FemaleHealthActivity::class.java))
}
```

## 🎯 与iOS端差异

| 功能 | iOS | Android |
|-----|-----|---------|
| 数据存储 | UserDefaults | SharedPreferences |
| 日期格式化 | DateFormatter | SimpleDateFormat |
| 通知机制 | NotificationCenter | LiveData/Flow |
| 布局 | SnapKit | ConstraintLayout |
| 导航 | UINavigationController | startActivity + finish |
| 自定义绘图 | UIGraphicsImageRenderer | Canvas + Paint |

## 📝 多语言支持

需在 `strings.xml` 中添加以下本地化字符串(见 `res/values/strings_female_cycle.xml`)

## 🔐 隐私说明

- 所有数据存储在本地 SharedPreferences
- 不涉及网络传输
- 符合 GDPR 和用户隐私要求

## 📄 License

Copyright © 2015-2018 bruce Innovations Technology Limited
