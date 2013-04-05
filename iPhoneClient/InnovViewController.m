//
//  InnovViewController.m
//  ARIS
//
//  Created by Jacob Hanshaw on 3/25/13.
//
//

#import <QuartzCore/QuartzCore.h>
#import "InnovViewController.h"
#import "NoteDetailsViewController.h"
#import "NoteEditorViewController.h"

#define INITIALSPAN 0.001

@interface InnovViewController ()

@end

@implementation InnovViewController

@synthesize note;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        tracking = YES;
        
        locationsToAdd    = [[NSMutableArray alloc] initWithCapacity:10];
        locationsToRemove = [[NSMutableArray alloc] initWithCapacity:10];
		
     //   [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeLoadingIndicator)     name:@"ConnectionLost"                               object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerMoved)                name:@"PlayerMoved"                                  object:nil];
	//	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeLoadingIndicator)     name:@"ReceivedLocationList"                         object:nil];
    //    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateOverlays)             name:@"NewOverlayListReady"                          object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addLocationsToNewQueue:)    name:@"NewlyAvailableLocationsAvailable"             object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addLocationsToRemoveQueue:) name:@"NewlyUnavailableLocationsAvailable"           object:nil];
   //     [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(incrementBadge)             name:@"NewlyChangedLocationsGameNotificationSent"    object:nil];
    }
    return self;
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
- (IBAction) refreshButtonAction
{
	//[(ARISAppDelegate *)[[UIApplication sharedApplication] delegate] playAudioAlert:@"ticktick" shouldVibrate:NO];
	
	tracking = YES;
	trackingButton.backgroundColor = [UIColor blueColor];
    
	[[[MyCLController sharedMyCLController] locationManager] stopUpdatingLocation];
	[[[MyCLController sharedMyCLController] locationManager] startUpdatingLocation];
    
	[self refresh];
}
/*
- (void)playerButtonTouch
{
    [AppModel sharedAppModel].hidePlayers = ![AppModel sharedAppModel].hidePlayers;
    [self hideOrShowPlayerLocations];
}

- (void)hideOrShowPlayerLocations
{
    if([AppModel sharedAppModel].hidePlayers)
    {
        [playerButton setStyle:UIBarButtonItemStyleBordered];
        if (mapContentView)
        {
            NSEnumerator *existingAnnotationsEnumerator = [[[mapContentView annotations] copy] objectEnumerator];
            Annotation *annotation;
            while (annotation = [existingAnnotationsEnumerator nextObject])
            {
                if (annotation != (Annotation *)mapView.userLocation && annotation.kind == NearbyObjectPlayer)
                    [mapView removeAnnotation:annotation];
            }
        }
    }
    else
        [playerButton setStyle:UIBarButtonItemStyleDone];
    
	[[[MyCLController sharedMyCLController] locationManager] stopUpdatingLocation];
	[[[MyCLController sharedMyCLController] locationManager] startUpdatingLocation];
    
    tracking = NO;
	[self refresh];
}

- (IBAction) addMediaButtonAction:(id)sender
{
    NoteEditorViewController *noteVC = [[NoteEditorViewController alloc] initWithNibName:@"NoteEditorViewController" bundle:nil];
    noteVC.delegate = self;
    [self.navigationController pushViewController:noteVC animated:YES];
}


- (MKOverlayView *) mapView:(MKMapView *)mapView viewForOverlay:(id)ovrlay
{
    TileOverlayView *view = [[TileOverlayView alloc] initWithOverlay:ovrlay];
    view.tileAlpha = 1;
    
    [AppModel sharedAppModel].overlayIsVisible = true;
    
    return view;
}

- (void) updateOverlays
{
    [overlayArray removeAllObjects];
    [mapContentView removeOverlays:[mapContentView overlays]];
    
    for(int i = 0; i < [[AppModel sharedAppModel].overlayList count]; i++)
    {
        overlay = [[TileOverlay alloc] initWithIndex: i];
        if(overlay != NULL)
        {
            [overlayArray addObject:overlay];
            [mapContentView addOverlay:overlay];
        }
    }
}
*/
- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];

 //   if     ([[AppModel sharedAppModel].currentGame.mapType isEqualToString:@"SATELLITE"]) mapView.mapType = MKMapTypeSatellite;
 //   else if([[AppModel sharedAppModel].currentGame.mapType isEqualToString:@"HYBRID"])    mapView.mapType = MKMapTypeHybrid;
 //   else                                                                                  mapView.mapType = MKMapTypeStandard;
    [mapView setShowsUserLocation:YES];
 //   [self hideOrShowPlayerLocations];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
	[[AppServices sharedAppServices] updateServerMapViewed];
    
    [self.navigationController setNavigationBarHidden:NO animated:NO];
	
    [self refreshViewFromModel];
	[self refresh];
	
	if (refreshTimer && [refreshTimer isValid]) [refreshTimer invalidate];
	refreshTimer = [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(refresh) userInfo:nil repeats:YES];
   // [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
}

