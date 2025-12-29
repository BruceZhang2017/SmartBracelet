package com.yourapp.health.female.data

import android.content.Context
import android.content.SharedPreferences
import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import com.yourapp.health.female.data.model.CycleConfiguration
import com.yourapp.health.female.data.model.DailySymptomData
import java.text.SimpleDateFormat
import java.util.*
import kotlin.collections.HashMap

/**
 * 女性生理周期数据管理器(单例)
 * 对应iOS端的FemaleCycleDataManager类
 *
 * 功能:
 * - 管理周期配置(经期天数、周期长度、最后经期日期)
 * - 管理每日症状数据
 * - 本地数据持久化
 * - 数据变更通知机制
 * - 周期计算(经期、排卵期、预测经期)
 */
class FemaleCycleDataManager private constructor(private val context: Context) {

    companion object {
        @Volatile
        private var INSTANCE: FemaleCycleDataManager? = null

        fun getInstance(context: Context): FemaleCycleDataManager {
            return INSTANCE ?: synchronized(this) {
                INSTANCE ?: FemaleCycleDataManager(context.applicationContext).also { INSTANCE = it }
            }
        }

        // 存储键
        private const val PREFS_NAME = "FemaleCycle_Data"
        private const val KEY_CYCLE_CONFIG = "FemaleCycle_Configuration"
        private const val KEY_DAILY_DATA = "FemaleCycle_DailyData"
    }

    // SharedPreferences
    private val prefs: SharedPreferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    private val gson = Gson()

