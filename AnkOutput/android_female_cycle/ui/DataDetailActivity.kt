package com.yourapp.health.female.ui

import android.os.Bundle
import android.view.View
import android.widget.LinearLayout
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import com.yourapp.health.female.R
import com.yourapp.health.female.data.FemaleCycleDataManager
import com.yourapp.health.female.data.model.DailySymptomData
import com.yourapp.health.female.utils.DateUtils
import java.text.SimpleDateFormat
import java.util.*

/**
 * 数据详情页面
 * 对应iOS端的DataDetailViewController
 *
 * 功能:
 * 1. 展示单日完整记录
 * 2. 显示所有症状详情
 * 3. 显示记录时间
 */
class DataDetailActivity : AppCompatActivity() {

    private lateinit var dataManager: FemaleCycleDataManager

    // UI组件
    private lateinit var dateText: TextView
    private lateinit var cycleDayText: TextView
    private lateinit var recordTimeText: TextView

    // 经期相关
    private lateinit var periodStartedRow: View
    private lateinit var periodStartedValueText: TextView
    private lateinit var flowRow: View
    private lateinit var flowValueText: TextView
    private lateinit var painRow: View
    private lateinit var painValueText: TextView

    // 性行为
    private lateinit var sexualActivityRow: View
    private lateinit var sexualActivityValueText: TextView

    // 心情
    private lateinit var moodRow: View
    private lateinit var moodValueText: TextView

    // 身体症状
    private lateinit var bodySymptomsRow: View
    private lateinit var bodySymptomsValueText: TextView

    private var dateString: String = ""

    private val dateFormatter = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
    private val displayFormatter = SimpleDateFormat("yyyy年MM月dd日", Locale.getDefault())
    private val timeFormatter = SimpleDateFormat("yyyy/MM/dd HH:mm", Locale.getDefault())

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_data_detail)

        dateString = intent.getStringExtra("date") ?: DateUtils.formatDate(System.currentTimeMillis())
        dataManager = FemaleCycleDataManager.getInstance(this)

        setupUI()
        loadData()
    }

    private fun setupUI() {
        dateText = findViewById(R.id.dateText)
        cycleDayText = findViewById(R.id.cycleDayText)
        recordTimeText = findViewById(R.id.recordTimeText)

        periodStartedRow = findViewById(R.id.periodStartedRow)
        periodStartedValueText = findViewById(R.id.periodStartedValueText)
        flowRow = findViewById(R.id.flowRow)
        flowValueText = findViewById(R.id.flowValueText)
        painRow = findViewById(R.id.painRow)
        painValueText = findViewById(R.id.painValueText)

        sexualActivityRow = findViewById(R.id.sexualActivityRow)
        sexualActivityValueText = findViewById(R.id.sexualActivityValueText)

        moodRow = findViewById(R.id.moodRow)
        moodValueText = findViewById(R.id.moodValueText)

        bodySymptomsRow = findViewById(R.id.bodySymptomsRow)
        bodySymptomsValueText = findViewById(R.id.bodySymptomsValueText)
    }

    private fun loadData() {
        val symptomData = dataManager.getSymptomData(dateString)

        // 日期
        val date = dateFormatter.parse(dateString)
        dateText.text = date?.let { displayFormatter.format(it) } ?: dateString

        // 周期天数
        val cycleDay = dataManager.getCycleDayNumber(DateUtils.parseDate(dateString))
        if (cycleDay > 0) {
            cycleDayText.text = getString(R.string.female_cycle_day_n, cycleDay)
            cycleDayText.visibility = View.VISIBLE
        } else {
            cycleDayText.visibility = View.GONE
        }

        // 记录时间(使用当前时间模拟)
        recordTimeText.text = getString(R.string.female_cycle_record_time) + ": " +
                              timeFormatter.format(Date())

        if (symptomData != null) {
            displaySymptomData(symptomData)
        } else {
            displayNoData()
        }
    }

    private fun displaySymptomData(data: DailySymptomData) {
        // 经期开始
        periodStartedValueText.text = if (data.isPeriodStarted) {
            getString(R.string.female_cycle_period_started)
        } else {
            getString(R.string.female_cycle_none)
        }

        // 流量
        if (data.flowLevel > 0) {
            flowRow.visibility = View.VISIBLE
            flowValueText.text = when (data.flowLevel) {
                1 -> getString(R.string.female_cycle_flow_light)
                2 -> getString(R.string.female_cycle_flow_medium)
                3 -> getString(R.string.female_cycle_flow_heavy)
                else -> getString(R.string.female_cycle_none)
            }
        } else {
            flowRow.visibility = View.GONE
        }

        // 痛经
        if (data.painLevel > 0) {
            painRow.visibility = View.VISIBLE
            painValueText.text = when (data.painLevel) {
                1 -> getString(R.string.female_cycle_pain_mild)
                2 -> getString(R.string.female_cycle_pain_moderate)
                3 -> getString(R.string.female_cycle_pain_severe)
                else -> getString(R.string.female_cycle_none)
            }
        } else {
            painRow.visibility = View.GONE
        }

        // 性行为
        if (data.sexualActivity > 0) {
            sexualActivityRow.visibility = View.VISIBLE
            sexualActivityValueText.text = when (data.sexualActivity) {
                1 -> getString(R.string.female_cycle_protected_sex)
                2 -> getString(R.string.female_cycle_unprotected_sex)
                else -> getString(R.string.female_cycle_none)
            }
        } else {
            sexualActivityRow.visibility = View.GONE
        }

        // 心情
        if (data.mood > 0) {
            moodRow.visibility = View.VISIBLE
            moodValueText.text = when (data.mood) {
                1 -> getString(R.string.female_cycle_mood_calm)
                2 -> getString(R.string.female_cycle_mood_happy)
                3 -> getString(R.string.female_cycle_mood_relaxed)
                4 -> getString(R.string.female_cycle_mood_energetic)
                5 -> getString(R.string.female_cycle_mood_sensitive)
                6 -> getString(R.string.female_cycle_mood_anxious)
                7 -> getString(R.string.female_cycle_mood_irritable)
                8 -> getString(R.string.female_cycle_mood_sad)
                else -> getString(R.string.female_cycle_none)
            }
        } else {
            moodRow.visibility = View.GONE
        }

        // 身体症状
        if (data.bodySymptoms.isNotEmpty()) {
            bodySymptomsRow.visibility = View.VISIBLE
            bodySymptomsValueText.text = data.bodySymptoms.joinToString("\n") {
                it.split("-").lastOrNull() ?: it
            }
        } else {
            bodySymptomsRow.visibility = View.GONE
        }
    }

    private fun displayNoData() {
        periodStartedValueText.text = getString(R.string.female_cycle_none)
        flowRow.visibility = View.GONE
        painRow.visibility = View.GONE
        sexualActivityRow.visibility = View.GONE
        moodRow.visibility = View.GONE
        bodySymptomsRow.visibility = View.GONE
    }
}
