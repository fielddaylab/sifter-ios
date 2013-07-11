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
#import "TagCell.h"

#import "ProgressButton.h"
#import "InnovPopOverSocialContentView.h"
#import "AsyncMediaTouchableImageView.h"
#import "ARISMoviePlayerViewController.h"
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

#define CANCEL_BUTTON_TITLE @"Cancel"
#define SHARE_BUTTON_TITLE  @"Share"

static NSString *NoteContentCellIdentifier = @"NoteConentCell";
static NSString *RecordCellIdentifier      = @"RecordCell";
static NSString *ShareCellIdentifier       = @"ShareCell";
static NSString *TagCellIdentifier         = @"TagCell";
static NSString *DeleteCellIdentifier      = @"DeleteCell";

@interface InnovNoteEditorViewController ()<AVAudioSessionDelegate, AVAudioRecorderDelegate, AVAudioPlayerDelegate, UITextViewDelegate, UITableViewDataSource, UITableViewDelegate, AsyncMediaTouchableImageViewDelegate, AsyncMediaImageViewDelegate, CameraViewControllerDelegate> {
    
    __weak IBOutlet UITableView *editNoteTableView;
    AsyncMediaTouchableImageView *imageView;
    UITextView *captionTextView;
    
    BOOL shareToFacebook;
    BOOL shareToTwitter;
    InnovPopOverSocialContentView *socialView;
    
    ProgressButton *recordButton;
    UIButton *deleteAudioButton;
    UIButton *deleteNoteButton;
    
    UIBarButtonItem *cancelButton;
    
    Note *note;
    
    BOOL newNote;
    BOOL noteCompleted;
    BOOL isEditing;
    BOOL cameraHasBeenPresented;
    
    int originalTagId;
    NSString  *originalTagName;
    int selectedIndex;
    NSString  *newTagName;
    NSArray *tagList;
    
    BOOL deletePressed;
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
}

@end

@implementation InnovNoteEditorViewController

@synthesize note, delegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshViewFromModel) name:@"NoteModelUpdate:Notes" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTags) name:@"NoteModelUpdate:Tags"  object:nil];
        
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
                                                   action:@selector(backButtonTouchAction:)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle: SHARE_BUTTON_TITLE
                                                                   style: UIBarButtonItemStyleDone
                                                                  target:self
                                                                  action:@selector(backButtonTouchAction:)];
    self.navigationItem.rightBarButtonItem = doneButton;
    
    imageView = [[AsyncMediaTouchableImageView alloc] initWithFrame:CGRectMake(NOTE_CONTENT_CELL_X_MARGIN, NOTE_CONTENT_CELL_Y_MARGIN, IMAGE_WIDTH, IMAGE_HEIGHT)];
    imageView.delegate = self;
    
    captionTextView = [[UITextView alloc] initWithFrame:CGRectMake(NOTE_CONTENT_CELL_X_MARGIN + imageView.frame.size.width + NOTE_CONTENT_IMAGE_TEXT_MARGIN, NOTE_CONTENT_CELL_Y_MARGIN, 196, IMAGE_HEIGHT)];
    captionTextView.delegate = self;
    
    recordButton = [[ProgressButton alloc] initWithFrame:CGRectMake(0, 0, 44, 46)];
    [recordButton addTarget:self action:@selector(recordButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    deleteAudioButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 44, 46)];
    [deleteAudioButton addTarget:self action:@selector(deleteAudioButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    deleteNoteButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 44, 46)];
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
    
    if(self.note.noteId != 0)
    {
#warning when do we edit
        isEditing = YES;
        
        captionTextView.text = note.text;
        
        if([note.text length] > 0 && ![note.text isEqualToString:DEFAULT_TEXT])
            captionTextView.textColor = [UIColor blackColor];
        
        imageView.userInteractionEnabled = YES;
        
        [editNoteTableView reloadData];
        
        if([self.note.tags count] > 0)
        {
            originalTagId = ((Tag *)[self.note.tags objectAtIndex:0]).tagId;
            originalTagName = ((Tag *)[self.note.tags objectAtIndex:0]).tagName;
            self.title = originalTagName;
            int index = [tagList indexOfObject:((Tag *)[self.note.tags objectAtIndex:0])];
            if(index == NSNotFound)
            {
                for(int i = 0; i < [tagList count]; ++i)
                {
                    if(((Tag *)[tagList objectAtIndex:i]).tagId == ((Tag *)[self.note.tags objectAtIndex:0]).tagId)
                    {
                        index = i;
                        break;
                    }
                }
            }
            [editNoteTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:TagSection]].accessoryType = UITableViewCellAccessoryCheckmark;
        }
        else
            [self tableView:editNoteTableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:TagSection]];
        
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
        isEditing = NO;
        newNote = YES;
