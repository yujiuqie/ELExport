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
        
        if ([items_0 count] < 3) {
            
            return self;
        }
        
        //Index , Status , Function , Line
        NSString *preInfo = [items_0 firstObject];
        NSArray *items_1 = [preInfo componentsSeparatedByString:@";"];
        
        if ([items_1 count] == 3) { //Normal : ELog
            
            _index = [[items_1 objectAtIndex:0] integerValue];
            _function = [items_1 objectAtIndex:1];
            _lineNumber = [[items_1 objectAtIndex:2] integerValue];
        }
        else{   //With Status : ESLog
            
            NSInteger tCount = [items_1 count];
            
            _index = [[items_1 objectAtIndex:0] integerValue];
            _status = [[items_1 subarrayWithRange:NSMakeRange(1, (tCount - 3))] componentsJoinedByString:@";"];
            _function = [items_1 objectAtIndex:(tCount - 2)];
            _lineNumber = [[items_1 objectAtIndex:(tCount - 1)] integerValue];
        }
        
        NSString *pInfo = [items_0 objectAtIndex:1];
        _print = [pInfo substringWithRange:NSMakeRange(0, [pInfo length] - 1)];
        
        _file = [items_0 objectAtIndex:2];
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
        
        NSMutableArray<ELELog *> *logs = [NSMutableArray array];
        
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
@property (nonatomic, strong) NSRecursiveLock *rwLock;
@property (nonatomic, strong) NSString *logFilePath;
@property (nonatomic, assign, readwrite) BOOL enbaleElog;
@property (nonatomic, strong) NSDateFormatter *formatter;

@end

@implementation ELExport

+ (void)load
{
    [[ELExport sharedExport] registerMainRunloopObserver];
}

+ (instancetype)sharedExport{
    
    static ELExport *_sharedExport = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        _sharedExport = [[ELExport alloc] init];
        _sharedExport.tempInfos = [NSMutableArray array];
        _sharedExport.rwLock = [[NSRecursiveLock alloc] init];
        _sharedExport.enbaleElog = YES;
        _sharedExport.stringEncoding = NSUTF8StringEncoding;
        _sharedExport.maxTempLineCount = 25;
    });
    
    return _sharedExport;
}

- (instancetype)initWithLogDirectoryName:(NSString *)directoryName
                    easyLogDirectoryName:(NSString *)easyDirectoryName
{
    self = [super init];
    
    if (self) {
        
        _tempInfos = [NSMutableArray array];
        _rwLock = [[NSRecursiveLock alloc] init];
        _enbaleElog = YES;
        _stringEncoding = NSUTF8StringEncoding;
        _maxTempLineCount = 25;
        _exportDirectoryName = directoryName;
        _easyExportDirectoryName = easyDirectoryName;
        [self registerMainRunloopObserver];
    }
    
    return self;
}

- (void)enableELog:(BOOL)enable
{
    _enbaleElog = enable;
}

- (NSString *)exportDirectoryName
{
    return _exportDirectoryName ? _exportDirectoryName : @"ELog";
}

- (NSString *)easyExportDirectoryName
{
    return _easyExportDirectoryName ? _easyExportDirectoryName : @"Easy_Export";
}

- (NSDateFormatter *)formatter
{
    if (!_formatter) {
        
        _formatter = [[NSDateFormatter alloc] init];
        [_formatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"]];
        [_formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    }
    
    return _formatter;
}

- (NSString *)exportFileName
{
    if (!_exportFileName) {
        
        _exportFileName = [self.formatter stringFromDate:[NSDate date]];
    }
    
    return _exportFileName;
}

- (NSString *)exportFileType
{
    return _exportFileType ? _exportFileType : @"csv";
}

#pragma mark -

- (NSString*)stringFromObject:(id)object encoding:(NSStringEncoding)encoding
{
    if (!object || ![NSJSONSerialization isValidJSONObject:object]) {
        
        return @"";
    }
    
    NSString *jsonString = @"";
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:object
                                                       options:0
                                                         error:&error];
    
    if (error) {
        
        NSLog(@"jsonData Error : %@",error);
    }
    
    if (jsonData){
        
        jsonString = [[NSString alloc] initWithData:jsonData encoding:encoding];
    }
    
    return jsonString;
}

- (NSString *)easyWriteString:(NSString *)string
                       toFile:(NSString *)fileName
{
    if (!string || [string length] == 0) {
        
        return @"";
    }
    
    NSString *targetFileName = fileName;
    
    if (!targetFileName) {
        
        targetFileName = [NSString stringWithFormat:@"E_%@",[self exportFileName]];
    }
    
    NSString *defaultPath = [self pathWithDirectoryName:self.easyExportDirectoryName FileName:targetFileName fileType:@"txt"];
    
    [_rwLock lock];
    
    [self writeLines:@[@"==========================================",
                       [NSString stringWithFormat:@"Easy Log : %@ ",[self.formatter stringFromDate:[NSDate date]]],
                       string]
              toPath:defaultPath];
    
    [_rwLock unlock];
    
    return defaultPath;
}

#pragma mark -

- (void)file:(char*)source function:(char*)functionName lineNumber:(NSInteger)lineNumber formatString:(NSString*)formatString, ...
{
    [_rwLock lock];
    va_list args;
    va_start(args,formatString);
    NSString *print = [[NSString alloc] initWithFormat:formatString arguments:args];
    va_end(args);
    
    NSLog(@"%@",print);
    
    if (!_enbaleElog) {
        
        return;
    }
    
    NSString *file = [[NSString alloc] initWithBytes:source length:strlen(source) encoding:_stringEncoding];
    NSString *function = [NSString stringWithCString:functionName encoding:_stringEncoding];
    index++;
    [self writeLine:[NSString stringWithFormat:@"%ld;%@;%ld;\"%@\";\"%@\"",(long)index,function,(long)lineNumber,print,file]];
    [_rwLock unlock];
}

- (void)file:(char*)source status:(NSString *)status function:(char*)functionName lineNumber:(NSInteger)lineNumber formatString:(NSString*)formatString, ...
{
    [_rwLock lock];
    va_list args;
    va_start(args,formatString);
    NSString *print = [[NSString alloc] initWithFormat:formatString arguments:args];
    va_end(args);
    
    NSLog(@"%@ : %@",status,print);
    
    if (!_enbaleElog) {
        
        return;
    }
    
    NSString *file = [[NSString alloc] initWithBytes:source length:strlen(source) encoding:_stringEncoding];
    NSString *function = [NSString stringWithCString: functionName encoding:_stringEncoding];
    index++;
    [self writeLine:[NSString stringWithFormat:@"%ld;%@;%@;%ld;\"%@\";\"%@\"",(long)index,status,function,(long)lineNumber,print,file]];
    [_rwLock unlock];
}

#pragma mark -

- (void)writeLine:(NSString *)line{
    
    [_tempInfos addObject:line];
    
    if ([_tempInfos count] >= self.maxTempLineCount) {
        
        [self synchronize];
    }
}

- (NSString *)logDirectory:(NSString *)directoryName
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *logDirectory = [[paths objectAtIndex:0] stringByAppendingPathComponent:directoryName];
    
    return logDirectory;
}

