//
//  CameraOverlayView.m
//  ARIS
//
//  Created by Jacob Hanshaw on 3/28/13.
//
//

#import "CameraOverlayView.h"
#import <QuartzCore/QuartzCore.h>

@implementation CameraOverlayView

@synthesize libraryButton;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    return self;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *hitView = [super hitTest:point withEvent:event];
    
    if (hitView == self)
        return nil;

    return hitView;
}

@end