//
//  ProgressButton.m
//  YOI
//
//  Created by Jacob Hanshaw on 7/4/13.
//
//

#import "ProgressButton.h"

@implementation ProgressButton

@synthesize percentDone;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    CGRect progressRect = CGRectMake(rect.origin.x, rect.origin.y, rect.size.width * percentDone, rect.size.height);
  //  CGRect backgroundRect = CGRectMake(rect.origin.x, rect.origin.y, rect.size.width * (1-percentDone), rect.size.height);
                                  
    [[UIColor blueColor] set];
    UIRectFill(progressRect);
    //[[UIColor greenColor] set];
    //UIRectFill(backgroundRect);
}


@end