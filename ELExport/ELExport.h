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

@interface ELExport : NSObject

+ (instancetype)sharedExport;

- (void)file:(char*)source function:(char*)functionName lineNumber:(NSInteger)lineNumber formatString:(NSString*)formatString, ...;

- (NSString *)logFilePath;

- (void)clearAllLogs;

@end
