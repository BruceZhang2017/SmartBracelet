//
//  WPCommands+FindDevice.h
//  WatchProtocolSDK-ObjC
//
//  Created by Claude on 2026/01/27.
//  Copyright © 2026 Huaxin. All rights reserved.
//
//  🎯 功能：智能查找设备功能增强
//  ✨ 新增内容：
//    - 带完成回调的查找方法
//    - 主动停止查找功能
//    - 自动定时停止功能
//    - 连接状态检查
//    - 查找状态管理
//

#import "WPCommands.h"

NS_ASSUME_NONNULL_BEGIN

// MARK: - 查找设备动作枚举
typedef NS_ENUM(NSInteger, WPFindDeviceAction) {
    WPFindDeviceActionStart = 0,    // 开始查找（设备震动/响铃）
    WPFindDeviceActionStop = 1      // 停止查找
};

// MARK: - 完成回调
/**
 * 查找设备完成回调
 * @param success 是否成功（YES: 指令已发送，NO: 发送失败）
 * @param error 错误信息（success=NO 时有值）
 */
typedef void(^WPFindDeviceCompletion)(BOOL success, NSError * _Nullable error);

// MARK: - WPCommands 查找设备扩展
@interface WPCommands (FindDevice)

// MARK: - 🔥 推荐使用的方法

/**
 * 查找手环（带完成回调）
 * @param completion 完成回调
 *
 * @discussion
 * 发送查找指令到手环，让手环震动/响铃以帮助用户找到设备。
 * 此方法会自动检查蓝牙连接状态，避免在未连接时发送无效指令。
 *
 * @note 使用示例:
 * ```objc
 * [WPCommands findBandWithCompletion:^(BOOL success, NSError *error) {
 *     if (success) {
 *         NSLog(@"✅ 查找指令已发送，手环应该在震动");
 *         [self showToast:@"请留意周围的震动声"];
 *     } else {
 *         NSLog(@"❌ 发送失败: %@", error.localizedDescription);
 *         [self showError:error.localizedDescription];
 *     }
 * }];
 * ```
 *
 * @warning 如果设备未连接，completion 会返回 success=NO 和相应错误
 * @warning 如果已在查找中，会忽略重复请求并返回 success=YES
 */
+ (void)findBandWithCompletion:(nullable WPFindDeviceCompletion)completion;

/**
 * 停止查找手环
 * @param completion 完成回调
 *
 * @discussion
 * 主动停止手环震动/响铃。用户找到设备后可立即调用此方法停止查找。
 *
 * @note 使用示例:
 * ```objc
 * // 用户点击"停止查找"按钮时
 * [WPCommands stopFindBandWithCompletion:^(BOOL success, NSError *error) {
 *     if (success) {
 *         NSLog(@"⏹ 已停止查找");
 *     }
 * }];
 * ```
 */
+ (void)stopFindBandWithCompletion:(nullable WPFindDeviceCompletion)completion;

/**
 * 查找手环（自动停止）
 * @param duration 持续时间（秒），0 或负数表示使用设备默认时长
 * @param completion 完成回调（在停止查找后调用）
 *
 * @discussion
 * 查找指定时长后自动发送停止指令，避免手环长时间震动影响电量。
 *
 * @note 使用示例:
 * ```objc
 * // 查找 5 秒后自动停止
 * [WPCommands findBandWithDuration:5 completion:^(BOOL success, NSError *error) {
 *     if (success) {
 *         NSLog(@"查找已自动结束");
 *     }
 * }];
 * ```
 *
 * @note 如果在自动停止前手动调用 stopFindBandWithCompletion:，定时器会被自动取消
 */
+ (void)findBandWithDuration:(NSTimeInterval)duration
                  completion:(nullable WPFindDeviceCompletion)completion;

// MARK: - 状态查询

/**
 * 是否正在查找设备
 *
 * @discussion
 * 可用于 UI 状态更新，例如切换按钮文字（"查找设备" ↔ "停止查找"）
 *
 * @note 使用示例:
 * ```objc
 * if ([WPCommands isFindingDevice]) {
 *     [self.findButton setTitle:@"停止查找" forState:UIControlStateNormal];
 * } else {
 *     [self.findButton setTitle:@"查找设备" forState:UIControlStateNormal];
 * }
 * ```
 */
@property (class, nonatomic, readonly) BOOL isFindingDevice;

// MARK: - 高级方法

/**
 * 取消所有查找任务
 *
 * @discussion
 * 清除所有查找相关的定时器和状态标志。
 * 通常在页面销毁或应用进入后台时调用。
 *
 * @note 使用示例:
 * ```objc
 * - (void)dealloc {
 *     [WPCommands cancelAllFindTasks];
 * }
 * ```
 */
+ (void)cancelAllFindTasks;

// MARK: - 兼容性方法

/**
 * 查找手机（让手机响铃）
 * @param completion 完成回调
 *
 * @discussion
 * 当用户在手环上点击"查找手机"功能时，手环会发送此指令到 App。
 * App 应实现 WPBluetoothManagerDelegate 的 receiveData: 方法来响应此指令。
 *
 * @warning 此方法由 App 主动调用时无实际效果，仅供测试使用
 */
+ (void)findPhoneWithCompletion:(nullable WPFindDeviceCompletion)completion;

@end

NS_ASSUME_NONNULL_END
