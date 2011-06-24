//
//  ShakeKit.m
//  ShakeKit
//
//  Created by Justin Williams on 5/20/11.
//  Copyright 2011 Second Gear. All rights reserved.
//

#import "ShakeKit.h"
#import "ShakeKitConstants.h"
#import "ASIHTTPRequest.h"
#import "OAuthCore.h"
#import "OAuth+Additions.h"
#import "ASIFormDataRequest.h"
#import "JSONKit.h"
#import "NSDictionary+ParameterString.h"
#import "NSString+URIEscaping.h"
#import "SKPost.h"
#import "SKUser.h"
#import "SKShake.h"

@interface ShakeKit ()
- (ASIHTTPRequest *)requestWithProtocol:(NSString *)protocol host:(NSString *)host path:(NSString *)path parameters:(NSDictionary *)params method:(NSString *)method;
- (void)loadObjectOfClass:(Class)aClass path:(NSString *)path completionHandler:(SKCompletionHandler)handler;
- (void)loadArrayOfClass:(Class)aClass key:(NSString *)key path:(NSString *)path completionHandler:(SKCompletionHandler)handler;
@end

@implementation ShakeKit

@synthesize applicationKey;
@synthesize applicationSecret;
@synthesize queue;

+ (id)shared
{
  static dispatch_once_t pred;
  static ShakeKit *ShakeKitInstance = nil;
  
  dispatch_once(&pred, ^{ ShakeKitInstance = [[self alloc] init]; });
  return ShakeKitInstance;
}

- (id)initWithApplicationKey:(NSString *)theKey secret:(NSString *)theSecret
{
  if ((self = [super init]))
  {
    queue = [[NSOperationQueue alloc] init];
    [queue setMaxConcurrentOperationCount:3];
    
    applicationKey = [theKey copy];
    applicationSecret = [theSecret copy];    
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
  SGRelease(applicationKey);
  SGRelease(applicationSecret);
  SGRelease(queue);
  [super dealloc];
}


#pragma mark -
#pragma mark Instance Methods
// +--------------------------------------------------------------------
// | Instance Methods
// +--------------------------------------------------------------------

- (void)loginWithUsername:(NSString *)theUsername password:(NSString *)thePassword withCompletionHandler:(SKCompletionHandler)theHandler
{
  NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:theUsername, @"username", thePassword, @"password", nil];  
  NSMutableDictionary *mutableParams = [[[NSMutableDictionary alloc] initWithDictionary:params] autorelease];
  [mutableParams setValue:self.applicationKey forKey:@"client_id"];
  [mutableParams setValue:self.applicationSecret forKey:@"client_secret"];
  [mutableParams setValue:@"password" forKey:@"grant_type"];
  
  NSString *escapedPath = [NSString escapePath:@"/token"];
  NSString *urlString = [NSString stringWithFormat:@"%@://%@%@", kSKProtocolHTTPS, kSKMlkShkAPIHost, escapedPath];
  NSString *body = [mutableParams convertToURIParameterString];
  NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@?%@", urlString, body]];  
  
  __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
  request.delegate = self;
  request.requestMethod = kSKMethodPOST;
  request.shouldContinueWhenAppEntersBackground = YES;
  
  [request setCompletionBlock:^{
    NSDictionary *result = [[request responseString] objectFromJSONString];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[result objectForKey:@"access_token"] forKey:kOAuthAccessToken];
    [defaults setObject:[result objectForKey:@"secret"] forKey:kOAuthAccessSecret];
    [defaults synchronize];
    
    theHandler(result, nil);
  }];
  
  [request setFailedBlock:^{
    NSError *error = request.error;
    theHandler(nil, error);
  }];
  
  [self.queue addOperation:request];
}

- (void)loadFavoritesWithCompletionHandler:(SKCompletionHandler)handler
{
  NSString *path = @"/favorites";
  [self loadArrayOfClass:[SKPost class] key:@"favorites" path:path completionHandler:handler];
}

- (void)loadFavoritesBeforeKey:(NSString *)theKey completionHandler:(SKCompletionHandler)handler
{
  NSString *path = [NSString stringWithFormat:@"/favorites/before/%@", theKey];
  [self loadArrayOfClass:[SKPost class] key:@"favorites" path:path completionHandler:handler];
}

