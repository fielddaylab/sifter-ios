//
//  LoginViewController.h
//  ARIS
//
//  Created by Ben Longoria on 2/11/09.
//  Copyright 2009 University of Wisconsin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppModel.h"
#import <ZXingWidgetController.h>

@protocol LogInViewControllerDelegate <NSObject>
@required
- (void)createUserAndLoginWithGroup:(NSString *) username andGameId:(int) gameId inMuseumMode:(BOOL) museumMode;
- (void)attemptLoginWithUserName:(NSString *) username andPassword:(NSString *) password andGameId:(int) gameId inMuseumMode:(BOOL) museumMode;

@end

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

@property(nonatomic, weak) id<LogInViewControllerDelegate> delegate;

-(IBAction) newAccountButtonTouched: (id) sender;
-(IBAction) loginButtonTouched: (id) sender;
-(IBAction) QRButtonTouched;
-(IBAction) changePassTouch;

@end
