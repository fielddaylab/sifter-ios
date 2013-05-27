//
//  InnovViewController.m
//  ARIS
//
//  Created by Jacob Hanshaw on 3/25/13.
//
//

#import "InnovViewController.h"
#import <QuartzCore/QuartzCore.h>

#import "AppModel.h"
#import "InnovNoteModel.h"
#import "AppServices.h"

#import "Note.h"
#import "Location.h"

#import "InnovPresentNoteDelegate.h"
#import "InnovSettingsView.h"
#import "InnovMapViewController.h"
#import "InnovListViewController.h"
#import "InnovNoteViewController.h"
#import "InnovNoteEditorViewController.h"
#import "InnovSelectedTagsViewController.h"

#define RIGHT_SIDE_MARGIN 20
#define SWITCH_VIEWS_ANIMATION_DURATION 1.25

@interface InnovViewController () <InnovSelectedTagsDelegate, InnovSettingsViewDelegate, InnovPresentNoteDelegate, InnovNoteEditorViewDelegate, InnovMapViewDelegate, InnovListViewDelegate, UISearchBarDelegate> {
    
    __weak IBOutlet UIButton *showTagsButton;
    __weak IBOutlet UIButton *trackingButton;
    
    IBOutlet UIView *contentView;
    
    NSTimer *refreshTimer;
    
    UIButton *switchButton;
    UIBarButtonItem *switchViewsBarButton;
    UISearchBar *searchBar;
    UIBarButtonItem *settingsBarButton;
    
    InnovSettingsView *settingsView;
    InnovMapViewController  *mapVC;
    InnovListViewController *listVC;
    InnovSelectedTagsViewController *selectedTagsVC;
    
    InnovNoteModel *noteModel;
    
    Note *noteToAdd;
    NSString *currentSearchTerm;
    ContentSelector currentSearchAlgorithm;
}

@end

@implementation InnovViewController

@synthesize noteToAdd;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        noteModel = [[InnovNoteModel alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
#warning unimplemented: change game and finalize settings
    
    Game *game = [[Game alloc] init];
    game.gameId                   = 3411;
    game.hasBeenPlayed            = YES;
    game.isLocational             = YES;
    game.showPlayerLocation       = YES;
    game.allowNoteComments        = YES;
    game.allowNoteLikes           = YES;
    game.inventoryModel.weightCap = 0;
    game.rating                   = 5;
    game.pcMediaId                = 0;
    game.numPlayers               = 10;
    game.playerCount              = 5;
    game.gdescription             = @"Fun";
    game.name                     = @"Note Share";
    game.authors                  = @"Jacob Hanshaw";
    game.mapType                  = @"STREET";
    [game getReadyToPlay];
#warning get rid of this and only use note model
    [AppModel sharedAppModel].currentGame = game;
    [AppModel sharedAppModel].playerId = 7;
    [AppModel sharedAppModel].loggedIn = YES;
#warning Make initially not logged in
    
    [AppModel sharedAppModel].serverURL = [NSURL URLWithString:@"http://dev.arisgames.org/server"];
    
    mapVC = [[InnovMapViewController alloc] init];
    mapVC.delegate = self;
    [self addChildViewController:mapVC];
    CGRect mapVCFrame = contentView.frame;
    mapVCFrame.origin.x = 0;
    mapVCFrame.origin.y = 0;
    mapVC.view.frame = mapVCFrame;
    [contentView addSubview:mapVC.view];
    [mapVC didMoveToParentViewController:self];
    
    listVC = [[InnovListViewController alloc] init];
    listVC.delegate = self;
    
    switchButton = [UIButton buttonWithType:UIButtonTypeCustom];
    switchButton.frame = CGRectMake(0, 0, 30, 30);
    [switchButton addTarget:self action:@selector(switchViews) forControlEvents:UIControlEventTouchUpInside];
    [switchButton setBackgroundImage: [UIImage imageNamed:@"noteicon.png"] forState:UIControlStateNormal];
    [switchButton setBackgroundImage: [UIImage imageNamed:@"noteicon.png"] forState:UIControlStateHighlighted];
    switchViewsBarButton = [[UIBarButtonItem alloc] initWithCustomView:switchButton];
    self.navigationItem.leftBarButtonItem = switchViewsBarButton;
    
    searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(-5.0, 0.0, self.navigationController.navigationBar.frame.size.width, self.navigationController.navigationBar.frame.size.height)];
    searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    searchBar.barStyle = UIBarStyleBlack;
    UIView *searchBarView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.navigationController.navigationBar.frame.size.width-10, self.navigationController.navigationBar.frame.size.height)];
    searchBarView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    searchBar.delegate = self;
    [searchBarView addSubview:searchBar];
    self.navigationItem.titleView = searchBarView;
    
    settingsBarButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"14-gear.png"] style:UIBarButtonItemStylePlain target:self action:@selector(settingsPressed)];
    self.navigationItem.rightBarButtonItem = settingsBarButton;
    
    settingsView = [[InnovSettingsView alloc] init];
    settingsView.layer.anchorPoint = CGPointMake(1, 0);
    CGRect settingsLocation = settingsView.frame;
    settingsLocation.origin.x = self.view.frame.size.width  - settingsView.frame.size.width;
    settingsLocation.origin.y = 0;
    settingsView.frame = settingsLocation;
    
    settingsView.hidden = YES;
    
    selectedTagsVC = [[InnovSelectedTagsViewController alloc] init];
    selectedTagsVC.delegate = self;
    CGRect selectedTagsFrame = selectedTagsVC.view.frame;
    selectedTagsFrame.origin.x = -self.view.frame.size.width/2;
    selectedTagsFrame.origin.y = self.view.frame.size.height/2+12;
    selectedTagsVC.view.frame = selectedTagsFrame;
    
    showTagsButton.layer.cornerRadius = 4.0f;
    
	trackingButton.backgroundColor = [UIColor lightGrayColor];
    trackingButton.layer.cornerRadius = 4.0f;
    trackingButton.hidden = NO;
    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    
    [self refresh];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //Fixes missing status bar when cancelling picture pick from library
    if([UIApplication sharedApplication].statusBarHidden)
    {
        [self.navigationController setNavigationBarHidden:YES animated:NO];
        [[UIApplication sharedApplication] setStatusBarHidden:NO];
        [self.navigationController setNavigationBarHidden:NO animated:NO];
    }
    
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

	[self refresh];
	
	if (refreshTimer && [refreshTimer isValid]) [refreshTimer invalidate];
	refreshTimer = [NSTimer scheduledTimerWithTimeInterval:20 target:self selector:@selector(refresh) userInfo:nil repeats:YES];
    
    if(noteToAdd != nil)
        [self animateInNote:noteToAdd];
}

