//
//  InnovListViewController.h
//  YOI
//
//  Created by Jacob James Hanshaw on 5/23/13.
//
//

#import <UIKit/UIKit.h>

#import "InnovPresentNoteDelegate.h"

@protocol InnovListViewDelegate <NSObject>
@required
-(void) fetchMoreNotes;
@end

@interface InnovListViewController : UIViewController

@property (nonatomic, weak) id<InnovListViewDelegate, InnovPresentNoteDelegate> delegate;

@end
