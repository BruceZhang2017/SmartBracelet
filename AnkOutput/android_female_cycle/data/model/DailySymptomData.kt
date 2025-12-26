package com.yourapp.health.female.data.model

import com.google.gson.annotations.SerializedName

/**
 * 每日症状数据模型
 * 对应iOS端的DailySymptomData结构体
 */
data class DailySymptomData(
    @SerializedName("date")
    val date: String, // 格式: yyyy-MM-dd

    @SerializedName("isPeriodStarted")
    var isPeriodStarted: Boolean = false,

    @SerializedName("flowLevel")
    var flowLevel: Int = 0, // 0=未选择, 1=少, 2=中, 3=多

    @SerializedName("painLevel")
    var painLevel: Int = 0, // 0=未选择, 1=轻微, 2=中等, 3=严重

    @SerializedName("sexualActivity")
    var sexualActivity: Int = 0, // 0=无, 1=保护性行为, 2=无保护性行为

    @SerializedName("mood")
    var mood: Int = 0, // 0=未选择, 1=平静, 2=开心, 3=放松, 4=活力满满, 5=敏感, 6=焦躁, 7=易怒, 8=悲伤

    @SerializedName("bodySymptoms")
    var bodySymptoms: MutableList<String> = mutableListOf() // 身体症状列表（格式：分类-症状）
) {
    /**
     * 检查是否有任何记录数据
     */
    fun hasAnyData(): Boolean {
        return isPeriodStarted ||
               flowLevel > 0 ||
               painLevel > 0 ||
               sexualActivity > 0 ||
               mood > 0 ||
               bodySymptoms.isNotEmpty()
    }
}
