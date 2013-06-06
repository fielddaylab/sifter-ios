//
//  LogInDelegate.h
//  YOI
//
//  Created by JacobJamesHanshaw on 6/6/13.
//
//

#import <Foundation/Foundation.h>

@protocol LogInDelegate <NSObject>
@required
- (void)createUserAndLoginWithGroup:(NSString *) username andGameId:(int) gameId inMuseumMode:(BOOL) museumMode;
- (void)attemptLoginWithUserName:(NSString *) username andPassword:(NSString *) password andGameId:(int) gameId inMuseumMode:(BOOL) museumMode;

@end
