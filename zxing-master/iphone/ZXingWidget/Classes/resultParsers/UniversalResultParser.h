//
//  UniversalResultParser.h
//  ZXingWidget
//
//  Created by Romain Pechayre on 11/14/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ResultParser.h"

@interface UniversalResultParser : ResultParser { }

+ (void)initWithDefaultParsers;
+ (ParsedResult *)parsedResultForString:(NSString *)s
                                 format:(BarcodeFormat)format;
@end