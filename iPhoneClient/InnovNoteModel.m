//
//  InnovNoteModel.m
//  YOI
//
//  Created by Jacob James Hanshaw on 5/22/13.
//
//

#import "InnovNoteModel.h"

#import "AppModel.h"
#import "AppServices.h"
#import "Logger.h"
#import "Note.h"
#import "Tag.h"

@interface InnovNoteModel()
{
    NSMutableDictionary *allNotes;
    NSMutableArray *availableNotes;
    NSMutableArray *availableTags;
    NSMutableArray *searchTerms;
}

@end

@implementation InnovNoteModel

@synthesize availableNotes;

+ (id)sharedNoteModel
{
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] init]; // or some other init method
    });
    return _sharedObject;
}

-(id)init
{
    self = [super init];
    if(self)
    {
        allNotes        = [[NSMutableDictionary alloc] init];
        availableNotes  = [[NSMutableArray alloc] init];
        availableTags   = [[NSMutableArray alloc] initWithCapacity:8];
        searchTerms     = [[NSMutableArray alloc] initWithCapacity:8];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(latestGameNotesReceived:)      name:@"GameNoteListRefreshed"   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateNoteContents:)      name:@"NewContentListReady"   object:nil];
    }
    return self;
}

-(void) clearData
{
    [allNotes removeAllObjects];
    [self sendLostNotesNotif:[availableNotes copy]];
    [availableNotes removeAllObjects];
    [self sendChangeNotesNotif];
    [self updateNotes:[[NSDictionary alloc] init]];
}

-(void) latestGameNotesReceived:(NSNotification *)notification
{
    NSDictionary *newNotes = [notification.userInfo objectForKey:@"notes"];
    [allNotes addEntriesFromDictionary:newNotes];
    for(Note *note in [newNotes allValues])
        [self updateNotes:newNotes];
}

-(void) updateNotes:(NSDictionary *)notes
{
    NSMutableArray *newlyAvailableNotes   = [[NSMutableArray alloc] initWithCapacity:20];
    NSMutableArray *newlyUnavailableNotes = [[NSMutableArray alloc] initWithCapacity:20];
    
    //Lost Notes
    for (Note *existingNote in availableNotes)
    {
        if(![self noteShouldBeAvailable:existingNote])
            [newlyUnavailableNotes addObject: existingNote];
    }
    
    [availableNotes removeObjectsInArray: newlyUnavailableNotes];
    
    //Gained Notes
    for(Note *newNote in [notes allValues])
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
    
    [availableNotes addObjectsFromArray:  newlyAvailableNotes];
    
    if([newlyAvailableNotes count] > 0 || [newlyUnavailableNotes count] > 0)
    {
        [self sendChangeNotesNotif];
        
        if([newlyAvailableNotes count] > 0)
            [self sendNewNotesNotif:newlyAvailableNotes];
        
        if([newlyUnavailableNotes count] > 0)
            [self sendLostNotesNotif:newlyUnavailableNotes];
    }
}

-(void) updateNoteContents:(NSNotification *)notification
{
    Note *note = [self noteForNoteId:[notification.userInfo objectForKey:@"noteId"]];
    [self updateNoteContentsWithNote:note];
}

-(void) updateNoteContentsWithNote: (Note *) note
{
    for(NSObject <NoteContentProtocol> *contentObject in note.contents)
    {
        //Removes note contents that are not done uploading, because they will all be added again right after this loop
        if([contentObject managedObjectContext] == nil || ![[contentObject getUploadState] isEqualToString:@"uploadStateDONE"])
            [note.contents removeObject:contentObject];
    }
    
    NSArray *uploadContentsForNote = [[[AppModel sharedAppModel].uploadManager.uploadContentsForNotes objectForKey:[NSNumber numberWithInt:note.noteId]]allValues];
    [note.contents addObjectsFromArray:uploadContentsForNote];
}

