//
//  InnovNoteEditorViewController.m
//  ARIS
//
//  Created by Jacob Hanshaw on 4/5/13.
//
//

typedef enum {
    NoteContentSection,
    RecordSection,
    ShareSection,
    TagSection,
    DropOnMapSection,
    DeleteSection,
    NumSections
} SectionLabel;

#import <AVFoundation/AVFoundation.h>
#import <CoreAudio/CoreAudioTypes.h>
#import <QuartzCore/QuartzCore.h>

#import "AppModel.h"
#import "InnovNoteModel.h"
#import "AppServices.h"
#import "ARISAppDelegate.h"
#import "Note.h"
#import "NoteContent.h"
#import "Tag.h"

#import "ProgressButton.h"
#import "InnovTagCell.h"
#import "InnovPopOverView.h"
#import "InnovPopOverTwitterAccountContentView.h"
#import "InnovPopOverSocialContentView.h"
#import "AsyncMediaTouchableImageView.h"
#import "ARISMoviePlayerViewController.h"
#import "DropOnMapViewController.h"
#import "InnovViewController.h"
#import "InnovNoteEditorViewController.h"
#import "CameraViewController.h"

#import "Logger.h"

#define DEFAULT_TEXT             @"Write a caption..."
#define PROGRESS_UPDATE_INTERVAL 1.0
#define MAX_AUDIO_LENGTH         30.0

#define NOTE_CONTENT_CELL_X_MARGIN     15
#define NOTE_CONTENT_CELL_Y_MARGIN     5
#define NOTE_CONTENT_IMAGE_TEXT_MARGIN 10

#define IMAGE_HEIGHT 85
#define IMAGE_WIDTH  IMAGE_HEIGHT

#define SHARE_BUTTON_HEIGHT 30
#define SHARE_BUTTON_WIDTH  SHARE_BUTTON_HEIGHT
#define NO_SHARE_ALPHA      0.25f;

#define CELL_BUTTON_HEIGHT 46

#define DROP_ON_MAP_HEIGHT 120

#define CANCEL_BUTTON_TITLE @"Cancel"
#define SHARE_BUTTON_TITLE  @"Share"

#define IMAGEHEIGHT 35
#define IMAGEWIDTH 35
#define SPACING 10

static NSString *NoteContentCellIdentifier = @"NoteConentCell";
static NSString *RecordCellIdentifier      = @"RecordCell";
static NSString *ShareCellIdentifier       = @"ShareCell";
static NSString *TagCellIdentifier         = @"TagCell";
static NSString *DropOnMapCellIdentifier   = @"DropOnMapCell";
static NSString *DeleteCellIdentifier      = @"DeleteCell";

@interface InnovNoteEditorViewController ()<AVAudioSessionDelegate, AVAudioRecorderDelegate, AVAudioPlayerDelegate, UITextViewDelegate, UITableViewDataSource, UITableViewDelegate, AsyncMediaTouchableImageViewDelegate, AsyncMediaImageViewDelegate, CameraViewControllerDelegate, InnovPopOverViewDelegate, InnovPopOverTwitterAccountContentViewDelegate> {
    
    UIBarButtonItem *cancelButton;
    
    Note *note;
    BOOL newNote;
    BOOL cameraHasBeenPresented;
    __weak IBOutlet UITableView *editNoteTableView;
    
    AsyncMediaTouchableImageView *imageView;
    UITextView *captionTextView;
    
    ProgressButton *recordButton;
    UIButton *deleteAudioButton;
    
    BOOL shareToFacebook;
    BOOL shareToTwitter;
    NSArray *allTwitterAccounts;
    NSArray *selectedTwitterAccounts;
    InnovPopOverView *popOver;
    InnovPopOverSocialContentView *socialView;
    
    int originalTagId;
    NSString  *originalTagName;
    int selectedIndex;
    NSString  *newTagName;
    NSArray *tagList;
    
    BOOL hasAudioToUpload;
    
    ARISMoviePlayerViewController *ARISMoviePlayer;
    //AudioMeter *meter;
	AVAudioRecorder *soundRecorder;
	AVAudioPlayer *soundPlayer;
	NSURL *soundFileURL;
	InnovAudioRecorderModeType mode;
	NSTimer *recordLengthCutoffAndPlayProgressTimer;
    double secondsRecordingOrPlaying;
    double audioLength;
    
    DropOnMapViewController *dropOnMapVC;
    
    UIButton *deleteNoteButton;
}

@end

@implementation InnovNoteEditorViewController

