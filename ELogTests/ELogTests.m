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
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testAdd {

    for (NSInteger i = 0; i < 1000; i++) {
        
        ELog(@"%ld. Test String",i);
    }
}

@end
