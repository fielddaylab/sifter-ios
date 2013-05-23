//
//  InnovSelectedTagsViewController.h
//  YOI
//
//  Created by Jacob James Hanshaw on 5/3/13.
//
//

#import <UIKit/UIKit.h>
#import "InnovDisplayProtocol.h"

#import "Tag.h"

@protocol InnovSelectedTagsDelegate

@required
- (void) didUpdateContentSelector;
- (void) addTag:    (Tag *) tag;
- (void) removeTag: (Tag *) tag;
@end

typedef enum {
	kTop,
    kPopular,
    kRecent
} ContentSelector;

@interface InnovSelectedTagsViewController : UIViewController <InnovDisplayProtocol>

@property(nonatomic, weak) id<InnovSelectedTagsDelegate> delegate;

@end
