//
//  InnovViewController.h
//  ARIS
//
//  Created by Jacob Hanshaw on 3/25/13.
//
//
@class Note;
@interface InnovViewController : UIViewController
- (void) presentNote:(Note *) note;
- (void) animateInNote: (Note *) note;
@end