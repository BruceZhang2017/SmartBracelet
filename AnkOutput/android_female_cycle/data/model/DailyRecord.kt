package com.yourapp.health.female.data.model

/**
 * 日常记录模型(用于列表展示)
 * 对应iOS端的DailyRecord结构体
 */
data class DailyRecord(
    val date: Long, // 日期时间戳
    val cycleDay: Int, // 周期第几天（0表示非经期）
    val isPeriod: Boolean, // 是否是经期
    val hasFlow: Boolean, // 是否有流量记录
    val hasPain: Boolean, // 是否有痛经记录
    val hasTemp: Boolean, // 是否有体温记录
    val hasSexual: Boolean, // 是否有性行为记录
    val hasMood: Boolean, // 是否有心情记录
    val hasBodySymptoms: Boolean, // 是否有身体症状记录
    val recordTime: Long // 记录时间
)

/**
 * 月份分组模型
 * 对应iOS端的MonthSection结构体
 */
data class MonthSection(
    val title: String, // 如："2025年12月"
    var records: List<DailyRecord>,
    var isExpanded: Boolean = true
)
