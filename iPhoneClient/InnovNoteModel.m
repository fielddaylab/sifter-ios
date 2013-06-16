//
//  InnovNoteModel.m
//  YOI
//
//  Created by Jacob James Hanshaw on 5/22/13.
//
//

#import "InnovNoteModel.h"

#import "Logger.h"
#import "Note.h"
#import "Tag.h"

@interface InnovNoteModel()
{
    NSArray *allNotes;
    NSMutableArray *availableTags;
    NSMutableArray *searchTerms;
}

@end

@implementation InnovNoteModel

@synthesize availableNotes;

-(id)init
{
    self = [super init];
    if(self)
    {
        [self clearData];
        availableNotes  = [[NSMutableArray alloc] initWithCapacity:20];
        availableTags   = [[NSMutableArray alloc] initWithCapacity:8];
        searchTerms     = [[NSMutableArray alloc] initWithCapacity:8];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(latestGameNotesReceived:)      name:@"GameNoteListRefreshed"   object:nil];
    }
    return self;
}

-(void) clearData
{
    [self updateNotes:[[NSArray alloc] init]];
}

-(void) latestGameNotesReceived:(NSNotification *)notification
{
    allNotes = [notification.userInfo objectForKey:@"notes"];
    [self updateNotes:allNotes];
}

-(void) updateNotes:(NSArray *)notes
{
    NSMutableArray *newlyAvailableNotes   = [[NSMutableArray alloc] initWithCapacity:20];
    NSMutableArray *newlyUnavailableNotes = [[NSMutableArray alloc] initWithCapacity:20];
    NSMutableArray *availableNotesMutable = [[NSMutableArray alloc] initWithArray:   availableNotes];
    
    //Gained Notes
    for(Note *newNote in notes)
    {
        BOOL match = NO;
        
        for (Note *existingNote in availableNotes)
        {
            if ([newNote compareTo: existingNote])
                match = YES;
        }
        
        if(!match && [self noteShouldBeAvailable:newNote]) //Newly Available Note
            [newlyAvailableNotes addObject:newNote];
    }
    
    //Lost Notes
    for (Note *existingNote in availableNotes)
    {
        BOOL match = NO;
        for (Note *newNote in notes)
        {
            if ([newNote compareTo: existingNote])
                match = YES;
        }
        
        if((!match && [self noteShouldBeAvailable:existingNote]) || ![self noteShouldBeAvailable:existingNote]) //Lost Note
            [newlyUnavailableNotes addObject: existingNote];
    }
    
    [availableNotesMutable addObjectsFromArray:  newlyAvailableNotes];
    [availableNotesMutable removeObjectsInArray: newlyUnavailableNotes];
    availableNotes = [availableNotesMutable copy];
    
    if([newlyAvailableNotes count] > 0 || [newlyUnavailableNotes count] > 0)
    {
        NSDictionary *nDict = [[NSDictionary alloc] initWithObjectsAndKeys:
                               availableNotes,@"availableNotes",
                               nil];
        NSNotification *notif  = [NSNotification notificationWithName:@"NotesAvailableChanged" object:self userInfo:nDict];
        [[Logger sharedLogger] logNotification: notif];
        [[NSNotificationCenter defaultCenter] postNotification:notif];
        
        if([newlyAvailableNotes count] > 0)
        {
            NSDictionary *nDict = [[NSDictionary alloc] initWithObjectsAndKeys:
                                   newlyAvailableNotes,@"newlyAvailableNotes",
                                   nil];
            NSNotification *notif  = [NSNotification notificationWithName:@"NewlyAvailableNotesAvailable"  object:self userInfo:nDict];
            [[Logger sharedLogger] logNotification: notif];
            [[NSNotificationCenter defaultCenter] postNotification: notif];
        }
        if([newlyUnavailableNotes count] > 0)
        {
            NSDictionary *nDict = [[NSDictionary alloc] initWithObjectsAndKeys:
                                   newlyUnavailableNotes,@"newlyUnavailableNotes",
                                   nil];
            NSNotification *notif  = [NSNotification notificationWithName:@"NewlyUnavailableNotesAvailable" object:self userInfo:nDict];
            [[Logger sharedLogger] logNotification: notif];
            [[NSNotificationCenter defaultCenter] postNotification: notif];
        }
        
    }
}

-(BOOL) noteShouldBeAvailable: (Note *) note
{
    BOOL match = NO;
    for(Tag *tag in availableTags)
    {
        if([note.tags count] > 0)
            if (((Tag *)[note.tags objectAtIndex:0]).tagId == tag.tagId) match = YES;
    }
    
    if(!match) return NO;
    
    for(NSString *searchTerm in searchTerms)
        if([note.title.lowercaseString rangeOfString:searchTerm].location == NSNotFound) return NO;
    
    return YES;
}

-(void) addTag: (Tag *) addTag
{
    [availableTags addObject: addTag];
    [self updateNotes:allNotes];
}

-(void) removeTag: (Tag *) removeTag
{
    for(Tag *tag in availableTags)
    {
        if(tag.tagId == removeTag.tagId)
            [availableTags removeObject: tag];
    }
    
    [self updateNotes:allNotes];
}

-(void) addSearchTerm: (NSString *) term
{
    if([term length] > 0) [searchTerms addObject: term];
    [self updateNotes:allNotes];
}

-(void) removeSearchTerm: (NSString *) term
{
    for(NSString *currentTerm in searchTerms)
    {
        if([term isEqualToString:currentTerm])
            [searchTerms removeObject: currentTerm];
    }
    
    [self updateNotes:allNotes];
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
