//
//  SelfRegistrationViewController.m
//  ARIS
//
//  Created by David Gagnon on 5/14/09.
//  Copyright 2009 . All rights reserved.
//

#import "SelfRegistrationViewController.h"

#import "SifterAppDelegate.h"
#import "AppModel.h"
#import "AppServices.h"

@implementation SelfRegistrationViewController

@synthesize delegate;
@synthesize userName;
@synthesize password;
@synthesize email;


//Override init for passing title and icon to tab bar
- (id)initWithNibName:(NSString *)nibName bundle:(NSBundle *)nibBundle
{
    self = [super initWithNibName:nibName bundle:nibBundle];
    if (self)
    {
        self.title = NSLocalizedString(@"SelfRegistrationTitleKey", @"");

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selfRegistrationFailure)  name:@"SelfRegistrationFailed" object:nil];  
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selfRegistrationSuccess)  name:@"SelfRegistrationSucceeded" object:nil];  
	}
	
    return self;
}


- (void)viewDidLoad {
	userName.placeholder = NSLocalizedString(@"UsernameKey",@"");
	password.placeholder = NSLocalizedString(@"PasswordKey",@"");
	email.placeholder    = NSLocalizedString(@"EmailKey",@"");
	[createAccountButton setTitle:NSLocalizedString(@"CreateAccountKey",@"") forState:UIControlStateNormal];
	
	[userName becomeFirstResponder];

	[super viewDidLoad];
}
 
- (IBAction)submitButtonTouched: (id) sender{
//	[[RootViewController sharedRootViewController] showWaitingIndicator:@"Creating a New User" displayProgressBar:NO];
#warning add?
	[[AppServices sharedAppServices] registerNewUser:self.userName.text password:self.password.text 
					firstName:@"" lastName:@"" email:self.email.text];
}
	
-(void)selfRegistrationFailure{
	NSLog(@"SelfRegistration: Unsuccessfull registration attempt, check network before giving an alert");
#warning add
	//[[RootViewController sharedRootViewController] removeWaitingIndicator];
    [AppModel sharedAppModel].userName = nil;
    [AppModel sharedAppModel].password = nil;
	
	if ([AppModel sharedAppModel].networkAlert) NSLog(@"SelfRegistration: Network is down, skip alert");
	else{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ErrorKey", @"")
                                                        message:NSLocalizedString(@"SelfRegistrationErrorMessageKey", @"")
													   delegate:nil cancelButtonTitle:NSLocalizedString(@"OkKey", @"") otherButtonTitles: nil];
		[alert show];	
	}	
	
	[userName becomeFirstResponder];

}

-(void)selfRegistrationSuccess{
	NSLog(@"SelfRegistration: New User Created Successfully");
#warning add?
//	[[RootViewController sharedRootViewController] removeWaitingIndicator];
    
    [delegate attemptLoginWithUserName:[AppModel sharedAppModel].userName andPassword:[AppModel sharedAppModel].password andGameId:0];
	[self.view endEditing:YES];

	[self.navigationController popToRootViewControllerAnimated:YES];
}
	

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	if (textField == userName)
		[password becomeFirstResponder];
	if(textField == password)
		[email becomeFirstResponder];
	if(textField == email)
		[self submitButtonTouched:self];
    
    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


- (void)dealloc
{    
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end