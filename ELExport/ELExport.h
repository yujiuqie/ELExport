//
//  ELExport.h
//  ELog
//
//  Created by viktyz on 16/9/21.
//  Copyright © 2016年 AlfredJiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ELConfig.h"

#ifdef ELOG_OPEN
#define ELog(s, ...) [[ELExport sharedExport] file:__FILE__ function: (char *)__FUNCTION__ lineNumber:__LINE__ formatString:(s),##__VA_ARGS__]
#else
#define ELog(s, ...) {}
#endif

@interface ELELog : NSObject

@property (nonatomic, strong) NSString *path;
@property (nonatomic, assign) NSInteger index;
@property (nonatomic, strong) NSString *file;
@property (nonatomic, strong) NSString *function;
@property (nonatomic, assign) NSInteger lineNumber;
@property (nonatomic, strong) NSString *print;

- (instancetype)initWithInfo:(NSString *)info;

@end

@interface ELEFile : NSObject

@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSArray<ELELog *> *allLogs;

- (instancetype)initWithPath:(NSString *)path;

@end

@interface ELExport : NSObject

+ (instancetype)sharedExport;

- (void)file:(char*)source function:(char*)functionName lineNumber:(NSInteger)lineNumber formatString:(NSString*)formatString, ...;

- (void)synchronize;

- (NSString *)logFilePath;

- (NSArray<ELEFile *> *)allLogFiles;

- (void)clearAllLogFiles;

@end
