//
//  CustomRefreshControl.m
//  YOI
//
//  Created by Jacob Hanshaw on 8/29/13.
//
//

#import "CustomRefreshControl.h"

@implementation CustomRefreshControl
{
    CGFloat topContentInset;
    BOOL topContentInsetSaved;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // getting containing scrollView
    UIScrollView *scrollView = (UIScrollView *)self.superview;
    
    // saving present top contentInset, because it can be changed by refresh control
    if (!topContentInsetSaved)
    {
        topContentInset = scrollView.contentInset.top;
        topContentInsetSaved = YES;
    }
    
    // saving own frame, that will be modified
    CGRect newFrame = self.frame;
    
    // if refresh control is fully or partially behind UINavigationBar
    if (scrollView.contentOffset.y + topContentInset > -newFrame.size.height)
    {
        // moving it with the rest of the content
        newFrame.origin.y = -newFrame.size.height;
        
        // if refresh control fully appeared
    }
    else
    {
        // keeping it at the same place
        newFrame.origin.y = scrollView.contentOffset.y + topContentInset;
    }
    
    // applying new frame to the refresh control
    self.frame = newFrame;
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
