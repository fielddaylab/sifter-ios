//
//  InnovNoteModel.h
//  YOI
//
//  Created by Jacob James Hanshaw on 5/22/13.
//
//

#import <Foundation/Foundation.h>

@class Tag;

@interface InnovNoteModel : NSObject

@property(nonatomic) NSArray *availableNotes;

-(void) clearData;

-(void) addTag: (Tag *) tag;
-(void) removeTag: (Tag *) tag;
-(void) addSearchTerm: (NSString *) term;
-(void) removeSearchTerm: (NSString *) term;

@end
