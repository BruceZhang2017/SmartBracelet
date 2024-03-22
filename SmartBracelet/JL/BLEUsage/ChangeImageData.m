//
//  ChangeImageData.m
//  QCY_Demo
//
//  Created by admin on 2021/11/19.
//  Copyright © 2021 杰理科技. All rights reserved.
//

#import "ChangeImageData.h"
#import "JL_RunSDK.h"
#import "JLFileTransferHelper.h"
#import "PersonModel.h"
@implementation ChangeImageData

-(void)changeToBin:(UIImage*)binImage{
    
    [[JL_RunSDK sharedMe] setCsmWatch:@"bgp_w001"];
    NSString *testPath = [JL_Tools listPath:NSDocumentDirectory MiddlePath:@"" File:@"ios_test.bmp"];
    [JL_Tools removePath:testPath];
    [JL_Tools createOn:NSDocumentDirectory MiddlePath:@"" File:@"ios_test.bmp"];
    
//    NSString *hpPath = [JL_Tools find:name];
//    NSData *hpData = [NSData dataWithContentsOfFile:hpPath];
//    UIImage *image = [UIImage imageWithData:hpData];
    
    int width = binImage.size.width;
    int height = binImage.size.height;
    NSLog(@"---> w:%d h:%d",width,height);
        
    NSData *bitmap = [ImageHelper convertUIImageToBitmapRGBA8:binImage];
    [JL_Tools writeData:bitmap fillFile:testPath];
    
    
    NSString *wName = [[JL_RunSDK sharedMe] csmWatch];
    
    NSString *binPath = [JL_Tools listPath:NSDocumentDirectory MiddlePath:@"" File:wName];
    [JL_Tools removePath:binPath];
    [JL_Tools createOn:NSDocumentDirectory MiddlePath:@"" File:wName];
    
    btm_to_res_path((char*)[testPath UTF8String], width, height, (char*)[binPath UTF8String]);
    NSLog(@"---> bg_watch.bin is OK!");
    
}

-(void)changeImageToBin:(NSData*)imageData and:(JL_ManagerM*) manager{

    NSString *bmpPath = [JL_Tools listPath:NSLibraryDirectory MiddlePath:@"" File:@"ios_test.bmp"];
    NSString *binPath = [JL_Tools listPath:NSLibraryDirectory MiddlePath:@"" File:@"bgp_w001"];

    [JL_Tools removePath:bmpPath];
    [JL_Tools removePath:binPath];

    [JL_Tools createOn:NSLibraryDirectory MiddlePath:@"" File:@"ios_test.bmp"];
    [JL_Tools createOn:NSLibraryDirectory MiddlePath:@"" File:@"bgp_w001"];

    UIImage *image = [UIImage imageWithData:imageData];
    int width = image.size.width;
    int height = image.size.height;
    NSLog(@"压缩分辨率 ---> w:%df h:%df",width,height);

    NSData *bitmap = [BitmapTool convert_B_G_R_A_BytesFromImage:image];
    [JL_Tools writeData:bitmap fillFile:bmpPath];

    JLModel_Device *model = [manager outputDeviceModel];
    if (model.sdkType == JL_SDKType701xWATCH) {
        /*--- BR28压缩算法 ---*/
        br28_btm_to_res_path((char*)[bmpPath UTF8String], width, height, (char*)[binPath UTF8String]);
        NSLog(@"--->Br28 BIN【%@】is OK!", @"bgp_w001");
    }else{
        /*--- BR23压缩算法 ---*/
        br23_btm_to_res_path((char*)[bmpPath UTF8String], width, height, (char*)[binPath UTF8String]);
        NSLog(@"--->Br23 BIN【%@】is OK!", @"bgp_w001");
    }
}

-(void)smallFileSyncContactsListWithPath:(NSString*)path and:(JL_ManagerM*) manager{
    
    [JL_Tools subTask:^{
        __block JLModel_SmallFile *smallFile = nil;
        
        /*--- 查询小文件列表 ---*/
        [manager.mSmallFileManager cmdSmallFileQueryType:JL_SmallFileTypeContacts
                                                  Result:^(NSArray<JLModel_SmallFile *> * _Nullable array) {
            if (array.count > 0) smallFile = array[0];
            NSLog(@"查询小文件列表");
        }];
        
        
        
        /*--- 先删通讯录 ---*/
        if (smallFile != nil) {
            __block JL_SmallFileOperate status_del = 0;
            [manager.mSmallFileManager cmdSmallFileDelete:smallFile
                                                         Result:^(JL_SmallFileOperate status) {
                status_del = status;
                NSLog(@"删通讯录");
            }];
            
            
            if (status_del != JL_SmallFileOperateSuceess) {
                [JL_Tools mainTask:^{
                    NSLog(@"--->小文件 CALL.TXT 传输失败");
                    
                }];
                return;
            }
        }
        
        /*--- 小文件传输文件 ---*/
        NSData *pathData = [NSData dataWithContentsOfFile:path];
        [manager.mSmallFileManager cmdSmallFileNew:pathData Type:JL_SmallFileTypeContacts
                                                  Result:^(JL_SmallFileOperate status, float progress,
                                                           uint16_t fileID) {
            
            NSLog(@"JL_SmallFileOperate状态：%hhu",status);
            [JL_Tools mainTask:^{
                
               
                if (status == JL_SmallFileOperateSuceess) {
                    NSLog(@"--->小文件 CALL.TXT 传输成功");
                   
                    self.status(@"1");
                }
                if (status != JL_SmallFileOperateSuceess &&
                    status != JL_SmallFileOperateDoing){
                    NSLog(@"--->小文件 CALL.TXT 传输失败");
                   
                    self.status(@"0");
                }
            }];
        }];
        
        
    }];
    
    
}
    
