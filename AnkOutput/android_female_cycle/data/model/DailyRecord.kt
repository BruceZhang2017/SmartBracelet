package com.yourapp.health.female.data.model

/**
 * 日常记录模型(用于列表展示)
 * 对应iOS端的DailyRecord结构体
 */
data class DailyRecord(
    val date: String, // 日期字符串（yyyy-MM-dd格式）
    val cycleDay: Int, // 周期第几天（0表示非经期）
    val isPeriod: Boolean, // 是否是经期
    val hasFlow: Boolean, // 是否有流量记录
    val hasPain: Boolean, // 是否有痛经记录
    val hasTemp: Boolean, // 是否有体温记录
    val hasSexual: Boolean, // 是否有性行为记录
    val hasMood: Boolean, // 是否有心情记录
    val hasBodySymptoms: Boolean, // 是否有身体症状记录
    val recordTime: Long // 记录时间
) {
    /**
     * 获取记录图标列表
     * 根据记录的症状类型动态生成图标资源ID列表
     */
    val icons: List<Int>
        get() {
            val iconList = mutableListOf<Int>()
            // 注意：需要在实际项目中定义这些图标资源
            // 这里使用占位符，实际使用时需要替换为真实的资源ID
            if (hasFlow) iconList.add(android.R.drawable.ic_menu_info_details) // 替换为流量图标
            if (hasPain) iconList.add(android.R.drawable.ic_menu_info_details) // 替换为疼痛图标
            if (hasTemp) iconList.add(android.R.drawable.ic_menu_info_details) // 替换为体温图标
            if (hasSexual) iconList.add(android.R.drawable.ic_menu_info_details) // 替换为性行为图标
            if (hasMood) iconList.add(android.R.drawable.ic_menu_info_details) // 替换为心情图标
            if (hasBodySymptoms) iconList.add(android.R.drawable.ic_menu_info_details) // 替换为身体症状图标
            return iconList
        }
}

/**
 * 月份分组模型
 * 对应iOS端的MonthSection结构体
 */
data class MonthSection(
    val monthYear: String, // 月份年份（yyyy-MM格式），如："2025-12"
    var records: List<DailyRecord>,
    var isExpanded: Boolean = true
)