@synthesize note, delegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshViewFromModel)    name:@"NoteModelUpdate:Notes"    object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTags)              name:@"NoteModelUpdate:Tags"     object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deselectTwitterButton)   name:@"NoTwitterAccounts"  object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectTwitterAccounts:)  name:@"TwitterAccountListReady"  object:nil];
        
        tagList = [[NSArray alloc]init];
    }
    return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    CGRect frame = [UIScreen mainScreen].applicationFrame;
    frame.size.height -= self.navigationController.navigationBar.frame.size.height;
    self.view.frame = frame;
    
    cancelButton = [[UIBarButtonItem alloc] initWithTitle: CANCEL_BUTTON_TITLE
                                                    style: UIBarButtonItemStyleDone
                                                   target:self
                                                   action:@selector(cancelButtonPressed:)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle: SHARE_BUTTON_TITLE
                                                                   style: UIBarButtonItemStyleDone
                                                                  target:self
                                                                  action:@selector(shareButtonPressed:)];
    self.navigationItem.rightBarButtonItem = doneButton;
    
    imageView = [[AsyncMediaTouchableImageView alloc] initWithFrame:CGRectMake(NOTE_CONTENT_CELL_X_MARGIN, NOTE_CONTENT_CELL_Y_MARGIN, IMAGE_WIDTH, IMAGE_HEIGHT)];
    imageView.delegate = self;
    
    captionTextView = [[UITextView alloc] initWithFrame:CGRectMake(NOTE_CONTENT_CELL_X_MARGIN + imageView.frame.size.width + NOTE_CONTENT_IMAGE_TEXT_MARGIN, NOTE_CONTENT_CELL_Y_MARGIN, 196, IMAGE_HEIGHT)];
    captionTextView.delegate = self;
    captionTextView.returnKeyType = UIReturnKeyDone;
    
    recordButton = [[ProgressButton alloc] initWithFrame:CGRectMake(0, 0, 44, CELL_BUTTON_HEIGHT)];
    [recordButton addTarget:self action:@selector(recordButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    deleteAudioButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 44, CELL_BUTTON_HEIGHT)];
    [deleteAudioButton addTarget:self action:@selector(deleteAudioButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    deleteNoteButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 44, CELL_BUTTON_HEIGHT)];
    [deleteNoteButton addTarget:self action:@selector(deleteNoteButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    deleteNoteButton.backgroundColor = [UIColor redColor];
    [deleteNoteButton setTitle:@"Delete" forState:UIControlStateNormal];
    [deleteNoteButton setTitle:@"Delete" forState:UIControlStateHighlighted];
    
    [[AVAudioSession sharedInstance] setDelegate: self];
    NSString *tempDir = NSTemporaryDirectory ();
    NSString *soundFilePath =[tempDir stringByAppendingString: [NSString stringWithFormat:@"%@.caf",[self getUniqueId]]];
    soundFileURL = [[NSURL alloc] initFileURLWithPath: soundFilePath];
    
    [self updateTags];
    
    UIGraphicsBeginImageContext(CGSizeMake(1,1));
    ARISMoviePlayer = [[ARISMoviePlayerViewController alloc] init];
    ARISMoviePlayer.view.frame = CGRectMake(0, 0, 1, 1);
    ARISMoviePlayer.moviePlayer.view.hidden = YES;
    ARISMoviePlayer.moviePlayer.shouldAutoplay = YES;
    ARISMoviePlayer.moviePlayer.movieSourceType = MPMovieSourceTypeStreaming;
    [ARISMoviePlayer.moviePlayer setControlStyle:MPMovieControlStyleNone];
    [ARISMoviePlayer.moviePlayer setFullscreen:NO];
    [self.view addSubview:ARISMoviePlayer.view];
    UIGraphicsEndImageContext();
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear: animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(MPMoviePlayerLoadStateDidChange:)             name:MPMoviePlayerLoadStateDidChangeNotification object:ARISMoviePlayer.moviePlayer];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(MPMoviePlayerPlaybackStateDidChange:)         name:MPMoviePlayerPlaybackStateDidChangeNotification object:ARISMoviePlayer.moviePlayer];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(MPMoviePlayerPlaybackDidFinishNotification:)  name:MPMoviePlayerPlaybackDidFinishNotification object:ARISMoviePlayer.moviePlayer];
    
    originalTagName = @"";
    newTagName = @"";
    CLLocationCoordinate2D coordinate = [AppModel sharedAppModel].playerLocation.coordinate;
    
    if(self.note.noteId != 0)
    {
        captionTextView.text = note.text;
        
        if([note.text length] > 0 && ![note.text isEqualToString:DEFAULT_TEXT])
            captionTextView.textColor = [UIColor blackColor];
        
        imageView.userInteractionEnabled = YES;
        
        [editNoteTableView reloadData];
        
        if([self.note.tags count] != 0)
        {
            originalTagId = ((Tag *)[self.note.tags objectAtIndex:0]).tagId;
            originalTagName = ((Tag *)[self.note.tags objectAtIndex:0]).tagName;
            self.title = originalTagName;
        }
        else
            [self tableView:editNoteTableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:TagSection]];
        
        if(self.note.latitude != 0 && self.note.longitude != 0)
            coordinate = CLLocationCoordinate2DMake(self.note.latitude, self.note.longitude);
        
        NSError *error;
        [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayAndRecord error: &error];
        [[Logger sharedLogger] logError:error];
        [[AVAudioSession sharedInstance] setActive: YES error: &error];
        [[Logger sharedLogger] logError:error];
        
        mode = kInnovAudioRecorderNoAudio;
        [self updateButtonsForCurrentMode];
        hasAudioToUpload = NO;
        
        [self refreshViewFromModel];
    }
    else if(!cameraHasBeenPresented)
    {
        self.note = [[Note alloc] init];
        self.note.text =  DEFAULT_TEXT;
        self.note.creatorId   = [AppModel sharedAppModel].playerId;
#warning Probably useless to put in user/display name
        self.note.username    = [AppModel sharedAppModel].userName;
        self.note.displayname = [AppModel sharedAppModel].displayName;
        self.note.noteId      = [[AppServices sharedAppServices] createNoteStartIncomplete];
        self.note.latitude    = [AppModel sharedAppModel].playerLocation.coordinate.latitude;
        self.note.longitude   = [AppModel sharedAppModel].playerLocation.coordinate.longitude;
        newNote = YES;
        if(self.note.noteId == 0)
        {
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle: NSLocalizedString(@"NoteEditorCreateNoteFailedKey", @"") message: NSLocalizedString(@"NoteEditorCreateNoteFailedMessageKey", @"") delegate:nil cancelButtonTitle: NSLocalizedString(@"OkKey", @"") otherButtonTitles: nil];
            [alert show];
            self.note = nil;
            [self.navigationController popToViewController:(UIViewController *)self.delegate animated:YES];
            return;
        }
        
        captionTextView.text = DEFAULT_TEXT;
        captionTextView.textColor = [UIColor lightGrayColor];
        
        imageView.userInteractionEnabled = NO;
        
        [[InnovNoteModel sharedNoteModel] addNote:self.note];
        
        [self cameraButtonTouchAction];
    }
    
    dropOnMapVC = [[DropOnMapViewController alloc] initWithCoordinate:coordinate];
    [self addChildViewController:dropOnMapVC];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [recordLengthCutoffAndPlayProgressTimer invalidate];
    
    if(mode == kInnovAudioRecorderPlaying || mode == kInnovAudioRecorderRecording)
        [self recordButtonPressed:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerLoadStateDidChangeNotification      object:ARISMoviePlayer.moviePlayer];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackStateDidChangeNotification  object:ARISMoviePlayer.moviePlayer];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification       object:ARISMoviePlayer.moviePlayer];
    
    NSError *error;
    [[AVAudioSession sharedInstance] setActive: NO error: &error];
    [[Logger sharedLogger] logError:error];
}

