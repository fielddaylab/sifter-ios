//
//  InnovNoteModel.h
//  YOI
//
//  Created by Jacob James Hanshaw on 5/22/13.
//
//

@class Note, Tag;

@interface InnovNoteModel : NSObject

@property(nonatomic, readonly) NSArray *availableNotes;

+(id) sharedNoteModel;
-(void) clearData;

-(void) addNote:(Note *) note;
-(void) updateNote:(Note *) note;
-(void) removeNote:(Note *) note;

-(Note *) noteForNoteId:(int) noteId;

-(void) addTag: (Tag *) tag;
-(void) removeTag: (Tag *) tag;
-(void) addSearchTerm: (NSString *) term;
-(void) removeSearchTerm: (NSString *) term;

@end
