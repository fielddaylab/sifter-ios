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

#import "Note.h"
#import "Location.h"

#import "InnovPresentNoteProtocol.h"
#import "InnovSettingsView.h"
#import "InnovMapViewController.h"
#import "TMQuiltView.h"
#import "TMPhotoQuiltViewCell.h"
#import "InnovNoteViewController.h"
#import "InnovNoteEditorViewController.h"
#import "InnovSelectedTagsViewController.h"

#define RIGHT_SIDE_MARGIN 20
#define SWITCH_VIEWS_ANIMATION_DURATION 1.25

@interface InnovViewController () <TMQuiltViewDataSource, TMQuiltViewDelegate, InnovSelectedTagsDelegate, InnovSettingsViewDelegate, InnovPresentNoteProtocol>

@end

@implementation InnovViewController

@synthesize lastLocation, noteToAdd;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
        locationsToAdd     = [[NSMutableArray alloc] initWithCapacity:10];
        locationsToRemove  = [[NSMutableArray alloc] initWithCapacity:10];
        
        availableTags      = [[NSMutableArray alloc] initWithCapacity:10];
        tagNotesDictionary = [[NSMutableDictionary alloc] init];
        
        images             = [[NSMutableArray alloc] initWithCapacity:20];
        text               = [[NSMutableArray alloc] initWithCapacity:20];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerMoved)                name:@"PlayerMoved"                             object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addLocationsToNewQueue:)    name:@"NewlyAvailableLocationsAvailable"        object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addLocationsToRemoveQueue:) name:@"NewlyUnavailableLocationsAvailable"      object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshViewFromModel)       name:@"NewNoteListReady"       object:nil];
        
        //     [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(incrementBadge)             name:@"NewlyChangedLocationsGameNotificationSent"    object:nil];
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
    [AppModel sharedAppModel].currentGame = game;
    [AppModel sharedAppModel].playerId = 7;
    [AppModel sharedAppModel].loggedIn = YES;
#warning Make initially not logged in
    
    [AppModel sharedAppModel].serverURL = [NSURL URLWithString:@"http://dev.arisgames.org/server"];
    
    mapVC = [[InnovMapViewController alloc] init];
    mapVC.delegate = self;
    [self addChildViewController:mapVC];
    mapVC.view.frame = contentView.frame;
    [contentView addSubview:mapVC.view];
    [mapVC didMoveToParentViewController:self];
    
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
    UIView *searchBarView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 310.0, self.navigationController.navigationBar.frame.size.height)];
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
    
#warning is this necessary?
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    
	trackingButton.backgroundColor = [UIColor lightGrayColor];
    trackingButton.layer.cornerRadius = 4.0f;
    trackingButton.hidden = YES;
    
    /* CGRect quiltViewFrame = listContentView.frame;
     quiltViewFrame.origin.x = 0;
     quiltViewFrame.origin.y = 0;
     quiltView = [[TMQuiltView alloc] initWithFrame:quiltViewFrame];
     quiltView.bounces = NO;
     quiltView.delegate = self;
     quiltView.dataSource = self;
     quiltView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
     [listContentView addSubview:quiltView]; */
    
    quiltView = nil;
    
    //[quiltView reloadData];
    
    [self refresh];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //   if     ([[AppModel sharedAppModel].currentGame.mapType isEqualToString:@"SATELLITE"]) mapView.mapType = MKMapTypeSatellite;
    //   else if([[AppModel sharedAppModel].currentGame.mapType isEqualToString:@"HYBRID"])    mapView.mapType = MKMapTypeHybrid;
    //   else                                                                                  mapView.mapType = MKMapTypeStandard;
    
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
	
    [self refreshViewFromModel];
	[self refresh];
	
	if (refreshTimer && [refreshTimer isValid]) [refreshTimer invalidate];
	refreshTimer = [NSTimer scheduledTimerWithTimeInterval:20 target:self selector:@selector(refresh) userInfo:nil repeats:YES];
    
    if(noteToAdd != nil){
        [self animateInNote:noteToAdd];
        noteToAdd = nil;
    }
    
}

