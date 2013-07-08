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
#import "MyCLController.h"
#import "Logger.h"
#import "Note.h"
#import "NoteContent.h"
#import "Tag.h"

@interface InnovNoteModel()
{
    NSMutableDictionary *allNotes;
    NSMutableArray *availableNotes;
    NSArray *notifNotesCounts;
    NSMutableArray *arrayOfArraysByType;
    NSArray *allTags;
    NSMutableArray *selectedTags;
    NSMutableArray *searchTerms;
    
    BOOL unprocessedNotifs;
    
    ContentSelector selectedContent;
}

@end

@implementation InnovNoteModel

@synthesize availableNotes, notifNotesCounts, allTags, selectedTags;

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
        arrayOfArraysByType             = [[NSMutableArray alloc] initWithCapacity:kNumContents];
        NSMutableArray *topNotes        = [[NSMutableArray alloc] init];
        NSMutableArray *popularNotes    = [[NSMutableArray alloc] init];
        NSMutableArray *recentNotes     = [[NSMutableArray alloc] init];
        NSMutableArray *mineNotes       = [[NSMutableArray alloc] init];
        [arrayOfArraysByType addObject:topNotes];
        [arrayOfArraysByType addObject:popularNotes];
        [arrayOfArraysByType addObject:recentNotes];
        [arrayOfArraysByType addObject:mineNotes];
        allTags         = [[NSArray alloc] init];
        selectedTags    = [[NSMutableArray alloc] initWithCapacity:8];
        searchTerms     = [[NSMutableArray alloc] initWithCapacity:8];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newNotesReceived:)    name:@"NewNoteListReady"    object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newTagsReceived:)     name:@"NewTagListReady"     object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateNoteContents:)  name:@"NewContentListReady" object:nil];
    }
    return self;
}

#pragma mark Clear Model

-(void) clearAllData
{
    [allNotes removeAllObjects];
    [self clearAvailableData];
}

-(void) clearAvailableData
{
    [self sendLostNotesNotif:[availableNotes copy]];
    [availableNotes removeAllObjects];
    [self sendChangeNotesNotif];
}

#pragma mark Mark Notes For Notification

- (void) setUpNotificationsForTopNotes: (int) topNotes popularNotes: (int) popularNotes recentNotes: (int) recentNotes andMyRecentNotes: (int) myRecentNotes
{
    notifNotesCounts = [NSArray arrayWithObjects:[NSNumber numberWithInt:topNotes], [NSNumber numberWithInt:popularNotes],
                       [NSNumber numberWithInt:recentNotes], [NSNumber numberWithInt:myRecentNotes], nil];
    [self setUpNotifications];
}

- (void) setUpNotifications
{
    
    if([[notifNotesCounts objectAtIndex:kTop] intValue] > [[arrayOfArraysByType objectAtIndex:kTop] count] && ([[arrayOfArraysByType objectAtIndex:kTop] count] % NOTES_PER_FETCH == 0))
    {
        unprocessedNotifs = YES;
        [self fetchMoreNotesOfType:kTop];
        return;
    }
    else if([[notifNotesCounts objectAtIndex:kPopular] intValue] > [[arrayOfArraysByType objectAtIndex:kPopular] count] && ([[arrayOfArraysByType objectAtIndex:kPopular] count] % NOTES_PER_FETCH == 0))
    {
        unprocessedNotifs = YES;
        [self fetchMoreNotesOfType:kPopular];
        return;
    }
    else if([[notifNotesCounts objectAtIndex:kRecent] intValue] > [[arrayOfArraysByType objectAtIndex:kRecent] count] && ([[arrayOfArraysByType objectAtIndex:kRecent] count] % NOTES_PER_FETCH == 0))
    {
        unprocessedNotifs = YES;
        [self fetchMoreNotesOfType:kRecent];
        return;
    }
    else if([[notifNotesCounts objectAtIndex:kMine] intValue]> [[arrayOfArraysByType objectAtIndex:kMine] count] && ([[arrayOfArraysByType objectAtIndex:kMine] count] % NOTES_PER_FETCH == 0))
    {
        unprocessedNotifs = YES;
        [self fetchMoreNotesOfType:kMine];
        return;
    }
    
    unprocessedNotifs = NO;
    NSMutableArray *notifNoteIds = [[NSMutableArray alloc] initWithCapacity:20];
    
    for(int i = 0; i < kNumContents; ++i)
    {
        for(int j = 0; j < MIN([[notifNotesCounts objectAtIndex:i] intValue], [[arrayOfArraysByType objectAtIndex:i] count]); ++j)
        {
            [notifNoteIds addObject:[[arrayOfArraysByType objectAtIndex:i] objectAtIndex:j]];
        }
    }
    
    NSArray *notifNotes = [allNotes objectsForKeys:notifNoteIds notFoundMarker:[[Note alloc] init]];
    [[MyCLController sharedMyCLController] prepareNotificationsForNotes: notifNotes];
}

