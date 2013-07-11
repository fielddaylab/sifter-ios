//
//  InnovPopOverView.m
//  YOI
//
//  Created by JacobJamesHanshaw on 6/19/13.
//
//

#import "InnovPopOverView.h"
#import <QuartzCore/QuartzCore.h>

#define CORNER_RADIUS  9.0
#define BUTTON_HEIGHT  40
#define BUTTON_WIDTH   40

@interface InnovPopOverView()
{
    UIView *contentView;
    UIButton *exitButton;
}

@end

@implementation InnovPopOverView

- (id)initWithFrame:(CGRect)frame andContentView: (UIView *) inputContentView
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.backgroundColor = [[UIColor alloc] initWithRed:0.0 green:0.0 blue:0.0 alpha:0.5];
        contentView = inputContentView;
        contentView.layer.masksToBounds = YES;
        contentView.layer.cornerRadius  = CORNER_RADIUS;
        contentView.center = self.center;
        
        [self addSubview:contentView];
        exitButton = [[UIButton alloc] initWithFrame:CGRectMake(0,
                                                                          0,
                                                                          BUTTON_WIDTH,
                                                                          BUTTON_HEIGHT)];
        exitButton.center = CGPointMake(self.frame.origin.x + contentView.frame.origin.x + contentView.frame.size.width,
                                        self.frame.origin.y + contentView.frame.origin.y);
        exitButton.backgroundColor = [UIColor clearColor];
        [exitButton setImage:[UIImage imageNamed:@"298-circlex.png"] forState:UIControlStateNormal];
        [exitButton setImage:[UIImage imageNamed:@"298-circlex.png"] forState:UIControlStateHighlighted];
        [exitButton addTarget:self action:@selector(exitButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview: exitButton];
    }
    return self;
}

- (void) adjustContentFrame:(CGRect)frame
{
    contentView.frame = frame;
    exitButton.center = CGPointMake(self.frame.origin.x + contentView.frame.origin.x + contentView.frame.size.width,
                                    self.frame.origin.y + contentView.frame.origin.y);
}

- (void) exitButtonPressed: (id) sender
{
    [self removeFromSuperview];
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    
    for(UITouch *touch in touches)
    {
        CGPoint point = [touch locationInView:self];
         if(!CGRectContainsPoint(contentView.frame, point))
             [self removeFromSuperview];
    }
   
}

@end