- (void) animateInNote: (Note *) note {
#warning unimplemented
    //Switch to mapview or animate in both
    //Animate in note
}

- (void) refresh
{
    [[AppServices sharedAppServices] fetchPlayerLocationList];
    [[AppServices sharedAppServices] fetchPlayerNoteListAsynchronously:YES];
    [[AppServices sharedAppServices] fetchGameNoteListAsynchronously:YES];
    [[AppServices sharedAppServices] fetchGameNoteTagsAsynchronously: YES];
    
    [mapVC updatePlayerLocation];
}

#pragma mark Selected Content Delegate Methods

- (void) didUpdateContentSelector
{
#warning not implemented
}

- (void) addTag: (Tag *) tag
{
    [availableTags addObject:tag];
    
    if(![tagNotesDictionary objectForKey:tag.tagName]) [tagNotesDictionary setObject:[[NSMutableArray alloc] init] forKey:tag.tagName];
    
    for(int i = 0; i < [[tagNotesDictionary objectForKey:tag.tagName] count]; i++)
    {
        Note *note = [[tagNotesDictionary objectForKey:tag.tagName] objectAtIndex:i];
        if(note && note.showOnMap)
        {
            CLLocationCoordinate2D locationLatLong = CLLocationCoordinate2DMake(note.latitude, note.longitude);
            Annotation *annotation = [[Annotation alloc]initWithCoordinate:locationLatLong];
            annotation.location = note.location;
            annotation.title = note.title;
            annotation.kind = NearbyObjectNote;
            annotation.iconMediaId = -tag.tagId;
#warning this needs to be implemented in AnnotationView.m
            
            [mapView addAnnotation:annotation];
        }
    }
    
    //[self refreshImagesAndText];
    //[quiltView reloadData];
}

- (void) removeTag: (Tag *) tag
{
    [availableTags removeObject:tag];
    
    NSObject<MKAnnotation> *tmpMKAnnotation;
    Annotation *tmpAnnotation;
    for (int i = 0; i < [[mapView annotations] count]; i++)
    {
        if((tmpMKAnnotation = [[mapView annotations] objectAtIndex:i]) == mapView.userLocation ||
           !((tmpAnnotation = (Annotation*)tmpMKAnnotation) && [tmpAnnotation respondsToSelector:@selector(title)])) continue;
        
        if(tmpAnnotation.iconMediaId == -tag.tagId)
        {
            [mapView removeAnnotation:tmpAnnotation];
            i--;
        }
    }
    
    //[self refreshImagesAndText];
    //[quiltView reloadData];
}

#pragma mark LocationsModel Update Methods

- (void) addLocationsToNewQueue:(NSNotification *)notification
{
    //Quickly make sure we're not re-adding any info (let the 'newly' added ones take over)
    NSArray *newLocations = (NSArray *)[notification.userInfo objectForKey:@"newlyAvailableLocations"];
    for(int i = 0; i < [newLocations count]; i++)
    {
        for(int j = 0; j < [locationsToAdd count]; j++)
        {
            if([((Location *)[newLocations objectAtIndex:i]) compareTo:((Location *)[locationsToAdd objectAtIndex:j])]
               || ((Location *)[newLocations objectAtIndex:i]).kind != NearbyObjectNote)
                [locationsToAdd removeObjectAtIndex:j];
        }
    }
    [locationsToAdd addObjectsFromArray:newLocations];
    
    [self refreshViewFromModel];
}

