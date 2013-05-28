//
//  MapNotePopUp.m
//  YOI
//
//  Created by Jacob Hanshaw on 4/19/13.
//
//

#import "InnovMapNotePopUp.h"

#import <QuartzCore/QuartzCore.h>

#import "Note.h"
#import "NoteContent.h"
#import "AsyncMediaImageView.h"
#import "InnovPresentNoteDelegate.h"

#define ANIMATION_TIME     0.5
#define SCALED_DOWN_AMOUNT 0.01  // For example, 0.01 is one hundredth of the normal size

@interface InnovMapNotePopUp ()
{
    BOOL hiding;

}

@end

@implementation InnovMapNotePopUp

@synthesize note, delegate;

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code
        NSArray *xibArray =  [[NSBundle mainBundle] loadNibNamed:@"InnovMapNotePopUp" owner:self options:nil];
        InnovMapNotePopUp *view = [xibArray objectAtIndex:0];
        self.frame = view.bounds;
        [self addSubview:view];
#warning check if corner radius works and transform is necessary
        self.layer.masksToBounds = YES;
        self.layer.cornerRadius= 9.0f;
        self.transform=CGAffineTransformMakeScale(SCALED_DOWN_AMOUNT, SCALED_DOWN_AMOUNT);
    }
    return self;
}

- (id)initWithMedia:(Media *) media andText:(NSString*) text
{
    self = [super init];
    if (self) {
        // Initialization code
        NSArray *xibArray =  [[NSBundle mainBundle] loadNibNamed:@"InnovMapNotePopUp" owner:self options:nil];
        InnovMapNotePopUp *view = [xibArray objectAtIndex:0];
        self.frame = view.bounds;
        [self addSubview:view];
#warning check if corner radius works and transform is necessary
        self.layer.masksToBounds = YES;
        self.layer.cornerRadius= 9.0f;
        self.transform=CGAffineTransformMakeScale(SCALED_DOWN_AMOUNT, SCALED_DOWN_AMOUNT);
        
        [imageView loadImageFromMedia:media];
        [textLabel setText:text];
    }
    return self;
}

#pragma mark Animations

- (void) show
{
    hiding = NO;
    
    textLabel.text = [note.title substringToIndex: [note.title rangeOfString:@"#" options:NSBackwardsSearch].location];
    for(int i = 0; i < [self.note.contents count]; ++i)
    {
        NoteContent *noteContent = [note.contents objectAtIndex:i];
        if([[noteContent getType] isEqualToString:kNoteContentTypePhoto]) [imageView loadImageFromMedia:[noteContent getMedia]];
    }
    
    self.hidden = NO;
    self.userInteractionEnabled = NO;
    [UIView beginAnimations:@"animationExpandNote" context:NULL];
    [UIView setAnimationDuration:ANIMATION_TIME];
    self.transform=CGAffineTransformMakeScale(1, 1);
    [UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
	[UIView commitAnimations];
    
}

- (void) hide
{
    if(!self.hidden && !hiding)
    {
        hiding = YES;
        self.userInteractionEnabled = NO;
        [UIView beginAnimations:@"animationShrinkNote" context:NULL];
        [UIView setAnimationDuration:ANIMATION_TIME];
        self.transform=CGAffineTransformMakeScale(SCALED_DOWN_AMOUNT, SCALED_DOWN_AMOUNT);
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
        [UIView commitAnimations];
    }
}

-(void)animationDidStop:(NSString *)animationID finished:(BOOL)finished context:(void *)context{
    if(finished)
    {
        if ([animationID isEqualToString:@"animationExpandNote"] && !hiding) self.userInteractionEnabled=YES;
        else if ([animationID isEqualToString:@"animationShrinkNote"] && hiding)
        {
            self.hidden = YES;
            [self removeFromSuperview];
        }
    }
}

- (IBAction)notePopUpPressed:(id)sender
{
    [delegate presentNote:self.note];
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
