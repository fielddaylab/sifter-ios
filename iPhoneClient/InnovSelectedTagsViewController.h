//
//  InnovSelectedTagsViewController.h
//  YOI
//
//  Created by Jacob James Hanshaw on 5/3/13.
//
//

#import "InnovDisplayProtocol.h"

@interface InnovSelectedTagsViewController : UIViewController <InnovDisplayProtocol>

- (void)updateSelectedContent:(ContentSelector) selector;

@end