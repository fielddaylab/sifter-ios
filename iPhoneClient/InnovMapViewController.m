//
//  InnovMapViewController.m
//  YOI
//
//  Created by Jacob James Hanshaw on 5/22/13.
//
//

#import "InnovMapViewController.h"
#import <MapKit/MapKit.h>

#import "AppModel.h"
#import "InnovNoteModel.h"
#import "AppServices.h"
#import "Logger.h"
#import "Note.h"
#import "Tag.h"
#import "WildcardGestureRecognizer.h"

#import "Annotation.h"
#import "AnnotationView.h"
#import "InnovPresentNoteDelegate.h"
#import "InnovMapNotePopUp.h"

#warning update defined numbers

#define INITIAL_SPAN    0.025
#define ZOOM_SPAN       0.001

#define ANIMATION_TIME  0.5

#define MADISON_LAT     43.07
#define MADISON_LONG    -89.40
#define MAX_DISTANCE    20000

@interface InnovMapViewController () <MKMapViewDelegate, InnovPresentNoteDelegate>

{
    IBOutlet MKMapView *mapView;
    InnovMapNotePopUp *notePopUp;

    CLLocation *madisonCenter;
    
    int shownNotesCount;
    NSMutableArray *unshownNotesQueue;
}
@end

@implementation InnovMapViewController

@synthesize delegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        unshownNotesQueue    = [[NSMutableArray alloc] initWithCapacity:20];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addAnnotationsForNotes:)    name:@"NewlyAvailableNotesAvailable"             object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeAnnotationsForNotes:) name:@"NewlyUnavailableNotesAvailable"           object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshNotes)               name:@"NoteModelUpdate:Notes"                    object:nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    madisonCenter = [[CLLocation alloc] initWithLatitude:MADISON_LAT longitude:MADISON_LONG];
    
    [self zoomAndCenterMapAnimated:NO];
    
    notePopUp = [[InnovMapNotePopUp alloc] init];
    notePopUp.hidden   = YES;
    notePopUp.center   = self.view.center;
    notePopUp.delegate = self;
    
    NSString *reqSysVer = @"6.0";
    NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
    if ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedDescending)
    {        
        WildcardGestureRecognizer * tapInterceptor = [[WildcardGestureRecognizer alloc] init];
        __weak InnovMapViewController *weakSelf = self;
        tapInterceptor.touchesBeganCallback = ^(NSSet * touches, UIEvent * event) {
            [weakSelf touchesBegan:nil withEvent:nil];
            [[weakSelf.navigationController.viewControllers objectAtIndex:0] touchesBegan:nil withEvent:nil];
        };
        [mapView addGestureRecognizer:tapInterceptor];
    }
    
    [mapView setShowsUserLocation:NO];
}

