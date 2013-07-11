//
//  WildcardGestureRecognizer.h
//  YOI
//
//  Created by Jacob Hanshaw on 7/8/13.
//
//

#import <Foundation/Foundation.h>

typedef void (^TouchesEventBlock)(NSSet * touches, UIEvent * event);

@interface WildcardGestureRecognizer : UIGestureRecognizer
{
    TouchesEventBlock touchesBeganCallback;
}

@property(copy) TouchesEventBlock touchesBeganCallback;

@end