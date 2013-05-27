//
//  InnovSelectedTagsViewController.h
//  YOI
//
//  Created by Jacob James Hanshaw on 5/3/13.
//
//

#import <UIKit/UIKit.h>
#import "InnovDisplayProtocol.h"

@class Tag;

typedef enum {
	kTop,
    kPopular,
    kRecent
} ContentSelector;

@protocol InnovSelectedTagsDelegate <NSObject>
@required
- (void) updateContentSelector: (ContentSelector) selector;
- (void) addTag:    (Tag *) tag;
- (void) removeTag: (Tag *) tag;

@end

@interface InnovSelectedTagsViewController : UIViewController <InnovDisplayProtocol>

@property(nonatomic, weak) id<InnovSelectedTagsDelegate> delegate;

@end
