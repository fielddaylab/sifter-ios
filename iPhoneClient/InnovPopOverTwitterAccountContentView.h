//
//  InnovPopOverTwitterAccountContentView.h
//  YOI
//
//  Created by Jacob Hanshaw on 7/17/13.
//
//

#import "InnovPopOverContentView.h"

@protocol InnovPopOverTwitterAccountContentViewDelegate <NSObject>
@required
- (void) setAvailableTwitterAccounts:(NSArray *) twitterAccounts;
@end

@interface InnovPopOverTwitterAccountContentView : InnovPopOverContentView <UITableViewDataSource, UITabBarDelegate>

@property(nonatomic) id<InnovPopOverTwitterAccountContentViewDelegate> delegate;

- (void) setInitialTwitterAccounts:(NSArray *) twitterAccounts;
- (IBAction)okButtonPressed:(id)sender;

@end