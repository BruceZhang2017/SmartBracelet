package com.yourapp.health.female.ui.view

import android.content.Context
import android.util.AttributeSet
import android.view.Gravity
import android.widget.ImageView
import android.widget.LinearLayout
import androidx.core.content.ContextCompat
import com.yourapp.health.female.R

/**
 * 流量选择按钮组
 * 对应iOS端的createFlowOptionsView()
 *
 * 功能:
 * 1. 3个水滴图标按钮(少/中/多)
 * 2. 累计高亮效果(选中2个,则前2个高亮)
 * 3. 点击切换选中状态
 */
class FlowButtonGroup @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0
) : LinearLayout(context, attrs, defStyleAttr) {

    var onLevelChanged: ((Int) -> Unit)? = null

    private val dropletButtons = mutableListOf<ImageView>()
    private var currentLevel = 0

    init {
        orientation = HORIZONTAL
        gravity = Gravity.CENTER

        setupButtons()
    }

    private fun setupButtons() {
        val dropletIcons = listOf(
            R.drawable.ic_droplet_light,
            R.drawable.ic_droplet_medium,
            R.drawable.ic_droplet_heavy
        )

        dropletIcons.forEachIndexed { index, iconRes ->
            val button = ImageView(context).apply {
                setImageResource(iconRes)
                setPadding(
                    resources.getDimensionPixelSize(R.dimen.flow_button_padding),
                    resources.getDimensionPixelSize(R.dimen.flow_button_padding),
                    resources.getDimensionPixelSize(R.dimen.flow_button_padding),
                    resources.getDimensionPixelSize(R.dimen.flow_button_padding)
                )
                setBackgroundResource(R.drawable.selector_flow_button)
                isClickable = true
                isFocusable = true

                setOnClickListener {
                    setLevel(index + 1)
                }
            }

            val layoutParams = LayoutParams(
                resources.getDimensionPixelSize(R.dimen.flow_button_size),
                resources.getDimensionPixelSize(R.dimen.flow_button_size)
            ).apply {
                if (index > 0) {
                    marginStart = resources.getDimensionPixelSize(R.dimen.flow_button_spacing)
                }
            }

            addView(button, layoutParams)
            dropletButtons.add(button)
        }

        updateButtonStates()
    }

    /**
     * 设置流量等级(0=未选择, 1=少, 2=中, 3=多)
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
        dropletButtons.forEachIndexed { index, button ->
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