- (void)loadFavoritesAfterKey:(NSString *)theKey completionHandler:(SKCompletionHandler)handler
{
  NSString *path = [NSString stringWithFormat:@"/favorites/after/%@", theKey];
  [self loadArrayOfClass:[SKPost class] key:@"favorites" path:path completionHandler:handler];
}

- (void)loadFriendsTimelineWithCompletionHandler:(SKCompletionHandler)handler
{
  NSString *path = @"/friends";
  [self loadArrayOfClass:[SKPost class] key:@"friend_shake" path:path completionHandler:handler];
}

- (void)loadFriendsTimelineBeforeKey:(NSString *)theKey completionHandler:(SKCompletionHandler)handler
{
  NSString *path = [NSString stringWithFormat:@"/friends/before/%@", theKey];
  [self loadArrayOfClass:[SKPost class] key:@"friend_shake" path:path completionHandler:handler];
}

- (void)loadFriendsTimelineAfterKey:(NSString *)theKey completionHandler:(SKCompletionHandler)handler
{
  NSString *path = [NSString stringWithFormat:@"/friends/after/%@", theKey];
  [self loadArrayOfClass:[SKPost class] key:@"friend_shake" path:path completionHandler:handler];
}

- (void)loadMagicFilesWithCompletionHandler:(SKCompletionHandler)handler
{
  NSString *path = @"/magicfiles";
  [self loadArrayOfClass:[SKPost class] key:@"magicfiles" path:path completionHandler:handler];
}

- (void)loadSharedFileWithKey:(NSString *)theKey completionHandler:(SKCompletionHandler)handler
{
  NSString *path = [NSString stringWithFormat:@"/sharedfile/%@", theKey];
  [self loadObjectOfClass:[SKPost class] path:path completionHandler:handler];
}

- (void)loadProfileForUserWithID:(NSInteger)theUserID completionHandler:(SKCompletionHandler)handler
{
  NSString *path = [NSString stringWithFormat:@"/user_id/%ld", theUserID];
  [self loadObjectOfClass:[SKUser class] path:path completionHandler:handler];
}

- (void)loadProfileForUserWithName:(NSString *)theScreenName completionHandler:(SKCompletionHandler)handler
{
  NSString *path = [NSString stringWithFormat:@"/user_name/%@", theScreenName];
  [self loadObjectOfClass:[SKUser class] path:path completionHandler:handler];
}

- (void)loadProfileForUser:(SKUser *)theUser completionHandler:(SKCompletionHandler)handler
{
  [self loadProfileForUserWithID:theUser.userID completionHandler:handler];
}

- (void)loadProfileForCurrentlyAuthenticatedUserWithCompletionHandler:(SKCompletionHandler)handler
{
  NSString *path = @"/user";
  [self loadObjectOfClass:[SKUser class] path:path completionHandler:handler];
}

- (void)loadShakesWithCompletionHandler:(SKCompletionHandler)handler
{
  NSString *path = @"/shakes";
  [self loadArrayOfClass:[SKShake class] key:@"shakes" path:path completionHandler:handler];
}

- (void)uploadFileFromLocalPath:(NSURL *)theLocalPath toShake:(SKShake *)theShake withCompletionHandler:(SKCompletionHandler)handler
{
  if ((![[NSFileManager defaultManager] fileExistsAtPath:[theLocalPath path]]))
  {
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:theLocalPath forKey:@"localPath"];
    NSError *error = [NSError errorWithDomain:SKShakeErrorDomain code:SKShakeErrorFileNotFound userInfo:userInfo];
    handler(nil, error);
    return;
  }
  
  NSString *path = @"/upload";  
  
  NSString *urlString = [NSString stringWithFormat:@"%@://%@%@", kSKProtocolHTTPS, kSKMlkShkAPIHost, path];
  NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@", urlString]];

  __block ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
  request.delegate = self;
  request.requestMethod = kSKMethodPOST;
  request.shouldContinueWhenAppEntersBackground = YES;
  
  if (theShake != nil)
  {
    [request setPostValue:[NSNumber numberWithInteger:theShake.shakeID] forKey:@"shake_id"];
  }
  
  [request addFile:[theLocalPath path] forKey:@"file"];
  
  //
  // MlkShk uses OAuth2 to handle its authentication, so we need to pass along the requested
  // tokens and secrets so that we get our stuff back.
  //
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSString *token = [defaults objectForKey:kOAuthAccessToken];
  NSString *secret = [defaults objectForKey:kOAuthAccessSecret];  
  
  [request buildPostBody]; 
  NSString *header = OAuth2Header(request.url, request.requestMethod, 80, self.applicationKey, self.applicationSecret, token, secret);
  
  [request addRequestHeader:@"Authorization" value:header];  

  [request setCompletionBlock:^{
    NSDictionary *result = [[request responseString] objectFromJSONString];
    /*
     This currently returns JSON for the file name and the share_key. 
     Not sure if I should convert that to an SKPost since it's not the full amount of data returned
     traditionally or just keep passing the dictionary back.
    */
    handler(result, nil);
  }];
  
  [request setFailedBlock:^{
    NSError *error = request.error;
    handler(nil, error);
  }];
  
  [self.queue addOperation:request];

}