#warning should allows show on List and Map?
        if(self.note.noteId == 0)
        {
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle: NSLocalizedString(@"NoteEditorCreateNoteFailedKey", @"") message: NSLocalizedString(@"NoteEditorCreateNoteFailedMessageKey", @"") delegate:self.delegate cancelButtonTitle: NSLocalizedString(@"OkKey", @"") otherButtonTitles: nil];
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
    
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [recordLengthCutoffAndPlayProgressTimer invalidate];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerLoadStateDidChangeNotification      object:ARISMoviePlayer.moviePlayer];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackStateDidChangeNotification  object:ARISMoviePlayer.moviePlayer];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification       object:ARISMoviePlayer.moviePlayer];
    
    if(!self.note || (newNote && !isEditing) || !noteCompleted)
        return;
    
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
#warning must be forced to yes due to the forced refresh after the camera, so facebook can have the image url in time
    [[AppServices sharedAppServices] updateNoteWithNoteId:self.note.noteId title:self.note.title publicToMap:YES publicToList:YES];
    
    if(mode == kInnovAudioRecorderRecording) [self recordButtonPressed:nil];
    if(hasAudioToUpload) [[[AppModel sharedAppModel]uploadManager] uploadContentForNoteId:self.note.noteId withTitle:[NSString stringWithFormat:@"%@",[NSDate date]] withText:nil withType:kNoteContentTypeAudio withFileURL:soundFileURL];
    
    if([newTagName length] > 0 && ![originalTagName isEqualToString:newTagName])
    {
        if(originalTagId != 0) [[AppServices sharedAppServices] deleteTagFromNote:self.note.noteId tagId:originalTagId];
        [[AppServices sharedAppServices] addTagToNote:self.note.noteId tagName:newTagName];
        
        Tag *tag = [[Tag alloc] init];
        tag.tagName = newTagName;
        [self.note.tags addObject:tag];
    }
    
#warning point where added to map may change
    if(newNote)
    {
        [[AppServices sharedAppServices] dropNote:self.note.noteId atCoordinate:[AppModel sharedAppModel].playerLocation.coordinate];
        [[AppServices sharedAppServices] setNoteCompleteForNoteId:self.note.noteId];
        
        self.note.latitude  = [AppModel sharedAppModel].playerLocation.coordinate.latitude;
        self.note.longitude = [AppModel sharedAppModel].playerLocation.coordinate.longitude;
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
        [((ARISAppDelegate *)[[UIApplication sharedApplication] delegate]).simpleTwitterShare shareText:text withImage:nil andURL:url fromNote:self.note.noteId automatically:YES];
    }
    
    NSError *error;
    [[AVAudioSession sharedInstance] setActive: NO error: &error];
    [[Logger sharedLogger] logError:error];
    
    [self.delegate prepareToDisplayNote: self.note];
    
    newNote = NO;
    self.note = nil;
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

- (void)backButtonTouchAction: (id) sender
{
    BOOL cancelPressed = [sender isKindOfClass: [UIBarButtonItem class]] && [((UIBarButtonItem *) sender).title isEqualToString:CANCEL_BUTTON_TITLE];
    if((!isEditing || newNote || deletePressed) && !([sender isKindOfClass: [UIBarButtonItem class]] && [((UIBarButtonItem *) sender).title isEqualToString:SHARE_BUTTON_TITLE]))
    {
        [[AppServices sharedAppServices]  deleteNoteWithNoteId:self.note.noteId];
        [[InnovNoteModel sharedNoteModel] removeNote:note];
        noteCompleted = NO;
    }
    else
        noteCompleted = YES;
    
    noteCompleted = noteCompleted && !cancelPressed;
    
    NSError *error;
    [[AVAudioSession sharedInstance] setActive: NO error: &error];
    [[Logger sharedLogger] logError:error];
    
    [self.navigationController popToViewController:(UIViewController *)self.delegate animated:YES];
}

