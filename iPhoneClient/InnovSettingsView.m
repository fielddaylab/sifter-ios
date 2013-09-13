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
#import "SifterAppDelegate.h"

#define ANIMATION_DURATION 0.1f
#define POINTER_LENGTH 10

@interface InnovSettingsView()
{
    __weak IBOutlet UIButton *notificationsButton;
    __weak IBOutlet UIButton *aboutButton;
    __weak IBOutlet UIButton *logInOutButton;
    BOOL hiding;
    
    CGRect contentRect;
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
        
        self.opaque = NO;
        self.backgroundColor = [UIColor clearColor];
        
        contentRect = CGRectInset(self.bounds, 0, 10);
        
        if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1)
        {
            [notificationsButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [aboutButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [logInOutButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        }
        
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
    self.userInteractionEnabled = NO;
    [self updateLogInOutButtonTitle];
    
    __weak UIView *weakSelf = self;
    [UIView animateWithDuration:ANIMATION_DURATION delay:0.0f options:UIViewAnimationCurveEaseOut animations:^{ weakSelf.alpha = 1.0f; }
                     completion:^(BOOL finished) { self.userInteractionEnabled = YES; }];
}

- (void)hide
{
    if(self.alpha != 0.0f && !hiding)
    {
        hiding = YES;
        self.userInteractionEnabled = NO;
        
        __weak UIView *weakSelf = self;
        [UIView animateWithDuration:ANIMATION_DURATION delay:0.0f options:UIViewAnimationCurveEaseOut animations:^{ weakSelf.alpha = 0.0f; }
                         completion:^(BOOL finished) { [weakSelf removeFromSuperview]; }];
    }
    
}

- (IBAction)notificationsButtonPressed:(id)sender
{
    [delegate showNotifications];
}

- (IBAction)aboutButtonPressed:(id)sender
{
    [delegate showAbout];
}
- (IBAction)logInOutButtonPressed:(id)sender
{
    if([AppModel sharedAppModel].playerId != 0)
        [self performLogout:nil];
    else
        [delegate presentLogIn];
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
    [defaults synchronize];
    
    [((SifterAppDelegate *)[[UIApplication sharedApplication] delegate]).simpleFacebookShare logOut];
    
    [self updateLogInOutButtonTitle];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"LogOutSucceeded" object:nil];
}

- (void) drawRect:(CGRect)rect
{
    CGMutablePathRef calloutPath = CGPathCreateMutable();
    CGPoint pointerPoint = CGPointMake(contentRect.origin.x + 0.84 * contentRect.size.width,  contentRect.origin.y - POINTER_LENGTH);
    
    CGFloat radius = 7.0;
    
    CGPathAddArc(calloutPath, NULL, CGRectGetMinX(contentRect) + radius, CGRectGetMinY(contentRect) + radius, radius, M_PI, 3 * M_PI / 2, 0);
    
    CGPathAddLineToPoint(calloutPath, NULL, pointerPoint.x - 10.0, CGRectGetMinY(contentRect));
    CGPathAddLineToPoint(calloutPath, NULL, pointerPoint.x, pointerPoint.y);
    CGPathAddLineToPoint(calloutPath, NULL, pointerPoint.x + 10.0,  CGRectGetMinY(contentRect));
    
    CGPathAddArc(calloutPath, NULL, CGRectGetMaxX(contentRect) - radius, CGRectGetMinY(contentRect) + radius, radius, 3 * M_PI / 2, 0, 0);
    
    CGPathAddArc(calloutPath, NULL, CGRectGetMaxX(contentRect) - radius, CGRectGetMaxY(contentRect) - radius, radius, 0, M_PI / 2, 0);
    
    CGPathAddArc(calloutPath, NULL, CGRectGetMinX(contentRect) + radius, CGRectGetMaxY(contentRect) - radius, radius, M_PI / 2, M_PI, 0);
    CGPathCloseSubpath(calloutPath);
    
    CGContextAddPath(UIGraphicsGetCurrentContext(), calloutPath);
    [[UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:0.5] set];
    CGContextFillPath(UIGraphicsGetCurrentContext());
    [[UIColor whiteColor] set];
    CGContextAddPath(UIGraphicsGetCurrentContext(), calloutPath);
    CGContextStrokePath(UIGraphicsGetCurrentContext()); 
}

@end