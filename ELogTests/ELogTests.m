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

- (void)testSynchronizeELog{
    
    ELog(@"test 1");
    ELog(@"test 2");
    ELog([[ELExport sharedExport] logFilePath]);
    ELog(@"test 3");
    ELog(@"test 4");
    
    [[ELExport sharedExport] synchronize];
}

- (void)testSynchronizeStatusELog{
    
    ELog(@"STATUS;TYPE_1",@"test 1");
    ELog(@"STATUS;TYPE_2");
    ELog([[ELExport sharedExport] logFilePath]);
    ELog(@"STATUS;TYPE_3");
    ELog(@"STATUS;TYPE_4");
    
    [[ELExport sharedExport] synchronize];
}

- (void)testExportLogOperation {
    
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

- (void)testExportStatusLogOperation {
    
    for (NSInteger i = 0; i < 50; i++) {
        
        [self statusLogOperation:i];
    }
}

- (void)statusLogOperation:(NSInteger)index
{
    [[ELExport sharedExport] clearAllLogFiles];
    
    NSArray *files_0 = [[ELExport sharedExport] allLogFiles];
    
    XCTAssertTrue([files_0 count] == 0,@"files_0 count should be 0");
    
    NSInteger randomCount = random() % 200 + 10;
    
    for (NSInteger i = 0; i < randomCount; i++) {
        
        ESLog(@"Status;Type_1;Type_2;Type_3;Type_4",@"%ld index %ld. Test String in %ld",index,i,randomCount);
    }
    
    NSArray *files_1 = [[ELExport sharedExport] allLogFiles];
    
    XCTAssertTrue([files_1 count] == 1,@"files_1 count should be 1");
    
    ELEFile *file = [files_1 firstObject];
    
    XCTAssertTrue([file.allLogs count] == randomCount,@"file logs count should be %ld : %ld",randomCount,[file.allLogs count]);
    
    ELELog *log_0 = [file.allLogs objectAtIndex:random()%randomCount];
    
    NSLog(@"%ld;%@;%@;%@;%ld;\"%@\"",log_0.index,log_0.status,log_0.file,log_0.function,log_0.lineNumber,log_0.print);
}

@end
