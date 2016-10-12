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
    
    [[ELExport sharedExport] synchronize];
    
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
    
    ESLog(@"STATUS;TYPE_1",@"test 1");
    ESLog(@"STATUS;TYPE_2",@"test 1");
    ESLog(@"STATUS;TYPE_3",[[ELExport sharedExport] logFilePath]);
    ESLog(@"STATUS;TYPE_4",@"test 1");
    ESLog(@"STATUS;TYPE_5",@"test 1");
    NSString *testString = [NSString stringWithFormat:@"%@;%@;%@;%d;\"%@\"",
                            @"STATUS;TYPE_6",
                            @"Test_String_1",
                            @"Test_String_2",
                            1000,
                            [[ELExport sharedExport] stringFromObject:@{
                                                                        @"test_key_1" :@"test_value_1",
                                                                        @"test_key_2" :@"test_value_2",
                                                                        @"test_key_3" :@3
                                                                        }
                                                             encoding:NSASCIIStringEncoding]];
    ESLog(testString,@"STATUS;TYPE_4");
    
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
    
    XCTAssertTrue([file.allLogs count] == randomCount,@"file logs count should be %ld : %ld",(long)randomCount,(unsigned long)[file.allLogs count]);
    
    ELELog *log_0 = [file.allLogs objectAtIndex:random()%randomCount];
    
    NSLog(@"%ld;%@;%@;%ld;\"%@\"",(long)log_0.index,log_0.file,log_0.function,(long)log_0.lineNumber,log_0.print);
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
    
    XCTAssertTrue([file.allLogs count] == randomCount,@"file logs count should be %ld : %ld",(long)(long)randomCount,(unsigned long)[file.allLogs count]);
    
    ELELog *log_0 = [file.allLogs objectAtIndex:random()%randomCount];
    
    NSLog(@"%ld;%@;%@;%@;%ld;\"%@\"",(long)log_0.index,log_0.status,log_0.file,log_0.function,(long)log_0.lineNumber,log_0.print);
}

@end
