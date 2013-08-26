//
//  InnovMapViewController.h
//  YOI
//
//  Created by Jacob James Hanshaw on 5/22/13.
//
//

@protocol InnovPresentNoteDelegate;

@class Note;

@interface InnovMapViewController : UIViewController

@property(nonatomic, weak) id<InnovPresentNoteDelegate> delegate;

- (void) showNotePopUpForNote: (Note *) note;
- (void) zoomAndCenterMapAnimated: (BOOL) animated;

@end