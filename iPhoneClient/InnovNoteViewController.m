//
//  InnovNoteViewController.m
//  YOI
//
//  Created by Jacob James Hanshaw on 5/8/13.
//
//

#import "InnovNoteViewController.h"
#import "AppModel.h"
#import "AppServices.h"
#import "Tag.h"
#import "Logger.h"

#define ANIMATION_TIME     0.6

@interface InnovNoteViewController ()

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
    
    imageView.delegate = self;
    
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
    
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear: animated];
    
    captionTextView.text = self.note.title;
    
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

- (IBAction)editButtonTouchAction: (id) sender
{
    InnovNoteEditorViewController *editVC = [[InnovNoteEditorViewController alloc] init];
    editVC.note = self.note;
    editVC.delegate = self;
    [self.navigationController pushViewController:editVC animated:YES];
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

- (IBAction)expandButtonPressed:(id)sender
{
    [self toggleImageFullScreen];
}

- (IBAction)flagButtonPressed:(id)sender
{
    #warning unimplemented
}

- (IBAction)commentButtonPressed:(id)sender
{
    #warning unimplemented
}

- (IBAction)likeButtonPressed:(id)sender
{
#warning unimplemented
}

#pragma mark Note Contents

- (void)refreshViewFromModel
{
    note = [[[AppModel sharedAppModel] playerNoteList] objectForKey:[NSNumber numberWithInt:note.noteId]];
    [self addCDUploadsToNote];
    
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
    NSLog(@"InnovNoteEditorVC: Added %d upload content(s) to note",[uploadContentsForNote count]);
}

#pragma mark Audio Methods

- (void)updateButtonsForCurrentMode{
    
    playButton.hidden = NO;
    
    switch (mode) {
		case kInnovAudioPlayerNoAudio:
			playButton.hidden = YES;
			break;
		case kInnovAudioPlayerAudio:
			[playButton setTitle: NSLocalizedString(@"PlayKey", @"") forState: UIControlStateNormal];
			[playButton setTitle: NSLocalizedString(@"PlayKey", @"") forState: UIControlStateHighlighted];
			break;
		case kInnovAudioPlayerPlaying:
			[playButton setTitle: NSLocalizedString(@"StopKey", @"") forState: UIControlStateNormal];
			[playButton setTitle: NSLocalizedString(@"StopKey", @"") forState: UIControlStateHighlighted];
			break;
		default:
			break;
	}
}

- (IBAction)playButtonPressed:(id)sender
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
    if (mode == kInnovAudioRecorderPlaying)
    {
        [self playButtonPressed:nil];
    }
}

/*
#pragma mark Table view methods

-(void)refreshComments
{
    [tagList removeAllObjects];
    for(int i = 0; i < [[AppModel sharedAppModel].gameTagList count];i++){
        [tagList addObject:[[AppModel sharedAppModel].gameTagList objectAtIndex:i]];
        
        if([((Tag *)[tagList objectAtIndex:i]).tagName isEqualToString:newTagName])
            [tagTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]].accessoryType = UITableViewCellAccessoryCheckmark;
    }
    [tagTableView reloadData];
}
*/
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 0;
    /*
    switch (section) {
        case 0:
            if(tagList.count > 0)
                return [tagList count];
            else
                return 1;
            break;
        default:
            break;
    }
    return 1;
     */
}
/*
-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    switch (section) {
        case 0:
            return @"Categories";
            break;
        default:
            break;
    }
    return @"ERROR";
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *tempCell = (TagCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (![tempCell respondsToSelector:@selector(nameLabel)]) tempCell = nil;
    TagCell *cell = (TagCell *)tempCell;
    
    
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
    
    return cell;
}

-(NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //Not considered selected when auto set to first row, so clear first row
    [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]].accessoryType = UITableViewCellAccessoryNone;
    
    NSIndexPath *oldIndex = [tableView indexPathForSelectedRow];
    [tableView cellForRowAtIndexPath:oldIndex].accessoryType = UITableViewCellAccessoryNone;
    return indexPath;
    
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    TagCell *cell = (TagCell *)[tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    
    newTagName = cell.nameLabel.text;
    [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    
    self.title = newTagName;
}

*/

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

- (void)viewDidUnload {
    imageView = nil;
    captionTextView = nil;
    playButton = nil;
    commentTableView = nil;
    [super viewDidUnload];
}

@end