#pragma mark UIImageView methods

-(void) asyncMediaImageTouched:(id)sender
{
    [self cameraButtonTouchAction];
}

-(void) startSpinner
{
    [imageView startSpinner];
}

-(void) updateImageView:(NSData *)image
{
    [imageView updateViewWithNewImage:[UIImage imageWithData:image]];
    [imageView stopSpinner];
}

#pragma mark UITextView methods

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    
    [self.view endEditing:YES];
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    textView.textColor = [UIColor blackColor];
    if([textView.text isEqualToString:DEFAULT_TEXT]) textView.text = @"";
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    
    if([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    }
    
    return YES;
}

#pragma mark Note Contents

- (void)refreshViewFromModel
{
    if(note)
    {
        self.note = [[InnovNoteModel sharedNoteModel] noteForNoteId:self.note.noteId];
        if(note.imageMediaId)
            [imageView loadImageFromMedia:[[AppModel sharedAppModel] mediaForMediaId:note.imageMediaId]];
        if(note.audioMediaId)
        {
            NSString *audioURL = [[AppModel sharedAppModel] mediaForMediaId:note.audioMediaId].url;
            if (![[ARISMoviePlayer.moviePlayer.contentURL absoluteString] isEqualToString: audioURL]) {
                [ARISMoviePlayer.moviePlayer setContentURL: [NSURL URLWithString:audioURL]];
                [ARISMoviePlayer.moviePlayer prepareToPlay];
            }
            mode = kInnovAudioRecorderAudio;
            [self updateButtonsForCurrentMode];
        }
    }
}

#pragma mark Button Methods

- (void)cancelButtonPressed: (id) sender
{
    if(newNote)
    {
        [[AppServices sharedAppServices]  deleteNoteWithNoteId:self.note.noteId];
        [[InnovNoteModel sharedNoteModel] removeNote:note];
    }
    [self.navigationController popToViewController:(UIViewController *)self.delegate animated:YES];
}

