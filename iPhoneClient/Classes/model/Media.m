//
//  Media.m
//  ARIS
//
//  Created by Kevin Harris on 9/25/09.
//  Copyright 2009 University of Wisconsin - Madison. All rights reserved.
//

#import "Media.h"
#import "AppModel.h"

NSString *const kMediaTypeVideo = @"Video";
NSString *const kMediaTypeImage = @"Image";
NSString *const kMediaTypeAudio = @"Audio";

@implementation Media
@dynamic gameid, uid, url, type, image;
@end