//
//  InnovViewController.m
//  ARIS
//
//  Created by Jacob Hanshaw on 3/25/13.
//
//

#import <QuartzCore/QuartzCore.h>
#import "InnovViewController.h"
#import "Note.h"
#import "InnovNoteViewController.h"

#import "TMQuiltView.h"
#import "TMPhotoQuiltViewCell.h"

#define INITIALSPAN 0.001
#define WIDESPAN    0.025

//For expanding view
#define ANIMATION_TIME     0.6
#define SCALED_DOWN_AMOUNT 0.01  // For example, 0.01 is one hundredth of the normal size

#define RIGHTSIDEMARGIN 20

@interface InnovViewController () <TMQuiltViewDataSource, TMQuiltViewDelegate>

@end

@implementation InnovViewController

@synthesize isLocal, lastLocation, noteToAdd;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        tracking = YES;
        
        locationsToAdd     = [[NSMutableArray alloc] initWithCapacity:10];
        locationsToRemove  = [[NSMutableArray alloc] initWithCapacity:10];
        
        availableTags      = [[NSMutableArray alloc] initWithCapacity:10];
        tagNotesDictionary = [[NSMutableDictionary alloc] init];
        
        images             = [[NSMutableArray alloc] initWithCapacity:20];
        text               = [[NSMutableArray alloc] initWithCapacity:20];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerMoved)                        name:@"PlayerMoved"                             object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addLocationsToNewQueue:)    name:@"NewlyAvailableLocationsAvailable"        object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addLocationsToRemoveQueue:) name:@"NewlyUnavailableLocationsAvailable"      object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshViewFromModel)               name:@"NewNoteListReady"       object:nil];
        
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
    
    [contentView addSubview:mapContentView];
    [mapView setDelegate:self];
    
#warning update madison's center
    madisonCenter = [[CLLocation alloc] initWithLatitude:43.07 longitude:-89.41];
    
    //Center on Madison
	MKCoordinateRegion region = mapView.region;
	region.center = madisonCenter.coordinate;
	region.span = MKCoordinateSpanMake(WIDESPAN, WIDESPAN);
    
	[mapView setRegion:region animated:NO];
    
    notePopUp.hidden = YES;
    notePopUp.center = contentView.center;
    notePopUp.transform=CGAffineTransformMakeScale(SCALED_DOWN_AMOUNT, SCALED_DOWN_AMOUNT);
    notePopUp.layer.cornerRadius = 9.0f;
    [mapContentView addSubview:notePopUp];
    
    showTagsButton.layer.cornerRadius = 4.0f;
    
    selectedTagsVC = [[InnovSelectedTagsViewController alloc] init];
    selectedTagsVC.delegate = self;
    CGRect selectedTagsFrame = selectedTagsVC.view.frame;
    selectedTagsFrame.origin.x = -self.view.frame.size.width/2;
    selectedTagsFrame.origin.y = self.view.frame.size.height/2+12;
    selectedTagsVC.view.frame = selectedTagsFrame;
    [self addChildViewController:selectedTagsVC];
    [selectedTagsVC didMoveToParentViewController:self];
    [self.view addSubview:selectedTagsVC.view];
    
    settingsView.layer.anchorPoint = CGPointMake(1, 0);
    CGRect settingsLocation = settingsView.frame;
    settingsLocation.origin.x = self.view.frame.size.width  - settingsView.frame.size.width;
    settingsLocation.origin.y = 0;//-settingsView.frame.size.height/2;
    settingsView.frame = settingsLocation;
    [self.view addSubview:settingsView];
    
    settingsView.hidden = YES;
    // settingsView.transform=CGAffineTransformMakeScale(SCALED_DOWN_AMOUNT, SCALED_DOWN_AMOUNT);
    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    
    switchButton = [UIButton buttonWithType:UIButtonTypeCustom];
    switchButton.frame = CGRectMake(0, 0, 30, 30);
    [switchButton addTarget:self action:@selector(switchViews) forControlEvents:UIControlEventTouchUpInside];
    [switchButton setBackgroundImage: [UIImage imageNamed:@"noteicon.png"] forState:UIControlStateNormal];
    [switchButton setBackgroundImage: [UIImage imageNamed:@"noteicon.png"] forState:UIControlStateHighlighted];
    switchViewsBarButton = [[UIBarButtonItem alloc] initWithCustomView:switchButton];
    self.navigationItem.leftBarButtonItem = switchViewsBarButton;
    
    searchBarTop = [[UISearchBar alloc] initWithFrame:CGRectMake(-5.0, 0.0, 320.0, 44.0)];
    searchBarTop.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    searchBarTop.barStyle = UIBarStyleBlack;
    UIView *searchBarView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 310.0, 44.0)];
    searchBarView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    searchBarTop.delegate = self;
    [searchBarView addSubview:searchBarTop];
    self.navigationItem.titleView = searchBarView;
    
    settingsBarButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"14-gear.png"] style:UIBarButtonItemStylePlain target:self action:@selector(settingsPressed)];
    self.navigationItem.rightBarButtonItem = settingsBarButton;
    
    tracking = NO;
    
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
    
	[[AppServices sharedAppServices] updateServerMapViewed];
	
    //  [self playerMoved];
    [self refreshViewFromModel];
	[self refresh];
	
	if (refreshTimer && [refreshTimer isValid]) [refreshTimer invalidate];
	refreshTimer = [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(refresh) userInfo:nil repeats:YES];
    
    if(noteToAdd != nil){
        [self animateInNote:noteToAdd];
        noteToAdd = nil;
    }
    
}

