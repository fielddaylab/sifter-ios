//
//  InnovNoteViewController.m
//  YOI
//
//  Created by Jacob James Hanshaw on 5/8/13.
//
//

#import "InnovNoteViewController.h"
#import <CoreAudio/CoreAudioTypes.h>

#import "AppModel.h"
#import "AppServices.h"
#import "InnovAudioEnums.h"
#import "Note.h"
#import "Tag.h"
#import "Logger.h"

#import "DAKeyboardControl.h"
#import "AsyncMediaTouchableImageView.h"
#import "InnovNoteEditorViewController.h"
#import "ARISMoviePlayerViewController.h"
#import "NoteCommentViewController.h"

#define ANIMATION_TIME      0.5

#define IMAGE_X_MARGIN      20
#define IMAGE_Y_MARGIN      20

#define BUTTON_WIDTH        36
#define BUTTON_HEIGHT       36

#define DEFAULT_TEXT        @"Add a comment..."
#define DEFAULT_TEXT_SIZE   14

#define EXPAND_INDEX                 3
#define DEFAULT_MAX_VISIBLE_COMMENTS 5

static NSString * const NOTE_CELL_ID    = @"NoteCell";
static NSString * const COMMENT_CELL_ID = @"CommentCell";

@interface InnovNoteViewController ()<UITextViewDelegate, UITableViewDataSource, UITableViewDelegate, AsyncMediaTouchableImageViewDelegate, AsyncMediaImageViewDelegate, InnovNoteEditorViewDelegate>
{
    __weak IBOutlet UITableView *noteTableView;
    __weak IBOutlet UIView *addCommentView;
    __weak IBOutlet UITextView *addCommentTextView;
    __weak IBOutlet UIButton *addCommentButton;
    
    AsyncMediaTouchableImageView *imageView;
    UILabel  *usernameLabel;
    UIButton *flagButton;
    UIButton *playButton;
    UIButton *likeButton;
    UIButton *shareButton;
    UITextView *captionTextView;
    
    Note *note;
    Note *noteComment;
    UIBarButtonItem *editButton;
    //UIBarButtonItem *cancelButton;
    id __unsafe_unretained delegate;
    
    CGRect originalImageViewFrame;
    
    BOOL expanded;
	InnovAudioViewerModeType mode;
    BOOL shouldAutoPlay;
    ARISMoviePlayerViewController *ARISMoviePlayer;
    
}

@end

@implementation InnovNoteViewController

@synthesize note, delegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        [addCommentTextView addObserver:self forKeyPath:@"contentSize" options:(NSKeyValueObservingOptionNew) context:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshViewFromModel) name:@"NewNoteListReady" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(MPMoviePlayerPlaybackDidFinishNotification:) name:MPMoviePlayerPlaybackDidFinishNotification object:ARISMoviePlayer.moviePlayer];
    }
    return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    /*  cancelButton = [[UIBarButtonItem alloc] initWithTitle: @"Back"
     style: UIBarButtonItemStyleDone
     target:self
     action:@selector(backButtonTouchAction:)];
     self.navigationItem.leftBarButtonItem = cancelButton; */
    
    editButton = [[UIBarButtonItem alloc] initWithTitle: @"Edit"
                                                  style: UIBarButtonItemStyleDone
                                                 target:self
                                                 action:@selector(editButtonTouchAction:)];
    self.navigationItem.rightBarButtonItem = editButton;
    
    // [self refreshComments];
    
    ARISMoviePlayer = [[ARISMoviePlayerViewController alloc] init];
    ARISMoviePlayer.view.frame = CGRectMake(0, 0, 1, 1);
    ARISMoviePlayer.moviePlayer.view.hidden = YES;
    [self.view addSubview:ARISMoviePlayer.view];
    ARISMoviePlayer.moviePlayer.movieSourceType = MPMovieSourceTypeStreaming;
    [ARISMoviePlayer.moviePlayer setControlStyle:MPMovieControlStyleNone];
    ARISMoviePlayer.moviePlayer.shouldAutoplay = shouldAutoPlay;
