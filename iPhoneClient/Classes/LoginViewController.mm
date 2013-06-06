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
#import "BumpTestViewController.h"

@implementation LoginViewController

@synthesize delegate;

- (id)initWithNibName:(NSString *)nibName bundle:(NSBundle *)nibBundle
{
    self = [super initWithNibName:nibName bundle:nibBundle];
    if (self)
    {
        self.title = NSLocalizedString(@"LoginTitleKey", @"");
    }
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

-(IBAction)QRButtonTouched
{
    ZXingWidgetController *widController = [[ZXingWidgetController alloc] initWithDelegate:self showCancel:YES OneDMode:NO];
    widController.readers = [[NSMutableSet alloc ] initWithObjects:[[QRCodeReader alloc] init], nil];
    [self presentModalViewController:widController animated:NO];
}

-(void)changePassTouch
{
    ForgotViewController *forgotPassViewController = [[ForgotViewController alloc] initWithNibName:@"ForgotViewController" bundle:[NSBundle mainBundle]];
    [[self navigationController] pushViewController:forgotPassViewController animated:NO];
}

-(IBAction)newAccountButtonTouched:(id)sender
{
    SelfRegistrationViewController *selfRegistrationViewController = [[SelfRegistrationViewController alloc] initWithNibName:@"SelfRegistration" bundle:[NSBundle mainBundle]];
    [[self navigationController] pushViewController:selfRegistrationViewController animated:NO];
}

- (void)zxingController:(ZXingWidgetController*)controller didScanResult:(NSString *)result
{
    [self dismissModalViewControllerAnimated:NO];
    if([result isEqualToString:@"TEST_BUMP"])
    {
        BumpTestViewController *b = [[BumpTestViewController alloc] initWithNibName:@"BumpTestViewController" bundle:nil];
        [self presentViewController:b animated:NO completion:nil];
    }
    else
    {
        NSArray *terms  = [result componentsSeparatedByString:@","];
        if([terms count] > 1)
        {
            int gameId = 0;
            bool create = NO;
            bool museumMode = NO;
            
            if([terms count] > 0) create = [[terms objectAtIndex:0] boolValue];
            if(create)
            {
                if([terms count] > 1) usernameField.text = [terms objectAtIndex:1]; //Group Name
                if([terms count] > 2) gameId = [[terms objectAtIndex:2] intValue];
                if([terms count] > 3) museumMode = [[terms objectAtIndex:3] boolValue];
                [delegate createUserAndLoginWithGroup:usernameField.text andGameId:gameId inMuseumMode:museumMode];
            }
            else
            {
                if([terms count] > 1) usernameField.text = [terms objectAtIndex:1]; //Username
                if([terms count] > 2) passwordField.text = [terms objectAtIndex:2]; //Password
                if([terms count] > 3) gameId = [[terms objectAtIndex:3] intValue];
                if([terms count] > 4) museumMode = [[terms objectAtIndex:4] boolValue];
                [delegate attemptLoginWithUserName:usernameField.text andPassword:passwordField.text andGameId:gameId inMuseumMode:museumMode];
            }
        }
        
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)zxingControllerDidCancel:(ZXingWidgetController*)controller
{
    [self dismissModalViewControllerAnimated:NO];
}

@end
