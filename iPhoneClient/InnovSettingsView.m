//
//  SettingsView.m
//  YOI
//
//  Created by Jacob James Hanshaw on 5/22/13.
//
//

#import "InnovSettingsView.h"
#import <QuartzCore/QuartzCore.h>

#import "AppModel.h"

#define ANIMATION_DURATION 0.15

@interface InnovSettingsView()
{
    __weak IBOutlet UIButton *notificationsButton;
    __weak IBOutlet UIButton *aboutButton;
    __weak IBOutlet UIButton *logInOutButton;
    BOOL hiding;
}
@end

@implementation InnovSettingsView

@synthesize delegate;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        NSArray *xibArray =  [[NSBundle mainBundle] loadNibNamed:@"InnovSettingsView" owner:self options:nil];
        InnovSettingsView *view = [xibArray objectAtIndex:0];
        self.frame = view.bounds;
        [self addSubview:view];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateLogInOutButtonTitle) name:@"NewLoginResponseReady" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(performLogout:)            name:@"PassChangeRequested"   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(performLogout:)            name:@"LogoutRequested"       object:nil];
    }
    return self;
}

#pragma mark Animations

- (void)show
{
    hiding = NO;
    self.hidden = NO;
    self.userInteractionEnabled = NO;
    [self updateLogInOutButtonTitle];
    
    CABasicAnimation *scale = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    scale.delegate = self;
    [scale setFromValue:[NSNumber numberWithFloat:0.0f]];
    [scale setToValue:  [NSNumber numberWithFloat:1.0f]];
    [scale setDuration: ANIMATION_DURATION];
    [scale setRemovedOnCompletion: NO];
    [scale setFillMode: kCAFillModeForwards];
    [self.layer addAnimation:scale forKey:@"transform.scaleUp"];
}

- (void)hide
{
    if(!self.hidden && !hiding)
    {
        hiding = YES;
        self.userInteractionEnabled = NO;
        
        CABasicAnimation *scale = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
        scale.delegate = self;
        [scale setFromValue:[NSNumber numberWithFloat:1.0f]];
        [scale setToValue:  [NSNumber numberWithFloat:0.0f]];
        [scale setDuration: ANIMATION_DURATION];
        [scale setRemovedOnCompletion: NO];
        [scale setFillMode: kCAFillModeForwards];
        [self.layer addAnimation:scale forKey:@"transform.scaleDown"];
    }
    
}

- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag
{
    if(flag){
        if (theAnimation == [[self layer] animationForKey:@"transform.scaleUp"] && !hiding)
        {
            self.userInteractionEnabled = YES;
        }
        else if(theAnimation == [[self layer] animationForKey:@"transform.scaleDown"] && hiding)
        {
            self.hidden = YES;
            [self removeFromSuperview];
        }
    }
}

- (IBAction)notificationsButtonPressed:(id)sender
{
#warning unimplemented
}

- (IBAction)aboutButtonPressed:(id)sender
{
    [delegate showAbout];
#warning unimplemented
}
- (IBAction)logInOutButtonPressed:(id)sender
{
    if([AppModel sharedAppModel].playerId == 0)
    {
        [delegate presentLogIn];
    }
    else
    {
        [self performLogout:nil];
        [self updateLogInOutButtonTitle];
    }
}

- (void)updateLogInOutButtonTitle
{
    if([AppModel sharedAppModel].playerId != 0)
    {
        [logInOutButton setTitle:@"Log Out" forState:UIControlStateNormal];
        [logInOutButton setTitle:@"Log Out" forState:UIControlStateHighlighted];
    }
    else
    {
        [logInOutButton setTitle:@"Log In" forState:UIControlStateNormal];
        [logInOutButton setTitle:@"Log In" forState:UIControlStateHighlighted];
    }
}

- (void)performLogout:(NSNotification *)notification
{
    [AppModel sharedAppModel].playerId       = 0;
    [AppModel sharedAppModel].playerMediaId  = -1;
    [AppModel sharedAppModel].userName       = @"";
    [AppModel sharedAppModel].displayName    = @"";
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger: [AppModel sharedAppModel].playerId        forKey:@"playerId"];
    [defaults setInteger: [AppModel sharedAppModel].playerMediaId   forKey:@"playerMediaId"];
    [defaults setObject:  [AppModel sharedAppModel].userName        forKey:@"userName"];
    [defaults setObject:  [AppModel sharedAppModel].displayName     forKey:@"displayName"];
}

@end