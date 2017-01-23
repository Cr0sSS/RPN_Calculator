//
//  ViewController.h
//  RPN Calculator
//
//  Created by Admin on 17.01.17.
//  Copyright © 2017 Andrey Kuznetsov. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *mainTextField;

@property (weak, nonatomic) IBOutlet UILabel *resultLabel;
@property (weak, nonatomic) IBOutlet UILabel *rpnLabel;

- (IBAction)resultButtonPress:(id)sender;
- (IBAction)deleteButtonPress:(id)sender;
- (IBAction)symbolButtonPress:(UIButton *)sender;

@end

