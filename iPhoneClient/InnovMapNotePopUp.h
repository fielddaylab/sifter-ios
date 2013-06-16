//
//  MapNotePopUp.h
//  YOI
//
//  Created by Jacob Hanshaw on 4/19/13.
//
//

#import "InnovDisplayProtocol.h"

@protocol InnovPresentNoteDelegate;

@class Note, Media;

@interface InnovMapNotePopUp : UIView <InnovDisplayProtocol>

@property (nonatomic)       Note *note;
@property (nonatomic, weak) id<InnovPresentNoteDelegate> delegate;

- (id)init;

@end
