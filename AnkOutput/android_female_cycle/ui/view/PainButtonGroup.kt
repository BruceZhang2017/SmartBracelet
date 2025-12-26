package com.yourapp.health.female.ui.view

import android.content.Context
import android.util.AttributeSet
import android.view.Gravity
import android.widget.ImageView
import android.widget.LinearLayout
import androidx.core.content.ContextCompat
import com.yourapp.health.female.R

/**
 * 痛经选择按钮组
 * 对应iOS端的createPainOptionsView()
 *
 * 功能:
 * 1. 3个闪电图标按钮(轻微/中等/严重)
 * 2. 累计高亮效果(选中2个,则前2个高亮)
 * 3. 点击切换选中状态
 */
class PainButtonGroup @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0
) : LinearLayout(context, attrs, defStyleAttr) {

    var onLevelChanged: ((Int) -> Unit)? = null

    private val lightningButtons = mutableListOf<ImageView>()
    private var currentLevel = 0

    init {
        orientation = HORIZONTAL
        gravity = Gravity.CENTER

        setupButtons()
    }

    private fun setupButtons() {
        val lightningIcons = listOf(
            R.drawable.ic_lightning_mild,
            R.drawable.ic_lightning_moderate,
            R.drawable.ic_lightning_severe
        )

        lightningIcons.forEachIndexed { index, iconRes ->
            val button = ImageView(context).apply {
                setImageResource(iconRes)
                setPadding(
                    resources.getDimensionPixelSize(R.dimen.pain_button_padding),
                    resources.getDimensionPixelSize(R.dimen.pain_button_padding),
                    resources.getDimensionPixelSize(R.dimen.pain_button_padding),
                    resources.getDimensionPixelSize(R.dimen.pain_button_padding)
                )
                setBackgroundResource(R.drawable.selector_pain_button)
                isClickable = true
                isFocusable = true

                setOnClickListener {
                    setLevel(index + 1)
                }
            }

            val layoutParams = LayoutParams(
                resources.getDimensionPixelSize(R.dimen.pain_button_size),
                resources.getDimensionPixelSize(R.dimen.pain_button_size)
            ).apply {
                if (index > 0) {
                    marginStart = resources.getDimensionPixelSize(R.dimen.pain_button_spacing)
                }
            }

            addView(button, layoutParams)
            lightningButtons.add(button)
        }

        updateButtonStates()
    }

    /**
     * 设置痛经等级(0=未选择, 1=轻微, 2=中等, 3=严重)
     */
    fun setLevel(level: Int) {
        if (level == currentLevel) {
            // 点击同一个按钮,取消选中
            currentLevel = 0
        } else {
            currentLevel = level.coerceIn(0, 3)
        }

        updateButtonStates()
        onLevelChanged?.invoke(currentLevel)
    }

    /**
     * 获取当前等级
     */
    fun getLevel(): Int = currentLevel

    /**
     * 更新按钮选中状态(累计高亮)
     */
    private fun updateButtonStates() {
        lightningButtons.forEachIndexed { index, button ->
            button.isSelected = (index < currentLevel)

            // 设置图标颜色
            val tint = if (button.isSelected) {
                ContextCompat.getColor(context, R.color.female_cycle_brand)
            } else {
                ContextCompat.getColor(context, R.color.female_cycle_text_hint)
            }
            button.setColorFilter(tint)
        }
    }
}
