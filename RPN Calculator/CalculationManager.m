//
//  CalculationManager.m
//  RPN Calculator
//
//  Created by Admin on 23.01.17.
//  Copyright © 2017 Andrey Kuznetsov. All rights reserved.
//

#import "CalculationManager.h"

@implementation CalculationManager

static NSString* const allDigits = @"1234567890";
static NSString* const dotPointers = @".,";

static NSString* const mathOperators = @"-+*/";
static NSMutableString* onlySymbols;


+ (CalculationManager*)sharedManager {
    static CalculationManager* manager = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [CalculationManager new];
        
        onlySymbols = [mathOperators mutableCopy];
        [onlySymbols deleteCharactersInRange:NSMakeRange(0, 1)];
        [onlySymbols appendString:@"()"];
    });
    
    return manager;
}


#pragma mark - Calculation

- (NSDictionary*)calculateExpression:(NSString*)expression {
    
    NSMutableArray* expressionArray = [self arrayFromString:expression];
    NSMutableArray* rpnExpressionArray = [self transformToRPN:expressionArray];
    
    double result = [self calculateRPNExpression:rpnExpressionArray];
    NSMutableString* rpnExpressionString = [self stringFromArray:rpnExpressionArray];
    
    NSDictionary* dict = @{@"rpn" : rpnExpressionString,
                           @"result" : [NSNumber numberWithDouble:result]};
    return dict;
}


- (double)calculateRPNExpression:(NSMutableArray*)rpnExpressionArray {
    NSMutableArray* stack = [NSMutableArray new];
    
    for (id token in rpnExpressionArray) {
        
        if ([token isKindOfClass:[NSNumber class]]) {
            [self pushObject:token toStack:stack];
            
        } else {
            if ([stack count] > 1) {
                double secondOper = [[self popFromStack:stack] doubleValue];
                double firstOper = [[self popFromStack:stack] doubleValue];
                double newOper;
                
                if ([token isEqual:@"+"]) {
                    newOper = firstOper + secondOper;
                    
                } else if ([token isEqual:@"-"]) {
                    newOper = firstOper - secondOper;
                    
                } else if ([token isEqual:@"/"]) {
                    if (secondOper == 0.f) {
                        [self postErrorMessage:@"Деление на ноль невозможно"];
                    }
                    
                    newOper = firstOper / secondOper;
                    
                } else {
                    newOper = firstOper * secondOper;
                }
                
                [self pushObject:[NSNumber numberWithDouble:newOper] toStack:stack];
                
            } else {
                [self postErrorMessage:@"Неверная запись выражения:\nПроверьте количество операндов и знаков операций"];
            }
        }
    }
    
    double result = [[self popFromStack:stack] doubleValue];
    
    if ([stack count]) {
        [self postErrorMessage:@"Неверная запись выражения:\nПроверьте количество операндов и знаков операций"];
    }
    
    return result;
}


#pragma mark - Stack Commands

- (void)pushObject:(id)object toStack:(NSMutableArray*)stack {
    [stack addObject:object];
}


- (id)popFromStack:(NSMutableArray*)stack {
    id object = [stack lastObject];
    [stack removeLastObject];
    return object;
}


- (id)peekFromStack:(NSMutableArray*)stack {
    return [stack lastObject];
}


#pragma mark - Formatters

- (NSMutableArray*)arrayFromString:(NSString*)expression {
    
    NSMutableArray* resultArray = [NSMutableArray new];
    NSMutableString* symbolsBefore = [NSMutableString new];
    
    for (NSUInteger i = 0; i < expression.length; i++) {
        NSString* symbol = [self stringFromUnichar:[expression characterAtIndex:i]];
        
        if ([allDigits containsString:symbol]) {
            [symbolsBefore insertString:symbol atIndex:symbolsBefore.length];
            
            if (i == expression.length - 1) {
                [resultArray addObject:[self numberFromString:symbolsBefore]];
            }
            
        } else if ([dotPointers containsString:symbol]) {
            [symbolsBefore insertString:@"." atIndex:symbolsBefore.length];
            
        } else if ([symbol isEqualToString:@"-"]) {
            if ([symbolsBefore isEqualToString:@""]) {
                [symbolsBefore insertString:symbol atIndex:symbolsBefore.length];
                
            } else {
                [self addOperator:symbol toArray:resultArray symbolsBefore:symbolsBefore];
                symbolsBefore = [@"" mutableCopy];
            }
            
        } else if ([@"+*/()" containsString:symbol]) {
            [self addOperator:symbol toArray:resultArray symbolsBefore:symbolsBefore];
            symbolsBefore = [@"" mutableCopy];
        }
    }
    
    if ([[resultArray lastObject] isKindOfClass:[NSString class]]) {
        if ([@"+-/*" containsString:[resultArray lastObject]]) {
            [self postErrorMessage:@"Неверная запись выражения:\nВыражение не может заканчиваться знаком операции"];
        }
    }
    
    return resultArray;
}