-(void) addNote:(Note *) note
{
    [allNotes setObject:note forKey:[NSNumber numberWithInt:note.noteId]];
    if([self noteShouldBeAvailable:note])
    {
        [availableNotes addObject:note];
        [self sendNewNotesNotif:[NSArray arrayWithObject:note]];
        [self sendChangeNotesNotif];
    }
}

-(void) updateNote:(Note *) note
{
    [allNotes setObject:note forKey:[NSNumber numberWithInt:note.noteId]];
    Note *existingNote;
    if([self noteShouldBeAvailable:note]) {
        for(existingNote in availableNotes)
        {
            if(note.noteId == existingNote.noteId)
            {
                [availableNotes removeObject:existingNote];
                [self sendLostNotesNotif:[NSArray arrayWithObject:existingNote]];
                break;
            }
        }
        [availableNotes addObject:note];
        [self sendNewNotesNotif:[NSArray arrayWithObject:note]];
        [self sendChangeNotesNotif];
    }
}

-(void) removeNote:(Note *) note
{
    [allNotes removeObjectForKey:[NSNumber numberWithInt:note.noteId]];
    Note *existingNote;
    for(existingNote in availableNotes)
    {
        if(note.noteId == existingNote.noteId)
        {
            [availableNotes removeObject:existingNote];
            [self sendLostNotesNotif:[NSArray arrayWithObject:existingNote]];
            [self sendChangeNotesNotif];
            break;
        }
    }
}

-(Note *) noteForNoteId:(int) noteId
{
#warning REMOVE
    NSString *sourceString = [[NSThread callStackSymbols] objectAtIndex:1];
    NSCharacterSet *separatorSet = [NSCharacterSet characterSetWithCharactersInString:@" -[]+?.,"];
    NSMutableArray *array = [NSMutableArray arrayWithArray:[sourceString  componentsSeparatedByCharactersInSet:separatorSet]];
    [array removeObject:@""];
    
    NSLog(@"%@: %@ Debug: %@", [array objectAtIndex:3], [array objectAtIndex:4], @"CAlling");
    
    Note *note = [allNotes objectForKey:[NSNumber numberWithInt:noteId]];
    
    if(!note && note.noteId)
    {
        [[AppServices sharedAppServices] fetchGameNoteListAsynchronously:YES];
    }
    else
        [self updateNoteContentsWithNote:note];
    
    return note;
}

#pragma mark Notifications

-(void) sendChangeNotesNotif
{
    NSDictionary *nDict = [[NSDictionary alloc] initWithObjectsAndKeys:
                           availableNotes,@"availableNotes",
                           nil];
    NSNotification *notif  = [NSNotification notificationWithName:@"NotesAvailableChanged" object:self userInfo:nDict];
    [[Logger sharedLogger] logNotification: notif];
    [[NSNotificationCenter defaultCenter] postNotification:notif];
}

-(void) sendNewNotesNotif: (NSArray *) notes
{
    NSDictionary *nDict = [[NSDictionary alloc] initWithObjectsAndKeys:
                           notes,@"newlyAvailableNotes",
                           nil];
    NSNotification *notif  = [NSNotification notificationWithName:@"NewlyAvailableNotesAvailable"  object:self userInfo:nDict];
    [[Logger sharedLogger] logNotification: notif];
    [[NSNotificationCenter defaultCenter] postNotification: notif];
}

-(void) sendLostNotesNotif: (NSArray *) notes
{
    NSDictionary *nDict = [[NSDictionary alloc] initWithObjectsAndKeys:
                           notes,@"newlyUnavailableNotes",
                           nil];
    NSNotification *notif  = [NSNotification notificationWithName:@"NewlyUnavailableNotesAvailable" object:self userInfo:nDict];
    [[Logger sharedLogger] logNotification: notif];
    [[NSNotificationCenter defaultCenter] postNotification: notif];
}

#pragma mark Available Notes

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
    for(int i = 0; i < [availableTags count]; ++i)
    {
        Tag *tag = [availableTags objectAtIndex:i];
        if(tag.tagId == removeTag.tagId)
        {
            [availableTags removeObject: tag];
            break;
        }
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
