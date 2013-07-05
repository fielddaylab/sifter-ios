//
//  InnovPopOverNotifContentView.h
//  YOI
//
//  Created by Jacob Hanshaw on 7/5/13.
//
//

@protocol InnovPopOverNotifContentViewDelegate <NSObject>
@required
- (void) dismiss;
@end

@interface InnovPopOverNotifContentView : UIView

@property(nonatomic) id<InnovPopOverNotifContentViewDelegate> delegate;

- (void) refreshFromModel;
- (IBAction)sliderValueChanged:(id)sender;
- (IBAction)saveButtonPressed:(id)sender;

@end