- (void) addLocationsToRemoveQueue:(NSNotification *)notification
{
    //Quickly make sure we're not re-adding any info (let the 'newly' added ones take over)
    NSArray *lostLocations = (NSArray *)[notification.userInfo objectForKey:@"newlyUnavailableLocations"];
    for(int i = 0; i < [lostLocations count]; i++)
    {
        for(int j = 0; j < [locationsToRemove count]; j++)
        {
            if([((Location *)[lostLocations objectAtIndex:i]) compareTo: ((Location *)[locationsToRemove objectAtIndex:j])])
                [locationsToRemove removeObjectAtIndex:j];
        }
    }
    [locationsToRemove addObjectsFromArray:lostLocations];
    
    //If told to remove something that is in queue to add, remove takes precedence
    for(int i = 0; i < [locationsToRemove count]; i++)
    {
        for(int j = 0; j < [locationsToAdd count]; j++)
        {
            if([((Location *)[locationsToRemove objectAtIndex:i]) compareTo: ((Location *)[locationsToAdd objectAtIndex:j])])
                [locationsToAdd removeObjectAtIndex:j];
        }
    }
    [self refreshViewFromModel];
}

- (void)refreshViewFromModel
{
    //Remove old locations first
    Location *tmpLocation;
    Note     *note;
    Tag      *noteTag;
    NSObject<MKAnnotation> *tmpMKAnnotation;
    Annotation *tmpAnnotation;
    for (int i = 0; i < [locationsToRemove count]; i++)
    {
        tmpLocation = (Location *)[locationsToRemove objectAtIndex:i];
        
        note           = [[AppModel sharedAppModel] noteForNoteId:tmpLocation.objectId playerListYesGameListNo:NO];
        if(!note) note = [[AppModel sharedAppModel] noteForNoteId:tmpLocation.objectId playerListYesGameListNo:YES];
        
        if(note)
        {
            noteTag = [note.tags objectAtIndex:0];
            
            [[tagNotesDictionary objectForKey:noteTag.tagName] removeObject:note];
            
            for (int j = 0; j < [[mapView annotations] count]; ++j)
            {
                if((tmpMKAnnotation = [[mapView annotations] objectAtIndex:j]) == mapView.userLocation ||
                   !((tmpAnnotation = (Annotation*)tmpMKAnnotation) && [tmpAnnotation respondsToSelector:@selector(title)])) continue;
                
                if([tmpAnnotation.location compareTo: ((Location *)[locationsToRemove objectAtIndex:i])])
                {
                    [mapView removeAnnotation:tmpAnnotation];
                    --j;
                }
            }
            [locationsToRemove removeObject:tmpLocation];
            --i;
        }
        
    }
    
    //Add new locations second
    for (int i = 0; i < [locationsToAdd count]; i++)
    {
        tmpLocation = (Location *)[locationsToAdd objectAtIndex:i];
        
        //Would check if player and if players should be shown, but only adds notes anyway, also removed some items code
        
        note    = [[AppModel sharedAppModel] noteForNoteId:tmpLocation.objectId playerListYesGameListNo:NO];
        if(!note) note = [[AppModel sharedAppModel] noteForNoteId:tmpLocation.objectId playerListYesGameListNo:YES];
        
        if(note)
        {
            note.location  = tmpLocation;
            
            noteTag = [note.tags objectAtIndex:0];
            
            if(![tagNotesDictionary objectForKey:noteTag.tagName]) [tagNotesDictionary setObject:[[NSMutableArray alloc] init] forKey:noteTag.tagName];
            [[tagNotesDictionary objectForKey:noteTag.tagName] addObject:note];
            
            BOOL match = NO;
            for(int j = 0; j < [availableTags count]; ++j)
            {
                if(((Tag *) [availableTags objectAtIndex:j]).tagId == noteTag.tagId) {
                    match = YES;
                    break;
                }
            }
            
            if(match)
            {
                CLLocationCoordinate2D locationLatLong = CLLocationCoordinate2DMake(note.latitude, note.longitude);
                Annotation *annotation = [[Annotation alloc]initWithCoordinate:locationLatLong];
                annotation.location = note.location;
                annotation.title = note.title;
                annotation.kind = NearbyObjectNote;
                annotation.iconMediaId = -noteTag.tagId;
#warning this needs to be implemented in AnnotationView.m
                
                [mapView addAnnotation:annotation];
            }
            
            [locationsToAdd removeObject:tmpLocation];
            --i;
        }
        
    }
    
    [self refreshImagesAndText];
    [quiltView reloadData];
    
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
    lastLocation = [[CLLocation alloc] initWithLatitude:mapView.region.center.latitude longitude:mapView.region.center.longitude];
    
    [self.navigationController pushViewController:editorVC animated:NO];
}

