//
//  OOAuth2Token.h
//  ShakeKit
//
//  Created by Justin Williams on 5/27/11.
//  Copyright 2011 Second Gear. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface OOAuth2Token : NSObject 

@property (assign, readonly) NSString *accessToken;
@property (assign, readonly) NSString *refreshToken;
@property (retain, readonly) NSDate *expiresAt;

- (id)initWithAuthorizationResponse:(NSDictionary *)responseData;
- (void)refreshFromAuthorizationResponse:(NSDictionary *)responseData;

- (BOOL)hasExpired;

@end