#warning never changed; Could do messages and update from model
    [ARISMoviePlayer.moviePlayer setFullscreen:NO];
    
    self.view.keyboardTriggerOffset = addCommentView.bounds.size.height;
    
    [self.view addKeyboardPanningWithActionHandler:^(CGRect keyboardFrameInView) {
        /*
         Try not to call "self" inside this block (retain cycle).
         But if you do, make sure to remove DAKeyboardControl
         when you are done with the view controller by calling:
         [self.view removeKeyboardControl];
         */
        
        CGRect addCommentViewFrame = addCommentView.frame;
        addCommentViewFrame.origin.y = keyboardFrameInView.origin.y - addCommentViewFrame.size.height;
        addCommentView.frame = addCommentViewFrame;
        
        CGRect tableViewFrame = noteTableView.frame;
        tableViewFrame.size.height = addCommentViewFrame.origin.y;
        noteTableView.frame = tableViewFrame;
        
        [self prepareNoteComment];
    }];
    
    imageView = [[AsyncMediaTouchableImageView alloc] init];
    imageView.frame = CGRectMake(IMAGE_X_MARGIN, IMAGE_Y_MARGIN, self.view.frame.size.width - 2 * IMAGE_X_MARGIN, self.view.frame.size.width - 2 * IMAGE_X_MARGIN);
    imageView.delegate = self;
    
    usernameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, IMAGE_Y_MARGIN + imageView.frame.size.height, self.view.frame.size.width-4*BUTTON_WIDTH, BUTTON_HEIGHT)];
    usernameLabel.backgroundColor = [UIColor blackColor];
    usernameLabel.textColor       = [UIColor whiteColor];
    
    flagButton  = [[UIButton alloc] initWithFrame:CGRectMake(usernameLabel.frame.size.width,            IMAGE_Y_MARGIN + imageView.frame.size.height, BUTTON_WIDTH, BUTTON_HEIGHT)];
    flagButton.backgroundColor = [UIColor blackColor];
    //   [flagButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    //   [flagButton setTitleColor:[UIColor blackColor] forState:UIControlStateHighlighted];
    [flagButton setTitle:@"F" forState:UIControlStateNormal];
    [flagButton setTitle:@"F" forState:UIControlStateHighlighted];
	[flagButton addTarget:self action:@selector(flagButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    playButton  = [[UIButton alloc] initWithFrame:CGRectMake(flagButton.frame.origin.x  + BUTTON_WIDTH, IMAGE_Y_MARGIN + imageView.frame.size.height, BUTTON_WIDTH, BUTTON_HEIGHT)];
    playButton.backgroundColor = [UIColor blackColor];
    [playButton setTitle:@"PL" forState:UIControlStateNormal];
    [playButton setTitle:@"PL" forState:UIControlStateHighlighted];
	[playButton addTarget:self action:@selector(playButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    likeButton  = [[UIButton alloc] initWithFrame:CGRectMake(playButton.frame.origin.x  + BUTTON_WIDTH, IMAGE_Y_MARGIN + imageView.frame.size.height, BUTTON_WIDTH, BUTTON_HEIGHT)];
    likeButton.backgroundColor = [UIColor blackColor];
    [likeButton setTitle:@"L" forState:UIControlStateNormal];
    [likeButton setTitle:@"L" forState:UIControlStateHighlighted];
	[likeButton addTarget:self action:@selector(likeButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    shareButton = [[UIButton alloc] initWithFrame:CGRectMake(likeButton.frame.origin.x + BUTTON_WIDTH,  IMAGE_Y_MARGIN + imageView.frame.size.height, BUTTON_WIDTH, BUTTON_HEIGHT)];
    shareButton.backgroundColor = [UIColor blackColor];
    [shareButton setTitle:@"S" forState:UIControlStateNormal];
    [shareButton setTitle:@"S" forState:UIControlStateHighlighted];
	[shareButton addTarget:self action:@selector(shareButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    captionTextView = [[UITextView alloc] initWithFrame:CGRectMake(0, IMAGE_Y_MARGIN + imageView.frame.size.height + BUTTON_HEIGHT, self.view.frame.size.width, BUTTON_HEIGHT)];
    captionTextView.delegate = self;
    captionTextView.userInteractionEnabled = NO;
}

- (void)viewDidUnload {
    imageView = nil;
    captionTextView = nil;
    playButton = nil;
    noteTableView = nil;
    addCommentView = nil;
    addCommentTextView = nil;
    addCommentButton = nil;
    
    [self.view removeKeyboardControl];
    
    [super viewDidUnload];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear: animated];
    
    captionTextView.text = [self.note.title substringToIndex: [self.note.title rangeOfString:@"#" options:NSBackwardsSearch].location];
    
    addCommentTextView.text = DEFAULT_TEXT;
    addCommentTextView.textColor = [UIColor lightGrayColor];
    
    imageView.userInteractionEnabled = YES;
    originalImageViewFrame = imageView.frame;
    
    if([self.note.tags count] > 0)
        self.title = ((Tag *)[self.note.tags objectAtIndex:0]).tagName;
    else self.title = @"Note";
    
    if (self.note.creatorId == [AppModel sharedAppModel].playerId)
        self.navigationItem.rightBarButtonItem = editButton;
    else
        self.navigationItem.rightBarButtonItem = nil;
    
    mode = kInnovAudioPlayerNoAudio;
    [self updateButtonsForCurrentMode];
    
    [self refreshViewFromModel];
    
}
/*
 -(void)shouldAlsoExit:(BOOL)shouldExit
 {
 if(shouldExit) [self.navigationController popViewControllerAnimated:NO];
 }
 */
-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
#warning may want to do something to pass note down the line
}

#pragma mark UITextView methods

#warning CHECK IF AUTO ENABLE RETURN WORKED

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    
    [captionTextView resignFirstResponder];
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    textView.textColor = [UIColor blackColor];
    if([textView.text isEqualToString:DEFAULT_TEXT]) textView.text = @"";
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    UITextView *textView = object;
    if (([textView bounds].size.height - [textView contentSize].height) > 0)
    {
        CGFloat topCorrect = ([textView bounds].size.height - [textView contentSize].height * [textView zoomScale])/2.0;
        topCorrect = ( topCorrect < 0.0 ? 0.0 : topCorrect );
        textView.contentOffset = (CGPoint){.x = 0, .y = -topCorrect};
    }
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    }
    
    return YES;
}

#pragma mark UIImageView methods

-(void) asyncMediaImageTouched:(id)sender
{
    [self toggleImageFullScreen];
}


-(void) toggleImageFullScreen
{
    if(![self framesAreEqual:self.view.frame and:imageView.frame])
    {
        [UIView beginAnimations:@"imageViewExpand" context:NULL];
        [UIView setAnimationDuration:ANIMATION_TIME];
        imageView.frame = self.view.frame;
        [UIView commitAnimations];
    }
    else
    {
        [UIView beginAnimations:@"imageViewShrunk" context:NULL];
        [UIView setAnimationDuration:ANIMATION_TIME];
        imageView.frame = originalImageViewFrame;
        [UIView commitAnimations];
    }
}

-(BOOL) framesAreEqual: (CGRect) frameA and: (CGRect) frameB
{
    return (frameA.origin.x == frameB.origin.x &&
            frameA.origin.y == frameB.origin.y &&
            frameA.size.width == frameB.size.width &&
            frameA.size.height == frameB.size.height);
}

#pragma mark Button methods

- (IBAction)editButtonTouchAction: (id) sender
{
    InnovNoteEditorViewController *editVC = [[InnovNoteEditorViewController alloc] init];
    editVC.note = self.note;
    editVC.delegate = self.delegate;
    [self.navigationController pushViewController:editVC animated:YES];
}

- (void)flagButtonPressed:(id)sender
{
#warning unimplemented
}

- (void) prepareNoteComment
{
    
}

- (IBAction)commentButtonPressed:(id)sender {
    [addCommentTextView resignFirstResponder];
    
    if([addCommentTextView.text length] > 0 && ![addCommentTextView.text isEqualToString:DEFAULT_TEXT])
    {
        Note *commentNote = [[Note alloc] init];
        commentNote.noteId = [[AppServices sharedAppServices]addCommentToNoteWithId:self.note.noteId andTitle:@""];
        
        commentNote.title = addCommentTextView.text;
        commentNote.parentNoteId = self.note.noteId;
        commentNote.creatorId = [AppModel sharedAppModel].playerId;
        commentNote.username = [AppModel sharedAppModel].userName;
#warning probably unnecessary to do this second call
        [[AppServices sharedAppServices]updateCommentWithId:commentNote.noteId andTitle:commentNote.title andRefresh:YES];
        
        [self.note.comments insertObject:commentNote atIndex:0];
        [[AppModel sharedAppModel].gameNoteList   setObject:self.note forKey:[NSNumber numberWithInt:self.note.noteId]];
        
        addCommentTextView.text = @"";
    }
}

- (void)likeButtonPressed:(id)sender
{
#warning unimplemented
}

- (void)shareButtonPressed:(id)sender
{
#warning unimplemented
}

#pragma mark Note Contents

- (void)refreshViewFromModel
{
#warning was playernotelist
    self.note = [[[AppModel sharedAppModel] gameNoteList] objectForKey:[NSNumber numberWithInt:self.note.noteId]];
    [self addCDUploadsToNote];
    [self addUploadsToComments];
    
    for(int i = 0; i < [self.note.contents count]; ++i)
    {
        NoteContent *noteContent = [self.note.contents objectAtIndex:i];
        if([[noteContent getType] isEqualToString:kNoteContentTypePhoto]) {
            [imageView loadImageFromMedia:[noteContent getMedia]];
        }
        else if ([[noteContent getType] isEqualToString:kNoteContentTypeAudio]) {
            if (![[ARISMoviePlayer.moviePlayer.contentURL absoluteString] isEqualToString: noteContent.getMedia.url]) {
                [ARISMoviePlayer.moviePlayer setContentURL: [NSURL URLWithString:noteContent.getMedia.url]];
                [ARISMoviePlayer.moviePlayer prepareToPlay];
			}
            mode = kInnovAudioPlayerAudio;
            [self updateButtonsForCurrentMode];
        }
#warning test moviePlayer Audio
    }
    
    [noteTableView reloadData];
}

-(void)addCDUploadsToNote
{
    for(int x = [self.note.contents count]-1; x >= 0; x--)
    {
        //Removes note contents that are not done uploading, because they will all be added again right after this loop
        if((NSObject <NoteContentProtocol> *)[[self.note.contents objectAtIndex:x] managedObjectContext] == nil ||
           ![[[self.note.contents objectAtIndex:x] getUploadState] isEqualToString:@"uploadStateDONE"])
            [self.note.contents removeObjectAtIndex:x];
    }
    
    NSArray *uploadContentsForNote = [[[AppModel sharedAppModel].uploadManager.uploadContentsForNotes objectForKey:[NSNumber numberWithInt:self.note.noteId]]allValues];
    [self.note.contents addObjectsFromArray:uploadContentsForNote];
    NSLog(@"InnovNoteVC: Added %d upload content(s) to note",[uploadContentsForNote count]);
}

#warning necessary?
-(void)addUploadsToComments
{
    for(int i = 0; i < [self.note.comments count]; i++)
    {
        Note *currNote = [self.note.comments objectAtIndex:i];
        for(int x = [currNote.contents count]-1; x >= 0; x--)
        {
            if(![[[currNote.contents objectAtIndex:x] getUploadState] isEqualToString:@"uploadStateDONE"])
                [currNote.contents removeObjectAtIndex:x];
        }
        
        NSMutableDictionary *uploads = [AppModel sharedAppModel].uploadManager.uploadContentsForNotes;
        NSArray *uploadContentForNote = [[uploads objectForKey:[NSNumber numberWithInt:currNote.noteId]] allValues];
        [currNote.contents addObjectsFromArray:uploadContentForNote];
        NSLog(@"InnovNoteVC: Added %d upload content(s) to note",[uploadContentForNote count]);
    }
}

#pragma mark Audio Methods

- (void)updateButtonsForCurrentMode{
    
    playButton.hidden = NO;
    
#warning use new titles
    
    switch (mode) {
		case kInnovAudioPlayerNoAudio:
			playButton.hidden = YES;
			break;
		case kInnovAudioPlayerAudio:
			[playButton setTitle: @"PL" forState: UIControlStateNormal];
			[playButton setTitle: @"PL" forState: UIControlStateHighlighted];
			break;
		case kInnovAudioPlayerPlaying:
			[playButton setTitle: @"ST" forState: UIControlStateNormal];
			[playButton setTitle: @"ST" forState: UIControlStateHighlighted];
			break;
		default:
			break;
	}
}

- (void)playButtonPressed:(id)sender
{
	switch (mode) {
		case kInnovAudioPlayerNoAudio:
            break;
		case kInnovAudioPlayerPlaying:
            [ARISMoviePlayer.moviePlayer stop];
            mode = kInnovAudioPlayerAudio;
            [self updateButtonsForCurrentMode];
            break;
			
		case kInnovAudioPlayerAudio:
            [ARISMoviePlayer.moviePlayer play];
			mode = kInnovAudioPlayerPlaying;
			[self updateButtonsForCurrentMode];
            break;
		default:
			break;
	}
}

#pragma mark MPMoviePlayerController notifications

- (void)MPMoviePlayerPlaybackDidFinishNotification:(NSNotification *)notif
{
    if (mode == kInnovAudioPlayerPlaying)
    {
        [self playButtonPressed:nil];
    }
}


#pragma mark Table view methods

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if([note.comments count] > DEFAULT_MAX_VISIBLE_COMMENTS && !expanded)
        return DEFAULT_MAX_VISIBLE_COMMENTS + 1;
    else
        return [note.comments count] + 1;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.row == 0)
    {
        CGSize constraint = CGSizeMake(self.view.frame.size.width, CGFLOAT_MAX);
        CGSize size = [note.title sizeWithFont:[UIFont systemFontOfSize:DEFAULT_TEXT_SIZE] constrainedToSize:constraint lineBreakMode:UILineBreakModeWordWrap];
        CGFloat captionTextViewHeight = MIN(size.height, BUTTON_HEIGHT);
        
        return imageView.frame.size.height + BUTTON_HEIGHT + captionTextViewHeight;
    }
    else
        return 44;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UITableViewCell *cell;
    if(indexPath.row == 0)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:NOTE_CELL_ID];
        if(!cell)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NOTE_CELL_ID];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            [cell addSubview:imageView];
            [cell addSubview:usernameLabel];
            [cell addSubview:flagButton];
            [cell addSubview:playButton];
            [cell addSubview:likeButton];
            [cell addSubview:shareButton];
            [cell addSubview:captionTextView];
        }
        
        usernameLabel.text = [AppModel sharedAppModel].userName;
        
        captionTextView.text = [self.note.title substringToIndex: [self.note.title rangeOfString:@"#" options:NSBackwardsSearch].location];
        [captionTextView sizeToFit];
    }
    else
    {
        cell = [tableView dequeueReusableCellWithIdentifier:COMMENT_CELL_ID];
        if(!cell)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:COMMENT_CELL_ID];
        }
        
        if(!expanded && indexPath.row == EXPAND_INDEX && [note.comments count] > DEFAULT_MAX_VISIBLE_COMMENTS)
        {
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            cell.textLabel.text          = @".   .   .";
        }
        else
        {
#warning check whether first index is newest or oldest
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textLabel.textAlignment = NSTextAlignmentLeft;
            if(expanded || indexPath.row < EXPAND_INDEX)
                cell.textLabel.text      = ((Note *)[note.comments objectAtIndex:[note.comments count]-indexPath.row]).title; //[note.comments objectAtIndex:indexPath.row-1];
            else
                cell.textLabel.text      = ((Note *)[note.comments objectAtIndex:(DEFAULT_MAX_VISIBLE_COMMENTS-indexPath.row)]).title;//[note.comments objectAtIndex:[note.comments count]-1-(DEFAULT_MAX_VISIBLE_COMMENTS-indexPath.row)];
        }
    }
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(!expanded && indexPath.row == 3)
    {
        expanded = YES;
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
        [tableView reloadData];
    }
}

#pragma mark Autorotation, Dealloc, and Other Necessary Methods

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(BOOL)shouldAutorotate
{
    return YES;
}

-(NSInteger)supportedInterfaceOrientations
{
    NSInteger mask = 0;
    if ([self shouldAutorotateToInterfaceOrientation: UIInterfaceOrientationLandscapeLeft])
        mask |= UIInterfaceOrientationMaskLandscapeLeft;
    if ([self shouldAutorotateToInterfaceOrientation: UIInterfaceOrientationLandscapeRight])
        mask |= UIInterfaceOrientationMaskLandscapeRight;
    if ([self shouldAutorotateToInterfaceOrientation: UIInterfaceOrientationPortrait])
        mask |= UIInterfaceOrientationMaskPortrait;
    if ([self shouldAutorotateToInterfaceOrientation: UIInterfaceOrientationPortraitUpsideDown])
        mask |= UIInterfaceOrientationMaskPortraitUpsideDown;
    return mask;
}

- (void)dealloc
{
    [[AVAudioSession sharedInstance] setDelegate: nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
