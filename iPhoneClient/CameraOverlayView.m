//
//  CameraOverlayView.m
//  ARIS
//
//  Created by Jacob Hanshaw on 3/28/13.
//
//

#import "CameraOverlayView.h"

@implementation CameraOverlayView

@synthesize libraryButton;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        libraryButton.layer.borderWidth = 1.0f;
        libraryButton.layer.borderColor = [UIColor darkGrayColor].CGColor;
        libraryButton.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.25];
        libraryButton.layer.cornerRadius = 15.0f;
    }
    return self;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *hitView = [super hitTest:point withEvent:event];
    
    // If the hitView is THIS view, return nil and allow hitTest:withEvent: to
    // continue traversing the hierarchy to find the underlying view.
    if (hitView == self) {
        return nil;
    }
    // Else return the hitView (as it could be one of this view's buttons):
    return hitView;
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
