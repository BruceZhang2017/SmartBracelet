//
//  NSData+HexString.h
//  WatchProtocolSDK-ObjC
//
//  Created by Claude on 2026/01/21.
//  Copyright © 2026 Huaxin. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * NSData 扩展，用于将字节数据转换为十六进制字符串
 * 对应 Swift 版本的 DataExtensions.swift
 */
@interface NSData (HexString)

/**
 * 将 Data 转换为十六进制字符串（带分隔符）
 * @param separator 分隔符，默认为 ":"
 * @return 十六进制字符串，例如 "01:02:FF" 或 "0102FF"
 *
 * 例如:
 * Data([0x01, 0x02, 0xFF]) -> hexEncodedStringWithSeparator(":") -> "01:02:FF"
 * Data([0x01, 0x02, 0xFF]) -> hexEncodedStringWithSeparator("") -> "0102FF"
 */
- (NSString *)hexEncodedStringWithSeparator:(NSString *)separator;

/**
 * 将 Data 转换为十六进制字符串（不带分隔符）
 * @return 十六进制字符串，例如 "0102FF"
 *
 * 例如:
 * Data([0x01, 0x02, 0xFF]) -> hexEncodedString -> "0102FF"
 */
- (NSString *)hexEncodedString;

@end

NS_ASSUME_NONNULL_END
