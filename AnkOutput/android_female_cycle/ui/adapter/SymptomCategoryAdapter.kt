package com.yourapp.health.female.ui.adapter

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import com.google.android.material.chip.Chip
import com.google.android.material.chip.ChipGroup
import com.yourapp.health.female.R
import com.yourapp.health.female.ui.model.SymptomCategory

/**
 * 症状分类适配器
 * 对应iOS端的UITableViewDataSource (BodySymptomsViewController)
 *
 * 功能:
 * 1. 显示症状分类标题
 * 2. 显示每个分类下的症状Chip
 * 3. 处理症状选中/取消
 */
class SymptomCategoryAdapter(
    private val categories: List<SymptomCategory>,
    private val selectedSymptoms: MutableSet<String>,
    private val onSymptomToggled: (String, Boolean) -> Unit
) : RecyclerView.Adapter<SymptomCategoryAdapter.CategoryViewHolder>() {

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): CategoryViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.item_symptom_category, parent, false)
        return CategoryViewHolder(view)
    }

    override fun onBindViewHolder(holder: CategoryViewHolder, position: Int) {
        val category = categories[position]
        holder.bind(category)
    }

    override fun getItemCount(): Int = categories.size

    inner class CategoryViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        private val categoryNameText: TextView = itemView.findViewById(R.id.categoryNameText)
        private val symptomsChipGroup: ChipGroup = itemView.findViewById(R.id.symptomsChipGroup)

        fun bind(category: SymptomCategory) {
            categoryNameText.text = category.name
            symptomsChipGroup.removeAllViews()

            // 为每个症状创建Chip
            category.symptoms.forEach { symptom ->
                val symptomKey = "${category.name}-${symptom}"
                val chip = Chip(itemView.context).apply {
                    text = symptom
                    isCheckable = true
                    isChecked = selectedSymptoms.contains(symptomKey)

                    setOnCheckedChangeListener { _, isChecked ->
                        onSymptomToggled(symptomKey, isChecked)
                    }
                }

                symptomsChipGroup.addView(chip)
            }
        }
    }
}
