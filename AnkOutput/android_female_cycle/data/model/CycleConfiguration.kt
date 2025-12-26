package com.yourapp.health.female.data.model

import com.google.gson.annotations.SerializedName

/**
 * 周期配置数据模型
 * 对应iOS端的CycleConfiguration结构体
 */
data class CycleConfiguration(
    @SerializedName("periodDays")
    var periodDays: Int = 7, // 经期天数

    @SerializedName("cycleLength")
    var cycleLength: Int = 28, // 周期长度

    @SerializedName("lastPeriodDate")
    var lastPeriodDate: Long = System.currentTimeMillis(), // 最后一次经期开始日期(时间戳)

    @SerializedName("isConfigured")
    var isConfigured: Boolean = false // 是否已由用户配置过
) {
    /**
     * 验证配置有效性
     */
    fun isValid(): Boolean {
        return periodDays in 3..10 &&
               cycleLength in 21..35 &&
               lastPeriodDate > 0
    }
}
