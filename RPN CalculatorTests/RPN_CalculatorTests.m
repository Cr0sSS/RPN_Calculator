//
//  RPN_CalculatorTests.m
//  RPN CalculatorTests
//
//  Created by Admin on 17.01.17.
//  Copyright © 2017 Andrey Kuznetsov. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>

#import "CalculationManager.h"

@interface RPN_CalculatorTests : XCTestCase

@end

@implementation RPN_CalculatorTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}


- (void)testDivideByZeroException {
    TestCalculationManager* manager = [TestCalculationManager new];
    
    NSString* notificationName = @"CalculationError";
    NSString* expectedMessage = @"Деление на ноль невозможно";
    
    [[NSNotificationCenter defaultCenter]
     addObserverForName:notificationName
     object:nil
     queue:nil
     usingBlock:^(NSNotification * _Nonnull note) {
         
         NSString* message = note.userInfo[@"message"];
         XCTAssertEqualObjects(message, expectedMessage);
     }];
    
    NSArray* zeroArray = @[@8, @0, @"/"];
    double zeroResult = [manager calculateRPNExpression:[zeroArray mutableCopy]];
    
    XCTAssertEqual(zeroResult * 2, zeroResult);
    XCTAssertNotEqual(zeroResult, 0);
    
    NSArray* zeroByZeroArray = @[@0, @0, @"/"];
    double zeroByZeroResult = [manager calculateRPNExpression:[zeroByZeroArray mutableCopy]];
    
    XCTAssertNotEqual(zeroByZeroResult, zeroByZeroResult);
}


- (void)testUnaryMinus {
    TestCalculationManager* manager = [TestCalculationManager new];
    
    NSDictionary* dict = [manager calculateExpression:@"8--3"];
    double result = [dict[@"result"] doubleValue];
    
    XCTAssertEqual(result, 11.f);
    
    NSDictionary* bracketsDict = [manager calculateExpression:@"8--3"];
    double resultInBrackets = [bracketsDict[@"result"] doubleValue];
    
    XCTAssertEqual(resultInBrackets, 11.f);
}


- (void)testUnaryMinusAfterBrackets {
    TestCalculationManager* manager = [TestCalculationManager new];
    
    NSDictionary* firstDict = [manager calculateExpression:@"(11+2)-3"];
    double firstResult = [firstDict[@"result"] doubleValue];
    
    XCTAssertEqual(firstResult, 10.f);
    
    NSDictionary* secondDict = [manager calculateExpression:@"(11+2)--3"];
    double secondResult = [secondDict[@"result"] doubleValue];
    
    XCTAssertEqual(secondResult, 16.f);
    
    NSDictionary* thirdDict = [manager calculateExpression:@"(9+3)/-4"];
    double thirdResult = [thirdDict[@"result"] doubleValue];
    
    XCTAssertEqual(thirdResult, -3.f);
}


- (void)testLastSymbolOperator {
    TestCalculationManager* manager = [TestCalculationManager new];
    
    NSString* notificationName = @"CalculationError";
    
    NSString* countsMessage = @"Неверная запись выражения:\nПроверьте количество операндов и знаков операций";
    NSString* lastSymbolMessage = @"Неверная запись выражения:\nВыражение не может заканчиваться знаком операции";
    
    [[NSNotificationCenter defaultCenter]
     addObserverForName:notificationName
     object:nil
     queue:nil
     usingBlock:^(NSNotification * _Nonnull note) {
         
         NSString* message = note.userInfo[@"message"];
         
         if (![message isEqualToString:countsMessage] && ![message isEqualToString:lastSymbolMessage]) {
             XCTFail();
         }
     }];
    
    [manager calculateExpression:@"4+2-"];
}


- (void)testFloatFromDotPointers {
    TestCalculationManager* manager = [TestCalculationManager new];
    
    NSDictionary* firstDict = [manager calculateExpression:@"4.25+2"];
    double firstResult = [firstDict[@"result"] doubleValue];
    
    XCTAssertEqualWithAccuracy(firstResult, 6.25f, 0.001f);
    
    NSDictionary* secondDict = [manager calculateExpression:@"8,55-3"];
    double secondResult = [secondDict[@"result"] doubleValue];
    
    XCTAssertEqualWithAccuracy(secondResult, 5.55f, 0.001f);
}


- (void)testPriority {
    TestCalculationManager* manager = [TestCalculationManager new];
    
    NSDictionary* firstDict = [manager calculateExpression:@"8*(1+5)-6/3"];
    double firstResult = [firstDict[@"result"] doubleValue];
    
    XCTAssertEqual(firstResult, 46.f);
    
    /*
    NSDictionary* secondDict = [manager calculateExpression:@"8-3^2*5+50/5^2"];
    double secondResult = [secondDict[@"result"] doubleValue];
    
    XCTAssertEqual(secondResult, -35.f);
    */
}

@end
