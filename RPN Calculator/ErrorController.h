//
//  ErrorController.h
//  RPN Calculator
//
//  Created by Admin on 23.01.17.
//  Copyright © 2017 Andrey Kuznetsov. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ErrorController : UIAlertController

+ (void)errorControllerWithTitle:(NSString*)title message:(NSString*)message;

@end
