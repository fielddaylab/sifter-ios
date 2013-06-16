//
//  PresentNoteDelegate.h
//  YOI
//
//  Created by Jacob James Hanshaw on 5/22/13.
//
//

@class Note;

@protocol InnovPresentNoteDelegate <NSObject>

@required
-(void) presentNote: (Note *) note;

@end
