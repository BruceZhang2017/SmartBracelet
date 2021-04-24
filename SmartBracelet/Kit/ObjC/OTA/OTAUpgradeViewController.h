//
//  OTAUpgradeViewController.h
//  PHY
//
//  Created by Han on 2018/10/9.
//  Copyright © 2018年 phy. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


@interface OTAUpgradeViewController : UIViewController

/** 从appDelegate里面，跳转过来，主要用于打开其他app共享跳转过来的文档 */
@property (nonatomic, strong) NSString *mscAddress;//mac地址
@property (nonatomic, strong) NSString *originalUUID;//uuid

@end

NS_ASSUME_NONNULL_END
