//
//  SGSportMapViewController.m
//  SGRunning
//
//  Created by 孙冠 on 16/11/4.
//  Copyright © 2016年 sunguan. All rights reserved.
//

#import "SGSportMapViewController.h"
#import <MAMapKit/MAMapKit.h>
#import "SGSportTrackingLine.h"

@interface SGSportMapViewController ()<MAMapViewDelegate>

@end

@implementation SGSportMapViewController{
    /// 起始位置
    CLLocation *_startLocation;
    MAMapView *mapView;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setupMapView];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
}

///添加地图视图
- (void)setupMapView {
    mapView = [[MAMapView alloc] initWithFrame:self.view.bounds];
    ///把地图添加至view
    [self.view addSubview:mapView];
    mapView.showsScale = NO;
    mapView.showsUserLocation = YES;
    mapView.userTrackingMode = MAUserTrackingModeFollow;
    mapView.allowsBackgroundLocationUpdates = YES;
    mapView.pausesLocationUpdatesAutomatically = NO;
    mapView.delegate = self;
    mapView.zoomLevel = 17;
    mapView.maxZoomLevel = 18;
}

- (void)saveLocalMapView: (NSString *)name {
    CGFloat width = [[UIScreen mainScreen] bounds].size.width;
    UIImage *image = [mapView takeSnapshotInRect:CGRectMake(0, (self.view.bounds.size.height - width) / 2, width, width)];
    // 本地沙盒目录
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    // 得到本地沙盒中名为"MyImage"的路径，"MyImage"是保存的图片名
    NSString *imageFilePath = [path stringByAppendingPathComponent: name];
    // 将取得的图片写入本地的沙盒中，其中0.5表示压缩比例，1表示不压缩，数值越小压缩比例越大
    BOOL success = [UIImageJPEGRepresentation(image, 0.5) writeToFile:imageFilePath  atomically:YES];
    if (success){
        NSLog(@"写入本地成功");
    }
}

#pragma mark - MAMapView代理方法
/**
 * @brief 位置或者设备方向更新后，会调用此函数
 * @param mapView 地图View
 * @param userLocation 用户定位信息(包括位置与设备方向等数据)
 * @param updatingLocation 标示是否是location数据更新, YES:location数据更新 NO:heading数据更新
 */
- (void)mapView:(MAMapView *)mapView didUpdateUserLocation:(MAUserLocation *)userLocation updatingLocation:(BOOL)updatingLocation {
    
    // 0. 判断 `位置数据` 是否变化 - 不一定是经纬度变化！
    if (!updatingLocation) {
        return;
    }
    
    // 1. 判断运动状态，只有`继续`才需要绘制运动轨迹
    if (_sportTracking.sportState != SGSportStateContinue) {
        return;
    }
    
    // 大概 1s 更新一次！
    // NSLog(@"%@ %p", userLocation.location, userLocation.location);
    
    // 判断起始位置是否存在
    if (_startLocation == nil) {
        _startLocation = userLocation.location;
        
        // 1. 实例化大头针
        MAPointAnnotation *annotaion = [MAPointAnnotation new];
        annotaion.title = @"起点";
        // 2. 指定坐标位置
        annotaion.coordinate = userLocation.location.coordinate;
        // 3. 添加到地图视图
        [mapView addAnnotation:annotaion];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SportData" object:[NSString stringWithFormat:@"%lf-%lf,", userLocation.location.coordinate.latitude, userLocation.location.coordinate.longitude]];
    // 绘制轨迹模型
    [mapView addOverlay:[_sportTracking appendLocation:userLocation.location]];
}

- (MAAnnotationView *)mapView:(MAMapView *)mapView viewForAnnotation:(id<MAAnnotation>)annotation {
    if ([annotation isKindOfClass:[MAPointAnnotation class]]){
        MAPointAnnotation* ann = (MAPointAnnotation*)annotation;
        if ([ann.title isEqualToString:@"起点"]) {
            MAAnnotationView *annotationView = (MAAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:@"startLocation"];
            if (annotationView == nil) {
                annotationView = [[MAAnnotationView alloc] initWithAnnotation:annotation
                                                              reuseIdentifier:@"startLocation"];
            }
            annotationView.image = [UIImage new];
            annotationView.centerOffset = CGPointMake(0, -20);
            return annotationView;
        }
    }
    
    // 1. 查询可重用大头针视图
    static NSString *annotaionId = @"annotaionId";
    MAAnnotationView *annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:annotaionId];
    
    // 2. 如果没有查到，新建视图
    if (annotationView == nil) {
        annotationView = [[MAAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:annotaionId];
    }
    
    // 3. 设置大头针视图 - 设置图像
    // 根据运动类型来创建运动图像
    UIImage *image = _sportTracking.sportImage;
    annotationView.image = image;
    annotationView.centerOffset = CGPointMake(0, -image.size.height * 0.5);
    
    // 4. 返回自定义大头针视图
    return annotationView;
}

// 需要实现MAMapViewDelegate的-mapView:rendererForOverlay:
- (MAOverlayRenderer *)mapView:(MAMapView *)mapView rendererForOverlay:(id<MAOverlay>)overlay {
    
    // 1. 判断 overlay 的类型
    if (![overlay isKindOfClass:[MAPolyline class]]) {
        return nil;
    }
    
    // 2. 实例化折线渲染器
    SGPolyLine *polyline = (SGPolyLine *)overlay;
    MAPolylineRenderer *renderer = [[MAPolylineRenderer alloc] initWithPolyline:polyline];
    
    // 3. 设置显示属性
    renderer.lineWidth = 5;
    renderer.strokeColor = polyline.color;
    
    return renderer;
}

@end
