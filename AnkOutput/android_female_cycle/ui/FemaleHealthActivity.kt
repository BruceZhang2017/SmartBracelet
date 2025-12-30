package com.yourapp.health.female.ui

import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.*
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import com.google.android.material.datepicker.MaterialDatePicker
import com.yourapp.health.female.data.FemaleCycleDataManager
import java.text.SimpleDateFormat
import java.util.*

/**
 * 女性健康配置页面
 * 对应iOS端的FemaleHealthViewController
 *
 * 功能:
 * 1. 配置经期天数(3-10天)
 * 2. 配置周期长度(21-35天)
 * 3. 配置最后一次经期开始日期
 * 4. 保存配置并跳转到日历页面
 */
class FemaleHealthActivity : AppCompatActivity() {

    // 数据管理器
    private lateinit var dataManager: FemaleCycleDataManager

    // UI组件
    private lateinit var periodDaysCard: View
    private lateinit var periodDaysValueText: TextView
    private lateinit var cycleLengthCard: View
    private lateinit var cycleLengthValueText: TextView
    private lateinit var lastPeriodCard: View
    private lateinit var lastPeriodValueText: TextView
    private lateinit var startButton: Button

    // 数据
    private var periodDays: Int = 7
    private var cycleLength: Int = 28
    private var lastPeriodDate: Long = System.currentTimeMillis()

    // 是否隐藏最后经期选项(从周期设置进入时隐藏)
    private var hideLastPeriodOption: Boolean = false

    private val dateFormatter = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_female_health)

        // 获取传入参数
        hideLastPeriodOption = intent.getBooleanExtra("hideLastPeriodOption", false)

        // 初始化数据管理器
        dataManager = FemaleCycleDataManager.getInstance(this)

        // 初始化UI
        setupUI()
        loadData()
        updateUI()
    }

    private fun setupUI() {
        // 初始化视图引用
        periodDaysCard = findViewById(R.id.periodDaysCard)
        periodDaysValueText = findViewById(R.id.periodDaysValueText)
        cycleLengthCard = findViewById(R.id.cycleLengthCard)
        cycleLengthValueText = findViewById(R.id.cycleLengthValueText)
        lastPeriodCard = findViewById(R.id.lastPeriodCard)
        lastPeriodValueText = findViewById(R.id.lastPeriodValueText)
        startButton = findViewById(R.id.startButton)

        // 设置点击监听
        periodDaysCard.setOnClickListener { showPeriodDaysPicker() }
        cycleLengthCard.setOnClickListener { showCycleLengthPicker() }
        lastPeriodCard.setOnClickListener { showLastPeriodDatePicker() }
        startButton.setOnClickListener { onStartButtonClick() }

        // 根据进入方式调整UI
        if (hideLastPeriodOption) {
            lastPeriodCard.visibility = View.GONE
            startButton.text = getString(R.string.female_cycle_save)
        } else {
            startButton.text = getString(R.string.female_cycle_start_prediction)
        }
    }

    private fun loadData() {
        val config = dataManager.getCycleConfiguration()
        periodDays = config.periodDays
        cycleLength = config.cycleLength
        lastPeriodDate = config.lastPeriodDate
    }

    private fun updateUI() {
        periodDaysValueText.text = getString(R.string.female_cycle_days_format, periodDays)
        cycleLengthValueText.text = getString(R.string.female_cycle_days_format, cycleLength)
        lastPeriodValueText.text = dateFormatter.format(Date(lastPeriodDate))
    }

    /**
     * 显示经期天数选择器
     */
    private fun showPeriodDaysPicker() {
        val options = (3..10).map { getString(R.string.female_cycle_days_format, it) }.toTypedArray()
        val selectedIndex = periodDays - 3

        AlertDialog.Builder(this)
            .setTitle(R.string.female_cycle_select_period_days)
            .setSingleChoiceItems(options, selectedIndex) { dialog, which ->
                periodDays = which + 3
                updateUI()
                saveData()
                dialog.dismiss()
            }
            .setNegativeButton(R.string.female_cycle_cancel, null)
            .show()
    }

    /**
     * 显示周期长度选择器
     */
    private fun showCycleLengthPicker() {
        val options = (21..35).map { getString(R.string.female_cycle_days_format, it) }.toTypedArray()
        val selectedIndex = cycleLength - 21

        AlertDialog.Builder(this)
            .setTitle(R.string.female_cycle_select_cycle_length)
            .setSingleChoiceItems(options, selectedIndex) { dialog, which ->
                cycleLength = which + 21
                updateUI()
                saveData()
                dialog.dismiss()
            }
            .setNegativeButton(R.string.female_cycle_cancel, null)
            .show()
    }

    /**
     * 显示最后经期日期选择器
     */
    private fun showLastPeriodDatePicker() {
        val picker = MaterialDatePicker.Builder.datePicker()
            .setTitleText(R.string.female_cycle_select_date)
            .setSelection(lastPeriodDate)
            .build()

        picker.addOnPositiveButtonClickListener { selection ->
            lastPeriodDate = selection
            updateUI()
            saveData()
        }

        picker.show(supportFragmentManager, "DATE_PICKER")
    }

    /**
     * 保存数据
     */
    private fun saveData() {
        dataManager.updateCycleConfiguration(
            periodDays = periodDays,
            cycleLength = cycleLength,
            lastPeriodDate = lastPeriodDate
        )
    }

    /**
     * 开始按钮点击
     */
    private fun onStartButtonClick() {
        saveData()

        if (hideLastPeriodOption) {
            // 从周期设置进入,点击保存后返回
            finish()
        } else {
            // 正常流程,跳转到日历页面
            val intent = Intent(this, FemaleCycleCalendarActivity::class.java)
            startActivity(intent)
            finish() // 移除配置页面,防止返回
        }
    }
}

