//
//  JL_ManagerM+FileTransfer.h
//  JL_BLEKit
//
//  Created by 杰理科技 on 2021/10/14.
//  Copyright © 2021 www.zh-jieli.com. All rights reserved.
//

#import <JL_BLEKit/JL_BLEKit.h>
#import "JL_TypeEnum.h"

NS_ASSUME_NONNULL_BEGIN

@interface JL_ManagerM (FileTransfer)

-(void)intputPKG_FileTransfer:(JL_PKG*)pkg;

-(void)cmdSmallFileQueryType:(uint8_t)type
                      Result:(JL_SMALLFILE_LIST __nullable)result;

-(void)cmdSmallFileReadType:(uint8_t)type
                     FileID:(uint16_t)fileId
                     Offset:(uint16_t)offset
                   FileSize:(uint16_t)fileSize
                     Result:(JL_SMALLFILE_RT __nullable)result;

-(void)cmdSmallFileNewType:(uint8_t)type
                    Offset:(uint16_t)offset
                  FileSize:(uint16_t)fileSize
                  FileData:(NSData*)data
                    Result:(JL_SMALLFILE_RT __nullable)result;

-(void)cmdSmallFileUpdateType:(uint8_t)type
                       FileID:(uint16_t)fileId
                       Offset:(uint16_t)offset
                     FileSize:(uint16_t)fileSize
                     FileData:(NSData*)data
                       Result:(JL_SMALLFILE_RT __nullable)result;

-(void)cmdSmallFileDeleteType:(uint8_t)type
                       FileID:(uint16_t)fileId
                       Result:(JL_SMALLFILE_RT __nullable)result;

@end

NS_ASSUME_NONNULL_END
