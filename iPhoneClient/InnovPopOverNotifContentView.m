//
//  InnovPopOverNotifContentView.m
//  YOI
//
//  Created by Jacob Hanshaw on 7/5/13.
//
//

#import "InnovPopOverNotifContentView.h"

#import "AppModel.h"
#import "InnovNoteModel.h"

#define MAX_OBSERVABLE_LOCATIONS 20

@interface InnovPopOverNotifContentView()
{
    __weak IBOutlet UILabel *topNotesLabel;
    __weak IBOutlet UISlider *topNotesSlider;
    __weak IBOutlet UILabel *popularNotesLabel;
    __weak IBOutlet UISlider *popularNotesSlider;
    __weak IBOutlet UILabel *recentNotesLabel;
    __weak IBOutlet UISlider *recentNotesSlider;
    __weak IBOutlet UILabel *myRecentNotesLabel;
    __weak IBOutlet UISlider *myRecentNotesSlider;
    
    NSArray *allSliders;
}

@end

@implementation InnovPopOverNotifContentView

@synthesize delegate;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        NSArray *xibArray =  [[NSBundle mainBundle] loadNibNamed:@"InnovPopOverNotifContentView" owner:self options:nil];
        InnovPopOverNotifContentView *view = [xibArray objectAtIndex:0];
        self.frame = view.bounds;
        [self addSubview:view];
        
        allSliders = [NSArray arrayWithObjects:topNotesSlider, popularNotesSlider, recentNotesSlider, myRecentNotesSlider, nil];
    }
    return self;
}

- (void) refreshFromModel
{
    NSArray *notifNotesCounts = [[InnovNoteModel sharedNoteModel] getNotifNoteCounts];
    
    topNotesSlider.value      = [[notifNotesCounts objectAtIndex:kTop]     intValue];
    popularNotesSlider.value  = [[notifNotesCounts objectAtIndex:kPopular] intValue];
    recentNotesSlider.value   = [[notifNotesCounts objectAtIndex:kRecent]  intValue];
    myRecentNotesSlider.value = [[notifNotesCounts objectAtIndex:kMine]    intValue];
    [self updateLabels];
}

- (IBAction)sliderValueChanged:(UISlider *)sender
{
    if(sender != myRecentNotesSlider || [AppModel sharedAppModel].playerId != 0)
    {
        [sender setValue:((int)(sender.value + 0.5)) animated:NO];
        
        if(sender == topNotesSlider)
            [self decrementIndexesOtherThan:kTop];
        else if (sender == popularNotesSlider)
            [self decrementIndexesOtherThan:kPopular];
        else if (sender == recentNotesSlider)
            [self decrementIndexesOtherThan:kRecent];
        else if (sender == myRecentNotesSlider)
            [self decrementIndexesOtherThan:kMine];
    }
    else
    {
        [myRecentNotesSlider setValue:((int)(sender.value + 0.5)) animated:NO];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Must Be Logged In" message:@"You must be logged in to receive notifications about notes you created." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles: nil];
        [alert show];
    }
    
    [self updateLabels];
}

- (void)decrementIndexesOtherThan:(ContentSelector) index
{
    while((((int)((UISlider *)[allSliders objectAtIndex:kTop]).value) + ((int)((UISlider *)[allSliders objectAtIndex:kPopular]).value)
           + ((int)((UISlider *)[allSliders objectAtIndex:kRecent]).value) + ((int)((UISlider *)[allSliders objectAtIndex:kMine]).value)) > MAX_OBSERVABLE_LOCATIONS)
    {
        int r;
        while((r = arc4random() % kNumContents) == index);
        
        if(((UISlider *)[allSliders objectAtIndex:r]).value > 0)
            ((UISlider *)[allSliders objectAtIndex:r]).value  -= 1;
    }
}

- (void)updateLabels
{
    if(((int)((UISlider *)[allSliders objectAtIndex:kTop]).value) == 0)
        topNotesLabel.text = @"No Top Notes";
    else if(((int)((UISlider *)[allSliders objectAtIndex:kTop]).value)== 1)
        topNotesLabel.text = @"The Top Note";
    else
        topNotesLabel.text = [NSString stringWithFormat:@"The Top %d Notes", ((int)((UISlider *)[allSliders objectAtIndex:kTop]).value)];
    
    if(((int)((UISlider *)[allSliders objectAtIndex:kPopular]).value) == 0)
        popularNotesLabel.text = @"No Popular Notes";
    else if(((int)((UISlider *)[allSliders objectAtIndex:kPopular]).value)== 1)
        popularNotesLabel.text = @"The Most Popular Note";
    else
        popularNotesLabel.text = [NSString stringWithFormat:@"The Most Popular %d Notes", ((int)((UISlider *)[allSliders objectAtIndex:kPopular]).value)];
    
    if(((int)((UISlider *)[allSliders objectAtIndex:kRecent]).value) == 0)
        recentNotesLabel.text = @"No Recent Notes";
    else if(((int)((UISlider *)[allSliders objectAtIndex:kRecent]).value) == 1)
        recentNotesLabel.text = @"The Most Recent Note";
    else
        recentNotesLabel.text = [NSString stringWithFormat:@"The Most Recent %d Notes", ((int)((UISlider *)[allSliders objectAtIndex:kRecent]).value)];
    
    if(((int)((UISlider *)[allSliders objectAtIndex:kMine]).value) == 0)
        myRecentNotesLabel.text = @"None of My Notes";
    else if(((int)((UISlider *)[allSliders objectAtIndex:kMine]).value) == 1)
        myRecentNotesLabel.text = @"My Most Recent Note";
    else
        myRecentNotesLabel.text = [NSString stringWithFormat:@"My Most Recent %d Notes", ((int)((UISlider *)[allSliders objectAtIndex:kMine]).value)];
}

- (IBAction)saveButtonPressed:(id)sender
{
    [[InnovNoteModel sharedNoteModel] setUpNotificationsForTopNotes: ((UISlider *)[allSliders objectAtIndex:kTop]).value
                                                       popularNotes: ((UISlider *)[allSliders objectAtIndex:kPopular]).value
                                                        recentNotes: ((UISlider *)[allSliders objectAtIndex:kRecent]).value
                                                   andMyRecentNotes: ((UISlider *)[allSliders objectAtIndex:kMine]).value];
    [delegate dismiss];
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