    // 日期格式化器
    private val dateFormatter = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())

    // 周期配置
    private var cycleConfig: CycleConfiguration = CycleConfiguration()

    // 每日症状数据字典，key为日期字符串（yyyy-MM-dd）
    private val dailyDataDict: HashMap<String, DailySymptomData> = HashMap()

    // LiveData for data change notifications
    private val _cycleConfigChanged = MutableLiveData<CycleConfiguration>()
    val cycleConfigChanged: LiveData<CycleConfiguration> = _cycleConfigChanged

    private val _dailyDataChanged = MutableLiveData<Pair<String, DailySymptomData>>()
    val dailyDataChanged: LiveData<Pair<String, DailySymptomData>> = _dailyDataChanged

    // Alias for symptomDataChanged to match iOS naming
    private val _symptomDataChanged = MutableLiveData<String>()
    val symptomDataChanged: LiveData<String> = _symptomDataChanged

    init {
        loadAllData()
    }

    // ==================== 数据加载 ====================

    /**
     * 从本地存储加载所有数据
     */
    private fun loadAllData() {
        // 加载周期配置
        val configJson = prefs.getString(KEY_CYCLE_CONFIG, null)
        cycleConfig = if (configJson != null) {
            try {
                gson.fromJson(configJson, CycleConfiguration::class.java)
            } catch (e: Exception) {
                CycleConfiguration()
            }
        } else {
            // 兼容旧数据(如果有)
            CycleConfiguration(
                periodDays = prefs.getInt("FemaleHealth_PeriodDays", 7),
                cycleLength = prefs.getInt("FemaleHealth_CycleLength", 28),
                lastPeriodDate = prefs.getLong("FemaleHealth_LastPeriodDate", System.currentTimeMillis())
            )
        }

        // 加载每日数据
        val dailyDataJson = prefs.getString(KEY_DAILY_DATA, null)
        dailyDataDict.clear()
        if (dailyDataJson != null) {
            try {
                val type = object : TypeToken<HashMap<String, DailySymptomData>>() {}.type
                val loadedData: HashMap<String, DailySymptomData> = gson.fromJson(dailyDataJson, type)
                dailyDataDict.putAll(loadedData)
            } catch (e: Exception) {
                // 解析失败,使用空数据
            }
        }
    }

    /**
     * 保存所有数据到本地存储
     */
    private fun saveAllData() {
        prefs.edit().apply {
            putString(KEY_CYCLE_CONFIG, gson.toJson(cycleConfig))
            putString(KEY_DAILY_DATA, gson.toJson(dailyDataDict))
        }.apply()
    }

    // ==================== 周期配置管理 ====================

    /**
     * 更新周期配置
     */
    fun updateCycleConfiguration(
        periodDays: Int? = null,
        cycleLength: Int? = null,
        lastPeriodDate: Long? = null
    ) {
        var hasChanges = false

        periodDays?.let {
            if (it != cycleConfig.periodDays && it in 3..10) {
                cycleConfig.periodDays = it
                hasChanges = true
            }
        }

        cycleLength?.let {
            if (it != cycleConfig.cycleLength && it in 21..35) {
                cycleConfig.cycleLength = it
                hasChanges = true
            }
        }

        lastPeriodDate?.let {
            // 比较日期是否为同一天
            val calendar = Calendar.getInstance()
            calendar.timeInMillis = it
            calendar.set(Calendar.HOUR_OF_DAY, 0)
            calendar.set(Calendar.MINUTE, 0)
            calendar.set(Calendar.SECOND, 0)
            calendar.set(Calendar.MILLISECOND, 0)
            val newDate = calendar.timeInMillis

            calendar.timeInMillis = cycleConfig.lastPeriodDate
            calendar.set(Calendar.HOUR_OF_DAY, 0)
            calendar.set(Calendar.MINUTE, 0)
            calendar.set(Calendar.SECOND, 0)
            calendar.set(Calendar.MILLISECOND, 0)
            val oldDate = calendar.timeInMillis

            if (newDate != oldDate) {
                cycleConfig.lastPeriodDate = newDate
                hasChanges = true
            }
        }

        if (hasChanges) {
            cycleConfig.isConfigured = true
            saveAllData()
            _cycleConfigChanged.postValue(cycleConfig)
        }
    }

    /**
     * 获取周期配置
     */
    fun getCycleConfiguration(): CycleConfiguration {
        return cycleConfig.copy()
    }

    /**
     * 检查是否已配置
     */
    fun isConfigured(): Boolean {
        return cycleConfig.isConfigured && cycleConfig.isValid()
    }

    // ==================== 每日数据管理 ====================

    /**
     * 获取指定日期的症状数据
     */
    fun getDailyData(date: Long): DailySymptomData {
        val dateString = dateFormatter.format(Date(date))
        return dailyDataDict[dateString] ?: DailySymptomData(dateString)
    }

    /**
     * 获取指定日期字符串的症状数据
     */
    fun getDailyData(dateString: String): DailySymptomData {
        return dailyDataDict[dateString] ?: DailySymptomData(dateString)
    }

    /**
     * 更新指定日期的症状数据
     */
    fun updateDailyData(date: Long, data: DailySymptomData) {
        val dateString = dateFormatter.format(Date(date))
        dailyDataDict[dateString] = data
        saveAllData()
        _dailyDataChanged.postValue(Pair(dateString, data))
        _symptomDataChanged.postValue(dateString)
    }

    /**
     * 更新指定日期的经期开始状态
     */
    fun updatePeriodStartStatus(date: Long, isStarted: Boolean) {
        val data = getDailyData(date).copy(isPeriodStarted = isStarted)
        updateDailyData(date, data)
    }

    /**
     * 更新指定日期的流量等级
     */
    fun updateFlowLevel(date: Long, level: Int) {
        val data = getDailyData(date).copy(flowLevel = level)
        updateDailyData(date, data)
    }

    /**
     * 更新指定日期的痛经等级
     */
    fun updatePainLevel(date: Long, level: Int) {
        val data = getDailyData(date).copy(painLevel = level)
        updateDailyData(date, data)
    }

    /**
     * 更新指定日期的性行为
     */
    fun updateSexualActivity(date: Long, activity: Int) {
        val data = getDailyData(date).copy(sexualActivity = activity)
        updateDailyData(date, data)
    }

    /**
     * 更新指定日期的心情
     */
    fun updateMood(date: Long, mood: Int) {
        val data = getDailyData(date).copy(mood = mood)
        updateDailyData(date, data)
    }

    /**
     * 更新指定日期的身体症状
     */
    fun updateBodySymptoms(date: Long, symptoms: List<String>) {
        val data = getDailyData(date)
        data.bodySymptoms.clear()
        data.bodySymptoms.addAll(symptoms)
        updateDailyData(date, data)
    }

    /**
     * 检查指定日期是否有记录数据
     */
    fun hasRecordData(date: Long): Boolean {
        val dateString = dateFormatter.format(Date(date))
        return dailyDataDict.containsKey(dateString)
    }

    /**
     * 获取所有有记录的日期
     */
    fun getAllRecordedDates(): List<String> {
        return dailyDataDict.keys.toList()
    }

    /**
     * 获取所有有记录的日期（按时间倒序排列）
     */
    fun getAllRecordedDatesSorted(): List<String> {
        return dailyDataDict.keys.sortedDescending()
    }

    /**
     * 按月份分组获取所有记录（倒序）
     */
    fun getRecordsByMonth(): List<Pair<String, List<String>>> {
        val sortedDates = getAllRecordedDatesSorted()
        val result = mutableListOf<Pair<String, List<String>>>()
        var currentMonth = ""
        var currentDates = mutableListOf<String>()

        for (dateString in sortedDates) {
            // 提取月份："yyyy-MM"
            val monthString = dateString.substring(0, 7) // "2025-12-09" -> "2025-12"

            if (monthString != currentMonth) {
                if (currentDates.isNotEmpty()) {
                    result.add(Pair(currentMonth, currentDates.toList()))
                }
                currentMonth = monthString
                currentDates = mutableListOf(dateString)
            } else {
                currentDates.add(dateString)
            }
        }

        // 添加最后一组
        if (currentDates.isNotEmpty()) {
            result.add(Pair(currentMonth, currentDates.toList()))
        }

        return result
    }

    /**
     * 获取所有记录（转换为DailyRecord列表）
     * 用于AllDataActivity显示
     */
    fun getAllRecords(): List<com.yourapp.health.female.data.model.DailyRecord> {
        val records = mutableListOf<com.yourapp.health.female.data.model.DailyRecord>()

        for ((dateString, symptomData) in dailyDataDict) {
            try {
                val date = dateFormatter.parse(dateString)
                val timestamp = date?.time ?: continue

                // 计算周期天数
                val cycleDay = calculateCycleDay(timestamp)

                // 创建DailyRecord
                val record = com.yourapp.health.female.data.model.DailyRecord(
                    date = dateString,
                    cycleDay = cycleDay,
                    isPeriod = cycleDay > 0,
                    hasFlow = symptomData.flowLevel > 0,
                    hasPain = symptomData.painLevel > 0,
                    hasTemp = false, // 暂未支持体温
                    hasSexual = symptomData.sexualActivity > 0,
                    hasMood = symptomData.mood > 0,
                    hasBodySymptoms = symptomData.bodySymptoms.isNotEmpty(),
                    recordTime = timestamp
                )
                records.add(record)
            } catch (e: Exception) {
                // 跳过无效日期
            }
        }

        // 按日期倒序排列
        return records.sortedByDescending { it.date }
    }

    /**
     * 检查指定日期是否有症状记录
     */
    fun hasSymptomRecord(dateString: String): Boolean {
        val symptomData = dailyDataDict[dateString] ?: return false

        // 检查是否有任何症状数据
        return symptomData.flowLevel > 0 ||
               symptomData.painLevel > 0 ||
               symptomData.sexualActivity > 0 ||
               symptomData.mood > 0 ||
               symptomData.bodySymptoms.isNotEmpty() ||
               symptomData.isPeriodStarted
    }

    // ==================== 别名方法（兼容iOS命名） ====================

    /**
     * 获取症状数据（别名方法，匹配iOS命名）
     */
    fun getSymptomData(dateString: String): DailySymptomData {
        return getDailyData(dateString)
    }

    /**
     * 保存症状数据（别名方法，匹配iOS命名）
     */
    fun saveSymptomData(data: DailySymptomData) {
        try {
            val date = dateFormatter.parse(data.date)
            if (date != null) {
                updateDailyData(date.time, data)
            }
        } catch (e: Exception) {
            // 解析失败，直接保存
            dailyDataDict[data.date] = data
            saveAllData()
            _dailyDataChanged.postValue(Pair(data.date, data))
            _symptomDataChanged.postValue(data.date)
        }
    }

    /**
     * 获取周期天数（别名方法，匹配iOS命名）
     */
    fun getCycleDayNumber(date: Long): Int {
        return calculateCycleDay(date)
    }

    // ==================== 周期计算 ====================

    /**
     * 计算指定日期在周期中的天数（1表示经期第一天）
     * 返回0表示不在经期内
     */
    fun calculateCycleDay(date: Long): Int {
        val calendar = Calendar.getInstance()
        val lastPeriodCalendar = Calendar.getInstance()
        lastPeriodCalendar.timeInMillis = cycleConfig.lastPeriodDate

        // 计算与上次经期开始的天数差
        val days = ((date - cycleConfig.lastPeriodDate) / (24 * 60 * 60 * 1000)).toInt()

        // 如果是负数，说明在上次经期之前
        if (days < 0) {
            return 0
        }

        // 检查是否在当前周期的经期内
        if (days < cycleConfig.periodDays) {
            return days + 1 // 经期第1-7天
        }

        // 检查是否在下一个周期的经期内
        val nextPeriodStart = cycleConfig.lastPeriodDate + (cycleConfig.cycleLength * 24 * 60 * 60 * 1000L)
        val daysFromNext = ((date - nextPeriodStart) / (24 * 60 * 60 * 1000)).toInt()

        if (daysFromNext >= 0 && daysFromNext < cycleConfig.periodDays) {
            return daysFromNext + 1
        }

        return 0 // 不在经期内
    }

    /**
     * 判断指定日期是否在经期内
     */
    fun isInPeriod(date: Long): Boolean {
        return calculateCycleDay(date) > 0
    }

    /**
     * 计算经期日期集合
     */
    fun getPeriodDates(centerDate: Long): Set<String> {
        val dates = mutableSetOf<String>()
        val calendar = Calendar.getInstance()

        // 计算当前经期
        for (i in 0 until cycleConfig.periodDays) {
            calendar.timeInMillis = cycleConfig.lastPeriodDate
            calendar.add(Calendar.DAY_OF_YEAR, i)
            dates.add(dateFormatter.format(calendar.time))
        }

        // 计算下一个经期(如果在显示范围内)
        calendar.timeInMillis = cycleConfig.lastPeriodDate
        calendar.add(Calendar.DAY_OF_YEAR, cycleConfig.cycleLength)
        val nextPeriodStart = calendar.timeInMillis

        for (i in 0 until cycleConfig.periodDays) {
            calendar.timeInMillis = nextPeriodStart
            calendar.add(Calendar.DAY_OF_YEAR, i)
            dates.add(dateFormatter.format(calendar.time))
        }

        return dates
    }

    /**
     * 计算排卵期日期集合
     * 排卵日 = 下次月经第一天 - 14天
     * 排卵期 = 排卵日前5天到排卵日后4天，共10天
     */
    fun getOvulationDates(centerDate: Long): Set<String> {
        val dates = mutableSetOf<String>()
        val calendar = Calendar.getInstance()

        val ovulationDayOffset = cycleConfig.cycleLength - 14
        val ovulationStart = ovulationDayOffset - 5
        val ovulationEnd = ovulationDayOffset + 4

        // 获取经期日期(避免重复)
        val periodDates = getPeriodDates(centerDate)

        for (i in ovulationStart..ovulationEnd) {
            calendar.timeInMillis = cycleConfig.lastPeriodDate
            calendar.add(Calendar.DAY_OF_YEAR, i)
            val dateString = dateFormatter.format(calendar.time)

            // 只有不在经期的日期才加入排卵期集合
            if (!periodDates.contains(dateString)) {
                dates.add(dateString)
            }
        }

        return dates
    }

    /**
     * 计算预测经期日期集合
     */
    fun getPredictedPeriodDates(centerDate: Long): Set<String> {
        val dates = mutableSetOf<String>()
        val calendar = Calendar.getInstance()

        // 计算下一次经期
        calendar.timeInMillis = cycleConfig.lastPeriodDate
        calendar.add(Calendar.DAY_OF_YEAR, cycleConfig.cycleLength)
        val nextPeriodStart = calendar.timeInMillis

        for (i in 0 until cycleConfig.periodDays) {
            calendar.timeInMillis = nextPeriodStart
            calendar.add(Calendar.DAY_OF_YEAR, i)
            dates.add(dateFormatter.format(calendar.time))
        }

        return dates
    }

    // ==================== 数据清理 ====================

    /**
     * 清除指定日期之前的旧数据（保留最近N天）
     */
    fun cleanOldData(keepDays: Int = 365) {
        val calendar = Calendar.getInstance()
        calendar.add(Calendar.DAY_OF_YEAR, -keepDays)
        val cutoffDateString = dateFormatter.format(calendar.time)

        var removedCount = 0
        val iterator = dailyDataDict.iterator()
        while (iterator.hasNext()) {
            val entry = iterator.next()
            if (entry.key < cutoffDateString) {
                iterator.remove()
                removedCount++
            }
        }

        if (removedCount > 0) {
            saveAllData()
        }
    }

    /**
     * 清除所有数据（谨慎使用）
     */
    fun clearAllData() {
        dailyDataDict.clear()
        cycleConfig = CycleConfiguration()
        saveAllData()

        _cycleConfigChanged.postValue(cycleConfig)
        _dailyDataChanged.postValue(Pair("", DailySymptomData("")))
    }
}
