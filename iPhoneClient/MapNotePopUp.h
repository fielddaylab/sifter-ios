//
//  MapNotePopUp.h
//  YOI
//
//  Created by Jacob Hanshaw on 4/19/13.
//
//

#import <UIKit/UIKit.h>
#import "AsyncMediaImageView.h"
#import "Note.h"

@interface MapNotePopUp : UIView {
    __weak IBOutlet AsyncMediaImageView *imageView;
    __weak IBOutlet UILabel *textLabel;
    
    Note *note;
}

@property (weak, nonatomic) IBOutlet AsyncMediaImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *textLabel;

@property (nonatomic) Note *note;

- (id)initWithFrame:(CGRect)frame;
- (id)initWithFrame:(CGRect)frame Media:(Media *) media andText:(NSString*) text;

@end
