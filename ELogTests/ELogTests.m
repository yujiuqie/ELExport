//
//  ELogTests.m
//  ELogTests
//
//  Created by viktyz on 16/9/21.
//  Copyright © 2016年 AlfredJiang. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ELExport.h"

@interface ELogTests : XCTestCase

@end

@implementation ELogTests

- (void)setUp {
    
    [super setUp];
}

- (void)tearDown {
    
    [super tearDown];
}

- (void)testELExport {
    
    for (NSInteger i = 0; i < 50; i++) {
        
        [self logOperation:i];
    }
}

- (void)logOperation:(NSInteger)index
{
    [[ELExport sharedExport] clearAllLogFiles];
    
    NSArray *files_0 = [[ELExport sharedExport] allLogFiles];
    
    XCTAssertTrue([files_0 count] == 0,@"files_0 count should be 0");
    
    NSInteger randomCount = random() % 200 + 10;
    
    for (NSInteger i = 0; i < randomCount; i++) {
        
        ELog(@"%ld index %ld. Test String in %ld",index,i,randomCount);
    }
    
    NSArray *files_1 = [[ELExport sharedExport] allLogFiles];
    
    XCTAssertTrue([files_1 count] == 1,@"files_1 count should be 1");
    
    ELEFile *file = [files_1 firstObject];
    
    XCTAssertTrue([file.allLogs count] == randomCount,@"file logs count should be %ld : %ld",randomCount,[file.allLogs count]);
    
    ELELog *log_0 = [file.allLogs objectAtIndex:random()%randomCount];
    
    NSLog(@"%ld;%@;%@;%ld;\"%@\"",log_0.index,log_0.file,log_0.function,log_0.lineNumber,log_0.print);
}

@end
