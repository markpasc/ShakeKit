//
//  OOAuth2Token.m
//  ShakeKit
//
//  Created by Justin Williams on 5/27/11.
//  Copyright 2011 Second Gear. All rights reserved.
//

#import "OOAuth2Token.h"

@interface OOAuth2Token ()
@property (retain) NSDictionary *authenticationResponseData;
- (void)extractExpiresAtFromResponseDictionary;
@end

static NSString * const kAccessTokenKey = @"access_token";
static NSString * const kRefreshTokenKey = @"refresh_token";
static NSString * const kExpiresInKey = @"expires_in";

@implementation OOAuth2Token


@synthesize accessToken;
@dynamic refreshToken;
@synthesize expiresAt;
@synthesize authenticationResponseData;

- (id)initWithAuthorizationResponse:(NSDictionary *)responseData
{
  if ((self = [super init]))
  {
    authenticationResponseData = [responseData copy];
    [self extractExpiresAtFromResponseDictionary];
  }
  
  return self;
}

#pragma mark -
#pragma mark NSCoding
// +--------------------------------------------------------------------
// | NSCoding
// +--------------------------------------------------------------------

- (void)encodeWithCoder:(NSCoder *)theCoder
{
  [theCoder encodeObject:authenticationResponseData forKey:@"authenticationResponseData"];
  [theCoder encodeObject:expiresAt forKey:@"expiresAt"];
}

- (id)initWithCoder:(NSCoder *)theDecoder
{
  if ((self = [super init]))
  {
    authenticationResponseData = [[theDecoder decodeObjectForKey:@"authenticationResponseData"] copy];
    expiresAt = [[theDecoder decodeObjectForKey:@"expiresAt"] retain];
  }
  return self;
}


#pragma mark -
#pragma mark Memory Management
// +--------------------------------------------------------------------
// | Memory Management
// +--------------------------------------------------------------------

- (void)dealloc
{
  [expiresAt release]; expiresAt = nil;
  [authenticationResponseData release]; authenticationResponseData = nil;
  [super dealloc];
}

#pragma mark -
#pragma mark Instance Methods
// +--------------------------------------------------------------------
// | Instance Methods
// +--------------------------------------------------------------------

- (void)refreshFromAuthorizationResponse:(NSDictionary *)responseData
{
  NSMutableDictionary *tokenData = [self.authenticationResponseData mutableCopy];
  
  [tokenData setObject:[responseData valueForKey:@"access_token"] forKey:kAccessTokenKey];
  [tokenData setObject:[responseData objectForKey:@"expires_in"]  forKey:kExpiresInKey];
  
  self.authenticationResponseData = tokenData;
  
  [tokenData release];
  [self extractExpiresAtFromResponseDictionary];
}

- (BOOL)hasExpired
{
  BOOL isExpired = [[NSDate date] earlierDate:expiresAt] == expiresAt;
  
  return isExpired;
}

#pragma mark -
#pragma mark Dynamic Accessor Methods
// +--------------------------------------------------------------------
// | Dynamic Accessor Methods
// +--------------------------------------------------------------------

- (NSString *)accessToken;
{
  return [self.authenticationResponseData objectForKey:kAccessTokenKey];
}

- (NSString *)refreshToken;
{
  return [self.authenticationResponseData objectForKey:kRefreshTokenKey];
}

#pragma mark -
#pragma mark Private/Convenience Methods
// +--------------------------------------------------------------------
// | Private/Convenience Methods
// +--------------------------------------------------------------------

- (void)extractExpiresAtFromResponseDictionary
{
  NSTimeInterval expiresIn = (NSTimeInterval)[[self.authenticationResponseData objectForKey:@"expires_in"] intValue];
  expiresAt = [[NSDate alloc] initWithTimeIntervalSinceNow:expiresIn];
}

@end
