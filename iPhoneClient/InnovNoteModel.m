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

#define PREV_DISPLAYED_NOTES_KEY @"PrevDispNotes"
#define NOTIF_NOTE_COUNT_KEY     @"NotifNoteCount"

@interface InnovNoteModel()
{
    NSMutableDictionary *allNotes;
    NSMutableDictionary *notifNotes;
    NSMutableArray *availableNotes;
    NSMutableArray *arrayOfArraysByType;
    NSMutableArray *allNotesFetchedInCategory;
    NSArray *allTags;
    NSMutableArray *selectedTags;
    NSMutableArray *searchTerms;
    
    BOOL unprocessedNotifs;
    
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
        notifNotes      = [[NSMutableDictionary alloc] initWithCapacity:20];
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
        allNotesFetchedInCategory = [NSMutableArray arrayWithCapacity:kNumContents];
        for(int i = 0; i < kNumContents; ++i)
        {
            [allNotesFetchedInCategory addObject:NO];
        }
        allTags         = [[NSArray alloc] init];
        selectedTags    = [[NSMutableArray alloc] initWithCapacity:8];
        searchTerms     = [[NSMutableArray alloc] initWithCapacity:8];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newNotesReceived:)    name:@"NewNoteListReady"    object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newTagsReceived:)     name:@"NewTagListReady"     object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateNoteContents:)  name:@"NewContentListReady" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(logInSucceeded)       name:@"LogInSucceeded"      object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(logOutSucceeded)      name:@"LogOutSucceeded"     object:nil];
    }
    return self;
}

#pragma mark Log In/Out Response

-(void) logInSucceeded
{
    [self fetchMoreNotesOfType:kMine];
}

-(void) logOutSucceeded
{
    [self clearAllData];
    [self fetchMoreNotes];
}

#pragma mark Clear Model

-(void) clearAllData
{
    [allNotes removeAllObjects];
    for(int i = 0; i < kNumContents; ++i)
        [[arrayOfArraysByType objectAtIndex:i] removeAllObjects];
    selectedTags = [allTags mutableCopy];
    [self sendSelectedTagsUpdateNotification];
    [searchTerms removeAllObjects];
    [allNotes addEntriesFromDictionary:notifNotes];
    [notifNotes removeAllObjects];
    [self clearAllNotesFetched];
    [self clearAvailableData];
    [self setUpNotifications];
}

-(void) clearAvailableData
{
    [self sendLostNotesNotif:[availableNotes copy]];
    [availableNotes removeAllObjects];
    [self sendChangeNotesNotif];
}

-(void) clearAllNotesFetched
{
    for(int i = 0; i < kNumContents; ++i)
    {
        [allNotesFetchedInCategory setObject:NO atIndexedSubscript:i];
    }
}

#pragma mark Mark Notes For Notification

- (void) setUpNotificationsForTopNotes: (int) topNotes popularNotes: (int) popularNotes recentNotes: (int) recentNotes andMyRecentNotes: (int) myRecentNotes
{
    NSArray *notifNotesCounts = [NSArray arrayWithObjects:[NSNumber numberWithInt:topNotes], [NSNumber numberWithInt:popularNotes],
                        [NSNumber numberWithInt:recentNotes], [NSNumber numberWithInt:myRecentNotes], nil];
    [[NSUserDefaults standardUserDefaults] setObject:notifNotesCounts forKey:NOTIF_NOTE_COUNT_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self setUpNotifications];
}

