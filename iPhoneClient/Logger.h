//
//  Logger.h
//  ARIS
//
//  Created by Jacob Hanshaw on 3/15/13.
//
//

#define DEBUGMODE 0

@interface Logger : NSObject {
    
}

+ (Logger *)sharedLogger;
- (void)logDebug:(NSString *) string;
- (void)logError:(NSError *) error;
- (void)logNotification:(NSNotification *) notification;

@end
