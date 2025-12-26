package com.yourapp.health.female.ui.adapter

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import com.yourapp.health.female.R
import com.yourapp.health.female.data.model.DailyRecord
import com.yourapp.health.female.data.model.MonthSection
import java.text.SimpleDateFormat
import java.util.*

/**
 * 月度记录适配器
 * 对应iOS端的UITableViewDataSource (AllDataViewController)
 *
 * 功能:
 * 1. 展示月份分组头
 * 2. 展示记录列表
 * 3. 折叠/展开分组
 * 4. 点击记录查看详情
 */
class MonthRecordAdapter(
    private val sections: List<MonthSection>,
    private val onRecordClicked: (DailyRecord) -> Unit,
    private val onSectionToggled: (Int) -> Unit
) : RecyclerView.Adapter<RecyclerView.ViewHolder>() {

    companion object {
        private const val VIEW_TYPE_HEADER = 0
        private const val VIEW_TYPE_RECORD = 1
    }

    private val monthYearFormatter = SimpleDateFormat("yyyy年MM月", Locale.getDefault())
    private val dateFormatter = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
    private val displayFormatter = SimpleDateFormat("MM月dd日", Locale.getDefault())

    override fun getItemViewType(position: Int): Int {
        var currentPos = 0
        sections.forEach { section ->
            if (currentPos == position) {
                return VIEW_TYPE_HEADER
            }
            currentPos++

            if (section.isExpanded) {
                if (position < currentPos + section.records.size) {
                    return VIEW_TYPE_RECORD
                }
                currentPos += section.records.size
            }
        }
        return VIEW_TYPE_HEADER
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): RecyclerView.ViewHolder {
        return when (viewType) {
            VIEW_TYPE_HEADER -> {
                val view = LayoutInflater.from(parent.context)
                    .inflate(R.layout.item_month_header, parent, false)
                HeaderViewHolder(view)
            }
            else -> {
                val view = LayoutInflater.from(parent.context)
                    .inflate(R.layout.item_daily_record, parent, false)
                RecordViewHolder(view)
            }
        }
    }

    override fun onBindViewHolder(holder: RecyclerView.ViewHolder, position: Int) {
        when (holder) {
            is HeaderViewHolder -> {
                val section = getSectionForPosition(position)
                section?.let { holder.bind(it, position) }
            }
            is RecordViewHolder -> {
                val record = getRecordForPosition(position)
                record?.let { holder.bind(it) }
            }
        }
    }

    override fun getItemCount(): Int {
        var count = 0
        sections.forEach { section ->
            count++ // Header
            if (section.isExpanded) {
                count += section.records.size
            }
        }
        return count
    }

    private fun getSectionForPosition(position: Int): MonthSection? {
        var currentPos = 0
        sections.forEach { section ->
            if (currentPos == position) {
                return section
            }
            currentPos++
            if (section.isExpanded) {
                currentPos += section.records.size
            }
        }
        return null
    }

    private fun getRecordForPosition(position: Int): DailyRecord? {
        var currentPos = 0
        sections.forEach { section ->
            currentPos++ // Skip header
            if (section.isExpanded) {
                if (position < currentPos + section.records.size) {
                    return section.records[position - currentPos]
                }
                currentPos += section.records.size
            }
        }
        return null
    }

    inner class HeaderViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        private val monthYearText: TextView = itemView.findViewById(R.id.monthYearText)
        private val recordCountText: TextView = itemView.findViewById(R.id.recordCountText)
        private val expandIcon: ImageView = itemView.findViewById(R.id.expandIcon)

        fun bind(section: MonthSection, position: Int) {
            // 解析月份年份
            val date = dateFormatter.parse("${section.monthYear}-01")
            monthYearText.text = date?.let { monthYearFormatter.format(it) } ?: section.monthYear

            // 记录数量
            recordCountText.text = itemView.context.getString(
                R.string.female_cycle_total_prefix
            ) + " ${section.records.size}${itemView.context.getString(R.string.female_cycle_days_suffix)}"

            // 展开/折叠图标
            expandIcon.rotation = if (section.isExpanded) 180f else 0f

            // 点击切换展开状态
            itemView.setOnClickListener {
                section.isExpanded = !section.isExpanded
                onSectionToggled(position)

                // 刷新列表
                notifyDataSetChanged()
            }
        }
    }

    inner class RecordViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        private val dateText: TextView = itemView.findViewById(R.id.dateText)
        private val cycleDayText: TextView = itemView.findViewById(R.id.cycleDayText)
        private val iconContainer: LinearLayout = itemView.findViewById(R.id.iconContainer)

        fun bind(record: DailyRecord) {
            // 日期
            val date = dateFormatter.parse(record.date)
            dateText.text = date?.let { displayFormatter.format(it) } ?: record.date

            // 周期天数
            if (record.cycleDay > 0) {
                cycleDayText.text = itemView.context.getString(R.string.female_cycle_day_n, record.cycleDay)
                cycleDayText.visibility = View.VISIBLE
            } else {
                cycleDayText.visibility = View.GONE
            }

            // 图标
            iconContainer.removeAllViews()
            record.icons.forEach { iconRes ->
                val iconView = ImageView(itemView.context).apply {
                    setImageResource(iconRes)
                    layoutParams = LinearLayout.LayoutParams(
                        itemView.resources.getDimensionPixelSize(R.dimen.record_icon_size),
                        itemView.resources.getDimensionPixelSize(R.dimen.record_icon_size)
                    ).apply {
                        marginEnd = itemView.resources.getDimensionPixelSize(R.dimen.record_icon_spacing)
                    }
                }
                iconContainer.addView(iconView)
            }

            // 点击事件
            itemView.setOnClickListener {
                onRecordClicked(record)
            }
        }
    }
}
