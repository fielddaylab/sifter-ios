//
//  InnovListViewController.h
//  YOI
//
//  Created by Jacob James Hanshaw on 5/23/13.
//
//

#import "InnovPresentNoteDelegate.h"

@interface InnovListViewController : UIViewController

@property (nonatomic, weak) id<InnovPresentNoteDelegate> delegate;

- (void) animateInNote:(Note *) newNote;

@end
