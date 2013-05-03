//
//  InnovChildViewControllerProtocol.h
//  YOI
//
//  Created by Jacob James Hanshaw on 5/3/13.
//
//

#import <Foundation/Foundation.h>

@protocol InnovChildViewControllerProtocol <NSObject>

@required
- (void) show;
- (void) hide;

@optional
- (void) toggleDisplay;
- (void) update;

@end
