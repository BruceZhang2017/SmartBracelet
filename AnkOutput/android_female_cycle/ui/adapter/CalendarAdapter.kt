package com.yourapp.health.female.ui.adapter

import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.recyclerview.widget.RecyclerView
import com.yourapp.health.female.R
import com.yourapp.health.female.data.FemaleCycleDataManager
import com.yourapp.health.female.ui.view.CalendarDayView
import com.yourapp.health.female.utils.DateUtils

/**
 * 日历网格适配器
 * 对应iOS端的UICollectionViewDataSource
 *
 * 功能:
 * 1. 展示7x6网格(42个单元格)
 * 2. 自定义CalendarDayView绘制
 * 3. 经期/排卵期背景连接效果
 * 4. 记录小圆点标记
 */
class CalendarAdapter(
    private var dates: List<Long?>,
    private var selectedDate: Long,
    private val dataManager: FemaleCycleDataManager,
    private val onDateSelected: (Long?) -> Unit
) : RecyclerView.Adapter<CalendarAdapter.DayViewHolder>() {

    // 周期数据缓存
    private var periodDates = setOf<String>()
    private var ovulationDates = setOf<String>()
    private var predictedPeriodDates = setOf<String>()

    init {
        updateCycleData()
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): DayViewHolder {
        val dayView = CalendarDayView(parent.context)
        val layoutParams = ViewGroup.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            parent.resources.getDimensionPixelSize(R.dimen.calendar_cell_height)
        )
        dayView.layoutParams = layoutParams
        return DayViewHolder(dayView)
    }

    override fun onBindViewHolder(holder: DayViewHolder, position: Int) {
        val date = dates[position]
        val dayView = holder.dayView

        if (date == null) {
            // 空白单元格
            dayView.setEmpty()
            return
        }

        // 基本数据
        val dateString = DateUtils.formatDate(date)
        val calendar = java.util.Calendar.getInstance()
        calendar.timeInMillis = date
        val day = calendar.get(java.util.Calendar.DAY_OF_MONTH)

        // 状态判断
        val isToday = DateUtils.isToday(date)
        val isSelected = DateUtils.isSameDay(date, selectedDate)
        val isInPeriod = periodDates.contains(dateString)
        val isInOvulation = ovulationDates.contains(dateString)
        val isInPredictedPeriod = predictedPeriodDates.contains(dateString)
        val hasRecord = dataManager.hasSymptomRecord(dateString)

        // 连接状态判断(用于背景绘制)
        val row = position / 7
        val col = position % 7

        // 检查左侧是否有连接
        val hasLeftConnection = when {
            col == 0 -> false // 第一列左侧无连接
            else -> {
                val leftDate = dates[position - 1]
                if (leftDate == null) {
                    false
                } else {
                    val leftDateString = DateUtils.formatDate(leftDate)
                    when {
                        isInPeriod -> periodDates.contains(leftDateString)
                        isInOvulation -> ovulationDates.contains(leftDateString)
                        isInPredictedPeriod -> predictedPeriodDates.contains(leftDateString)
                        else -> false
                    }
                }
            }
        }

        // 检查右侧是否有连接
        val hasRightConnection = when {
            col == 6 -> false // 最后一列右侧无连接
            else -> {
                val rightDate = dates[position + 1]
                if (rightDate == null) {
                    false
                } else {
                    val rightDateString = DateUtils.formatDate(rightDate)
                    when {
                        isInPeriod -> periodDates.contains(rightDateString)
                        isInOvulation -> ovulationDates.contains(rightDateString)
                        isInPredictedPeriod -> predictedPeriodDates.contains(rightDateString)
                        else -> false
                    }
                }
            }
        }

        // 特殊标记圆点(经期第一天/最后一天/排卵日)
        val isPeriodFirstDay = isInPeriod && !hasLeftConnection && hasRightConnection
        val isPeriodLastDay = isInPeriod && hasLeftConnection && !hasRightConnection
        val isOvulationDay = isOvulationDay(dateString)

        // 配置CalendarDayView
        dayView.setDate(
            day = day,
            isToday = isToday,
            isSelected = isSelected,
            isInPeriod = isInPeriod,
            isInOvulation = isInOvulation,
            isInPredictedPeriod = isInPredictedPeriod,
            hasLeftConnection = hasLeftConnection,
            hasRightConnection = hasRightConnection,
            isPeriodFirstDay = isPeriodFirstDay,
            isPeriodLastDay = isPeriodLastDay,
            isOvulationDay = isOvulationDay,
            hasRecord = hasRecord
        )

        // 点击事件
        dayView.setOnClickListener {
            onDateSelected(date)
        }
    }

    override fun getItemCount(): Int = dates.size

    /**
     * 更新日期列表
     */
    fun updateDates(newDates: List<Long?>) {
        this.dates = newDates
        updateCycleData()
        notifyDataSetChanged()
    }

    /**
     * 更新选中日期
     */
    fun updateSelectedDate(newSelectedDate: Long) {
        this.selectedDate = newSelectedDate
        notifyDataSetChanged()
    }

    /**
     * 更新周期数据缓存
     */
    private fun updateCycleData() {
        // 获取当前显示月份的中间日期
        val centerDate = dates.firstOrNull { it != null } ?: System.currentTimeMillis()

        periodDates = dataManager.getPeriodDates(centerDate)
        ovulationDates = dataManager.getOvulationDates(centerDate)
        predictedPeriodDates = dataManager.getPredictedPeriodDates(centerDate)
    }

    /**
     * 判断是否为排卵日(排卵期中间日)
     */
    private fun isOvulationDay(dateString: String): Boolean {
        if (!ovulationDates.contains(dateString)) return false

        val config = dataManager.getCycleConfiguration()
        val ovulationDayOffset = config.cycleLength - 14
        val lastPeriodDate = config.lastPeriodDate

        val calendar = java.util.Calendar.getInstance()
        calendar.timeInMillis = lastPeriodDate
        calendar.add(java.util.Calendar.DAY_OF_YEAR, ovulationDayOffset)

        val ovulationDayString = DateUtils.formatDate(calendar.timeInMillis)
        return dateString == ovulationDayString
    }

    class DayViewHolder(val dayView: CalendarDayView) : RecyclerView.ViewHolder(dayView)
}
