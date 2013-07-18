//
//  InnovPopOverView.h
//  YOI
//
//  Created by JacobJamesHanshaw on 6/19/13.
//
//

#define NAV_BAR_HEIGHT 44

@class InnovPopOverContentView;

@protocol InnovPopOverViewDelegate <NSObject>
@required
- (void) popOverCancelled;
@end

@interface InnovPopOverView : UIView

@property(nonatomic, weak) id<InnovPopOverViewDelegate> delegate;

- (id)initWithFrame:(CGRect)frame andContentView: (InnovPopOverContentView *) inputContentView;
- (void)adjustContentFrame:(CGRect)frame;

@end