-(void)getContact:(JL_ManagerM*) manager {
//    dataArray = [NSMutableArray new];
    NSMutableData *mData = [NSMutableData new];
    
    JLModel_Device *deviceModel = [manager outputDeviceModel];
    
    if (deviceModel.smallFileWayType == JL_SmallFileWayTypeNO) {
        /*--- 原来通讯流程 ---*/
        [manager.mFileManager setCurrentFileHandleType:[JLFileTransferHelper getContactTargetDev:deviceModel]];
        [manager.mFileManager cmdFileReadContentWithName:@"CALL.txt" Result:^(JL_FileContentResult result,
                                                                                  uint32_t size, NSData * _Nullable
                                                                                  data,float progress) {
            if (result == JL_FileContentResultStart) {
                NSLog(@"---> 读取【Call.txt】开始.");
            } else if (result == JL_FileContentResultReading) {
                NSLog(@"---> 读取【Call.txt】Reading");
                if (data.length > 0) {
                    [mData appendData:data];
                }
            } else if(result == JL_FileContentResultEnd) {
                NSLog(@"---> 读取【Call.txt】结束");
                if (mData == nil || mData.length < 40) {
                    return;
                }
                [JL_Tools mainTask:^{
                    [self outputContactsListData:mData];
                    
                }];

            } else if (result == JL_FileContentResultCancel) {
                NSLog(@"---> 读取【Call.txt】取消");
            } else if (result == JL_FileContentResultFail) {
                NSLog(@"---> 读取【Call.txt】失败");
            } else if (result == JL_FileContentResultNull) {
                NSLog(@"---> 读取【Call.txt】文件为空");
            } else if (result == JL_FileContentResultDataError) {
                NSLog(@"---> 读取【Call.txt】数据出错");
            }
        }];
    }else{
        
        [JL_Tools subTask:^{
            __block JLModel_SmallFile *smallFile = nil;
            
            /*--- 查询小文件列表 ---*/
            [manager.mSmallFileManager cmdSmallFileQueryType:JL_SmallFileTypeContacts
                                                      Result:^(NSArray<JLModel_SmallFile *> * _Nullable array) {
                if (array.count > 0) smallFile = array[0];
                
            }];
            
            
            if (smallFile == nil) return;

            /*--- 读取小文件通讯录 ---*/
            [manager.mSmallFileManager cmdSmallFileRead:smallFile
                                                 Result:^(JL_SmallFileOperate status,
                                                          float progress, NSData * _Nullable data) {
                if (status == JL_SmallFileOperateDoing) {
                    NSLog(@"---> 小文件读取【Call.txt】开始：%lu",(unsigned long)data.length);
                }
                if (status != JL_SmallFileOperateDoing &&
                    status != JL_SmallFileOperateSuceess) {
                    NSLog(@"---> 小文件读取【Call.txt】失败~");
                }
                
                if (data.length > 0) [mData appendData:data];
                if (status == JL_SmallFileOperateSuceess) {
                    NSLog(@"---> 小文件读取【Call.txt】成功！");
                    if (mData.length >= 40) {
                        [JL_Tools mainTask:^{
                            [self outputContactsListData:mData];
                            
                        }];
                    }
                }
            }];
        }];
    }
}

-(void)outputContactsListData:(NSData*)mData{
    for (int i = 0; i <= mData.length - 40; i += 40) {
        NSData *buf_name = [JL_Tools data:mData R:i L:20];
        NSData *buf_number = [JL_Tools data:mData R:i+20 L:20];
        NSString *nameStr = [[NSString alloc] initWithData:buf_name encoding:NSUTF8StringEncoding];
        nameStr = [nameStr stringByReplacingOccurrencesOfString:@"\0" withString:@""];
        nameStr = [nameStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        NSString *numberStr = [[NSString alloc] initWithData:buf_number encoding:NSUTF8StringEncoding];
        numberStr = [numberStr stringByReplacingOccurrencesOfString:@"\0"withString:@""];
        numberStr = [numberStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        PersonModel *model = [[PersonModel alloc] init];
        model.fullName = nameStr;
        model.phoneNum = numberStr;
        
        NSLog(@"model.fullName:%@ ,model.phoneNum:%@",model.fullName,model.phoneNum);
    }
}
@end
