//
//  InnovMapViewController.m
//  YOI
//
//  Created by Jacob James Hanshaw on 5/22/13.
//
//

#import "InnovMapViewController.h"

#import "AppServices.h"
#import "Logger.h"
#import "Note.h"

#import "Annotation.h"
#import "AnnotationView.h"
#import "MapNotePopUp.h"

#warning update defined numbers

#define INITIAL_SPAN 0.025
#define ZOOM_SPAN    0.001

#define ANIMATION_TIME     0.5

#define MADISON_LAT  43.07
#define MADISON_LONG -89.41
#define MAX_DISTANCE 20000

@implementation InnovMapViewController

@synthesize delegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        tracking = NO;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePlayerLocation) name:@"PlayerMoved" object:nil];
#warning need to listen for new notes messages
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    madisonCenter = [[CLLocation alloc] initWithLatitude:MADISON_LAT longitude:MADISON_LONG];
    
    //Center on Madison
	isLocal = NO;
    [self zoomAndCenterMapAnimated:NO];
    
    notePopUp = [[MapNotePopUp alloc] init];
    notePopUp.hidden   = YES;
    notePopUp.center   = self.view.center;
    notePopUp.delegate = self;
}

- (void)viewDidAppear:(BOOL)animated
{
#warning neccessary?
    //  [self playerMoved];
    [[AppServices sharedAppServices] updateServerMapViewed];
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

#pragma mark user location

- (void) toggleTracking
{
    [[[MyCLController sharedMyCLController] locationManager] stopUpdatingLocation];
	[[[MyCLController sharedMyCLController] locationManager] startUpdatingLocation];
    
    tracking = !tracking;
    [self updatePlayerLocation];
}

- (void) updatePlayerLocation
{
    CLLocationDistance distance = [[AppModel sharedAppModel].playerLocation distanceFromLocation:madisonCenter];
    isLocal = distance <= MAX_DISTANCE;
    [mapView setShowsUserLocation:isLocal];
    if (mapView && tracking) [self zoomAndCenterMapAnimated:YES];
}

- (void) zoomAndCenterMapAnimated: (BOOL) animated
{
    appSetNextRegionChange = YES;
    
    MKCoordinateRegion region = mapView.region;
    if(isLocal)
    {
        region.center = [AppModel sharedAppModel].playerLocation.coordinate;
        region.span = MKCoordinateSpanMake(ZOOM_SPAN, ZOOM_SPAN);
        
    }
    else
    {
        region.center = madisonCenter.coordinate;
        region.span = MKCoordinateSpanMake(INITIAL_SPAN, INITIAL_SPAN);
        
    }
    [mapView setRegion:region animated:animated];
}

#pragma mark update from model

- (void) addAnnotationOfNote: (Note *) note
{
    CLLocationCoordinate2D locationLatLong = CLLocationCoordinate2DMake(note.latitude, note.longitude);
    Annotation *annotation = [[Annotation alloc]initWithCoordinate:locationLatLong];
    annotation.location = note.location;
    annotation.title = note.title;
    annotation.kind = NearbyObjectNote;
    annotation.iconMediaId = -((Tag *)[note.tags objectAtIndex:0]).tagId;
#warning this needs to be implemented in AnnotationView.m
    
    [mapView addAnnotation:annotation];
}

#pragma mark MKMapViewDelegate
- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated
{
	if (!appSetNextRegionChange) tracking = NO;
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
- (void)mapView:(MKMapView *)aMapView didSelectAnnotationView:(MKAnnotationView *)view
{
    if(view.annotation == aMapView.userLocation) return;
	Location *location = ((Annotation*)view.annotation).location;
    [self showNotePopUpForLocation:location];
}

#pragma mark Present Pop Up

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [notePopUp hide];
}

- (void) showNotePopUpForLocation: (Location *) location
{
    Note * note    = [[AppModel sharedAppModel] noteForNoteId:location.objectId playerListYesGameListNo:NO];
    if(!note) note = [[AppModel sharedAppModel] noteForNoteId:location.objectId playerListYesGameListNo:YES];
    if(note){
        //Note: will always be hidden by touches began
        
        MKCoordinateRegion region = mapView.region;
        region.center = CLLocationCoordinate2DMake(note.latitude, note.longitude);
        [mapView setRegion:region animated:YES];
        
        Annotation *currentAnnotation = [mapView.selectedAnnotations lastObject];
        [mapView deselectAnnotation:currentAnnotation animated:YES];
        
        notePopUp.note = note;
        [self.view addSubview:notePopUp];
        [notePopUp show];
    }
    else{
        [[Logger sharedLogger] logDebug:@"Attempted to show nil note"];
        Annotation *currentAnnotation = [mapView.selectedAnnotations lastObject];
        [mapView deselectAnnotation:currentAnnotation animated:YES];
        return;
    }
    
}

- (void) presentNote:(Note *)note
{
    [delegate presentNote:note];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end