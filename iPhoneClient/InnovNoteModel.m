//
//  InnovNoteModel.m
//  YOI
//
//  Created by Jacob James Hanshaw on 5/22/13.
//
//

#import "InnovNoteModel.h"

#import "Note.h"

@interface InnovNoteModel()
{
    NSMutableArray *allLocations;
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
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(latestGameNotesReceived:)   name:@"GameNoteListRefreshed"   object:nil];
     // [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(latestPlayerNotesReceived:) name:@"PlayerNoteListRefreshed" object:nil];
#warning only receives game note list
    }
    return self;
}

-(void)clearData
{
    [self updateNotes:[[NSArray alloc] init]];
}

-(void)latestGameNotesReceived:(NSNotification *)notification
{
    [self updateNotes:[notification.userInfo objectForKey:@"notes"]];
}

-(void)updateNotes:(NSArray *)notes
{
    NSMutableArray *newlyAvailableNotes   = [[NSMutableArray alloc] initWithCapacity:20];
    NSMutableArray *newlyUnavailableNotes = [[NSMutableArray alloc] initWithCapacity:20];
    
    //Gained Notes
    for(Note *newNote in notes)
    {
        BOOL match = NO;
        for (Note *existingNote in self.availableNotes)
        {
            if ([newNote compareTo: existingNote])
                match = YES;
        }
        
        if(!match) //New Location
            [newlyAvailableNotes addObject:newNote];
    }
    
    //Lost Notes
    for (Note *existingLocation in self.currentLocations)
    {
        BOOL match = NO;
        for (Location *newLocation in locations)
        {
            if ([newLocation compareTo: existingLocation])
                match = YES;
        }
        
        if(!match) //Lost location
            [newlyUnavailableLocations addObject:existingLocation];
    }
    
    self.currentLocations = locations;
    
    if([newlyAvailableLocations count] > 0)
    {
        NSDictionary *lDict = [[NSDictionary alloc] initWithObjectsAndKeys:
                               newlyAvailableLocations,@"newlyAvailableLocations",
                               locations,@"allLocations",
                               nil];
        NSLog(@"NSNotification: NewlyAvailableLocationsAvailable");
        [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"NewlyAvailableLocationsAvailable" object:self userInfo:lDict]];
    }
    if([newlyUnavailableLocations count] > 0)
    {
        NSDictionary *lDict = [[NSDictionary alloc] initWithObjectsAndKeys:
                               newlyUnavailableLocations,@"newlyUnavailableLocations",
                               locations,@"allLocations",
                               nil];
        NSLog(@"NSNotification: NewlyUnavailableLocationsAvailable");
        [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"NewlyUnavailableLocationsAvailable" object:self userInfo:lDict]];
    }
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
