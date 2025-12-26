package com.yourapp.health.female.ui.view

import android.content.Context
import android.graphics.*
import android.util.AttributeSet
import android.view.View
import com.yourapp.health.female.R

/**
 * 日历单元格自定义View
 * 对应iOS端的CalendarDayCell
 *
 * 核心功能:
 * 1. 自定义绘制连续背景(经期/排卵期/预测期)
 * 2. 背景智能连接(左圆右直/左直右圆/全直角/完整圆形)
 * 3. 特殊标记圆点(经期开始/结束/排卵日)
 * 4. 记录小圆点(底部)
 * 5. 日期文字
 * 6. 选中状态
 */
class CalendarDayView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0
) : View(context, attrs, defStyleAttr) {

    // 数据
    private var day: Int = 0
    private var isEmpty: Boolean = false
    private var isToday: Boolean = false
    private var isSelected: Boolean = false
    private var isInPeriod: Boolean = false
    private var isInOvulation: Boolean = false
    private var isInPredictedPeriod: Boolean = false
    private var hasLeftConnection: Boolean = false
    private var hasRightConnection: Boolean = false
    private var isPeriodFirstDay: Boolean = false
    private var isPeriodLastDay: Boolean = false
    private var isOvulationDay: Boolean = false
    private var hasRecord: Boolean = false

    // 颜色
    private val periodBgColor = context.getColor(R.color.female_cycle_period_bg)
    private val periodDotColor = context.getColor(R.color.female_cycle_period_dot)
    private val ovulationBgColor = context.getColor(R.color.female_cycle_ovulation_bg)
    private val ovulationDotColor = context.getColor(R.color.female_cycle_ovulation_dot)
    private val brandColor = context.getColor(R.color.female_cycle_brand)
    private val textPrimaryColor = context.getColor(R.color.female_cycle_text_primary)
    private val textSecondaryColor = context.getColor(R.color.female_cycle_text_secondary)
    private val textHintColor = context.getColor(R.color.female_cycle_text_hint)

    // 画笔
    private val bgPaint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val textPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        textAlign = Paint.Align.CENTER
        textSize = resources.getDimension(R.dimen.calendar_day_text_size)
    }
    private val dotPaint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val recordDotPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = brandColor
    }
    private val selectedCirclePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        strokeWidth = resources.getDimension(R.dimen.calendar_selected_stroke_width)
        color = brandColor
    }

    // 路径
    private val bgPath = Path()

    /**
     * 设置日期数据
     */
    fun setDate(
        day: Int,
        isToday: Boolean = false,
        isSelected: Boolean = false,
        isInPeriod: Boolean = false,
        isInOvulation: Boolean = false,
        isInPredictedPeriod: Boolean = false,
        hasLeftConnection: Boolean = false,
        hasRightConnection: Boolean = false,
        isPeriodFirstDay: Boolean = false,
        isPeriodLastDay: Boolean = false,
        isOvulationDay: Boolean = false,
        hasRecord: Boolean = false
    ) {
        this.day = day
        this.isEmpty = false
        this.isToday = isToday
        this.isSelected = isSelected
        this.isInPeriod = isInPeriod
        this.isInOvulation = isInOvulation
        this.isInPredictedPeriod = isInPredictedPeriod
        this.hasLeftConnection = hasLeftConnection
        this.hasRightConnection = hasRightConnection
        this.isPeriodFirstDay = isPeriodFirstDay
        this.isPeriodLastDay = isPeriodLastDay
        this.isOvulationDay = isOvulationDay
        this.hasRecord = hasRecord

        invalidate()
    }

    /**
     * 设置为空白单元格
     */
    fun setEmpty() {
        this.isEmpty = true
        invalidate()
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)

        if (isEmpty) return

        val centerX = width / 2f
        val centerY = height / 2f
        val radius = minOf(width, height) / 2f * 0.7f

        // 1. 绘制连续背景(经期/排卵期/预测期)
        drawBackground(canvas, centerX, centerY, radius)

        // 2. 绘制选中状态圆环
        if (isSelected) {
            canvas.drawCircle(centerX, centerY, radius, selectedCirclePaint)
        }

        // 3. 绘制特殊标记圆点
        drawSpecialDot(canvas, centerX, centerY)

        // 4. 绘制日期文字
        drawDayText(canvas, centerX, centerY)

        // 5. 绘制记录小圆点(底部)
        if (hasRecord) {
            val recordDotY = height - resources.getDimension(R.dimen.calendar_record_dot_margin)
            canvas.drawCircle(centerX, recordDotY, resources.getDimension(R.dimen.calendar_record_dot_radius), recordDotPaint)
        }
    }

    /**
     * 绘制连续背景
     */
    private fun drawBackground(canvas: Canvas, centerX: Float, centerY: Float, radius: Float) {
        // 确定背景颜色
        val bgColor = when {
            isInPeriod -> periodBgColor
            isInPredictedPeriod -> periodBgColor
            isInOvulation -> ovulationBgColor
            else -> return // 无背景
        }

        bgPaint.color = bgColor
        bgPath.reset()

        when {
            // 情况1: 无连接 -> 完整圆形
            !hasLeftConnection && !hasRightConnection -> {
                canvas.drawCircle(centerX, centerY, radius, bgPaint)
            }

            // 情况2: 左圆右直 -> 经期/排卵期开始
            !hasLeftConnection && hasRightConnection -> {
                // 绘制左半圆
                val leftArc = RectF(centerX - radius, centerY - radius, centerX + radius, centerY + radius)
                bgPath.addArc(leftArc, 90f, 180f)

                // 绘制右侧矩形
                val rightRect = RectF(centerX, centerY - radius, width.toFloat(), centerY + radius)
                bgPath.addRect(rightRect, Path.Direction.CW)

                canvas.drawPath(bgPath, bgPaint)
            }

            // 情况3: 左直右圆 -> 经期/排卵期结束
            hasLeftConnection && !hasRightConnection -> {
                // 绘制左侧矩形
                val leftRect = RectF(0f, centerY - radius, centerX, centerY + radius)
                bgPath.addRect(leftRect, Path.Direction.CW)

                // 绘制右半圆
                val rightArc = RectF(centerX - radius, centerY - radius, centerX + radius, centerY + radius)
                bgPath.addArc(rightArc, -90f, 180f)

                canvas.drawPath(bgPath, bgPaint)
            }

            // 情况4: 全直角 -> 中间天
            else -> {
                val fullRect = RectF(0f, centerY - radius, width.toFloat(), centerY + radius)
                canvas.drawRect(fullRect, bgPaint)
            }
        }
    }

    /**
     * 绘制特殊标记圆点
     */
    private fun drawSpecialDot(canvas: Canvas, centerX: Float, centerY: Float) {
        val dotRadius = resources.getDimension(R.dimen.calendar_special_dot_radius)

        when {
            // 经期第一天或最后一天 - 深粉色圆点
            isPeriodFirstDay || isPeriodLastDay -> {
                dotPaint.color = periodDotColor
                canvas.drawCircle(centerX, centerY, dotRadius, dotPaint)
            }

            // 排卵日 - 深紫色圆点
            isOvulationDay -> {
                dotPaint.color = ovulationDotColor
                canvas.drawCircle(centerX, centerY, dotRadius, dotPaint)
            }
        }
    }

    /**
     * 绘制日期文字
     */
    private fun drawDayText(canvas: Canvas, centerX: Float, centerY: Float) {
        // 确定文字颜色
        textPaint.color = when {
            isToday -> brandColor
            isSelected -> brandColor
            isInPeriod || isInOvulation || isInPredictedPeriod -> textPrimaryColor
            else -> textSecondaryColor
        }

        // 确定文字样式
        textPaint.isFakeBoldText = isToday || isSelected

        // 计算文字Y坐标(垂直居中)
        val fontMetrics = textPaint.fontMetrics
        val textY = centerY - (fontMetrics.ascent + fontMetrics.descent) / 2

        canvas.drawText(day.toString(), centerX, textY, textPaint)
    }
}
