//
//  LoginViewController.h
//  ARIS
//
//  Created by Ben Longoria on 2/11/09.
//  Copyright 2009 University of Wisconsin. All rights reserved.
//

#import "AppModel.h"
#import <ZXingWidgetController.h>
#import "InnovLogInDelegate.h"

@interface LoginViewController : UIViewController <ZXingDelegate>
{
	IBOutlet UITextField *usernameField;
	IBOutlet UITextField *passwordField;
	IBOutlet UIButton *loginButton;
    IBOutlet UIButton *qrButton;
	IBOutlet UIButton *newAccountButton;
    IBOutlet UIButton *changePassButton;

	IBOutlet UILabel *newAccountMessageLabel;
}

@property(nonatomic, weak) id<InnovLogInDelegate> delegate;

-(IBAction) newAccountButtonTouched: (id) sender;
-(IBAction) loginButtonTouched: (id) sender;
-(IBAction) QRButtonTouched;
-(IBAction) changePassTouch;

@end
