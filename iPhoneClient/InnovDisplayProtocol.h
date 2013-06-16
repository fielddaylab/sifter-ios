//
//  InnovDisplayProtocol.h
//  YOI
//
//  Created by Jacob James Hanshaw on 5/3/13.
//
//

@protocol InnovDisplayProtocol <NSObject>

@required
- (void) show;
- (void) hide;

@optional
- (void) toggleDisplay;
- (void) update;

@end
