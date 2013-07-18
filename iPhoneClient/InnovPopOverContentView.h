//
//  InnovPopOverContentView.h
//  YOI
//
//  Created by Jacob Hanshaw on 7/17/13.
//
//

@protocol InnovPopOverContentViewDelegate <NSObject>
@required
- (void) dismiss;
@end

@interface InnovPopOverContentView : UIView

@property(nonatomic, weak) id<InnovPopOverContentViewDelegate> dismissDelegate;

@end