- (void) animateInNote: (Note *) note {
#warning unimplemented
    //Switch to mapview
    //Animate in note
}

/*
 - (IBAction) changeMapType:(id)sender
 {
 ARISAppDelegate* appDelegate = (ARISAppDelegate *)[[UIApplication sharedApplication] delegate];
 [appDelegate playAudioAlert:@"ticktick" shouldVibrate:NO];
 
 switch (mapView.mapType)
 {
 case MKMapTypeStandard:
 mapView.mapType=MKMapTypeSatellite;
 break;
 case MKMapTypeSatellite:
 mapView.mapType=MKMapTypeHybrid;
 break;
 case MKMapTypeHybrid:
 mapView.mapType=MKMapTypeStandard;
 break;
 }
 }
 */

- (void) refresh
{
    if (mapView)
    {
        [[AppServices sharedAppServices] fetchPlayerLocationList];
        [[AppServices sharedAppServices] fetchPlayerNoteListAsynchronously:YES];
        [[AppServices sharedAppServices] fetchGameNoteListAsynchronously:YES];
        [[AppServices sharedAppServices] fetchGameNoteTagsAsynchronously: YES];
        
        if (tracking) [self zoomAndCenterMap];
    }
}

- (void) playerMoved
{
    CLLocationDistance distance = [[AppModel sharedAppModel].playerLocation distanceFromLocation:madisonCenter];
    
#warning update distance magic number
    isLocal = distance <= 20000;
    trackingButton.hidden = !isLocal;
    [mapView setShowsUserLocation:isLocal];
    if (mapView && tracking) [self zoomAndCenterMap];
}

