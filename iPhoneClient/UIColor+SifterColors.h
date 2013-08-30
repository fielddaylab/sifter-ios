//
//  UIColor+SifterColors.h
//  Sifter
//
//  Created by David Gagnon on 6/24/13.
//
//

#import <UIKit/UIKit.h>

@interface UIColor (SifterColors)

/*+ (UIColor *) SifterColorScarlet;
+ (UIColor *) SifterColorDarkBlue;
+ (UIColor *) SifterColorLightBlue;
+ (UIColor *) SifterColorOrange; */
+ (UIColor *) SifterColorRed;
//+ (UIColor *) SifterColorYellow;
+ (UIColor *) SifterColorBlack;
+ (UIColor *) SifterColorLightGray;
//+ (UIColor *) SifterColorGray;
+ (UIColor *) SifterColorDarkGray;
+ (UIColor *) SifterColorWhite;
//+ (UIColor *) SifterColorOffWhite;

+ (UIColor *) SifterColorTranslucentBlack;
+ (UIColor *) SifterColorTranslucentWhite;

+ (UIColor *) SifterColorNavBarTint;
+ (UIColor *) SifterColorNavBarText;           
+ (UIColor *) SifterColorTabBarTint;
+ (UIColor *) SifterColorTabBarText;           
+ (UIColor *) SifterColorToolBarTint;
+ (UIColor *) SifterColorBarButtonTint;
+ (UIColor *) SifterColorSegmentedControlTint;
+ (UIColor *) SifterColorSearchBarTint;

+ (UIColor *) SifterColorContentBackdrop; //behind fullscreen content
+ (UIColor *) SifterColorNpcContentBackdrop; //behind npc media
+ (UIColor *) SifterColorTextBackdrop;    //behind large amounts of text
+ (UIColor *) SifterColorText;            //content text
+ (UIColor *) SifterColorViewBackdrop;    //behind navigation screens
+ (UIColor *) SifterColorViewText;        //labels on navigation screens

+ (NSString *) SifterHtmlTemplate;

@end
