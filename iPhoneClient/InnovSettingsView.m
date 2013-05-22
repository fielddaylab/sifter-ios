//
//  SettingsView.m
//  YOI
//
//  Created by Jacob James Hanshaw on 5/22/13.
//
//

#import "InnovSettingsView.h"

#import <QuartzCore/QuartzCore.h>

@implementation InnovSettingsView

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
/*
#pragma mark Animations

- (void)showSettings
{
    hiding = NO;
    self.hidden = NO;
    self.userInteractionEnabled = NO;
    
    self.layer.anchorPoint = CGPointMake(1, 0);
    CABasicAnimation *scale = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    [scale setFromValue:[NSNumber numberWithFloat:0.0f]];
    [scale setToValue:[NSNumber numberWithFloat:1.0f]];
    [scale setDuration:0.8f];
    [scale setRemovedOnCompletion:NO];
    [scale setFillMode:kCAFillModeForwards];
    scale.delegate = self;
    [self.layer addAnimation:scale forKey:@"transform.scaleUp"];
}

- (void)hideSettings
{
    hidingSettings = YES;
    
    self.layer.anchorPoint = CGPointMake(1, 0);
    CABasicAnimation *scale = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    [scale setFromValue:[NSNumber numberWithFloat:1.0f]];
    [scale setToValue:[NSNumber numberWithFloat:0.0f]];
    [scale setDuration:0.8f];
    [scale setRemovedOnCompletion:NO];
    [scale setFillMode:kCAFillModeForwards];
    scale.delegate = self;
    [settingsView.layer addAnimation:scale forKey:@"transform.scaleDown"];
    
}

- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag
{
    if(flag){
        if (theAnimation == [[settingsView layer] animationForKey:@"transform.scaleUp"] && !hidingSettings)
            settingsView.userInteractionEnabled = YES;
        else if(theAnimation == [[settingsView layer] animationForKey:@"transform.scaleDown"] && hidingSettings)
            settingsView.hidden = YES;
    }
}
*/
- (IBAction)profileButtonPressed:(id)sender
{
    #warning unimplemented
}

- (IBAction)createLinkButtonPressed:(id)sender
{
    #warning unimplemented
}

- (IBAction)notificationsButtonPressed:(id)sender
{
    #warning unimplemented
}

- (IBAction)aboutButtonPressed:(id)sender
{
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
