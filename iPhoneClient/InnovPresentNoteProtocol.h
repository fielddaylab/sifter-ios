//
//  PresentNoteProtocol.h
//  YOI
//
//  Created by Jacob James Hanshaw on 5/22/13.
//
//

#import <Foundation/Foundation.h>

@class Note;

@protocol InnovPresentNoteProtocol <NSObject>

@required
-(void) presentNote: (Note *) note;

@end