- (void)shareButtonPressed: (id) sender
{
    if([captionTextView.text isEqualToString:DEFAULT_TEXT] || [captionTextView.text length] == 0) self.note.text = @"";
    else self.note.text = captionTextView.text;
    
    int textContentId = 0;
    for(NSObject <NoteContentProtocol> *contentObject in note.contents)
    {
        if([contentObject isKindOfClass:[NoteContent class]] && [[contentObject getType] isEqualToString:kNoteContentTypeText])
        {
            textContentId = [contentObject getContentId];
            ((NoteContent *)contentObject).text = self.note.text;
        }
    }
    
    if(textContentId == 0)
    {
        NSString *urlString = [NSString stringWithFormat:@"%@.txt",[NSDate date]];
        urlString = [NSString stringWithFormat:@"%d.txt",urlString.hash];
        NSURL *url = [NSURL URLWithString:urlString];
        [[[AppModel sharedAppModel] uploadManager]uploadContentForNoteId:self.note.noteId withTitle:[NSString stringWithFormat:@"%@",[NSDate date]] withText:self.note.text withType:@"TEXT" withFileURL:url];
    }
    else
        [[AppServices sharedAppServices]updateNoteContent:textContentId text:self.note.text];
    
    [[AppServices sharedAppServices] updateNoteWithNoteId:self.note.noteId title:self.note.title publicToMap:YES publicToList:YES];
    
    if(mode == kInnovAudioRecorderRecording)
        [self recordButtonPressed:nil];
    if(hasAudioToUpload)
        [[[AppModel sharedAppModel]uploadManager] uploadContentForNoteId:self.note.noteId withTitle:[NSString stringWithFormat:@"%@",[NSDate date]] withText:nil withType:kNoteContentTypeAudio withFileURL:soundFileURL];
    
    if([newTagName length] > 0 && ![originalTagName isEqualToString:newTagName])
    {
        if(originalTagId != 0) [[AppServices sharedAppServices] deleteTagFromNote:self.note.noteId tagId:originalTagId];
        [[AppServices sharedAppServices] addTagToNote:self.note.noteId tagName:newTagName];
        
        Tag *tag = [[Tag alloc] init];
        tag.tagName = newTagName;
        [self.note.tags addObject:tag];
    }
    
    if(newNote)
        [[AppServices sharedAppServices] setNoteCompleteForNoteId:self.note.noteId];
    
    if(dropOnMapVC.locationMoved)
    {
        self.note.latitude = dropOnMapVC.currentCoordinate.latitude;
        self.note.longitude = dropOnMapVC.currentCoordinate.longitude;
        [[AppServices sharedAppServices] dropNote:self.note.noteId atCoordinate:dropOnMapVC.currentCoordinate];
    }
    
    [[InnovNoteModel sharedNoteModel] updateNote:note];
    
    if(shareToFacebook)
    {
        NSString *title = ([self.note.tags count] > 0) ? ((Tag *)[self.note.tags objectAtIndex:0]).tagName : DEFAULT_TITLE;
        NSString *imageURL = [[AppModel sharedAppModel] mediaForMediaId:note.imageMediaId].url;
#warning fix url to be web notebook url
        NSString *url  = HOME_URL;
        [((ARISAppDelegate *)[[UIApplication sharedApplication] delegate]).simpleFacebookShare shareText:self.note.text withImage:imageURL title:title andURL:url fromNote:self.note.noteId automatically:YES];
    }
    
    if(shareToTwitter)
    {
        NSString *text = [NSString stringWithFormat:@"%@ %@", TWITTER_HANDLE, self.note.text];
        NSString *url  = HOME_URL;
#warning fix url to be web notebook url
        [((ARISAppDelegate *)[[UIApplication sharedApplication] delegate]).simpleTwitterShare autoTweetWithText:text image:nil andURL:url fromNote:self.note.noteId toAccounts:selectedTwitterAccounts];
    }
    
    [self.delegate prepareToDisplayNote: self.note];
    
    [self.navigationController popToViewController:(UIViewController *)self.delegate animated:YES];
}

-(void)cameraButtonTouchAction
{
    CameraViewController *cameraVC = [[CameraViewController alloc] init];
    
    if(!newNote) cameraVC.backView = self;
    else cameraVC.backView = self.delegate;
    cameraVC.editView = self;
    cameraVC.noteId = self.note.noteId;
    
    cameraHasBeenPresented = YES;
    
    [self.navigationController pushViewController:cameraVC animated:NO];
}

- (void)deleteNoteButtonPressed:(id)sender
{
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Are You Sure?" message: @"Are you sure you want to delete this note?" delegate:self cancelButtonTitle: @"Cancel" otherButtonTitles: @"Delete", nil];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex)
    {
        [[AppServices sharedAppServices]  deleteNoteWithNoteId:self.note.noteId];
        [[InnovNoteModel sharedNoteModel] removeNote:note];
        [self.navigationController popToViewController:(UIViewController *)self.delegate animated:YES];
    }
}

#pragma mark Audio Methods

- (NSString *)getUniqueId
{
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    CFRelease(theUUID);
    return (__bridge_transfer NSString *)string;
}