-(void)cameraButtonTouchAction
{
    CameraViewController *cameraVC = [[CameraViewController alloc] init];
    
    if(isEditing) cameraVC.backView = self;
    else cameraVC.backView = self.delegate;
    cameraVC.editView = self;
    cameraVC.noteId = self.note.noteId;
    
    cameraHasBeenPresented = YES;
    
    [self.navigationController pushViewController:cameraVC animated:NO];
}

- (void)deleteNoteButtonPressed:(id)sender
{
    deletePressed = YES;
    [self backButtonTouchAction:nil];
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
								 otherButtonTitles:nil];
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
        socialView.facebookButton.alpha = 1.0f;
    else
        socialView.facebookButton.alpha = NO_SHARE_ALPHA;
}

- (void)twitterButtonPressed:(UIButton *) sender
{
    shareToTwitter = !shareToTwitter;
    
    if(shareToTwitter)
        socialView.twitterButton.alpha = 1.0f;
    else
        socialView.twitterButton.alpha = NO_SHARE_ALPHA;
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

/*
 [[AppServices sharedAppServices]deleteNoteLocationWithNoteId:self.note.noteId];
 
 DropOnMapViewController *mapVC = [[DropOnMapViewController alloc] initWithNibName:@"DropOnMapViewController" bundle:nil] ;
 mapVC.noteId = self.note.noteId;
 mapVC.delegate = self;
 self.noteValid = YES;
 self.mapButton.selected = YES;
 
 [self.navigationController pushViewController:mapVC animated:NO];
 
 
 [[AppServices sharedAppServices] updateNoteWithNoteId:self.note.noteId title:self.textField.text publicToMap:self.note.showOnMap publicToList:self.note.showOnList];
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
        case DeleteSection:
            return 1;
        default:
            return 1;
    }
}
#warning Check if Still has blank space
-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    if(section == TagSection)
        return @"Categories";
   
    return nil;
}
#warning Eliminate Redundancy with Default
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
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
        case DeleteSection:
            return 44;
        default:
            return 44;
    }
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    switch (indexPath.section)
    {
        case NoteContentSection:
        {
            UITableViewCell *cell = (TagCell *)[tableView dequeueReusableCellWithIdentifier:NoteContentCellIdentifier];
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
            UITableViewCell *cell = (TagCell *)[tableView dequeueReusableCellWithIdentifier:RecordCellIdentifier];
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
            UITableViewCell *cell = (TagCell *)[tableView dequeueReusableCellWithIdentifier:ShareCellIdentifier];
            if(!cell)
            {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ShareCellIdentifier];
#warning FIX
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
            UITableViewCell *tempCell = (TagCell *)[tableView dequeueReusableCellWithIdentifier:TagCellIdentifier];
            if (![tempCell respondsToSelector:@selector(nameLabel)]) tempCell = nil;
            TagCell *cell = (TagCell *)tempCell;
            
#warning Doesn't Re-use Cell. I'm re-using ARIS code, but should be refactored
            if (cell == nil) {
                // Create a temporary UIViewController to instantiate the custom cell.
                UIViewController *temporaryController = [[UIViewController alloc] initWithNibName:@"TagCell" bundle:nil];
                // Grab a pointer to the custom cell.
                cell = (TagCell *)temporaryController.view;
                // Release the temporary UIViewController.
                [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            }
            
            if([tagList count] == 0) cell.nameLabel.text = @"No Categories in Application";
            else cell.nameLabel.text = ((Tag *)[tagList objectAtIndex:indexPath.row]).tagName;
            
            if(([newTagName length] > 0 && [newTagName isEqualToString:((Tag *)[tagList objectAtIndex:indexPath.row]).tagName]) || ([newTagName length] == 0 && [originalTagName isEqualToString:((Tag *)[tagList objectAtIndex:indexPath.row]).tagName])) [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
            
            return cell;
        }
        case DeleteSection:
        {
            UITableViewCell *cell = (TagCell *)[tableView dequeueReusableCellWithIdentifier:DeleteCellIdentifier];
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
        TagCell *cell = (TagCell *)[tableView cellForRowAtIndexPath:indexPath];
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        
        newTagName = cell.nameLabel.text;
        
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

- (void)viewDidUnload {
    imageView = nil;
    captionTextView = nil;
    recordButton = nil;
    deleteAudioButton = nil;
    editNoteTableView = nil;
    [super viewDidUnload];
}

@end