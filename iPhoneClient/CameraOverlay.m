//
//  CameraOverlay.m
//  YOI
//
//  Created by Jacob Hanshaw on 8/8/13.
//
//

#import "CameraOverlay.h"

#import <QuartzCore/QuartzCore.h>

@implementation CameraOverlay

@synthesize libraryButton;

- (id)initWithFrame:(CGRect)frame andDelegate:(id) delegate
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.opaque = NO;
        
        libraryButton = [[UIButton alloc] initWithFrame:CGRectMake(self.frame.size.width/2-BUTTON_WIDTH/2, BUTTON_Y_OFFSET, BUTTON_WIDTH, BUTTON_HEIGHT)];
        libraryButton.layer.borderWidth   = 1.0f;
        libraryButton.layer.borderColor   = [UIColor darkGrayColor].CGColor;
        libraryButton.backgroundColor     = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.3];
        libraryButton.layer.masksToBounds = YES;
        libraryButton.layer.cornerRadius  = BUTTON_CORNER_RADIUS;
        
        [libraryButton setImage: [UIImage imageNamed:BUTTON_IMAGE_NAME] forState: UIControlStateNormal];
        [libraryButton setImage: [UIImage imageNamed:BUTTON_IMAGE_NAME] forState: UIControlStateHighlighted];
        [libraryButton addTarget:delegate action:@selector(showLibraryButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:libraryButton];
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor( context, [UIColor colorWithWhite:0.0 alpha:0.5].CGColor );
    CGContextFillRect( context, rect );
    
    float imageSize = [UIScreen mainScreen].bounds.size.height > [UIScreen mainScreen].bounds.size.width ? [UIScreen mainScreen].bounds.size.width : [UIScreen mainScreen].bounds.size.height;
    
    CGRect holeRect = CGRectMake(self.center.x - imageSize/2, self.center.y - imageSize/2, imageSize, imageSize);
    CGRect holeRectIntersection = CGRectIntersection( holeRect, rect );
    [[UIColor clearColor] setFill];
    UIRectFill(holeRectIntersection);
}
*/

@end