- (void) setUpNotifications
{
    NSArray *notifNotesCounts = [self getNotifNoteCounts];
    
    if([[notifNotesCounts objectAtIndex:kTop] intValue] > [[arrayOfArraysByType objectAtIndex:kTop] count] && ![allNotesFetchedInCategory objectAtIndex:kTop])
    {
        unprocessedNotifs = YES;
        [self fetchMoreNotesOfType:kTop];
        return;
    }
    else if([[notifNotesCounts objectAtIndex:kPopular] intValue] > [[arrayOfArraysByType objectAtIndex:kPopular] count] && ![allNotesFetchedInCategory objectAtIndex:kPopular])
    {
        unprocessedNotifs = YES;
        [self fetchMoreNotesOfType:kPopular];
        return;
    }
    else if([[notifNotesCounts objectAtIndex:kRecent] intValue] > [[arrayOfArraysByType objectAtIndex:kRecent] count] && ![allNotesFetchedInCategory objectAtIndex:kRecent])
    {
        unprocessedNotifs = YES;
        [self fetchMoreNotesOfType:kRecent];
        return;
    }
    else if([[notifNotesCounts objectAtIndex:kMine] intValue] > [[arrayOfArraysByType objectAtIndex:kMine] count] && ![allNotesFetchedInCategory objectAtIndex:kMine])
    {
        unprocessedNotifs = YES;
        [self fetchMoreNotesOfType:kMine];
        return;
    }
    
    unprocessedNotifs = NO;
    NSMutableArray *notifNoteIds = [[NSMutableArray alloc] initWithCapacity:20];
    
    for(int i = 0; i < kNumContents; ++i)
    {
        int indexInArray = 0;
        while (([[notifNotesCounts objectAtIndex:i] intValue]-[notifNoteIds count]) > 0 && indexInArray < [[arrayOfArraysByType objectAtIndex:i] count])
        {
            Note* currentNote = [allNotes objectForKey: [[arrayOfArraysByType objectAtIndex:i] objectAtIndex:indexInArray]];
            if([self noteShouldBeAvailable:currentNote] && ![self noteHasBeenDisplayedByNotif:currentNote])
                [notifNoteIds addObject:[[arrayOfArraysByType objectAtIndex:i] objectAtIndex:indexInArray]];
            ++indexInArray;
        }
        if([[notifNotesCounts objectAtIndex:i] intValue] != [notifNoteIds count])
            unprocessedNotifs = YES;
    }
    
    notifNotes = [NSMutableDictionary dictionaryWithObjects:[allNotes objectsForKeys:notifNoteIds notFoundMarker:[[Note alloc] init]] forKeys:notifNoteIds];
    [[MyCLController sharedMyCLController] prepareNotificationsForNotes: [notifNotes allValues]];
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
        if((specifiedContent != kMine || [AppModel sharedAppModel].playerId != 0) && ![allNotesFetchedInCategory objectAtIndex:specifiedContent])
        {
            int currentNoteCount = [[arrayOfArraysByType objectAtIndex:specifiedContent] count];
            [AppServices sharedAppServices].shouldIgnoreResults = NO;
            NSString *date = (specifiedContent == kRecent && currentNoteCount > 0) ? ((Note *)[allNotes objectForKey:[[arrayOfArraysByType objectAtIndex:specifiedContent] objectAtIndex:currentNoteCount-1]]).created : nil;
            [[AppServices sharedAppServices] fetch: NOTES_PER_FETCH more: specifiedContent NotesStartingFromLocation: currentNoteCount andDate:date];
        }
    }
}

#pragma mark Updates from Server

-(void) newNotesReceived:(NSNotification *)notification
{
    NSDictionary *newNotes = [notification.userInfo objectForKey:@"notes"];
    [allNotes addEntriesFromDictionary:newNotes];
    ContentSelector updatedNotes = [[notification.userInfo objectForKey:@"ContentSelector"] intValue];
    NSMutableArray *selectedArray = [arrayOfArraysByType objectAtIndex:updatedNotes];
    
    for(id object in [newNotes allKeys]) // [selectedArray addObjectsFromArray:[newNotes allKeys]]; replaced to prevent duplicates
    {
        if(![selectedArray containsObject:object])
            [selectedArray addObject:object];
    }
    
    if(unprocessedNotifs)
        [self setUpNotifications];
    
    if([[newNotes allKeys] count] < NOTES_PER_FETCH)
        [allNotesFetchedInCategory setObject:YES atIndexedSubscript:updatedNotes];
    
    if(updatedNotes == selectedContent)
    {
        [self updateAvailableNotes];
        [self sendNotesUpdateNotification];
        
        if([availableNotes count] < MAX_MAP_NOTES_COUNT && ![allNotesFetchedInCategory objectAtIndex:updatedNotes])
            [self fetchMoreNotesOfType:selectedContent];
    }
    
}