#pragma mark Display New Note

- (void) prepareToDisplayNote: (Note *) note
{
    noteToAdd = note;
}

- (void) animateInNote: (Note *) note {
#warning unimplemented
    //Switch to mapview or animate in both
    //Animate in note
    noteToAdd = nil;
}

#pragma mark Refresh

- (void) refresh
{
    [self fetchMoreNotes];
    [[AppServices sharedAppServices] fetchGameNoteTagsAsynchronously: YES];
    
    [mapVC updatePlayerLocation];
}

#pragma mark Selected Content Delegate Methods

- (void) updateContentSelector:(ContentSelector)selector
{
    [noteModel clearData];
    currentSearchAlgorithm = selector;
    [self fetchMoreNotes];
}

- (void) fetchMoreNotes
{
#warning Player Note List needs to be decided
    //  [[AppServices sharedAppServices] fetchPlayerNoteListAsynchronously:YES];
#warning implement proper searchers
#warning fetch more notes each time
    switch (currentSearchAlgorithm)
    {
        case kTop:
        case kPopular:
        case kRecent:
        default:
            [[AppServices sharedAppServices] fetchGameNoteListAsynchronously:YES];
            break;
    }
}

- (void) addTag: (Tag *) tag
{
    [noteModel addTag:tag];
}

- (void) removeTag: (Tag *) tag
{
    [noteModel removeTag:tag];
}

#pragma mark Search Bar Delegate Methods

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
#warning should be case sensitive?
    [noteModel removeSearchTerm:currentSearchTerm];
    currentSearchTerm = searchText;
    [noteModel addSearchTerm:currentSearchTerm];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)aSearchBar
{
    [aSearchBar resignFirstResponder];
}

#pragma mark Buttons Pressed

- (void)settingsPressed
{
    if(![self.view.subviews containsObject:settingsView])
    {
        [self.view addSubview:settingsView];
        [settingsView show];
    }
    else
    {
        [settingsView hide];
    }
}

