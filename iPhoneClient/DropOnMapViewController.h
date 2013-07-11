//
//  DropOnMapViewController.h
//  ARIS
//
//  Created by Brian Thiel on 9/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <MapKit/MapKit.h>

@interface DropOnMapViewController : UIViewController <MKMapViewDelegate>

@property (nonatomic) BOOL locationMoved;
@property (nonatomic) CLLocationCoordinate2D currentCoordinate;

- (id)initWithCoordinate: (CLLocationCoordinate2D) initialCoordinate;

@end