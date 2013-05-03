//
//  InnovSelectedTagsViewController.h
//  YOI
//
//  Created by Jacob James Hanshaw on 5/3/13.
//
//

#import <UIKit/UIKit.h>
#import "InnovChildViewControllerProtocol.h"

@protocol InnovSelectedTagsDelegate

@required
- (void) didUpdateContentSelector;
- (void) didUpdateSelectedTagList;

@end

typedef enum {
	kTop,
    kPopular,
    kRecent
} ContentSelector;

@interface InnovSelectedTagsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, InnovChildViewControllerProtocol>
{
    
    __unsafe_unretained IBOutlet UISegmentedControl *contentSelectorSegCntrl;
    __unsafe_unretained IBOutlet UITableView *tagTableView;
    
    id<InnovSelectedTagsDelegate> delegate;
    
    BOOL hiding;
    NSMutableArray *tagList;
}

@property(nonatomic) ContentSelector selectedContent;
@property(nonatomic) NSMutableArray *selectedTagList;

- (IBAction)contentSelectorChangedValue:(UISegmentedControl *)sender;

@end
