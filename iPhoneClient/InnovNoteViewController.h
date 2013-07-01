//
//  InnovNoteViewController.h
//  YOI
//
//  Created by Jacob James Hanshaw on 5/8/13.
//
//

@class Note;

@interface InnovNoteViewController : UIViewController 

@property (nonatomic)                    Note *note;
@property (nonatomic, weak) id delegate;

@end
