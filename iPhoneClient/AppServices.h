//
//  AppServices.h
//  ARIS
//
//  Created by David J Gagnon on 5/11/11.
//  Copyright 2011 University of Wisconsin. All rights reserved.
//

@class JSONResult;

#import "MyCLController.h"
#import "InnovNoteModel.h"

@interface AppServices : NSObject

extern NSString *const kARISServerServicePackage;

@property(readwrite) BOOL isCurrentlyFetchingGameNoteList;
@property(readwrite) BOOL shouldIgnoreResults;

+ (AppServices *)sharedAppServices;

- (void)resetCurrentlyFetchingVars;

//Player
- (void)login;
- (void)loginWithFacebookEmail:(NSString *) email displayName:(NSString *) displayName andId:(NSString *) idString;
- (void)registerNewUser:(NSString*)userName
               password:(NSString*)pass
			  firstName:(NSString*)firstName
               lastName:(NSString*)lastName
                  email:(NSString*)email;
- (void)uploadPlayerPicMediaWithFileURL:(NSURL *)fileURL;
- (void)setPlayerPicToUrl:(NSString *) urlString;
- (void)updatePlayer:(int)playerId withName:(NSString *)name andImage:(int)mid;
- (void)resetAndEmailNewPassword:(NSString *)email;
- (void)fetchOneGameGameList:(int)gameId;

//Fetch Game Data (ONLY CALLED ONCE PER GAME!!)
- (void)fetchGameMediaListAsynchronously:    (BOOL)YesForAsyncOrNoForSync;
- (void)fetchGameNoteTagsAsynchronously:     (BOOL)YesForAsyncOrNoForSync;

//Get Specific Data (technically, these being called is a sign that the "fetch game data" functions failed somewhere...)
- (void)fetchMedia:(int)mediaId;
- (void)fetchNote:(int)noteId;

- (void)fetch:(int) noteCount more: (ContentSelector) selectedContent NotesContainingSearchTerms: (NSArray *) searchTerms withTagIds: (NSArray *) tagIds StartingFromLocation: (int) lastLocation andDate: (NSString *) date;
- (void)fetch:(int) noteCount more: (ContentSelector) selectedContent NotesStartingFromLocation: (int) lastLocation andDate: (NSString *) date;

//Note Stuff
- (int)createNote;
- (int)createNoteStartIncomplete;
- (void)setNoteCompleteForNoteId:(int)noteId;
- (void)updateNoteWithNoteId:(int)noteId title:(NSString *)title publicToMap:(BOOL)publicToMap publicToList:(BOOL)publicToList;
- (void)deleteNoteWithNoteId:(int)noteId;
- (void)dropNote:(int)noteId atCoordinate:(CLLocationCoordinate2D)coordinate;
- (void)addContentToNoteWithText:(NSString *)text type:(NSString *)type mediaId:(int)mediaId andNoteId:(int)noteId andFileURL:(NSURL *)fileURL;
- (void)uploadContentToNoteWithFileURL:(NSURL *)fileURL name:(NSString *)name noteId:(int)noteId type:(NSString *)type;
- (void)deleteNoteContentWithContentId:(int)contentId andNoteId:(int) noteId;
- (void)deleteNoteLocationWithNoteId:(int)noteId;
- (void)updateNoteContent:(int)contentId text:(NSString *)text;
- (void)updateNoteContent:(int)contentId title:(NSString *)title;
- (void)addTagToNote:(int)noteId tagName:(NSString *)tag;
- (void)deleteTagFromNote:(int)noteId tagId:(int)tagId;
- (int) addCommentToNoteWithId:(int)noteId andTitle:(NSString *)title;
- (void)updateCommentWithId:(int)noteId andTitle:(NSString *)title andRefresh:(BOOL)refresh;
- (void)likeNote:(int)noteId;
- (void)unLikeNote:(int)noteId;
- (void)flagNote:(int)noteId;
- (void)unFlagNote:(int)noteId;
- (void)sharedNoteToFacebook:(int)noteId;
- (void)sharedNoteToTwitter:(int)noteId;
- (void)sharedNoteToPinterest:(int)noteId;
- (void)sharedNoteToEmail:(int)noteId;

//Tell server of state
- (void)updateServerWithPlayerLocation;

//Parse server responses
- (void)parseGameMediaListFromJSON:       (JSONResult *)jsonResult;
- (void)parseGameNoteListFromJSON:        (JSONResult *)jsonResult;
- (void)parseGameTagsListFromJSON:        (JSONResult *)jsonResult;

//Parse individual pieces of server response
- (Note *)     parseNoteFromDictionary:     (NSDictionary *)noteDictionary;

- (void)sendNotificationToNoteViewer: (NSDictionary *) userInfo;
- (void)sendNotificationToNotebookViewer;

@end
