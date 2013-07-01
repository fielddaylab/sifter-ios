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
    NSArray *allTags;
    NSMutableArray *selectedTags;
    NSMutableArray *searchTerms;
    
    ContentSelector selectedContent;
}

@end

@implementation InnovNoteModel

@synthesize availableNotes, allTags, selectedTags;

+ (id)sharedNoteModel
{
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] init];
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
        allTags         = [[NSArray alloc] init];
        selectedTags    = [[NSMutableArray alloc] initWithCapacity:8];
        searchTerms     = [[NSMutableArray alloc] initWithCapacity:8];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newNotesReceived:)    name:@"NewNoteListReady"    object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newTagsReceived:)     name:@"NewTagListReady"     object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateNoteContents:)  name:@"NewContentListReady" object:nil];
    }
    return self;
}

-(void) clearData
{
    [allNotes removeAllObjects];
    [self sendLostNotesNotif:[availableNotes copy]];
    [availableNotes removeAllObjects];
    [self sendChangeNotesNotif];
}

- (void) fetchMoreNotes
{
    if ([AppServices sharedAppServices].isCurrentlyFetchingGameNoteList)
    {
        [NSTimer scheduledTimerWithTimeInterval:0.5
                                         target:self
                                       selector:@selector(fetchMoreNotes)
                                       userInfo:nil
                                        repeats:NO];
    }
    else
    {
        [AppServices sharedAppServices].shouldIgnoreResults = NO;
        switch (selectedContent)
        {
            case kTop:
                [[AppServices sharedAppServices] fetch: NOTES_PER_FETCH moreTopNotesStartingFrom:    [allNotes count]];
                break;
            case kPopular:
                [[AppServices sharedAppServices] fetch: NOTES_PER_FETCH morePopularNotesStartingFrom:[allNotes count]];
                break;
            case kRecent:
                [[AppServices sharedAppServices] fetch: NOTES_PER_FETCH moreRecentNotesStartingFrom: [allNotes count]];
                break;
            case kMine:
                [[AppServices sharedAppServices] fetch: NOTES_PER_FETCH morePlayerNotesStartingFrom: [allNotes count]];
                break;
            default:
                break;
        }
    }
}


#pragma mark Updates from Server

-(void) newNotesReceived:(NSNotification *)notification
{
    NSDictionary *newNotes = [notification.userInfo objectForKey:@"notes"];
    [allNotes addEntriesFromDictionary:newNotes];
    [self updateNotes:newNotes];
    [self sendNotesUpdateNotification];
}


-(void) newTagsReceived:(NSNotification *)notification
{
    allTags = [notification.userInfo objectForKey:@"tags"];
    if([selectedTags count] == 0) selectedTags = [allTags mutableCopy];
    
    NSNotification *notif  = [NSNotification notificationWithName:@"NoteModelUpdate:Tags" object:self];
    [[Logger sharedLogger] logNotification: notif];
    [[NSNotificationCenter defaultCenter] postNotification: notif];
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
    Note *note = [self noteForNoteId:[[notification.userInfo objectForKey:@"noteId"] intValue]];
    [self updateNoteContentsWithNote:note];
}

-(void) updateNoteContentsWithNote: (Note *) note
{
    note = [self noteForNoteId:note.noteId];
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
#warning Find out why sending notification breaks this
    [allNotes setObject:note forKey:[NSNumber numberWithInt:note.noteId]];
    if([self noteShouldBeAvailable:note])
        [availableNotes addObject:note];
}

-(void) updateNote:(Note *) note
{
    [allNotes setObject:note forKey:[NSNumber numberWithInt:note.noteId]];
    int indexToRemove = -1;
    for(int i = 0; i < [availableNotes count]; ++i)
    {
        Note *existingNote = [availableNotes objectAtIndex:i];
        if(note.noteId == existingNote.noteId)
        {
            indexToRemove = i;
            break;
        }
    }
    
    if(indexToRemove != -1)
    {
        [self sendLostNotesNotif:[NSArray arrayWithObject:[availableNotes objectAtIndex:indexToRemove]]];
        [availableNotes removeObjectAtIndex:indexToRemove];
    }
    if([self noteShouldBeAvailable:note])
    {
        if(indexToRemove >= [availableNotes count])
            [availableNotes addObject:note];
        else
            [availableNotes insertObject:note atIndex:indexToRemove];
        [self sendNewNotesNotif:[NSArray arrayWithObject:note]];
    }
    
    [self sendChangeNotesNotif];
    [self sendNotesUpdateNotification];
}

-(void) removeNote:(Note *) note
{
    [allNotes removeObjectForKey:[NSNumber numberWithInt:note.noteId]];
    Note *noteToRemove;
    for(Note *existingNote in availableNotes)
    {
        if(note.noteId == existingNote.noteId)
        {
            noteToRemove = existingNote;
            break;
        }
    }
    if(noteToRemove)
    {
        [availableNotes removeObject:noteToRemove];
        [self sendLostNotesNotif:[NSArray arrayWithObject:noteToRemove]];
        [self sendChangeNotesNotif];
    }
}

-(Note *) noteForNoteId:(int) noteId
{
    Note *note = [allNotes objectForKey:[NSNumber numberWithInt:noteId]];
    
    if(!note && note.noteId != 0)
        [[AppServices sharedAppServices] fetchNote:note.noteId];
    //else
    //    [self updateNoteContentsWithNote:note];
#warning Consider
    return note;
}

#pragma mark Available Notes

-(BOOL) noteShouldBeAvailable: (Note *) note
{
#warning POSSIBLY CHANGE
    if(selectedContent != kMine)
    {
        BOOL match = NO;
        for(Tag *tag in selectedTags)
        {
            if([note.tags count] > 0)
                if (((Tag *)[note.tags objectAtIndex:0]).tagId == tag.tagId) match = YES;
        }
        if(!match) return NO;
    }
    for(NSString *searchTerm in searchTerms)
        if([note.username.lowercaseString rangeOfString:searchTerm].location == NSNotFound && [note.title.lowercaseString rangeOfString:searchTerm].location == NSNotFound) return NO;
    
    return YES;
}

-(void) addTag: (Tag *) addTag
{
    for(Tag *currentTag in selectedTags)
        if(currentTag.tagId == addTag.tagId) return;
    
    [selectedTags addObject: addTag];
    [self updateNotes:allNotes];
    [self sendSelectedTagsUpdateNotification];
}

-(void) removeTag: (Tag *) removeTag
{
    for(int i = 0; i < [selectedTags count]; ++i)
    {
        Tag *tag = [selectedTags objectAtIndex:i];
        if(tag.tagId == removeTag.tagId)
        {
            [selectedTags removeObject: tag];
            [self updateNotes:allNotes];
            [self sendSelectedTagsUpdateNotification];
            return;
        }
    }
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

-(void) setSelectedContent: (ContentSelector) contentSelector
{
    selectedContent = contentSelector;
    [AppServices sharedAppServices].shouldIgnoreResults = YES;
    [self clearData];
    [self fetchMoreNotes];
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

- (void) sendNotesUpdateNotification
{
    NSNotification *notif  = [NSNotification notificationWithName:@"NoteModelUpdate:Notes" object:self];
    [[Logger sharedLogger] logNotification: notif];
    [[NSNotificationCenter defaultCenter] postNotification: notif];
}

- (void) sendSelectedTagsUpdateNotification
{
    NSNotification *notif  = [NSNotification notificationWithName:@"NoteModelUpdate:SelectedTags" object:self];
    [[Logger sharedLogger] logNotification: notif];
    [[NSNotificationCenter defaultCenter] postNotification: notif];
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
