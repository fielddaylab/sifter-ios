//
//  MapNotePopUp.m
//  YOI
//
//  Created by Jacob Hanshaw on 4/19/13.
//
//

#import "MapNotePopUp.h"

#import <QuartzCore/QuartzCore.h>

#import "Note.h"
#import "AsyncMediaImageView.h"

@implementation MapNotePopUp

@synthesize imageView, textLabel, note;

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code
        NSArray *xibArray =  [[NSBundle mainBundle] loadNibNamed:@"MapNotePopUp" owner:self options:nil];
        MapNotePopUp *view = [xibArray objectAtIndex:0];
        self.frame = view.bounds;
        [self addSubview:view];
        
        self.layer.cornerRadius= 9.0f;
    }
    return self;
}

- (id)initWithMedia:(Media *) media andText:(NSString*) text
{
    self = [super init];
    if (self) {
        // Initialization code
        NSArray *xibArray =  [[NSBundle mainBundle] loadNibNamed:@"MapNotePopUp" owner:self options:nil];
        MapNotePopUp *view = [xibArray objectAtIndex:0];
        self.frame = view.bounds;
        [self addSubview:view];
        
        self.layer.cornerRadius= 9.0f;
        
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
