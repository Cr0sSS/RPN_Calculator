//
//  ViewController.m
//  RPN Calculator
//
//  Created by Admin on 17.01.17.
//  Copyright © 2017 Andrey Kuznetsov. All rights reserved.
//

#import "ViewController.h"
#import "CalculationManager.h"

#import "ErrorController.h"

@interface ViewController ()

@property (assign, nonatomic) BOOL hasError;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"VCBack"]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(showErrorMessage:)
                                                 name:@"CalculationError"
                                               object:nil];
    
    //self.mainTextField.text = @"1+2*5 - 5/22 + (45 +34)*-3";
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (IBAction)resultButtonPress:(id)sender {
    [self startCalculation];
}

- (IBAction)deleteButtonPress:(id)sender {
    [self deleteLastSymbol];
}

- (IBAction)symbolButtonPress:(UIButton *)sender {
    [self addSymbol:sender.titleLabel.text];
}


- (void)startCalculation {
    self.hasError = NO;
    
    NSDictionary* dict = [[CalculationManager sharedManager] calculateExpression:self.mainTextField.text];
    
    //NSMutableString* expression = dict[@"expression"];
    //self.resultLabel.text = self.hasError ? self.resultLabel.text : expression;

    NSMutableString* rpnExpression = dict[@"rpn"];
    double result = [dict[@"result"] doubleValue];
    
    self.rpnLabel.text = self.hasError ? @"" : rpnExpression;
    self.resultLabel.text = self.hasError ? @"ОШИБКА" : [NSString stringWithFormat:@"%1.2f", result];
}


- (void)deleteLastSymbol {
    NSMutableString* string = [self.mainTextField.text mutableCopy];
    
    if (string.length > 0) {
        [string deleteCharactersInRange:NSMakeRange(string.length - 1, 1)];
    }
    
    self.mainTextField.text = string;
}


- (void)addSymbol:(NSString*)symbol {
    NSMutableString* string = [self.mainTextField.text mutableCopy];
    [string appendString:symbol];
    self.mainTextField.text = string;
}


- (void)showErrorMessage:(NSNotification*)notification {
    self.hasError = YES;

    NSString* message = [notification userInfo][@"message"];
    ErrorController* ec = [ErrorController errorControllerWithMessage:message];
    [self presentViewController:ec animated:YES completion:nil];
}


#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    [self startCalculation];
    return YES;
}


- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    return NO;
}

@end
