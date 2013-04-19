//
//  MapNotePopUp.m
//  YOI
//
//  Created by Jacob Hanshaw on 4/19/13.
//
//

#import "MapNotePopUp.h"

#import <QuartzCore/QuartzCore.h>

@implementation MapNotePopUp

@synthesize imageView, textLabel, note;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame Media:(Media *) media andText:(NSString*) text
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [imageView loadImageFromMedia:media];
        [textLabel setText:text];
        
    }
    return self;
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
