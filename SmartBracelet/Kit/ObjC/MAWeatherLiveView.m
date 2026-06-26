//
//  MAWeatherLiveView.m
//  officialDemo2D
//
//  Created by PC on 15/8/24.
//  Copyright (c) 2015年 AutoNavi. All rights reserved.
//

#import "MAWeatherLiveView.h"
#import "PureLayout.h"

@interface MAWeatherLiveView()

@property (nonatomic, strong) UILabel *city;
@property (nonatomic, strong) UILabel *weather;
@property (nonatomic, strong) UILabel *temperature;
@property (nonatomic, strong) UILabel *wind;

@end


@implementation MAWeatherLiveView

- (void)updateWeatherWithInfo:(AMapLocalWeatherLive *)liveInfo
{
    self.city.text        = liveInfo.city;
    self.weather.text     = liveInfo.weather;
    self.temperature.text = [NSString stringWithFormat:@"%@°",liveInfo.temperature];
    NSString * str1 = NSLocalizedString(@"humidity", @"");
    NSString * str2 = NSLocalizedString(@"wind_speed", @"");
    self.wind.text        = [NSString stringWithFormat:@"%@ %@%@  %@%@%%",liveInfo.windDirection,liveInfo.windPower, str2,str1,liveInfo.humidity];
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _city                        = [[UILabel alloc] init];
        [self addSubview:_city];
        [_city autoAlignAxisToSuperviewAxis:ALAxisVertical];
        [_city autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:20];
        [_city autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:16 relation:NSLayoutRelationGreaterThanOrEqual];
        [_city autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:16 relation:NSLayoutRelationGreaterThanOrEqual];
        _city.text                   = @"city";
        _city.textColor              = [UIColor whiteColor];
        _city.font                   = [UIFont systemFontOfSize:32];
        _city.backgroundColor        = [UIColor clearColor];
        _city.textAlignment          = NSTextAlignmentCenter;
        _city.numberOfLines          = 0;
        _city.adjustsFontSizeToFitWidth = YES;
        _city.minimumScaleFactor     = 0.75;

        _weather                     = [[UILabel alloc] init];
        [self addSubview:_weather];
        [_weather autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_city withOffset:15.0];
        [_weather autoAlignAxisToSuperviewAxis:ALAxisVertical];
        [_weather autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:16 relation:NSLayoutRelationGreaterThanOrEqual];
        [_weather autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:16 relation:NSLayoutRelationGreaterThanOrEqual];
        _weather.text                = @"weather";
        _weather.textColor           = [UIColor whiteColor];
        _weather.font                = [UIFont systemFontOfSize:28];
        _weather.backgroundColor     = [UIColor clearColor];
        _weather.textAlignment       = NSTextAlignmentCenter;
        _weather.numberOfLines       = 0;
        _weather.adjustsFontSizeToFitWidth = YES;
        _weather.minimumScaleFactor  = 0.75;

        _wind                        = [[UILabel alloc] init];
        [self addSubview:_wind];
        [_wind autoAlignAxisToSuperviewAxis:ALAxisVertical];
        [_wind autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:15];
        [_wind autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:16];
        [_wind autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:16];
        _wind.text                   = @"wind";
        _wind.textColor              = [UIColor whiteColor];
        _wind.font                   = [UIFont systemFontOfSize:16];
        _wind.backgroundColor        = [UIColor clearColor];
        _wind.textAlignment          = NSTextAlignmentCenter;
        _wind.numberOfLines          = 0;
        _wind.lineBreakMode          = NSLineBreakByWordWrapping;

        UIView *container            = [[UIView alloc] init];
        [self addSubview:container];
        container.backgroundColor    = [UIColor clearColor];
        [container autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_weather];
        [container autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:_wind];
        [container autoPinEdgeToSuperviewEdge:ALEdgeLeft];
        [container autoPinEdgeToSuperviewEdge:ALEdgeRight];

        _temperature                 = [[UILabel alloc] init];
        [container addSubview:_temperature];
        [_temperature autoCenterInSuperview];
        [_temperature autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:16 relation:NSLayoutRelationGreaterThanOrEqual];
        [_temperature autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:16 relation:NSLayoutRelationGreaterThanOrEqual];
        _temperature.text            = @"loading";
        _temperature.textColor       = [UIColor whiteColor];
        _temperature.font            = [UIFont systemFontOfSize:100];
        _temperature.backgroundColor = [UIColor clearColor];
        _temperature.textAlignment   = NSTextAlignmentCenter;
        _temperature.adjustsFontSizeToFitWidth = YES;
        _temperature.minimumScaleFactor = 0.6;
        
    }
    return self;
}



@end
