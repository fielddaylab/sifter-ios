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
//#import "NoteDetailsViewController.h"
//#import "NoteEditorViewController.h"

#define INITIALSPAN 0.001
#define WIDESPAN    0.025

//For expanding view
#define ANIMATION_TIME     0.6
#define SCALED_DOWN_AMOUNT 0.01  // For example, 0.01 is one hundredth of the normal size

#define RIGHTSIDEMARGIN 20

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
		
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerMoved)                name:@"PlayerMoved"                             object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addLocationsToNewQueue:)    name:@"NewlyAvailableLocationsAvailable"        object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addLocationsToRemoveQueue:) name:@"NewlyUnavailableLocationsAvailable"      object:nil];
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
    game.gameId = 3407;
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
    
    showTagsButton.layer.cornerRadius = 4.0f;
    
    selectedTagsVC = [[InnovSelectedTagsViewController alloc] init];
    CGRect selectedTagsFrame = selectedTagsVC.view.frame;
    selectedTagsFrame.origin.x = -self.view.frame.size.width/2;
    selectedTagsFrame.origin.y = self.view.frame.size.height/2+12;
    selectedTagsVC.view.frame = selectedTagsFrame;
    [self addChildViewController:selectedTagsVC];
    [selectedTagsVC didMoveToParentViewController:self];
    [self.view addSubview:selectedTagsVC.view];
    
    CGRect settingsLocation = settingsView.frame;
    settingsLocation.origin.x = self.view.frame.size.width - settingsView.frame.size.width/2;
    settingsLocation.origin.y = -settingsView.frame.size.height/2;
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
    
    //Fixes missing status bar when cancelling picture pick from library
    if([UIApplication sharedApplication].statusBarHidden)
    {
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    }
    
    if(noteToAdd != nil){
#warning unimplemented
        //show new note
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

#pragma mark LocationsModel Update Methods

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

#pragma mark Selected Content Delegate Methods

- (void) didUpdateContentSelector
{
#warning not implemented
}

- (void) didUpdateSelectedTagList
{
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
        
        Note * note    = [[AppModel sharedAppModel] noteForNoteId:tmpLocation.objectId playerListYesGameListNo:NO];
        if(!note) note = [[AppModel sharedAppModel] noteForNoteId:tmpLocation.objectId playerListYesGameListNo:YES];
        
        BOOL match = NO;
        for(int j = 0; j < [selectedTagsVC.selectedTagList count]; ++j)
            if(((Tag *)[note.tags objectAtIndex:0]).tagId == ((Tag *)[selectedTagsVC.selectedTagList objectAtIndex:j]).tagId) match = YES;
        
        if(!match) continue;
        
        CLLocationCoordinate2D locationLatLong = tmpLocation.location.coordinate;
        
        Annotation *annotation = [[Annotation alloc]initWithCoordinate:locationLatLong];
        annotation.location = tmpLocation;
        annotation.title = tmpLocation.name;
        annotation.kind = tmpLocation.kind;
        annotation.iconMediaId = tmpLocation.iconMediaId;
        
        //UIImage *iconImage = [UIImage imageNamed:[NSString stringWithFormat:@"tag%d.png", ((Tag *)[note.tags objectAtIndex:0]).tagId]];
        NSLog(@"Make image named tag%d.png", ((Tag *)[note.tags objectAtIndex:0]).tagId);
        //annotation.icon = iconImage;
#warning FIX
        
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
    Note * note = ((MapNotePopUp *)((UIButton *)sender).superview).note;
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
    
    settingsView.layer.anchorPoint = CGPointMake(1, 0);
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
    
    settingsView.layer.anchorPoint = CGPointMake(1, 0);
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
        tableView.frame = contentFrame;
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
    tableView = nil;
    settingsView = nil;
    [super viewDidUnload];
}

@end