- (void)updateButtonsForCurrentMode
{
    deleteAudioButton.hidden = YES;
	[deleteAudioButton setTitle: NSLocalizedString(@"DiscardKey", @"") forState: UIControlStateNormal];
	[deleteAudioButton setTitle: NSLocalizedString(@"DiscardKey", @"") forState: UIControlStateHighlighted];
    
    CGRect frame = recordButton.frame;
    frame.size.width = [UIScreen mainScreen].bounds.size.width;
    
    switch (mode)
    {
		case kInnovAudioRecorderNoAudio:
			[recordButton setTitle: NSLocalizedString(@"BeginRecordingKey", @"") forState: UIControlStateNormal];
			[recordButton setTitle: NSLocalizedString(@"BeginRecordingKey", @"") forState: UIControlStateHighlighted];
			break;
		case kInnovAudioRecorderRecording:
			[recordButton setTitle: NSLocalizedString(@"StopRecordingKey", @"") forState: UIControlStateNormal];
			[recordButton setTitle: NSLocalizedString(@"StopRecordingKey", @"") forState: UIControlStateHighlighted];
			break;
		case kInnovAudioRecorderAudio:
			[recordButton setTitle: NSLocalizedString(@"PlayKey", @"") forState: UIControlStateNormal];
			[recordButton setTitle: NSLocalizedString(@"PlayKey", @"") forState: UIControlStateHighlighted];
			deleteAudioButton.hidden = NO;
            frame.size.width = [UIScreen mainScreen].bounds.size.width/2;//cell.frame.size.width;
			break;
		case kInnovAudioRecorderPlaying:
			[recordButton setTitle: NSLocalizedString(@"StopKey", @"") forState: UIControlStateNormal];
			[recordButton setTitle: NSLocalizedString(@"StopKey", @"") forState: UIControlStateHighlighted];
			break;
		default:
			break;
	}
    
    recordButton.frame = frame;
}

- (void)recordButtonPressed:(id)sender
{
	NSError *error;
	
	switch (mode) {
		case kInnovAudioRecorderNoAudio:
        {
            mode = kInnovAudioRecorderRecording;
			NSDictionary *recordSettings = [[NSDictionary alloc] initWithObjectsAndKeys:
											[NSNumber numberWithInt:kAudioFormatAppleIMA4],     AVFormatIDKey,
											[NSNumber numberWithInt:16000.0],                   AVSampleRateKey,
											[NSNumber numberWithInt: 1],                        AVNumberOfChannelsKey,
											[NSNumber numberWithInt: AVAudioQualityMin],        AVSampleRateConverterAudioQualityKey,
											nil];
            
			soundRecorder = [[AVAudioRecorder alloc] initWithURL: soundFileURL settings: recordSettings error: &error];
			[[Logger sharedLogger] logError:error];
            
			soundRecorder.delegate = self;
			[soundRecorder setMeteringEnabled:YES];
			[soundRecorder prepareToRecord];
			
			
			BOOL audioHWAvailable = [[AVAudioSession sharedInstance] inputIsAvailable];
			if (!audioHWAvailable) {
				UIAlertView *cantRecordAlert =
				[[UIAlertView alloc] initWithTitle: NSLocalizedString(@"NoAudioHardwareAvailableTitleKey", @"")
										   message: NSLocalizedString(@"NoAudioHardwareAvailableMessageKey", @"")
										  delegate: nil
								 cancelButtonTitle: NSLocalizedString(@"OkKey",@"")
								 otherButtonTitles: nil];
				[cantRecordAlert show];
				return;
			}
			
			[soundRecorder record];
            
			recordLengthCutoffAndPlayProgressTimer = [NSTimer scheduledTimerWithTimeInterval:PROGRESS_UPDATE_INTERVAL
                                                                                      target:self
                                                                                    selector:@selector(playOrRecordTimerResponse)
                                                                                    userInfo:nil
                                                                                     repeats:YES];
        }
            break;
			
		case kInnovAudioRecorderPlaying:
        {
            mode = kInnovAudioRecorderAudio;
            if (soundPlayer != nil)
                [soundPlayer stop];
            else
                [ARISMoviePlayer.moviePlayer stop];
            
            [recordLengthCutoffAndPlayProgressTimer invalidate];
			
            secondsRecordingOrPlaying = 0.0;
            recordButton.percentDone = 0.0;
            [recordButton setNeedsDisplay];
        }
            break;
			
		case kInnovAudioRecorderAudio:
        {
            mode = kInnovAudioRecorderPlaying;
            if(hasAudioToUpload)
            {
                if (soundPlayer == nil)
                {
                    soundPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:soundFileURL error:&error];
                    [[Logger sharedLogger] logError:error];
                    audioLength = soundPlayer.duration;
                    [soundPlayer prepareToPlay];
                    [soundPlayer setDelegate: self];
                }
                [soundPlayer play];
            }
            else
                [ARISMoviePlayer.moviePlayer play];
            
            recordLengthCutoffAndPlayProgressTimer = [NSTimer scheduledTimerWithTimeInterval:PROGRESS_UPDATE_INTERVAL
                                                                                      target:self
                                                                                    selector:@selector(playOrRecordTimerResponse)
                                                                                    userInfo:nil
                                                                                     repeats:YES];
        }
            break;
			
		case kInnovAudioRecorderRecording:
        {
            mode = kInnovAudioRecorderAudio;
            [recordLengthCutoffAndPlayProgressTimer invalidate];
			
            secondsRecordingOrPlaying = 0.0;
            recordButton.percentDone = 0.0;
            [recordButton setNeedsDisplay];
            
			[soundRecorder stop];
			soundRecorder = nil;
            
            hasAudioToUpload = YES;
        }
            break;
			
		default:
			break;
	}
    
    [self updateButtonsForCurrentMode];
}

