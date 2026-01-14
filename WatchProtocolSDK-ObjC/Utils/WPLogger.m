//
//  WPLogger.m
//  WatchProtocolSDK-ObjC
//
//  Created by Claude on 2026/01/12.
//  Copyright © 2026 Huaxin. All rights reserved.
//

#import "WPLogger.h"

@interface WPLogger ()

@property (nonatomic, strong) NSURL *logFileURL;
@property (nonatomic, strong) NSFileHandle *fileHandle;
@property (nonatomic, strong) NSLock *lock;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@end

@implementation WPLogger

+ (instancetype)sharedInstance {
    static WPLogger *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // 初始化锁
        _lock = [[NSLock alloc] init];

        // 获取文档目录
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = paths.firstObject;
        _logFileURL = [NSURL fileURLWithPath:[documentsDirectory stringByAppendingPathComponent:@"watchprotocol_log.txt"]];

        // 删除旧日志文件
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:_logFileURL.path]) {
            NSError *error = nil;
            [fileManager removeItemAtURL:_logFileURL error:&error];
            if (error && error.code != NSFileNoSuchFileError) {
                NSLog(@"删除日志文件时发生错误: %@", error);
            }
        }

        // 创建新空文件
        [@"" writeToURL:_logFileURL atomically:NO encoding:NSUTF8StringEncoding error:nil];

        // 打开文件句柄
        NSError *error = nil;
        _fileHandle = [NSFileHandle fileHandleForWritingToURL:_logFileURL error:&error];
        if (error) {
            NSLog(@"无法初始化日志文件: %@", error);
        } else {
            [_fileHandle seekToEndOfFile];
        }

        // 初始化日期格式化器
        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss.SSS";
        _dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    }
    return self;
}

- (void)log:(NSString *)message {
    // 1. 输出到控制台
    NSLog(@"%@", message);

    // 2. 写入日志文件（线程安全）
    [self.lock lock];

    NSString *timestamp = [self.dateFormatter stringFromDate:[NSDate date]];
    NSString *logMessage = [NSString stringWithFormat:@"[%@] %@\n", timestamp, message];
    NSData *data = [logMessage dataUsingEncoding:NSUTF8StringEncoding];

    if (data) {
        @try {
            if (self.fileHandle) {
                [self.fileHandle writeData:data];
            } else {
                // 如果文件句柄失效，直接写入
                [data writeToURL:self.logFileURL options:NSDataWritingAtomic error:nil];
            }
        } @catch (NSException *exception) {
            NSLog(@"写入日志文件失败: %@", exception);
        }
    }

    [self.lock unlock];
}

- (NSString *)logFilePath {
    return self.logFileURL.path;
}

- (void)dealloc {
    [self.fileHandle closeFile];
}

@end
