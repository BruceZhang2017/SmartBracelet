//
//  ChangeImageData.h
//  QCY_Demo
//
//  Created by admin on 2021/11/19.
//  Copyright © 2021 杰理科技. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ImageHelper.h"
#import "bmp_convert.h"
#import "JLHeadFile.h"
NS_ASSUME_NONNULL_BEGIN

typedef void(^returnValue)(NSString *label);
@interface ChangeImageData : NSObject

@property (nonatomic, strong) returnValue status;
-(void)changeToBin:(UIImage*)binImage;
-(void)changeImageToBin:(NSData*)imageData and:(JL_ManagerM*) manager;
-(void)smallFileSyncContactsListWithPath:(NSString*)path and:(JL_ManagerM*) manager;
-(void)getContact:(JL_ManagerM*) manager;
-(void)outputContactsListData:(NSData*)mData;
@end

NS_ASSUME_NONNULL_END
