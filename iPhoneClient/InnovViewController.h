//
//  InnovViewController.h
//  ARIS
//
//  Created by Jacob Hanshaw on 3/25/13.
//
//

#import <UIKit/UIKit.h>

@class Note, CLLocation;

@interface InnovViewController : UIViewController

@property (nonatomic) CLLocation *lastLocation;
@property (nonatomic) Note *noteToAdd;

@end
