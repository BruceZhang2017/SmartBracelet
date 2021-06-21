//
//  MAWeatherForecastView.h
//  officialDemo2D
//
//  Created by PC on 15/8/24.
//  Copyright (c) 2015年 AutoNavi. All rights reserved.
//

@import UIKit;
@import AMapSearchKit;


@interface MAWeatherForecastView : UIView

- (void)updateWeatherWithInfo:(AMapLocalWeatherForecast *)forecastInfo;

@end
