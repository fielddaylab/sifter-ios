//
//  SettingsView.m
//  YOI
//
//  Created by Jacob James Hanshaw on 5/22/13.
//
//

#import "InnovSettingsView.h"

#import <QuartzCore/QuartzCore.h>

#define ANIMATION_DURATION 0.5

@implementation InnovSettingsView

@synthesize delegate;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        NSArray *xibArray =  [[NSBundle mainBundle] loadNibNamed:@"InnovSettingsView" owner:self options:nil];
        InnovSettingsView *view = [xibArray objectAtIndex:0];
        self.frame = view.bounds;
        [self addSubview:view];
    }
    return self;
}

#pragma mark Animations

- (void)show
{
    hiding = NO;
    self.hidden = NO;
    self.userInteractionEnabled = NO;
    
    CABasicAnimation *scale = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    [scale setFromValue:[NSNumber numberWithFloat:0.0f]];
    [scale setToValue:[NSNumber numberWithFloat:1.0f]];
    [scale setDuration:ANIMATION_DURATION];
    [scale setRemovedOnCompletion:NO];
    [scale setFillMode:kCAFillModeForwards];
    scale.delegate = self;
    [self.layer addAnimation:scale forKey:@"transform.scaleUp"];
}

- (void)hide
{
    if(!self.hidden && !hiding)
    {
        hiding = YES;
        self.userInteractionEnabled = NO;
        
        CABasicAnimation *scale = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
        [scale setFromValue:[NSNumber numberWithFloat:1.0f]];
        [scale setToValue:[NSNumber numberWithFloat:0.0f]];
        [scale setDuration:ANIMATION_DURATION];
        [scale setRemovedOnCompletion:NO];
        [scale setFillMode:kCAFillModeForwards];
        scale.delegate = self;
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

- (IBAction)profileButtonPressed:(id)sender
{
    [delegate showProfile];
#warning unimplemented
}

- (IBAction)createLinkButtonPressed:(id)sender
{
    [delegate link];
#warning unimplemented
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

/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect
 {
 // Drawing code
 }
 */



@end
