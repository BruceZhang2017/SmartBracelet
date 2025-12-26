package com.yourapp.health.female.utils

import java.text.SimpleDateFormat
import java.util.*

/**
 * 日期工具类
 */
object DateUtils {

    private val dateFormatter = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
    private val monthYearFormatter = SimpleDateFormat("yyyy-MM", Locale.getDefault())
    private val displayFormatter = SimpleDateFormat("MM/dd", Locale.getDefault())
    private val detailFormatter = SimpleDateFormat("yyyy/MM/dd HH:mm", Locale.getDefault())

    /**
     * 格式化日期为字符串(yyyy-MM-dd)
     */
    fun formatDate(date: Long): String {
        return dateFormatter.format(Date(date))
    }

    /**
     * 解析日期字符串
     */
    fun parseDate(dateString: String): Long {
        return try {
            dateFormatter.parse(dateString)?.time ?: System.currentTimeMillis()
        } catch (e: Exception) {
            System.currentTimeMillis()
        }
    }

    /**
     * 格式化为月份年份(yyyy-MM)
     */
    fun formatMonthYear(date: Long): String {
        return monthYearFormatter.format(Date(date))
    }

    /**
     * 格式化为显示格式(MM/dd)
     */
    fun formatDisplay(date: Long): String {
        return displayFormatter.format(Date(date))
    }

    /**
     * 格式化为详细时间(yyyy/MM/dd HH:mm)
     */
    fun formatDetail(date: Long): String {
        return detailFormatter.format(Date(date))
    }

    /**
     * 判断两个日期是否为同一天
     */
    fun isSameDay(date1: Long, date2: Long): Boolean {
        val cal1 = Calendar.getInstance().apply { timeInMillis = date1 }
        val cal2 = Calendar.getInstance().apply { timeInMillis = date2 }

        return cal1.get(Calendar.YEAR) == cal2.get(Calendar.YEAR) &&
               cal1.get(Calendar.DAY_OF_YEAR) == cal2.get(Calendar.DAY_OF_YEAR)
    }

    /**
     * 判断日期是否为今天
     */
    fun isToday(date: Long): Boolean {
        return isSameDay(date, System.currentTimeMillis())
    }

    /**
     * 判断日期是否在未来
     */
    fun isFutureDate(date: Long): Boolean {
        val today = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        return date > today.timeInMillis
    }

    /**
     * 获取月份第一天
     */
    fun getFirstDayOfMonth(date: Long): Long {
        val calendar = Calendar.getInstance()
        calendar.timeInMillis = date
        calendar.set(Calendar.DAY_OF_MONTH, 1)
        calendar.set(Calendar.HOUR_OF_DAY, 0)
        calendar.set(Calendar.MINUTE, 0)
        calendar.set(Calendar.SECOND, 0)
        calendar.set(Calendar.MILLISECOND, 0)
        return calendar.timeInMillis
    }

    /**
     * 获取月份天数
     */
    fun getDaysInMonth(date: Long): Int {
        val calendar = Calendar.getInstance()
        calendar.timeInMillis = date
        return calendar.getActualMaximum(Calendar.DAY_OF_MONTH)
    }

    /**
     * 获取月份第一天是星期几(1=周日, 7=周六)
     */
    fun getFirstDayOfWeek(date: Long): Int {
        val calendar = Calendar.getInstance()
        calendar.timeInMillis = getFirstDayOfMonth(date)
        return calendar.get(Calendar.DAY_OF_WEEK)
    }

    /**
     * 添加天数
     */
    fun addDays(date: Long, days: Int): Long {
        val calendar = Calendar.getInstance()
        calendar.timeInMillis = date
        calendar.add(Calendar.DAY_OF_YEAR, days)
        return calendar.timeInMillis
    }

    /**
     * 添加月份
     */
    fun addMonths(date: Long, months: Int): Long {
        val calendar = Calendar.getInstance()
        calendar.timeInMillis = date
        calendar.add(Calendar.MONTH, months)
        return calendar.timeInMillis
    }
}
