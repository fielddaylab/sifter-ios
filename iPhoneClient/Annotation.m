//
//  Annotation.m
//  ARIS
//
//  Created by Brian Deith on 7/21/09.
//  Copyright 2009 Brian Deith. All rights reserved.
//

#import "Annotation.h"


@implementation Annotation

@synthesize coordinate, title, subtitle, iconMediaId, kind, note, icon;

-(id)initWithCoordinate:(CLLocationCoordinate2D) c{
    self = [super init];
	if (self)
    {
		coordinate=c;
	}
	NSLog(@"Item annotation created");
	return self;
}


@end
