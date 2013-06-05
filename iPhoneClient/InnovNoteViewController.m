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
#import "AsyncMediaImageView.h"
#import "InnovNoteEditorViewController.h"
#import "ARISMoviePlayerViewController.h"
#import "NoteCommentViewController.h"

#define ANIMATION_TIME      0.5

#define IMAGE_X_MARGIN      0
#define IMAGE_Y_MARGIN      0

#define BUTTON_WIDTH        36
#define BUTTON_HEIGHT       36

#define COMMENT_BAR_HEIGHT          40
#define COMMENT_BAR_CONTENT_HEIGHT  30
#define COMMENT_BAR_X_MARGIN        10
#define COMMENT_BAR_Y_MARGIN        6
#define COMMENT_BAR_BUTTON_WIDTH    58

#define DEFAULT_TEXT        @"Add a comment..."
#define DEFAULT_TEXT_SIZE   14

#define EXPAND_INDEX                 3
#define DEFAULT_MAX_VISIBLE_COMMENTS 5

static NSString * const NOTE_CELL_ID    = @"NoteCell";
static NSString * const COMMENT_CELL_ID = @"CommentCell";

@interface InnovNoteViewController ()<UITextViewDelegate, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate, AsyncMediaImageViewDelegate, InnovNoteEditorViewDelegate>
{
    __weak IBOutlet UITableView *noteTableView;
    UIToolbar   *addCommentBar;
    UITextField *addCommentTextField;
    UIButton    *addCommentButton;
    
    AsyncMediaImageView *imageView;
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
    
    addCommentBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0f,
                                                                self.view.bounds.size.height - COMMENT_BAR_HEIGHT,
                                                                self.view.bounds.size.width,
                                                                COMMENT_BAR_HEIGHT)];
    addCommentBar.barStyle = UIBarStyleBlackOpaque;
    addCommentBar.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:addCommentBar];
    
    addCommentTextField =    [[UITextField alloc] initWithFrame:CGRectMake(COMMENT_BAR_X_MARGIN,
                                                                           COMMENT_BAR_Y_MARGIN,
                                                                           addCommentBar.bounds.size.width - (2 * COMMENT_BAR_X_MARGIN)  - (COMMENT_BAR_BUTTON_WIDTH + COMMENT_BAR_X_MARGIN),
                                                                           COMMENT_BAR_CONTENT_HEIGHT)];
    addCommentTextField.delegate            = self;
    addCommentTextField.returnKeyType       = UIReturnKeySend;
    addCommentTextField.borderStyle         = UITextBorderStyleRoundedRect;
    addCommentTextField.clearButtonMode     = UITextFieldViewModeWhileEditing;
    addCommentTextField.autoresizingMask    = UIViewAutoresizingFlexibleWidth;
    [addCommentBar addSubview:addCommentTextField];
    
    addCommentButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    addCommentButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    addCommentButton.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:12];
    [addCommentButton addTarget:self action:@selector(addCommentButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [addCommentButton setTitle:@"Comment" forState:UIControlStateNormal];
    [addCommentButton setTitle:@"Comment" forState:UIControlStateHighlighted];
    addCommentButton.frame = CGRectMake(addCommentBar.bounds.size.width - (COMMENT_BAR_BUTTON_WIDTH + COMMENT_BAR_X_MARGIN),
                                  COMMENT_BAR_Y_MARGIN,
                                  COMMENT_BAR_BUTTON_WIDTH,
                                  COMMENT_BAR_CONTENT_HEIGHT);
    [addCommentBar addSubview:addCommentButton];
    
    self.view.keyboardTriggerOffset = addCommentBar.bounds.size.height;
    
    [self.view addKeyboardPanningWithActionHandler:^(CGRect keyboardFrameInView) {
        /*
         Try not to call "self" inside this block (retain cycle).
         But if you do, make sure to remove DAKeyboardControl
         when you are done with the view controller by calling:
         [self.view removeKeyboardControl];
         */
        
        CGRect addCommentBarFrame = addCommentBar.frame;
        addCommentBarFrame.origin.y = keyboardFrameInView.origin.y - addCommentBarFrame.size.height;
        addCommentBar.frame = addCommentBarFrame;
        
        CGRect tableViewFrame = noteTableView.frame;
        tableViewFrame.size.height = addCommentBarFrame.origin.y;
        noteTableView.frame = tableViewFrame;

        [noteTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:([noteTableView numberOfRowsInSection:0] - 1) inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }];
    
    imageView = [[AsyncMediaImageView alloc] init];
    imageView.frame = CGRectMake(IMAGE_X_MARGIN, IMAGE_Y_MARGIN, self.view.frame.size.width - 2 * IMAGE_X_MARGIN, self.view.frame.size.width - 2 * IMAGE_X_MARGIN);
    imageView.delegate = self;
    
    usernameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, IMAGE_Y_MARGIN + imageView.frame.size.height, self.view.frame.size.width-4*BUTTON_WIDTH, BUTTON_HEIGHT)];
    usernameLabel.backgroundColor = [UIColor blackColor];
    usernameLabel.textColor       = [UIColor whiteColor];
    
    playButton  = [[UIButton alloc] initWithFrame:CGRectMake(usernameLabel.frame.size.width,            IMAGE_Y_MARGIN + imageView.frame.size.height, BUTTON_WIDTH, BUTTON_HEIGHT)];
    playButton.backgroundColor = [UIColor blackColor];
    [playButton setTitle:@"PL" forState:UIControlStateNormal];
    [playButton setTitle:@"PL" forState:UIControlStateHighlighted];
	[playButton addTarget:self action:@selector(playButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    flagButton  = [[UIButton alloc] initWithFrame:CGRectMake(playButton.frame.origin.x  + BUTTON_WIDTH, IMAGE_Y_MARGIN + imageView.frame.size.height, BUTTON_WIDTH, BUTTON_HEIGHT)];
    flagButton.backgroundColor = [UIColor blackColor];
    //   [flagButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    //   [flagButton setTitleColor:[UIColor blackColor] forState:UIControlStateHighlighted];
    [flagButton setTitle:@"F" forState:UIControlStateNormal];
    [flagButton setTitle:@"F" forState:UIControlStateHighlighted];
	[flagButton addTarget:self action:@selector(flagButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    likeButton  = [[UIButton alloc] initWithFrame:CGRectMake(flagButton.frame.origin.x  + BUTTON_WIDTH, IMAGE_Y_MARGIN + imageView.frame.size.height, BUTTON_WIDTH, BUTTON_HEIGHT)];
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
    captionTextView.font = [UIFont fontWithName:@"Helvetica" size:DEFAULT_TEXT_SIZE];
}

- (void)viewDidUnload {
    imageView = nil;
    captionTextView = nil;
    playButton = nil;
    noteTableView = nil;
    addCommentBar = nil;
    addCommentTextField = nil;
    addCommentButton = nil;
    
    [self.view removeKeyboardControl];
    
    [super viewDidUnload];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear: animated];
    
    captionTextView.text = [self.note.title substringToIndex: [self.note.title rangeOfString:@"#" options:NSBackwardsSearch].location];
    
    addCommentTextField.text = DEFAULT_TEXT;
    addCommentTextField.textColor = [UIColor lightGrayColor];
    
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

#pragma mark UITextField methods

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self addCommentButtonPressed:nil];
    return YES;
}

- (void) textFieldDidBeginEditing:(UITextField *)textField
{
    textField.textColor = [UIColor blackColor];
    if([textField.text isEqualToString:DEFAULT_TEXT]) textField.text = @"";
}

#pragma mark Button methods

- (void)editButtonTouchAction: (id) sender
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

- (void) addCommentButtonPressed:(id)sender {
    [addCommentTextField resignFirstResponder];
    
    if([addCommentTextField.text length] > 0 && ![addCommentTextField.text isEqualToString:DEFAULT_TEXT])
    {
        Note *commentNote = [[Note alloc] init];
        commentNote.noteId = [[AppServices sharedAppServices]addCommentToNoteWithId:self.note.noteId andTitle:@""];
        
        commentNote.title = addCommentTextField.text;
        commentNote.parentNoteId = self.note.noteId;
        commentNote.creatorId = [AppModel sharedAppModel].playerId;
        commentNote.username = [AppModel sharedAppModel].userName;
#warning probably unnecessary to do this second call
        [[AppServices sharedAppServices]updateCommentWithId:commentNote.noteId andTitle:commentNote.title andRefresh:YES];
        
        [self.note.comments insertObject:commentNote atIndex:0];
        [[AppModel sharedAppModel].gameNoteList   setObject:self.note forKey:[NSNumber numberWithInt:self.note.noteId]];
        
        addCommentTextField.text = @"";
    }
    
    [noteTableView reloadData];
    [noteTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:([noteTableView numberOfRowsInSection:0] - 1) inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
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
    
    playButton.userInteractionEnabled = YES;
    
#warning use new titles
    
    switch (mode) {
		case kInnovAudioPlayerNoAudio:
             playButton.userInteractionEnabled = NO;
             [playButton setTitle: @"" forState: UIControlStateNormal];
			[playButton setTitle: @"" forState: UIControlStateHighlighted];
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
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        
        if(!expanded && indexPath.row == EXPAND_INDEX && [note.comments count] > DEFAULT_MAX_VISIBLE_COMMENTS)
        {
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            cell.textLabel.text          = @".   .   .";
        }
        else
        {
            cell.textLabel.textAlignment = NSTextAlignmentLeft;
            if(expanded || indexPath.row < EXPAND_INDEX || [note.comments count] <= DEFAULT_MAX_VISIBLE_COMMENTS)
                cell.textLabel.text      = ((Note *)[note.comments objectAtIndex:[note.comments count]-indexPath.row]).title;
            else
                cell.textLabel.text      = ((Note *)[note.comments objectAtIndex:(DEFAULT_MAX_VISIBLE_COMMENTS-indexPath.row)]).title;
        }
    }
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [addCommentTextField resignFirstResponder];
    
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
