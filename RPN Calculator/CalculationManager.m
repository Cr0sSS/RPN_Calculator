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

+ (CalculationManager*)sharedManager {
    static CalculationManager* manager = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [CalculationManager new];
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
                
                /*
                // Добавить реализацию для новой операции
                } else if ([token isEqual:@"^"]) {
                    newOper = pow(firstOper, secondOper);
                */
                    
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
        NSInteger symbolPriority = [self priorityOfOperator:symbol];
        
        if ([allDigits containsString:symbol]) {
            [symbolsBefore insertString:symbol atIndex:symbolsBefore.length];
            
            if (i == expression.length - 1) {
                [resultArray addObject:[self numberFromString:symbolsBefore]];
            }
            
        } else if ([dotPointers containsString:symbol]) {
            [symbolsBefore insertString:@"." atIndex:symbolsBefore.length];
            
        } else if (symbolPriority == 3) {
            //// Унарный минус
            if ([symbolsBefore isEqualToString:@""] && ![[resultArray lastObject] isEqualToString:@")"]) {
                [symbolsBefore appendString:symbol];
             
            //// Знак операции "минус"
            } else {
                [self addOperator:symbol toArray:resultArray symbolsBefore:symbolsBefore];
                symbolsBefore = [@"" mutableCopy];
            }
            
        } else if (symbolPriority < INT_MAX) {
            //// Любой знак, кроме минуса и точки
            [self addOperator:symbol toArray:resultArray symbolsBefore:symbolsBefore];
            symbolsBefore = [@"" mutableCopy];
        }
    }
    
    id lastObj = [resultArray lastObject];
    if ([lastObj isKindOfClass:[NSString class]]) {
        
        if ([self priorityOfOperator:lastObj] > 1) {
            //// Не скобка
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
            
            NSInteger operPriority = [self priorityOfOperator:tokenString];
            if (operPriority > 1 && operPriority < INT_MAX) {
                //// Является знаком операции
                NSInteger count = [stack count];
                for (NSInteger i = 0; i < count; i++) {
                    NSString* stackString = [self peekFromStack:stack];
                    
                    if ([self priorityOfOperator:tokenString] <= [self priorityOfOperator:stackString]) {
                        [outputQueue addObject:[self popFromStack:stack]];

                    } else {
                        break;
                    }
                }
                
                [self pushObject:token toStack:stack];
                
            } else if ([tokenString isEqualToString:@"("]) {
                [self pushObject:token toStack:stack];
                
            } else {
                //// Закрывающая скобка
                NSInteger count = [stack count];
                if (count) {
                    for (NSInteger i = 0; i < count; i++) {
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
    
    NSInteger count = [stack count];
    for (NSInteger i = 0; i < count; i++) {
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


- (NSInteger)priorityOfOperator:(NSString*)operator {
    char operatorChar = [operator characterAtIndex:0];
    
    switch (operatorChar) {
        case '(':
            return 0;
        case ')':
            return 1;
        case '+':
            return 2;
        case '-':
            return 3;
        case '*':
            return 4;
        case '/':
            return 4;
        
        /*
        // Добавить приоритет для новой операции
        case '^':
            return 5;
        */
            
        default:
            return INT_MAX;
    }
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


@implementation TestCalculationManager

- (double)calculateRPNExpression:(NSMutableArray*)rpnExpressionArray {
    return [super calculateRPNExpression:rpnExpressionArray];
}

@end
