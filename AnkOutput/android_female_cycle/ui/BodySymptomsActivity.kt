package com.yourapp.health.female.ui

import android.content.Intent
import android.os.Bundle
import android.widget.Button
import androidx.appcompat.app.AppCompatActivity
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.yourapp.health.female.R
import com.yourapp.health.female.ui.adapter.SymptomCategoryAdapter
import com.yourapp.health.female.ui.model.SymptomCategory

/**
 * 身体症状选择页面
 * 对应iOS端的BodySymptomsViewController
 *
 * 功能:
 * 1. 显示7个症状分类
 * 2. 每个分类下有多个症状选项
 * 3. 支持多选
 * 4. 保存并返回选中结果
 */
class BodySymptomsActivity : AppCompatActivity() {

    private lateinit var recyclerView: RecyclerView
    private lateinit var confirmButton: Button
    private lateinit var adapter: SymptomCategoryAdapter

    private var selectedSymptoms = mutableSetOf<String>()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_body_symptoms)

        // 获取已选中的症状
        val currentSymptoms = intent.getStringArrayListExtra("selectedSymptoms") ?: emptyList()
        selectedSymptoms.addAll(currentSymptoms)

        setupUI()
        loadSymptomCategories()
    }

    private fun setupUI() {
        recyclerView = findViewById(R.id.symptomRecyclerView)
        confirmButton = findViewById(R.id.confirmButton)

        recyclerView.layoutManager = LinearLayoutManager(this)

        confirmButton.setOnClickListener {
            saveAndFinish()
        }
    }

    private fun loadSymptomCategories() {
        val categories = createSymptomCategories()

        adapter = SymptomCategoryAdapter(
            categories = categories,
            selectedSymptoms = selectedSymptoms,
            onSymptomToggled = { symptom, isSelected ->
                if (isSelected) {
                    selectedSymptoms.add(symptom)
                } else {
                    selectedSymptoms.remove(symptom)
                }
            }
        )

        recyclerView.adapter = adapter
    }

    /**
     * 创建症状分类数据
     * 格式: "分类名-症状名"
     */
    private fun createSymptomCategories(): List<SymptomCategory> {
        return listOf(
            // 全身
            SymptomCategory(
                name = getString(R.string.female_cycle_symptom_category_whole_body),
                symptoms = listOf(
                    getString(R.string.female_cycle_symptom_normal),
                    getString(R.string.female_cycle_symptom_cramps),
                    getString(R.string.female_cycle_symptom_fatigue),
                    getString(R.string.female_cycle_symptom_edema)
                )
            ),

            // 头部
            SymptomCategory(
                name = getString(R.string.female_cycle_symptom_category_head),
                symptoms = listOf(
                    getString(R.string.female_cycle_symptom_headache),
                    getString(R.string.female_cycle_symptom_dizziness),
                    getString(R.string.female_cycle_symptom_vomiting),
                    getString(R.string.female_cycle_symptom_insomnia)
                )
            ),

            // 腹部
            SymptomCategory(
                name = getString(R.string.female_cycle_symptom_category_abdomen),
                symptoms = listOf(
                    getString(R.string.female_cycle_symptom_diarrhea),
                    getString(R.string.female_cycle_symptom_lower_abdominal_pain),
                    getString(R.string.female_cycle_symptom_abdominal_swelling),
                    getString(R.string.female_cycle_symptom_abdominal_pain)
                )
            ),

            // 腿部
            SymptomCategory(
                name = getString(R.string.female_cycle_symptom_category_legs),
                symptoms = listOf(
                    getString(R.string.female_cycle_symptom_thigh_soreness),
                    getString(R.string.female_cycle_symptom_thigh_spasm),
                    getString(R.string.female_cycle_symptom_calf_soreness),
                    getString(R.string.female_cycle_symptom_calf_spasm)
                )
            ),

            // 其他
            SymptomCategory(
                name = getString(R.string.female_cycle_symptom_category_other),
                symptoms = listOf(
                    getString(R.string.female_cycle_symptom_breast_tenderness),
                    getString(R.string.female_cycle_symptom_backache),
                    getString(R.string.female_cycle_symptom_hot_flash),
                    getString(R.string.female_cycle_symptom_cold_deficiency)
                )
            ),

            // 分泌物
            SymptomCategory(
                name = getString(R.string.female_cycle_symptom_category_discharge),
                symptoms = listOf(
                    getString(R.string.female_cycle_symptom_dry),
                    getString(R.string.female_cycle_symptom_sticky),
                    getString(R.string.female_cycle_symptom_egg_white),
                    getString(R.string.female_cycle_symptom_watery),
                    getString(R.string.female_cycle_symptom_milky)
                )
            ),

            // 皮肤
            SymptomCategory(
                name = getString(R.string.female_cycle_symptom_category_skin),
                symptoms = listOf(
                    getString(R.string.female_cycle_symptom_oily),
                    getString(R.string.female_cycle_symptom_blackhead),
                    getString(R.string.female_cycle_symptom_acne)
                )
            )
        )
    }

    private fun saveAndFinish() {
        val result = Intent()
        result.putStringArrayListExtra("selectedSymptoms", ArrayList(selectedSymptoms))
        setResult(RESULT_OK, result)
        finish()
    }
}