- (NSString *)pathWithDirectoryName:(NSString *)directoryName
                           FileName:(NSString *)fileName
                           fileType:(NSString *)fileType
{
    if (!fileName || !fileType) {
        
        return @"";
    }
    
    NSString *logDirectory = [self logDirectory:directoryName];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL fileExists = [fileManager fileExistsAtPath:logDirectory];
    
    if (!fileExists) {
        
        [fileManager createDirectoryAtPath:logDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return [logDirectory stringByAppendingFormat:@"/%@.%@",fileName,fileType];
}

#pragma mark -

- (NSString *)logFilePath{
    
    if (!_logFilePath) {
        
        _logFilePath = [self pathWithDirectoryName:self.exportDirectoryName FileName:self.exportFileName fileType:self.exportFileType];
        
        NSLog(@"ELog Export Path : %@",_logFilePath);
    }
    
    return _logFilePath;
}

- (NSArray<ELEFile *> *)allLogFiles
{
    [self synchronize];
    
    NSString *logDirectory = [self logDirectory:[self exportDirectoryName]];
    
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
    
    NSString *logDirectory = [self logDirectory:[self exportDirectoryName]];
    
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

#pragma mark -

- (NSString *)easyLogDirectoryPath
{
    return [self logDirectory:[self easyExportDirectoryName]];
}

- (NSDictionary *)allEasyLogFiles
{
    NSString *logDirectory = [self easyLogDirectoryPath];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    BOOL fileExists = [fileManager fileExistsAtPath:logDirectory];
    
    if (!fileExists) {
        
        return @{};
    }
    
    [_rwLock lock];
    
    NSArray<NSString *> *items = [fileManager contentsOfDirectoryAtPath:logDirectory error:nil];
    
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    
    [items enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        NSString *path = [logDirectory stringByAppendingFormat:@"/%@",obj];
        
        NSStringEncoding encoding;
        NSError *error = nil;
        NSString *strInfo = [NSString stringWithContentsOfFile:path usedEncoding:&encoding error:&error];
        
        if (!error) {
            
            [result setObject:strInfo forKey:obj];
        }
    }];
    
    [_rwLock unlock];
    
    return result;
}

- (void)clearAllEasyLogFiles{
    
    NSString *logDirectory = [self easyLogDirectoryPath];
    
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

#pragma mark -

- (void)synchronize
{
    if ([_tempInfos count] == 0) {
        
        return;
    }
    
    [_rwLock lock];
    __block NSArray *needWriteLines = [_tempInfos copy];
    [_tempInfos removeAllObjects];
    [_rwLock unlock];
    
    [self writeLines:needWriteLines toPath:[self logFilePath]];
    needWriteLines = nil;
}

#pragma mark -

- (void)writeLines:(NSArray *)lines toPath:(NSString *)path
{
    if ([lines count] == 0 || !path || [path length] == 0) {
        
        return;
    }
    
    NSFileHandle *outFile = [NSFileHandle fileHandleForWritingAtPath:path];
    
    if (!outFile) {
        
        NSFileManager *fm = [NSFileManager defaultManager];
        
        NSString * result = [lines componentsJoinedByString:@"\n"];
        NSData *buffer = [result dataUsingEncoding:_stringEncoding];
        
        [fm createFileAtPath:path contents:buffer attributes:nil];
    }
    else{
        
        NSString * result = [NSString stringWithFormat:@"\n%@",[[lines valueForKey:@"description"] componentsJoinedByString:@"\n"]];
        NSData *buffer = [result dataUsingEncoding:_stringEncoding];
        
        [outFile seekToEndOfFile];
        [outFile writeData:buffer];
        [outFile closeFile];
    }
}

#pragma mark -

static void runLoopObserverCallback(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info){
    
    if (activity == kCFRunLoopBeforeWaiting) {
        
        [[ELExport sharedExport] synchronize];
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