- (IBAction)trackingButtonPressed:(id)sender
{
	[(ARISAppDelegate *)[[UIApplication sharedApplication] delegate] playAudioAlert:@"ticktick" shouldVibrate:NO];
	
	trackingButton.backgroundColor = [UIColor blueColor];
    
    [mapVC toggleTracking];
}

#pragma mark settings delegate methods

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

#pragma mark present note delegate method

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
    [searchBar resignFirstResponder];
    [settingsView hide];
    [selectedTagsVC hide];
}

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
    
    if (![self.view.subviews containsObject:mapVC.view])
    {
        coming = mapVC;
        going = listContentView;
        transition = UIViewAnimationTransitionFlipFromLeft;
        newButtonTitle = @"List";
        newButtonImageName = @"noteicon.png";
    }
    else
    {
        coming = listContentView;
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

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [quiltView reloadData];
}
/*
 #pragma mark - TMQuiltViewDataSource
 
 - (NSInteger)quiltViewNumberOfCells:(TMQuiltView *)quiltView {
 int cellCount = [availableTags count];
 for(int i = 0; i < [availableTags count]; ++i)
 cellCount+= [[tagNotesDictionary objectForKey:((Tag *)[availableTags objectAtIndex:i]).tagName] count];
 
 return cellCount;
 }
 */
#pragma mark - QuiltViewControllerDataSource

- (void) refreshImagesAndText
{
    [images removeAllObjects];
    [text   removeAllObjects];
    for(int i = 0; i < [availableTags count]; ++i)
    {
#warning re-add or do something else to designate tag
        //   [images addObject:[UIImage imageNamed:[NSString stringWithFormat:@"%@_header.png", ((Tag *)[availableTags objectAtIndex:i]).tagName]]];
        //   [text   addObject:@""];
        for(int j = 0; j < [[tagNotesDictionary objectForKey:((Tag *)[availableTags objectAtIndex:i]).tagName] count]; ++j)
        {
            Note * note = [[tagNotesDictionary objectForKey:((Tag *)[availableTags objectAtIndex:i]).tagName] objectAtIndex:j];
            
            NoteContent *noteContent;
            for(int k = 0; k < [note.contents count]; ++k)
            {
                noteContent = [note.contents objectAtIndex:k];
                if([[noteContent getType] isEqualToString:kNoteContentTypePhoto]) break;
            }
            
            NSString *number = [NSString stringWithFormat:@"%d", j];
            
            [images addObject:noteContent];
            if(note.title) [text   addObject:note.title];
            else           [text   addObject: number];
        }
    }
}

- (NSInteger)quiltViewNumberOfCells:(TMQuiltView *)TMQuiltView {
    return 0; //[images count];
}

- (TMQuiltViewCell *)quiltView:(TMQuiltView *)aQuiltView cellAtIndexPath:(NSIndexPath *)indexPath {
    TMPhotoQuiltViewCell *cell = (TMPhotoQuiltViewCell *)[aQuiltView dequeueReusableCellWithReuseIdentifier:@"PhotoCell"];
    if (!cell) {
        cell = [[TMPhotoQuiltViewCell alloc] initWithReuseIdentifier:@"PhotoCell"];
    }
    if([[images objectAtIndex:indexPath.row] isKindOfClass:[UIImage class]]) [cell.photoView setImage:[images objectAtIndex:indexPath.row]];
    else [cell.photoView loadImageFromMedia:[[images objectAtIndex:indexPath.row] getMedia]];
    
    //   if(![[text objectAtIndex:indexPath.row] isEqualToString:@""])
    cell.titleLabel.text = [text objectAtIndex:indexPath.row];
    
    return cell;
}
#pragma mark - TMQuiltViewDelegate

