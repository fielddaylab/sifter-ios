//
//  LoginViewController.m
//  ARIS
//
//  Created by Ben Longoria on 2/11/09.
//  Copyright 2009 University of Wisconsin. All rights reserved.
//

#import "LoginViewController.h"
#import "SelfRegistrationViewController.h"
#import "ARISAppDelegate.h"
#import "ChangePasswordViewController.h"
#import "ForgotViewController.h"
#import "QRCodeReader.h"

@implementation LoginViewController

@synthesize delegate;

- (id)initWithNibName:(NSString *)nibName bundle:(NSBundle *)nibBundle
{
    self = [super initWithNibName:nibName bundle:nibBundle];
    if (self)
        self.title = @"Log In to YOI"; // NSLocalizedString(@"LoginTitleKey", @"");
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    CGRect frame = [UIScreen mainScreen].applicationFrame;
    frame.size.height -= self.navigationController.navigationBar.frame.size.height;
    self.view.frame = frame;

    usernameField.placeholder = NSLocalizedString(@"UsernameKey", @"");
    passwordField.placeholder = NSLocalizedString(@"PasswordKey", @"");
    [loginButton setTitle:NSLocalizedString(@"LoginKey",@"") forState:UIControlStateNormal];
    newAccountMessageLabel.text = NSLocalizedString(@"NewAccountMessageKey", @"");
    [newAccountButton setTitle:NSLocalizedString(@"CreateAccountKey",@"") forState:UIControlStateNormal];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [usernameField resignFirstResponder];
    [passwordField resignFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == usernameField)
        [passwordField becomeFirstResponder];
    if(textField == passwordField)
        [self loginButtonTouched:self];
    return YES;
}

//Makes keyboard disappear on touch outside of keyboard or textfield
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [usernameField resignFirstResponder];
    [passwordField resignFirstResponder];
}

-(IBAction)loginButtonTouched:(id)sender
{
    [delegate attemptLoginWithUserName:usernameField.text andPassword:passwordField.text andGameId:0 inMuseumMode:false];

    [usernameField resignFirstResponder];
    [passwordField resignFirstResponder];
    
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)changePassTouch
{
    ForgotViewController *forgotPassViewController = [[ForgotViewController alloc] initWithNibName:@"ForgotViewController" bundle:[NSBundle mainBundle]];
    [[self navigationController] pushViewController:forgotPassViewController animated:NO];
}

-(IBAction)newAccountButtonTouched:(id)sender
{
    SelfRegistrationViewController *selfRegistrationViewController = [[SelfRegistrationViewController alloc] initWithNibName:@"SelfRegistration" bundle:[NSBundle mainBundle]];
    selfRegistrationViewController.delegate = self.delegate;
    [[self navigationController] pushViewController:selfRegistrationViewController animated:NO];
}

@end
