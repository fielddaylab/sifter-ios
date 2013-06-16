//
//  InnovNoteViewController.h
//  YOI
//
//  Created by Jacob James Hanshaw on 5/8/13.
//
//

@protocol InnovNoteViewDelegate <NSObject>
@required
- (void)presentLogIn;
@end

@class Note;

@interface InnovNoteViewController : UIViewController 

@property (nonatomic)                    Note *note;
@property (nonatomic, weak) id<InnovNoteViewDelegate> delegate;

@end
