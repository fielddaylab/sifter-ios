//
//  JSONConnection.h
//  ARIS
//
//  Created by David J Gagnon on 8/28/09.
//  Copyright 2009 University of Wisconsin - Madison. All rights reserved.
//

#import "JSONResult.h"

@interface JSONConnection : NSObject  <NSURLConnectionDelegate>{
	NSURL *jsonServerURL;
	NSString *serviceName;
	NSString *methodName;
	NSArray *arguments;
    SEL handler;
    NSMutableDictionary *userInfo;
	NSMutableData *asyncData;
	NSURL *completeRequestURL;
    NSURLConnection *connection;
}

@property(nonatomic) NSURL *jsonServerURL;
@property(nonatomic) NSString *serviceName;
@property(nonatomic) NSString *methodName;
@property(nonatomic) NSArray *arguments;
@property(nonatomic) SEL handler;
@property(nonatomic) NSMutableDictionary *userInfo;
@property(nonatomic) NSMutableDictionary *handlerUserInfo;
@property(nonatomic) NSURL *completeRequestURL;
@property(nonatomic) NSMutableData *asyncData;
@property(nonatomic) NSURLConnection *connection;



- (JSONConnection*)initWithServer: (NSURL *)server
					andServiceName:(NSString *)serviceName 
					andMethodName:(NSString *)methodName
					andArguments:(NSArray *)arguments
                      andUserInfo:(NSMutableDictionary *)userInfo;

- (JSONResult*) performSynchronousRequest;
- (void) performAsynchronousRequestWithHandler: (SEL)handler;
- (void) performAsynchronousRequestWithHandler: (SEL)handler andUserInfo:(NSMutableDictionary *) hUserInfo;
- (void)connectionDidFinishLoading:(NSURLConnection*)theConnection;
- (void)connection:(NSURLConnection *)theConnection didReceiveData:(NSData *)incrementalData;
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;


@end
