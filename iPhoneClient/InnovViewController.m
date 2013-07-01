
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
#import "AppServices.h"
#import "ARISAppDelegate.h"
#import "Note.h"
#import "InnovNoteModel.h"
#import "InnovPresentNoteDelegate.h"

#import "InnovSettingsView.h"
#import "LoginViewController.h"
#import "InnovMapViewController.h"
#import "InnovListViewController.h"
#import "InnovSelectedTagsViewController.h"
#import "InnovNoteViewController.h"
#import "InnovNoteEditorViewController.h"

#define SWITCH_VIEWS_ANIMATION_DURATION 0.50

@interface InnovViewController () <InnovMapViewDelegate, InnovLogInDelegate, InnovSettingsViewDelegate, InnovPresentNoteDelegate, InnovNoteViewDelegate, InnovNoteEditorViewDelegate, UISearchBarDelegate> {
    
    __weak IBOutlet UIButton *showTagsButton;
    __weak IBOutlet UIButton *trackingButton;
    
    __weak IBOutlet UIView *contentView;
    
    NSTimer *refreshTimer;
    
    UIButton *switchButton;
    UIBarButtonItem *switchViewsBarButton;
    UISearchBar *searchBar;
    UIBarButtonItem *settingsBarButton;
    
    InnovMapViewController  *mapVC;
    InnovListViewController *listVC;
    InnovSettingsView *settingsView;
    InnovSelectedTagsViewController *selectedTagsVC;
    
    Note *noteToAdd;
    NSString *currentSearchTerm;
    ContentSelector currentSearchAlgorithm;
}

@end

@implementation InnovViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkForLogInFail) name:@"NewLoginResponseReady" object:nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    CGRect frame = [UIScreen mainScreen].applicationFrame;
    frame.size.height -= self.navigationController.navigationBar.frame.size.height;
    self.view.frame = frame;
    
    mapVC = [[InnovMapViewController alloc] init];
    mapVC.delegate = self;
    [self addChildViewController:mapVC];
    CGRect contentVCFrame = contentView.frame;
    contentVCFrame.origin.x = 0;
    contentVCFrame.origin.y = 0;
    mapVC.view.frame = contentVCFrame;
    [contentView addSubview:mapVC.view];
    [mapVC didMoveToParentViewController:self];
    
    listVC = [[InnovListViewController alloc] init];
    listVC.delegate = self;
    [self addChildViewController:listVC];
    listVC.view.frame = contentVCFrame;
#warning Possibly add  [self addChildViewController:listVC];
    
    switchButton = [UIButton buttonWithType:UIButtonTypeCustom];
    switchButton.frame = CGRectMake(0, 0, 30, 30);
    [switchButton addTarget:self action:@selector(switchViews) forControlEvents:UIControlEventTouchUpInside];
    [switchButton setBackgroundImage: [UIImage imageNamed:@"listModeIcon.png"] forState:UIControlStateNormal];
    [switchButton setBackgroundImage: [UIImage imageNamed:@"listModeIcon.png"] forState:UIControlStateHighlighted];
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
    
    settingsBarButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"settingsIcon.png"] style:UIBarButtonItemStylePlain target:self action:@selector(settingsPressed)];
    self.navigationItem.rightBarButtonItem = settingsBarButton;
    
    settingsView = [[InnovSettingsView alloc] init];
    settingsView.delegate = self;
    settingsView.layer.anchorPoint = CGPointMake(1, 0);
    CGRect settingsLocation = settingsView.frame;
    settingsLocation.origin.x = self.view.frame.size.width  - settingsView.frame.size.width;
    settingsLocation.origin.y = 0;
    settingsView.frame = settingsLocation;
    settingsView.hidden = YES;
    
    selectedTagsVC = [[InnovSelectedTagsViewController alloc] init];
    selectedTagsVC.view.layer.anchorPoint = CGPointMake(0, 1);
    CGRect selectedTagsFrame = selectedTagsVC.view.frame;
    selectedTagsFrame.origin.x = 0;
    selectedTagsFrame.origin.y = (contentView.frame.origin.y + contentView.frame.size.height) - selectedTagsVC.view.frame.size.height;
    selectedTagsVC.view.frame = selectedTagsFrame;
    
    showTagsButton.layer.cornerRadius = 4.0f;
    
	trackingButton.selected = YES;
    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    
    [[InnovNoteModel sharedNoteModel] fetchMoreNotes];
    [[AppServices sharedAppServices] fetchGameNoteTagsAsynchronously:YES];
    
    [mapVC updatePlayerLocation];
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
    
    if(noteToAdd != nil)
        [self animateInNote:noteToAdd];
}

#pragma mark Display New Note

- (void) prepareToDisplayNote: (Note *) note
{
    noteToAdd = note;
    #warning could be different
    [[InnovNoteModel sharedNoteModel] removeSearchTerm:currentSearchTerm];
    currentSearchTerm = @"";
    [[InnovNoteModel sharedNoteModel] setSelectedContent:kMine];
}