- (void)viewDidAppear:(BOOL)animated
{
#warning neccessary?
    //   if     ([[AppModel sharedAppModel].currentGame.mapType isEqualToString:@"SATELLITE"]) mapView.mapType = MKMapTypeSatellite;
    //   else if([[AppModel sharedAppModel].currentGame.mapType isEqualToString:@"HYBRID"])    mapView.mapType = MKMapTypeHybrid;
    //   else                                                                                  mapView.mapType = MKMapTypeStandard;
    [[[MyCLController sharedMyCLController] locationManager] stopUpdatingLocation];
	[[[MyCLController sharedMyCLController] locationManager] startUpdatingLocation];
    
  /*  UIView *legalView = nil;
    for (UIView *subview in mapView.subviews) {
        if ([subview isKindOfClass:[UILabel class]]) {
            legalView = subview;
        }
    }
    legalView.frame = CGRectMake(legalView.frame.origin.x, self.view.frame.size.height - 64, legalView.frame.size.width, legalView.frame.size.height); */
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

- (void) zoomAndCenterMapAnimated: (BOOL) animated
{
    MKCoordinateRegion region = mapView.region;
    region.center = madisonCenter.coordinate;
    region.span = MKCoordinateSpanMake(INITIAL_SPAN, INITIAL_SPAN);
    [mapView setRegion:region animated:animated];
}

#pragma mark update from model

- (void) refreshNotes
{
    for(Annotation *annotation in mapView.annotations)
    {
        if((id <MKAnnotation>)annotation == mapView.userLocation || !([annotation respondsToSelector:@selector(title)]))
            continue;
        Note *note = [[InnovNoteModel sharedNoteModel] noteForNoteId:annotation.note.noteId];
        CLLocationCoordinate2D oldCoord = annotation.coordinate;
        annotation.coordinate = CLLocationCoordinate2DMake(note.latitude, note.longitude);
        annotation.title = note.text;
        annotation.kind = NearbyObjectNote;
        annotation.iconMediaId = ((Tag *)[note.tags objectAtIndex:0]).mediaId;
        if(oldCoord.latitude != annotation.coordinate.latitude || oldCoord.longitude != annotation.coordinate.longitude)
        {
            [mapView removeAnnotation:annotation];
            [mapView addAnnotation:annotation];
        }
    }
}

- (void) addAnnotationsForNotes:(NSNotification *)notification
{
    for(Note *note in unshownNotesQueue)
    {
        if(shownNotesCount < MAX_MAP_NOTES_COUNT)
        {
            CLLocationCoordinate2D locationLatLong = CLLocationCoordinate2DMake(note.latitude, note.longitude);
            Annotation *annotation = [[Annotation alloc]initWithCoordinate:locationLatLong];
            annotation.note = note;
            annotation.title = note.text;
            annotation.kind = NearbyObjectNote;
            annotation.iconMediaId = ((Tag *)[note.tags objectAtIndex:0]).mediaId;
            ++shownNotesCount;
            [mapView addAnnotation:annotation];
        }
        else break;
    }
    
    NSArray *newNotes = (NSArray *)[notification.userInfo objectForKey:@"newlyAvailableNotes"];
    
    for(Note *note in newNotes)
    {
        if(shownNotesCount < MAX_MAP_NOTES_COUNT)
        {
            CLLocationCoordinate2D locationLatLong = CLLocationCoordinate2DMake(note.latitude, note.longitude);
            Annotation *annotation = [[Annotation alloc]initWithCoordinate:locationLatLong];
            annotation.note = note;
            annotation.title = note.text;
            annotation.kind = NearbyObjectNote;
            annotation.iconMediaId = ((Tag *)[note.tags objectAtIndex:0]).mediaId;
            ++shownNotesCount;
            [mapView addAnnotation:annotation];
        }
        else
        {
            [unshownNotesQueue addObject:note];
        }
    }
}

- (void) removeAnnotationsForNotes:(NSNotification *)notification
{
    NSArray *removeNotes = (NSArray *)[notification.userInfo objectForKey:@"newlyUnavailableNotes"];
    
    for(Note *note in removeNotes)
    {
        BOOL found = NO;
        NSObject<MKAnnotation> *tmpMKAnnotation;
        Annotation *tmpAnnotation;
        for (int i = 0; i < [[mapView annotations] count]; i++)
        {
            if(notePopUp.note.noteId == note.noteId)
                [notePopUp hide];
            
            if((tmpMKAnnotation = [[mapView annotations] objectAtIndex:i]) == mapView.userLocation ||
               !((tmpAnnotation = (Annotation*)tmpMKAnnotation) && [tmpAnnotation respondsToSelector:@selector(title)])) continue;
            
            if([tmpAnnotation.note compareTo:note])
            {
                found = YES;
                --shownNotesCount;
                [mapView removeAnnotation:tmpAnnotation];
                break;
            }
        }
        if(!found) [unshownNotesQueue removeObject:note];
    }
}

#pragma mark MKMapViewDelegate

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
	Note *note = ((Annotation*)view.annotation).note;
    [self showNotePopUpForNote:note];
}

#pragma mark Present Pop Up

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    
    [notePopUp hide];
    Annotation *currentAnnotation = [mapView.selectedAnnotations lastObject];
    [mapView deselectAnnotation:currentAnnotation animated:YES];
}

- (void) showNotePopUpForNote: (Note *) note
{
    //Note: will always be hidden by touches began except when re-displayed from editor
    if(!notePopUp.hidden) [notePopUp hide];
    
    MKCoordinateRegion region = mapView.region;
    region.center = CLLocationCoordinate2DMake(note.latitude, note.longitude);
    [mapView setRegion:region animated:YES];
    
    notePopUp.note = note;
    notePopUp.center = mapView.center;
    [self.view addSubview:notePopUp];
    [notePopUp show];
}

- (void) presentNote:(Note *)note
{
    [delegate presentNote:note];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end