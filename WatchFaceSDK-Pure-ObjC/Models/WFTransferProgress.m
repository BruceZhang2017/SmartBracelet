//
//  WFTransferProgress.m
//  WatchFaceSDK-ObjC
//
//  Created by Claude on 2026-01-13.
//

#import "WFTransferProgress.h"

@implementation WFTransferProgress

- (instancetype)initWithCurrentPacket:(NSInteger)currentPacket
                         totalPackets:(NSInteger)totalPackets
                     bytesTransferred:(NSInteger)bytesTransferred
                           totalBytes:(NSInteger)totalBytes {
    self = [super init];
    if (self) {
        _currentPacket = currentPacket;
        _totalPackets = totalPackets;
        _bytesTransferred = bytesTransferred;
        _totalBytes = totalBytes;
        _percentage = totalBytes > 0 ? (float)bytesTransferred / (float)totalBytes : 0.0f;
        _message = [NSString stringWithFormat:@"%.2f%%", _percentage * 100];
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<WFTransferProgress: %ld/%ld packets, %ld/%ld bytes, %.2f%%>",
            (long)self.currentPacket, (long)self.totalPackets,
            (long)self.bytesTransferred, (long)self.totalBytes,
            self.percentage * 100];
}

@end
