//
//  InnovPopOverSocialContentView.m
//  YOI
//
//  Created by JacobJamesHanshaw on 6/19/13.
//
//

#import "InnovPopOverSocialContentView.h"
#import <Pinterest/Pinterest.h>

#import "SifterAppDelegate.h"
#import "InnovNoteModel.h"
#import "AppServices.h"
#import "AsyncMediaImageView.h"
#import "Note.h"
#import "NoteContent.h"
#import "Tag.h"

#define PINTEREST_CLIENT_ID          @"1432066"

@interface InnovPopOverSocialContentView()<AsyncMediaImageViewDelegate>
{
    AsyncMediaImageView *imageView;
    BOOL usersNote;
}

@end

@implementation InnovPopOverSocialContentView

@synthesize note, facebookButton, twitterButton, pinterestButton, emailButton;

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
        
         [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshNote) name:@"NoteModelUpdate:Notes" object:nil];
        
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) refreshNote
{
    self.note = [[InnovNoteModel sharedNoteModel] noteForNoteId:self.note.noteId];
}

- (IBAction)facebookButtonPressed:(id)sender
{
    NSString *title = [self getTitleOfCurrentNote];
    NSString *imageURL = [[AppModel sharedAppModel] mediaForMediaId:note.imageMediaId].url;
    
#warning fix url to be web notebook url
    NSString *url  = HOME_URL;
    
    [((SifterAppDelegate *)[[UIApplication sharedApplication] delegate]).simpleFacebookShare shareText:self.note.text withImage:imageURL title:title andURL:url fromNote:self.note.noteId automatically:NO];
}

- (IBAction)twitterButtonPressed:(id)sender
{
#warning fix url to be web notebook url
    NSString *text = [NSString stringWithFormat:@"%@ %@", TWITTER_HANDLE, self.note.text];
    NSString *url  = HOME_URL;
    
    [((SifterAppDelegate *)[[UIApplication sharedApplication] delegate]).simpleTwitterShare  shareText:text withImage:nil andURL:url fromNote:self.note.noteId];
}

- (IBAction)pinterestButtonPressed:(id)sender
{
    NSString *imageURL = [[AppModel sharedAppModel] mediaForMediaId:note.imageMediaId].url;
    
    Pinterest *pinterest = [[Pinterest alloc] initWithClientId:PINTEREST_CLIENT_ID];
    [pinterest createPinWithImageURL:[NSURL URLWithString:imageURL]
                           sourceURL:[NSURL URLWithString: HOME_URL]
                         description:self.note.text];
    
    [[AppServices sharedAppServices] sharedNoteToPinterest:self.note.noteId];
}

- (IBAction)emailButtonPressed:(id)sender
{
    NSData  *image;
    if((image = [[AppModel sharedAppModel] mediaForMediaId:note.imageMediaId].image))
    {
        #warning fix url to be web notebook url and link to app and add better subject line
        NSString *creationIndication;
        if(usersNote)
            creationIndication = @"made";
        else
            creationIndication = @"found";
        
        NSString *url    = HOME_URL;
        NSString *title  = [self getTitleOfCurrentNote];
        NSString *text   = [NSString stringWithFormat:@"Check out this note about %@ I %@ on the UW-Madison Campus: %@ \n\n\nSee the whole note at: %@ or download the Sifter app", title, creationIndication, self.note.text, url];
        NSString *subject = [NSString stringWithFormat:@"Interesting note on %@ from UW-Madison Campus", title];
        [((SifterAppDelegate *)[[UIApplication sharedApplication] delegate]).simpleMailShare shareText:text asHTML:NO withImage:image andSubject:subject toRecipients:nil fromNote:self.note.noteId];
    }
    else
        [imageView loadImageFromMedia:[[AppModel sharedAppModel] mediaForMediaId:note.imageMediaId]];
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

@end