- (NSMutableArray*)transformToRPN:(NSMutableArray*)expression {
    
    NSMutableArray* outputQueue = [NSMutableArray new];
    NSMutableArray* stack = [NSMutableArray new];
    
    for (id token in expression) {
        
        if ([token isKindOfClass:[NSNumber class]]) {
            [outputQueue addObject:token];
            
        } else if ([token isKindOfClass:[NSString class]]) {
            NSString* tokenString = (NSString*)token;
            
            if ([@"+-*/" containsString:tokenString]) {
                
                if ([stack count]) {
                    
                    NSInteger maxStep = [stack count];
                    for (NSInteger i = 0; i < maxStep; i++) {
                        NSString* stackObj = [self peekFromStack:stack];
                        
                        if ([@"+-" containsString:tokenString] && [@"*/+-" containsString:stackObj]) {
                            [outputQueue addObject:[self popFromStack:stack]];
                            
                        } else {
                            break;
                        }
                    }
                }
                [self pushObject:token toStack:stack];
                
            } else if ([tokenString isEqualToString:@"("]) {
                [self pushObject:token toStack:stack];
                
            } else {
                //// Закрывающаяся скобка
                if ([stack count]) {
                    
                    NSInteger maxStep = [stack count];
                    for (NSInteger i = 0; i < maxStep; i++) {
                        NSString* stackObj = [self peekFromStack:stack];
                        
                        if (![stackObj isEqualToString:@"("]) {
                            [outputQueue addObject:[self popFromStack:stack]];
                            
                        } else {
                            [self popFromStack:stack];
                            break;
                        }
                    }
                } else {
                    [self postErrorMessage:@"Пропущена скобка в выражении"];
                }
            }
        }
    }
    NSInteger maxStep = [stack count];
    for (NSInteger i = 0; i < maxStep; i++) {
        NSString* stackObj = [self peekFromStack:stack];
        
        if ([stackObj isEqualToString:@"("]) {
            [self postErrorMessage:@"Не закрыта скобка в выражении"];
            
        } else {
            [outputQueue addObject:[self popFromStack:stack]];
        }
    }
    
    if ([[outputQueue lastObject] isKindOfClass:[NSNumber class]]) {
        [self postErrorMessage:@"Неверная запись выражения:\nПроверьте расстановку скобок и знаков операций"];
    }
    
    return outputQueue;
}


- (NSString*)stringFromUnichar:(unichar)innerChar {
    return [NSString stringWithFormat:@"%@", [NSString stringWithCharacters:&innerChar length:1]];
}


- (void)addOperator:(NSString*)symbol toArray:(NSMutableArray*)resultArray symbolsBefore:(NSMutableString*)symbolsBefore {
    
    if (symbolsBefore.length) {
        [resultArray addObject:[self numberFromString:symbolsBefore]];
    }
    
    [resultArray addObject:symbol];
}


- (NSNumber*)numberFromString:(NSString*)symbols {
    
    double value = [symbols doubleValue];
    NSNumber* number = [NSNumber numberWithDouble:value];
    return number;
}


- (NSMutableString*)stringFromArray:(NSMutableArray*)array {
    NSMutableString* string = [NSMutableString new];
    
    for (id obj in array) {
        NSString* stringObj;
        
        if ([obj isKindOfClass:[NSNumber class]]) {
            stringObj = [obj stringValue];
        } else {
            stringObj = obj;
        }
        
        [string appendString:stringObj];
        [string appendString:@" "];
    }
    
    return string;
}


#pragma mark - Error

- (void)postErrorMessage:(NSString*)message {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CalculationError"
                                                        object:self
                                                      userInfo:@{@"message" : message}];
}

@end
