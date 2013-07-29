//
//  InnovMapViewController.h
//  YOI
//
//  Created by Jacob James Hanshaw on 5/22/13.
//
//

@protocol InnovPresentNoteDelegate;

@protocol InnovMapViewDelegate <NSObject>
@required
-(void) stoppedTracking;
@end

@class Note;

@interface InnovMapViewController : UIViewController

@property(nonatomic, weak) id<InnovMapViewDelegate, InnovPresentNoteDelegate> delegate;

- (BOOL) toggleTracking;
- (void) updatePlayerLocation;
- (void) zoomAndCenterMapAnimated:(BOOL) animated;
- (void) showNotePopUpForNote: (Note *) note;

@end