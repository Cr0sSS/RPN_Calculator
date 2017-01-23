//
//  CalculationManager.h
//  RPN Calculator
//
//  Created by Admin on 23.01.17.
//  Copyright © 2017 Andrey Kuznetsov. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CalculationManager : NSObject

+ (CalculationManager*)sharedManager;

- (NSDictionary*)calculateExpression:(NSString*)expression;

@end
