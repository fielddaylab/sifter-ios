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
#import "NoteDetailsViewController.h"
#import "NoteEditorViewController.h"

#define INITIALSPAN 0.001
#define WIDESPAN    0.025

//For expanding view
#define ANIMATION_TIME     0.6
#define SCALED_DOWN_AMOUNT 0.01  // For example, 0.01 is one hundredth of the normal size

@interface InnovViewController ()

@end

@implementation InnovViewController

@synthesize isLocal, lastLocation, noteToAdd;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        tracking = YES;
        
        locationsToAdd    = [[NSMutableArray alloc] initWithCapacity:10];
        locationsToRemove = [[NSMutableArray alloc] initWithCapacity:10];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerMoved)
                                                     name:@"PlayerMoved"                                  object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addLocationsToNewQueue:)    name:@"NewlyAvailableLocationsAvailable"             object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addLocationsToRemoveQueue:) name:@"NewlyUnavailableLocationsAvailable"           object:nil];
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
    
    [mapContentView addSubview:notePopUp];
    notePopUp.hidden = YES;
    notePopUp.center = contentView.center;
    notePopUp.transform=CGAffineTransformMakeScale(SCALED_DOWN_AMOUNT, SCALED_DOWN_AMOUNT);
    notePopUp.layer.cornerRadius = 9.0f;
    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    
    showTagsButton.layer.cornerRadius = 4.0f;
    
    switchButton = [UIButton buttonWithType:UIButtonTypeCustom];
    switchButton.frame = CGRectMake(0, 0, 30, 30);
    [switchButton addTarget:self action:@selector(switchViews) forControlEvents:UIControlEventTouchUpInside];
    [switchButton setBackgroundImage: [UIImage imageNamed:@"noteicon.png"] forState:UIControlStateNormal];
    [switchButton setBackgroundImage: [UIImage imageNamed:@"noteicon.png"] forState:UIControlStateHighlighted];
    switchViewsBarButton = [[UIBarButtonItem alloc] initWithCustomView:switchButton];
    self.navigationItem.leftBarButtonItem = switchViewsBarButton;
    
    searchBarTop = [[UISearchBar alloc] initWithFrame:CGRectMake(-5.0, 0.0, 320.0, 44.0)];
    searchBarTop.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    searchBarTop.barStyle = UIBarStyleBlack;
    UIView *searchBarView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 310.0, 44.0)];
    searchBarView.autoresizingMask = 0;
    searchBarTop.delegate = self;
    [searchBarView addSubview:searchBarTop];
    self.navigationItem.titleView = searchBarView;
    
    settingsBarButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"14-gear.png"] style:UIBarButtonItemStylePlain target:self action:@selector(settingsPressed)];
    self.navigationItem.rightBarButtonItem = settingsBarButton;
    
    tracking = NO;
    
	trackingButton.backgroundColor = [UIColor lightGrayColor];
    trackingButton.layer.cornerRadius = 4.0f;
    trackingButton.hidden = YES;
    
    [self refresh];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // [self.navigationController setNavigationBarHidden:YES animated:NO];
    // [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
    
    //   if     ([[AppModel sharedAppModel].currentGame.mapType isEqualToString:@"SATELLITE"]) mapView.mapType = MKMapTypeSatellite;
    //   else if([[AppModel sharedAppModel].currentGame.mapType isEqualToString:@"HYBRID"])    mapView.mapType = MKMapTypeHybrid;
    //   else                                                                                  mapView.mapType = MKMapTypeStandard;
    
    if(noteToAdd != nil){
#warning unimplemented
        //hide new note
    }
}

- (void) viewDidAppear:(BOOL)animated
{
    
    [super viewDidAppear:animated];
    
	[[AppServices sharedAppServices] updateServerMapViewed];
    
    //  [self.navigationController setNavigationBarHidden:NO animated:NO];
	
    //  [self playerMoved];
    [self refreshViewFromModel];
	[self refresh];
	
	if (refreshTimer && [refreshTimer isValid]) [refreshTimer invalidate];
	refreshTimer = [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(refresh) userInfo:nil repeats:YES];
    
    if(noteToAdd != nil){
#warning unimplemented
        [self animateInNewNote];
        noteToAdd = nil;
    }
    
}

