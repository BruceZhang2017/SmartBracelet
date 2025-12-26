package com.yourapp.health.female.ui

import android.content.Intent
import android.os.Bundle
import android.widget.Button
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.Observer
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.yourapp.health.female.R
import com.yourapp.health.female.data.FemaleCycleDataManager
import com.yourapp.health.female.data.model.DailyRecord
import com.yourapp.health.female.data.model.MonthSection
import com.yourapp.health.female.ui.adapter.MonthRecordAdapter

/**
 * 所有数据列表页面
 * 对应iOS端的AllDataViewController
 *
 * 功能:
 * 1. 按月分组展示所有记录
 * 2. 可折叠的月份分组
 * 3. 点击查看详情
 * 4. 跳转到周期设置
 */
class AllDataActivity : AppCompatActivity() {

    private lateinit var dataManager: FemaleCycleDataManager
    private lateinit var recyclerView: RecyclerView
    private lateinit var settingsButton: Button
    private lateinit var adapter: MonthRecordAdapter

    private val monthSections = mutableListOf<MonthSection>()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_all_data)

        dataManager = FemaleCycleDataManager.getInstance(this)

        setupUI()
        observeData()
        loadData()
    }

    private fun setupUI() {
        recyclerView = findViewById(R.id.recordRecyclerView)
        settingsButton = findViewById(R.id.settingsButton)

        recyclerView.layoutManager = LinearLayoutManager(this)

        adapter = MonthRecordAdapter(
            sections = monthSections,
            onRecordClicked = { record ->
                openDetailPage(record)
            },
            onSectionToggled = { position ->
                adapter.notifyItemChanged(position)
            }
        )

        recyclerView.adapter = adapter

        settingsButton.setOnClickListener {
            openSettings()
        }
    }

    private fun observeData() {
        dataManager.symptomDataChanged.observe(this, Observer {
            loadData()
        })
    }

    private fun loadData() {
        // 获取所有记录
        val allRecords = dataManager.getAllRecords()

        // 按月分组
        monthSections.clear()
        monthSections.addAll(groupRecordsByMonth(allRecords))

        adapter.notifyDataSetChanged()
    }

    /**
     * 按月分组记录
     */
    private fun groupRecordsByMonth(records: List<DailyRecord>): List<MonthSection> {
        val grouped = records.groupBy { record ->
            // 提取年月(yyyy-MM)
            record.date.substring(0, 7)
        }

        return grouped.map { (monthKey, recordsInMonth) ->
            MonthSection(
                monthYear = monthKey,
                records = recordsInMonth,
                isExpanded = true // 默认展开
            )
        }.sortedByDescending { it.monthYear }
    }

    /**
     * 打开详情页面
     */
    private fun openDetailPage(record: DailyRecord) {
        val intent = Intent(this, DataDetailActivity::class.java)
        intent.putExtra("date", record.date)
        startActivity(intent)
    }

    /**
     * 打开周期设置
     */
    private fun openSettings() {
        val intent = Intent(this, FemaleHealthActivity::class.java)
        intent.putExtra("hideLastPeriodOption", true)
        startActivity(intent)
    }
}
