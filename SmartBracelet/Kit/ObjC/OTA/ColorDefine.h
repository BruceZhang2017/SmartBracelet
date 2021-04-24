//
//  ColorDefine.h
//  PHY
//
//  Created by Han on 2018/9/27.
//  Copyright © 2018年 phy. All rights reserved.
//

#ifndef ColorDefine_h
#define ColorDefine_h

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

//通用颜色 nav颜色
#define Color_navPageButton_Green               UIColorFromRGB(0x009C3A)
#define Color_Background                        UIColorFromRGB(0xf4f4f4)
#define Color_Title                             UIColorFromRGB(0x333333)
#define Color_Title_Black                       UIColorFromRGB(0x3b3b3b)

#define Color_GRAY                              UIColorFromRGB(0xd9d9d9)
#define Color_BLACK                             UIColorFromRGB(0x000000)
#define Color_White                             UIColorFromRGB(0xffffff)

//Tabbar
#define Color_Tabbar_Normal                     UIColorFromRGB(0xcfcccd)
#define Color_Tabbar_Selected                   UIColorFromRGB(0x3399FF)
#define Color_Tabbar_LineColor                  UIColorFromRGB(0xdddddd)

//自定义的progress
#define Color_Progress_Box                     UIColorFromRGB(0xFC5832)
#define Color_Progress_TrackTint                     UIColorFromRGB(0xCFCFCF)
#define Color_Progress_Tint                     UIColorFromRGB(0xFC5832)

#define SCREEN_WIDTH                                  ([UIScreen mainScreen].bounds.size.width)
#define SCREEN_HEIGHT                                 ([UIScreen mainScreen].bounds.size.height)


//cellLineColor

//Button

#endif /* ColorDefine_h */