- (void) zoomAndCenterMap
{
	appSetNextRegionChange = YES;
	
	//Center the map on the player
    #warning CHANGE TO CENTER OF MADISON
	MKCoordinateRegion region = mapView.region;
	region.center = [AppModel sharedAppModel].playerLocation.coordinate;
	region.span = MKCoordinateSpanMake(INITIALSPAN, INITIALSPAN);
    
	[mapView setRegion:region animated:YES];
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
    if(!mapView) return;
    
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

#pragma mark MKMapViewDelegate
- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated
{
	if (!appSetNextRegionChange)
    {
		tracking = NO;
		trackingButton.backgroundColor = [UIColor lightGrayColor];
	}
	
	appSetNextRegionChange = NO;
}

- (void)mapView:(MKMapView *)mV didAddAnnotationViews:(NSArray *)views
{
    for (AnnotationView *aView in views)
    {
        //Drop animation
        CGRect endFrame = aView.frame;
        aView.frame = CGRectMake(aView.frame.origin.x, aView.frame.origin.y - 230.0, aView.frame.size.width, aView.frame.size.height);
        [UIView animateWithDuration:0.45 delay:0.0 options:UIViewAnimationCurveEaseIn animations:^{[aView setFrame: endFrame];} completion:^(BOOL finished) {}];
    }
}

- (MKAnnotationView *)mapView:(MKMapView *)myMapView viewForAnnotation:(id <MKAnnotation>)annotation
{
	if (annotation == mapView.userLocation)
        return nil;
    else
        return [[AnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:nil];
}


#pragma mark Buttons Pressed

- (IBAction)trackingButtonPressed:(id)sender
{
	[(ARISAppDelegate *)[[UIApplication sharedApplication] delegate] playAudioAlert:@"ticktick" shouldVibrate:NO];
	
	tracking = YES;
	trackingButton.backgroundColor = [UIColor blueColor];
    
	[[[MyCLController sharedMyCLController] locationManager] stopUpdatingLocation];
	[[[MyCLController sharedMyCLController] locationManager] startUpdatingLocation];
    
	[self refresh];
}

- (IBAction)showTagsPressed:(id)sender
{
    [selectedTagsVC toggleDisplay];
}

- (IBAction)cameraPressed:(id)sender {
    
    editorVC = [[InnovNoteEditorViewController alloc] init];
    editorVC.delegate = self;
    lastLocation = [[CLLocation alloc] initWithLatitude:mapView.region.center.latitude longitude:mapView.region.center.longitude];
    
    [self.navigationController pushViewController:editorVC animated:NO];
}

- (void)settingsPressed
{
    if(settingsView.hidden || hidingSettings) [self showSettings];
    else [self hideSettings];
}

- (IBAction) presentNote:(id) sender
{
#warning change if other possible senders
    Note * note;
    if([sender isKindOfClass:[UIButton class]]) note = ((MapNotePopUp *)((UIButton *)sender).superview).note;
    else note = sender;
    //NoteDetailsViewController *noteVC = [[NoteDetailsViewController alloc] initWithNibName:@"NoteDetailsViewController" bundle:nil];
    InnovNoteViewController *noteVC = [[InnovNoteViewController alloc] init];
    noteVC.note = note;
    noteVC.delegate = self;
    [self.navigationController pushViewController:noteVC animated:YES];
    Annotation *currentAnnotation = [mapView.selectedAnnotations lastObject];
    [mapView deselectAnnotation:currentAnnotation animated:YES];
}

- (IBAction)createLinkPressed:(id)sender {
#warning unimplemented
}

- (IBAction)notificationsPressed:(id)sender {
#warning unimplemented
}

- (IBAction)autoPlayPressed:(id)sender {
#warning unimplemented
}

- (IBAction)aboutPressed:(id)sender {
#warning unimplemented
}

- (void)mapView:(MKMapView *)aMapView didSelectAnnotationView:(MKAnnotationView *)view
{
    if(view.annotation == aMapView.userLocation) return;
	Location *location = ((Annotation*)view.annotation).location;
    [self showNotePopUpForLocation:location];
}

- (void) showNotePopUpForLocation: (Location *) location {
    
    Note * note    = [[AppModel sharedAppModel] noteForNoteId:location.objectId playerListYesGameListNo:NO];
    if(!note) note = [[AppModel sharedAppModel] noteForNoteId:location.objectId playerListYesGameListNo:YES];
    if(note){
        //if(!notePopUp.hidden && !hidingPopUp) [self hideNotePopUp]; //HAndled by touchesBegan
        [self showNotePopUpForNote:note];
    }
    else{
        NSLog(@"InnovViewController: ERROR: attempted to display nil note");
        Annotation *currentAnnotation = [mapView.selectedAnnotations lastObject];
        [mapView deselectAnnotation:currentAnnotation animated:YES];
        return;
    }
    
}

#pragma mark TouchesBegan Method

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	[searchBarTop resignFirstResponder];
    if(!notePopUp.hidden && !hidingPopUp)
        [self hideNotePopUp];
    if(!settingsView.hidden && !hidingSettings)
        [self hideSettings];
    [selectedTagsVC hide];
}

#pragma mark Animations

- (void)showSettings
{
    hidingSettings = NO;
    settingsView.hidden = NO;
    settingsView.userInteractionEnabled = NO;
    
 //   settingsView.layer.anchorPoint = CGPointMake(1, 0);
    CABasicAnimation *scale = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    [scale setFromValue:[NSNumber numberWithFloat:0.0f]];
    [scale setToValue:[NSNumber numberWithFloat:1.0f]];
    [scale setDuration:0.8f];
    [scale setRemovedOnCompletion:NO];
    [scale setFillMode:kCAFillModeForwards];
    scale.delegate = self;
    [settingsView.layer addAnimation:scale forKey:@"transform.scaleUp"];
}

- (void)hideSettings
{
    hidingSettings = YES;
    
   // settingsView.layer.anchorPoint = CGPointMake(1, 0);
    CABasicAnimation *scale = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    [scale setFromValue:[NSNumber numberWithFloat:1.0f]];
    [scale setToValue:[NSNumber numberWithFloat:0.0f]];
    [scale setDuration:0.8f];
    [scale setRemovedOnCompletion:NO];
    [scale setFillMode:kCAFillModeForwards];
    scale.delegate = self;
    [settingsView.layer addAnimation:scale forKey:@"transform.scaleDown"];
    
}

- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag
{
    if(flag){
        if (theAnimation == [[settingsView layer] animationForKey:@"transform.scaleUp"] && !hidingSettings)
            settingsView.userInteractionEnabled = YES;
        else if(theAnimation == [[settingsView layer] animationForKey:@"transform.scaleDown"] && hidingSettings)
            settingsView.hidden = YES;
    }
}

- (void) showNotePopUpForNote: (Note *) note {
    
    hidingPopUp = NO;
    
    MKCoordinateRegion region = mapView.region;
	region.center = CLLocationCoordinate2DMake(note.latitude, note.longitude);
	[mapView setRegion:region animated:YES];
    
    notePopUp.note = note;
    notePopUp.textLabel.text = note.title;
    for(int i = 0; i < [note.contents count]; ++i)
    {
        NoteContent *noteContent = [note.contents objectAtIndex:i];
        if([[noteContent getType] isEqualToString:kNoteContentTypePhoto]) [notePopUp.imageView loadImageFromMedia:[noteContent getMedia]];
    }
    
    Annotation *currentAnnotation = [mapView.selectedAnnotations lastObject];
    [mapView deselectAnnotation:currentAnnotation animated:YES];
    
    notePopUp.hidden = NO;
    notePopUp.userInteractionEnabled = NO;
    [UIView beginAnimations:@"animationExpandNote" context:NULL];
    [UIView setAnimationDuration:ANIMATION_TIME];
    notePopUp.transform=CGAffineTransformMakeScale(1, 1);
    [UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
	[UIView commitAnimations];
    
}

-(void)animationDidStop:(NSString *)animationID finished:(BOOL)finished context:(void *)context{
    if(finished)
    {
        if ([animationID isEqualToString:@"animationExpandNote"] && !hidingPopUp) notePopUp.userInteractionEnabled=YES;
        else if ([animationID isEqualToString:@"animationShrinkNote"] && hidingPopUp) notePopUp.hidden = YES;
    }
}

- (void) hideNotePopUp {
    
    hidingPopUp = YES;
    
    [UIView beginAnimations:@"animationShrinkNote" context:NULL];
    [UIView setAnimationDuration:ANIMATION_TIME];
    notePopUp.transform=CGAffineTransformMakeScale(SCALED_DOWN_AMOUNT, SCALED_DOWN_AMOUNT);
    [UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
	[UIView commitAnimations];
}

- (void)switchViews {
    [UIView beginAnimations:@"View Flip" context:nil];
    [UIView setAnimationDuration:1.25];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    
    UIView *coming = nil;
    UIView *going = nil;
    NSString *newButtonTitle;
    NSString *newButtonImageName;
    UIViewAnimationTransition transition;
    
    if (mapContentView.superview == nil)
    {
        coming = mapContentView;
        going = listContentView;
        transition = UIViewAnimationTransitionFlipFromLeft;
        newButtonTitle = @"List";
        newButtonImageName = @"noteicon.png";
    }
    else
    {
        coming = listContentView;
        going = mapContentView;
        transition = UIViewAnimationTransitionFlipFromRight;
        newButtonTitle = @"Map";
        newButtonImageName = @"103-map.png";
    }
    //  attempt to landscape
    CGRect contentFrame = contentView.frame;
    contentFrame.origin.x = 0;
    contentFrame.origin.y = 0;
    coming.frame = contentFrame;
    if(coming == mapContentView){
        mapView.frame = contentFrame;
        [mapContentView setNeedsDisplay];
    }
    else{
        quiltView.frame = contentFrame;
        [listContentView setNeedsDisplay];
    }
    
    [UIView setAnimationTransition: transition forView:contentView cache:YES];
    [going removeFromSuperview];
    [contentView insertSubview: coming atIndex:0];
    [UIView commitAnimations];
    [UIView beginAnimations:@"Button Flip" context:nil];
    [UIView setAnimationDuration:1.25];
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
    mapContentView = nil;
    listContentView = nil;
    contentView = nil;
    showTagsButton = nil;
    mapView = nil;
    trackingButton = nil;
    switchViewsBarButton = nil;
    notePopUp = nil;
    quiltView = nil;
    settingsView = nil;
    [super viewDidUnload];
}

@end