- (void) animateInNewNote {
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
- (IBAction)trackingButtonPressed:(id)sender
{
	[(ARISAppDelegate *)[[UIApplication sharedApplication] delegate] playAudioAlert:@"ticktick" shouldVibrate:NO];
	
	tracking = YES;
	trackingButton.backgroundColor = [UIColor blueColor];
    
	[[[MyCLController sharedMyCLController] locationManager] stopUpdatingLocation];
	[[[MyCLController sharedMyCLController] locationManager] startUpdatingLocation];
    
	[self refresh];
}

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
	MKCoordinateRegion region = mapView.region;
	region.center = [AppModel sharedAppModel].playerLocation.coordinate;
#warning CHANGE TO CENTER OF MADISON
	region.span = MKCoordinateSpanMake(INITIALSPAN, INITIALSPAN);
    
	[mapView setRegion:region animated:YES];
}

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
        if (tmpLocation.hidden == YES || tmpLocation.kind != NearbyObjectNote) continue; //Would check if player and if players should be shown, but only adds notes anyway, also removed some items code
        
        CLLocationCoordinate2D locationLatLong = tmpLocation.location.coordinate;
        
        Annotation *annotation = [[Annotation alloc]initWithCoordinate:locationLatLong];
        annotation.location = tmpLocation;
        annotation.title = tmpLocation.name;
        annotation.kind = tmpLocation.kind;
        annotation.iconMediaId = tmpLocation.iconMediaId;
        
        [mapView addAnnotation:annotation];
    }
    [locationsToAdd removeAllObjects];
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
    if(view.annotation == aMapView.userLocation) return;
	Location *location = ((Annotation*)view.annotation).location;
    [self showNotePopUpForLocation:location];
    /*
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
     
     [actionSheet showInView:view];*/
}

- (void) showNotePopUpForLocation: (Location *) location {
    
    Note * note    = [[AppModel sharedAppModel] noteForNoteId:location.objectId playerListYesGameListNo:NO];
    if(!note) note = [[AppModel sharedAppModel] noteForNoteId:location.objectId playerListYesGameListNo:YES];
    if(note){
        [self showNotePopUpForNote:note];
    }
    else{
        NSLog(@"InnovViewController: ERROR: attempted to display nil note");
        Annotation *currentAnnotation = [mapView.selectedAnnotations lastObject];
        [mapView deselectAnnotation:currentAnnotation animated:YES];
        return;
    }
    
}

- (void) showNotePopUpForNote: (Note *) note {
    
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
    [UIView beginAnimations:@"animationExpand" context:NULL];
    [UIView setAnimationDuration:ANIMATION_TIME];
    notePopUp.transform=CGAffineTransformMakeScale(1, 1);
    [UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
	[UIView commitAnimations];
    
}

-(void)animationDidStop:(NSString *)animationID finished:(BOOL)finished context:(void *)context{
	if ([animationID isEqualToString:@"animationExpand"]) notePopUp.userInteractionEnabled=YES;
    else if ([animationID isEqualToString:@"animationShrink"]) notePopUp.hidden = YES;
}

- (void) hideNotePopUp {
    [UIView beginAnimations:@"animationShrink" context:NULL];
    [UIView setAnimationDuration:ANIMATION_TIME];
    notePopUp.transform=CGAffineTransformMakeScale(SCALED_DOWN_AMOUNT, SCALED_DOWN_AMOUNT);
    [UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
	[UIView commitAnimations];
}

- (IBAction) presentNote:(UITapGestureRecognizer *) sender {
#warning change if other possible senders
    Note * note = ((MapNotePopUp *)sender.view).note;
    NoteDetailsViewController *dataVC = [[NoteDetailsViewController alloc] initWithNibName:@"NoteDetailsViewController" bundle:nil];
    dataVC.note = note;
    dataVC.delegate = self;
    [self.navigationController pushViewController:dataVC animated:YES];
    Annotation *currentAnnotation = [mapView.selectedAnnotations lastObject];
    [mapView deselectAnnotation:currentAnnotation animated:YES];
}

- (IBAction)test:(UITapGestureRecognizer *)sender {
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

- (void)settingsPressed
{
#warning unimplemented
}

- (IBAction)showTagsPressed:(id)sender
{
#warning unimplemented
}

- (IBAction)cameraPressed:(id)sender {
    
    editorVC = [[InnovNoteEditorViewController alloc] init];
    editorVC.delegate = self;
    lastLocation = [[CLLocation alloc] initWithLatitude:mapView.region.center.latitude longitude:mapView.region.center.longitude];
    
    [self.navigationController pushViewController:editorVC animated:YES];
}

#pragma mark UISearchBar Methods

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	[searchBarTop resignFirstResponder];
    if(!notePopUp.hidden) [self hideNotePopUp];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBarTop resignFirstResponder];
#warning THEN DO FUN THINGS!
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
    #warning unimplemented
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
    #warning unimplemented
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
#warning unimplemented
	
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    /*
    NSEnumerator *existingAnnotationsEnumerator = [[[mapView annotations] copy] objectEnumerator];
    NSObject <MKAnnotation> *annotation;
    while (annotation = [existingAnnotationsEnumerator nextObject])
        if(annotation != mapView.userLocation) [mapView removeAnnotation:annotation];
     */
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
    [super viewDidUnload];
}

@end