#pragma mark Fetch More Notes

- (void) fetchMoreNotes
{
    [self fetchMoreNotesOfType:selectedContent];
}

- (void) fetchMoreNotesWithUserInfo: (NSNotification *) notification
{
    [self fetchMoreNotesOfType:[[notification.userInfo objectForKey:@"ContentSelector"] intValue]];
}

- (void) fetchMoreNotesOfType:(ContentSelector) specifiedContent
{
    if ([AppServices sharedAppServices].isCurrentlyFetchingGameNoteList)
    {
        [NSTimer scheduledTimerWithTimeInterval:1.0
                                         target:self
                                       selector:@selector(fetchMoreNotesWithUserInfo:)
                                       userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:specifiedContent], @"ContentSelector", nil]
                                        repeats:NO];
    }
    else
    {
        int currentNoteCount = [[arrayOfArraysByType objectAtIndex:specifiedContent] count];
        [AppServices sharedAppServices].shouldIgnoreResults = NO;
        [[AppServices sharedAppServices] fetch: NOTES_PER_FETCH more: specifiedContent NotesStartingFrom: currentNoteCount];
    }
}

#pragma mark Updates from Server

-(void) newNotesReceived:(NSNotification *)notification
{
    NSDictionary *newNotes = [notification.userInfo objectForKey:@"notes"];
    [allNotes addEntriesFromDictionary:newNotes];
    ContentSelector updatedNotes = [[notification.userInfo objectForKey:@"ContentSelector"] intValue];
    NSMutableArray *selectedArray = [arrayOfArraysByType objectAtIndex:updatedNotes];
    [selectedArray addObjectsFromArray:[newNotes allKeys]];
    
    if(unprocessedNotifs)
        [self setUpNotifications];
    
    if(updatedNotes == selectedContent)
    {
        [self updateAvailableNotes];
        [self sendNotesUpdateNotification];
    }
}


-(void) newTagsReceived:(NSNotification *)notification
{
    allTags = [notification.userInfo objectForKey:@"tags"];
    if([selectedTags count] == 0) selectedTags = [allTags mutableCopy];
    
    NSNotification *notif  = [NSNotification notificationWithName:@"NoteModelUpdate:Tags" object:self];
    [[Logger sharedLogger] logNotification: notif];
    [[NSNotificationCenter defaultCenter] postNotification: notif];
}

-(void) updateAvailableNotes
{
    NSArray *selectedNoteIds = [arrayOfArraysByType objectAtIndex:selectedContent];
    NSArray *selectedNotes   = [allNotes objectsForKeys:selectedNoteIds notFoundMarker:[[Note alloc] init]];
    [self updateNotes:selectedNotes];
}

-(void) updateNotes:(NSArray *)notes
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
    if([note.tags count] == 0) return NO;
    
    if(selectedContent != kMine)
    {
        BOOL match = NO;
        for(Tag *tag in selectedTags)
        {
            if (((Tag *)[note.tags objectAtIndex:0]).tagId == tag.tagId)
            {
                match = YES;
                break;
            }
        }
        if(!match) return NO;
    }
    
    NSString *author = ([note.displayname length] > 0) ? note.displayname : note.username;
    
    for(NSString *searchTerm in searchTerms)
        if([author.lowercaseString rangeOfString:searchTerm].location == NSNotFound && [note.text.lowercaseString rangeOfString:searchTerm].location == NSNotFound) return NO;
    
    return (note.imageMediaId != 0);
}

-(void) addTag: (Tag *) addTag
{
    for(Tag *currentTag in selectedTags)
        if(currentTag.tagId == addTag.tagId) return;
    
    [selectedTags addObject: addTag];
    [self updateAvailableNotes];
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
            [self updateAvailableNotes];
            [self sendSelectedTagsUpdateNotification];
            return;
        }
    }
}

-(void) addSearchTerm: (NSString *) term
{
    if([term length] > 0) [searchTerms addObject: term];
    [self updateAvailableNotes];
}

-(void) removeSearchTerm: (NSString *) term
{
    for(NSString *currentTerm in searchTerms)
    {
        if([term isEqualToString:currentTerm])
            [searchTerms removeObject: currentTerm];
    }
    [self updateAvailableNotes];
}

-(void) setSelectedContent: (ContentSelector) contentSelector
{
    selectedContent = contentSelector;
    [AppServices sharedAppServices].shouldIgnoreResults = YES;
    [self clearAvailableData];
    
    if([[arrayOfArraysByType objectAtIndex:selectedContent] count] < NOTES_PER_FETCH)
        [self fetchMoreNotes];
    else
        [self updateAvailableNotes];
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