#pragma mark -
#pragma mark Private/Convenience Methods
// +--------------------------------------------------------------------
// | Private/Convenience Methods
// +--------------------------------------------------------------------

- (ASIHTTPRequest *)requestWithProtocol:(NSString *)protocol host:(NSString *)host path:(NSString *)path parameters:(NSDictionary *)params method:(NSString *)method
{
  NSString *escapedPath = [NSString escapePath:path];
  
  NSString *urlString = [NSString stringWithFormat:@"%@://%@%@", protocol, host, escapedPath];    
  NSString *body = [params convertToURIParameterString];
  
  NSURL *url = nil;
  if ([body length] == 0)
  {
    url = [NSURL URLWithString:[NSString stringWithFormat:@"%@", urlString]];
  }
  else
  {
    url = [NSURL URLWithString:[NSString stringWithFormat:@"%@?%@", urlString, body]];
  }
  
  ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
  request.requestMethod = method;
  request.shouldContinueWhenAppEntersBackground = YES;
  
  //
  // MlkShk uses OAuth2 to handle its authentication, so we need to pass along the requested
  // tokens and secrets so that we get our stuff back.
  //
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSString *token = [defaults objectForKey:kOAuthAccessToken];
  NSString *secret = [defaults objectForKey:kOAuthAccessSecret];  
  
  [request buildPostBody]; 
  NSString *header = OAuth2Header(url, method, 80, self.applicationKey, self.applicationSecret, token, secret);
  
  [request addRequestHeader:@"Authorization" value:header];  
  
  return request;
}

- (void)loadObjectOfClass:(Class)aClass path:(NSString *)path completionHandler:(SKCompletionHandler)handler
{
  __block ASIHTTPRequest *request = [self requestWithProtocol:kSKProtocolHTTPS host:kSKMlkShkAPIHost path:path parameters:nil method:kSKMethodGET];
  
  [request setCompletionBlock:^{
    NSDictionary *responseDictionary = [[request responseString] objectFromJSONString];
    id obj = [[aClass alloc] initWithDictionary:responseDictionary];
    
    handler([obj autorelease], nil);
  }];
  
  [request setFailedBlock:^{
    NSError *error = request.error;
    handler(nil, error);
  }];
  
  [self.queue addOperation:request];
}

- (void)loadArrayOfClass:(Class)aClass key:(NSString *)key path:(NSString *)path completionHandler:(SKCompletionHandler)handler
{
  __block ASIHTTPRequest *request = [self requestWithProtocol:kSKProtocolHTTPS host:kSKMlkShkAPIHost path:path parameters:nil method:kSKMethodGET];
  
  [request setCompletionBlock:^{
    NSDictionary *responseDictionary = [[request responseString] objectFromJSONString];
    NSMutableArray *objs = [[NSMutableArray alloc] init];
    for (NSDictionary *objInfo in [responseDictionary objectForKey:key])
    {
      id obj = [[aClass alloc] initWithDictionary:objInfo];
      [objs addObject:obj];
      [obj release];
    }
    
    handler([objs autorelease], nil);
  }];
  
  [request setFailedBlock:^{
    NSError *error = request.error;
    handler(nil, error);
  }];
  
  [self.queue addOperation:request];
}

@end
