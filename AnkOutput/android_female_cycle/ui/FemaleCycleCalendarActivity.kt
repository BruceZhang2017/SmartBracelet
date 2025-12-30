package com.yourapp.health.female.ui

import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.*
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.Observer
import androidx.recyclerview.widget.GridLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.google.android.material.chip.Chip
import com.google.android.material.chip.ChipGroup
import com.yourapp.health.female.data.FemaleCycleDataManager
import com.yourapp.health.female.data.model.DailySymptomData
import com.yourapp.health.female.data.model.MoodLevel
import com.yourapp.health.female.ui.adapter.CalendarAdapter
import com.yourapp.health.female.ui.view.FlowButtonGroup
import com.yourapp.health.female.ui.view.PainButtonGroup
import com.yourapp.health.female.utils.DateUtils
import java.text.SimpleDateFormat
import java.util.*

/**
 * 女性生理周期日历主页面
 * 对应iOS端的FemaleCycleCalendarViewController
 *
 * 核心功能:
 * 1. 月度日历展示(7x6网格)
 * 2. 经期/排卵期/预测期可视化
 * 3. 症状记录(流量、痛经、性行为、心情、身体症状)
 * 4. 数据实时保存和展示
 * 5. 动态UI更新(根据选中日期调整显示)
 */
class FemaleCycleCalendarActivity : AppCompatActivity() {

    // 数据管理器
    private lateinit var dataManager: FemaleCycleDataManager

    // UI组件 - Header
    private lateinit var monthYearText: TextView
    private lateinit var prevMonthButton: ImageButton
    private lateinit var nextMonthButton: ImageButton
    private lateinit var settingsButton: ImageButton
    private lateinit var allDataButton: ImageButton

    // UI组件 - 日历
    private lateinit var weekdayRow: LinearLayout
    private lateinit var calendarRecyclerView: RecyclerView
    private lateinit var calendarAdapter: CalendarAdapter

    // UI组件 - 图例
    private lateinit var periodLegendRow: View
    private lateinit var ovulationLegendRow: View

    // UI组件 - 症状记录区
    private lateinit var symptomRecordContainer: View
    private lateinit var selectedDateText: TextView
    private lateinit var cycleDayText: TextView
    private lateinit var futureTipText: TextView

    // UI组件 - 经期开始
    private lateinit var periodStartedSwitch: Switch

    // UI组件 - 流量和痛经
    private lateinit var flowRow: View
    private lateinit var flowButtonGroup: FlowButtonGroup
    private lateinit var painRow: View
    private lateinit var painButtonGroup: PainButtonGroup

    // UI组件 - 性行为
    private lateinit var sexualActivityRow: View
    private lateinit var sexualActivityChipGroup: ChipGroup
    private lateinit var protectedChip: Chip
    private lateinit var unprotectedChip: Chip

    // UI组件 - 心情
    private lateinit var moodRow: View
    private lateinit var moodChipGroup: ChipGroup

    // UI组件 - 身体症状
    private lateinit var bodySymptomsRow: View
    private lateinit var bodySymptomsText: TextView

    // 数据
    private var currentDisplayDate: Long = System.currentTimeMillis()
    private var selectedDate: Long = System.currentTimeMillis()
    private val monthYearFormatter = SimpleDateFormat("yyyy年MM月", Locale.getDefault())

