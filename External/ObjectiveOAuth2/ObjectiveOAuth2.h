//
//  ObjectiveOAuth2.h
//  ShakeKit
//
//  Created by Justin Williams on 5/27/11.
//  Copyright 2011 Second Gear. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class OOAuth2Token;
@protocol ObjectiveOAuth2Delegate;

@interface ObjectiveOAuth2 : NSObject 

@property (copy) NSString *clientID;
@property (copy) NSString *clientSecret;

@property (retain) NSURL *redirectURL;
@property (retain) NSURL *tokenURL;
@property (retain) NSURL *cancelURL;
@property (retain) NSURL *userURL;
@property (retain) OOAuth2Token *token;
@property (assign) id <ObjectiveOAuth2Delegate> delegate;
@property (assign, getter=isVerifying) BOOL verifying;
@property (retain) NSMutableArray *activeRequests;


- (id)initWithClientID:(NSString *)clientID secret:(NSString *)secret redirectURL:(NSURL *)redirectURL;

- (NSURLRequest *)perormAuthorizationRequestWithAdditionalParameters:(NSDictionary *)params;
- (void)verifyAuthorizationWithAccessCode:(NSString *)accessCode;
- (void)refreshToken:(OOAuth2Token *)accessToken;

@end

@protocol ObjectiveOAuth2Delegate

@required
- (void)clientDidReceiveAccessToken:(ObjectiveOAuth2 *)client;
- (void)clientDidRefreshAccessToken:(ObjectiveOAuth2 *)client;

@optional
- (void)clientDidReceiveAccessCode:(ObjectiveOAuth2 *)client;
- (void)clientDidCancel:(ObjectiveOAuth2 *)client;

@end