- (void)playOrRecordTimerResponse
{
    secondsRecordingOrPlaying += PROGRESS_UPDATE_INTERVAL;
    
    if((secondsRecordingOrPlaying >= MAX_AUDIO_LENGTH && mode == kInnovAudioRecorderRecording) ||
       (secondsRecordingOrPlaying >= audioLength      && mode == kInnovAudioRecorderPlaying))
        [self recordButtonPressed:nil];
    else
    {
        if(mode == kInnovAudioRecorderRecording)
            recordButton.percentDone = secondsRecordingOrPlaying/MAX_AUDIO_LENGTH;
        else if(audioLength > 0)
            recordButton.percentDone = secondsRecordingOrPlaying/audioLength;
        [recordButton setNeedsDisplay];
    }
}

- (void)deleteAudioButtonPressed:(id)sender
{
    if(hasAudioToUpload) hasAudioToUpload = NO;
    else
    {
        for(int i = 0; i < [note.contents count]; ++i)
        {
            NoteContent *noteContent = [self.note.contents objectAtIndex:i];
            if([[noteContent getType] isEqualToString:kNoteContentTypeAudio])
            {
                if([[noteContent getUploadState] isEqualToString:@"uploadStateDONE"])
                    [[AppServices sharedAppServices] deleteNoteContentWithContentId:[noteContent getContentId] andNoteId:self.note.noteId];
                else
                    [[AppModel sharedAppModel].uploadManager deleteContentFromNoteId:self.note.noteId andFileURL:[NSURL URLWithString:[[noteContent getMedia] url]]];
                
                [self.note.contents removeObjectAtIndex:i];
            }
        }
        
        self.note.audioMediaId = 0;
    }
    
	soundPlayer = nil;
	mode = kInnovAudioRecorderNoAudio;
	[self updateButtonsForCurrentMode];
}

#pragma mark Audio Player Delegate Methods

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    if (mode == kInnovAudioRecorderPlaying)
        [self recordButtonPressed:nil];
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error {
	[[Logger sharedLogger] logError:error];
}

#pragma mark MPMoviePlayerController notifications

- (void)MPMoviePlayerLoadStateDidChange:(NSNotification *)notification
{
    if ((ARISMoviePlayer.moviePlayer.loadState & MPMovieLoadStatePlaythroughOK) == MPMovieLoadStatePlaythroughOK)
        audioLength = ARISMoviePlayer.moviePlayer.duration;
}

- (void)MPMoviePlayerPlaybackStateDidChange:(NSNotification *)notification
{
    if (ARISMoviePlayer.moviePlayer.playbackState == MPMoviePlaybackStatePlaying)
    {
        if (mode != kInnovAudioRecorderPlaying)
            [self recordButtonPressed:nil];
    }
}

- (void)MPMoviePlayerPlaybackDidFinishNotification:(NSNotification *)notif
{
    if (mode == kInnovAudioRecorderPlaying)
        [self recordButtonPressed:nil];
}

#pragma mark Sharing Methods

- (void)facebookButtonPressed:(UIButton *) sender
{
    shareToFacebook = !shareToFacebook;
    
    if(shareToFacebook)
    {
        socialView.facebookButton.alpha = 1.0f;
        if(![((ARISAppDelegate *)[[UIApplication sharedApplication] delegate]).simpleFacebookShare isLoggedIn])
            [((ARISAppDelegate *)[[UIApplication sharedApplication] delegate]).simpleFacebookShare openSession];
    }
    else
        socialView.facebookButton.alpha = NO_SHARE_ALPHA;
}

- (void)twitterButtonPressed:(UIButton *) sender
{
    shareToTwitter = !shareToTwitter;
    
    if(shareToTwitter)
    {
        socialView.twitterButton.alpha = 1.0f;
        if(![allTwitterAccounts count])
            [((ARISAppDelegate *)[[UIApplication sharedApplication] delegate]).simpleTwitterShare getAvailableTwitterAccounts];
        else
            [self presentTwitterAccountSelectionView];
    }
    else
        [self deselectTwitterButton];
}

- (void)selectTwitterAccounts:(NSNotification *) notif
{
    allTwitterAccounts = [notif.userInfo objectForKey:@"TwitterAccounts"];
    if([allTwitterAccounts count] > 0)
        [self presentTwitterAccountSelectionView];
    else
        [self deselectTwitterButton];
}

- (void) presentTwitterAccountSelectionView
{
    InnovPopOverTwitterAccountContentView *twitterView = [[InnovPopOverTwitterAccountContentView alloc] init];
    twitterView.delegate = self;
    [twitterView setInitialTwitterAccounts:allTwitterAccounts];
    popOver = [[InnovPopOverView alloc] initWithFrame:self.view.frame andContentView:twitterView];
    popOver.delegate = self;
    [self.view addSubview:popOver];
}

- (void) deselectTwitterButton
{
    shareToTwitter = NO;
    socialView.twitterButton.alpha = NO_SHARE_ALPHA;
}

#pragma mark PopOver View Delegate methods

- (void) popOverCancelled
{
    [self deselectTwitterButton];
}

#pragma mark Twitter Account Content View Delegate methods