- (void) refresh
{
    if (mapView)
    {
        if ([AppModel sharedAppModel].currentGame.gameId != 0)
        {
            [[AppServices sharedAppServices] fetchPlayerLocationList];
       //     [[AppServices sharedAppServices] fetchPlayerOverlayList];
       //     [self showLoadingIndicator];
        }
        
        if (tracking) [self zoomAndCenterMap];
        
        //What? Pen down? What's going on here?
        /* if(mapTrace){
         [self.route addObject:[AppModel sharedAppModel].playerLocation];
         MKPolyline *line = [[MKPolyline alloc] init];
         line
         }*/
    }
}

- (void) playerMoved
{
    if (mapView && tracking) [self zoomAndCenterMap];
}

- (void) zoomAndCenterMap
{
	appSetNextRegionChange = YES;
	
	//Center the map on the player
	MKCoordinateRegion region = mapView.region;
	region.center = [AppModel sharedAppModel].playerLocation.coordinate; //FIX: CHANGE TO CENTER OF MADISON
	region.span = MKCoordinateSpanMake(INITIALSPAN, INITIALSPAN);
    
	[mapView setRegion:region animated:YES];
}
/*
- (void) showLoadingIndicator
{
	UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
	UIBarButtonItem * barButton = [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];
	[[self navigationItem] setRightBarButtonItem:barButton];
	[activityIndicator startAnimating];
}

- (void) removeLoadingIndicator
{
	[[self navigationItem] setRightBarButtonItem:nil];
}
*/
- (void) addLocationsToNewQueue:(NSNotification *)notification
{
    //Quickly make sure we're not re-adding any info (let the 'newly' added ones take over)
    NSArray *newLocations = (NSArray *)[notification.userInfo objectForKey:@"newlyAvailableLocations"];
    for(int i = 0; i < [newLocations count]; i++)
    {
        for(int j = 0; j < [locationsToAdd count]; j++)
        {
            if([((Location *)[newLocations objectAtIndex:i]) compareTo:((Location *)[locationsToAdd objectAtIndex:j])])
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
    
    NSObject<MKAnnotation> *tmpMKAnnotation;
    Annotation *tmpAnnotation;
    for (int i = 0; i < [[mapView annotations] count]; i++)
    {
        if((tmpMKAnnotation = [[mapView annotations] objectAtIndex:i]) == mapView.userLocation ||
           !((tmpAnnotation = (Annotation*)tmpMKAnnotation) && [tmpAnnotation respondsToSelector:@selector(title)])) continue;
        for(int j = 0; j < [locationsToRemove count]; j++)
        {
            if([tmpAnnotation.location compareTo:((Location *)[locationsToRemove objectAtIndex:j])])
            {
                [mapView removeAnnotation:tmpAnnotation];
                i--;
            }
        }
    }
     
    [locationsToRemove removeAllObjects];
    
    //Add new locations second
    Location *tmpLocation;
    for (int i = 0; i < [locationsToAdd count]; i++)
    {
        tmpLocation = (Location *)[locationsToAdd objectAtIndex:i];
        if (tmpLocation.hidden == YES || (tmpLocation.kind == NearbyObjectPlayer && [AppModel sharedAppModel].hidePlayers)) continue;
        
        CLLocationCoordinate2D locationLatLong = tmpLocation.location.coordinate;
        
        Annotation *annotation = [[Annotation alloc]initWithCoordinate:locationLatLong];
        annotation.location = tmpLocation;
        annotation.title = tmpLocation.name;
        annotation.kind = tmpLocation.kind;
        annotation.iconMediaId = tmpLocation.iconMediaId;
        
        if (tmpLocation.kind == NearbyObjectItem && tmpLocation.qty > 1 && annotation.title != nil)
            annotation.subtitle = [NSString stringWithFormat:@"x %d",tmpLocation.qty];
        
        if(annotation.kind == NearbyObjectNote) [mapView addAnnotation:annotation];
    }
    [locationsToAdd removeAllObjects];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

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

- (MKAnnotationView *)mapView:(MKMapView *)myMapView viewForAnnotation:(id <MKAnnotation>)annotation
{
	if (annotation == mapView.userLocation)
        return nil;
    else
        return [[AnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:nil];
}

- (void)mapView:(MKMapView *)aMapView didSelectAnnotationView:(MKAnnotationView *)view
{
	Location *location = ((Annotation*)view.annotation).location;
    if(view.annotation == aMapView.userLocation) return;
    
	NSMutableArray *buttonTitles = [NSMutableArray arrayWithCapacity:1];
	int cancelButtonIndex = 0;
	if (location.allowsQuickTravel)
    {
		[buttonTitles addObject: NSLocalizedString(@"GPSViewQuickTravelKey", @"")];
		cancelButtonIndex = 1;
	}
	[buttonTitles addObject: NSLocalizedString(@"CancelKey", @"")];
	
    UIActionSheet *actionSheet = [[UIActionSheet alloc]initWithTitle:location.name
															delegate:self
												   cancelButtonTitle:nil
											  destructiveButtonTitle:nil
												   otherButtonTitles:nil];
	actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
	actionSheet.cancelButtonIndex = cancelButtonIndex;
	
	for (NSString *title in buttonTitles)
		[actionSheet addButtonWithTitle:title];
	
	[actionSheet showInView:view];
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

- (double)getZoomLevel:(MKMapView *)mV
{
    double MERCATOR_RADIUS = 85445659.44705395;
    double MAX_GOOGLE_LEVELS  = 20;
    CLLocationDegrees longitudeDelta = mV.region.span.longitudeDelta;
    CGFloat mapWidthInPixels = mV.bounds.size.width;
    double zoomScale = longitudeDelta * MERCATOR_RADIUS * M_PI / (180.0 * mapWidthInPixels);
    double zoomer = MAX_GOOGLE_LEVELS - log2( zoomScale );
    if ( zoomer < 0 ) zoomer = 0;
    return zoomer;
}

#pragma mark UIActionSheet Delegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	Annotation *currentAnnotation = [mapView.selectedAnnotations lastObject];
	
	if (buttonIndex == actionSheet.cancelButtonIndex)
        [mapView deselectAnnotation:currentAnnotation animated:YES];
	else
    {
         Note * note    = [[AppModel sharedAppModel] noteForNoteId:currentAnnotation.location.objectId playerListYesGameListNo:NO];
         if(!note) note = [[AppModel sharedAppModel] noteForNoteId:currentAnnotation.location.objectId playerListYesGameListNo:YES];
        if(note){
         NoteDetailsViewController *dataVC = [[NoteDetailsViewController alloc] initWithNibName:@"NoteDetailsViewController" bundle:nil];
         dataVC.note = note;
         dataVC.delegate = self;
            [self.navigationController pushViewController:dataVC animated:YES];
        [mapView deselectAnnotation:currentAnnotation animated:YES];
        }
        else{
            NSLog(@"InnovViewController: ERROR: attempted to display nil note");
        }
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    Game *game = [[Game alloc] init];
    game.gameId = 3377;
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
    
    [AppModel sharedAppModel].serverURL = [NSURL URLWithString:@"http://dev.arisgames.org/server"];
    
    [contentView addSubview:mapContentView];
    [mapView setDelegate:self];
    showTagsButton.layer.cornerRadius = 4.0f;
    trackingButton.layer.cornerRadius = 4.0f;
    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    
    switchButton = [UIButton buttonWithType:UIButtonTypeCustom];
    switchButton.frame = CGRectMake(0, 0, 30, 30);
    [switchButton addTarget:self action:@selector(switchViews) forControlEvents:UIControlEventTouchUpInside];
    [switchButton setBackgroundImage: [UIImage imageNamed:@"noteicon.png"] forState:UIControlStateNormal];
    [switchButton setBackgroundImage: [UIImage imageNamed:@"noteicon.png"] forState:UIControlStateHighlighted];
    switchViewsBarButton = [[UIBarButtonItem alloc] initWithCustomView:switchButton];
    self.navigationItem.leftBarButtonItem = switchViewsBarButton;
    settingsBarButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"14-gear.png"] style:UIBarButtonItemStylePlain target:self action:@selector(settingsPressed)];
    self.navigationItem.rightBarButtonItem = settingsBarButton;
	trackingButton.backgroundColor = [UIColor blueColor];
    
    searchBarTop = [[UISearchBar alloc] initWithFrame:CGRectMake(-5.0, 0.0, 320.0, 44.0)];
    searchBarTop.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    searchBarTop.barStyle = UIBarStyleBlack;
    UIView *searchBarView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 310.0, 44.0)];
    searchBarView.autoresizingMask = 0;
    searchBarTop.delegate = self;
    [searchBarView addSubview:searchBarTop];
    self.navigationItem.titleView = searchBarView;
    
    //addMediaButton.target = self;
    //addMediaButton.action = @selector(addMediaButtonAction:);
	
    //[self updateOverlays];
    [self refresh];
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

- (void)settingsPressed {
}

- (IBAction)showTagsPressed:(id)sender {
}

- (IBAction)cameraPressed:(id)sender {
    NoteEditorViewController *noteVC = [[NoteEditorViewController alloc] initWithNibName:@"NoteEditorViewController" bundle:nil];
    noteVC.startWithView = [sender tag] + 1;
    noteVC.delegate = self;
    [self.navigationController pushViewController:noteVC animated:NO];
}

- (IBAction)trackingButtonPressed:(id)sender {
    [self refreshButtonAction];
}

#pragma mark UISearchBar Methods 
 
- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	[searchBarTop resignFirstResponder];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBarTop resignFirstResponder];
    //FIX: THEN DO FUN THINGS!
}

#pragma mark TableView Delegate and Datasource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return 10;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
	if(cell == nil) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    
    cell.textLabel.text = [NSString stringWithFormat:@"Row: %d", indexPath.row];
    
	return cell;
}
/*
-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    //if(section==0)return  @"Group";
    // else
    //return NSLocalizedString(@"AttributesAttributesTitleKey", @"");
}
*/
// Customize the height of each row
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 60;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
	
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    NSEnumerator *existingAnnotationsEnumerator = [[[mapView annotations] copy] objectEnumerator];
    NSObject <MKAnnotation> *annotation;
    while (annotation = [existingAnnotationsEnumerator nextObject])
        if(annotation != mapView.userLocation) [mapView removeAnnotation:annotation];
}

- (void)viewDidUnload {
    mapContentView = nil;
    listContentView = nil;
    contentView = nil;
    showTagsButton = nil;
    mapView = nil;
    trackingButton = nil;
    switchViewsBarButton = nil;
    [super viewDidUnload];
}

@end
