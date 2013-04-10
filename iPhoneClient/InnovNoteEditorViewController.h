//
//  InnovNoteEditorViewController.h
//  ARIS
//
//  Created by Jacob Hanshaw on 4/5/13.
//
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

#import "AsyncMediaImageView.h"
#import "Note.h"

@interface InnovNoteEditorViewController : UIViewController <AVAudioSessionDelegate, UITextViewDelegate, UITableViewDataSource, UITableViewDelegate, AVAudioPlayerDelegate, UIActionSheetDelegate> {
    
    __weak IBOutlet AsyncMediaImageView *imageView;
    __weak IBOutlet UITextView *captionTextView;
    __weak IBOutlet UIButton *recordButton;
    __weak IBOutlet UIButton *deleteAudioButton;
    __weak IBOutlet UITableView *tagTableView;

    Note *note;
    id __unsafe_unretained delegate;
    BOOL isEditable;
    
    BOOL cancelled;
    NSMutableArray *gameTagList;
}

@property (nonatomic)                    Note *note;
@property (nonatomic, unsafe_unretained) id delegate;
@property (readwrite)                    BOOL isEditable;

- (IBAction)recordButtonPressed:(id)sender;
- (IBAction)deleteAudioButtonPressed:(id)sender;

@end
