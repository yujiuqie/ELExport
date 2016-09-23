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
    
    [[ELExport sharedExport] clearAllLogFiles];
    
    NSArray *files_0 = [[ELExport sharedExport] allLogFiles];
    
    XCTAssertTrue([files_0 count] == 0,@"files_0 count should be 0");
}

- (void)tearDown {
    
    [[ELExport sharedExport] clearAllLogFiles];
    
    NSArray *files_2 = [[ELExport sharedExport] allLogFiles];
    
    XCTAssertTrue([files_2 count] == 0,@"files_2 count should be 0");
    
    [super tearDown];
}

- (void)testELExport {

    for (NSInteger i = 0; i < 1000; i++) {
        
        ELog(@"%ld. Test String",i);
    }
    
    NSArray *files_1 = [[ELExport sharedExport] allLogFiles];
    
    XCTAssertTrue([files_1 count] == 1,@"files_1 count should be 1");
    
    ELEFile *file = [files_1 firstObject];
    
    XCTAssertTrue([file.allLogs count] == 1000,@"file logs count should be 1000 : %ld",[file.allLogs count]);
    
    ELELog *log_0 = [file.allLogs objectAtIndex:0];
    
    NSLog(@"%ld;%@;%@;%ld;\"%@\"",log_0.index,log_0.file,log_0.function,log_0.lineNumber,log_0.print);
}

@end
