/*
 
 File: MyCLController.m
 Abstract: Singleton class used to talk to CoreLocation and send results back to
 the app's view controllers.
 
 Version: 1.1
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple Inc.
 ("Apple") in consideration of your agreement to the following terms, and your
 use, installation, modification or redistribution of this Apple software
 constitutes acceptance of these terms.  If you do not agree with these terms,
 please do not use, install, modify or redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and subject
 to these terms, Apple grants you a personal, non-exclusive license, under
 Apple's copyrights in this original Apple software (the "Apple Software"), to
 use, reproduce, modify and redistribute the Apple Software, with or without
 modifications, in source and/or binary forms; provided that if you redistribute
 the Apple Software in its entirety and without modifications, you must retain
 this notice and the following text and disclaimers in all such redistributions
 of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may be used
 to endorse or promote products derived from the Apple Software without specific
 prior written permission from Apple.  Except as expressly stated in this notice,
 no other rights or licenses, express or implied, are granted by Apple herein,
 including but not limited to any patent rights that may be infringed by your
 derivative works or by other works in which the Apple Software may be
 incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
 WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
 WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
 COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
 GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR
 DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY OF
 CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN IF
 APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2008 Apple Inc. All Rights Reserved.
 
 */
#import "MyCLController.h"

#import "AppModel.h"
#import "InnovNoteModel.h"
#import "Note.h"
#import "Tag.h"

// Shorthand for getting localized strings, used in formats below for readability
#define LocStr(key) [[NSBundle mainBundle] localizedStringForKey:(key) value:@"" table:nil]


@implementation MyCLController

@synthesize locationManager;


+ (id)sharedMyCLController
{
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] init]; // or some other init method
    });
    return _sharedObject;
}


- (MyCLController*) init{
	self = [super init];
	if (self != nil) {
        CLLocationManager *locationManagerAlloc = [[CLLocationManager alloc] init];
		self.locationManager = locationManagerAlloc;
		self.locationManager.delegate = self; // Tells the location manager to send updates to this object
		self.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
		self.locationManager.distanceFilter = 5; //Minimum change of 5 meters for update
	}
	return self;
    
}


// Called when the location is updated
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    [AppModel sharedAppModel].playerLocation = newLocation;
}

// Called when there is an error getting the location
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
	NSMutableString *errorString = [[NSMutableString alloc] init];
	
	if ([error domain] == kCLErrorDomain) {
		
		// We handle CoreLocation-related errors here
        if ([error code]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"NoLocationTitleKey", nil) message:NSLocalizedString(@"NoLocationMessageKey", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"OkKey", @"") otherButtonTitles: nil];
            [alert show];
        }
		switch ([error code]) {
                // This error code is usually returned whenever user taps "Don't Allow" in response to
                // being told your app wants to access the current location. Once this happens, you cannot
                // attempt to get the location again until the app has quit and relaunched.
                //
                // "Don't Allow" on two successive app launches is the same as saying "never allow". The user
                // can reset this for all apps by going to Settings > General > Reset > Reset Location Warnings.
                //
			case kCLErrorDenied:{
                [errorString appendFormat:@"%@\n", NSLocalizedString(@"LocationDenied", nil)];
            }
                break;
				
                // This error code is usually returned whenever the device has no data or WiFi connectivity,
                // or when the location cannot be determined for some other reason.
                //
                // CoreLocation will keep trying, so you can keep waiting, or prompt the user.
                //
                
			case kCLErrorLocationUnknown:{
                [errorString appendFormat:@"%@\n", NSLocalizedString(@"LocationUnknown", nil)];
            }
                break;
				
				// We shouldn't ever get an unknown error code, but just in case...
				//}
			default:{
                [errorString appendFormat:@"%@ %d\n", NSLocalizedString(@"GenericLocationError", nil), [error code]];
            }
				
                break;
		}
	} else {
		// We handle all non-CoreLocation errors here
		// (we depend on localizedDescription for localization)
		[errorString appendFormat:@"Error domain: \"%@\"  Error code: %d\n", [error domain], [error code]];
		[errorString appendFormat:@"Description: \"%@\"\n", [error localizedDescription]];
	}
	
	//Send the update somewhere?
}

- (void)prepareNotificationsForNotes:(NSArray *) notes
{
    // Do not create regions if support is unavailable or disabled && Check the authorization status
    if ([CLLocationManager regionMonitoringAvailable] && (([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized) ||
                                                          ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined)))
    {
        // Clear out any old regions to prevent buildup.
        if ([self.locationManager.monitoredRegions count] > 0) {
            for (id obj in self.locationManager.monitoredRegions)
                [self.locationManager stopMonitoringForRegion:obj];
        }
        
        // If the overlay's radius is too large, registration fails automatically,
        // so clamp the radius to the max value.
        /*CLLocationDegrees radius = overlay.radius;
         if (radius > self.locManager.maximumRegionMonitoringDistance) {
         radius = self.locManager.maximumRegionMonitoringDistance;
         }*/
        
        // Create the region to be monitored.
        for(Note *note in notes)
        {
            CLRegion* region = [[CLRegion alloc] initCircularRegionWithCenter:CLLocationCoordinate2DMake(note.latitude, note.longitude)
                                                                       radius:kCLLocationAccuracyHundredMeters identifier:[NSString stringWithFormat:@"%d", note.noteId]];
            [self.locationManager startMonitoringForRegion:region];
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    // If the user's current location is not within the region anymore, stop updating
    if ([region containsCoordinate:[AppModel sharedAppModel].playerLocation.coordinate])
    {
        Note *note = [[InnovNoteModel sharedNoteModel] noteForNoteId:[region.identifier intValue]];
        NSString *tagName = ((Tag *)[note.tags objectAtIndex:0]).tagName;
        
        UILocalNotification *localNotification = [[UILocalNotification alloc] init];
        localNotification.alertBody = [NSString stringWithFormat:@"There is a note nearby about %@ that you may be interested in viewing.", tagName];
        localNotification.alertAction = nil;
        localNotification.hasAction = YES;
        localNotification.userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:note.noteId] forKey:@"noteId"];
        [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
    }
    //[self.locationManager startUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    //[self.locationManager stopUpdatingLocation];
}

@end