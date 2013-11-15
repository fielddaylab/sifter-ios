//
//  DeprecatedEnums.h
//  Siftr
//
//  Created by Jacob Hanshaw on 11/15/13.
//
//

#ifdef __IPHONE_6_0
#   define kLabelAlignmentCenter    NSTextAlignmentCenter
#   define kLabelAlignmentLeft      NSTextAlignmentLeft
#   define kLabelAlignmentRight     NSTextAlignmentRight
#   define kLabelTruncationTail     NSLineBreakByTruncatingTail
#   define kLabelTruncationMiddle   NSLineBreakByTruncatingMiddle
#else
#   define kLabelAlignmentCenter    UITextAlignmentCenter
#   define kLabelAlignmentLeft      UITextAlignmentLeft
#   define kLabelAlignmentRight     UITextAlignmentRight
#   define kLabelTruncationTail     UILineBreakModeTailTruncation
#   define kLabelTruncationMiddle   UILineBreakModeMiddleTruncation
#endif