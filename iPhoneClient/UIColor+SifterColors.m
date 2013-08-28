//
//  UIImage+SifterColors.m
//  Sifter
//
//  Created by David Gagnon on 6/24/13.
//
//

#import "UIColor+SifterColors.h"

@implementation UIColor (SifterColors)

+ (UIColor *) SifterColorScarlet   { return [UIColor colorWithRed:(207.0/255.0) green:( 47.0/255.0)  blue:( 40.0/255.0) alpha:1.0]; }
+ (UIColor *) SifterColorDarkBlue  { return [UIColor colorWithRed:(  0.0/255.0) green:(101.0/255.0)  blue:(149.0/255.0) alpha:1.0]; }
+ (UIColor *) SifterColorLightBlue { return [UIColor colorWithRed:(132.0/255.0) green:(153.0/255.0)  blue:(165.0/255.0) alpha:1.0]; }
+ (UIColor *) SifterColorOrange    { return [UIColor colorWithRed:(249.0/255.0) green:( 99.0/255.0)  blue:(  2.0/255.0) alpha:1.0]; }
+ (UIColor *) SifterColorRed       { return [UIColor colorWithRed:(200.0/255.0) green:( 32.0/255.0)  blue:( 51.0/255.0) alpha:1.0]; }
+ (UIColor *) SifterColorYellow    { return [UIColor colorWithRed:(216.0/255.0) green:(181.0/255.0)  blue:( 17.0/255.0) alpha:1.0]; }
+ (UIColor *) SifterColorBlack     { return [UIColor colorWithRed:( 16.0/255.0) green:(  8.0/255.0)  blue:(  2.0/255.0) alpha:1.0]; }
+ (UIColor *) SifterColorLightGray { return [UIColor colorWithRed:(203.0/255.0) green:(201.0/255.0)  blue:(192.0/255.0) alpha:1.0]; }
+ (UIColor *) SifterColorGray      { return [UIColor colorWithRed:(150.0/255.0) green:(150.0/255.0)  blue:(150.0/255.0) alpha:1.0]; }
+ (UIColor *) SifterColorDarkGray  { return [UIColor colorWithRed:( 77.0/255.0) green:( 77.0/255.0)  blue:( 77.0/255.0) alpha:1.0]; }
+ (UIColor *) SifterColorWhite     { return [UIColor colorWithRed:(255.0/255.0) green:(255.0/255.0)  blue:(255.0/255.0) alpha:1.0]; }
+ (UIColor *) SifterColorOffWhite  { return [UIColor colorWithRed:(228.0/255.0) green:(229.0/255.0)  blue:(230.0/255.0) alpha:1.0]; }
+ (UIColor *) SifterColorTranslucentBlack { return [UIColor colorWithRed:( 16.0/255.0) green:(  8.0/255.0) blue:(  2.0/255.0) alpha:0.8]; }
+ (UIColor *) SifterColorTranslucentWhite { return [UIColor colorWithRed:(255.0/255.0) green:(255.0/255.0) blue:(255.0/255.0) alpha:0.1]; }

// Should put following in own class SifterTemplate or something
+ (UIColor *) SifterColorNavBarTint           { return [UIColor whiteColor]; }
+ (UIColor *) SifterColorNavBarText           { return [UIColor SifterColorBlack]; }
+ (UIColor *) SifterColorTabBarTint           { return [UIColor SifterColorWhite]; }
+ (UIColor *) SifterColorTabBarText           { return [UIColor SifterColorBlack]; }
+ (UIColor *) SifterColorToolBarTint          { return [UIColor SifterColorWhite]; }
+ (UIColor *) SifterColorBarButtonTint        { return [UIColor SifterColorLightGray]; }
+ (UIColor *) SifterColorSegmentedControlTint { return [UIColor SifterColorRed]; }
+ (UIColor *) SifterColorSearchBarTint        { return [UIColor SifterColorWhite]; }

+ (UIColor *) SifterColorTextBackdrop       { return [UIColor SifterColorTranslucentWhite]; }
+ (UIColor *) SifterColorText               { return [UIColor SifterColorBlack]; }
+ (UIColor *) SifterColorContentBackdrop    { return [UIColor SifterColorWhite]; }
+ (UIColor *) SifterColorNpcContentBackdrop { return [UIColor blackColor]; }
+ (UIColor *) SifterColorViewBackdrop       { return [UIColor SifterColorWhite]; }
+ (UIColor *) SifterColorViewText           { return [UIColor SifterColorBlack]; }

+ (NSString *) SifterHtmlTemplate
{
    return 
    @"<html>"
    @"<head>"
    @"	<style type='text/css'><!--"
    @"  html { margin:0; padding:0; }"
    @"	body {"
    @"      color:#000000;"
    @"		font-size:14px;"
    @"      font-family:HelveticaNeue-Light;"
    @"      margin:0;"
    @"      padding:10;"
    @"	}"
    @"	a { color: #FFFFFF; text-decoration: underline; }"
    @"	--></style>"
    @"</head>"
    @"<body>%@</body>"
    @"</html>";
}

@end
