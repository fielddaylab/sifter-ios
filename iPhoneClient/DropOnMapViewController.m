//
//  DropOnMapViewController.m
//  ARIS
//
//  Created by Brian Thiel on 9/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "DropOnMapViewController.h"

#import "AppServices.h"
#import "ARISAppDelegate.h"
#import "DDAnnotation.h"
#import "DDAnnotationView.h"
#import "AnnotationView.h"

#define INITIAL_SPAN 0.001

@interface DropOnMapViewController()
{
    __weak IBOutlet MKMapView *mapView;
}
@end

@implementation DropOnMapViewController

@synthesize locationMoved, currentCoordinate;

- (id)initWithCoordinate: (CLLocationCoordinate2D) initialCoordinate
{
    self = [super init];
    if (self)
        currentCoordinate = initialCoordinate;
    return self;
}

#pragma mark - View lifecycle

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    DDAnnotation *annotation = [[DDAnnotation alloc] initWithCoordinate:currentCoordinate addressDictionary:nil];
	annotation.title    = @"Drag to Move Note";
	annotation.subtitle = [NSString stringWithFormat:@"%f %f", annotation.coordinate.latitude, annotation.coordinate.longitude];
	[mapView addAnnotation:annotation];
    
    [self zoomAndCenterMap];
}

-(void) zoomAndCenterMap
{
	MKCoordinateRegion region = mapView.region;
	region.center = currentCoordinate;
	region.span = MKCoordinateSpanMake(INITIAL_SPAN, INITIAL_SPAN);
    
	[mapView setRegion:region animated:NO];
}

#pragma mark MKMapViewDelegate

- (void)mapView:(MKMapView *)aMapView annotationView:(MKAnnotationView *)annotationView didChangeDragState:(MKAnnotationViewDragState)newState fromOldState:(MKAnnotationViewDragState)oldState
{
	if (oldState == MKAnnotationViewDragStateDragging)
    {
		DDAnnotation *annotation = (DDAnnotation *)annotationView.annotation;
		annotation.subtitle = [NSString	stringWithFormat:@"%f %f", annotation.coordinate.latitude, annotation.coordinate.longitude];
        locationMoved = YES;
	}
}

- (MKAnnotationView *)mapView:(MKMapView *)aMapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[MKUserLocation class]])
        return nil;
	
	static NSString * const kPinAnnotationIdentifier = @"PinIdentifier";
	MKAnnotationView *draggablePinView = [aMapView dequeueReusableAnnotationViewWithIdentifier:kPinAnnotationIdentifier];
	
	if (draggablePinView)
		draggablePinView.annotation = annotation;
    else
		draggablePinView = [DDAnnotationView annotationViewWithAnnotation:annotation reuseIdentifier:kPinAnnotationIdentifier mapView:aMapView];
    
	return draggablePinView;
}

- (void)mapView:(MKMapView *)mv didAddAnnotationViews:(NSArray *)views
{
	MKAnnotationView *annotationView = [views objectAtIndex:0];
	id <MKAnnotation> mp = [annotationView annotation];
    if([mp isKindOfClass:[DDAnnotation class]])
    {
        MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance([mp coordinate], 1500, 1500);
        [mv setRegion:region animated:YES];
        [mv selectAnnotation:mp animated:YES];
    }
}

@end