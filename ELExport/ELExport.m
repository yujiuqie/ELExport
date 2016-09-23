//
//  ELExport.m
//  ELog
//
//  Created by viktyz on 16/9/21.
//  Copyright © 2016年 AlfredJiang. All rights reserved.
//

#import "ELExport.h"
#import <objc/runtime.h>

@implementation ELELog

- (instancetype)initWithInfo:(NSString *)info
{
    self = [super init];
    
    if (self) {
        
        NSArray *items_0 = [info componentsSeparatedByString:@";\""];
        
        if ([items_0 count] != 2) {
            
            return self;
        }
        
        NSString *preInfo = [items_0 firstObject];
        NSArray *items_1 = [preInfo componentsSeparatedByString:@";"];
        
        if ([items_1 count] != 4) {
            
            return self;
        }
        
        _print = [items_0 lastObject];
        
        _index = [[items_1 objectAtIndex:0] integerValue];
        _file = [items_1 objectAtIndex:1];
        _function = [items_1 objectAtIndex:2];
        _lineNumber = [[items_1 objectAtIndex:3] integerValue];
    }
    return self;
}

@end

@implementation ELEFile

- (instancetype)initWithPath:(NSString *)path
{
    self = [super init];
    
    if (self) {
        
        _path = path;
        _name = [path lastPathComponent];
        
        NSStringEncoding encoding;
        NSError *error = nil;
        NSString *strInfo = [NSString stringWithContentsOfFile:_path usedEncoding:&encoding error:&error];
        
        if (error) {
            
            NSLog(@"\n%lu\n%@",(unsigned long)encoding,error);
            
            return self;
        }
        
        NSArray<NSString *> *lines = [strInfo componentsSeparatedByString:@"\"\n"];
        
        NSMutableArray *logs = [NSMutableArray array];
        
        [lines enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            ELELog *log = [[ELELog alloc] initWithInfo:obj];
            log.path = path;
            [logs addObject:log];
        }];
        
        _allLogs = logs;
    }
    
    return self;
}

@end

@interface ELExport()
{
    CFRunLoopRef runLoop;
    NSInteger index;
}

@property (nonatomic, strong) NSMutableArray *tempInfos;
@property (nonatomic, strong) NSLock *rwLock;
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
        
        _sharedExport.rwLock = [[NSLock alloc] init];
        
        [_sharedExport registerMainRunloopObserver];
    });
    
    return _sharedExport;
}

- (void)file:(char*)source function:(char*)functionName lineNumber:(NSInteger)lineNumber formatString:(NSString*)formatString, ...
{
    [_rwLock lock];
    va_list args;
    va_start(args,formatString);
    NSString *print = [[NSString alloc] initWithFormat:formatString arguments:args];
    va_end(args);
    
    NSLog(@"%@",print);
    
    NSString *file = [[NSString alloc] initWithBytes:source length:strlen(source) encoding:NSUTF8StringEncoding];
    NSString *function = [NSString stringWithCString: functionName encoding:NSUTF8StringEncoding];
    index++;
    [self writeLine:[NSString stringWithFormat:@"%ld;%@;%@;%ld;\"%@\"",(long)index,file,function,(long)lineNumber,print]];
    [_rwLock unlock];
}

- (void)writeLine:(NSString *)line{
    
    [_tempInfos addObject:line];
    
    if ([_tempInfos count] >= ELog_Max_Temp_Line_Count) {
        
        [self save];
    }
}

- (NSString *)logDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *logDirectory = [[paths objectAtIndex:0] stringByAppendingPathComponent:ELOG_EXPORT_DIRECTORY_NAME];
    
    return logDirectory;
}

- (NSString *)logFilePath{
    
    if (!_logFilePath) {
        
        NSString *logDirectory = [self logDirectory];
        
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

- (NSArray<ELEFile *> *)allLogFiles
{
    [self synchronize];
    
    NSString *logDirectory = [self logDirectory];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    BOOL fileExists = [fileManager fileExistsAtPath:logDirectory];
    
    if (!fileExists) {
        
        return @[];
    }
    
    [_rwLock lock];
    
    NSArray<NSString *> *items = [fileManager contentsOfDirectoryAtPath:logDirectory error:nil];
    
    NSMutableArray<ELEFile *> *result = [NSMutableArray array];
    
    [items enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        NSString *path = [logDirectory stringByAppendingFormat:@"/%@",obj];
        
        ELEFile *model = [[ELEFile alloc] initWithPath:path];
        
        if ([model.allLogs count] != 0) {
            
            [result addObject:model];
        }
    }];
    
    [_rwLock unlock];
    
    return result;
}

- (void)clearAllLogFiles{
    
    [self synchronize];
    
    NSString *logDirectory = [self logDirectory];
    
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
    
    [self.writeQueue addOperationWithBlock:^{
        
        [self synchronize];
    }];
}

- (void)synchronize
{
    if ([_tempInfos count] == 0) {
        
        return;
    }
    
    [_rwLock lock];
    __block NSArray *needWriteLines = [_tempInfos copy];
    [_tempInfos removeAllObjects];
    [_rwLock unlock];
    
    [self writeLines:needWriteLines];
    needWriteLines = nil;
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
        
        NSString * result = [NSString stringWithFormat:@"\n%@",[[lines valueForKey:@"description"] componentsJoinedByString:@"\n"]];
        NSData *buffer = [result dataUsingEncoding:NSUTF8StringEncoding];
        
        [outFile seekToEndOfFile];
        [outFile writeData:buffer];
        [outFile closeFile];
    }
}

#pragma mark -

- (NSOperationQueue *)writeQueue
{
    if (!_writeQueue)
    {
        _writeQueue = [[NSOperationQueue alloc] init];
        [_writeQueue setSuspended:YES];
        [_writeQueue setMaxConcurrentOperationCount:1];
    }
    
    return _writeQueue;
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