- (IBAction)showTagsPressed:(id)sender
{
    if(![self.view.subviews containsObject:selectedTagsVC.view])
    {
        [self addChildViewController:selectedTagsVC];
        [self.view addSubview:selectedTagsVC.view];
        [selectedTagsVC didMoveToParentViewController:self];
        [selectedTagsVC show];
    }
    else
    {
        [selectedTagsVC hide];
    }
}

- (IBAction)cameraPressed:(id)sender {
    
    InnovNoteEditorViewController *editorVC = [[InnovNoteEditorViewController alloc] init];
    editorVC.delegate = self;
    
    [self.navigationController pushViewController:editorVC animated:NO];
}

- (IBAction)trackingButtonPressed:(id)sender
{
	[(ARISAppDelegate *)[[UIApplication sharedApplication] delegate] playAudioAlert:@"ticktick" shouldVibrate:NO];
	
	trackingButton.backgroundColor = [UIColor blueColor];
    
    [mapVC toggleTracking];
    
    NSLog(@"Count of player notes: %d Count of game notes: %d", [[AppModel sharedAppModel].playerNoteList count], [[AppModel sharedAppModel].gameNoteList count]);
}

- (void) stoppedTracking
{
    trackingButton.backgroundColor = [UIColor lightGrayColor];
}

#pragma mark Settings Delegate Methods

- (void) showProfile
{
#warning unimplemented
}

- (void) link
{
#warning unimplemented
}

- (void) showAbout
{
#warning unimplemented
}

#pragma mark Present Note Delegate Method

- (void) presentNote:(Note *) note
{
    InnovNoteViewController *noteVC = [[InnovNoteViewController alloc] init];
    noteVC.note = note;
    noteVC.delegate = self;
    [self.navigationController pushViewController:noteVC animated:YES];
}

#pragma mark TouchesBegan Method

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    
    [searchBar resignFirstResponder];
    [settingsView hide];
    [selectedTagsVC hide];
}

#pragma mark Switch Views

- (void)switchViews {
    
    UIViewController *coming = nil;
    UIViewController *going = nil;
    NSString *newButtonTitle;
    NSString *newButtonImageName;
    UIViewAnimationTransition transition;
    
    CGRect contentFrame = contentView.frame;
    contentFrame.origin.x = 0;
    contentFrame.origin.y = 0;
    coming.view.frame = contentFrame;
    
    if (![contentView.subviews containsObject:mapVC.view])
    {
        coming = mapVC;
        going = listVC;
        transition = UIViewAnimationTransitionFlipFromLeft;
        newButtonTitle = @"List";
        newButtonImageName = @"noteicon.png";
    }
    else
    {
        coming = listVC;
        going = mapVC;
        transition = UIViewAnimationTransitionFlipFromRight;
        newButtonTitle = @"Map";
        newButtonImageName = @"103-map.png";
    }
    
    [UIView beginAnimations:@"View Flip" context:nil];
    [UIView setAnimationDuration:SWITCH_VIEWS_ANIMATION_DURATION];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationTransition: transition forView:contentView cache:YES];
    
    [going willMoveToParentViewController:nil];
    [going.view removeFromSuperview];
    [going removeFromParentViewController];
    
    [self addChildViewController:coming];
    coming.view.frame = contentFrame; //setNeedsDisplay?
    [contentView addSubview:coming.view];
    [coming didMoveToParentViewController:self];
    
    [UIView commitAnimations];
    
    [UIView beginAnimations:@"Button Flip" context:nil];
    [UIView setAnimationDuration:SWITCH_VIEWS_ANIMATION_DURATION];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationTransition: transition forView:switchViewsBarButton.customView cache:YES];
    [((UIButton *)switchViewsBarButton.customView) setBackgroundImage: [UIImage imageNamed:newButtonImageName] forState:UIControlStateNormal];
    [((UIButton *)switchViewsBarButton.customView) setBackgroundImage: [UIImage imageNamed:newButtonImageName] forState:UIControlStateHighlighted];
    [UIView commitAnimations];
}

#pragma mark Autorotation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
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

#pragma mark Free Memory

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidUnload {
    contentView = nil;
    showTagsButton = nil;
    trackingButton = nil;
    switchViewsBarButton = nil;
    settingsView = nil;
    [super viewDidUnload];
}

@end