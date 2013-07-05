//
//  InnovNoteModel.h
//  YOI
//
//  Created by Jacob James Hanshaw on 5/22/13.
//
//

typedef enum {
	kTop,
    kPopular,
    kRecent,
    kMine
} ContentSelector;

#define NOTES_PER_FETCH 50

@class Note, Tag;

@interface InnovNoteModel : NSObject

@property(nonatomic, readonly) NSArray *availableNotes;
@property(nonatomic, readonly) NSArray *allTags;
@property(nonatomic, readonly) NSArray *selectedTags;

+(InnovNoteModel *) sharedNoteModel;
-(void) clearData;
-(void) fetchMoreNotes;

-(void) addNote:(Note *) note;
-(void) updateNote:(Note *) note;
-(void) removeNote:(Note *) note;
-(Note *) noteForNoteId:(int) noteId;

-(void) addTag: (Tag *) tag;
-(void) removeTag: (Tag *) tag;
-(void) addSearchTerm: (NSString *) term;
-(void) removeSearchTerm: (NSString *) term;
-(void) setSelectedContent: (ContentSelector) contentSelector;

@end