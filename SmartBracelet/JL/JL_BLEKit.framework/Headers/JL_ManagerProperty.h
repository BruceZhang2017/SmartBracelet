//
//  JL_ManagerProperty.h
//  JL_BLEKit
//
//  Created by 杰理科技 on 2021/10/14.
//  Copyright © 2021 www.zh-jieli.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JL_TypeEnum.h"
#import "JL_Tools.h"

NS_ASSUME_NONNULL_BEGIN

@interface JL_ManagerProperty : NSObject
@property(nonatomic,strong)JL_Timer *__nullable cmdTimer;
@property(nonatomic,assign)int                  timeoutSN;
@property(nonatomic,assign)JL_SMALLFILE_LIST __nullable smallfile_list;
@property(nonatomic,assign)JL_SMALLFILE_RT   __nullable smallfile_read;
@property(nonatomic,assign)JL_SMALLFILE_RT   __nullable smallfile_new;
@property(nonatomic,assign)JL_SMALLFILE_RT   __nullable smallfile_update;
@property(nonatomic,assign)JL_SMALLFILE_RT   __nullable smallfile_delete;
@end

NS_ASSUME_NONNULL_END
