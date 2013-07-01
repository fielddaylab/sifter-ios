//
//  Note.h
//  ARIS
//
//  Created by Brian Thiel on 8/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NearbyObjectProtocol.h"

extern NSString *const kNoteContentTypeAudio;
extern NSString *const kNoteContentTypeVideo;
extern NSString *const kNoteContentTypePhoto;
extern NSString *const kNoteContentTypeText;

@interface Note : NSObject <NearbyObjectProtocol>

@property(readwrite,assign)  int noteId;
@property(readwrite, assign) int creatorId;
@property(nonatomic, strong) NSString *title;
@property(nonatomic, strong) NSString *username;
@property(nonatomic, strong) NSString *displayname;
@property(nonatomic, strong) NSMutableArray *comments;
@property(nonatomic, strong) NSMutableArray *contents;
@property(nonatomic, strong) NSMutableArray *tags;
@property(readwrite, assign) int facebookShareCount;
@property(readwrite, assign) int twitterShareCount;
@property(readwrite, assign) int pinterestShareCount;
@property(readwrite, assign) int emailShareCount;
@property(readwrite, assign) BOOL shared;
@property(readwrite, assign) BOOL dropped;
@property(readwrite, assign) BOOL showOnMap;
@property(readwrite, assign) BOOL showOnList;
@property(readwrite, assign) BOOL userLiked;
@property(readwrite, assign) BOOL userFlagged;
@property(readwrite, assign) int numRatings;
@property(readwrite, assign) double latitude;
@property(readwrite, assign) double longitude;
@property(readwrite, assign) nearbyObjectKind kind;
@property(readwrite, assign) int parentNoteId;
@property(readwrite, assign) int parentRating;
@property(nonatomic, unsafe_unretained) id delegate;

-(BOOL)isUploading;
-(BOOL)compareTo: (Note *) note;
@end
