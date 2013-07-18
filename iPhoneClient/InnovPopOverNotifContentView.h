//
//  InnovPopOverNotifContentView.h
//  YOI
//
//  Created by Jacob Hanshaw on 7/5/13.
//
//

#import "InnovPopOverContentView.h"

@interface InnovPopOverNotifContentView : InnovPopOverContentView

- (void) refreshFromModel;
- (IBAction)sliderValueChanged:(id)sender;
- (IBAction)saveButtonPressed:(id)sender;

@end