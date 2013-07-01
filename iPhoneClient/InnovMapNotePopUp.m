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
#import "InnovNoteModel.h"
#import "NoteContent.h"
#import "AsyncMediaImageView.h"
#import "InnovPresentNoteDelegate.h"

#define CORNER_RADIUS      9.0
#define ANIMATION_TIME     0.5
#define SCALED_DOWN_AMOUNT 0.01

@interface InnovMapNotePopUp ()
{
    __weak IBOutlet AsyncMediaImageView *imageView;
    __weak IBOutlet UILabel *textLabel;
    
    BOOL hiding;
}

@end

@implementation InnovMapNotePopUp

@synthesize note, delegate;

- (id)init
{
    self = [super init];
    if (self)
    {
        NSArray *xibArray =  [[NSBundle mainBundle] loadNibNamed:@"InnovMapNotePopUp" owner:self options:nil];
        InnovMapNotePopUp *view = [xibArray objectAtIndex:0];
        self.frame = view.bounds;
        [self addSubview:view];
        
        self.layer.masksToBounds = YES;
        self.layer.cornerRadius  = CORNER_RADIUS;
        self.transform = CGAffineTransformMakeScale(SCALED_DOWN_AMOUNT, SCALED_DOWN_AMOUNT);
    }
    return self;
}

- (IBAction) notePopUpPressed: (id) sender
{
    [delegate presentNote:self.note];
}

- (void) refreshViewFromModel
{
        self.note = [[InnovNoteModel sharedNoteModel] noteForNoteId:self.note.noteId];
        
        textLabel.text = note.title;
        if([note.contents count] > 0)
        {
            for(NoteContent *noteContent in note.contents)
            {
                if([[noteContent getType] isEqualToString:kNoteContentTypePhoto])
                    [imageView loadImageFromMedia:[noteContent getMedia]];
            }
        }
        else
        {
            imageView.image = nil;
            [imageView startSpinner];
            [NSTimer scheduledTimerWithTimeInterval:2.0
                                             target:self
                                           selector:@selector(refreshViewFromModel)
                                           userInfo:nil
                                            repeats:NO];
        }
}

#pragma mark Animations

- (void) show
{
    hiding = NO;
    self.hidden = NO;
    self.userInteractionEnabled = NO;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshViewFromModel) name:@"NotesAvailableChanged" object:nil];
    
    [self refreshViewFromModel];
    
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
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        
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

@end