//
//  ViewController.m
//  Coursera
//
//  Created by Alexander on 08.02.14.
//  Copyright (c) 2014 Alexander. All rights reserved.
//

#import "ViewController.h"
#import "NetManager.h"
#import "MBProgressHUD.h"

@interface ViewController () <UITextFieldDelegate>
{}
@property (nonatomic, weak) IBOutlet UITextField* emailField;
@property (nonatomic, weak) IBOutlet UITextField* passField;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.emailField.text = NetManager.sharedInstance.email;
    self.passField.text = NetManager.sharedInstance.password;
}


- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSString* finishStr = [textField.text stringByReplacingCharactersInRange:range withString:string];
    if(textField == self.emailField)
        NetManager.sharedInstance.email = finishStr;
    if(textField == self.passField)
        NetManager.sharedInstance.password = finishStr;
    return YES;
}

- (IBAction)loginPressed:(id)sender
{
    MBProgressHUD* hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [[NetManager sharedInstance] autorizeWithComplection:^(BOOL success, NSString *errorStr)
    {
        if(success){
            [hud hide:YES];
            [self successLogin];
        } else {
            hud.detailsLabelText = errorStr;
            [hud hide:YES afterDelay:2.0];
        }
    }];
}

- (void)successLogin
{
    [self performSegueWithIdentifier:@"showCourses" sender:self];
}

@end
