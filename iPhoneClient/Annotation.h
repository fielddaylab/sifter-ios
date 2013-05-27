//
//  Annotation.h
//  ARIS
//
//  Created by Brian Deith on 7/21/09.
//  Copyright 2009 Brian Deith. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "Media.h"
#import "NearbyObjectProtocol.h"
#import "Location.h"

@class Note;

@interface Annotation : NSObject <MKAnnotation> {
	CLLocationCoordinate2D coordinate;
	NSString *title;
	NSString *subtitle;
	int iconMediaId;
    UIImage *icon;
	nearbyObjectKind kind;
	Note *note;
    Location *location;
}

@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;
@property(readwrite, assign) int iconMediaId;
@property (nonatomic) UIImage *icon;
@property(readwrite, assign) nearbyObjectKind kind;
@property (nonatomic) Note *note;
@property (nonatomic) Location *location;

- (id)initWithCoordinate:(CLLocationCoordinate2D) coordinate;

@end
