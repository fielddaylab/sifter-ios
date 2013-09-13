//
//  SelfRegistrationViewController.h
//  ARIS
//
//  Created by David Gagnon on 5/14/09.
//  Copyright 2009 University of Wisconsin - Madison. All rights reserved.
//

@protocol SelfRegistrationDelegate <NSObject>
@required
- (void)attemptLoginWithUserName:(NSString *)userName andPassword:(NSString *)password andGameId:(int)gameId;
@end

@interface SelfRegistrationViewController : UIViewController <UITextFieldDelegate, UITextViewDelegate>
{
	IBOutlet UITextField *userName;
	IBOutlet UITextField *password;
	IBOutlet UITextField *email;
	IBOutlet UIButton *createAccountButton;
}

@property(nonatomic, weak) id<SelfRegistrationDelegate> delegate;
@property (nonatomic) IBOutlet UITextField *userName;
@property (nonatomic) IBOutlet UITextField *password;
@property (nonatomic) IBOutlet UITextField *email;


-(IBAction)submitButtonTouched: (id) sender;


@end
