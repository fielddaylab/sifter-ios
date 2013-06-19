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
#import "AsyncMediaImageView.h"
#import "Note.h"

#define TWITTER_HANDLE               @"@jacob_hanshaw"
#define DEFAULT_TITLE                @"Note"
#define HOME_URL                     @"dev.arisgames.org"

@interface InnovPopOverSocialContentView()<AsyncMediaImageViewDelegate>
{
    AsyncMediaImageView *imageView;
    Media *media;
    
    BOOL usersNote;
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
    }
    return self;
}

- (IBAction)facebookButtonPressed:(id)sender
{
    NSString *title = [self getTitleOfCurrentNote];
    NSString *imageURL = [self getImageUrlOfCurrentNote];
    
#warning fix url to be web notebook url
    NSString *url  = @"jacobhanshaw.com";
    
    [((ARISAppDelegate *)[[UIApplication sharedApplication] delegate]).simpleFacebookShare shareText:self.note.title withImage:imageURL title:title andURL:url];
}

- (IBAction)twitterButtonPressed:(id)sender
{
#warning fix url to be web notebook url
    NSString *text = [NSString stringWithFormat:@"%@ %@", TWITTER_HANDLE, self.note.title];
    NSString *url  = @"jacobhanshaw.com";
    [((ARISAppDelegate *)[[UIApplication sharedApplication] delegate]).simpleTwitterShare  shareText:text withImage:nil andURL:url];
}

- (IBAction)pinterestButtonPressed:(id)sender
{
    NSString *imageURL = [self getImageUrlOfCurrentNote];
    
    Pinterest *pinterest = [[Pinterest alloc] initWithClientId:@"1432066"];
    [pinterest createPinWithImageURL:[NSURL URLWithString:imageURL]
                           sourceURL:[NSURL URLWithString: HOME_URL]
                         description:self.note.title];
}

- (IBAction)mailButtonPressed:(id)sender
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
        
        NSString *url    = @"jacobhanshaw.com";
        NSString *title  = [self getTitleOfCurrentNote];
        NSString *text   = [NSString stringWithFormat:@"Check out this interesting note about %@ I %@ on the UW-Madison Campus: %@ \n\n\nSee the whole note at: %@ or download the YOI app", title, creationIndication, self.note.title, url];
        NSString *subject = [NSString stringWithFormat:@"Interesting note on %@ from UW-Madison Campus", title];
        [((ARISAppDelegate *)[[UIApplication sharedApplication] delegate]).simpleMailShare shareText:text asHTML:NO withImage:image andSubject:subject toRecipients:nil];
    }
    else
        [imageView loadImageFromMedia:[self getImageMedia]];
}

- (void)imageFinishedLoading
{
    [self mailButtonPressed:nil];
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
