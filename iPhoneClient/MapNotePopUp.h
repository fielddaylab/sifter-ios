//
//  MapNotePopUp.h
//  YOI
//
//  Created by Jacob Hanshaw on 4/19/13.
//
//

#import <UIKit/UIKit.h>
#import "InnovDisplayProtocol.h"
#import "InnovPresentNoteProtocol.h"

@class Note, Media, AsyncMediaImageView;

@interface MapNotePopUp : UIView <InnovDisplayProtocol> {
    __weak IBOutlet AsyncMediaImageView *imageView;
    __weak IBOutlet UILabel *textLabel;
    
    Note *note;
    BOOL hiding;
}

@property (nonatomic)       Note *note;
@property (nonatomic, weak) id<InnovPresentNoteProtocol> delegate;

- (id)init;
- (id)initWithMedia:(Media *) media andText:(NSString*) text;

@end