// ==================== Layout XML 示例 ====================

/*
activity_female_health.xml:

<?xml version="1.0" encoding="utf-8"?>
<ScrollView xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:background="#F5F5F5">

    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:orientation="vertical"
        android:padding="16dp">

        <!-- 问题1: 经期天数 -->
        <TextView
            android:id="@+id/questionLabel1"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:text="@string/female_cycle_question_period_days"
            android:textColor="#FFFFFF"
            android:textSize="14sp" />

        <androidx.cardview.widget.CardView
            android:id="@+id/periodDaysCard"
            android:layout_width="match_parent"
            android:layout_height="56dp"
            android:layout_marginTop="12dp"
            app:cardCornerRadius="8dp"
            app:cardElevation="0dp">

            <LinearLayout
                android:layout_width="match_parent"
                android:layout_height="match_parent"
                android:gravity="center_vertical"
                android:orientation="horizontal"
                android:paddingHorizontal="16dp">

                <TextView
                    android:layout_width="0dp"
                    android:layout_height="wrap_content"
                    android:layout_weight="1"
                    android:text="@string/female_cycle_period_days"
                    android:textColor="#333333"
                    android:textSize="16sp"
                    android:textStyle="bold" />

                <TextView
                    android:id="@+id/periodDaysValueText"
                    android:layout_width="wrap_content"
                    android:layout_height="wrap_content"
                    android:text="7天"
                    android:textColor="#9097A0"
                    android:textSize="16sp" />

                <ImageView
                    android:layout_width="16dp"
                    android:layout_height="16dp"
                    android:layout_marginStart="8dp"
                    android:src="@drawable/ic_chevron_right"
                    android:tint="#9097A0" />
            </LinearLayout>
        </androidx.cardview.widget.CardView>

        <!-- 问题2: 周期长度 -->
        <TextView
            android:id="@+id/questionLabel2"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:layout_marginTop="32dp"
            android:text="@string/female_cycle_question_cycle_length"
            android:textColor="#FFFFFF"
            android:textSize="14sp" />

        <androidx.cardview.widget.CardView
            android:id="@+id/cycleLengthCard"
            android:layout_width="match_parent"
            android:layout_height="56dp"
            android:layout_marginTop="12dp"
            app:cardCornerRadius="8dp"
            app:cardElevation="0dp">

            <LinearLayout
                android:layout_width="match_parent"
                android:layout_height="match_parent"
                android:gravity="center_vertical"
                android:orientation="horizontal"
                android:paddingHorizontal="16dp">

                <TextView
                    android:layout_width="0dp"
                    android:layout_height="wrap_content"
                    android:layout_weight="1"
                    android:text="@string/female_cycle_cycle_length"
                    android:textColor="#333333"
                    android:textSize="16sp"
                    android:textStyle="bold" />

                <TextView
                    android:id="@+id/cycleLengthValueText"
                    android:layout_width="wrap_content"
                    android:layout_height="wrap_content"
                    android:text="28天"
                    android:textColor="#9097A0"
                    android:textSize="16sp" />

                <ImageView
                    android:layout_width="16dp"
                    android:layout_height="16dp"
                    android:layout_marginStart="8dp"
                    android:src="@drawable/ic_chevron_right"
                    android:tint="#9097A0" />
            </LinearLayout>
        </androidx.cardview.widget.CardView>

        <!-- 问题3: 最后经期日期 -->
        <TextView
            android:id="@+id/questionLabel3"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:layout_marginTop="32dp"
            android:text="@string/female_cycle_question_last_period"
            android:textColor="#FFFFFF"
            android:textSize="14sp" />

        <androidx.cardview.widget.CardView
            android:id="@+id/lastPeriodCard"
            android:layout_width="match_parent"
            android:layout_height="56dp"
            android:layout_marginTop="12dp"
            app:cardCornerRadius="8dp"
            app:cardElevation="0dp">

            <LinearLayout
                android:layout_width="match_parent"
                android:layout_height="match_parent"
                android:gravity="center_vertical"
                android:orientation="horizontal"
                android:paddingHorizontal="16dp">

                <TextView
                    android:layout_width="0dp"
                    android:layout_height="wrap_content"
                    android:layout_weight="1"
                    android:text="@string/female_cycle_last_period_start_date"
                    android:textColor="#333333"
                    android:textSize="16sp"
                    android:textStyle="bold" />

                <TextView
                    android:id="@+id/lastPeriodValueText"
                    android:layout_width="wrap_content"
                    android:layout_height="wrap_content"
                    android:text="2025-12-04"
                    android:textColor="#9097A0"
                    android:textSize="16sp" />

                <ImageView
                    android:layout_width="16dp"
                    android:layout_height="16dp"
                    android:layout_marginStart="8dp"
                    android:src="@drawable/ic_chevron_right"
                    android:tint="#9097A0" />
            </LinearLayout>
        </androidx.cardview.widget.CardView>

        <!-- 开始按钮 -->
        <Button
            android:id="@+id/startButton"
            android:layout_width="match_parent"
            android:layout_height="44dp"
            android:layout_marginTop="48dp"
            android:background="@drawable/bg_button_brand"
            android:text="@string/female_cycle_start_prediction"
            android:textColor="#FFFFFF"
            android:textSize="18sp"
            android:textStyle="bold" />

    </LinearLayout>
</ScrollView>
*/
