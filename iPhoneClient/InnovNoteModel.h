//
//  InnovNoteModel.h
//  YOI
//
//  Created by Jacob James Hanshaw on 5/22/13.
//
//

@protocol RefreshDelegate <NSObject>
@required
- (void) refreshCompleted;
@end

typedef enum {
	kTop,
    kPopular,
    kRecent,
    kMine,
    kNumContents
} ContentSelector;

#define NOTES_PER_FETCH        50
#define MAX_MAP_NOTES_COUNT    50

@class Note, Tag;

@interface InnovNoteModel : NSObject

@property(nonatomic, readonly) NSArray *availableNotes;
@property(nonatomic, readonly) NSArray *allTags;
@property(nonatomic, readonly) NSArray *selectedTags;

+(InnovNoteModel *) sharedNoteModel;
-(void) clearAllData;

-(void) setUpNotificationsForTopNotes: (int) topNotes popularNotes: (int) popularNotes recentNotes: (int) recentNotes andMyRecentNotes: (int) myRecentNotes;

-(void) fetchMoreNotes;
-(void) refreshCurrentNotesWithDelegate:(id<RefreshDelegate>) delegate;

-(void) addNote:(Note *) note;
-(void) updateNote:(Note *) note;
-(void) removeNote:(Note *) note;
-(void) setNoteAsPreviouslyDisplayed:(Note *) note;
-(Note *) noteForNoteId:(int) noteId;

-(NSArray *) getNotifNoteCounts;

-(void) addTag: (Tag *) tag;
-(void) removeTag: (Tag *) tag;
-(void) addSearchTerm: (NSString *) term;
-(void) removeSearchTerm: (NSString *) term;
-(void) setSelectedContent: (ContentSelector) contentSelector;

-(void) addNoteToFacebookShareQueue: (Note *) note;
-(BOOL) removeNoteFromFacebookShareQueue: (Note *) note;

@end