- (void) animateInNote: (Note *) note
{
    if ([contentView.subviews containsObject:mapVC.view])
        [mapVC showNotePopUpForNote:note];
    else
        [listVC animateInNote:note];
    noteToAdd = nil;
}

#pragma mark Search Bar Delegate Methods

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [[InnovNoteModel sharedNoteModel] removeSearchTerm:currentSearchTerm];
    currentSearchTerm = searchText.lowercaseString;
    [[InnovNoteModel sharedNoteModel] addSearchTerm:currentSearchTerm];
}

//Enables search bar when search field is empty
- (void)searchBarTextDidBeginEditing:(UISearchBar *)aSearchBar
{
    UITextField *searchField = nil;
    for (UIView *subview in aSearchBar.subviews) {
        if ([subview isKindOfClass:[UITextField class]]) {
            searchField = (UITextField *)subview;
            break;
        }
    }
    
    if (searchField)
        searchField.enablesReturnKeyAutomatically = NO;
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
        [settingsView hide];
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
        [selectedTagsVC hide];
}

- (IBAction)cameraPressed:(id)sender
{
    if([AppModel sharedAppModel].playerId == 0)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Must Be Logged In" message:@"You must be logged in to create a note." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Log In", nil];
        [alert show];
    }
    else
    {
        InnovNoteEditorViewController *editorVC = [[InnovNoteEditorViewController alloc] init];
        editorVC.delegate = self;
        [self.navigationController pushViewController:editorVC animated:NO];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex) [self presentLogIn];
}

- (IBAction)trackingButtonPressed:(id)sender
{
	[(ARISAppDelegate *)[[UIApplication sharedApplication] delegate] playAudioAlert:@"ticktick" shouldVibrate:NO];
    [mapVC toggleTracking];
}

- (void) stoppedTracking
{
    trackingButton.selected = NO;
}

#pragma mark Settings Delegate Methods

- (void) showAbout
{
#warning unimplemented
}

- (void) presentLogIn
{
    LoginViewController *logInVC = [[LoginViewController alloc] init];
    logInVC.delegate = self;
    [self.navigationController pushViewController:logInVC animated:YES];
}

#pragma mark Login and Game Selection
- (void)createUserAndLoginWithGroup:(NSString *)groupName andGameId:(int)gameId inMuseumMode:(BOOL)museumMode
{
	[AppModel sharedAppModel].museumMode = museumMode;
    
	[[AppServices sharedAppServices] createUserAndLoginWithGroup:[NSString stringWithFormat:@"%d-%@", gameId, groupName]];
    
    if(gameId != 0)
    {
        [AppModel sharedAppModel].skipGameDetails = YES;
        [[AppServices sharedAppServices] fetchOneGameGameList:gameId];
    }
}

- (void)attemptLoginWithUserName:(NSString *)userName andPassword:(NSString *)password andGameId:(int)gameId inMuseumMode:(BOOL)museumMode
{
	[AppModel sharedAppModel].userName = userName;
	[AppModel sharedAppModel].password = password;
	[AppModel sharedAppModel].museumMode = museumMode;
    
	[[AppServices sharedAppServices] login];
    
    if(gameId != 0)
    {
        [AppModel sharedAppModel].skipGameDetails = YES;
        [[AppServices sharedAppServices] fetchOneGameGameList:gameId];
    }
}

- (void)checkForLogInFail
{
    if([AppModel sharedAppModel].playerId == 0)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Log In Failed" message:@"The attempt to log in failed. Please confirm your log in information and try again or create an account if you do not have one." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles: nil];
        [alert show];
    }
}

#pragma mark Present Note Delegate Method

- (void) presentNote:(Note *) note
{
    [searchBar resignFirstResponder];
    
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
    NSString *newButtonImageName;
    UIViewAnimationTransition transition;
    
    if (![contentView.subviews containsObject:mapVC.view])
    {
        coming = mapVC;
        going = listVC;
        transition = UIViewAnimationTransitionFlipFromLeft;
        newButtonImageName = @"listModeIcon.png";
    }
    else
    {
        coming = listVC;
        going = mapVC;
        transition = UIViewAnimationTransitionFlipFromRight;
        newButtonImageName = @"mapModeIcon.png";
    }
    
    [UIView beginAnimations:@"View Flip" context:nil];
    [UIView setAnimationDuration:SWITCH_VIEWS_ANIMATION_DURATION];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationTransition: transition forView:contentView cache:YES];
    
    [going willMoveToParentViewController:nil];
    [going.view removeFromSuperview];
    [going removeFromParentViewController];
    
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

#pragma mark Free Memory

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidUnload
{
    contentView = nil;
    showTagsButton = nil;
    trackingButton = nil;
    switchViewsBarButton = nil;
    settingsView = nil;
    [super viewDidUnload];
}

@end