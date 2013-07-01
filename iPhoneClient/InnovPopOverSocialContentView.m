//
//  InnovPopOverSocialContentView.m
//  YOI
//
//  Created by JacobJamesHanshaw on 6/19/13.
//
//

#import "InnovPopOverSocialContentView.h"
#import <Pinterest/Pinterest.h>

#import "ARISAppDelegate.h"
#import "InnovNoteModel.h"
#import "AppServices.h"
#import "AsyncMediaImageView.h"
#import "CustomBadge.h"
#import "Note.h"
#import "NoteContent.h"
#import "Tag.h"

#define TWITTER_HANDLE               @"@jacob_hanshaw"
#define PINTEREST_CLIENT_ID          @"1432066"
#define DEFAULT_TITLE                @"Note"

@interface InnovPopOverSocialContentView()<AsyncMediaImageViewDelegate>
{
    AsyncMediaImageView *imageView;
    Media *media;
    
    BOOL usersNote;
    __weak IBOutlet UIButton *facebookButton;
    CustomBadge *facebookBadge;
    __weak IBOutlet UIButton *twitterButton;
    CustomBadge *twitterBadge;
    __weak IBOutlet UIButton *pinterestButton;
    CustomBadge *pinterestBadge;
    __weak IBOutlet UIButton *emailButton;
    CustomBadge *emailBadge;
}

@end

@implementation InnovPopOverSocialContentView

@synthesize note;

- (id)init
{
    self = [super init];
    if (self)
    {
        NSArray *xibArray =  [[NSBundle mainBundle] loadNibNamed:@"InnovPopOverSocialContentView" owner:self options:nil];
        InnovPopOverSocialContentView *view = [xibArray objectAtIndex:0];
        self.frame = view.bounds;
        [self addSubview:view];
        imageView = [[AsyncMediaImageView alloc] init];
        imageView.delegate = self;
        
        usersNote = ([AppModel sharedAppModel].playerId == self.note.creatorId);
        
        facebookBadge = [CustomBadge customBadgeWithString:@"0"];
        facebookBadge.center = CGPointMake(facebookButton.frame.size.width, 0);
        facebookButton.clipsToBounds = NO;
        [facebookButton addSubview:facebookBadge];
        
        twitterBadge = [CustomBadge customBadgeWithString:@"0"];
        twitterBadge.center = CGPointMake(twitterButton.frame.size.width, 0);
        twitterButton.clipsToBounds = NO;
        [twitterButton addSubview:twitterBadge];
        
        pinterestBadge = [CustomBadge customBadgeWithString:@"0"];
        pinterestBadge.center = CGPointMake(pinterestButton.frame.size.width, 0);
        pinterestButton.clipsToBounds = NO;
        [pinterestButton addSubview:pinterestBadge];
        
        emailBadge = [CustomBadge customBadgeWithString:@"0"];
        emailBadge.center = CGPointMake(emailButton.frame.size.width, 0);
        emailButton.clipsToBounds = NO;
        [emailButton addSubview:emailBadge];
        
         [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshBadges) name:@"NoteModelUpdate:Notes" object:nil];
        
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) refreshBadges
{
    self.note = [[InnovNoteModel sharedNoteModel] noteForNoteId:self.note.noteId];
    
    facebookBadge.badgeText  = [NSString stringWithFormat:@"%d", self.note.facebookShareCount];
    [facebookBadge setNeedsDisplay];
    [facebookBadge setNeedsLayout];
    twitterBadge.badgeText   = [NSString stringWithFormat:@"%d", self.note.twitterShareCount];
    [twitterBadge setNeedsDisplay];
    [twitterBadge setNeedsLayout];
    pinterestBadge.badgeText = [NSString stringWithFormat:@"%d", self.note.pinterestShareCount];
    [pinterestBadge setNeedsDisplay];
    [pinterestBadge setNeedsLayout];
    emailBadge.badgeText     = [NSString stringWithFormat:@"%d", self.note.emailShareCount];
    [emailBadge setNeedsDisplay];
    [emailBadge setNeedsLayout];
}

- (IBAction)facebookButtonPressed:(id)sender
{
    NSString *title = [self getTitleOfCurrentNote];
    NSString *imageURL = [self getImageUrlOfCurrentNote];
    
#warning fix url to be web notebook url
    NSString *url  = HOME_URL;
    
    [((ARISAppDelegate *)[[UIApplication sharedApplication] delegate]).simpleFacebookShare shareText:self.note.title withImage:imageURL title:title andURL:url fromNote:self.note.noteId];
}

- (IBAction)twitterButtonPressed:(id)sender
{
#warning fix url to be web notebook url
    NSString *text = [NSString stringWithFormat:@"%@ %@", TWITTER_HANDLE, self.note.title];
    NSString *url  = HOME_URL;
    [((ARISAppDelegate *)[[UIApplication sharedApplication] delegate]).simpleTwitterShare  shareText:text withImage:nil andURL:url fromNote:self.note.noteId];
}

- (IBAction)pinterestButtonPressed:(id)sender
{
    NSString *imageURL = [self getImageUrlOfCurrentNote];
    
    Pinterest *pinterest = [[Pinterest alloc] initWithClientId:PINTEREST_CLIENT_ID];
    [pinterest createPinWithImageURL:[NSURL URLWithString:imageURL]
                           sourceURL:[NSURL URLWithString: HOME_URL]
                         description:self.note.title];
    
    [[AppServices sharedAppServices] sharedNoteToPinterest:self.note.noteId];
}

- (IBAction)emailButtonPressed:(id)sender
{
    NSData  *image;
    if((image = [self getImageDataOfCurrentNote]))
    {
        #warning fix url to be web notebook url and link to app and add better subject line
        NSString *creationIndication;
        if(usersNote)
            creationIndication = @"made";
        else
            creationIndication = @"found";
        
        NSString *url    = HOME_URL;
        NSString *title  = [self getTitleOfCurrentNote];
        NSString *text   = [NSString stringWithFormat:@"Check out this interesting note about %@ I %@ on the UW-Madison Campus: %@ \n\n\nSee the whole note at: %@ or download the YOI app", title, creationIndication, self.note.title, url];
        NSString *subject = [NSString stringWithFormat:@"Interesting note on %@ from UW-Madison Campus", title];
        [((ARISAppDelegate *)[[UIApplication sharedApplication] delegate]).simpleMailShare shareText:text asHTML:NO withImage:image andSubject:subject toRecipients:nil fromNote:self.note.noteId];
    }
    else
        [imageView loadImageFromMedia:[self getImageMedia]];
}

- (void)imageFinishedLoading
{
    [self emailButtonPressed:nil];
}

- (NSString *) getTitleOfCurrentNote
{
    if([self.note.tags count] > 0)
        return ((Tag *)[self.note.tags objectAtIndex:0]).tagName;
    
    return DEFAULT_TITLE;
}

#pragma mark Get Image Information
- (Media *) getImageMedia
{
    if(!media)
    {
        for(NoteContent *noteContent in self.note.contents)
        {
            if([[noteContent getType] isEqualToString:kNoteContentTypePhoto])
                return (media = [noteContent getMedia]);
        }
    }
    
    return media;
}

- (NSString *) getImageUrlOfCurrentNote
{
    return  [self getImageMedia].url;
}

- (NSData *) getImageDataOfCurrentNote
{
    return [self getImageMedia].image;
}

@end