- (NSInteger)quiltViewNumberOfColumns:(TMQuiltView *)quiltView {
    
    
    if ([[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeLeft
        || [[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeRight) {
        return 3;
    } else {
        return 2;
    }
}

- (CGFloat)quiltView:(TMQuiltView *)aQuiltView heightForCellAtIndexPath:(NSIndexPath *)indexPath {
    //   return ((TMPhotoQuiltViewCell *)[self quiltView:quiltView cellAtIndexPath:indexPath]).photoView.frame.size.height / [self quiltViewNumberOfColumns:aQuiltView];
    return 320/[self quiltViewNumberOfColumns:aQuiltView];
}

- (void)quiltView:(TMQuiltView *)quiltView didSelectCellAtIndexPath:(NSIndexPath *)indexPath
{
    int index = indexPath.row;
    for(int i = 0; i < [availableTags count]; ++i)
    {
        if([[tagNotesDictionary objectForKey:((Tag *)[availableTags objectAtIndex:i]).tagName] count] <= index) index -= [[tagNotesDictionary objectForKey:((Tag *)[availableTags objectAtIndex:i]).tagName] count];
        else
        {
            [self presentNote:[[tagNotesDictionary objectForKey:((Tag *)[availableTags objectAtIndex:i]).tagName] objectAtIndex:index]];
            return;
        }
        
    }
}
/*
 #pragma mark TableView Delegate and Datasource Methods
 
 - (NSInteger)numberOfSectionsInTableView:(UITableView *)atableView {
 return [availableTags count];
 }
 
 - (NSInteger)tableView:(UITableView *)atableView numberOfRowsInSection:(NSInteger)section {
 return [[tagNotesDictionary objectForKey:((Tag *)[availableTags objectAtIndex:section]).tagName] count];
 }
 
 // Customize the appearance of table view cells.
 - (UITableViewCell *)tableView:(UITableView *)atableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
 #warning unimplemented
 
 // UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
 // if(cell == nil) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
 
 // cell.textLabel.text = @"ROW";
 
 //InnovTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
 //if(cell == nil) cell = [[InnovTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
 
 UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"InnovTableViewCell"];
 if (cell == nil) {
 // Load the top-level objects from the custom cell XIB.
 NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"InnovTableViewCell" owner:self options:nil];
 // Grab a pointer to the first object (presumably the custom cell, as that's all the XIB should contain).
 
 //cell = [topLevelObjects objectAtIndex:0];
 }
 
 // ((InnovTableViewCell*)cell).note = [[tagNotesDictionary objectForKey:((Tag *)[availableTags objectAtIndex:indexPath.section]).tagName] objectAtIndex:indexPath.row];
 //   [((InnovTableViewCell*)cell) updateCell];
 
 
 return cell;
 }
 
 -(NSString *)tableView:(UITableView *)atableView titleForHeaderInSection:(NSInteger)section{
 return ((Tag *)[availableTags objectAtIndex:section]).tagName;
 }
 
 - (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
 UIView *headerView = [[[UIView alloc] initWithFrame:CGRectMake(0,0, 320, 44)] autorelease];
 UILabel *label = [[[UILabel alloc] initWithFrame:headerView.frame] autorelease];
 label.textColor = [UIColor redColor];
 label.text = [NSString stringWithFormat:@"Section %i", section];
 
 [headerView addSubview:label];
 return headerView;
 }
 
 
 -(CGFloat)tableView:(UITableView *)atableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
 return 500;// [[UIScreen mainScreen] applicationFrame].size.height - self.navigationController.navigationBar.frame.size.height;
 #warning unimplemented
 }
 
 - (void)tableView:(UITableView *)atableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
 #warning unimplemented
 
 }
 */
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
    quiltView = nil;
    settingsView = nil;
    [super viewDidUnload];
}

@end