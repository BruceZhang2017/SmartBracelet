# Debug Session: dial-rle-size-stall
- **Status**: [OPEN]
- **Issue**: 自定义表盘在 RLE 路径下目标大小设置为 20KB 时，经过多轮压缩后 `raw_to_rle` 结果稳定在约 33KB，无法继续下降。
- **Debug Server**: N/A
- **Log File**: N/A

## Reproduction Steps
1. 在 `MyClockViewController` 中选择自定义图片并进入 `startupdateCustomImage()`
2. 走 `screenType == 2 || screenType == 3` 的 RLE 路径
3. 观察日志中多轮 `Attempt ... dial=... target=20480`

## Hypotheses & Verification
| ID | Hypothesis | Likelihood | Effort | Evidence |
|----|------------|------------|--------|----------|
| A | `raw_to_rle` 结果主要由原始像素分布决定，JPEG 质量变化未显著改变 `rawImageData` | High | Low | Pending |
| B | `resizeAndReduceRGB` 没有实际降低颜色复杂度，因此 `reduced-rgb` 与 `base` 几乎一致 | High | Low | Pending |
| C | `20KB` 低于当前设备/编码下限，现有策略无解 | Medium | Low | Pending |
| D | `rawImageData` 生成过程固定展开像素格式，前置 JPEG 压缩收益被抵消 | Medium | Medium | Pending |
| E | 蓝牙响应错误打断了表盘发送链路，但不影响压缩阶段 size stall | Low | Low | Pending |

## Log Evidence
- 用户提供日志显示 `base/reduced-rgb/reduced-rgb-x2` 三个阶段的 `dial` 大小均稳定在 `33014~33157`
- 所有尝试中的 `raw=65536` 恒定，符合 `128 * 128 * 4` 的 ARGB 原始像素大小
- `ABParTool` 头文件声明 `UIImage.rawImageData` 输出格式为 `ARGB`
- `reduced-rgb` 与 `reduced-rgb-x2` 基本无收益，说明当前颜色简化强度不足，未改变 RLE 可压缩性

## Verification Conclusion
- A: Confirmed。`JPEG -> UIImage -> rawImageData(ARGB)` 链路把前面的压缩收益基本抹平，RLE 结果主要由最终像素分布决定。
- B: Confirmed。当前 `resizeAndReduceRGB` 仅做 `step=4` 量化，过弱，因此与 `base` 几乎一致。
- C: Inconclusive。`20KB` 可能低于部分图片的可达下限，但需要更激进的像素简化策略验证后再判断。
- D: Confirmed。`rawImageData` 为 ARGB 定长展开，因此 `raw` 大小恒定。
- E: Rejected as root cause。蓝牙错误日志出现在压缩失败之后，不是 size stall 的直接原因。

## Fix Attempt
- 将 RLE 路径的 `qualitySteps` 从 10 档收紧为 2 档，避免无意义重试
- 新增 RLE 候选图像链路：`quant-16`、`quant-32`、`pixel-75-quant-32`、`pixel-62-quant-48`、`pixel-50-quant-64`
- 通过更激进的颜色量化和下采样再无插值放大，主动制造更长的色块连续段，提高 RLE 可压缩性

## Pending Verification
- 重新运行自定义表盘上传，比较各阶段 `dial=` 是否明显低于之前的 `33014~33157`
- 若最佳结果仍远高于 `20480`，则可判定当前图片内容在该设备 RLE 编码下不满足 20KB 约束，需要改产品阈值或提前失败提示