    // 日历数据
    private var calendarDates = mutableListOf<Long?>()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_female_cycle_calendar)

        // 初始化数据管理器
        dataManager = FemaleCycleDataManager.getInstance(this)

        // 初始化UI
        setupUI()
        setupCalendar()
        setupSymptomRecording()
        observeData()

        // 加载数据
        loadCalendarData()
        loadSymptomData()
    }

    private fun setupUI() {
        // Header
        monthYearText = findViewById(R.id.monthYearText)
        prevMonthButton = findViewById(R.id.prevMonthButton)
        nextMonthButton = findViewById(R.id.nextMonthButton)
        settingsButton = findViewById(R.id.settingsButton)
        allDataButton = findViewById(R.id.allDataButton)

        // 星期行
        weekdayRow = findViewById(R.id.weekdayRow)

        // 日历
        calendarRecyclerView = findViewById(R.id.calendarRecyclerView)

        // 图例
        periodLegendRow = findViewById(R.id.periodLegendRow)
        ovulationLegendRow = findViewById(R.id.ovulationLegendRow)

        // 症状记录区
        symptomRecordContainer = findViewById(R.id.symptomRecordContainer)
        selectedDateText = findViewById(R.id.selectedDateText)
        cycleDayText = findViewById(R.id.cycleDayText)
        futureTipText = findViewById(R.id.futureTipText)

        // 经期开始
        periodStartedSwitch = findViewById(R.id.periodStartedSwitch)

        // 流量和痛经
        flowRow = findViewById(R.id.flowRow)
        flowButtonGroup = findViewById(R.id.flowButtonGroup)
        painRow = findViewById(R.id.painRow)
        painButtonGroup = findViewById(R.id.painButtonGroup)

        // 性行为
        sexualActivityRow = findViewById(R.id.sexualActivityRow)
        sexualActivityChipGroup = findViewById(R.id.sexualActivityChipGroup)
        protectedChip = findViewById(R.id.protectedChip)
        unprotectedChip = findViewById(R.id.unprotectedChip)

        // 心情
        moodRow = findViewById(R.id.moodRow)
        moodChipGroup = findViewById(R.id.moodChipGroup)

        // 身体症状
        bodySymptomsRow = findViewById(R.id.bodySymptomsRow)
        bodySymptomsText = findViewById(R.id.bodySymptomsText)

        // 设置点击监听
        prevMonthButton.setOnClickListener { changeMonth(-1) }
        nextMonthButton.setOnClickListener { changeMonth(1) }
        settingsButton.setOnClickListener { openSettings() }
        allDataButton.setOnClickListener { openAllData() }
        bodySymptomsRow.setOnClickListener { openBodySymptoms() }

        // 更新Header
        updateMonthYearText()
    }

    private fun setupCalendar() {
        // 配置RecyclerView
        val layoutManager = GridLayoutManager(this, 7)
        calendarRecyclerView.layoutManager = layoutManager

        // 创建Adapter
        calendarAdapter = CalendarAdapter(
            dates = calendarDates,
            selectedDate = selectedDate,
            dataManager = dataManager,
            onDateSelected = { date ->
                if (date != null) {
                    selectedDate = date
                    calendarAdapter.updateSelectedDate(selectedDate)
                    loadSymptomData()
                }
            }
        )

        calendarRecyclerView.adapter = calendarAdapter
    }

    private fun setupSymptomRecording() {
        // 经期开始开关
        periodStartedSwitch.setOnCheckedChangeListener { _, isChecked ->
            saveSymptom { it.isPeriodStarted = isChecked }

            // 如果开启经期,自动显示流量和痛经选项
            if (isChecked) {
                flowRow.visibility = View.VISIBLE
                painRow.visibility = View.VISIBLE
            }
        }

        // 流量按钮组
        flowButtonGroup.onLevelChanged = { level ->
            saveSymptom { it.flowLevel = level }
        }

        // 痛经按钮组
        painButtonGroup.onLevelChanged = { level ->
            saveSymptom { it.painLevel = level }
        }

        // 性行为Chip
        sexualActivityChipGroup.setOnCheckedStateChangeListener { group, checkedIds ->
            val sexualActivity = when {
                checkedIds.contains(R.id.protectedChip) -> 1
                checkedIds.contains(R.id.unprotectedChip) -> 2
                else -> 0
            }
            saveSymptom { it.sexualActivity = sexualActivity }
        }

        // 心情Chip
        moodChipGroup.setOnCheckedStateChangeListener { group, checkedIds ->
            val mood = when {
                checkedIds.contains(R.id.moodCalmChip) -> MoodLevel.CALM
                checkedIds.contains(R.id.moodHappyChip) -> MoodLevel.HAPPY
                checkedIds.contains(R.id.moodRelaxedChip) -> MoodLevel.RELAXED
                checkedIds.contains(R.id.moodEnergeticChip) -> MoodLevel.ENERGETIC
                checkedIds.contains(R.id.moodSensitiveChip) -> MoodLevel.SENSITIVE
                checkedIds.contains(R.id.moodAnxiousChip) -> MoodLevel.ANXIOUS
                checkedIds.contains(R.id.moodIrritableChip) -> MoodLevel.IRRITABLE
                checkedIds.contains(R.id.moodSadChip) -> MoodLevel.SAD
                else -> MoodLevel.NONE
            }
            saveSymptom { it.mood = mood }
        }
    }

    private fun observeData() {
        // 监听周期配置变化
        dataManager.cycleConfigChanged.observe(this, Observer { config ->
            loadCalendarData()
            calendarAdapter.notifyDataSetChanged()
        })

        // 监听症状数据变化
        dataManager.symptomDataChanged.observe(this, Observer { dateString ->
            // 如果变化的是当前显示月份的数据,刷新日历
            if (isInCurrentMonth(dateString)) {
                calendarAdapter.notifyDataSetChanged()
            }

            // 如果变化的是当前选中日期,刷新症状显示
            if (DateUtils.formatDate(selectedDate) == dateString) {
                loadSymptomData()
            }
        })
    }

    /**
     * 加载日历数据
     */
    private fun loadCalendarData() {
        calendarDates.clear()

        val firstDayOfMonth = DateUtils.getFirstDayOfMonth(currentDisplayDate)
        val daysInMonth = DateUtils.getDaysInMonth(currentDisplayDate)
        val firstDayOfWeek = DateUtils.getFirstDayOfWeek(currentDisplayDate)

        // 添加空白占位(前面的空格)
        for (i in 1 until firstDayOfWeek) {
            calendarDates.add(null)
        }

        // 添加实际日期
        for (day in 1..daysInMonth) {
            val date = DateUtils.addDays(firstDayOfMonth, day - 1)
            calendarDates.add(date)
        }

        // 填充到42个(6行)
        while (calendarDates.size < 42) {
            calendarDates.add(null)
        }

        calendarAdapter.updateDates(calendarDates)
    }

    /**
     * 加载症状数据
     */
    private fun loadSymptomData() {
        val dateString = DateUtils.formatDate(selectedDate)
        val symptomData = dataManager.getSymptomData(dateString)

        // 更新选中日期显示
        selectedDateText.text = SimpleDateFormat("MM月dd日", Locale.getDefault()).format(Date(selectedDate))

        // 更新周期天数显示
        val cycleDay = dataManager.getCycleDayNumber(selectedDate)
        if (cycleDay > 0) {
            cycleDayText.text = getString(R.string.female_cycle_day_n, cycleDay)
            cycleDayText.visibility = View.VISIBLE
        } else {
            cycleDayText.visibility = View.GONE
        }

        // 检查是否为未来日期
        val isFuture = DateUtils.isFutureDate(selectedDate)
        if (isFuture) {
            symptomRecordContainer.visibility = View.GONE
            futureTipText.visibility = View.VISIBLE
            return
        } else {
            symptomRecordContainer.visibility = View.VISIBLE
            futureTipText.visibility = View.GONE
        }

        // 检查是否在经期
        val isInPeriod = dataManager.isInPeriod(selectedDate)

        // 更新UI显示
        updateSymptomUI(symptomData, isInPeriod)
    }

    /**
     * 更新症状UI
     */
    private fun updateSymptomUI(symptomData: DailySymptomData?, isInPeriod: Boolean) {
        // 经期开始开关
        periodStartedSwitch.isChecked = symptomData?.isPeriodStarted ?: false

        // 流量和痛经(只在经期显示)
        if (isInPeriod || symptomData?.isPeriodStarted == true) {
            flowRow.visibility = View.VISIBLE
            painRow.visibility = View.VISIBLE
            flowButtonGroup.setLevel(symptomData?.flowLevel ?: 0)
            painButtonGroup.setLevel(symptomData?.painLevel ?: 0)
        } else {
            flowRow.visibility = View.GONE
            painRow.visibility = View.GONE
        }

        // 性行为
        sexualActivityChipGroup.clearCheck()
        when (symptomData?.sexualActivity) {
            1 -> protectedChip.isChecked = true
            2 -> unprotectedChip.isChecked = true
        }

        // 心情
        moodChipGroup.clearCheck()
        val moodChipId = when (symptomData?.mood) {
            1 -> R.id.moodCalmChip
            2 -> R.id.moodHappyChip
            3 -> R.id.moodRelaxedChip
            4 -> R.id.moodEnergeticChip
            5 -> R.id.moodSensitiveChip
            6 -> R.id.moodAnxiousChip
            7 -> R.id.moodIrritableChip
            8 -> R.id.moodSadChip
            else -> null
        }
        moodChipId?.let { findViewById<Chip>(it)?.isChecked = true }

        // 身体症状
        val symptoms = symptomData?.bodySymptoms ?: emptyList()
        if (symptoms.isEmpty()) {
            bodySymptomsText.text = getString(R.string.female_cycle_none)
            bodySymptomsText.setTextColor(getColor(R.color.female_cycle_text_hint))
        } else {
            bodySymptomsText.text = symptoms.joinToString(", ") {
                it.split("-").lastOrNull() ?: it
            }
            bodySymptomsText.setTextColor(getColor(R.color.female_cycle_text_primary))
        }
    }

    /**
     * 保存症状数据
     */
    private fun saveSymptom(modifier: (DailySymptomData) -> Unit) {
        val dateString = DateUtils.formatDate(selectedDate)
        var symptomData = dataManager.getSymptomData(dateString) ?: DailySymptomData(
            date = dateString,
            isPeriodStarted = false,
            flowLevel = 0,
            painLevel = 0,
            sexualActivity = 0,
            mood = MoodLevel.NONE,
            bodySymptoms = mutableListOf()
        )

        modifier(symptomData)
        dataManager.saveSymptomData(symptomData)

        // 刷新日历显示
        calendarAdapter.notifyDataSetChanged()
    }

    /**
     * 切换月份
     */
    private fun changeMonth(offset: Int) {
        currentDisplayDate = DateUtils.addMonths(currentDisplayDate, offset)
        updateMonthYearText()
        loadCalendarData()
    }

    /**
     * 更新月份年份文字
     */
    private fun updateMonthYearText() {
        monthYearText.text = monthYearFormatter.format(Date(currentDisplayDate))
    }

    /**
     * 检查日期是否在当前显示月份
     */
    private fun isInCurrentMonth(dateString: String): Boolean {
        val date = DateUtils.parseDate(dateString)
        val currentMonth = DateUtils.formatMonthYear(currentDisplayDate)
        val dateMonth = DateUtils.formatMonthYear(date)
        return currentMonth == dateMonth
    }

    /**
     * 打开周期设置
     */
    private fun openSettings() {
        val intent = Intent(this, FemaleHealthActivity::class.java)
        intent.putExtra("hideLastPeriodOption", true)
        startActivity(intent)
    }

    /**
     * 打开所有数据
     */
    private fun openAllData() {
        val intent = Intent(this, AllDataActivity::class.java)
        startActivity(intent)
    }

    /**
     * 打开身体症状选择
     */
    private fun openBodySymptoms() {
        val dateString = DateUtils.formatDate(selectedDate)
        val intent = Intent(this, BodySymptomsActivity::class.java)
        intent.putExtra("date", dateString)

        // 传递当前已选中的症状
        val currentSymptoms = dataManager.getSymptomData(dateString)?.bodySymptoms ?: emptyList()
        intent.putStringArrayListExtra("selectedSymptoms", ArrayList(currentSymptoms))

        startActivityForResult(intent, REQUEST_CODE_BODY_SYMPTOMS)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == REQUEST_CODE_BODY_SYMPTOMS && resultCode == RESULT_OK) {
            val selectedSymptoms = data?.getStringArrayListExtra("selectedSymptoms") ?: emptyList()
            saveSymptom { it.bodySymptoms = selectedSymptoms.toMutableList() }
        }
    }

    companion object {
        private const val REQUEST_CODE_BODY_SYMPTOMS = 1001
    }
}
