//
//  ELogInstanceTests.m
//  ELog
//
//  Created by viktyz on 16/10/13.
//  Copyright © 2016年 AlfredJiang. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ELExport.h"

@interface ELogInstanceTests : XCTestCase

@property (nonatomic, strong) ELExport *export;

@end

@implementation ELogInstanceTests

- (void)setUp {
    
    if (!_export) {
        
        _export = [[ELExport alloc] initWithLogDirectoryName:@"InstanceELog" easyLogDirectoryName:@"InstanceEasyELog"];
    }
    
    [super setUp];
}

- (void)tearDown {
    
    [_export synchronize];
    
    [super tearDown];
}

- (void)testSynchronizeELog{
    
    ELog(@"test 1");
    ELog(@"test 2");
    ELog([_export logFilePath]);
    ELog(@"test 3");
    ELog(@"test 4");
    
    [_export synchronize];
}

- (void)testSynchronizeStatusELog{
    
    ESLog(@"STATUS;TYPE_1",@"test 1");
    ESLog(@"STATUS;TYPE_2",@"test 1");
    ESLog(@"STATUS;TYPE_3",[_export logFilePath]);
    ESLog(@"STATUS;TYPE_4",@"test 1");
    ESLog(@"STATUS;TYPE_5",@"test 1");
    NSString *testString = [NSString stringWithFormat:@"%@;%@;%@;%d;\"%@\"",
                            @"STATUS;TYPE_6",
                            @"Test_String_1",
                            @"Test_String_2",
                            1000,
                            [_export stringFromObject:@{
                                                                        @"test_key_1" :@"test_value_1",
                                                                        @"test_key_2" :@"test_value_2",
                                                                        @"test_key_3" :@3
                                                                        }
                                                             encoding:NSASCIIStringEncoding]];
    ESLog(testString,@"STATUS;TYPE_4");
    
    [_export synchronize];
}

- (void)testExportLogOperation {
    
    for (NSInteger i = 0; i < 50; i++) {
        
        [self logOperation:i];
    }
}

- (void)logOperation:(NSInteger)index
{
    [_export clearAllLogFiles];
    
    NSArray *files_0 = [_export allLogFiles];
    
    XCTAssertTrue([files_0 count] == 0,@"files_0 count should be 0");
    
    NSInteger randomCount = random() % 200 + 10;
    
    for (NSInteger i = 0; i < randomCount; i++) {
        
        ELog(@"%ld index %ld. Test String in %ld",index,i,randomCount);
    }
    
    NSArray *files_1 = [_export allLogFiles];
    
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
    [_export clearAllLogFiles];
    
    NSArray *files_0 = [_export allLogFiles];
    
    XCTAssertTrue([files_0 count] == 0,@"files_0 count should be 0");
    
    NSInteger randomCount = random() % 200 + 10;
    
    for (NSInteger i = 0; i < randomCount; i++) {
        
        ESLog(@"Status;Type_1;Type_2;Type_3;Type_4",@"%ld index %ld. Test String in %ld",index,i,randomCount);
    }
    
    NSArray *files_1 = [_export allLogFiles];
    
    XCTAssertTrue([files_1 count] == 1,@"files_1 count should be 1");
    
    ELEFile *file = [files_1 firstObject];
    
    XCTAssertTrue([file.allLogs count] == randomCount,@"file logs count should be %ld : %ld",(long)(long)randomCount,(unsigned long)[file.allLogs count]);
    
    ELELog *log_0 = [file.allLogs objectAtIndex:random()%randomCount];
    
    NSLog(@"%ld;%@;%@;%@;%ld;\"%@\"",(long)log_0.index,log_0.status,log_0.file,log_0.function,(long)log_0.lineNumber,log_0.print);
}

- (void)testEasyLog
{
    [_export clearAllEasyLogFiles];
    
    XCTAssertTrue([[[_export allEasyLogFiles] allKeys] count] == 0,@"easy files should be empty after clear all files");
    
    NSInteger iCount = 10;
    
    for (NSInteger index = 0; index < iCount ; index ++) {
        
        NSString *easyLogPath = [_export easyWriteString:[NSString stringWithFormat:@"Test_Info_%ld",(long)index] toFile:[NSString stringWithFormat:@"Test_File_%ld",(long)index]];
        
        ESLog([_export easyLogDirectoryPath],easyLogPath);
    }
    
    XCTAssertTrue([[[_export allEasyLogFiles] allKeys] count] == iCount,@"easy files count should be equal to filename's count");
}

@end