-(void) newTagsReceived:(NSNotification *)notification
{
    allTags = [notification.userInfo objectForKey:@"tags"];
    
    NSNotification *notif  = [NSNotification notificationWithName:@"NoteModelUpdate:Tags" object:self];
    [[Logger sharedLogger] logNotification: notif];
    [[NSNotificationCenter defaultCenter] postNotification: notif];
    
    if([selectedTags count] == 0)
    {
        selectedTags = [allTags mutableCopy];
        [self sendSelectedTagsUpdateNotification];
        [self updateAvailableNotes];
    }
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

-(void) setNoteAsPreviouslyDisplayed:(Note *) note
{
    NSMutableArray *previouslyDisplayedNotes = [[NSUserDefaults standardUserDefaults] objectForKey:PREV_DISPLAYED_NOTES_KEY];
    if(!previouslyDisplayedNotes)
        previouslyDisplayedNotes = [[NSMutableArray alloc] init];
    
    [previouslyDisplayedNotes addObject:[NSNumber numberWithInt:note.noteId]];
    
    [[NSUserDefaults standardUserDefaults] setObject:previouslyDisplayedNotes forKey:PREV_DISPLAYED_NOTES_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(Note *) noteForNoteId:(int) noteId
{
    Note *note = [allNotes objectForKey:[NSNumber numberWithInt:noteId]];
    if(!note)
        note = [notifNotes objectForKey:[NSNumber numberWithInt:noteId]];
    
    if(!note && note.noteId != 0)
        [[AppServices sharedAppServices] fetchNote:note.noteId];
    
    return note;
}

-(NSArray *) getNotifNoteCounts
{
    NSArray *notifNoteCounts = [[NSUserDefaults standardUserDefaults] objectForKey:NOTIF_NOTE_COUNT_KEY];
    if(!notifNoteCounts)
        notifNoteCounts = [NSArray arrayWithObjects:[NSNumber numberWithInt:0],[NSNumber numberWithInt:0],[NSNumber numberWithInt:0],[NSNumber numberWithInt:0], nil];
    
    return notifNoteCounts;
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
    [self sendSelectedTagsUpdateNotification];
    [self updateAvailableNotes];
}

-(void) removeTag: (Tag *) removeTag
{
    for(int i = 0; i < [selectedTags count]; ++i)
    {
        Tag *tag = [selectedTags objectAtIndex:i];
        if(tag.tagId == removeTag.tagId)
        {
            [selectedTags removeObject: tag];
            [self sendSelectedTagsUpdateNotification];
            [self clearAllNotesFetched];
            [self updateAvailableNotes];
            return;
        }
    }
}

-(void) addSearchTerm: (NSString *) term
{
    if([term length] > 0)
    {
        [searchTerms addObject: term];
        [self updateAvailableNotes];
    }
}

-(void) removeSearchTerm: (NSString *) term
{
    for(NSString *currentTerm in searchTerms)
    {
        if([term isEqualToString:currentTerm])
            [searchTerms removeObject: currentTerm];
    }
    
    [self clearAllNotesFetched];
    [self updateAvailableNotes];
}

-(void) setSelectedContent: (ContentSelector) contentSelector
{
    selectedContent = contentSelector;
    [AppServices sharedAppServices].shouldIgnoreResults = YES;
    [self clearAvailableData];
    
    if([[arrayOfArraysByType objectAtIndex:selectedContent] count] < MAX_MAP_NOTES_COUNT)
        [self fetchMoreNotes];
    else
        [self updateAvailableNotes];
}

-(BOOL) noteHasBeenDisplayedByNotif: (Note *) note
{
    NSMutableArray *previouslyDisplayedNotes = [[NSUserDefaults standardUserDefaults] objectForKey:PREV_DISPLAYED_NOTES_KEY];
    
    for(Note *displayedNote in previouslyDisplayedNotes)
    {
        if(displayedNote.noteId == note.noteId)
            return YES;
    }
    
    return NO;
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