//
//  MapNotePopUp.h
//  YOI
//
//  Created by Jacob Hanshaw on 4/19/13.
//
//

#import <UIKit/UIKit.h>
#import "InnovDisplayProtocol.h"

@protocol InnovPresentNoteDelegate;

@class Note, Media;

@interface MapNotePopUp : UIView <InnovDisplayProtocol>

@property (nonatomic)       Note *note;
@property (nonatomic, weak) id<InnovPresentNoteDelegate> delegate;

- (id)init;
- (id)initWithMedia:(Media *) media andText:(NSString*) text;

@end
