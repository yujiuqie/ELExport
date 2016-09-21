//
//  ELExport.m
//  ELog
//
//  Created by viktyz on 16/9/21.
//  Copyright © 2016年 AlfredJiang. All rights reserved.
//

#import "ELExport.h"
#import <objc/runtime.h>

@interface ELExport()
{
    CFRunLoopRef runLoop;
    NSInteger index;
}

@property (nonatomic, strong) NSMutableArray *tempInfos;
@property (nonatomic, strong) NSLock *writeLock;
@property (nonatomic, strong) NSOperationQueue *writeQueue;
@property (nonatomic, strong) NSString *logFilePath;

@end

@implementation ELExport

+ (instancetype)sharedExport{
    
    static ELExport *_sharedExport = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        _sharedExport = [[ELExport alloc] init];
        
        _sharedExport.tempInfos = [NSMutableArray array];
        
        _sharedExport.writeQueue = [[NSOperationQueue alloc] init];
        _sharedExport.writeQueue.maxConcurrentOperationCount = 1;
        
        _sharedExport.writeLock = [[NSLock alloc] init];
        
        [_sharedExport registerMainRunloopObserver];
    });
    
    return _sharedExport;
}

- (void)file:(char*)source function:(char*)functionName lineNumber:(NSInteger)lineNumber formatString:(NSString*)formatString, ...
{
    va_list args;
    va_start(args,formatString);
    NSString *print = [[NSString alloc] initWithFormat:formatString arguments:args];
    va_end(args);
    
    [_writeQueue addOperationWithBlock:^{
        
        NSString *file = [[NSString alloc] initWithBytes:source length:strlen(source) encoding:NSUTF8StringEncoding];
        NSString *function = [NSString stringWithCString: functionName encoding:NSUTF8StringEncoding];
        index++;
        [self writeLine:[NSString stringWithFormat:@"%ld;%@;%@;%ld;%@",index,file,function,lineNumber,print]];
    }];
}

- (void)writeLine:(NSString *)line{
    
    [_writeLock lock];
    [_tempInfos addObject:line];
    [_writeLock unlock];
    
    if ([_tempInfos count] >= ELog_Max_Temp_Line_Count) {
        
        [self save];
    }
}

- (NSString *)logFilePath{
    
    if (!_logFilePath) {
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *logDirectory = [[paths objectAtIndex:0] stringByAppendingPathComponent:ELOG_EXPORT_DIRECTORY_NAME];
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL fileExists = [fileManager fileExistsAtPath:logDirectory];
        
        if (!fileExists) {
            
            [fileManager createDirectoryAtPath:logDirectory withIntermediateDirectories:YES attributes:nil error:nil];
        }
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"]];
        [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        NSString *dateStr = [formatter stringFromDate:[NSDate date]];
        _logFilePath = [logDirectory stringByAppendingFormat:@"/%@.%@",dateStr,ELog_Export_File_Type];
        
        NSLog(@"ELog Export Path : %@",_logFilePath);
    }
    
    return _logFilePath;
}

- (void)clearAllLogs{
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *logDirectory = [[paths objectAtIndex:0] stringByAppendingPathComponent:ELOG_EXPORT_DIRECTORY_NAME];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL fileExists = [fileManager fileExistsAtPath:logDirectory];
    
    if (!fileExists) {
        
        return;
    }
    
    NSArray<NSString *> *items = [fileManager contentsOfDirectoryAtPath:logDirectory error:nil];
    
    [items enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        [fileManager removeItemAtPath:[logDirectory stringByAppendingFormat:@"/%@",obj] error:nil];
    }];
}

- (void)save{
    
    if ([_tempInfos count] == 0) {
        
        return;
    }
    
    NSLog(@"保存文件");
    
    [_writeLock lock];
    __block NSArray *needWriteLines = [_tempInfos copy];
    [_tempInfos removeAllObjects];
    [_writeLock unlock];
    
    [_writeQueue addOperationWithBlock:^{
        
        [self writeLines:needWriteLines];
        needWriteLines = nil;
    }];
}

#pragma mark -

- (void)writeLines:(NSArray *)lines
{
    if ([lines count] == 0) {
        
        return;
    }
    
    NSFileHandle *outFile = [NSFileHandle fileHandleForWritingAtPath:[self logFilePath]];
    
    if (!outFile) {
        
        NSFileManager *fm = [NSFileManager defaultManager];
        
        NSString * result = [lines componentsJoinedByString:@"\n"];
        NSData *buffer = [result dataUsingEncoding:NSUTF8StringEncoding];
        
        [fm createFileAtPath:[self logFilePath] contents:buffer attributes:nil];
    }
    else{
        
        NSLog(@"写入文件");
        
        NSString * result = [NSString stringWithFormat:@"\n%@",[[lines valueForKey:@"description"] componentsJoinedByString:@"\n"]];
        NSData *buffer = [result dataUsingEncoding:NSUTF8StringEncoding];
        
        [outFile seekToEndOfFile];
        [outFile writeData:buffer];
        [outFile closeFile];
    }
}

#pragma mark -

static void runLoopObserverCallback(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info){
    
    if (activity == kCFRunLoopBeforeWaiting) {
        
        [[ELExport sharedExport] save];
    }
}

- (void)registerMainRunloopObserver{
    
    static CFRunLoopObserverRef observer;
    runLoop = CFRunLoopGetCurrent();
    CFOptionFlags activities = kCFRunLoopBeforeWaiting;
    CFRunLoopObserverContext context = {
        0,
        (__bridge void *)@"MainRunloopObserver",
        &CFRetain,
        &CFRelease,
        NULL
    };
    
    observer = CFRunLoopObserverCreate(NULL,
                                       activities,
                                       YES,
                                       INT_MAX,
                                       &runLoopObserverCallback,
                                       &context);
    CFRunLoopAddObserver(runLoop, observer, kCFRunLoopDefaultMode);
    
    CFRelease(observer);
}

@end
