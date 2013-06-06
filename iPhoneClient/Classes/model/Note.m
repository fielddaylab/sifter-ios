//
//  Note.m
//  ARIS
//
//  Created by Brian Thiel on 8/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Note.h"
#import "ARISAppDelegate.h"
#import "AppModel.h"
#import "NearbyObjectsViewController.h"
#import "NoteContent.h"

 NSString *const kNoteContentTypeAudio = @"AUDIO";
 NSString *const kNoteContentTypeVideo = @"VIDEO";
 NSString *const kNoteContentTypePhoto = @"PHOTO";
 NSString *const kNoteContentTypeText = @"TEXT";

@implementation Note
@synthesize comments,contents, creatorId,noteId,parentNoteId,parentRating,shared,text,title,kind,numRatings,username,delegate,dropped,showOnMap,showOnList,userLiked,hasImage,hasAudio,tags,tagSection,tagName,latitude,longitude;
@synthesize displayname;

-(nearbyObjectKind) kind { return NearbyObjectNote; }

- (Note *) init {
    self = [super init];
    if (self) {
		kind = NearbyObjectNote;
        iconMediaId = 71;
        self.comments = [NSMutableArray arrayWithCapacity:5];
        self.contents = [NSMutableArray arrayWithCapacity:5];
        self.tags = [NSMutableArray arrayWithCapacity:5];
    }
    return self;	
}



- (void) display{
	NSLog(@"WebPage: Display Self Requested");
#warning add?
    /*
        //open up note viewer
        NoteDetailsViewController *dataVC = [[NoteDetailsViewController alloc] initWithNibName:@"NoteDetailsViewController" bundle:nil];
        dataVC.note = self;
        dataVC.delegate = self;
    [[RootViewController sharedRootViewController] displayNearbyObjectView:dataVC];
     */
}

-(BOOL)isUploading{
    for (int i = 0;i < [self.contents count]; i++) {
        if ([[(NoteContent *)[self.contents objectAtIndex:i]type] isEqualToString:@"UPLOAD"]) {
            return  YES;
        }
    }
    return  NO;
}

- (int)	iconMediaId {
    return 71; 
}

- (BOOL)compareTo:(Note *)other
{
    return  self.noteId         == other.noteId;/* &&
            self.creatorId      == other.creatorId &&
            self.numRatings     == other.numRatings &&
            self.shared         == other.shared &&
            self.dropped        == other.dropped &&
            self.showOnMap      == other.showOnMap &&
            self.showOnList     == other.showOnList &&
            self.userLiked      == other.userLiked &&
            self.parentNoteId   == other.parentNoteId &&
            self.parentRating   == other.parentRating &&
            self.kind           == other.kind &&
            self.iconMediaId    == other.iconMediaId &&
            self.latitude       == other.latitude &&
            self.longitude      == other.longitude &&
            [self.title         isEqualToString:other.title] &&
            [self.text          isEqualToString:other.text] &&
            [self.username      isEqualToString:other.username] &&
            [self.displayname   isEqualToString:other.displayname] &&
            [self.tagName       isEqualToString:other.tagName]; */
}

@end
