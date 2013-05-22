//
//  MapNotePopUp.h
//  YOI
//
//  Created by Jacob Hanshaw on 4/19/13.
//
//

#import <UIKit/UIKit.h>

@class Note, Media, AsyncMediaImageView;

@interface MapNotePopUp : UIView {
    __weak IBOutlet AsyncMediaImageView *imageView;
    __weak IBOutlet UILabel *textLabel;
    
    Note *note;
}

@property (weak, nonatomic) IBOutlet AsyncMediaImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *textLabel;

@property (nonatomic) Note *note;

- (id)init;
- (id)initWithMedia:(Media *) media andText:(NSString*) text;

@end
