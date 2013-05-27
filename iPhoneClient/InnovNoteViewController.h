//
//  InnovNoteViewController.h
//  YOI
//
//  Created by Jacob James Hanshaw on 5/8/13.
//
//

#import <UIKit/UIKit.h>

@class Note;

@interface InnovNoteViewController : UIViewController 

@property (nonatomic)                    Note *note;
@property (nonatomic, unsafe_unretained) id delegate;

@end