- (void) setAvailableTwitterAccounts:(NSArray *) aTwitterAccounts
{
    selectedTwitterAccounts = aTwitterAccounts;
    if([selectedTwitterAccounts count] == 0)
        [self deselectTwitterButton];
}

/*
 - (void)updateMeter {
 [soundRecorder updateMeters];
 float levelInDb = [soundRecorder averagePowerForChannel:0];
 levelInDb = levelInDb + 160;
 
 //Level will always be between 0 and 160 now
 //Usually it will sit around 100 in quiet so we need to correct
 levelInDb = MAX(levelInDb - 100,0);
 float levelInZeroToOne = levelInDb / 60;
 
 NSLog(@"AudioRecorderLevel: %f, level in float:%f",levelInDb,levelInZeroToOne);
 
 self.meter updateLevel:levelInZeroToOne];
 }
 */

#pragma mark Table view methods

-(void)updateTags
{
    tagList = [InnovNoteModel sharedNoteModel].allTags;
    [editNoteTableView reloadSections:[NSIndexSet indexSetWithIndex:TagSection] withRowAnimation:UITableViewRowAnimationAutomatic];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return NumSections;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section)
    {
        case NoteContentSection:
            return 1;
        case RecordSection:
            return 1;
        case ShareSection:
            return 1;
        case TagSection:
            if(tagList.count > 0)
                return [tagList count];
            else
                return 1;
        case DropOnMapSection:
            return 1;
        case DeleteSection:
            return 1;
        default:
            return 1;
    }
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if(section == TagSection)
        return @"Categories";
    
    return nil;
}
#warning Eliminate Redundancy with Default
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section)
    {
        case NoteContentSection:
            return IMAGE_HEIGHT + 2 * NOTE_CONTENT_CELL_Y_MARGIN;
        case RecordSection:
            return 44;
        case ShareSection:
            return 2 * SHARE_BUTTON_HEIGHT;
        case TagSection:
            return 44;
        case DropOnMapSection:
            return DROP_ON_MAP_HEIGHT;
        case DeleteSection:
            return 44;
        default:
            return 44;
    }
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section)
    {
        case NoteContentSection:
        {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NoteContentCellIdentifier];
            if(!cell)
            {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NoteContentCellIdentifier];
                [cell addSubview:imageView];
                CGRect frame = captionTextView.frame;
                frame.size.width = cell.frame.size.width - 2 * NOTE_CONTENT_CELL_X_MARGIN - IMAGE_WIDTH - NOTE_CONTENT_IMAGE_TEXT_MARGIN;
                captionTextView.frame = frame;
                [cell addSubview:captionTextView];
                [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            }
            return cell;
        }
        case RecordSection:
        {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:RecordCellIdentifier];
            if(!cell)
            {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:RecordCellIdentifier];
                recordButton.backgroundColor = [UIColor blackColor];
                [cell addSubview:recordButton];
                CGRect frame = deleteAudioButton.frame;
                frame.size.width = [UIScreen mainScreen].bounds.size.width/2; // cell.frame.size.width;
                frame.origin.x = [UIScreen mainScreen].bounds.size.width/2; //recordButton.frame.origin.x + recordButton.frame.size.width;
                deleteAudioButton.frame = frame;
                deleteAudioButton.backgroundColor = [UIColor blueColor];
                [cell addSubview:deleteAudioButton];
                [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            }
            
            return cell;
        }
        case ShareSection:
        {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ShareCellIdentifier];
            if(!cell)
            {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ShareCellIdentifier];
                socialView = [[InnovPopOverSocialContentView alloc] init];
                socialView.frame = CGRectMake(([UIScreen mainScreen].bounds.size.width - tableView.frame.size.width/16.0*15.0)/2, 0, tableView.frame.size.width/16.0*15.0, 2 * SHARE_BUTTON_HEIGHT);
                socialView.note = self.note;
                [[NSNotificationCenter defaultCenter] removeObserver:socialView name:@"NoteModelUpdate:Notes" object:nil];
                [socialView.shareLabel     removeFromSuperview];
                [socialView.facebookBadge  removeFromSuperview];
                [socialView.twitterBadge   removeFromSuperview];
                [socialView.pinterestBadge removeFromSuperview];
                [socialView.emailBadge     removeFromSuperview];
                socialView.facebookButton.frame  = CGRectMake(     socialView.frame.size.width /4-SHARE_BUTTON_WIDTH/2, 0,                   SHARE_BUTTON_WIDTH, SHARE_BUTTON_HEIGHT);
                socialView.twitterButton.frame   = CGRectMake((3 * socialView.frame.size.width)/4-SHARE_BUTTON_WIDTH/2, 0,                   SHARE_BUTTON_WIDTH, SHARE_BUTTON_HEIGHT);
                socialView.pinterestButton.frame = CGRectMake(     socialView.frame.size.width /4-SHARE_BUTTON_WIDTH/2, SHARE_BUTTON_HEIGHT, SHARE_BUTTON_WIDTH, SHARE_BUTTON_HEIGHT);
                socialView.emailButton.frame     = CGRectMake((3 * socialView.frame.size.width)/4-SHARE_BUTTON_WIDTH/2, SHARE_BUTTON_HEIGHT, SHARE_BUTTON_WIDTH, SHARE_BUTTON_HEIGHT);
                [socialView.facebookButton removeTarget:socialView action:@selector(facebookButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
                [socialView.twitterButton  removeTarget:socialView action:@selector(twitterButtonPressed:)  forControlEvents:UIControlEventTouchUpInside];
                [socialView.facebookButton addTarget:   self       action:@selector(facebookButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
                [socialView.twitterButton  addTarget:   self       action:@selector(twitterButtonPressed:)  forControlEvents:UIControlEventTouchUpInside];
                socialView.layer.masksToBounds = YES;
                socialView.layer.cornerRadius  = 8.0f;
                cell.backgroundView = [UIView new];
                [cell addSubview:socialView];
                [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            }
            
            if(shareToFacebook)
                socialView.facebookButton.alpha = 1.0f;
            else
                socialView.facebookButton.alpha = NO_SHARE_ALPHA;
            
            if(shareToTwitter)
                socialView.twitterButton.alpha = 1.0f;
            else
                socialView.twitterButton.alpha = NO_SHARE_ALPHA;
            
            return cell;
        }
        case TagSection:
        {
            InnovTagCell *cell = [tableView dequeueReusableCellWithIdentifier:TagCellIdentifier];
            if (cell == nil)
            {
                cell = [[InnovTagCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:TagCellIdentifier];
                [cell.textLabel setNumberOfLines:1];
                [cell.textLabel setLineBreakMode:UILineBreakModeTailTruncation];
                [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            }
            
            if([tagList count] == 0) [cell.textLabel setText: @"No Categories in Application"];
            else [cell.textLabel setText:((Tag *)[tagList objectAtIndex:indexPath.row]).tagName];
          
            if(([newTagName length] > 0 && [newTagName isEqualToString:((Tag *)[tagList objectAtIndex:indexPath.row]).tagName]) || ([newTagName length] == 0 && [originalTagName isEqualToString:((Tag *)[tagList objectAtIndex:indexPath.row]).tagName])) [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
            
            return cell;
        }
        case DropOnMapSection:
        {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:DropOnMapCellIdentifier];
            if(!cell)
            {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:DropOnMapCellIdentifier];
                dropOnMapVC.view.frame = CGRectMake(0, 0, cell.frame.size.width, cell.frame.size.height+2);
                [cell addSubview:dropOnMapVC.view];
                [dropOnMapVC didMoveToParentViewController:self];
                [dropOnMapVC showAnnotation];
                [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            }
            return cell;
        }
        case DeleteSection:
        {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:DeleteCellIdentifier];
            if(!cell)
            {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:DeleteCellIdentifier];
                CGRect frame = deleteNoteButton.frame;
                frame.size.width = cell.frame.size.width;
                deleteNoteButton.frame = frame;
                [cell addSubview:deleteNoteButton];
                [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            }
            return cell;
        }
        default:
            return nil;
    }
}

-(NSIndexPath *)tableView:(UITableView *) tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section == TagSection)
    {
        CGSize labelSize = [cell.textLabel.text sizeWithFont:[UIFont boldSystemFontOfSize:17.0] constrainedToSize:CGSizeMake(MAXFLOAT, MAXFLOAT) lineBreakMode:UILineBreakModeTailTruncation];
        
        int defaultTextLabelXMargin = cell.textLabel.frame.origin.x;
        if(defaultTextLabelXMargin == 0)
            defaultTextLabelXMargin = 10;
        
        ((InnovTagCell *)cell).mediaImageView.frame = CGRectMake( defaultTextLabelXMargin + labelSize.width + SPACING,
                                               (cell.frame.size.height - IMAGEHEIGHT)/2,
                                               IMAGEWIDTH,
                                               IMAGEHEIGHT);
        
        int mediaId = ((Tag *)[tagList  objectAtIndex:indexPath.row]).mediaId;
        if(mediaId != 0)
            [((InnovTagCell *)cell).mediaImageView loadImageFromMedia:[[AppModel sharedAppModel] mediaForMediaId:mediaId]];
        else
            [((InnovTagCell *)cell).mediaImageView setImage:[UIImage imageNamed:@"noteicon.png"]];
    }
    
    return indexPath;
}

-(NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //Not considered selected when auto set to first row, so clear first row
    if(indexPath.section == TagSection)
    {
        [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:TagSection]].accessoryType = UITableViewCellAccessoryNone;
        
        NSIndexPath *oldIndex = [tableView indexPathForSelectedRow];
        [tableView cellForRowAtIndexPath:oldIndex].accessoryType = UITableViewCellAccessoryNone;
    }
    
    return indexPath;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section == TagSection)
    {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        
        newTagName = cell.textLabel.text;
        
        self.title = newTagName;
    }
}

#pragma mark Dealloc, and Other Necessary Methods

- (void)dealloc
{
    [[AVAudioSession sharedInstance] setDelegate: nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload
{
    imageView = nil;
    captionTextView = nil;
    recordButton = nil;
    deleteAudioButton = nil;
    editNoteTableView = nil;
    [super viewDidUnload];
}

@end