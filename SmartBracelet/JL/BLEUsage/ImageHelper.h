//
//  ImageHelper.h
//  QCY_Demo
//
//  Created by JLee on 2020/12/29.
//  Copyright © 2020 杰理科技. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ImageHelper : NSObject

+ ( NSData * ) convertUIImageToBitmapRGBA8: ( UIImage * ) image;
+ ( CGContextRef ) newBitmapRGBA8ContextFromImage: ( CGImageRef ) image;
+ ( UIImage * ) convertBitmapRGBA8ToUIImage: ( unsigned char * ) buffer
                                  withWidth: ( int ) width
                                 withHeight: ( int ) height ;
@end

NS_ASSUME_NONNULL_END
