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

#define NOTES_PER_FETCH 25

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
#warning implement proper searchers
#warning fetch more notes each time
    switch (selectedContent)
    {
        case kTop:
        case kPopular:
        case kRecent:
        case kMine:
        default:
            [[AppServices sharedAppServices] fetchGameNoteListAsynchronously:YES];
            break;
    }
}


#pragma mark Updates from Server

-(void) newNotesReceived:(NSNotification *)notification
{
    NSDictionary *newNotes = [notification.userInfo objectForKey:@"notes"];
    [allNotes addEntriesFromDictionary:newNotes];
    [self updateNotes:newNotes];
    
    NSNotification *notif  = [NSNotification notificationWithName:@"NoteModelUpdate:Notes" object:self];
    [[Logger sharedLogger] logNotification: notif];
    [[NSNotificationCenter defaultCenter] postNotification: notif];
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
    for(existingNote in availableNotes)
    {
        if(note.noteId == existingNote.noteId)
        {
            [availableNotes removeObject:existingNote];
            [self sendLostNotesNotif:[NSArray arrayWithObject:existingNote]];
            if(![self noteShouldBeAvailable:note])
            {
                [self sendChangeNotesNotif];
                return;
            }
            break;
        }
    }
    [availableNotes addObject:note];
    [self sendNewNotesNotif:[NSArray arrayWithObject:note]];
    [self sendChangeNotesNotif];
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
    Note *note = [allNotes objectForKey:[NSNumber numberWithInt:noteId]];
    
    if(!note && note.noteId != 0)
        [[AppServices sharedAppServices] fetchGameNoteListAsynchronously:YES];
    else
        [self updateNoteContentsWithNote:note];
    
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
        if([note.title.lowercaseString rangeOfString:searchTerm].location == NSNotFound) return NO;
    
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
