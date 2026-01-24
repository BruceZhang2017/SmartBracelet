//
//  NSData+HexString.m
//  WatchProtocolSDK-ObjC
//
//  Created by Claude on 2026/01/21.
//  Copyright © 2026 Huaxin. All rights reserved.
//

#import "NSData+HexString.h"

@implementation NSData (HexString)

- (NSString *)hexEncodedStringWithSeparator:(NSString *)separator {
    if (self.length == 0) {
        return @"";
    }

    NSMutableString *hexString = [NSMutableString stringWithCapacity:self.length * 2];
    const unsigned char *bytes = (const unsigned char *)self.bytes;

    for (NSUInteger i = 0; i < self.length; i++) {
        if (i > 0 && separator.length > 0) {
            [hexString appendString:separator];
        }
        [hexString appendFormat:@"%02X", bytes[i]];
    }

    return [hexString copy];
}

- (NSString *)hexEncodedString {
    return [self hexEncodedStringWithSeparator:@""];
}

@end
