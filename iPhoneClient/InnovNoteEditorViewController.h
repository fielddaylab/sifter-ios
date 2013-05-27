//
//  InnovNoteEditorViewController.h
//  ARIS
//
//  Created by Jacob Hanshaw on 4/5/13.
//
//

#import <UIKit/UIKit.h>


@protocol InnovNoteEditorViewDelegate

@optional
- (void) prepareToDisplayNote: (Note *) noteToAdd;
//- (void) shouldAlsoExit:(BOOL) shouldExit;
@end

typedef enum {
	kInnovAudioRecorderNoAudio,
	kInnovAudioRecorderRecording,
	kInnovAudioRecorderAudio,
	kInnovAudioRecorderPlaying
} InnovAudioRecorderModeType;

@class Note;

@interface InnovNoteEditorViewController : UIViewController

@property (nonatomic)                   Note *note;
@property (nonatomic, weak)             id<InnovNoteEditorViewDelegate> delegate;

@end
